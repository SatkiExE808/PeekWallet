import 'package:flutter/material.dart';

import '../prefs/rpc_overrides.dart';
import '../theme.dart';

/// Per-chain custom-endpoint editor.
///
/// PeekWallet ships with sensible defaults for every chain (public
/// block explorers + RPC nodes). For users running their own
/// infrastructure — or who want to stop leaking wallet activity to
/// public services — this screen overrides them per chain.
///
/// Each row's empty state shows the default; typing replaces it.
/// Changes take effect the next time the relevant wallet is opened
/// (or the user re-enters the coin screen).
class RpcOverridesScreen extends StatefulWidget {
  const RpcOverridesScreen({super.key});

  @override
  State<RpcOverridesScreen> createState() => _RpcOverridesScreenState();
}

class _RpcOverridesScreenState extends State<RpcOverridesScreen> {
  // Editable fields, one per (coin, kind) tuple. Pre-filled from
  // the override store on initState.
  final Map<String, TextEditingController> _ctrls = {};

  /// Configurable endpoints, ordered by chain. Each entry pins down:
  ///   - coinId / kind for the override store
  ///   - default value (shown as hint when the user hasn't set one)
  ///   - a human-readable label and hint
  static final _entries = <_RpcEntry>[
    _RpcEntry(
      coinId: 'BTC',
      kind: 'mempool',
      label: 'Bitcoin (mempool.space-compat)',
      hint: 'https://mempool.space/api',
    ),
    _RpcEntry(
      coinId: 'LTC',
      kind: 'mempool',
      label: 'Litecoin (litecoinspace-compat)',
      hint: 'https://litecoinspace.org/api',
    ),
    _RpcEntry(
      coinId: 'BCH',
      kind: 'explorer',
      label: 'Bitcoin Cash (Blockchair)',
      hint: 'https://api.blockchair.com/bitcoin-cash',
    ),
    _RpcEntry(
      coinId: 'ETH',
      kind: 'rpc',
      label: 'Ethereum JSON-RPC',
      hint: 'https://eth.llamarpc.com',
    ),
    _RpcEntry(
      coinId: 'ETH',
      kind: 'explorer',
      label: 'Ethereum explorer (Blockscout-compat)',
      hint: 'https://eth.blockscout.com/api',
    ),
    _RpcEntry(
      coinId: 'MATIC',
      kind: 'rpc',
      label: 'Polygon JSON-RPC',
      hint: 'https://polygon-rpc.com',
    ),
    _RpcEntry(
      coinId: 'MATIC',
      kind: 'explorer',
      label: 'Polygon explorer (Blockscout-compat)',
      hint: 'https://polygon.blockscout.com/api',
    ),
    _RpcEntry(
      coinId: 'SOL',
      kind: 'rpc',
      label: 'Solana JSON-RPC',
      hint: 'https://api.mainnet-beta.solana.com',
    ),
    _RpcEntry(
      coinId: 'TRX',
      kind: 'explorer',
      label: 'Tron (TronGrid)',
      hint: 'https://api.trongrid.io',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final e in _entries) {
      _ctrls['${e.coinId}:${e.kind}'] = TextEditingController(
          text: RpcOverrides.I.get(e.coinId, e.kind) ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(_RpcEntry e) async {
    final value = _ctrls['${e.coinId}:${e.kind}']!.text.trim();
    await RpcOverrides.I.set(e.coinId, e.kind, value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value.isEmpty
          ? '${e.label} → cleared, using default next open'
          : '${e.label} → saved'),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _resetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all overrides?'),
        content: const Text(
          'Every chain will go back to its public default endpoint. '
          'You can re-add overrides at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await RpcOverrides.I.clearAll();
    if (!mounted) return;
    setState(() {
      for (final c in _ctrls.values) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom RPC endpoints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset all',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Point each chain at your own node instead of the public '
                'default. Stops the default explorer / RPC operator from '
                'seeing your wallet activity. Take effect the next time '
                'you open the affected wallet.',
                style:
                    TextStyle(color: PeekColors.text2, fontSize: 13),
              ),
              const SizedBox(height: 24),
              for (final e in _entries) ...[
                Text(e.label,
                    style: const TextStyle(
                        color: PeekColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: _ctrls['${e.coinId}:${e.kind}'],
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(hintText: e.hint),
                  onSubmitted: (_) => _save(e),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Default: ${e.hint}',
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _save(e),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Save',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Privacy notes:\n'
                '• Monero is configured separately on the Settings → Monero node screen.\n'
                '• Each request still goes over plain HTTPS — to also hide your IP, '
                'set up Tor / a VPN on your device or run the endpoint on your '
                'LAN over Tailscale.\n'
                '• The wallet doesn\'t validate that the endpoint is honest. Pick '
                'providers you trust.',
                style:
                    TextStyle(color: PeekColors.text3, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RpcEntry {
  const _RpcEntry({
    required this.coinId,
    required this.kind,
    required this.label,
    required this.hint,
  });
  final String coinId;
  final String kind;
  final String label;
  final String hint;
}
