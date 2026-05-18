// Pure-Dart BCH transaction builder + signer.
//
// BCH split from Bitcoin in August 2017 and explicitly rejected the
// SegWit upgrade. So the wire format here is the LEGACY pre-SegWit
// Bitcoin tx:
//
//   version(4 LE)
//   varint(in_count) | inputs...
//   varint(out_count) | outputs...
//   locktime(4 LE)
//
// Each input: prevout(36) + varint(script_len) + scriptSig + sequence(4)
//   scriptSig content for P2PKH: <push sig+sighash> <push pubkey>
//
// Each output: value(8 LE) + varint(script_len) + scriptPubKey
//   P2PKH scriptPubKey: OP_DUP OP_HASH160 <push 20> <pkh> OP_EQUALVERIFY OP_CHECKSIG
//
// Sighash: BIP-143 algorithm (the same one Bitcoin uses for SegWit
// inputs) BUT with sighashType = 0x41 = SIGHASH_ALL | SIGHASH_FORKID.
// The SIGHASH_FORKID bit (0x40) was BCH's anti-replay marker added
// at the 2017 fork. Without it the network rejects the tx as a
// "legacy" signature it doesn't recognize.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'bch_keys.dart';

class BuiltBitcoinCashTransaction {
  const BuiltBitcoinCashTransaction({
    required this.rawHex,
    required this.txid,
    required this.byteSize,
    required this.feeSat,
    required this.changeSat,
    required this.recipientSat,
  });
  final String rawHex;
  final String txid;
  /// BCH doesn't use vbytes (no SegWit discount) — just total bytes.
  /// Fee math uses this directly.
  final int byteSize;
  final int feeSat;
  final int changeSat;
  final int recipientSat;
}

class InsufficientBchFundsException implements Exception {
  const InsufficientBchFundsException(this.message);
  final String message;
  @override
  String toString() => 'InsufficientFunds: $message';
}

class InvalidBchAddressException implements Exception {
  const InvalidBchAddressException(this.message);
  final String message;
  @override
  String toString() => 'InvalidBchAddress: $message';
}

/// A spendable UTXO. Same shape as Bitcoin's but kept separate to
/// keep the BCH module from cross-importing the BTC mempool client.
class BchUtxo {
  const BchUtxo({
    required this.txid,
    required this.vout,
    required this.valueSat,
    required this.address,
  });
  final String txid;
  final int vout;
  final int valueSat;
  /// Which one of our addresses owns this UTXO — used by the signer
  /// to look up the matching spending key.
  final String address;
}

