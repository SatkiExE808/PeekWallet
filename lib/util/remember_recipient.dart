import '../address_book/address_book.dart';

/// After a successful send, record the recipient in the address book
/// so the user doesn't have to retype/repaste it next time.
///
/// Behavior:
///   - If the address is already saved for this coin, just bump
///     [recordUse] so the next address-book picker sorts it on top.
///   - If it's new, add a silent entry labeled "Sent {date}". The
///     user can rename it later via Address Book → edit.
///
/// Never throws — a failure to remember shouldn't surface to the
/// user mid-send-confirmation. Worst case the address just isn't
/// auto-saved.
Future<void> rememberRecipient({
  required String coinId,
  required String address,
}) async {
  try {
    final existing = await AddressBook.I.findByAddress(coinId, address);
    if (existing != null) {
      await AddressBook.I.recordUse(existing.id);
      return;
    }
    final now = DateTime.now();
    final dateLabel =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await AddressBook.I.add(
      coinId: coinId,
      address: address,
      label: 'Sent $dateLabel',
    );
  } catch (_) {
    // Swallow — auto-save is a convenience, not a guarantee.
  }
}
