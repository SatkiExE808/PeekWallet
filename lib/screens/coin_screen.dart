import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../coins/coin.dart';
import '../coins/monero/monero_engine.dart';
import '../coins/monero/monero_wallet.dart';
import '../theme.dart';
import '../vault/vault_state.dart';

/// Coin detail page. For Monero, shows the live native-engine balance
/// + sync progress; other coins still show placeholder text until
/// their own backends land.
class CoinScreen extends StatefulWidget {
  const CoinScreen({super.key, required this.coin});
  final Coin coin;

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
  bool _daemonConnected = false;
  String? _daemonError;
  String? _engineError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
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

  Future<void> _bootMonero(String mnemonic) async {
    // Recent tip - 5000 ≈ ~1 week of history. Fast first sync, won't
    // miss recent deposits. Settings UI for tweaking this lands later.
    const restoreHeight = 3676000;
    // Repaint while open() is still streaming stage updates so the
    // user sees progress instead of just a blank '…XMR'.
    final stageTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {});
    });
    final w = await MoneroSession.I.start(
      mnemonic: mnemonic,
      passphrase: VaultState.I.passphrase,
      restoreHeight: restoreHeight,
      daemonUri: kDefaultMoneroDaemon,
    );
    stageTicker.cancel();
    if (w == null) {
      setState(() => _engineError = MoneroSession.I.lastError ?? 'unknown');
      return;
    }
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _syncPct = w.syncProgressPct;
        _balanceXmr = w.balanceXmr;
        _daemonConnected = w.isDaemonConnected;
        _daemonError = w.daemonError;
      });
    });
  }

  String _balanceText() {
    if (widget.coin.id != 'XMR') return '… ${widget.coin.symbol}';
    if (_engineError != null) return '… ${widget.coin.symbol}';
    if (_balanceXmr == null) {
      final s = MoneroSession.I.stage;
      return s == null ? '… ${widget.coin.symbol}' : 'Boot: $s';
    }
    if (!_daemonConnected) return 'Connecting to daemon…';
    final synced = (_syncPct ?? 0) >= 100;
    if (!synced) return 'Syncing ${_syncPct ?? 0}%';
    return '${_balanceXmr!.toStringAsFixed(9)} ${widget.coin.symbol}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.coin.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.coin.color,
                    radius: 18,
                    child: Icon(widget.coin.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.coin.symbol} balance',
                    style: const TextStyle(color: PeekColors.text2, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _balanceText(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              if (widget.coin.id == 'XMR') const _EngineStatusBanner(),
              if (_engineError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Engine: $_engineError',
                    style: const TextStyle(color: PeekColors.red, fontSize: 11),
                  ),
                ),
              if (widget.coin.id == 'XMR' &&
                  _engineError == null &&
                  _daemonError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Daemon: $_daemonError',
                    style: const TextStyle(color: PeekColors.red, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 20),
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
          ),
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
