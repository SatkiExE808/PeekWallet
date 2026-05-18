import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../theme.dart';
import 'qr_scan_screen.dart';

/// Address-book listing. Tap an entry → details / edit. Tap '+' → add.
/// Filterable by coin (one-coin world today, but the filter is wired
/// so adding BTC / ETH later is one extra picker on this screen).
class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key, this.pickForCoin});

  /// When set, the screen renders in "picker" mode — tapping an entry
  /// pops with the entry as the route result so the Send screen can
  /// receive the selected address. When null, taps open detail/edit.
  final String? pickForCoin;

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  Future<List<AddressBookEntry>>? _entries;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _entries = widget.pickForCoin == null
          ? AddressBook.I.all()
          : AddressBook.I.forCoin(widget.pickForCoin!);
    });
  }

  Future<void> _add() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressBookEditScreen(
          initialCoinId: widget.pickForCoin ?? 'XMR',
        ),
      ),
    );
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isPicker = widget.pickForCoin != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isPicker ? 'Pick recipient' : 'Address book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add entry',
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<AddressBookEntry>>(
          future: _entries,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: PeekColors.accent),
              );
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return _EmptyState(
                onAdd: _add,
                isPicker: isPicker,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _EntryTile(
                entry: entries[i],
                onTap: () async {
                  if (isPicker) {
                    Navigator.of(context).pop(entries[i]);
                    return;
                  }
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AddressBookEditScreen(existing: entries[i]),
                    ),
                  );
                  if (changed == true) _reload();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap});
  final AddressBookEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final addr = entry.address;
    final short = addr.length > 22
        ? '${addr.substring(0, 10)}…${addr.substring(addr.length - 6)}'
        : addr;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _coinColor(entry.coinId),
          child: Text(
            entry.coinId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          entry.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          short,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: PeekColors.text2,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: PeekColors.text3),
        onTap: onTap,
      ),
    );
  }

  Color _coinColor(String coinId) {
    switch (coinId) {
      case 'XMR':
        return const Color(0xFFFF6600);
      case 'BTC':
        return const Color(0xFFF7931A);
      case 'ETH':
        return const Color(0xFF627EEA);
      default:
        return PeekColors.text3;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.isPicker});
  final VoidCallback onAdd;
  final bool isPicker;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 56, color: PeekColors.text3),
            const SizedBox(height: 16),
            const Text(
              'No saved addresses yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isPicker
                  ? 'Tap "Add entry" to save the recipient you\'re about to send to.'
                  : 'Save the addresses of people you send to often so you don\'t have to paste each time.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: PeekColors.text2, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add entry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit form. Pass `existing` to edit; omit to add a new entry.
class AddressBookEditScreen extends StatefulWidget {
  const AddressBookEditScreen({
    super.key,
    this.existing,
    this.initialCoinId = 'XMR',
    this.initialAddress,
  });

  final AddressBookEntry? existing;
  final String initialCoinId;
  final String? initialAddress;

  @override
  State<AddressBookEditScreen> createState() => _AddressBookEditScreenState();
}

class _AddressBookEditScreenState extends State<AddressBookEditScreen> {
  late final TextEditingController _label;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  late String _coinId;
  String? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _address = TextEditingController(
        text: e?.address ?? widget.initialAddress ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _coinId = e?.coinId ?? widget.initialCoinId;
  }

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _err = null;
      _busy = true;
    });
    final label = _label.text.trim();
    final address = _address.text.trim();
    if (label.isEmpty) {
      setState(() {
        _err = 'Label cannot be empty.';
        _busy = false;
      });
      return;
    }
    if (address.isEmpty) {
      setState(() {
        _err = 'Address cannot be empty.';
        _busy = false;
      });
      return;
    }
    try {
      if (widget.existing == null) {
        await AddressBook.I.add(
          coinId: _coinId,
          address: address,
          label: label,
          notes: _notes.text.trim(),
        );
      } else {
        await AddressBook.I.update(
          widget.existing!.id,
          label: label,
          notes: _notes.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
            'The address is not affected — only this saved label / note is removed.'),
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
    if (yes != true || widget.existing == null) return;
    await AddressBook.I.delete(widget.existing!.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen(title: 'Scan address')),
    );
    if (scanned != null && scanned.isNotEmpty) {
      _address.text = scanned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit address' : 'Add address'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _label,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g. Alice — Cake wallet',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _address,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                readOnly: isEdit, // can't change address — delete + re-add
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: '4… or 8…',
                  helperText: isEdit
                      ? 'Addresses can\'t be edited — delete and re-add to change.'
                      : null,
                  suffixIcon: isEdit
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              onPressed: _scan,
                              tooltip: 'Scan',
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_paste, size: 18),
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) {
                                  _address.text = data!.text!.trim();
                                }
                              },
                              tooltip: 'Paste',
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notes,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Free-text — only stored locally.',
                ),
              ),
              if (_err != null) ...[
                const SizedBox(height: 10),
                Text(_err!, style: const TextStyle(color: PeekColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Save changes' : 'Add to book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
