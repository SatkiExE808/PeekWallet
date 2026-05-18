// Solana legacy-transaction builder + signer.
//
// Solana doesn't use RLP or Bitcoin-style varints; instead it has
// its own "compact-u16" varint (a 1-3 byte little-endian length
// prefix) wrapping every array. A transaction is:
//
//   compactArray<Signature>      // 64-byte ed25519 sigs, one per signer
//   message:
//     header: 3 u8s              // numRequiredSigs, numROSigned, numROUnsigned
//     compactArray<Pubkey>       // 32-byte ed25519 public keys
//     recentBlockhash: 32 bytes  // anti-replay; expires after ~150 slots
//     compactArray<Instruction>:
//       programIdIndex: u8       // which accountKey is the program
//       compactArray<u8>         // which accountKeys this instruction touches
//       compactArray<u8>         // program-specific binary data
//
// For a simple SystemProgram.transfer:
//   programId   = SystemProgram (11111111111111111111111111111111 base58)
//   accountKeys = [from, to, SystemProgram]
//   instruction data = [0x02, 0x00, 0x00, 0x00, lamports_u64_LE]
//                       └─ "Transfer" variant discriminator ────────────┘
//
// We sign the SERIALIZED MESSAGE bytes (everything from header to
// end of instructions), prepend the resulting 64-byte signature in
// the signatures slot, and submit the full transaction as base64
// via sendTransaction RPC.
//
// Specification reference: solana_program docs (`Transaction`,
// `Message`, `system_instruction::transfer`) — the wire format is
// stable across Solana versions; new transactions (v0) add address-
// lookup-table support which we deliberately don't use, keeping us
// in the simpler "legacy" format.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'pda.dart' as pda;
import 'solana_keys.dart';

/// SystemProgram's well-known address. Constant string;
/// "11111111111111111111111111111111" in base58 = 32 zero bytes.
final Uint8List _systemProgramId = Uint8List(32);

// SPL Token Program address is exposed by pda.dart — we use
// pda.splTokenProgramId throughout. (Was duplicated here pre-PDA.)

/// Result of building+signing a Solana transfer transaction.
class BuiltSolanaTransaction {
  const BuiltSolanaTransaction({
    required this.rawBase64,
    required this.signature,
    required this.lamports,
  });
  /// Wire-format payload. POST as `params: [rawBase64, {encoding: 'base64'}]`
  /// to sendTransaction.
  final String rawBase64;
  /// 64-byte ed25519 signature, base58-encoded. Solana uses the
  /// signature as the tx identifier — same value the explorer shows
  /// as "Tx Hash".
  final String signature;
  /// Amount in lamports (for the UI preview / success message).
  final int lamports;
}

class InvalidSolanaAddressException implements Exception {
  const InvalidSolanaAddressException(this.message);
  final String message;
  @override
  String toString() => 'InvalidSolanaAddress: $message';
}

/// Build, sign, and serialize a SystemProgram.transfer transaction.
///
/// - [fromPubkey] / [fromPrivateSeed]: the signer's ed25519 keypair
///   material. The wallet's [SolanaAddressDerivation] carries both.
/// - [toAddress]: recipient, base58.
/// - [lamports]: amount to send (1 SOL = 10^9 lamports).
/// - [recentBlockhash]: 32-byte hash from `getLatestBlockhash`.
Future<BuiltSolanaTransaction> buildAndSignTransfer({
  required Uint8List fromPubkey,
  required Uint8List fromPrivateSeed,
  required String toAddress,
  required int lamports,
  required Uint8List recentBlockhash,
}) async {
  if (lamports <= 0) {
    throw const InvalidSolanaAddressException('Amount must be positive');
  }
  if (recentBlockhash.length != 32) {
    throw const InvalidSolanaAddressException(
        'Recent blockhash must be 32 bytes');
  }

  final toPubkey = base58Decode(toAddress);
  if (toPubkey == null || toPubkey.length != 32) {
    throw InvalidSolanaAddressException(
        'Recipient must be a base58-encoded 32-byte Solana address; '
        'got ${toPubkey?.length ?? 0} bytes');
  }

  // Account list order matters: signers come first, then writable
  // non-signers, then read-only signers, then read-only non-signers.
  // For a simple transfer:
  //   - from: signer + writable
  //   - to:   non-signer + writable
  //   - SystemProgram: non-signer + read-only
  // So the order is [from, to, SystemProgram] with header counts
  // (1 required sig, 0 ro-signed, 1 ro-unsigned).
  final accountKeys = <Uint8List>[fromPubkey, toPubkey, _systemProgramId];
  const numRequiredSignatures = 1;
  const numReadonlySigned = 0;
  const numReadonlyUnsigned = 1; // SystemProgram is read-only

  // Instruction:
  //   programIdIndex: 2 (points at SystemProgram in accountKeys)
  //   accounts:       [0, 1]  (from, to)
  //   data:           [0x02, 0x00, 0x00, 0x00, lamports as u64 LE]
  final transferData = Uint8List(4 + 8);
  // discriminator 2 = Transfer
  transferData[0] = 2;
  // lamports as little-endian u64
  final amount = ByteData(8)..setUint64(0, lamports, Endian.little);
  transferData.setRange(4, 12, amount.buffer.asUint8List());

  final instruction = _CompiledInstruction(
    programIdIndex: 2,
    accountIndices: Uint8List.fromList([0, 1]),
    data: transferData,
  );

  // Serialize the message.
  final message = _serializeMessage(
    header: [
      numRequiredSignatures,
      numReadonlySigned,
      numReadonlyUnsigned,
    ],
    accountKeys: accountKeys,
    recentBlockhash: recentBlockhash,
    instructions: [instruction],
  );

  // Sign the message bytes with ed25519. The cryptography package
  // gives back a Signature; we extract the 64 raw bytes for the
  // wire format.
  final alg = Ed25519();
  final keyPair = await alg.newKeyPairFromSeed(fromPrivateSeed);
  final sig = await alg.sign(message, keyPair: keyPair);
  final sigBytes = Uint8List.fromList(sig.bytes);
  if (sigBytes.length != 64) {
    throw StateError(
        'Ed25519 signature should be 64 bytes, got ${sigBytes.length}');
  }

  // Wire transaction: compactArray<Signature> || Message
  final txBytes = BytesBuilder();
  txBytes.add(_compactU16(1)); // single signer
  txBytes.add(sigBytes);
  txBytes.add(message);

  return BuiltSolanaTransaction(
    rawBase64: _base64Encode(txBytes.toBytes()),
    signature: base58Encode(sigBytes),
    lamports: lamports,
  );
}

