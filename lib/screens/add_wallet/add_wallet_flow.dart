import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../coins/coin_module.dart';
import '../../coins/module_registry.dart';
import '../../theme.dart';
import '../../util/screenshot_guard.dart';
import '../../util/sensitive_clipboard.dart';
import '../../vault/vault_state.dart';
import '../../wallets/seed_format.dart';
import '../../wallets/wallet_store.dart';
import '../qr_scan_screen.dart';

enum WalletAddMode { create, restore }

/// Multi-step flow for adding a new wallet:
///   1. Pick coin (skipped when only one coin is registered)
///   2. Pick action — Create new / Restore from seed / Restore from keys
///   3. Pick seed format (depending on action + coin)
///   4. Format-specific input or seed-display step
///   5. Save under a user-chosen name with master-password confirm
class AddWalletFlow extends StatelessWidget {
  const AddWalletFlow({super.key});

  @override
  Widget build(BuildContext context) {
    if (kCoinModules.length == 1) {
      return AddWalletActionPicker(coin: kCoinModules.first);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Choose coin')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: kCoinModules.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final c = kCoinModules[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.color,
                  child: Icon(c.icon, color: Colors.white),
                ),
                title: Text(c.name),
                subtitle: Text(c.symbol,
                    style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: PeekColors.text3),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddWalletActionPicker(coin: c)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddWalletActionPicker extends StatelessWidget {
  const AddWalletActionPicker({super.key, required this.coin});
  final CoinModule coin;

  @override
  Widget build(BuildContext context) {
    final hasKeysOnly = coin.supportedRestoreFormats.contains(SeedFormat.keysOnly);
    return Scaffold(
      appBar: AppBar(title: Text('Add ${coin.name} wallet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _ActionTile(
              icon: Icons.add_circle_outline,
              title: 'Create new wallet',
              subtitle: 'Generate a fresh seed phrase. Anyone with the phrase '
                  'can spend the wallet — write it down on paper.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddWalletFormatPicker(
                    coin: coin,
                    mode: WalletAddMode.create,
                    formats: coin.supportedCreateFormats,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.restore,
              title: 'Restore from seed',
              subtitle: 'Use a recovery phrase you already have '
                  '(BIP39 12/24 words, Monero 25-word seed, or Polyseed 14 words).',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddWalletFormatPicker(
                    coin: coin,
                    mode: WalletAddMode.restore,
                    formats: coin.supportedRestoreFormats
                        .where((f) => f != SeedFormat.keysOnly)
                        .toList(),
                  ),
                ),
              ),
            ),
            if (hasKeysOnly) ...[
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.key,
                title: 'Restore from keys',
                subtitle: 'Address + private spend key + private view key. '
                    'Use this when you have the keys but not a seed phrase.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddWalletKeysRestoreScreen(coin: coin),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: PeekColors.accent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
        ),
        trailing: const Icon(Icons.chevron_right, color: PeekColors.text3),
        onTap: onTap,
      ),
    );
  }
}

