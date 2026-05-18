import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/monero/monero_wallet.dart';
import '../prefs/prefs.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/peek_logger.dart';
import '../vault/biometric_auth.dart';
import '../vault/vault_state.dart';
import 'about_screen.dart';
import 'address_book_screen.dart';
import 'reveal_seed_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nodeController = TextEditingController();
  String? _savedUri;
  bool _loading = true;
  bool _busy = false;
  String? _message;
  MaterialColor? _messageColor;

  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  int _autoLockSeconds = Prefs.defaultAutoLockSeconds;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await Prefs.I.moneroDaemonUri();
    final bioEnabled = await VaultState.I.biometricEnabled();
    final bioAvail = await BiometricAuth.I.isAvailable();
    final autoLock = await Prefs.I.autoLockSeconds();
    setState(() {
      _savedUri = saved;
      _nodeController.text = saved ?? '';
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvail;
      _autoLockSeconds = autoLock;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool wantOn) async {
    if (!wantOn) {
      await VaultState.I.disableBiometric();
      setState(() => _biometricEnabled = false);
      return;
    }
    // Confirm the password before stashing it. Even though the
    // wallet is unlocked, we don't trust the in-memory state —
    // a wrong password here would lock the user out of biometric
    // unlock until they disabled + re-enabled.
    final password = await _askPassword(
      title: 'Enable biometric unlock',
      hint: 'Enter your app password to confirm',
    );
    if (password == null) return;
    try {
      await VaultState.I.enableBiometric(password);
      setState(() => _biometricEnabled = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not enable: $e')),
      );
    }
  }

  Future<String?> _askPassword({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Password', hintText: hint),
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

  Future<void> _save() async {
    final input = _nodeController.text.trim();
    if (input.isNotEmpty && !MoneroDaemonEndpoint.isValid(input)) {
      setState(() {
        _message = 'Could not parse that URL. Try e.g. https://node.example.com:18081';
        _messageColor = Colors.red;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    await Prefs.I.setMoneroDaemonUri(input.isEmpty ? null : input);
    setState(() {
      _savedUri = input.isEmpty ? null : input;
      _busy = false;
      _message = 'Saved. Lock + unlock the app to switch your wallet to the new node.';
      _messageColor = Colors.green;
    });
  }

  String _autoLockLabel(int seconds) {
    if (seconds <= 0) return 'Immediately';
    if (seconds >= 86400) return 'Never';
    if (seconds < 60) return '$seconds s';
    if (seconds < 3600) return '${seconds ~/ 60} min';
    return '${seconds ~/ 3600} h';
  }

  Future<void> _pickAutoLock() async {
    const options = <(int, String)>[
      (0, 'Immediately'),
      (30, '30 seconds'),
      (60, '1 minute'),
      (120, '2 minutes (default)'),
      (300, '5 minutes'),
      (900, '15 minutes'),
      (3600, '1 hour'),
      (86400, 'Never'),
    ];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Auto-lock after backgrounding',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'How long PeekWallet can stay unlocked while you\'re using '
                'other apps. Returning within this window keeps you logged '
                'in; longer and the password is required again.',
                style: TextStyle(color: PeekColors.text3, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            for (final (sec, label) in options)
              ListTile(
                title: Text(label),
                trailing: sec == _autoLockSeconds
                    ? const Icon(Icons.check, color: PeekColors.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(sec),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await Prefs.I.setAutoLockSeconds(picked);
      setState(() => _autoLockSeconds = picked);
    }
  }

  Future<void> _exportLogs() async {
    final content = await PeekLogger.I.readCurrent();
    if (!mounted) return;
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No logs to export yet.')),
      );
      return;
    }
    // Show the contents in a scrollable dialog with a Copy button.
    // Filesystem-share + email-attach is a follow-up — needs the
    // share_plus plugin. The copy-to-clipboard path covers the
    // primary use case ("paste into a GitHub issue").
    // Capture the outer messenger so the post-pop SnackBar isn't
    // racing against a disposed dialog context.
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logs (last 7 days)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (ctx.mounted) Navigator.of(ctx).pop();
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Logs copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency() async {
    const currencies = <String>[
      'usd', 'eur', 'gbp', 'jpy', 'cny', 'krw', 'rub',
      'aud', 'cad', 'inr', 'try', 'brl', 'sgd', 'hkd', 'twd',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Display currency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SwitchListTile(
              title: const Text('Show fiat values'),
              subtitle: const Text(
                'Polls CoinGecko every 5 min. No PII sent.',
                style: TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
              value: PriceFeed.I.enabled,
              onChanged: (v) async {
                await PriceFeed.I.setEnabled(v);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
            ),
            const Divider(),
            for (final c in currencies)
              ListTile(
                title: Text(c.toUpperCase()),
                trailing: c == PriceFeed.I.currency
                    ? const Icon(Icons.check, color: PeekColors.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await PriceFeed.I.setCurrency(picked);
    }
  }

  Future<void> _confirmLock() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lock app?'),
        content: const Text(
          'You will need to enter your password to unlock. Any in-progress '
          'Monero sync will pick up where it left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
    if (yes == true) VaultState.I.lock();
  }

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await Prefs.I.setMoneroDaemonUri(null);
    setState(() {
      _savedUri = null;
      _nodeController.text = '';
      _busy = false;
      _message = 'Reset. The app will use $kDefaultMoneroDaemon on next unlock.';
      _messageColor = Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    final input = _nodeController.text.trim();
    final effective = input.isEmpty
        ? (_savedUri ?? kDefaultMoneroDaemon)
        : input;
    final preview = MoneroDaemonEndpoint.isValid(effective)
        ? MoneroDaemonEndpoint.parse(effective)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PeekColors.accent))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Monero node',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'The Monero daemon PeekWallet connects to for sync. '
                      'Default is Cake Wallet\'s public node. For full privacy, '
                      'run your own monerod and point this at it.',
                      style: TextStyle(color: PeekColors.text2, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nodeController,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Daemon URL',
                        hintText: kDefaultMoneroDaemon,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste, size: 18),
                          tooltip: 'Paste',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _nodeController.text = data!.text!.trim();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Connects to ${preview.hostPort} (ssl=${preview.useSsl})',
                        style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _messageColor == Colors.red
                              ? PeekColors.red
                              : PeekColors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _reset,
                            child: const Text('Reset to default'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _busy ? null : _save,
                            child: _busy
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const _SectionDivider(label: 'Public nodes'),
                    const SizedBox(height: 8),
                    for (final url in const [
                      kDefaultMoneroDaemon,
                      ...kMoneroFallbackNodes,
                    ])
                      _NodeQuickPick(
                        url: url,
                        isActive: (_savedUri ?? kDefaultMoneroDaemon) == url,
                        onPick: () {
                          _nodeController.text = url;
                          setState(() {});
                        },
                      ),
                    const SizedBox(height: 28),
                    const _SectionDivider(label: 'Security'),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fingerprint, color: PeekColors.text2),
                      title: const Text('Biometric unlock'),
                      subtitle: Text(
                        _biometricAvailable
                            ? 'Use fingerprint / face to unlock instead of typing the password'
                            : 'Not available on this device (no enrolled biometric)',
                        style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                      value: _biometricEnabled,
                      onChanged: _biometricAvailable ? _toggleBiometric : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.visibility_outlined, color: PeekColors.text2),
                      title: const Text('Reveal recovery phrase'),
                      subtitle: const Text(
                        'View your BIP39 seed + Monero spend/view keys',
                        style: TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: PeekColors.text3),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RevealSeedScreen()),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.contact_page_outlined,
                          color: PeekColors.text2),
                      title: const Text('Address book'),
                      subtitle: const Text(
                        'Saved labels for recipients you send to',
                        style: TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: PeekColors.text3),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddressBookScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer_outlined,
                          color: PeekColors.text2),
                      title: const Text('Auto-lock'),
                      subtitle: Text(
                        _autoLockLabel(_autoLockSeconds),
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: PeekColors.text3),
                      onTap: _pickAutoLock,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline, color: PeekColors.text2),
                      title: const Text('Lock app'),
                      subtitle: const Text(
                        'Clear the in-memory seed and require the password again',
                        style: TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                      onTap: _confirmLock,
                    ),
                    const SizedBox(height: 28),
                    const _SectionDivider(label: 'Display'),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: PriceFeed.I,
                      builder: (_, _) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.currency_exchange,
                            color: PeekColors.text2),
                        title: const Text('Display currency'),
                        subtitle: Text(
                          PriceFeed.I.enabled
                              ? PriceFeed.I.currency.toUpperCase()
                              : 'Disabled',
                          style: const TextStyle(
                              color: PeekColors.text3, fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: PeekColors.text3),
                        onTap: _pickCurrency,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined,
                          color: PeekColors.text2),
                      title: const Text('Export logs'),
                      subtitle: const Text(
                        'Last 7 days. Addresses and keys are auto-redacted.',
                        style: TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: PeekColors.text3),
                      onTap: _exportLogs,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline,
                          color: PeekColors.text2),
                      title: const Text('About PeekWallet'),
                      subtitle: const Text(
                        'Version, license, source code',
                        style: TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: PeekColors.text3),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: PeekColors.text2, fontSize: 12),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: PeekColors.border)),
      ],
    );
  }
}

class _NodeQuickPick extends StatelessWidget {
  const _NodeQuickPick({
    required this.url,
    required this.isActive,
    required this.onPick,
  });
  final String url;
  final bool isActive;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        url,
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      ),
      trailing: isActive
          ? const Icon(Icons.check_circle, color: PeekColors.green, size: 18)
          : const Icon(Icons.chevron_right, color: PeekColors.text3),
      onTap: onPick,
    );
  }
}
