import 'dart:async';

import '../../util/peek_logger.dart';
import 'tron_keys.dart';
import 'trongrid_client.dart';

/// Runtime handle for a Tron wallet — derive address + poll TronGrid
/// for balance and history. Send (build TRX TransferContract +
/// protobuf-encode + sign + broadcastTransaction) is a follow-up.
class TronWallet {
  TronWallet._({
    required this.mnemonic,
    required this.passphrase,
    required this.address,
  }) : _client = TronGridClient();

  factory TronWallet.open({
    required String mnemonic,
    String passphrase = '',
  }) {
    final addr = deriveTronAddress(
      mnemonic: mnemonic,
      passphrase: passphrase,
    );
    return TronWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      address: addr,
    );
  }

  final String mnemonic;
  final String passphrase;
  final TronAddressDerivation address;
  final TronGridClient _client;
  bool _closed = false;

  String get primaryAddress => address.address;

  /// Confirmed TRX balance in sun (1 TRX = 10^6 sun).
  Future<int> balanceSun() async {
    if (_closed) return 0;
    try {
      final v = await _client.balanceSun(address.address);
      PeekLogger.I.log('trx', 'balance fetched: $v sun');
      return v;
    } catch (e) {
      PeekLogger.I.log('trx', 'balance fetch failed: $e');
      rethrow;
    }
  }

  Future<List<TronTx>> transactions() async {
    if (_closed) return const [];
    try {
      return await _client.transactions(address.address);
    } catch (e) {
      PeekLogger.I.log('trx', 'history fetch failed: $e');
      return const [];
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