class AddWalletFormatPicker extends StatelessWidget {
  const AddWalletFormatPicker({
    super.key,
    required this.coin,
    required this.mode,
    required this.formats,
  });
  final CoinModule coin;
  final WalletAddMode mode;
  final List<SeedFormat> formats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mode == WalletAddMode.create
            ? 'New seed format'
            : 'Restore format'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: formats.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final f = formats[i];
            return Card(
              child: ListTile(
                title: Text(f.displayName),
                subtitle: Text(_subtitleFor(f),
                    style: const TextStyle(color: PeekColors.text2, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, color: PeekColors.text3),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => mode == WalletAddMode.create
                        ? AddWalletCreateScreen(coin: coin, format: f)
                        : AddWalletRestoreScreen(coin: coin, format: f),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _subtitleFor(SeedFormat f) {
    switch (f) {
      case SeedFormat.bip39_12:
        return '12 words — same format as vault-wallet, Trust Wallet, '
            'Trezor, Ledger. Universal across many coins.';
      case SeedFormat.bip39_24:
        return '24 words — more entropy than 12. Same universal format.';
      case SeedFormat.monero25:
        return 'Native Monero electrum-style seed. Direct interop with '
            'Cake, Feather, and Monero GUI.';
      case SeedFormat.moneroPolyseed:
        return 'Newer Monero standard — 14 words. Restore height baked in.';
      case SeedFormat.keysOnly:
        return 'Spend key + view key + address. No words.';
    }
  }
}

// ── Create flow ───────────────────────────────────────────────

class AddWalletCreateScreen extends StatefulWidget {
  const AddWalletCreateScreen({
    super.key,
    required this.coin,
    required this.format,
  });
  final CoinModule coin;
  final SeedFormat format;

  @override
  State<AddWalletCreateScreen> createState() => _AddWalletCreateScreenState();
}

class _AddWalletCreateScreenState extends State<AddWalletCreateScreen> {
  bool _busy = false;
  String? _err;
  NewWalletMaterial? _generated;
  String? _walletId;

  Future<void> _generate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    // The wallet-file password MUST be the same value that
    // WalletStore.open() will compute later when reopening this
    // wallet. Derive it from (master password, walletId) — both
    // available here, both stable.
    final cachedPwd = VaultState.I.cachedPassword;
    if (cachedPwd == null) {
      setState(() {
        _err = 'Vault is locked — re-unlock and try again.';
        _busy = false;
      });
      return;
    }
    final id = WalletStore.I.generateId();
    final pwd =
        await WalletStore.I.deriveWalletFilePassword(cachedPwd, id);
    try {
      final mat = await widget.coin.generateNew(
        walletId: id,
        format: widget.format,
        walletFilePassword: pwd,
      );
      setState(() {
        _generated = mat;
        _walletId = id;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _confirmAndSave(String name) async {
    if (_generated == null || _walletId == null) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    final password = await _promptPassword(context);
    if (password == null) {
      setState(() => _busy = false);
      return;
    }
    try {
      await WalletStore.I.create(
        withId: _walletId!,
        name: name.trim().isEmpty ? '${widget.coin.name} wallet' : name.trim(),
        coinId: widget.coin.id,
        format: widget.format,
        seedMaterial: _generated!.seedMaterial,
        password: password,
        primaryAddress: _generated!.primaryAddress,
        restoreHeight: _generated!.restoreHeight,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generated == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.format.displayName)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.privacy_tip, size: 64, color: PeekColors.accent),
                const SizedBox(height: 12),
                Text(
                  'Generate a ${widget.format.displayName.toLowerCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'When you tap Generate, the words will appear once. '
                  'Write them down on paper before continuing. Anyone with '
                  'the words can take your funds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PeekColors.text2, fontSize: 13),
                ),
                if (_err != null) ...[
                  const SizedBox(height: 12),
                  Text(_err!,
                      style: const TextStyle(color: PeekColors.red, fontSize: 13)),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: _busy ? null : _generate,
                  child: _busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Generate seed'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ScreenshotGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Write this down')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _SeedReveal(
              format: widget.format,
              revealableSeed: _generated!.revealableSeed,
              busy: _busy,
              err: _err,
              initialName: '${widget.coin.name} wallet',
              onConfirm: _confirmAndSave,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeedReveal extends StatefulWidget {
  const _SeedReveal({
    required this.format,
    required this.revealableSeed,
    required this.busy,
    required this.err,
    required this.initialName,
    required this.onConfirm,
  });
  final SeedFormat format;
  final String revealableSeed;
  final bool busy;
  final String? err;
  final String initialName;
  final Future<void> Function(String name) onConfirm;

  @override
  State<_SeedReveal> createState() => _SeedRevealState();
}

class _SeedRevealState extends State<_SeedReveal> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.revealableSeed.split(RegExp(r'\s+'));
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x33EF4444),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x66EF4444)),
            ),
            child: const Text(
              'These words ARE the wallet. Anyone with them can spend it. '
              'Write them on paper, store offline, and never paste them on '
              'a website or share them with "support".',
              style: TextStyle(color: PeekColors.text, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 44,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: words.length,
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: PeekColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PeekColors.border),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${i + 1}  ',
                      style: const TextStyle(color: PeekColors.text3, fontSize: 12),
                    ),
                    TextSpan(
                      text: words[i],
                      style: const TextStyle(
                        color: PeekColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await SensitiveClipboard.copy(
                widget.revealableSeed,
                label: '${widget.format.displayName} seed',
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Copied — clipboard auto-clears in 30 s')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy phrase'),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Wallet name (only you can see this)',
              hintText: 'e.g. "Main Monero"',
            ),
          ),
          if (widget.err != null) ...[
            const SizedBox(height: 10),
            Text(widget.err!,
                style: const TextStyle(color: PeekColors.red, fontSize: 13)),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: widget.busy ? null : () => widget.onConfirm(_name.text),
            child: widget.busy
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('I have saved the words — add wallet'),
          ),
        ],
      ),
    );
  }
}

