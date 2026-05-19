import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight rolling log file. Writes to
/// `<docs>/peek_logs/peek-YYYY-MM-DD.log`; rotates by date, keeps the
/// last 7 days. Print-style API for ergonomics.
///
/// **Redaction policy** — strings that look like:
///   - Monero addresses (95 / 106 chars, base58 alphabet)
///   - Hex keys (64 hex chars)
///   - BIP39 word sequences (≥12 lowercase words, all in a small
///     letter-only alphabet)
/// are replaced with `<redacted-XMR-address>` / `<redacted-key-hex>`
/// / `<redacted-mnemonic>` before being written to disk. The intent
/// is that the log file can be shared in a bug report without
/// leaking funds.
///
/// Opt-out: file logging can be disabled at any time via
/// `PeekLogger.I.setEnabled(false)`. When disabled, log() is a no-op.
class PeekLogger {
  PeekLogger._();
  static final PeekLogger I = PeekLogger._();

  IOSink? _sink;
  File? _currentFile;
  bool _enabled = true;
  bool _ready = false;
  Future<void>? _initFuture;

  Future<void> _ensureReady() async {
    if (_ready) return;
    _initFuture ??= _open();
    return _initFuture;
  }

  Future<void> _open() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/peek_logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      await _rotate(dir);
      final now = DateTime.now();
      final ymd = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      _currentFile = File('${dir.path}/peek-$ymd.log');
      _sink = _currentFile!.openWrite(mode: FileMode.append);
      _ready = true;
    } catch (_) {
      // Failure to open the log file is non-fatal — log() degrades to
      // a no-op so we never crash a wallet operation because of a
      // logging hiccup.
      _enabled = false;
    }
  }

  Future<void> _rotate(Directory dir) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    for (final entry in dir.listSync()) {
      if (entry is! File) continue;
      try {
        final stat = entry.statSync();
        if (stat.modified.isBefore(cutoff)) {
          entry.deleteSync();
        }
      } catch (_) {/* leave it */}
    }
  }

  bool get enabled => _enabled;

  Future<void> setEnabled(bool on) async {
    _enabled = on;
    if (!on) {
      await _sink?.flush();
      await _sink?.close();
      _sink = null;
      _ready = false;
      _initFuture = null;
    }
  }

  /// Append one line to the log file. Safe to call before _open
  /// completes — buffers internally until the sink is ready. The
  /// debug-build `debugPrint` mirror keeps `flutter logs` working.
  void log(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
    if (!_enabled) return;
    final redacted = _redact(message);
    final line = '${DateTime.now().toIso8601String()} [$tag] $redacted\n';
    unawaited(_ensureReady().then((_) {
      if (!_enabled) return;
      try {
        _sink?.write(line);
      } catch (_) {/* dropped log line; not worth crashing */}
    }));
  }

  /// Read the current log file's contents. Used by "Export logs" in
  /// Settings — returns "" if logs are disabled or never opened.
  Future<String> readCurrent() async {
    await _ensureReady();
    final f = _currentFile;
    if (f == null || !f.existsSync()) return '';
    try {
      return await f.readAsString();
    } catch (_) {
      return '';
    }
  }

  /// Path to the current log file, for the share-sheet "Save as…" /
  /// "Send via email" flow. Null when logs are disabled.
  String? get currentFilePath => _currentFile?.path;

  // ── Redaction ─────────────────────────────────────────────────

  static final _xmrAddrRe = RegExp(r'\b[1-9A-HJ-NP-Za-km-z]{95,106}\b');
  static final _hexRe = RegExp(r'\b[0-9a-f]{64}\b');
  // English BIP39 (lowercase). Word length is 3-8 chars; phrases are
  // 12/15/18/21/24 words. The original regex assumed lowercase-only;
  // tolerate mixed-case so a screenshot transcription doesn't slip
  // through. Polyseed words can be longer (Czech / Esperanto reach
  // 13 chars), so the cap is widened to 13.
  static final _bip39Re = RegExp(
      r'\b([A-Za-z]{3,13}\s+){11,23}[A-Za-z]{3,13}\b');
  // Monero 25-word seed (English). Word length 4-9 chars typically;
  // exactly 25 words. Captured separately so we redact even if the
  // wordlist falls outside the BIP39 cap above.
  static final _xmr25Re =
      RegExp(r'\b([A-Za-z]{4,12}\s+){24}[A-Za-z]{4,12}\b');

  static String _redact(String s) {
    return s
        .replaceAll(_xmrAddrRe, '<redacted-XMR-address>')
        .replaceAll(_hexRe, '<redacted-key-hex>')
        .replaceAll(_xmr25Re, '<redacted-mnemonic>')
        .replaceAll(_bip39Re, '<redacted-mnemonic>');
  }
}
