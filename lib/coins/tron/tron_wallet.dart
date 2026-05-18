import 'dart:async';

import '../../util/peek_logger.dart';
import 'trc20.dart';
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

  /// Raw TRC-20 balance for [token] in base units. Decimals
  /// conversion is the caller's job — for USDT/USDC that's
  /// 10^6 per token.
  ///
  /// Swallows errors and returns zero rather than rethrowing —
  /// individual token failures shouldn't blank the whole wallet
  /// view, mirroring how the ERC-20 path handles it.
  Future<BigInt> tokenBalanceRaw(Trc20Token token) async {
    if (_closed) return BigInt.zero;
    try {
      // TronGrid wants both addresses in "41…" hex form. We have
      // the wallet's hex via address.hexAddress; for the contract
      // we need to convert via the trc20 helper.
      final paramHex =
          encodeTrc20BalanceOfParameter(address.hexAddress);
      // Strip 0x41 prefix from owner_address — TronGrid is picky
      // about which side wants the prefix; the contract address
      // needs it, the parameter doesn't, the owner_address does.
      final result = await _client.triggerConstantContract(
        ownerHexAddress: address.hexAddress,
        contractHexAddress: _t58ToHex(token.contract),
        functionSelector: 'balanceOf(address)',
        parameterHex: paramHex,
      );
      return decodeTrc20Uint256(result);
    } catch (e) {
      PeekLogger.I.log('trx',
          '${token.symbol} balance fetch failed: $e');
      return BigInt.zero;
    }
  }

  /// Display units = raw / 10^decimals. Returned as double for UI
  /// formatting only; arithmetic on amounts should stay on BigInt
  /// to avoid the 53-bit precision cliff.
  double tokenBalanceDisplay(BigInt raw, Trc20Token token) {
    return raw.toDouble() /
        BigInt.from(10).pow(token.decimals).toDouble();
  }

  /// Default TRC-20 token list. Future Settings → Custom Tokens
  /// would extend this per-wallet.
  List<Trc20Token> get defaultTokens => kDefaultTrc20Tokens;

  /// Convert a base58 T-prefixed Tron address to its 21-byte hex
  /// form ("41…"). Inline here so we don't need to thread the
  /// helper into trc20.dart's public API.
  String _t58ToHex(String base58) {
    const alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    var n = BigInt.zero;
    final big58 = BigInt.from(58);
    for (final ch in base58.runes) {
      final idx = alphabet.indexOf(String.fromCharCode(ch));
      if (idx < 0) {
        throw FormatException('Invalid Tron address: $base58');
      }
      n = n * big58 + BigInt.from(idx);
    }
    final tmp = <int>[];
    while (n > BigInt.zero) {
      tmp.add((n % BigInt.from(256)).toInt());
      n = n ~/ BigInt.from(256);
    }
    var leadingOnes = 0;
    for (var i = 0; i < base58.length && base58[i] == '1'; i++) {
      leadingOnes++;
    }
    final out =
        List<int>.filled(leadingOnes + tmp.length, 0);
    for (var i = 0; i < tmp.length; i++) {
      out[leadingOnes + i] = tmp[tmp.length - 1 - i];
    }
    // Strip the 4-byte trailing checksum.
    final payload = out.sublist(0, out.length - 4);
    return payload
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
