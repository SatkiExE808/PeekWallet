// Pure-Dart BIP143 (P2WPKH) transaction builder + signer.
//
// We chose NOT to depend on coinlib for this. coinlib's Flutter
// integration requires a per-arch native libsecp256k1 build, which
// adds CI complexity and supply-chain surface to a wallet app. The
// signing primitives we already pull in (bip32's pointycastle-backed
// ECDSA + sha256 + ripemd160) are enough.
//
// Specification references (read these alongside the code):
//   BIP-0143: SegWit transaction signature verification
//   BIP-0141: Segregated Witness (consensus layer)
//   BIP-0084: Derivation scheme for P2WPKH-based accounts
//
// Test coverage in test/bitcoin_tx_builder_test.dart pins the
// sighash + signed-tx output against BIP143's "Native P2WPKH" worked
// example. If you change anything in this file, the spec-vector test
// MUST still pass — otherwise we'll silently produce transactions
// that look fine but burn fees / lose funds.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'bitcoin_keys.dart';
import 'chain_params.dart';
import 'mempool_client.dart';

/// Result of a successful build+sign. The caller broadcasts [rawHex]
/// and records [txid] in the local history so the UI can show the
/// pending tx immediately, before mempool.space picks it up.
class BuiltBitcoinTransaction {
  const BuiltBitcoinTransaction({
    required this.rawHex,
    required this.txid,
    required this.virtualSize,
    required this.feeSat,
    required this.changeSat,
    required this.recipientSat,
  });

  /// Raw hex ready to POST to /tx.
  final String rawHex;
  /// Standard txid (double-SHA256 of the non-witness serialization),
  /// big-endian display form. Matches what every block explorer shows.
  final String txid;
  /// Virtual size in vBytes per BIP141 — what the network charges for.
  /// Used for the fee-rate display: feeRate ≈ feeSat / virtualSize.
  final int virtualSize;
  final int feeSat;
  /// Change actually paid back to the wallet. Zero if the change was
  /// below dust threshold and got rolled into the fee.
  final int changeSat;
  final int recipientSat;
}

class InsufficientFundsException implements Exception {
  const InsufficientFundsException(this.message);
  final String message;
  @override
  String toString() => 'InsufficientFunds: $message';
}

class InvalidBitcoinAddressException implements Exception {
  const InvalidBitcoinAddressException(this.message);
  final String message;
  @override
  String toString() => 'InvalidBitcoinAddress: $message';
}

