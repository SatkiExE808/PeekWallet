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
  String? _error;

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
  String? _engineError;
  List<MoneroTx> _transactions = const [];
  MoneroWallet? _moneroWallet;

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
          setState(() => _engineError = engine.error);
          return;
        }
        await _bootMoneroFromMeta(widget.walletMeta!);
      }
      return;
    }

    // Legacy single-wallet mode (vault-wallet-style unified seed).
    final mn = VaultState.I.mnemonic;
    if (mn == null) {
      setState(() => _error = 'Wallet is locked');
      return;
    }
    try {
      final a = await widget.coin.deriveAddress(mn);
      setState(() => _address = a);
    } catch (e) {
      setState(() => _error = 'Address derivation failed: $e');
    }

    if (widget.coin.id == 'XMR' && moneroNativeAvailable()) {
      final engine = MoneroEngine.I.status();
      if (!engine.loaded) {
        setState(() => _engineError = engine.error);
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
      setState(() => _engineError = 'Vault locked — wallet password unavailable');
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
        setState(() => _engineError = 'Password required to open this wallet');
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
      setState(() => _engineError = 'Could not open wallet: $e');
      return;
    }

    final coin = coinModuleFor(meta.coinId);
    if (coin == null) {
      stageTicker.cancel();
      setState(() => _engineError = 'Unknown coin: ${meta.coinId}');
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
      setState(() =>
          _engineError = MoneroSession.I.lastErrorFor(meta.id) ?? 'unknown');
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
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock wallet'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'App password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Open'),
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
      setState(() => _engineError = 'Vault locked — wallet password unavailable');
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
      setState(() => _engineError = MoneroSession.I.lastError ?? 'unknown');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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

  String _balanceText() {
    if (widget.coin.id != 'XMR') return '… ${widget.coin.symbol}';
    if (_engineError != null) return '… ${widget.coin.symbol}';
    if (_balanceXmr == null) {
      final s = MoneroSession.I.stage;
      return s == null ? '… ${widget.coin.symbol}' : 'Boot: $s';
    }
    if (!_daemonConnected) return 'Connecting to daemon…';
    // monero_c's Wallet_synchronized is the authoritative "done" flag.
    // We can't rely on syncProgressPct alone — the daemon's tip keeps
    // advancing while we scan, so the ratio asymptotes at 99-something
    // forever. isSynced flips once the wallet decides it's caught up.
    if (!_isSynced) return 'Syncing ${_syncPct ?? 0}%';
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
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset wallet file?'),
        content: const Text(
          'This deletes the on-disk wallet file and recreates it from '
          'your stored seed. The chain-sync cache is lost so the wallet '
          'will need to rescan from your restore height (could take a '
          'while). Your seed is NOT touched — funds are safe.\n\n'
          'Use this if you\'re stuck with a persistent "invalid '
          'password" error.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PeekColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset & rescan'),
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
      _engineError = null;
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
                                  '${widget.coin.symbol} balance',
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
                        _balanceText(),
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
                          _engineError == null &&
                          _daemonError != null) ...[
                        const SizedBox(height: PeekDesign.sp2),
                        StatusPill(
                          text: 'Daemon: $_daemonError',
                          color: PeekColors.red,
                          icon: Icons.cloud_off_rounded,
                        ),
                      ],
                      if (_engineError != null) ...[
                        const SizedBox(height: PeekDesign.sp2),
                        StatusPill(
                          text: 'Engine: $_engineError',
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
                            label: const Text('Reset & rescan from seed'),
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
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x33EF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: PeekColors.text)),
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
                          label: 'Receive',
                          primary: false,
                          onTap: _showReceiveSheet,
                        ),
                      ),
                      const SizedBox(width: PeekDesign.sp3),
                      Expanded(
                        child: ActionButton(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Send',
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
                        children: const [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: PeekColors.text3),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Wallet is still syncing — newer activity '
                              'may be missing. Older confirmed outputs '
                              'are still spendable.',
                              style: TextStyle(
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
                      const Text('Activity',
                          style: TextStyle(
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PeekColors.surface,
                      borderRadius: BorderRadius.circular(10),
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
                        const SnackBar(content: Text('Address copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy address'),
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
    if (!balanceLoaded) {
      return StatusPill(
        text: 'Booting wallet…',
        color: PeekColors.accent,
        icon: Icons.hourglass_top_rounded,
      );
    }
    if (!daemonConnected) {
      return StatusPill(
        text: 'Connecting to daemon…',
        color: PeekColors.accent,
        icon: Icons.cloud_sync_rounded,
      );
    }
    if (!isSynced) {
      final behind = tipHeight - currentHeight;
      final pct = syncPct ?? 0;
      final tail = tipHeight > 0 && behind > 0
          ? ' · $behind blocks behind'
          : '';
      return StatusPill(
        text: 'Syncing $pct%$tail',
        color: PeekColors.accent,
        icon: Icons.sync_rounded,
      );
    }
    return StatusPill(
      text: tipHeight > 0
          ? 'Synced · height ${_fmt(tipHeight)}'
          : 'Synced',
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
    final color = tx.isFailed
        ? PeekColors.red
        : (tx.isIncoming ? PeekColors.green : PeekColors.text);
    final sign = tx.isIncoming ? '+' : '−';
    final amount = '$sign${tx.amountXmr.toStringAsFixed(6)} XMR';
    final dt = tx.timestamp.toLocal();
    final dateLabel = _fmtDate(dt);
    final subtitle = tx.isFailed
        ? 'Failed'
        : tx.isPending
            ? 'Pending'
            : tx.confirmations < 10
                ? '${tx.confirmations} conf'
                : 'Confirmed';

    return InkWell(
      onTap: () => _showDetails(context, tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                tx.isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              tx.isIncoming ? 'Incoming' : 'Outgoing',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _kv('Amount', '${tx.amountXmr.toStringAsFixed(9)} XMR'),
            if (!tx.isIncoming)
              _kv('Fee', '${tx.feeXmr.toStringAsFixed(9)} XMR'),
            _kv('Date', _fmtDate(tx.timestamp.toLocal())),
            _kv('Block height', tx.blockHeight == 0 ? '—' : tx.blockHeight.toString()),
            _kv('Confirmations', tx.confirmations.toString()),
            _kv('Status', tx.isFailed ? 'Failed' : (tx.isPending ? 'Pending' : 'Confirmed')),
            if (tx.paymentId.isNotEmpty)
              _kv('Payment ID', tx.paymentId),
            const SizedBox(height: 12),
            // Note section — editable if a wallet handle was provided.
            // Empty notes show an "Add" prompt; non-empty show the
            // note plus Edit. Saves persist to the on-disk wallet via
            // Wallet_setUserNote.
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Note',
                    style: TextStyle(color: PeekColors.text2, fontSize: 12),
                  ),
                ),
                if (wallet != null)
                  TextButton.icon(
                    onPressed: () => _editNote(ctx),
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(
                      tx.note.isEmpty ? 'Add' : 'Edit',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PeekColors.border),
              ),
              child: Text(
                tx.note.isEmpty ? '— No note —' : tx.note,
                style: TextStyle(
                  color: tx.note.isEmpty ? PeekColors.text3 : PeekColors.text,
                  fontSize: 13,
                  fontStyle: tx.note.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('TX ID', style: TextStyle(color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PeekColors.border),
              ),
              child: SelectableText(
                tx.hash,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
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
                        const SnackBar(content: Text('TX ID copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
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
                            const SnackBar(
                                content: Text('Could not open browser')));
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Explorer'),
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
    final controller = TextEditingController(text: tx.note);
    final updated = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Transaction note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Free-text — only you can read this.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          if (tx.note.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(''),
              child: const Text('Clear'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text),
            child: const Text('Save'),
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
          content: Text(updated.isEmpty ? 'Note cleared' : 'Note saved'),
        ),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Could not save note: $e')),
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
    if (w == null) {
      // No live engine — only the primary address from pure-Dart
      // derivation is available. Still useful for receive.
      _rows = [
        _SubaddrRow(
          index: 0,
          address: widget.primaryAddress,
          label: 'Primary',
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
            ? 'Primary'
            : (() {
                final l = w.subaddressLabel(i);
                return l.isEmpty ? '' : l;
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
    final controller = TextEditingController(text: row.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Label subaddress #${row.index}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: 'e.g. "Customer payments", "Side gig"',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          if (row.label.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: const Text('Clear'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
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
      setState(() => _genError = 'Could not save label: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Receive XMR',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PeekColors.surface,
                  borderRadius: BorderRadius.circular(10),
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
                    const SnackBar(content: Text('Address copied')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy address'),
              ),
              if (!live) ...[
                const SizedBox(height: 12),
                const Text(
                  'Subaddresses unavailable until the wallet finishes booting.',
                  style: TextStyle(color: PeekColors.text3, fontSize: 11),
                ),
              ] else ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Subaddresses',
                        style: TextStyle(color: PeekColors.text2, fontSize: 12),
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
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Generate a fresh address per payer so observers can\'t link two payments to the same wallet. All point to the same balance.',
                  style: TextStyle(color: PeekColors.text3, fontSize: 11),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? PeekColors.surface2 : PeekColors.surface,
          borderRadius: BorderRadius.circular(8),
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
                tooltip: 'Edit label',
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
    final s = MoneroEngine.I.status();
    final color = s.loaded ? PeekColors.green : PeekColors.red;
    final label = s.loaded
        ? '✓ Native monero_c engine loaded'
        : '✗ Engine not loaded: ${s.error}';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
