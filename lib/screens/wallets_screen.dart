import 'package:flutter/material.dart';

import '../coins/coin.dart';
import '../coins/module_registry.dart';
import '../theme.dart';
import '../wallets/wallet_meta.dart';
import '../wallets/wallet_store.dart';
import 'add_wallet/add_wallet_flow.dart';
import 'bitcoin_coin_screen.dart';
import 'coin_screen.dart';

/// Lists every wallet in the WalletStore. Tap a row to open its coin
/// page; tap "+" to add a new wallet via the multi-step flow.
///
/// This replaces the previous "one row per coin" view — the new
/// architecture supports multiple wallets per coin, so the list is
/// per-wallet.
class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  late Future<List<WalletMeta>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = WalletStore.I.list();
    WalletStore.I.addListener(_refresh);
  }

  @override
  void dispose() {
    WalletStore.I.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _entries = WalletStore.I.list();
    });
  }

  Future<void> _add() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddWalletFlow()),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add wallet',
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<WalletMeta>>(
          future: _entries,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: PeekColors.accent),
              );
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return _EmptyState(onAdd: _add);
            }
            return ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final meta = entries[i];
                final coin = coinModuleFor(meta.coinId);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: coin?.color ?? PeekColors.text3,
                      child: Icon(
                        coin?.icon ?? Icons.help_outline,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(meta.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${coin?.symbol ?? meta.coinId} · ${meta.format.displayName}',
                      style: const TextStyle(
                          color: PeekColors.text2, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: PeekColors.text3),
                    onTap: coin == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => meta.coinId == 'BTC'
                                    ? BitcoinCoinScreen(walletMeta: meta)
                                    : CoinScreen(
                                        coin: _LegacyCoinAdapter(coin),
                                        walletMeta: meta,
                                      ),
                              ),
                            ),
                    onLongPress: () => _showWalletMenu(meta),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showWalletMenu(WalletMeta meta) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PeekColors.bg2,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: PeekColors.text2),
              title: const Text('Rename'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: PeekColors.red),
              title: const Text('Delete'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: PeekColors.text3),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') await _rename(meta);
    if (action == 'delete') await _delete(meta);
  }

  Future<void> _rename(WalletMeta meta) async {
    final controller = TextEditingController(text: meta.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename wallet'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.trim().isNotEmpty) {
      await WalletStore.I.rename(walletId: meta.id, newName: newName);
    }
  }

  Future<void> _delete(WalletMeta meta) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${meta.name}?'),
        content: const Text(
          'The on-chain wallet is not affected — anyone with the seed '
          'can still restore it later. Only this device\'s record is '
          'removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await WalletStore.I.delete(meta.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: PeekColors.text3),
            const SizedBox(height: 16),
            const Text(
              'No wallets yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a fresh wallet or restore an existing one from a '
              'recovery phrase / keys.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PeekColors.text2, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add wallet'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bridge from the new CoinModule (which has the full lifecycle) to
/// the legacy Coin interface that CoinScreen still expects. Keeps the
/// CoinScreen rewrite out of THIS commit — that lands when we cut
/// over to the new MoneroSession.startFor multi-wallet path.
class _LegacyCoinAdapter implements Coin {
  _LegacyCoinAdapter(this.module);
  final dynamic /* CoinModule */ module;

  @override
  String get id => module.id as String;
  @override
  String get name => module.name as String;
  @override
  String get symbol => module.symbol as String;
  @override
  Color get color => module.color as Color;
  @override
  IconData get icon => module.icon as IconData;
  @override
  Future<String> deriveAddress(String mnemonic) async {
    // Old Coin.deriveAddress is used by the legacy CoinScreen to
    // pre-populate the receive address; the equivalent in the new
    // model is the cached primaryAddress in WalletMeta. CoinScreen
    // falls back to "no address" if this returns empty — fine for
    // the transition.
    return '';
  }
}
