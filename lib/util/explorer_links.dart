// Block-explorer URL builders, one per supported coin/chain.
//
// We hard-code the explorer hosts here rather than pulling them out
// of the per-coin params files so the user can override these in a
// future Settings → Explorers picker without breaking the producer
// modules. Today they're constants; tomorrow they'd read from a
// settings store.
//
// Privacy note: opening these URLs reveals (your IP + the tx/address
// you're looking at) to the explorer. Tor-routing the urlLauncher
// open is a follow-up that depends on the Tor support roadmap item.

import 'package:url_launcher/url_launcher.dart';

/// Resolve a per-coin tx page URL. Returns null when the chain
/// doesn't have a meaningful "view this tx" view (Monero hides per-
/// tx detail enough that the explorer mostly just confirms the tx
/// existed, but we still expose the link for users who want it).
String? explorerTxUrl({required String coinId, required String txid}) {
  switch (coinId) {
    case 'XMR':
      return 'https://xmrchain.net/tx/$txid';
    case 'BTC':
      return 'https://mempool.space/tx/$txid';
    case 'LTC':
      return 'https://litecoinspace.org/tx/$txid';
    case 'ETH':
      return 'https://etherscan.io/tx/$txid';
    case 'MATIC':
      return 'https://polygonscan.com/tx/$txid';
    case 'SOL':
      return 'https://solscan.io/tx/$txid';
    case 'TRX':
      return 'https://tronscan.org/#/transaction/$txid';
    case 'BCH':
      return 'https://blockchair.com/bitcoin-cash/transaction/$txid';
    default:
      return null;
  }
}

/// Open [url] in the OS browser. Returns true if launch succeeded.
/// Swallows the LaunchException because there's nothing useful the
/// caller can do besides showing a snackbar — and we return false
/// for exactly that.
Future<bool> openExplorerUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
