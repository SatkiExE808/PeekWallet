import 'package:flutter/material.dart';

import '../coins/coin_module.dart';
import '../coins/module_registry.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
import '../vault/vault_state.dart';
import '../wallets/seed_format.dart';
import '../wallets/wallet_store.dart';

/// One-tap "Restore every coin from my vault seed" flow.
///
/// Closes the UX trap where `Add wallet → Generate new` created a
/// fresh random seed per wallet, leaving the vault's 12-word seed
/// useless as a backup for those wallets. The right model is the
/// one MetaMask / Trust Wallet / Phantom use: a single BIP39 seed
/// covers every coin via standard BIP44 derivation paths.
///
/// This screen takes the unlocked vault mnemonic and, for each
/// supported coin that doesn't already have a wallet, calls the
/// coin module's restoreFrom(BIP39) and adds the resulting entry
/// to the WalletStore. Same seed → same addresses every time, so
/// after a future vault-restore the user can re-run this flow and
/// get exactly the same wallets back.
class RestoreAllFromVaultScreen extends StatefulWidget {
  const RestoreAllFromVaultScreen({super.key});

  @override
  State<RestoreAllFromVaultScreen> createState() =>
      _RestoreAllFromVaultScreenState();
}

class _RestoreAllFromVaultScreenState
    extends State<RestoreAllFromVaultScreen> {
  bool _busy = false;
  String? _err;
  final Map<String, _CoinStatus> _status = {};
  Set<String> _existingCoinIds = const {};

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final list = await WalletStore.I.list();
    setState(() {
      _existingCoinIds = list.map((m) => m.coinId).toSet();
    });
  }

  /// Coins we'll try to derive. Every CoinModule in the registry
  /// EXCEPT XMR — Monero gets its own per-coin treatment because
  /// the legacy single-wallet boot path already manages a Monero
  /// wallet from the vault seed via the BIP39 derivation. Adding
  /// a SECOND XMR wallet here would just create a duplicate.
  List<CoinModule> get _targetCoins => kCoinModules
      .where((m) => m.id != 'XMR')
      .where((m) =>
          m.supportedRestoreFormats.contains(SeedFormat.bip39_12) ||
          m.supportedRestoreFormats.contains(SeedFormat.bip39_24))
      .toList();

  Future<void> _run() async {
    final mnemonic = VaultState.I.mnemonic;
    final cachedPwd = VaultState.I.cachedPassword;
    if (mnemonic == null || cachedPwd == null) {
      setState(() => _err =
          'Vault is locked. Unlock and try again.');
      return;
    }

    setState(() {
      _busy = true;
      _err = null;
      for (final c in _targetCoins) {
        _status[c.id] = _CoinStatus.queued;
      }
    });

    // Determine the seed format that matches the vault's mnemonic
    // word count. Most vaults are 12 words; some users might've
    // imported a 24-word phrase.
    final words = mnemonic.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final format =
        words.length == 24 ? SeedFormat.bip39_24 : SeedFormat.bip39_12;

    for (final coin in _targetCoins) {
      if (_existingCoinIds.contains(coin.id)) {
        setState(() => _status[coin.id] = _CoinStatus.skipped);
        continue;
      }
      setState(() => _status[coin.id] = _CoinStatus.running);

      try {
        final id = WalletStore.I.generateId();
        final walletFilePwd =
            await WalletStore.I.deriveWalletFilePassword(cachedPwd, id);

        final material = await coin.restoreFrom(
          walletId: id,
          format: format,
          input: {
            'seed': mnemonic,
            'mnemonic': mnemonic,
            'passphrase': '',
          },
          walletFilePassword: walletFilePwd,
        );

        await WalletStore.I.create(
          withId: id,
          name: '${coin.name} wallet',
          coinId: coin.id,
          format: format,
          seedMaterial: material.seedMaterial,
          password: cachedPwd,
          primaryAddress: material.primaryAddress,
          restoreHeight: material.restoreHeight,
        );

        setState(() => _status[coin.id] = _CoinStatus.done);
      } catch (e) {
        setState(() => _status[coin.id] = _CoinStatus.failed);
      }
    }

    if (!mounted) return;
    setState(() => _busy = false);
    await _loadExisting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore all coins from vault')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(PeekDesign.sp4,
              PeekDesign.sp4, PeekDesign.sp4, PeekDesign.sp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(PeekDesign.sp4),
                decoration: BoxDecoration(
                  borderRadius: PeekDesign.brCard,
                  gradient: PeekDesign.surfaceGradient,
                  border: Border.all(color: PeekColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: PeekColors.accentMuted,
                        borderRadius: PeekDesign.brSmall,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          size: 18, color: PeekColors.accent),
                    ),
                    const SizedBox(width: PeekDesign.sp3),
                    const Expanded(
                      child: Text(
                        'Adds a wallet for every supported coin, derived '
                        'from your vault\'s recovery phrase. Same seed → '
                        'same addresses every time, so your vault seed '
                        'becomes the single backup for all of them.',
                        style: TextStyle(
                            color: PeekColors.text2,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PeekDesign.sp3),
              Container(
                padding: const EdgeInsets.all(PeekDesign.sp3),
                decoration: BoxDecoration(
                  color: PeekColors.surface2,
                  borderRadius: PeekDesign.brSmall,
                  border: Border.all(color: PeekColors.hairline),
                ),
                child: const Text(
                  'Existing wallets are skipped (no duplicates). Monero '
                  'is handled separately via the legacy single-wallet '
                  'flow from the same seed.',
                  style: TextStyle(
                      color: PeekColors.text3,
                      fontSize: 11,
                      height: 1.4),
                ),
              ),
              const SizedBox(height: PeekDesign.sp5),
              Expanded(
                child: ListView(
                  children: [
                    for (final coin in _targetCoins)
                      _coinRow(coin),
                  ],
                ),
              ),
              if (_err != null) ...[
                const SizedBox(height: 8),
                Text(_err!,
                    style: const TextStyle(
                        color: PeekColors.red, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _run,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Restore all from vault seed'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coinRow(CoinModule coin) {
    final status =
        _status[coin.id] ?? _CoinStatus.idle;
    final existing = _existingCoinIds.contains(coin.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          coinAvatar(coin.id, radius: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coin.name,
                    style: const TextStyle(
                        color: PeekColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                  existing
                      ? 'Already have a ${coin.symbol} wallet — skip'
                      : 'Will derive from BIP39 vault seed',
                  style: const TextStyle(
                      color: PeekColors.text3, fontSize: 11),
                ),
              ],
            ),
          ),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _statusBadge(_CoinStatus status) {
    switch (status) {
      case _CoinStatus.idle:
      case _CoinStatus.queued:
        return const SizedBox(width: 20);
      case _CoinStatus.running:
        return const SizedBox(
          width: 18,
          height: 18,
          child:
              CircularProgressIndicator(strokeWidth: 2),
        );
      case _CoinStatus.done:
        return const Icon(Icons.check_circle,
            color: PeekColors.green, size: 20);
      case _CoinStatus.skipped:
        return const Icon(Icons.skip_next,
            color: PeekColors.text3, size: 20);
      case _CoinStatus.failed:
        return const Icon(Icons.error_outline,
            color: PeekColors.red, size: 20);
    }
  }
}

enum _CoinStatus { idle, queued, running, done, skipped, failed }
