import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/monero/monero_wallet.dart';
import '../prefs/prefs.dart';
import '../theme.dart';
import '../vault/vault_state.dart';

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
    setState(() {
      _savedUri = saved;
      _nodeController.text = saved ?? '';
      _loading = false;
    });
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
                    const _SectionDivider(label: 'Vault'),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline, color: PeekColors.text2),
                      title: const Text('Lock app'),
                      subtitle: const Text(
                        'Clear the in-memory seed and require the password again',
                        style: TextStyle(color: PeekColors.text3, fontSize: 11),
                      ),
                      onTap: () {
                        VaultState.I.lock();
                      },
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