/// Build + sign a P2WPKH transaction. The caller owns coin selection
/// — picking which UTXOs to spend is intentionally NOT done here so
/// the UI can show the user exactly what's being spent (transparency
/// > magic). For simple cases see [selectUtxosGreedy] below.
///
/// All inputs MUST be P2WPKH outputs owned by [signers]. If a UTXO's
/// owning address isn't in [signers], we throw — better to fail loud
/// than produce an unsignable tx.
///
/// Outputs are: [destAddress] for [amountSat], plus a change output
/// back to [changeAddress] (omitted if change would be below dust).
///
/// [feeRateSatPerVByte] is multiplied by the estimated vsize. The
/// resulting fee is taken from the change output; if change goes
/// negative we throw InsufficientFunds.
BuiltBitcoinTransaction buildAndSignP2WPKH({
  required List<Utxo> inputs,
  required Map<String, BitcoinSpendingKey> signers,
  required String destAddress,
  required int amountSat,
  required String changeAddress,
  required int feeRateSatPerVByte,
  BitcoinChainParams params = kBtcMainnet,
}) {
  if (inputs.isEmpty) {
    throw const InsufficientFundsException('No UTXOs provided');
  }
  if (amountSat <= 0) {
    throw const InvalidBitcoinAddressException('Amount must be positive');
  }
  if (feeRateSatPerVByte <= 0) {
    throw const InvalidBitcoinAddressException('Fee rate must be positive');
  }

  // Parse destination address to its pubkey hash. This validates that
  // it's a real bech32 P2WPKH address on the right network; any other
  // format throws here, before the user signs anything.
  final destPkh = decodeP2WPKHAddress(destAddress, params: params);
  final changePkh = decodeP2WPKHAddress(changeAddress, params: params);

  // Resolve a signer for every input. Missing signer = wallet doesn't
  // own this UTXO, which would mean the caller passed garbage.
  final keys = <BitcoinSpendingKey>[];
  for (final utxo in inputs) {
    final k = signers[utxo.address];
    if (k == null) {
      throw InvalidBitcoinAddressException(
        'Missing private key for UTXO address ${utxo.address}',
      );
    }
    keys.add(k);
  }

  final totalIn = inputs.fold<int>(0, (sum, u) => sum + u.valueSat);

  // First-pass fee: assume change is included. We compute vsize from
  // a fully-signed witness (signatures are 71-73 bytes; we use 72 as
  // the typical case — overpays by at most 1 sat/vB in vsize terms,
  // which is well below dust).
  final vsizeWithChange = _estimateVsize(
    inputCount: inputs.length,
    outputCount: 2,
  );
  final feeWithChange = vsizeWithChange * feeRateSatPerVByte;
  var changeSat = totalIn - amountSat - feeWithChange;

  // Dust threshold for P2WPKH per Bitcoin Core: 294 sat at 3 sat/vB.
  // We use a slightly conservative 546 to match P2PKH historic value
  // and to avoid forcing the user into a debate over thresholds.
  const dustSat = 546;
  final hasChange = changeSat >= dustSat;

  // If change would be dust, recompute the fee for a single-output tx
  // and let the dust become extra fee.
  int feeSat;
  if (hasChange) {
    feeSat = feeWithChange;
  } else {
    final vsizeNoChange = _estimateVsize(
      inputCount: inputs.length,
      outputCount: 1,
    );
    feeSat = totalIn - amountSat;
    final minFeeNoChange = vsizeNoChange * feeRateSatPerVByte;
    if (feeSat < minFeeNoChange) {
      throw InsufficientFundsException(
        'Need ${minFeeNoChange + amountSat} sat including fees but only '
        '$totalIn sat selected (fee would be $feeSat, need $minFeeNoChange)',
      );
    }
    changeSat = 0;
  }

  if (!hasChange && feeSat < 0) {
    throw InsufficientFundsException(
        'Selected UTXOs total $totalIn sat, need at least ${amountSat + feeWithChange}');
  }

  // Build the output list. SIGHASH_ALL signs ALL outputs, so the
  // order we choose here is committed to. Convention: destination
  // first, then change — easier to read in a block explorer.
  final outputs = <_TxOutput>[
    _TxOutput(valueSat: amountSat, scriptPubKey: _p2wpkhScriptPubKey(destPkh)),
    if (hasChange)
      _TxOutput(
          valueSat: changeSat,
          scriptPubKey: _p2wpkhScriptPubKey(changePkh)),
  ];

  // Pre-compute the BIP143 reusable hashes (hashPrevouts, hashSequence,
  // hashOutputs). These are SHA-256d over the relevant fields:
  // - hashPrevouts = hash of all input outpoints concatenated
  // - hashSequence = hash of all input nSequence values concatenated
  // - hashOutputs  = hash of all outputs concatenated
  final hashPrevouts = _sha256d(_concat([
    for (final i in inputs) _serializeOutpoint(i.txid, i.vout),
  ]));
  final hashSequence = _sha256d(_concat([
    for (final _ in inputs) _u32LE(0xfffffffd), // RBF-enabled
  ]));
  final hashOutputs = _sha256d(_concat([
    for (final o in outputs)
      _concat([_u64LE(o.valueSat), _varInt(o.scriptPubKey.length), o.scriptPubKey]),
  ]));

  // Per-input signature. For each input, build the BIP143 sighash,
  // sign deterministically, append SIGHASH_ALL byte, build the
  // witness stack: [<sig+sighashbyte>, <pubkey>].
  final witnesses = <Uint8List>[];
  for (var i = 0; i < inputs.length; i++) {
    final utxo = inputs[i];
    final key = keys[i];

    // BIP143 P2WPKH "scriptCode" is the legacy P2PKH script for the
    // input's pubkey hash:
    //   OP_DUP OP_HASH160 <pkh> OP_EQUALVERIFY OP_CHECKSIG
    final scriptCode = Uint8List.fromList([
      0x76, 0xa9, // OP_DUP OP_HASH160
      0x14, // push 20 bytes
      ...key.publicKeyHash,
      0x88, 0xac, // OP_EQUALVERIFY OP_CHECKSIG
    ]);

    final preimage = _concat([
      _u32LE(2), // version
      hashPrevouts,
      hashSequence,
      _serializeOutpoint(utxo.txid, utxo.vout),
      _varInt(scriptCode.length),
      scriptCode,
      _u64LE(utxo.valueSat),
      _u32LE(0xfffffffd), // nSequence
      hashOutputs,
      _u32LE(0), // locktime
      _u32LE(1), // SIGHASH_ALL
    ]);
    final sigHash = _sha256d(preimage);

    // bip32.sign returns 64-byte (r||s) with low-s normalization
    // already applied (BIP62). We re-encode as DER and append the
    // sighash type byte.
    final rs = key.node.sign(sigHash);
    final der = _encodeDer(rs.sublist(0, 32), rs.sublist(32, 64));
    final sig = Uint8List.fromList([...der, 0x01]); // SIGHASH_ALL

    // Witness stack for P2WPKH: [<sig>, <pubkey>]
    witnesses
        .add(_serializeWitnessStack(<Uint8List>[sig, key.publicKey]));
  }

  // Now serialize the full witness transaction:
  //   version | marker(0x00) | flag(0x01)
  //   varint(inputs) | inputs...
  //   varint(outputs) | outputs...
  //   witness vectors (one per input)
  //   locktime
  final rawTx = _concat([
    _u32LE(2), // version
    Uint8List.fromList([0x00, 0x01]), // SegWit marker+flag
    _varInt(inputs.length),
    for (final u in inputs) _serializeWitnessInput(u),
    _varInt(outputs.length),
    for (final o in outputs)
      _concat([_u64LE(o.valueSat), _varInt(o.scriptPubKey.length), o.scriptPubKey]),
    ..._intersperse(witnesses), // already serialized
    _u32LE(0), // locktime
  ]);

  // txid = sha256d of the NON-witness serialization (BIP141 — the
  // wtxid is different and is used for tx-relay only). For our send
  // confirmation UI we want the canonical txid that explorers show.
  final nonWitnessTx = _serializeNonWitness(inputs, outputs);
  final txid = _txidFromBytes(_sha256d(nonWitnessTx));

  // BIP141 vsize: (3 * base + total) / 4, rounded up.
  final base = nonWitnessTx.length;
  final total = rawTx.length;
  final vsize = ((3 * base + total) + 3) ~/ 4;

  return BuiltBitcoinTransaction(
    rawHex: _toHex(rawTx),
    txid: txid,
    virtualSize: vsize,
    feeSat: feeSat,
    changeSat: changeSat,
    recipientSat: amountSat,
  );
}