// ── Restore flow (seed-based) ─────────────────────────────────

class AddWalletRestoreScreen extends StatefulWidget {
  const AddWalletRestoreScreen({
    super.key,
    required this.coin,
    required this.format,
  });
  final CoinModule coin;
  final SeedFormat format;

  @override
  State<AddWalletRestoreScreen> createState() => _AddWalletRestoreScreenState();
}

class _AddWalletRestoreScreenState extends State<AddWalletRestoreScreen> {
  final _name = TextEditingController();
  final _seed = TextEditingController();
  final _passphrase = TextEditingController();
  final _seedOffset = TextEditingController();
  final _restoreHeight = TextEditingController();
  String? _err;
  bool _busy = false;

  bool get _isBip39 =>
      widget.format == SeedFormat.bip39_12 || widget.format == SeedFormat.bip39_24;

  @override
  void dispose() {
    _name.dispose();
    _seed.dispose();
    _passphrase.dispose();
    _seedOffset.dispose();
    _restoreHeight.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final cachedPwd = VaultState.I.cachedPassword;
    if (cachedPwd == null) {
      setState(() {
        _err = 'Vault is locked — re-unlock and try again.';
        _busy = false;
      });
      return;
    }
    final id = WalletStore.I.generateId();
    // Same derivation WalletStore.open() will use when reopening
    // this wallet later. Pre-fix, this was the legacy shared
    // VaultState.I.walletFilePassword which didn't match what open
    // returned — guaranteeing "invalid password" on any non-BIP39
    // wallet (no address-mismatch recovery to bail us out).
    final pwd =
        await WalletStore.I.deriveWalletFilePassword(cachedPwd, id);
    try {
      final input = <String, String>{
        'seed': _seed.text,
        if (_isBip39) 'mnemonic': _seed.text,
        if (_isBip39) 'passphrase': _passphrase.text,
        if (!_isBip39) 'seedOffset': _seedOffset.text,
      };
      final height = int.tryParse(_restoreHeight.text.trim());
      final material = await widget.coin.restoreFrom(
        walletId: id,
        format: widget.format,
        input: input,
        walletFilePassword: pwd,
        restoreHeight: height,
      );
      if (!mounted) return;
      final password = await _promptPassword(context);
      if (password == null) {
        setState(() => _busy = false);
        return;
      }
      await WalletStore.I.create(
        withId: id,
        name: _name.text.trim().isEmpty
            ? '${widget.coin.name} wallet'
            : _name.text.trim(),
        coinId: widget.coin.id,
        format: widget.format,
        seedMaterial: material.seedMaterial,
        password: password,
        primaryAddress: material.primaryAddress,
        restoreHeight: material.restoreHeight ?? height,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restore ${widget.format.displayName}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Wallet name',
                  hintText: 'e.g. "Imported from Cake"',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _seed,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _isBip39 ? 'Recovery phrase' : 'Seed words',
                  hintText: 'word1 word2 word3 …',
                ),
              ),
              if (_isBip39) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _passphrase,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'BIP39 passphrase (25th word) — optional',
                    hintText: 'Leave blank if not used',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'If the source wallet had a passphrase, you MUST enter it — '
                  'otherwise the imported addresses will be different.',
                  style: TextStyle(color: PeekColors.text3, fontSize: 11),
                ),
              ] else ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _seedOffset,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Seed offset — optional',
                    hintText: 'Leave blank if the seed isn\'t encrypted',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _restoreHeight,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Restore height — optional',
                  hintText: 'Block number to start scanning from',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lower = more thorough but slower sync; higher = faster '
                'but skips older transactions. Leave blank to let the '
                'wallet decide.',
                style: TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
              if (_err != null) ...[
                const SizedBox(height: 14),
                Text(_err!,
                    style: const TextStyle(color: PeekColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _restore,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Restore wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Restore from keys (XMR-only at the moment) ────────────────

class AddWalletKeysRestoreScreen extends StatefulWidget {
  const AddWalletKeysRestoreScreen({super.key, required this.coin});
  final CoinModule coin;

  @override
  State<AddWalletKeysRestoreScreen> createState() =>
      _AddWalletKeysRestoreScreenState();
}

class _AddWalletKeysRestoreScreenState extends State<AddWalletKeysRestoreScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _spendKey = TextEditingController();
  final _viewKey = TextEditingController();
  final _restoreHeight = TextEditingController();
  String? _err;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _spendKey.dispose();
    _viewKey.dispose();
    _restoreHeight.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final cachedPwd = VaultState.I.cachedPassword;
    if (cachedPwd == null) {
      setState(() {
        _err = 'Vault is locked — re-unlock and try again.';
        _busy = false;
      });
      return;
    }
    final id = WalletStore.I.generateId();
    final pwd =
        await WalletStore.I.deriveWalletFilePassword(cachedPwd, id);
    try {
      final height = int.tryParse(_restoreHeight.text.trim()) ?? 0;
      final material = await widget.coin.restoreFrom(
        walletId: id,
        format: SeedFormat.keysOnly,
        input: {
          'address': _address.text.trim(),
          'spendKey': _spendKey.text.trim(),
          'viewKey': _viewKey.text.trim(),
        },
        walletFilePassword: pwd,
        restoreHeight: height,
      );
      if (!mounted) return;
      final password = await _promptPassword(context);
      if (password == null) {
        setState(() => _busy = false);
        return;
      }
      await WalletStore.I.create(
        withId: id,
        name: _name.text.trim().isEmpty
            ? '${widget.coin.name} wallet'
            : _name.text.trim(),
        coinId: widget.coin.id,
        format: SeedFormat.keysOnly,
        seedMaterial: material.seedMaterial,
        password: password,
        primaryAddress: material.primaryAddress,
        restoreHeight: material.restoreHeight ?? height,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore from keys')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Wallet name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _address,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Primary address',
                  hintText: '4… (95 chars)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    onPressed: () async {
                      final scanned = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) =>
                              const QrScanScreen(title: 'Scan address'),
                        ),
                      );
                      if (scanned != null) _address.text = scanned;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _spendKey,
                obscureText: true,
                autocorrect: false,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Private spend key (hex)',
                  hintText: '64 hex chars — keep this secret',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _viewKey,
                obscureText: true,
                autocorrect: false,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Private view key (hex)',
                  hintText: '64 hex chars',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _restoreHeight,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Restore height',
                  hintText: 'Block number — earlier covers older receipts',
                ),
              ),
              if (_err != null) ...[
                const SizedBox(height: 14),
                Text(_err!,
                    style: const TextStyle(color: PeekColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _restore,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Restore wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _promptPassword(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm password'),
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
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  controller.dispose();
  return (result == null || result.isEmpty) ? null : result;
}
