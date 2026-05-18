import 'dart:async';

import '../../util/peek_logger.dart';
import 'solana_keys.dart';
import 'solana_rpc_client.dart';

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
  }) : _rpc = SolanaRpcClient();

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

  void close() {
    if (_closed) return;
    _closed = true;
    _rpc.close();
  }
}
