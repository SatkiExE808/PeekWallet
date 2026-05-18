import 'dart:async';

import '../../util/peek_logger.dart';
import 'ethereum_keys.dart';
import 'etherscan_client.dart';

/// Runtime handle for an Ethereum wallet — derive BIP44 address +
/// poll Blockscout/Etherscan for balance and history. Send is NOT
/// implemented here yet (lands in a follow-up): RLP encoding +
/// EIP-1559 fee market + nonce management is substantial work and
/// out of scope for the "receive + monitor" first commit.
///
/// Account-based chain so there's no gap-limit complexity — one
/// address per (account, index) is enough. The send path will need
/// nonce tracking but for receive-only we just need the first
/// address.
class EthereumWallet {
  EthereumWallet._({
    required this.mnemonic,
    required this.passphrase,
    required this.address,
  }) : _client = EtherscanClient();

  factory EthereumWallet.open({
    required String mnemonic,
    String passphrase = '',
  }) {
    final addr = deriveEthereumAddress(
      mnemonic: mnemonic,
      passphrase: passphrase,
    );
    return EthereumWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      address: addr,
    );
  }

  final String mnemonic;
  final String passphrase;
  final EthereumAddressDerivation address;
  final EtherscanClient _client;
  bool _closed = false;

  /// EIP-55 checksummed receive address (what the UI shows + QRs).
  String get primaryAddress => address.address;
  /// Lowercase form, used for RPC calls and txlist matching.
  String get primaryAddressLower => address.addressLower;

  /// Confirmed wei balance for our address. Mempool balance is NOT
  /// included here — Ethereum's account model doesn't have a clean
  /// pre-confirmation state like Bitcoin's mempool sums.
  Future<BigInt> balanceWei() async {
    if (_closed) return BigInt.zero;
    try {
      final b = await _client.balanceWei(address.addressLower);
      PeekLogger.I.log('eth', 'balance fetched: $b wei');
      return b;
    } catch (e) {
      PeekLogger.I.log('eth', 'balance fetch failed: $e');
      rethrow;
    }
  }

  /// Recent transactions, newest first.
  Future<List<EthereumTx>> transactions() async {
    if (_closed) return const [];
    try {
      return await _client.transactions(address.addressLower);
    } catch (e) {
      PeekLogger.I.log('eth', 'history fetch failed: $e');
      return const [];
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
