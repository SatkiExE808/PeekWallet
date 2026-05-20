import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../address_book/address_book.dart';
import '../theme.dart';
import '../util/coin_avatar.dart';
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
    final accent = PeekColors.coinAccent(entry.coinId);
    return Material(
      color: PeekColors.surface,
      borderRadius: PeekDesign.brCard,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: PeekDesign.brCard,
        splashColor: accent.withAlpha(36),
        highlightColor: accent.withAlpha(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: PeekDesign.brCard,
            border: Border.all(color: PeekColors.hairline, width: 1),
            // Same coin-aware left-edge stripe as the wallets list
            // rows, so contacts visually belong to the same family
            // as the wallets they pay to.
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.012, 0.012, 1.0],
              colors: [
                accent,
                accent,
                PeekColors.surface,
                PeekColors.surface,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: PeekDesign.sp4, vertical: PeekDesign.sp3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: accent.withAlpha(96), width: 1.5),
                ),
                child: coinAvatar(entry.coinId, radius: 16),
              ),
              const SizedBox(width: PeekDesign.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PeekColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      short,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: PeekColors.text3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PeekDesign.sp2),
              const Icon(Icons.chevron_right,
                  color: PeekColors.text3, size: 18),
            ],
          ),
        ),
      ),
    );
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
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  PeekColors.accent.withAlpha(48),
                  PeekColors.accent.withAlpha(0),
                ]),
              ),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PeekColors.surface2,
                  border: Border.all(color: PeekColors.border),
                ),
                child: const Icon(Icons.bookmark_rounded,
                    size: 32, color: PeekColors.accent),
              ),
            ),
            const SizedBox(height: PeekDesign.sp5),
            const Text(
              'No saved addresses yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: PeekDesign.sp2),
            Text(
              isPicker
                  ? 'Save the recipient you\'re about to send to.'
                  : 'Save the addresses of people you send to often so you don\'t have to paste each time.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: PeekColors.text2, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: PeekDesign.sp6),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add entry'),
              ),
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
                const SizedBox(height: PeekDesign.sp3),
                Container(
                  padding: const EdgeInsets.all(PeekDesign.sp3),
                  decoration: BoxDecoration(
                    color: PeekColors.red.withAlpha(28),
                    borderRadius: PeekDesign.brSmall,
                    border: Border.all(color: PeekColors.red.withAlpha(96)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: PeekColors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _err!,
                          style: const TextStyle(
                              color: PeekColors.red,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: PeekDesign.sp5),
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