/// Build, sign, and serialize an SPL Token Program transfer.
///
/// Pre-conditions:
///   - [sourceATA] is the sender's token account for the mint
///     (32-byte base58 pubkey). Must already exist; we just looked
///     up the balance so this is always the case.
///   - [destATA] is the recipient's token account.
///   - [destOwner] / [mint] / [createDestATA]: if [createDestATA]
///     is true we prepend a CreateAssociatedTokenAccount instruction
///     so the recipient gets an ATA even if they've never received
///     this mint before. The funding (rent ~0.002 SOL) comes from
///     the sender's native SOL balance.
Future<BuiltSolanaTransaction> buildAndSignSplTransfer({
  required Uint8List ownerPubkey,
  required Uint8List ownerPrivateSeed,
  required String sourceATABase58,
  required String destATABase58,
  required BigInt amountRaw,
  required Uint8List recentBlockhash,
  bool createDestATA = false,
  Uint8List? destOwner,
  Uint8List? mint,
}) async {
  if (amountRaw <= BigInt.zero) {
    throw const InvalidSolanaAddressException(
        'Amount must be positive');
  }
  if (recentBlockhash.length != 32) {
    throw const InvalidSolanaAddressException(
        'Recent blockhash must be 32 bytes');
  }
  if (createDestATA && (destOwner == null || mint == null)) {
    throw ArgumentError(
        'destOwner + mint are required when createDestATA=true');
  }

  final sourceBytes = base58Decode(sourceATABase58);
  final destBytes = base58Decode(destATABase58);
  if (sourceBytes == null ||
      sourceBytes.length != 32 ||
      destBytes == null ||
      destBytes.length != 32) {
    throw const InvalidSolanaAddressException(
        'Token account address must decode to 32 bytes');
  }

  // Build the account list. Order matters for the message header
  // counts; signers first, then writable non-signers, then read-only
  // signers, then read-only non-signers.
  //
  // For a transfer alone:
  //   [owner (signer), sourceATA (writable), destATA (writable),
  //    TokenProgram (readonly)]
  //
  // For transfer + CreateATA, we also need: destOwner (readonly),
  // mint (readonly), SystemProgram (readonly), ATA Program (readonly).
  // We dedupe so we don't list TokenProgram twice.
  final accountKeys = <Uint8List>[
    ownerPubkey, // 0: signer + writable (pays for rent if creating)
    sourceBytes, // 1: writable non-signer
    destBytes, // 2: writable non-signer
  ];
  if (createDestATA) {
    accountKeys.addAll([
      destOwner!, // 3: readonly non-signer
      mint!, // 4: readonly non-signer
      pda.systemProgramId, // 5: readonly non-signer
      pda.ataProgramId, // 6: readonly non-signer
    ]);
  }
  accountKeys.add(pda.splTokenProgramId);
  // Token Program lands at index (accountKeys.length - 1) — for
  // a bare transfer that's 3; for create+transfer it's 7.
  final tokenProgramIdx = accountKeys.length - 1;

  // Header counts:
  //   numRequiredSignatures = 1 (just the owner)
  //   numReadonlySigned     = 0
  //   numReadonlyUnsigned   = however many trailing readonly accounts.
  //   The order above puts writables (source, dest) immediately after
  //   the signer and readonlies (destOwner, mint, systemProgram,
  //   ataProgram, tokenProgram) after that.
  final numReadonlyUnsigned = createDestATA ? 5 : 1;
  const numRequiredSignatures = 1;
  const numReadonlySigned = 0;

  final instructions = <_CompiledInstruction>[];

  if (createDestATA) {
    // CreateAssociatedTokenAccountIdempotent instruction:
    //   data: [1] (the idempotent variant — safe to send even if
    //         the ATA already exists; that's the cheapest safety
    //         net for the case where the user's pre-flight check
    //         said "no ATA" but a race created one in between)
    //   accounts (per ATA program spec):
    //     0: funding (signer + writable) — pays rent
    //     1: ATA address (writable)
    //     2: ATA owner (readonly)
    //     3: mint (readonly)
    //     4: SystemProgram (readonly)
    //     5: TokenProgram (readonly)
    instructions.add(_CompiledInstruction(
      programIdIndex: 6, // ataProgramId in accountKeys
      accountIndices: Uint8List.fromList([
        0, // funding = owner
        2, // ATA address = destATA
        3, // owner of ATA = destOwner
        4, // mint
        5, // SystemProgram
        tokenProgramIdx,
      ]),
      data: Uint8List.fromList([1]), // idempotent variant
    ));
  }

  // Transfer instruction: discriminator 3 + amount u64 LE.
  final transferData = Uint8List(1 + 8);
  transferData[0] = 3;
  final amountLE = ByteData(8);
  var n = amountRaw;
  for (var i = 0; i < 8; i++) {
    amountLE.setUint8(i, (n & BigInt.from(0xff)).toInt());
    n = n >> 8;
  }
  transferData.setRange(1, 9, amountLE.buffer.asUint8List());

  instructions.add(_CompiledInstruction(
    programIdIndex: tokenProgramIdx,
    accountIndices: Uint8List.fromList([1, 2, 0]), // source, dest, owner
    data: transferData,
  ));

  final message = _serializeMessage(
    header: [
      numRequiredSignatures,
      numReadonlySigned,
      numReadonlyUnsigned,
    ],
    accountKeys: accountKeys,
    recentBlockhash: recentBlockhash,
    instructions: instructions,
  );

  final alg = Ed25519();
  final keyPair = await alg.newKeyPairFromSeed(ownerPrivateSeed);
  final sig = await alg.sign(message, keyPair: keyPair);
  final sigBytes = Uint8List.fromList(sig.bytes);

  final txBytes = BytesBuilder();
  txBytes.add(_compactU16(1));
  txBytes.add(sigBytes);
  txBytes.add(message);

  return BuiltSolanaTransaction(
    rawBase64: _base64Encode(txBytes.toBytes()),
    signature: base58Encode(sigBytes),
    lamports: amountRaw.toInt(), // misnomer for SPL; just a tag
  );
}

