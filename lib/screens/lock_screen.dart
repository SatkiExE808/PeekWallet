import 'package:flutter/material.dart';

import '../theme.dart';
import '../vault/vault_state.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pwd = TextEditingController();
  String? _err;
  bool _busy = false;

  @override
  void dispose() {
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _err = null;
      _busy = true;
    });
    try {
      await VaultState.I.unlock(_pwd.text);
      // Routing handled by main.dart listening to VaultState.
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.lock_outline, size: 56, color: PeekColors.accent),
              const SizedBox(height: 20),
              const Text(
                'PeekWallet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your password to unlock.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PeekColors.text2, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pwd,
                obscureText: true,
                autofocus: true,
                onSubmitted: (_) => _unlock(),
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (_err != null) ...[
                const SizedBox(height: 8),
                Text(_err!, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _busy ? null : _unlock,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Unlock'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