/// Build, sign and serialize a BCH P2PKH transaction.
BuiltBitcoinCashTransaction buildAndSignP2PKH({
  required List<BchUtxo> inputs,
  required Map<String, BitcoinCashSpendingKey> signers,
  required Uint8List destPkh,
  required int amountSat,
  required Uint8List changePkh,
  required int feeRateSatPerByte,
}) {
  if (inputs.isEmpty) {
    throw const InsufficientBchFundsException('No UTXOs provided');
  }
  if (amountSat <= 0) {
    throw const InvalidBchAddressException('Amount must be positive');
  }
  if (feeRateSatPerByte <= 0) {
    throw const InvalidBchAddressException('Fee rate must be positive');
  }

  final keys = <BitcoinCashSpendingKey>[];
  for (final u in inputs) {
    final k = signers[u.address];
    if (k == null) {
      throw InvalidBchAddressException(
          'Missing key for UTXO at ${u.address}');
    }
    keys.add(k);
  }

  final totalIn = inputs.fold<int>(0, (s, u) => s + u.valueSat);

  // Fee estimation: a legacy P2PKH tx has the size formula:
  //   10 base bytes (version + locktime + 2 varint placeholders for
  //                   in/out counts, since typical counts < 253)
  //   + N inputs * ~148 bytes each (signed)
  //   + M outputs * 34 bytes each
  // For 1-3 inputs and 1-2 outputs the varint counts are 1 byte each;
  // the formula simplifies to estimateByteSize() below.
  final sizeWithChange = _estimateByteSize(
    inputCount: inputs.length,
    outputCount: 2,
  );
  final feeWithChange = sizeWithChange * feeRateSatPerByte;
  var changeSat = totalIn - amountSat - feeWithChange;

  const dustSat = 546; // same as BTC
  final hasChange = changeSat >= dustSat;

  // The final byteSize is recomputed from the actual serialized
  // tx; the estimate just drives the fee math + change/no-change
  // decision here.
  int feeSat;
  if (hasChange) {
    feeSat = feeWithChange;
  } else {
    final sizeNoChange = _estimateByteSize(
      inputCount: inputs.length,
      outputCount: 1,
    );
    final minFee = sizeNoChange * feeRateSatPerByte;
    feeSat = totalIn - amountSat;
    if (feeSat < minFee) {
      throw InsufficientBchFundsException(
        'Need ${minFee + amountSat} sat including fees but only $totalIn sat selected',
      );
    }
    changeSat = 0;
  }

  // Outputs: recipient first, change second (if any). Order is
  // committed to by the sighash so don't reshuffle past this point.
  final outputs = <_TxOutput>[
    _TxOutput(valueSat: amountSat, scriptPubKey: _p2pkhScriptPubKey(destPkh)),
    if (hasChange)
      _TxOutput(
        valueSat: changeSat,
        scriptPubKey: _p2pkhScriptPubKey(changePkh),
      ),
  ];

  // BIP143 reusable hashes — same as Bitcoin's SegWit, since the
  // sighash algorithm is structurally identical; only the trailing
  // sighashType byte's high bit is different.
  final hashPrevouts = _sha256d(_concat([
    for (final i in inputs) _serializeOutpoint(i.txid, i.vout),
  ]));
  final hashSequence = _sha256d(_concat([
    for (final _ in inputs) _u32LE(0xfffffffe), // not RBF (BCH doesn't honor RBF)
  ]));
  final hashOutputs = _sha256d(_concat([
    for (final o in outputs)
      _concat([_u64LE(o.valueSat), _varInt(o.scriptPubKey.length), o.scriptPubKey]),
  ]));

  // Sign each input. SCRIPT contents:
  //   <push sig+sighashType> <push pubkey>
  final scriptSigs = <Uint8List>[];
  for (var i = 0; i < inputs.length; i++) {
    final utxo = inputs[i];
    final key = keys[i];

    // scriptCode for BIP143 sighash = standard P2PKH script of the
    // input's pkh: OP_DUP OP_HASH160 <pkh> OP_EQUALVERIFY OP_CHECKSIG
    final pkh = key.publicKeyHash;
    final scriptCode = Uint8List.fromList([
      0x76, 0xa9, 0x14, ...pkh, 0x88, 0xac,
    ]);

    // sighashType: SIGHASH_ALL (0x01) | SIGHASH_FORKID (0x40) = 0x41.
    // The forkId field (3 bytes set to 0 for BCH mainnet) is OR-ed
    // into the sighashType's high bits per the BCH spec. Mainnet's
    // forkId = 0, so the final sighashType uint32 is 0x00000041.
    const sighashType = 0x41;

    final preimage = _concat([
      _u32LE(2), // version
      hashPrevouts,
      hashSequence,
      _serializeOutpoint(utxo.txid, utxo.vout),
      _varInt(scriptCode.length),
      scriptCode,
      _u64LE(utxo.valueSat),
      _u32LE(0xfffffffe),
      hashOutputs,
      _u32LE(0), // locktime
      _u32LE(sighashType),
    ]);
    final sigHash = _sha256d(preimage);

    // bip32's sign returns 64 bytes (r||s) with low-s normalization.
    final rs = key.node.sign(sigHash);
    final der = _encodeDer(rs.sublist(0, 32), rs.sublist(32, 64));
    final sigWithType =
        Uint8List.fromList([...der, sighashType]);

    // scriptSig = <push sigWithType> <push pubkey>
    final scriptSig = _concat([
      _pushData(sigWithType),
      _pushData(key.publicKey),
    ]);
    scriptSigs.add(scriptSig);
  }

  // Now assemble the full legacy transaction.
  final tx = BytesBuilder();
  tx.add(_u32LE(2)); // version
  tx.add(_varInt(inputs.length));
  for (var i = 0; i < inputs.length; i++) {
    final u = inputs[i];
    final s = scriptSigs[i];
    tx.add(_serializeOutpoint(u.txid, u.vout));
    tx.add(_varInt(s.length));
    tx.add(s);
    tx.add(_u32LE(0xfffffffe));
  }
  tx.add(_varInt(outputs.length));
  for (final o in outputs) {
    tx.add(_u64LE(o.valueSat));
    tx.add(_varInt(o.scriptPubKey.length));
    tx.add(o.scriptPubKey);
  }
  tx.add(_u32LE(0)); // locktime
  final rawBytes = tx.toBytes();

  // txid = sha256d(serialized tx) reversed to display form.
  final hashBytes = _sha256d(rawBytes);
  final txid = _toHex(Uint8List.fromList(hashBytes.reversed.toList()));

  return BuiltBitcoinCashTransaction(
    rawHex: _toHex(rawBytes),
    txid: txid,
    byteSize: rawBytes.length,
    feeSat: feeSat,
    changeSat: changeSat,
    recipientSat: amountSat,
  );
}