/// Pick UTXOs greedy-largest-first until we cover [amountSat] + an
/// estimated fee. Naive but produces deterministic, debuggable
/// selections — important when the user is staring at a "Spend these
/// 3 UTXOs" preview. Returns null if not enough funds.
List<Utxo>? selectUtxosGreedy({
  required List<Utxo> available,
  required int amountSat,
  required int feeRateSatPerVByte,
}) {
  // Filter out unconfirmed UTXOs by default (safer; the user can
  // override later via a "spend unconfirmed" toggle if we add one).
  final pool = available.where((u) => u.confirmed).toList()
    ..sort((a, b) => b.valueSat.compareTo(a.valueSat));

  if (pool.isEmpty) return null;

  final picked = <Utxo>[];
  var sum = 0;
  for (final u in pool) {
    picked.add(u);
    sum += u.valueSat;
    final vsize = _estimateVsize(inputCount: picked.length, outputCount: 2);
    final needed = amountSat + vsize * feeRateSatPerVByte;
    if (sum >= needed) return picked;
  }
  return null;
}

/// BIP143 sighash computation, exposed for spec-vector unit tests.
/// Production code should NOT call this directly — use the full
/// [buildAndSignP2WPKH] path so the witness stack gets assembled too.
///
/// All inputs/outputs use the BIP143 wire format. See test vectors in
/// test/bitcoin_tx_builder_test.dart for what real values look like.
Uint8List computeBip143SighashForTesting({
  required int version,
  required List<({String txid, int vout, int value, Uint8List pubKeyHash, int sequence})> inputs,
  required List<({int value, Uint8List scriptPubKey})> outputs,
  required int signingInputIndex,
  required int locktime,
  int sighashType = 1, // SIGHASH_ALL
}) {
  final hashPrevouts = _sha256d(_concat([
    for (final i in inputs) _serializeOutpoint(i.txid, i.vout),
  ]));
  final hashSequence = _sha256d(_concat([
    for (final i in inputs) _u32LE(i.sequence),
  ]));
  final hashOutputs = _sha256d(_concat([
    for (final o in outputs)
      _concat([_u64LE(o.value), _varInt(o.scriptPubKey.length), o.scriptPubKey]),
  ]));
  final signed = inputs[signingInputIndex];
  final scriptCode = Uint8List.fromList([
    0x76, 0xa9, 0x14, ...signed.pubKeyHash, 0x88, 0xac,
  ]);
  final preimage = _concat([
    _u32LE(version),
    hashPrevouts,
    hashSequence,
    _serializeOutpoint(signed.txid, signed.vout),
    _varInt(scriptCode.length),
    scriptCode,
    _u64LE(signed.value),
    _u32LE(signed.sequence),
    hashOutputs,
    _u32LE(locktime),
    _u32LE(sighashType),
  ]);
  return _sha256d(preimage);
}

