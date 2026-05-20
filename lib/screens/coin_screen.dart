import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../coins/coin.dart';
import '../coins/module_registry.dart';
import '../coins/monero/monero_engine.dart';
import '../coins/monero/monero_wallet.dart';
import '../l10n/gen/app_localizations.dart';
import '../prefs/prefs.dart';
import '../prices/price_feed.dart';
import '../util/explorer_links.dart';
import '../util/peek_logger.dart';
import '../wallets/balance_cache.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import '../vault/vault_state.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import '../widgets/coin_screen_widgets.dart';
import 'send_xmr_screen.dart';

/// Kinds of one-shot errors we surface in the red banner near the top.
enum _XmrLoadError { none, locked, addressDerivation }

/// Kinds of engine/daemon errors shown as `Engine: …` status pills.
/// `raw` carries through native engine messages (engine.error,
/// MoneroSession.lastError) which we don't translate.
enum _XmrEngineError {
  none,
  vaultLocked,
  passwordRequired,
  couldNotOpen,
  unknownCoin,
  raw,
}

/// Coin detail page. For Monero, shows the live native-engine balance
/// + sync progress; other coins still show placeholder text until
/// their own backends land.
///
/// Two modes:
///   - Legacy (walletMeta == null): boots via the single-wallet
///     MoneroSession.I.start path using VaultState.mnemonic.
///   - Multi-wallet (walletMeta provided): opens that specific wallet
///     via MoneroSession.I.startFor + CoinModule.open. Cached
///     primary address in meta avoids re-derivation.
class CoinScreen extends StatefulWidget {
  const CoinScreen({
    super.key,
    required this.coin,
    this.walletMeta,
  });
  final Coin coin;
  final WalletMeta? walletMeta;

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> {
  String? _address;
  _XmrLoadError _loadErr = _XmrLoadError.none;
  String? _loadErrDetail;

  /// 1s poll of MoneroSession for balance + sync %. Cheap enough — the
  /// FFI calls are non-blocking reads of cached native state.
  Timer? _poll;
  int? _syncPct;
  double? _balanceXmr;
  int _currentHeight = 0;
  int _tipHeight = 0;
  bool _daemonConnected = false;
  bool _isSynced = false;
  String? _daemonError;
  _XmrEngineError _engineErr = _XmrEngineError.none;
  String? _engineErrDetail;
  List<MoneroTx> _transactions = const [];
  MoneroWallet? _moneroWallet;

  String? _engineErrText(AppLocalizations l) => switch (_engineErr) {
        _XmrEngineError.none => null,
        _XmrEngineError.vaultLocked => l.xmrScreenErrVaultLocked,
        _XmrEngineError.passwordRequired => l.xmrScreenErrPasswordRequired,
        _XmrEngineError.couldNotOpen =>
          l.xmrScreenErrCouldNotOpen(_engineErrDetail ?? ''),
        _XmrEngineError.unknownCoin =>
          l.xmrScreenErrUnknownCoin(_engineErrDetail ?? ''),
        _XmrEngineError.raw => _engineErrDetail,
      };

  String? _loadErrText(AppLocalizations l) => switch (_loadErr) {
        _XmrLoadError.none => null,
        _XmrLoadError.locked => l.xmrScreenErrLocked,
        _XmrLoadError.addressDerivation =>
          l.xmrScreenErrAddressDerivation(_loadErrDetail ?? ''),
      };

  /// Subscription on VaultState — bails out of any in-flight poll if
  /// the wallet locks while this screen is alive (IndexedStack keeps
  /// us mounted even when the user navigates away).
  VoidCallback? _vaultListener;

  @override
  void initState() {
    super.initState();
    _load();
    _vaultListener = _onVaultChange;
    VaultState.I.addListener(_vaultListener!);
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (_vaultListener != null) {
      VaultState.I.removeListener(_vaultListener!);
    }
    super.dispose();
  }

  void _onVaultChange() {
    // Re-lock teardown: when VaultState locks, MoneroSession.stop()
    // has closed the wallet and freed the native pointer. The poll
    // timer is still scheduled — stop it before its next tick reads
    // from the (defensively-zeroed) closed wallet.
    if (!VaultState.I.isUnlocked) {
      _poll?.cancel();
      _poll = null;
      _moneroWallet = null;
      if (mounted) {
        setState(() {
          _balanceXmr = null;
          _syncPct = null;
          _currentHeight = 0;
          _tipHeight = 0;
          _daemonConnected = false;
          _isSynced = false;
          _daemonError = null;
          _transactions = const [];
        });
      }
    }
  }

  Future<void> _load() async {
    if (widget.walletMeta != null) {
      // Multi-wallet mode — use the cached address; skip derivation.
      setState(() => _address = widget.walletMeta!.primaryAddress ?? '');
      if (widget.walletMeta!.coinId == 'XMR' && moneroNativeAvailable()) {
        final engine = MoneroEngine.I.status();
        if (!engine.loaded) {
          setState(() {
            _engineErr = _XmrEngineError.raw;
            _engineErrDetail = engine.error;
          });
          return;
        }
        await _bootMoneroFromMeta(widget.walletMeta!);
      }
      return;
    }

    // Legacy single-wallet mode (vault-wallet-style unified seed).
    final mn = VaultState.I.mnemonic;
    if (mn == null) {
      setState(() => _loadErr = _XmrLoadError.locked);
      return;
    }
    try {
      final a = await widget.coin.deriveAddress(mn);
      setState(() => _address = a);
    } catch (e) {
      setState(() {
        _loadErr = _XmrLoadError.addressDerivation;
        _loadErrDetail = e.toString();
      });
    }

    if (widget.coin.id == 'XMR' && moneroNativeAvailable()) {
      final engine = MoneroEngine.I.status();
      if (!engine.loaded) {
        setState(() {
          _engineErr = _XmrEngineError.raw;
          _engineErrDetail = engine.error;
        });
        return;
      }
      await _bootMonero(mn);
    }
  }

  Future<void> _bootMoneroFromMeta(WalletMeta meta) async {
    final stageTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {});
    });

    final walletFilePassword = VaultState.I.walletFilePassword;
    if (walletFilePassword == null) {
      stageTicker.cancel();
      setState(() => _engineErr = _XmrEngineError.vaultLocked);
      return;
    }

    // Use the cached master password from VaultState (set on
    // unlock). Falls back to prompting only if the cache is empty
    // — happens when the session was unlocked before the cache
    // landed, or if a future feature explicitly evicts the cache
    // (PIN-only mode, etc.).
    var password = VaultState.I.cachedPassword;
    if (password == null) {
      password = await _promptPasswordOnce(context);
      if (password == null) {
        stageTicker.cancel();
        setState(() => _engineErr = _XmrEngineError.passwordRequired);
        return;
      }
    }

    final DecryptedWallet decrypted;
    try {
      decrypted = await WalletStore.I.open(
        walletId: meta.id,
        password: password,
      );
    } catch (e) {
      stageTicker.cancel();
      setState(() {
        _engineErr = _XmrEngineError.couldNotOpen;
        _engineErrDetail = e.toString();
      });
      return;
    }

    final coin = coinModuleFor(meta.coinId);
    if (coin == null) {
      stageTicker.cancel();
      setState(() {
        _engineErr = _XmrEngineError.unknownCoin;
        _engineErrDetail = meta.coinId;
      });
      return;
    }

    final daemonUri =
        await Prefs.I.moneroDaemonUri() ?? kDefaultMoneroDaemon;
    final w = await MoneroSession.I.startFor(
      walletId: meta.id,
      opener: (onStage) async {
        final result = await coin.open(
          walletId: meta.id,
          format: meta.format,
          seedMaterial: decrypted.seedMaterial,
          walletFilePassword: decrypted.walletFilePassword,
          daemonUri: daemonUri,
          restoreHeight: meta.restoreHeight ?? 0,
          onStage: onStage,
        );
        return result as MoneroWallet?;
      },
    );
    stageTicker.cancel();
    if (w == null) {
      setState(() {
        _engineErr = _XmrEngineError.raw;
        _engineErrDetail = MoneroSession.I.lastErrorFor(meta.id) ?? 'unknown';
      });
      return;
    }
    _moneroWallet = w;
    var lastHistoryPoll = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      List<MoneroTx>? newTx;
      final now = DateTime.now();
      if (now.difference(lastHistoryPoll).inSeconds >= 5) {
        lastHistoryPoll = now;
        try {
          newTx = w.transactions();
        } catch (e) {
          PeekLogger.I.log('xmr', 'tx list refresh failed: $e');
        }
      }
      setState(() {
        _syncPct = w.syncProgressPct;
        _balanceXmr = w.balanceXmr;
        _currentHeight = w.currentHeight;
        _tipHeight = w.daemonTipHeight;
        _daemonConnected = w.isDaemonConnected;
        _isSynced = w.isSynced;
        _daemonError = w.daemonError;
        if (newTx != null) _transactions = newTx;
      });
      _pushBalanceCache(w.balanceXmr);
    });
  }

  Future<String?> _promptPasswordOnce(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.xmrScreenUnlockTitle),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(labelText: l.xmrScreenAppPasswordLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l.xmrScreenUnlockAction),
          ),
        ],
      ),
    );
    controller.dispose();
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _bootMonero(String mnemonic) async {
    // Fallback restoreHeight only used if the daemon doesn't respond
    // to /get_height within ~15s during wallet creation. In the normal
    // path MoneroWallet.open queries the daemon for real tip and calls
    // Wallet_setRefreshFromBlockHeight with (tip - 5000). This value
    // is intentionally conservative — a couple weeks before the real
    // May-2026 tip — so even on a degraded boot the wallet won't skip
    // recent receives. Bump on each release as a safety net.
    const restoreHeight = 3650000;
    // Repaint while open() is still streaming stage updates so the
    // user sees progress instead of just a blank '…XMR'.
    final stageTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {});
    });
    final walletPwd = VaultState.I.walletFilePassword;
    if (walletPwd == null) {
      // Same pattern as _bootMoneroFromMeta — cancel the ticker
      // before bailing or it keeps repainting forever (battery +
      // mutates state on a disposed screen).
      stageTicker.cancel();
      setState(() => _engineErr = _XmrEngineError.vaultLocked);
      return;
    }
    final daemonUri =
        await Prefs.I.moneroDaemonUri() ?? kDefaultMoneroDaemon;
    final w = await MoneroSession.I.start(
      mnemonic: mnemonic,
      passphrase: VaultState.I.passphrase,
      restoreHeight: restoreHeight,
      daemonUri: daemonUri,
      walletPassword: walletPwd,
    );
    stageTicker.cancel();
    if (w == null) {
      setState(() {
        _engineErr = _XmrEngineError.raw;
        _engineErrDetail = MoneroSession.I.lastError ?? 'unknown';
      });
      return;
    }
    _moneroWallet = w;
    var lastHistoryPoll = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Refresh the cached tx list every 5s — it's a native call
      // that iterates the wallet's in-memory history vector, cheap
      // but not free, no reason to do it once per second.
      List<MoneroTx>? newTx;
      final now = DateTime.now();
      if (now.difference(lastHistoryPoll).inSeconds >= 5) {
        lastHistoryPoll = now;
        try {
          newTx = w.transactions();
        } catch (e) {
          PeekLogger.I.log('xmr', 'tx list refresh failed: $e');
        }
      }
      setState(() {
        _syncPct = w.syncProgressPct;
        _balanceXmr = w.balanceXmr;
        _currentHeight = w.currentHeight;
        _tipHeight = w.daemonTipHeight;
        _daemonConnected = w.isDaemonConnected;
        _isSynced = w.isSynced;
        _daemonError = w.daemonError;
        if (newTx != null) _transactions = newTx;
      });
      _pushBalanceCache(w.balanceXmr);
    });
  }

  void _showReceiveSheet() {
    if (_address == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReceiveSheet(
        wallet: _moneroWallet,
        primaryAddress: _address!,
      ),
    );
  }

  /// Snapshot the current balance into the wallets-list cache so
  /// the wallets-list subtitle + portfolio total can render without
  /// re-fetching. No-op if balance is null (wallet still loading)
  /// or the screen is running in legacy single-wallet mode (where
  /// there's no walletMeta to key the cache by).
  void _pushBalanceCache(double? balance) {
    if (balance == null) return;
    final meta = widget.walletMeta;
    if (meta == null) return;
    final price = PriceFeed.I.prices['XMR'];
    BalanceCache.I.put(CachedBalance(
      walletId: meta.id,
      symbol: 'XMR',
      displayAmount: '${balance.toStringAsFixed(8)} XMR',
      fiatValue: price == null ? 0 : balance * price,
      fiatCurrency: PriceFeed.I.currency,
      updatedAt: DateTime.now(),
    ));
  }

  String _balanceText(AppLocalizations l) {
    if (widget.coin.id != 'XMR') return '… ${widget.coin.symbol}';
    if (_engineErr != _XmrEngineError.none) return '… ${widget.coin.symbol}';
    if (_balanceXmr == null) {
      final s = MoneroSession.I.stage;
      return s == null ? '… ${widget.coin.symbol}' : l.xmrScreenBootStage(s);
    }
    if (!_daemonConnected) return l.xmrScreenConnectingDaemon;
    // monero_c's Wallet_synchronized is the authoritative "done" flag.
    // We can't rely on syncProgressPct alone — the daemon's tip keeps
    // advancing while we scan, so the ratio asymptotes at 99-something
    // forever. isSynced flips once the wallet decides it's caught up.
    if (!_isSynced) return l.xmrScreenSyncingPct(_syncPct ?? 0);
    return '${_balanceXmr!.toStringAsFixed(9)} ${widget.coin.symbol}';
  }

  /// Manual fallback when the auto self-heal didn't recover the
  /// wallet. Confirms with the user (this wipes the on-disk wallet
  /// file — the chain cache, sync state, and any subaddress labels
  /// are lost) then nukes the dir + re-triggers the open flow,
  /// which now passes through the seed-based re-create path.
  Future<void> _resetWalletAndRetry() async {
    final meta = widget.walletMeta;
    if (meta == null) return;
    final l = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.xmrScreenResetTitle),
        content: Text(l.xmrScreenResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PeekColors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l.xmrScreenResetAction),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    // Close the failed session (if any), then nuke the directory.
    try {
      MoneroSession.I.stopFor(meta.id);
    } catch (_) {/* best effort */}

    final docs = await getApplicationDocumentsDirectory();
    final walletDir = Directory('${docs.path}/peek_xmr/${meta.id}');
    if (walletDir.existsSync()) {
      try {
        walletDir.deleteSync(recursive: true);
      } catch (_) {/* best effort */}
    }

    if (!mounted) return;
    // Reset state + re-run the open flow. The opener will now go
    // through the seed-based re-create path because no file exists.
    setState(() {
      _engineErr = _XmrEngineError.none;
      _engineErrDetail = null;
      _moneroWallet = null;
      _balanceXmr = null;
      _syncPct = null;
      _isSynced = false;
      _currentHeight = 0;
      _tipHeight = 0;
    });
    await _bootMoneroFromMeta(meta);
  }

  Future<void> _refresh() async {
    // Pull-to-refresh on the coin screen — force a daemon refresh +
    // tx history reload. We don't await the actual sync (that could
    // take minutes); just kick monero_c's async refresh and wait a
    // moment so the spinner has time to feel responsive.
    if (_moneroWallet != null) {
      _moneroWallet!.refreshAsync();
      try {
        final fresh = _moneroWallet!.transactions();
        setState(() => _transactions = fresh);
      } catch (_) {/* ignore */}
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loadErrText = _loadErrText(l);
    final engineErrText = _engineErrText(l);
    return Scaffold(
      appBar: AppBar(title: Text(widget.coin.name)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: PeekColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(PeekDesign.sp4, PeekDesign.sp3,
                PeekDesign.sp4, PeekDesign.sp4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    borderRadius: PeekDesign.brHero,
                    gradient: PeekDesign.surfaceGradient,
                    border: Border.all(color: PeekColors.border, width: 1),
                    boxShadow: PeekDesign.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          coinAvatar(widget.coin.id, radius: 22),
                          const SizedBox(width: PeekDesign.sp3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.coin.name,
                                  style: const TextStyle(
                                    color: PeekColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Text(
                                  l.coinScreenBalanceLabel(widget.coin.symbol),
                                  style: const TextStyle(
                                      color: PeekColors.text3,
                                      fontSize: 11,
                                      letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: PeekDesign.sp5),
                      Text(
                        _balanceText(l),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: PriceFeed.I,
                        builder: (_, _) {
                          if (_balanceXmr == null || _balanceXmr == 0) {
                            return const SizedBox(height: 4);
                          }
                          final fiat = PriceFeed.I
                              .formatFiat(widget.coin.id, _balanceXmr!);
                          if (fiat.isEmpty) return const SizedBox(height: 4);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              fiat,
                              style: const TextStyle(
                                  color: PeekColors.text2,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                      // Sync state — pill shows progress %, height
                      // delta, or fully-synced confirmation. The
                      // engine-status banner stays inline below it.
                      if (widget.coin.id == 'XMR') ...[
                        const SizedBox(height: PeekDesign.sp3),
                        _XmrSyncPill(
                          syncPct: _syncPct,
                          currentHeight: _currentHeight,
                          tipHeight: _tipHeight,
                          isSynced: _isSynced,
                          daemonConnected: _daemonConnected,
                          balanceLoaded: _balanceXmr != null,
                        ),
                      ],
                      if (widget.coin.id == 'XMR' &&
                          _engineErr == _XmrEngineError.none &&
                          _daemonError != null) ...[
                        const SizedBox(height: PeekDesign.sp2),
                        StatusPill(
                          text: l.xmrScreenDaemonError(_daemonError!),
                          color: PeekColors.red,
                          icon: Icons.cloud_off_rounded,
                        ),
                      ],
                      if (engineErrText != null) ...[
                        const SizedBox(height: PeekDesign.sp2),
                        StatusPill(
                          text: l.xmrScreenEngineError(engineErrText),
                          color: PeekColors.red,
                          icon: Icons.error_outline_rounded,
                        ),
                        if (widget.coin.id == 'XMR' &&
                            widget.walletMeta != null) ...[
                          const SizedBox(height: PeekDesign.sp3),
                          OutlinedButton.icon(
                            onPressed: _resetWalletAndRetry,
                            icon:
                                const Icon(Icons.restart_alt_rounded, size: 16),
                            label: Text(l.xmrScreenResetAndRescanFromSeed),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PeekColors.red,
                              side: const BorderSide(color: PeekColors.red),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (widget.coin.id == 'XMR') const _EngineStatusBanner(),
                const SizedBox(height: PeekDesign.sp4),
              if (loadErrText != null)
                Container(
                  padding: const EdgeInsets.all(PeekDesign.sp3),
                  decoration: BoxDecoration(
                    color: PeekColors.red.withAlpha(28),
                    borderRadius: PeekDesign.brSmall,
                    border: Border.all(color: PeekColors.red.withAlpha(96)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: PeekColors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loadErrText,
                          style: const TextStyle(
                              color: PeekColors.red,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_address == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: PeekColors.accent),
                  ),
                )
              else ...[
                if (widget.coin.id == 'XMR') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          icon: Icons.qr_code_rounded,
                          label: l.actionReceive,
                          primary: false,
                          onTap: _showReceiveSheet,
                        ),
                      ),
                      const SizedBox(width: PeekDesign.sp3),
                      Expanded(
                        child: ActionButton(
                          icon: Icons.arrow_upward_rounded,
                          label: l.actionSend,
                          primary: true,
                          // Older confirmed outputs (10+ blocks deep)
                          // are spendable mid-sync — Cake does the same.
                          // createTransaction rejects if there really
                          // aren't enough unlocked outputs.
                          onTap: (_moneroWallet != null &&
                                  (_balanceXmr ?? 0) > 0)
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SendXmrScreen(
                                          wallet: _moneroWallet!),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (_moneroWallet != null &&
                      !_isSynced &&
                      (_balanceXmr ?? 0) > 0) ...[
                    const SizedBox(height: PeekDesign.sp3),
                    Container(
                      padding: const EdgeInsets.all(PeekDesign.sp3),
                      decoration: BoxDecoration(
                        color: PeekColors.surface2,
                        borderRadius: PeekDesign.brSmall,
                        border: Border.all(color: PeekColors.hairline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: PeekColors.text3),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.xmrScreenWalletStillSyncing,
                              style: const TextStyle(
                                  color: PeekColors.text3,
                                  fontSize: 11,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: PeekDesign.sp6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(l.xmrScreenActivity,
                          style: const TextStyle(
                              color: PeekColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1)),
                      const SizedBox(width: PeekDesign.sp2),
                      if (_transactions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: PeekColors.surface2,
                            borderRadius: PeekDesign.brPill,
                          ),
                          child: Text(
                            '${_transactions.length}',
                            style: const TextStyle(
                                color: PeekColors.text2,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: PeekDesign.sp3),
                  if (_transactions.isEmpty)
                    EmptyActivity(
                        loading: !_isSynced,
                        coinLabel: widget.coin.symbol)
                  else
                    // Full list — the parent SingleChildScrollView
                    // handles overflow. Removed the previous .take(20)
                    // cap; older TXes were invisible with no way to
                    // page back to them.
                    for (final tx in _transactions)
                      _TxRow(
                        tx: tx,
                        wallet: _moneroWallet,
                        onNoteEdited: () {
                          // Refresh the cached list so the new note
                          // shows on the row without waiting for the
                          // 5-s history-poll tick.
                          if (_moneroWallet != null) {
                            try {
                              final fresh = _moneroWallet!.transactions();
                              setState(() => _transactions = fresh);
                            } catch (_) {/* leave old list */}
                          }
                        },
                      ),
                ] else ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: QrImageView(
                        data: _address!,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(PeekDesign.sp3),
                    decoration: BoxDecoration(
                      color: PeekColors.surface,
                      borderRadius: PeekDesign.brSmall,
                      border: Border.all(color: PeekColors.border),
                    ),
                    child: SelectableText(
                      _address!,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _address!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.xmrScreenAddressCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(l.xmrScreenCopyAddress),
                  ),
                ],
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill shown directly below the XMR balance number with the live
/// sync state. Renders one of:
///   - "Connecting to daemon…" — no daemon yet
///   - "Booting wallet…" — engine still spinning up
///   - "Syncing X% · N blocks behind" — mid-scan
///   - "Synced · height H" — caught up
///   - silence — pre-load, no data yet
class _XmrSyncPill extends StatelessWidget {
  const _XmrSyncPill({
    required this.syncPct,
    required this.currentHeight,
    required this.tipHeight,
    required this.isSynced,
    required this.daemonConnected,
    required this.balanceLoaded,
  });
  final int? syncPct;
  final int currentHeight;
  final int tipHeight;
  final bool isSynced;
  final bool daemonConnected;
  final bool balanceLoaded;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!balanceLoaded) {
      return StatusPill(
        text: l.xmrScreenBootingWallet,
        color: PeekColors.accent,
        icon: Icons.hourglass_top_rounded,
      );
    }
    if (!daemonConnected) {
      return StatusPill(
        text: l.xmrScreenConnectingDaemon,
        color: PeekColors.accent,
        icon: Icons.cloud_sync_rounded,
      );
    }
    if (!isSynced) {
      final behind = tipHeight - currentHeight;
      final pct = syncPct ?? 0;
      final text = tipHeight > 0 && behind > 0
          ? l.xmrScreenSyncingPctBehind(pct, behind)
          : l.xmrScreenSyncingPct(pct);
      return StatusPill(
        text: text,
        color: PeekColors.accent,
        icon: Icons.sync_rounded,
      );
    }
    return StatusPill(
      text: tipHeight > 0
          ? l.xmrScreenSyncedAtHeight(_fmt(tipHeight))
          : l.xmrScreenSynced,
      color: PeekColors.green,
      icon: Icons.check_circle_rounded,
    );
  }

  static String _fmt(int h) {
    final s = h.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({
    required this.tx,
    this.wallet,
    this.onNoteEdited,
  });
  final MoneroTx tx;
  /// When set, the detail sheet shows an "edit note" affordance that
  /// writes through wallet.setUserNote. Pass null for wallets we
  /// can't write back to (closed, watch-only).
  final MoneroWallet? wallet;
  final VoidCallback? onNoteEdited;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = tx.isFailed
        ? PeekColors.red
        : (tx.isIncoming ? PeekColors.green : PeekColors.text);
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.amountXmr.toStringAsFixed(6)} XMR';
    final dt = tx.timestamp.toLocal();
    final dateLabel = _fmtDate(dt);
    final subtitle = tx.isFailed
        ? l.xmrScreenTxStatusFailed
        : tx.isPending
            ? l.xmrScreenTxStatusPending
            : tx.confirmations < 10
                ? l.xmrScreenConfirmationsShort(tx.confirmations)
                : l.xmrScreenTxStatusConfirmed;

    return InkWell(
      onTap: () => _showDetails(context, tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PeekDesign.sp2),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PeekColors.surface2,
                borderRadius: PeekDesign.brSmall,
              ),
              child: Icon(
                tx.isIncoming
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: PeekDesign.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$dateLabel · $subtitle',
                    style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PeekColors.text3, size: 18),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  void _showDetails(BuildContext context, MoneroTx tx) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: PeekColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tx.isIncoming ? l.xmrScreenDirIncoming : l.xmrScreenDirOutgoing,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _kv(l.xmrScreenTxAmount, '${tx.amountXmr.toStringAsFixed(9)} XMR'),
            if (!tx.isIncoming)
              _kv(l.xmrScreenTxFee, '${tx.feeXmr.toStringAsFixed(9)} XMR'),
            _kv(l.xmrScreenTxDate, _fmtDate(tx.timestamp.toLocal())),
            _kv(l.xmrScreenTxBlockHeight,
                tx.blockHeight == 0 ? '—' : tx.blockHeight.toString()),
            _kv(l.xmrScreenTxConfirmations, tx.confirmations.toString()),
            _kv(
              l.xmrScreenTxStatus,
              tx.isFailed
                  ? l.xmrScreenTxStatusFailed
                  : (tx.isPending
                      ? l.xmrScreenTxStatusPending
                      : l.xmrScreenTxStatusConfirmed),
            ),
            if (tx.paymentId.isNotEmpty)
              _kv(l.xmrScreenTxPaymentId, tx.paymentId),
            const SizedBox(height: 12),
            // Note section — editable if a wallet handle was provided.
            // Empty notes show an "Add" prompt; non-empty show the
            // note plus Edit. Saves persist to the on-disk wallet via
            // Wallet_setUserNote.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.xmrScreenTxNote,
                    style: const TextStyle(color: PeekColors.text2, fontSize: 12),
                  ),
                ),
                if (wallet != null)
                  TextButton.icon(
                    onPressed: () => _editNote(ctx),
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(
                      tx.note.isEmpty ? l.xmrScreenTxAdd : l.xmrScreenTxEdit,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PeekDesign.sp3),
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: PeekDesign.brSmall,
                border: Border.all(color: PeekColors.border),
              ),
              child: Text(
                tx.note.isEmpty ? l.xmrScreenNoNote : tx.note,
                style: TextStyle(
                  color: tx.note.isEmpty ? PeekColors.text3 : PeekColors.text,
                  fontSize: 13,
                  fontStyle: tx.note.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            const SizedBox(height: PeekDesign.sp3),
            Text(
              l.xmrScreenTxId,
              style: const TextStyle(
                  color: PeekColors.text3,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(PeekDesign.sp3),
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: PeekDesign.brSmall,
                border: Border.all(color: PeekColors.border),
              ),
              child: SelectableText(
                tx.hash,
                style: const TextStyle(
                    fontSize: 12, fontFamily: 'monospace', color: PeekColors.text),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: tx.hash));
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(l.xmrScreenTxIdCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(l.xmrScreenCopy),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = explorerTxUrl(
                          coinId: 'XMR', txid: tx.hash);
                      if (url == null) return;
                      final ok = await openExplorerUrl(url);
                      if (!ok && ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(l.xmrScreenCouldNotOpenBrowser)));
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l.xmrScreenExplorer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: const TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(BuildContext ctx) async {
    final w = wallet;
    if (w == null) return;
    final l = AppLocalizations.of(ctx);
    final controller = TextEditingController(text: tx.note);
    final updated = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l.xmrScreenTxNoteTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: l.xmrScreenTxNoteHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l.actionCancel),
          ),
          if (tx.note.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(''),
              child: Text(l.xmrScreenClear),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text),
            child: Text(l.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated == null) return;
    try {
      w.setUserNote(txid: tx.hash, note: updated);
      onNoteEdited?.call();
      if (!ctx.mounted) return;
      // The detail sheet is already open — close it so the user sees
      // the refreshed note when they tap the row again. (Updating in
      // place would mean rebuilding the sheet which is harder.)
      Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
              updated.isEmpty ? l.xmrScreenNoteCleared : l.xmrScreenNoteSaved),
        ),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(l.xmrScreenCouldNotSaveNote(e.toString()))),
      );
    }
  }
}

/// Cake-style receive sheet: shows the currently-selected subaddress
/// at the top (QR + copy), then a list of all generated subaddresses
/// below with a "+ New" button to mint a fresh one.
///
/// Privacy note baked into the UI: a fresh subaddress per payer means
/// observers can't link two payments to the same wallet. Index 0 is
/// the always-present primary address.
class _ReceiveSheet extends StatefulWidget {
  const _ReceiveSheet({required this.wallet, required this.primaryAddress});
  final MoneroWallet? wallet;
  final String primaryAddress;

  @override
  State<_ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<_ReceiveSheet> {
  /// Index of the subaddress currently displayed (QR + address text).
  /// Starts on the highest-index one — most recently generated is
  /// usually what the user wants to share.
  int _selectedIndex = 0;
  List<_SubaddrRow> _rows = const [];
  bool _generating = false;
  String? _genError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final w = widget.wallet;
    final primaryLabel =
        AppLocalizations.of(context).xmrScreenLabelPrimary;
    if (w == null) {
      // No live engine — only the primary address from pure-Dart
      // derivation is available. Still useful for receive.
      _rows = [
        _SubaddrRow(
          index: 0,
          address: widget.primaryAddress,
          label: primaryLabel,
        ),
      ];
      _selectedIndex = 0;
      return;
    }
    final n = w.subaddressCount;
    final rows = <_SubaddrRow>[];
    for (var i = 0; i < n; i++) {
      rows.add(_SubaddrRow(
        index: i,
        address: w.subaddress(i),
        label: i == 0
            ? primaryLabel
            : (() {
                final lbl = w.subaddressLabel(i);
                return lbl.isEmpty ? '' : lbl;
              })(),
      ));
    }
    setState(() {
      _rows = rows;
      // Keep the user's current selection if still valid; otherwise
      // jump to the newest row.
      if (_selectedIndex >= rows.length) {
        _selectedIndex = rows.length - 1;
      }
    });
  }

  Future<void> _generate() async {
    final w = widget.wallet;
    if (w == null) return;
    setState(() {
      _generating = true;
      _genError = null;
    });
    try {
      w.addSubaddress();
      _reload();
      // Jump the visible address + QR to the freshly-generated one.
      setState(() => _selectedIndex = _rows.length - 1);
    } catch (e) {
      setState(() => _genError = e.toString());
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _editLabel(_SubaddrRow row) async {
    final w = widget.wallet;
    if (w == null) return;
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: row.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.xmrScreenLabelSubaddress(row.index)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: l.xmrScreenSubaddrLabelHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.actionCancel),
          ),
          if (row.label.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: Text(l.xmrScreenClear),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newLabel == null) return;
    try {
      w.setSubaddressLabel(index: row.index, label: newLabel);
      _reload();
    } catch (e) {
      setState(() => _genError = l.xmrScreenCouldNotSaveLabel(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final selected = _rows.isEmpty
        ? widget.primaryAddress
        : _rows[_selectedIndex.clamp(0, _rows.length - 1)].address;
    final live = widget.wallet != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: PeekColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.xmrScreenReceiveTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: selected,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: PeekDesign.sp3),
              Container(
                padding: const EdgeInsets.all(PeekDesign.sp3),
                decoration: BoxDecoration(
                  color: PeekColors.surface,
                  borderRadius: PeekDesign.brSmall,
                  border: Border.all(color: PeekColors.border),
                ),
                child: SelectableText(
                  selected,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: selected));
                  messenger.showSnackBar(
                    SnackBar(content: Text(l.xmrScreenAddressCopied)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l.xmrScreenCopyAddress),
              ),
              if (!live) ...[
                const SizedBox(height: 12),
                Text(
                  l.xmrScreenSubaddrUnavailable,
                  style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                ),
              ] else ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.xmrScreenSubaddrSectionTitle,
                        style: const TextStyle(color: PeekColors.text2, fontSize: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: PeekColors.accent))
                          : const Icon(Icons.add, size: 16),
                      label: Text(l.xmrScreenSubaddrNew),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l.xmrScreenSubaddrBody,
                  style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                ),
                const SizedBox(height: 8),
                if (_genError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _genError!,
                      style: const TextStyle(color: PeekColors.red, fontSize: 11),
                    ),
                  ),
                for (final row in _rows.reversed)
                  _SubaddrTile(
                    row: row,
                    isSelected: row.index == _selectedIndex,
                    onTap: () => setState(() => _selectedIndex = row.index),
                    onLabelEdit: row.index == 0
                        ? null // Primary address is unlabelable
                        : () => _editLabel(row),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubaddrRow {
  const _SubaddrRow({
    required this.index,
    required this.address,
    required this.label,
  });
  final int index;
  final String address;
  final String label;
}

class _SubaddrTile extends StatelessWidget {
  const _SubaddrTile({
    required this.row,
    required this.isSelected,
    required this.onTap,
    this.onLabelEdit,
  });
  final _SubaddrRow row;
  final bool isSelected;
  final VoidCallback onTap;
  /// When non-null, long-press on the tile opens the label editor.
  /// Null for the primary address (which can't be renamed).
  final VoidCallback? onLabelEdit;

  @override
  Widget build(BuildContext context) {
    // First 6 and last 4 chars so each tile renders one line on phones.
    final addr = row.address;
    final short = addr.length > 14
        ? '${addr.substring(0, 6)}…${addr.substring(addr.length - 6)}'
        : addr;
    return InkWell(
      onTap: onTap,
      onLongPress: onLabelEdit,
      borderRadius: PeekDesign.brSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? PeekColors.surface2 : PeekColors.surface,
          borderRadius: PeekDesign.brSmall,
          border: Border.all(
            color: isSelected ? PeekColors.accent : PeekColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? PeekColors.accent : PeekColors.bg2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${row.index}',
                style: TextStyle(
                  color: isSelected ? Colors.white : PeekColors.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (row.label.isNotEmpty)
                    Text(
                      row.label,
                      style: const TextStyle(
                        color: PeekColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    short,
                    style: TextStyle(
                      color: row.label.isEmpty ? PeekColors.text : PeekColors.text3,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (onLabelEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                color: PeekColors.text3,
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context).xmrScreenEditLabelTooltip,
                onPressed: onLabelEdit,
              ),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              color: isSelected ? PeekColors.accent : PeekColors.text3,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sanity check: shows whether libmonero_wallet2_api_c.so loaded on
/// this device.
class _EngineStatusBanner extends StatelessWidget {
  const _EngineStatusBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = MoneroEngine.I.status();
    final color = s.loaded ? PeekColors.green : PeekColors.red;
    final label = s.loaded
        ? l.xmrScreenEngineLoaded
        : l.xmrScreenEngineNotLoaded(s.error ?? '');
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