/// Greedy largest-first UTXO selection. Identical to the BTC version
/// — duplicating because the BCH module shouldn't reach into the BTC
/// coin's data classes. (A future cleanup could pull the algorithm
/// out into a common utility taking a generic "utxo with .valueSat".)
List<BchUtxo>? selectBchUtxosGreedy({
  required List<BchUtxo> available,
  required int amountSat,
  required int feeRateSatPerByte,
}) {
  final pool = available.toList()
    ..sort((a, b) => b.valueSat.compareTo(a.valueSat));
  if (pool.isEmpty) return null;

  final picked = <BchUtxo>[];
  var sum = 0;
  for (final u in pool) {
    picked.add(u);
    sum += u.valueSat;
    final size = _estimateByteSize(
        inputCount: picked.length, outputCount: 2);
    final needed = amountSat + size * feeRateSatPerByte;
    if (sum >= needed) return picked;
  }
  return null;
}

// ============================================================================
// Helpers: byte serialization, sha256d, DER, scriptSig push encoding.
// ============================================================================

class _TxOutput {
  const _TxOutput({required this.valueSat, required this.scriptPubKey});
  final int valueSat;
  final Uint8List scriptPubKey;
}

int _estimateByteSize({required int inputCount, required int outputCount}) {
  // version 4 + locktime 4 + varint(in) ≤ 3 + varint(out) ≤ 3
  //   + N inputs * (36 outpoint + 1 scriptSigLen + ~107 scriptSig +
  //                 4 sequence) = ~148 per input
  //   + M outputs * (8 value + 1 scriptLen + 25 P2PKH) = 34 per output
  return 10 +
      _varIntLen(inputCount) +
      inputCount * 148 +
      _varIntLen(outputCount) +
      outputCount * 34;
}

int _varIntLen(int n) {
  if (n < 0xfd) return 1;
  if (n <= 0xffff) return 3;
  if (n <= 0xffffffff) return 5;
  return 9;
}

Uint8List _u32LE(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();
Uint8List _u64LE(int v) =>
    (ByteData(8)..setUint64(0, v, Endian.little)).buffer.asUint8List();

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

Uint8List _serializeOutpoint(String txidHex, int vout) {
  // display txid hex → internal (reversed) bytes, then vout LE.
  final raw = _hexToBytes(txidHex);
  final reversed = Uint8List.fromList(raw.reversed.toList());
  return _concat([reversed, _u32LE(vout)]);
}

Uint8List _p2pkhScriptPubKey(Uint8List pkh) =>
    Uint8List.fromList([0x76, 0xa9, 0x14, ...pkh, 0x88, 0xac]);

/// Bitcoin "push N bytes" prefix. Values < 76 push directly with
/// the length as the opcode; 76-255 use OP_PUSHDATA1.
Uint8List _pushData(Uint8List data) {
  if (data.length < 0x4c) {
    return Uint8List.fromList([data.length, ...data]);
  }
  if (data.length <= 0xff) {
    return Uint8List.fromList([0x4c, data.length, ...data]);
  }
  if (data.length <= 0xffff) {
    return Uint8List.fromList(
        [0x4d, data.length & 0xff, (data.length >> 8) & 0xff, ...data]);
  }
  throw ArgumentError('push too large: ${data.length}');
}

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
