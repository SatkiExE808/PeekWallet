import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../util/screenshot_guard.dart';
import '../util/sensitive_clipboard.dart';
import '../wallets/seed_format.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';

/// Per-wallet "show recovery phrase" screen.
///
/// Important: this is what every multi-wallet user needs to back up
/// — the vault's 12-word seed does NOT restore these wallets.
/// Each wallet has its own seed (BIP39, monero 25-word, polyseed, or
/// keys-only) stored encrypted in WalletStore under the master
/// password.
///
/// We force a password re-prompt before revealing so a shoulder-surfer
/// who grabbed the unlocked phone can't just open Settings → reveal.
/// FLAG_SECURE blocks screenshots of the seed and the recents
/// thumbnail.
class ShowWalletSeedScreen extends StatefulWidget {
  const ShowWalletSeedScreen({super.key, required this.walletMeta});
  final WalletMeta walletMeta;

  @override
  State<ShowWalletSeedScreen> createState() => _ShowWalletSeedScreenState();
}

class _ShowWalletSeedScreenState extends State<ShowWalletSeedScreen> {
  final _pwd = TextEditingController();
  bool _busy = false;
  String? _err;
  Map<String, dynamic>? _material;

  @override
  void dispose() {
    _pwd.dispose();
    // Overwrite the in-memory seed map before releasing the State.
    // Dart can't zero a String, but clearing the map lets the
    // garbage collector reclaim sooner instead of leaving the
    // mnemonic in heap until the screen is GC'd.
    final m = _material;
    if (m != null) {
      for (final key in m.keys.toList()) {
        m[key] = '';
      }
      m.clear();
      _material = null;
    }
    super.dispose();
  }

  Future<void> _reveal() async {
    setState(() {
      _err = null;
      _busy = true;
    });
    try {
      final decrypted = await WalletStore.I.open(
        walletId: widget.walletMeta.id,
        password: _pwd.text,
      );
      setState(() {
        _material = decrypted.seedMaterial;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
        _pwd.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ScreenshotGuard(
      child: Scaffold(
        appBar: AppBar(
            title: Text(l.showSeedTitle(widget.walletMeta.name))),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _material == null ? _passwordForm() : _seedView(),
          ),
        ),
      ),
    );
  }

  Widget _passwordForm() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.showSeedPasswordPrompt,
          style: const TextStyle(color: PeekColors.text2, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pwd,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(labelText: l.showSeedPasswordLabel),
          onSubmitted: (_) => _reveal(),
        ),
        if (_err != null) ...[
          const SizedBox(height: 10),
          Text(_err!,
              style: const TextStyle(color: PeekColors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _busy ? null : _reveal,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(l.showSeedRevealAction),
        ),
      ],
    );
  }

  Widget _seedView() {
    final l = AppLocalizations.of(context);
    final material = _material!;
    final String seed = (material['seed'] ??
            material['mnemonic'] ??
            '(no seed — keys-only wallet)') as String;
    final String? passphrase = material['passphrase'] as String?;
    final String? seedOffset = material['seedOffset'] as String?;

    final String? address = material['address'] as String?;
    final String? spendKey = material['spendKey'] as String?;
    final String? viewKey = material['viewKey'] as String?;

    return ListView(
      children: [
        _warningBanner(),
        const SizedBox(height: 16),
        _formatBadge(),
        const SizedBox(height: 12),
        if (seed != '(no seed — keys-only wallet)') ...[
          Text(l.showSeedRecoveryPhrase,
              style: const TextStyle(
                  color: PeekColors.text2, fontSize: 12)),
          const SizedBox(height: 6),
          _seedBox(seed),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l.showSeedCopyPhrase),
                  onPressed: () async {
                    await SensitiveClipboard.copy(seed,
                        label: 'wallet seed');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(l.showSeedCopyClipboardClears)),
                    );
                  },
                ),
              ),
            ],
          ),
          if (passphrase != null && passphrase.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l.showSeedPassphraseSection,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 6),
            _seedBox(passphrase),
          ],
          if (seedOffset != null && seedOffset.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l.showSeedSeedOffsetSection,
                style: const TextStyle(
                    color: PeekColors.text2, fontSize: 12)),
            const SizedBox(height: 6),
            _seedBox(seedOffset),
          ],
        ],
        if (address != null) ...[
          _kv(l.showSeedAddressLabel, address),
          if (viewKey != null) _kv(l.showSeedViewKeyLabel, viewKey),
          if (spendKey != null) _kv(l.showSeedSpendKeyLabel, spendKey),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(l.showSeedCopySpendKey),
            onPressed: spendKey == null
                ? null
                : () => SensitiveClipboard.copy(spendKey,
                    label: 'monero spend key'),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l.showSeedStorageFooter(
              widget.walletMeta.format.displayName,
              widget.walletMeta.coinId),
          style:
              const TextStyle(color: PeekColors.text3, fontSize: 11),
        ),
      ],
    );
  }

  Widget _warningBanner() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PeekDesign.sp4),
      decoration: BoxDecoration(
        color: PeekColors.red.withAlpha(28),
        border: Border.all(color: PeekColors.red.withAlpha(96)),
        borderRadius: PeekDesign.brCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PeekColors.red.withAlpha(40),
              borderRadius: PeekDesign.brSmall,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: PeekColors.red, size: 18),
          ),
          const SizedBox(width: PeekDesign.sp3),
          Expanded(
            child: Text(
              l.showSeedWriteDownWarning,
              style: const TextStyle(
                  color: PeekColors.text, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatBadge() {
    final l = AppLocalizations.of(context);
    final f = widget.walletMeta.format;
    // Format labels mix technical naming conventions (BIP39 / Polyseed
    // / Monero) that map 1:1 to terms developers + other wallets use
    // — keeping the technical names recognisable across languages
    // beats translating them. Only the "Keys only" case (which isn't
    // a standard term) gets localized.
    final label = switch (f) {
      SeedFormat.bip39_12 => '12-word BIP39',
      SeedFormat.bip39_24 => '24-word BIP39',
      SeedFormat.monero25 => '25-word Monero',
      SeedFormat.moneroPolyseed => '14-word Polyseed',
      SeedFormat.keysOnly => l.showSeedKeysOnlyDisplay,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: PeekColors.surface2,
        borderRadius: PeekDesign.brPill,
        border: Border.all(color: PeekColors.border),
      ),
      child: Text(label,
          style: const TextStyle(
              color: PeekColors.text2,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _seedBox(String value) {
    return GestureDetector(
      onLongPress: () => SensitiveClipboard.copy(value,
          label: 'wallet seed'),
      child: Container(
        padding: const EdgeInsets.all(PeekDesign.sp4),
        decoration: BoxDecoration(
          color: PeekColors.surface,
          border: Border.all(color: PeekColors.border),
          borderRadius: PeekDesign.brCard,
        ),
        child: SelectableText(
          value,
          style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.6,
              color: PeekColors.text),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style:
                  const TextStyle(color: PeekColors.text2, fontSize: 12)),
          const SizedBox(height: 4),
          GestureDetector(
            onLongPress: () => SensitiveClipboard.copy(v, label: k),
            child: SelectableText(v,
                style: const TextStyle(
                    color: PeekColors.text,
                    fontSize: 12,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
