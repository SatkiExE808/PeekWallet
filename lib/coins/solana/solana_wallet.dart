import 'dart:async';

import '../../prefs/rpc_overrides.dart';
import '../../util/peek_logger.dart';
import 'pda.dart' as pda;
import 'sol_tx_builder.dart';
import 'solana_keys.dart';
import 'solana_rpc_client.dart';
import 'spl_tokens.dart';

/// Runtime handle for a Solana wallet — derive address + poll
/// mainnet-beta RPC for balance and history. Send (build/sign a
/// SystemProgram.transfer + broadcast) is a follow-up; for now this
/// is receive + monitor.
///
/// Account-based chain (like Ethereum) so there's no gap-limit
/// machinery — one address per account is enough for the user-visible
/// flow.
class SolanaWallet {
  SolanaWallet._({
    required this.mnemonic,
    required this.passphrase,
    required this.address,
  }) : _rpc = _buildRpcClient();

  /// User override (if any) is tried first, then the public mainnet-
  /// beta RPC + community fallbacks (Ankr, Blast, PublicNode). The
  /// fallbacks are intentionally included even when the user pinned a
  /// custom endpoint — Solana's mainnet-beta drops connections often
  /// enough that a safety net is worth the privacy tradeoff.
  static SolanaRpcClient _buildRpcClient() {
    final override = RpcOverrides.I.get('SOL', 'rpc');
    if (override == null || override.isEmpty) {
      return SolanaRpcClient();
    }
    return SolanaRpcClient(endpoints: [
      override,
      'https://api.mainnet-beta.solana.com',
      'https://solana-rpc.publicnode.com',
      'https://solana-mainnet.public.blastapi.io',
      'https://rpc.ankr.com/solana',
    ]);
  }

