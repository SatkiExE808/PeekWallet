import 'dart:async';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';

import '../../util/peek_logger.dart';
import 'trc20.dart';
import 'tron_keys.dart';
import 'tron_tx_builder.dart';
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

  /// TRC-20 transfer history for this wallet. Includes every token
  /// the address has touched; the UI filters to known tokens.
  Future<List<Trc20Transfer>> trc20Transfers() async {
    if (_closed) return const [];
    try {
      return await _client.trc20Transfers(address.address);
    } catch (e) {
      PeekLogger.I.log('trx', 'TRC-20 history fetch failed: $e');
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

  /// Send native TRX. Returns the broadcast txid on success.
  ///
  /// Tron sends use a "hosted build, local sign, hosted broadcast"
  /// flow because the underlying tx is protobuf-encoded with a
  /// recent block reference. We have TronGrid construct the
  /// unsigned tx (it knows the latest block), sign the resulting
  /// raw_data_hex with our secp256k1 key, then submit.
  ///
  /// We re-verify the txid locally: sha256(raw_data_hex) should
  /// equal the returned txID, otherwise TronGrid is misbehaving
  /// and we refuse to broadcast.
  Future<String> sendTrx({
    required String destAddress,
    required int amountSun,
  }) async {
    if (_closed) throw StateError('Wallet is closed');
    final destHex = _t58ToHex(destAddress);

    PeekLogger.I.log('trx',
        'TRX send: $amountSun sun to ${destAddress.substring(0, 10)}…');

    final unsigned = await _client.createNativeTransaction(
      ownerHexAddress: address.hexAddress,
      toHexAddress: destHex,
      amountSun: amountSun,
    );
    _verifyHostedTx(unsigned);

    return _signAndBroadcast(unsigned);
  }

  /// Send a TRC-20 token. Same hosted-build/local-sign flow as
  /// [sendTrx]; only the underlying tx is a smart-contract call
  /// rather than a native transfer.
  Future<String> sendTrc20({
    required Trc20Token token,
    required String destAddress,
    required BigInt amountRaw,
  }) async {
    if (_closed) throw StateError('Wallet is closed');
    final destHex = _t58ToHex(destAddress);
    final contractHex = _t58ToHex(token.contract);

    PeekLogger.I.log('trx',
        '${token.symbol} send: $amountRaw raw to ${destAddress.substring(0, 10)}…');

    final unsigned = await _client.createTrc20Transfer(
      ownerHexAddress: address.hexAddress,
      contractHexAddress: contractHex,
      toHexAddress: destHex,
      amountBaseUnits: amountRaw,
    );
    _verifyHostedTx(unsigned);

    return _signAndBroadcast(unsigned);
  }

  /// Re-compute the txid from raw_data_hex and ensure it matches
  /// what TronGrid returned. Doesn't validate the protobuf contents
  /// (we'd need a decoder for that) but catches the simplest class
  /// of host-tampering: returning a tx that hashes to a different
  /// txid than claimed.
  void _verifyHostedTx(TronUnsignedTx unsigned) {
    final bytes = _hexToBytes(unsigned.rawDataHex);
    final recomputed = sha256.convert(bytes).bytes;
    final recomputedHex = recomputed
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    if (recomputedHex.toLowerCase() != unsigned.txid.toLowerCase()) {
      throw StateError(
          'Tron host txid mismatch: ${unsigned.txid} vs '
          '${recomputedHex.substring(0, 16)}… — refusing to broadcast');
    }
  }

  Future<String> _signAndBroadcast(TronUnsignedTx unsigned) async {
    // Re-derive the private key on demand — receive-time we only
    // stored the public part.
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
    final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
    final child = root.derivePath(address.path);
    final privKey = Uint8List.fromList(child.privateKey!);
    final pubKey = Uint8List.fromList(child.publicKey);

    final sigHex = signTronTransaction(
      rawDataHex: unsigned.rawDataHex,
      privateKey: privKey,
      expectedPublicKey: pubKey,
    );

    final signed = TronSignedTx(
      txid: unsigned.txid,
      rawData: unsigned.rawData,
      rawDataHex: unsigned.rawDataHex,
      signatureHex: sigHex,
    );
    final txid = await _client.broadcastTransaction(signed);
    PeekLogger.I.log('trx', 'broadcast tx $txid');
    return txid;
  }

  Uint8List _hexToBytes(String hex) {
    var clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (clean.length.isOdd) clean = '0$clean';
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(2 * i, 2 * i + 2), radix: 16);
    }
    return out;
  }

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
