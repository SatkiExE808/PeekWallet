import 'dart:async';

import '../../prefs/rpc_overrides.dart';
import '../../util/peek_logger.dart';
import 'bch_keys.dart';
import 'bch_tx_builder.dart';
import 'blockchair_client.dart';
import 'cashaddr.dart';

/// Runtime handle for a Bitcoin Cash wallet. Receive + balance +
/// (partial) history; send is a follow-up (BCH uses legacy P2PKH
/// signing with SIGHASH_FORKID — different from BIP143).
class BitcoinCashWallet {
  BitcoinCashWallet._({
    required this.mnemonic,
    required this.passphrase,
    required this.address,
  }) : _client = BlockchairBchClient(
            baseUrl: RpcOverrides.I.get('BCH', 'explorer'));

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

  /// All spendable UTXOs for the wallet's primary address. We only
  /// have one address per BCH wallet today (no gap-limit window) —
  /// extending to multiple addresses is a follow-up.
  Future<List<BchUtxo>> utxos() async {
    if (_closed) return const [];
    final raw = await _client.utxos(address.address);
    return raw
        .map((u) => BchUtxo(
              txid: u.txid,
              vout: u.vout,
              valueSat: u.valueSat,
              address: address.address,
            ))
        .toList();
  }

  /// Suggested fee rate (sat/byte) for the send screen.
  int suggestedFeeRateSatPerByte() => _client.suggestedFeeRateSatPerByte();

  /// Build, sign and broadcast a BCH P2PKH transaction.
  Future<BuiltBitcoinCashTransaction> sendBch({
    required String destAddress,
    required int amountSat,
    required int feeRateSatPerByte,
  }) async {
    if (_closed) throw StateError('Wallet is closed');

    final destDecoded = cashaddrDecode(destAddress);
    if (destDecoded == null) {
      throw const InvalidBchAddressException(
          'Recipient must be a valid CashAddr (bitcoincash:q…)');
    }
    if (destDecoded.type != CashAddrType.p2pkh) {
      throw const InvalidBchAddressException(
          'Only P2PKH CashAddr supported today (P2SH lands later)');
    }

    final available = await utxos();
    final selected = selectBchUtxosGreedy(
      available: available,
      amountSat: amountSat,
      feeRateSatPerByte: feeRateSatPerByte,
    );
    if (selected == null) {
      throw const InsufficientBchFundsException(
          'Not enough confirmed funds for this amount + fee');
    }

    // Re-derive the spending key from the wallet's mnemonic. We only
    // have a single address per wallet so this is straight account 0,
    // index 0. Multi-address support would fan out over indices and
    // pick the right one per UTXO.
    final spending = deriveBitcoinCashSpendingKey(
      mnemonic: mnemonic,
      passphrase: passphrase,
    );

    // Change goes back to the same address — BCH doesn't have a
    // standard "internal/external" chain convention the way Bitcoin
    // does for HD wallets. Privacy-conscious users would want a
    // fresh address per send; that's a follow-up.
    final built = buildAndSignP2PKH(
      inputs: selected,
      signers: {spending.address: spending},
      destPkh: destDecoded.hash,
      amountSat: amountSat,
      changePkh: spending.publicKeyHash,
      feeRateSatPerByte: feeRateSatPerByte,
    );

    PeekLogger.I.log('bch',
        'broadcasting tx ${built.txid} (${built.byteSize} bytes, fee ${built.feeSat} sat)');
    final returnedTxid = await _client.broadcast(built.rawHex);
    if (returnedTxid != built.txid) {
      PeekLogger.I.log('bch',
          'WARNING: explorer returned $returnedTxid but we computed ${built.txid}');
    }
    return built;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