  static Future<SolanaWallet> open({
    required String mnemonic,
    String passphrase = '',
  }) async {
    final addr = await deriveSolanaAddress(
      mnemonic: mnemonic,
      passphrase: passphrase,
    );
    return SolanaWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      address: addr,
    );
  }

  final String mnemonic;
  final String passphrase;
  final SolanaAddressDerivation address;
  final SolanaRpcClient _rpc;
  bool _closed = false;

  String get primaryAddress => address.address;

  /// Confirmed SOL balance in lamports.
  Future<int> balanceLamports() async {
    if (_closed) return 0;
    try {
      final v = await _rpc.balanceLamports(address.address);
      PeekLogger.I.log('sol', 'balance fetched: $v lamports');
      return v;
    } catch (e) {
      PeekLogger.I.log('sol', 'balance fetch failed: $e');
      rethrow;
    }
  }

  /// Recent transactions, newest first. Resolves each signature to
  /// the full tx so we can show the user the net balance change.
  Future<List<SolanaTxDetail>> transactions({int limit = 25}) async {
    if (_closed) return const [];
    try {
      final summaries = await _rpc.signatures(address.address, limit: limit);
      final detailed = <SolanaTxDetail>[];
      // Resolve sequentially to avoid hammering the public RPC's
      // per-IP rate limit. A real wallet would batch these.
      for (final s in summaries) {
        final detail = await _rpc.transaction(s.signature, address.address);
        if (detail != null) detailed.add(detail);
      }
      return detailed;
    } catch (e) {
      PeekLogger.I.log('sol', 'history fetch failed: $e');
      return const [];
    }
  }

  /// Build, sign, and broadcast a SystemProgram.transfer.
  ///
  /// Returns the tx signature (the same value the explorer shows as
  /// "Tx Hash"). On failure throws the upstream RPC error.
  Future<BuiltSolanaTransaction> sendSol({
    required String destAddress,
    required int lamports,
  }) async {
    if (_closed) throw StateError('Wallet is closed');

    final blockhashStr = await _rpc.latestBlockhash();
    final blockhash = base58Decode(blockhashStr);
    if (blockhash == null || blockhash.length != 32) {
      throw StateError(
          'Unexpected blockhash from RPC: $blockhashStr');
    }

    PeekLogger.I.log(
      'sol',
      'send requested: $lamports lamports to '
          '${destAddress.length >= 12 ? '${destAddress.substring(0, 10)}…' : destAddress}',
    );

    final built = await buildAndSignTransfer(
      fromPubkey: address.publicKey,
      fromPrivateSeed: address.privateSeed,
      toAddress: destAddress,
      lamports: lamports,
      recentBlockhash: blockhash,
    );

    final sigFromRpc = await _rpc.sendTransaction(built.rawBase64);
    if (sigFromRpc != built.signature) {
      PeekLogger.I.log('sol',
          'WARNING: RPC returned signature $sigFromRpc but we computed ${built.signature}');
    }
    PeekLogger.I.log('sol',
        'broadcast tx ${built.signature} ($lamports lamports)');
    return built;
  }

  /// Raw SPL token balance (base units) summed across all token
  /// accounts the user owns for this mint. Returns zero if the user
  /// has no accounts yet.
  Future<BigInt> tokenBalanceRaw(SplToken token) async {
    if (_closed) return BigInt.zero;
    try {
      final result = await _rpc.splTokenBalance(
        ownerBase58: address.address,
        mintBase58: token.mint,
      );
      return result.rawAmount;
    } catch (e) {
      PeekLogger.I.log(
          'sol', '${token.symbol} balance fetch failed: $e');
      return BigInt.zero;
    }
  }

  /// Raw → display unit conversion. SPL token decimals come from the
  /// catalog (USDC/USDT = 6); returned as double for display only.
  double tokenBalanceDisplay(BigInt raw, SplToken token) {
    return raw.toDouble() /
        BigInt.from(10).pow(token.decimals).toDouble();
  }

  /// Default SPL token list. Future Settings → Custom Tokens would
  /// extend this per-wallet.
  List<SplToken> get defaultTokens => kDefaultSplTokens;

  /// SPL token transfers for every default token, merged into a
  /// single newest-first list. Each token costs O(limit) RPC calls
  /// (one signatures + N parsed-transaction lookups) so this is
  /// the most expensive method on the wallet — but we only run it
  /// during the periodic 30s refresh, and the result is much more
  /// useful than the bare native-only history.
  Future<List<SolanaTokenTx>> splTransfers({int limit = 15}) async {
    if (_closed) return const [];
    final out = <SolanaTokenTx>[];
    for (final token in defaultTokens) {
      try {
        final ata = await _rpc.firstTokenAccountAddress(
          ownerBase58: address.address,
          mintBase58: token.mint,
        );
        if (ata == null) continue; // user has no account for this mint
        final txs = await _rpc.tokenTransfers(
          tokenAccountAddress: ata,
          mintAddress: token.mint,
          tokenSymbol: token.symbol,
          tokenDecimals: token.decimals,
          walletOwnerAddress: address.address,
          limit: limit,
        );
        out.addAll(txs);
      } catch (e) {
        PeekLogger.I.log('sol',
            '${token.symbol} history fetch failed: $e');
        // Continue to the next token rather than failing the whole
        // history fetch.
      }
    }
    return out;
  }

  /// Build, sign and broadcast an SPL token transfer. Returns the
  /// transaction signature (the on-chain id) on success.
  ///
  /// Requires the recipient to ALREADY have a token account for
  /// this mint (an "ATA"). If they don't, this throws with a clear
  /// message — the user can ask the recipient to receive SOL or any
  /// other asset first to create the account, then retry.
  ///
  /// We don't compute the ATA address client-side (PDA derivation
  /// needs ed25519 off-curve checks). Instead we call the RPC for
  /// both sender + recipient token accounts and use the first one
  /// each side has — works for the dominant case where users have
  /// exactly one account per mint (the canonical ATA).
  Future<BuiltSolanaTransaction> sendSpl({
    required SplToken token,
    required String destOwnerAddress,
    required BigInt amountRaw,
  }) async {
    if (_closed) throw StateError('Wallet is closed');

    final sourceATA = await _rpc.firstTokenAccountAddress(
      ownerBase58: address.address,
      mintBase58: token.mint,
    );
    if (sourceATA == null) {
      throw StateError(
          'No ${token.symbol} token account found for this wallet. '
          'Receive the token here first.');
    }

    // Look up the recipient's existing ATA. If they have one, use
    // it directly. If they don't, derive the canonical ATA address
    // client-side via PDA so we know where to send AND emit a
    // CreateAssociatedTokenAccount instruction (idempotent variant)
    // ahead of the transfer. The funding (~0.002 SOL rent) comes
    // from our SOL balance.
    var destATA = await _rpc.firstTokenAccountAddress(
      ownerBase58: destOwnerAddress,
      mintBase58: token.mint,
    );
    var shouldCreate = false;
    final destOwnerBytes = base58Decode(destOwnerAddress);
    final mintBytes = base58Decode(token.mint);
    if (destOwnerBytes == null || destOwnerBytes.length != 32) {
      throw StateError(
          'Recipient address $destOwnerAddress does not decode to 32 bytes');
    }
    if (mintBytes == null || mintBytes.length != 32) {
      throw StateError('Token mint ${token.mint} is malformed');
    }
    if (destATA == null) {
      final derived = pda.associatedTokenAddress(
        owner: destOwnerBytes,
        mint: mintBytes,
      );
      destATA = base58Encode(derived);
      shouldCreate = true;
      PeekLogger.I.log(
        'sol',
        '${token.symbol} send: recipient has no ATA; will create '
            '${destATA.substring(0, 10)}… (rent ~0.002 SOL from sender)',
      );
    }

    final blockhashStr = await _rpc.latestBlockhash();
    final blockhash = base58Decode(blockhashStr);
    if (blockhash == null || blockhash.length != 32) {
      throw StateError('Unexpected blockhash from RPC: $blockhashStr');
    }

    PeekLogger.I.log(
      'sol',
      '${token.symbol} send requested: $amountRaw raw to '
          '${destOwnerAddress.length >= 10 ? '${destOwnerAddress.substring(0, 10)}…' : destOwnerAddress}',
    );

    final built = await buildAndSignSplTransfer(
      ownerPubkey: address.publicKey,
      ownerPrivateSeed: address.privateSeed,
      sourceATABase58: sourceATA,
      destATABase58: destATA,
      amountRaw: amountRaw,
      recentBlockhash: blockhash,
      createDestATA: shouldCreate,
      destOwner: shouldCreate ? destOwnerBytes : null,
      mint: shouldCreate ? mintBytes : null,
    );

    final sigFromRpc = await _rpc.sendTransaction(built.rawBase64);
    if (sigFromRpc != built.signature) {
      PeekLogger.I.log('sol',
          'WARNING: RPC returned signature $sigFromRpc but we computed ${built.signature}');
    }
    PeekLogger.I.log('sol',
        'broadcast SPL transfer ${built.signature} ($amountRaw ${token.symbol} raw)');
    return built;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _rpc.close();
  }
}