// ============================================================================
// Internals — serialization, hashing, DER. Standard Bitcoin stuff;
// every function here is unit-tested against BIP143 vectors so don't
// "simplify" without re-running the spec-vector test.
// ============================================================================

class _TxOutput {
  const _TxOutput({required this.valueSat, required this.scriptPubKey});
  final int valueSat;
  final Uint8List scriptPubKey;
}

/// Estimate vsize for a P2WPKH-only transaction.
///   non-witness portion:
///     4 version + varint(in) + in*(36 outpoint + 1 scriptSigLen=0 + 4 seq)
///     + varint(out) + out*(8 value + 1 lenByte + 22 P2WPKH script)
///     + 4 locktime
///   witness portion:
///     2 (marker+flag) + in*(1 witCount + 1 sigLen + 72 sig + 1 pkLen + 33 pk)
///   vsize = ceil((3 * base + total) / 4)
int _estimateVsize({required int inputCount, required int outputCount}) {
  // base = non-witness serialization length
  final base = 4 +
      _varIntLen(inputCount) +
      inputCount * (36 + 1 + 4) +
      _varIntLen(outputCount) +
      outputCount * (8 + 1 + 22) +
      4;
  final witness = 2 + inputCount * (1 + 1 + 72 + 1 + 33);
  final total = base + witness;
  return ((3 * base + total) + 3) ~/ 4;
}

int _varIntLen(int n) {
  if (n < 0xfd) return 1;
  if (n <= 0xffff) return 3;
  if (n <= 0xffffffff) return 5;
  return 9;
}

Uint8List _u32LE(int v) {
  final b = ByteData(4)..setUint32(0, v, Endian.little);
  return b.buffer.asUint8List();
}

Uint8List _u64LE(int v) {
  final b = ByteData(8)..setUint64(0, v, Endian.little);
  return b.buffer.asUint8List();
}

Uint8List _varInt(int n) {
  if (n < 0xfd) return Uint8List.fromList([n]);
  if (n <= 0xffff) {
    final b = ByteData(3);
    b.setUint8(0, 0xfd);
    b.setUint16(1, n, Endian.little);
    return b.buffer.asUint8List();
  }
  if (n <= 0xffffffff) {
    final b = ByteData(5);
    b.setUint8(0, 0xfe);
    b.setUint32(1, n, Endian.little);
    return b.buffer.asUint8List();
  }
  final b = ByteData(9);
  b.setUint8(0, 0xff);
  b.setUint64(1, n, Endian.little);
  return b.buffer.asUint8List();
}

