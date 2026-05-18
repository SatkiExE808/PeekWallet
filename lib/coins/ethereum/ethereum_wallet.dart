import 'dart:async';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;

import '../../util/peek_logger.dart';
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

  /// Build, sign, and broadcast an EIP-1559 ETH transfer.
  ///
  /// - [destAddress]: recipient (0x-prefixed hex, EIP-55 OK).
  /// - [valueWei]: amount in wei.
  /// - [maxPriorityFeeWei] / [maxFeeWei]: fee tiers (use
  ///   [feeSuggestion] for the standard "Market" pair).
  ///
  /// We sanity-check the RPC's chainId against the mainnet constant
  /// (1) before signing. If a future Settings → Custom RPC sends us
  /// to Sepolia by accident, this catches it before we burn nonce.
  Future<BuiltEthereumTransaction> sendEth({
    required String destAddress,
    required BigInt valueWei,
    required BigInt maxPriorityFeeWei,
    required BigInt maxFeeWei,
  }) async {
    if (_closed) throw StateError('Wallet is closed');

    final chainId = await _rpc.chainId();
    if (chainId != network.chainId) {
      throw StateError(
          'RPC reports chainId=$chainId, refusing to sign — '
          'expected ${network.chainId} (${network.name})');
    }

    final nonceVal = await _rpc.getTransactionCount(address.addressLower);
    final gasLimit = await _rpc.estimateGas(
      from: address.addressLower,
      to: destAddress,
      valueWei: valueWei,
    );

    PeekLogger.I.log(
      _logTag,
      'send requested: $valueWei wei to '
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
      toAddress: destAddress,
      valueWei: valueWei,
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
