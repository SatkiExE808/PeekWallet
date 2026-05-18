import 'dart:async';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;

import '../../util/peek_logger.dart';
import 'erc20.dart';
import 'erc20_tokens.dart';
import 'eth_network.dart';
import 'eth_rpc_client.dart';
import 'eth_tx_builder.dart';
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
    required this.network,
  })  : _client = EtherscanClient(baseUrl: network.blockscoutBaseUrl),
        _rpc = EthRpcClient(endpoint: network.rpcUrl);

  /// Open an EVM wallet for the given seed + network. Defaults to
  /// Ethereum mainnet; pass [kPolygonMainnet] (or any other
  /// [EthereumNetwork]) to target a different chain.
  factory EthereumWallet.open({
    required String mnemonic,
    String passphrase = '',
    EthereumNetwork network = kEthMainnet,
  }) {
    // Every common EVM wallet uses coinType=60 for every EVM chain
    // — the account-based model means the same private key holds
    // balances on all of them simultaneously. We follow that
    // convention, so the [network.coinType] field is informational
    // only at the moment.
    final addr = deriveEthereumAddress(
      mnemonic: mnemonic,
      passphrase: passphrase,
    );
    return EthereumWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      address: addr,
      network: network,
    );
  }

  final String mnemonic;
  final String passphrase;
  final EthereumAddressDerivation address;
  /// Which EVM chain this wallet talks to.
  final EthereumNetwork network;
  final EtherscanClient _client;
  final EthRpcClient _rpc;
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
      PeekLogger.I.log(_logTag, 'balance fetched: $b wei');
      return b;
    } catch (e) {
      PeekLogger.I.log(_logTag, 'balance fetch failed: $e');
      rethrow;
    }
  }

  String get _logTag => network.symbol.toLowerCase();

  /// Recent transactions, newest first.
  Future<List<EthereumTx>> transactions() async {
    if (_closed) return const [];
    try {
      return await _client.transactions(address.addressLower);
    } catch (e) {
      PeekLogger.I.log(_logTag, 'history fetch failed: $e');
      return const [];
    }
  }

  /// Read the raw ERC-20 balance (in base units, not display units)
  /// for [token]. Wraps eth_call balanceOf.
  Future<BigInt> tokenBalanceRaw(Erc20Token token) async {
    if (_closed) return BigInt.zero;
    try {
      final result = await _rpc.ethCall(
        to: token.contract,
        data: encodeBalanceOfCall(address.addressLower),
      );
      return decodeUint256(result);
    } catch (e) {
      PeekLogger.I.log(_logTag,
          '${token.symbol} balance fetch failed: $e');
      return BigInt.zero;
    }
  }

  /// Convenience: convert raw → display units via 10^decimals.
  /// Returns a double for display only; for arithmetic on amounts
  /// you'd want BigInt to avoid precision loss on tokens with 18+
  /// decimals + large balances.
  double tokenBalanceDisplay(BigInt raw, Erc20Token token) {
    return raw.toDouble() /
        BigInt.from(10).pow(token.decimals).toDouble();
  }

  /// Default token list for this wallet's chain.
  List<Erc20Token> get defaultTokens => defaultTokensFor(network.chainId);

  /// Live fee suggestion bundle for the send screen.
  Future<EthFeeSuggestion> feeSuggestion() async {
    final base = await _rpc.baseFeePerGas();
    final tip = await _rpc.maxPriorityFeePerGas();
    // maxFee = 2*base + tip — protects against the base fee climbing
    // between when we sign and when the tx is included. Same heuristic
    // MetaMask uses for the "Market" fee tier.
    final maxFee = base * BigInt.two + tip;
    return EthFeeSuggestion(
      baseFeeWei: base,
      maxPriorityFeeWei: tip,
      maxFeeWei: maxFee,
    );
  }

  /// Current pending-state nonce — what we should use for the next tx.
  Future<BigInt> nonce() => _rpc.getTransactionCount(address.addressLower);

  /// Build, sign, and broadcast an EIP-1559 transfer.
  ///
  /// - Native send (default): pass [destAddress] + [valueWei]. Tx
  ///   `to` is the recipient, `value` is the wei amount, `data`
  ///   is empty.
  /// - Token send: also pass [token] + [tokenAmountRaw]. Tx `to`
  ///   becomes the token contract, `value` is 0, `data` is the
  ///   ABI-encoded `transfer(destAddress, tokenAmountRaw)` call.
  ///   The caller's [destAddress] is the human-visible recipient
  ///   even though it's not the wire-level `to`.
  ///
  /// The RPC's chainId is sanity-checked against this wallet's
  /// network before signing — if Settings → Custom RPC ever sends
  /// us to Sepolia by accident, we catch it before burning nonce.
  Future<BuiltEthereumTransaction> sendEth({
    required String destAddress,
    required BigInt valueWei,
    required BigInt maxPriorityFeeWei,
    required BigInt maxFeeWei,
    Erc20Token? token,
    BigInt? tokenAmountRaw,
  }) async {
    if (_closed) throw StateError('Wallet is closed');

    final chainId = await _rpc.chainId();
    if (chainId != network.chainId) {
      throw StateError(
          'RPC reports chainId=$chainId, refusing to sign — '
          'expected ${network.chainId} (${network.name})');
    }

    final nonceVal = await _rpc.getTransactionCount(address.addressLower);

    // For token sends, the on-wire `to` is the contract and `data`
    // is the ABI-encoded transfer call. For native sends, `to` is
    // the recipient and `data` is empty.
    final String wireTo;
    final BigInt wireValue;
    final Uint8List? wireData;
    if (token != null) {
      if (tokenAmountRaw == null || tokenAmountRaw <= BigInt.zero) {
        throw ArgumentError('tokenAmountRaw must be > 0 for token sends');
      }
      wireTo = token.contract;
      wireValue = BigInt.zero;
      final dataHex = encodeTransferCall(
        to0xAddress: destAddress,
        amountBaseUnits: tokenAmountRaw,
      );
      wireData = Uint8List.fromList(_hexToBytes(dataHex));
    } else {
      wireTo = destAddress;
      wireValue = valueWei;
      wireData = null;
    }

    final gasLimit = await _rpc.estimateGas(
      from: address.addressLower,
      to: wireTo,
      valueWei: wireValue,
      dataHex: wireData == null
          ? null
          : '0x${wireData.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
    );

    final logSummary = token == null
        ? '$valueWei wei'
        : '$tokenAmountRaw ${token.symbol} (raw)';
    PeekLogger.I.log(
      _logTag,
      'send requested: $logSummary to '
          '${destAddress.length >= 12 ? '${destAddress.substring(0, 10)}…' : destAddress} '
          'nonce=$nonceVal gas=$gasLimit maxFee=$maxFeeWei',
    );

    // Re-derive the private key on demand — receive-time we only
    // stored the public part. We have to redo BIP44 here because
    // ethereum_keys.dart's public API is publickey-only by design.
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
    final root = bip32.BIP32.fromSeed(Uint8List.fromList(seed));
    final child = root.derivePath(address.path);
    final privKey = Uint8List.fromList(child.privateKey!);
    final pubKey = Uint8List.fromList(child.publicKey);

    final built = buildAndSignEip1559(
      chainId: chainId,
      nonce: nonceVal,
      maxPriorityFeePerGasWei: maxPriorityFeeWei,
      maxFeePerGasWei: maxFeeWei,
      gasLimit: gasLimit,
      toAddress: wireTo,
      valueWei: wireValue,
      data: wireData,
      privateKey: privKey,
      expectedPublicKey: pubKey,
    );

    PeekLogger.I.log(_logTag,
        'broadcasting tx ${built.txHash} (gas $gasLimit @ $maxFeeWei wei)');
    final txid = await _rpc.sendRawTransaction(built.rawHex);
    if (txid.toLowerCase() != built.txHash.toLowerCase()) {
      PeekLogger.I.log(_logTag,
          'WARNING: RPC returned txid $txid but we computed ${built.txHash}');
    }
    return built;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
    _rpc.close();
  }
}

/// Bundle of fee suggestions returned by [EthereumWallet.feeSuggestion].
/// Fee math: maxFee = 2 * baseFee + maxPriority, where the 2× base-fee
/// buffer absorbs the chain's per-block fee adjustment between sign
/// and include. Anything left over after include returns as gas
/// refund to the sender — there's no risk of overpaying.
class EthFeeSuggestion {
  const EthFeeSuggestion({
    required this.baseFeeWei,
    required this.maxPriorityFeeWei,
    required this.maxFeeWei,
  });
  final BigInt baseFeeWei;
  final BigInt maxPriorityFeeWei;
  final BigInt maxFeeWei;
}

/// Plain hex → bytes; treats an optional 0x prefix as ignored. Used
/// internally for assembling the ERC-20 `data` payload of a token
/// send. Kept private because erc20.dart already has its own helper
/// that I don't want to over-export.
List<int> _hexToBytes(String hex) {
  var clean = hex.startsWith('0x') || hex.startsWith('0X')
      ? hex.substring(2)
      : hex;
  if (clean.length.isOdd) clean = '0$clean';
  final out = List<int>.filled(clean.length ~/ 2, 0);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}