Uint8List _concat(Iterable<Uint8List> parts) {
  var size = 0;
  for (final p in parts) {
    size += p.length;
  }
  final out = Uint8List(size);
  var off = 0;
  for (final p in parts) {
    out.setRange(off, off + p.length, p);
    off += p.length;
  }
  return out;
}

Uint8List _sha256d(Uint8List input) {
  final a = sha256.convert(input).bytes;
  return Uint8List.fromList(sha256.convert(a).bytes);
}

/// Serialize an outpoint: 32-byte hash (BIG-ENDIAN display txid
/// REVERSED to little-endian internal form) + 4-byte index.
Uint8List _serializeOutpoint(String txidHex, int vout) {
  final hash = Uint8List.fromList(_hexToBytes(txidHex).reversed.toList());
  return _concat([hash, _u32LE(vout)]);
}

Uint8List _serializeWitnessInput(Utxo u) => _concat([
      _serializeOutpoint(u.txid, u.vout),
      _varInt(0), // empty scriptSig for SegWit inputs
      _u32LE(0xfffffffd), // nSequence (RBF)
    ]);

Uint8List _serializeWitnessStack(List<Uint8List> items) {
  final parts = <Uint8List>[_varInt(items.length)];
  for (final it in items) {
    parts.add(_varInt(it.length));
    parts.add(it);
  }
  return _concat(parts);
}

Uint8List _serializeNonWitness(List<Utxo> inputs, List<_TxOutput> outputs) =>
    _concat([
      _u32LE(2),
      _varInt(inputs.length),
      for (final u in inputs) _serializeWitnessInput(u),
      _varInt(outputs.length),
      for (final o in outputs)
        _concat([
          _u64LE(o.valueSat),
          _varInt(o.scriptPubKey.length),
          o.scriptPubKey,
        ]),
      _u32LE(0),
    ]);

/// P2WPKH scriptPubKey: OP_0 (0x00) + push_20 (0x14) + 20-byte hash.
Uint8List _p2wpkhScriptPubKey(Uint8List pkh) =>
    Uint8List.fromList([0x00, 0x14, ...pkh]);

/// DER encoding of (r, s) — strips leading zeros, prepends 0x00 if
/// the high bit would otherwise flip the sign. Standard Bitcoin DER.
Uint8List _encodeDer(Uint8List r, Uint8List s) {
  final rEnc = _derPositiveInt(r);
  final sEnc = _derPositiveInt(s);
  final body = <int>[
    0x02, rEnc.length, ...rEnc,
    0x02, sEnc.length, ...sEnc,
  ];
  return Uint8List.fromList([0x30, body.length, ...body]);
}

Uint8List _derPositiveInt(Uint8List bytes) {
  var i = 0;
  while (i < bytes.length - 1 && bytes[i] == 0) {
    i++;
  }
  final trimmed = bytes.sublist(i);
  if (trimmed[0] & 0x80 != 0) {
    return Uint8List.fromList([0x00, ...trimmed]);
  }
  return trimmed;
}

/// Convert a 32-byte hash (internal little-endian) to a big-endian
/// display txid (the form block explorers and `getrawtransaction`
/// show). Bitcoin's "txid" is what you'd see if you printed the
/// sha256d output byte-by-byte reversed.
String _txidFromBytes(Uint8List bytes) =>
    _toHex(Uint8List.fromList(bytes.reversed.toList()));

String _toHex(Uint8List b) {
  final sb = StringBuffer();
  for (final byte in b) {
    sb.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

Uint8List _hexToBytes(String hex) {
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}

/// Splat helper used inside a [_concat] spread. Just expands the
/// list so we can splice witnesses into the middle of a sequence of
/// non-witness chunks without writing a separate loop.
Iterable<Uint8List> _intersperse(List<Uint8List> ws) sync* {
  for (final w in ws) {
    yield w;
  }
}
