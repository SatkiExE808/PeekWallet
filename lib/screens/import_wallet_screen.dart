import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../vault/vault_state.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

enum _ImpErrKind { none, badWordCount, badChecksum, pwTooShort, pwMismatch, other }

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _phrase = TextEditingController();
  final _passphrase = TextEditingController();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  _ImpErrKind _errKind = _ImpErrKind.none;
  String? _errOther;
  bool _busy = false;

  @override
  void dispose() {
    _phrase.dispose();
    _passphrase.dispose();
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() {
      _errKind = _ImpErrKind.none;
      _errOther = null;
    });
    final raw = _phrase.text.trim().toLowerCase();
    final words = raw.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length != 12 && words.length != 24) {
      setState(() => _errKind = _ImpErrKind.badWordCount);
      return;
    }
    final normalized = words.join(' ');
    if (!bip39.validateMnemonic(normalized)) {
      setState(() => _errKind = _ImpErrKind.badChecksum);
      return;
    }
    if (_p1.text.length < 8) {
      setState(() => _errKind = _ImpErrKind.pwTooShort);
      return;
    }
    if (_p1.text != _p2.text) {
      setState(() => _errKind = _ImpErrKind.pwMismatch);
      return;
    }
    setState(() => _busy = true);
    try {
      await VaultState.I.create(
        normalized,
        _p1.text,
        passphrase: _passphrase.text,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() {
        _errKind = _ImpErrKind.other;
        _errOther = e.toString();
        _busy = false;
      });
    }
  }

  String? _errText(AppLocalizations l) => switch (_errKind) {
        _ImpErrKind.none => null,
        _ImpErrKind.badWordCount => l.iwErrorBadWordCount,
        _ImpErrKind.badChecksum => l.iwErrorBip39Checksum,
        _ImpErrKind.pwTooShort => l.iwErrorAppPasswordTooShort,
        _ImpErrKind.pwMismatch => l.cwPasswordsDontMatch,
        _ImpErrKind.other => _errOther,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final err = _errText(l);
    return Scaffold(
      appBar: AppBar(title: Text(l.iwScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.iwIntro,
                style: const TextStyle(color: PeekColors.text2, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phrase,
                minLines: 3,
                maxLines: 5,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: l.iwRecoveryPhraseLabel,
                  hintText: l.iwPhraseHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passphrase,
                obscureText: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: l.iwPassphraseOptionalLabel,
                  hintText: l.iwPassphraseHintBlank,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.iwPassphraseWarning,
                style: const TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _p1,
                obscureText: true,
                decoration: InputDecoration(labelText: l.iwAppPasswordMinLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _p2,
                obscureText: true,
                decoration: InputDecoration(labelText: l.iwConfirmAppPasswordLabel),
              ),
              if (err != null) ...[
                const SizedBox(height: 10),
                Text(err, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _import,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l.iwImportAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