class _CompiledInstruction {
  const _CompiledInstruction({
    required this.programIdIndex,
    required this.accountIndices,
    required this.data,
  });
  final int programIdIndex;
  final Uint8List accountIndices;
  final Uint8List data;
}

Uint8List _serializeMessage({
  required List<int> header,
  required List<Uint8List> accountKeys,
  required Uint8List recentBlockhash,
  required List<_CompiledInstruction> instructions,
}) {
  final out = BytesBuilder();
  out.add(Uint8List.fromList(header)); // 3 bytes
  // compactArray<Pubkey>
  out.add(_compactU16(accountKeys.length));
  for (final k in accountKeys) {
    if (k.length != 32) {
      throw StateError('Account keys must be 32 bytes, got ${k.length}');
    }
    out.add(k);
  }
  out.add(recentBlockhash);
  // compactArray<CompiledInstruction>
  out.add(_compactU16(instructions.length));
  for (final ins in instructions) {
    out.addByte(ins.programIdIndex);
    out.add(_compactU16(ins.accountIndices.length));
    out.add(ins.accountIndices);
    out.add(_compactU16(ins.data.length));
    out.add(ins.data);
  }
  return out.toBytes();
}

/// Solana's "compact-u16": variable-length encoding of an unsigned
/// 16-bit integer using 1-3 bytes. Same idea as protobuf varints
/// but capped at u16:
///   value 0..0x7f:        single byte
///   value 0x80..0x3fff:   two bytes (each carrying 7 bits, high bit
///                         set on the first to mark continuation)
///   value 0x4000..0xffff: three bytes
Uint8List _compactU16(int n) {
  if (n < 0 || n > 0xffff) {
    throw ArgumentError('compact-u16 out of range: $n');
  }
  final out = <int>[];
  var v = n;
  while (true) {
    var b = v & 0x7f;
    v >>= 7;
    if (v == 0) {
      out.add(b);
      break;
    }
    out.add(b | 0x80);
  }
  return Uint8List.fromList(out);
}

/// Standard base64 encoding (RFC 4648 with padding) — what Solana's
/// sendTransaction RPC expects when called with `encoding: 'base64'`.
String _base64Encode(Uint8List bytes) => base64.encode(bytes);
