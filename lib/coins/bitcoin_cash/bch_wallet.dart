import 'dart:async';

import '../../util/peek_logger.dart';
import 'bch_keys.dart';
import 'blockchair_client.dart';

/// Runtime handle for a Bitcoin Cash wallet. Receive + balance +
/// (partial) history; send is a follow-up (BCH uses legacy P2PKH
/// signing with SIGHASH_FORKID — different from BIP143).
class BitcoinCashWallet {
  BitcoinCashWallet._({
    required this.mnemonic,
    required this.passphrase,
    required this.address,
  }) : _client = BlockchairBchClient();

  factory BitcoinCashWallet.open({
    required String mnemonic,
    String passphrase = '',
  }) {
    final addr = deriveBitcoinCashAddress(
      mnemonic: mnemonic,
      passphrase: passphrase,
    );
    return BitcoinCashWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      address: addr,
    );
  }

  final String mnemonic;
  final String passphrase;
  final BitcoinCashAddressDerivation address;
  final BlockchairBchClient _client;
  bool _closed = false;

  String get primaryAddress => address.address;

  /// Confirmed BCH balance in satoshis.
  Future<int> balanceSat() async {
    if (_closed) return 0;
    try {
      final v = await _client.balanceSat(address.address);
      PeekLogger.I.log('bch', 'balance fetched: $v sat');
      return v;
    } catch (e) {
      PeekLogger.I.log('bch', 'balance fetch failed: $e');
      rethrow;
    }
  }

  Future<List<BchTx>> transactions() async {
    if (_closed) return const [];
    try {
      return await _client.transactions(address.address);
    } catch (e) {
      PeekLogger.I.log('bch', 'history fetch failed: $e');
      return const [];
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
