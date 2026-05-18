// Native Monero wallet via monero_c FFI bindings.
//
// The high-level wrappers in package:monero/monero.dart are marked
// deprecated by the upstream maintainer, who's planning to migrate
// everything to the lower-level `lib.MONERO_*` calls. Until that lands
// the high-level wrappers still work and are dramatically cleaner;
// suppress the lint so analyzer noise doesn't drown real signals.

// ignore_for_file: deprecated_member_use
//
// Flow:
//   1. deriveMoneroKeys()           — pure Dart, gives us the spend/
//                                      view keys + primary address.
//   2. WalletManager_createWalletFromKeys() / openWallet()
//                                   — hands keys to the native wallet,
//                                      which writes a wallet file to
//                                      `walletDir` (or reopens it).
//   3. Wallet_init(host:port, ssl)  — try the user's daemon first,
//                                      then kMoneroFallbackNodes. First
//                                      one accepted by Wallet_init wins.
//   4. Wallet_startRefresh()         — background sync. Balance ticks
//                                      up as blocks scan; daemonTipHeight
//                                      goes >0 once the daemon responds.
//   5. balanceXmr / syncProgressPct / isSynced — UI polls these.
//
// Lifecycle is single-instance per app session (see MoneroSession).
// The native side is happy with multiple instances, but managing
// multiple sync threads is gratuitous complexity for our single-
// wallet use case.

import 'dart:io';

import 'package:monero/monero.dart' as monero;
import 'package:path_provider/path_provider.dart';

import 'monero_keys.dart';

class MoneroWallet {
  MoneroWallet._(this._ptr, this.address);

  /// Holds the C-side wallet pointer. Bindings take it as the first
  /// positional argument of every Wallet_* call.
  final dynamic _ptr;
  final String address;

  /// Boots a wallet from a BIP39 phrase and points it at the daemon.
  /// The first call after install will write a wallet file to
  /// `<docs>/peek_xmr/` and begin scanning from `restoreHeight`.
  /// Subsequent calls reopen the same on-disk wallet for speed.
  static Future<MoneroWallet> open({
    required String mnemonic,
    required int restoreHeight,
    required String daemonUri,
    required String walletPassword,
    String passphrase = '',
    void Function(String stage)? onStage,
  }) async {
    void stage(String s) {
      // ignore: avoid_print
      print('[xmr] $s');
      onStage?.call(s);
    }
    stage('deriving keys');
    final keys = deriveMoneroKeys(mnemonic, passphrase: passphrase);

    stage('locating wallet dir');
    final docs = await getApplicationDocumentsDirectory();
    // peek_xmr_v3 — the v2 dir was created with a hardcoded
    // restoreHeight that overshot the real chain tip by ~110k blocks
    // (May-2026 tip is ~3,676,500, not the 3,790,000+ I'd assumed).
    // That left existing wallets "synced" but skipping all real blocks.
    // Fresh dir + a sane fallback constant + daemon-tip clamp below.
    final walletDir = Directory('${docs.path}/peek_xmr_v3');
    if (!walletDir.existsSync()) walletDir.createSync(recursive: true);
    final walletPath = '${walletDir.path}/wallet';

    stage('getting wallet manager');
    final wm = monero.WalletManagerFactory_getWalletManager();

    dynamic w;
    var fileExists = monero.WalletManager_walletExists(wm, walletPath);
    var justCreated = false;

    if (fileExists) {
      stage('opening existing wallet file');
      w = monero.WalletManager_openWallet(
        wm,
        path: walletPath,
        password: walletPassword,
      );
      // Two ways the existing on-disk wallet can be unusable:
      //
      // 1. Wrong password — pre-PR-#5 builds used a hardcoded constant
      //    for the wallet file password; new builds derive it from the
      //    master password, so the old file won't open.
      // 2. Different seed — shouldn't happen in normal flow, but if
      //    someone restored a different mnemonic the old wallet file
      //    on disk now belongs to a different identity.
      //
      // Both surface as: opened wallet's address doesn't match the
      // seed-derived address (or doesn't open at all). Wallet_status
      // alone is unreliable across monero_c builds, so check the
      // address explicitly. The wallet file is just a sync cache —
      // wiping + recreating is safe because the seed is the source
      // of truth.
      String openedAddress = '';
      try {
        openedAddress = monero.Wallet_address(w);
      } catch (_) {/* leave empty */}
      final status = monero.Wallet_status(w);
      final reopenedOk =
          status == 0 && openedAddress == keys.primaryAddress;
      if (!reopenedOk) {
        final err = monero.Wallet_errorString(w);
        stage('open mismatch '
            '(status=$status, addr=${openedAddress.isEmpty ? "(empty)" : "${openedAddress.substring(0, 12)}…"}'
            '${err.isEmpty ? "" : ", $err"}) — recreating from keys');
        try {
          monero.WalletManager_closeWallet(wm, w, false);
        } catch (_) {/* best effort */}
        try {
          walletDir.deleteSync(recursive: true);
        } catch (_) {/* best effort */}
        walletDir.createSync(recursive: true);
        fileExists = false;
      }
    }

    if (!fileExists) {
      stage('creating new wallet from keys');
      justCreated = true;
      w = monero.WalletManager_createWalletFromKeys(
        wm,
        path: walletPath,
        password: walletPassword,
        nettype: 0, // 0 = mainnet
        restoreHeight: restoreHeight,
        addressString: keys.primaryAddress,
        viewKeyString: keys.privateViewHex,
        spendKeyString: keys.privateSpendHex,
        kdf_rounds: 1,
      );
    }

    // Try the user's daemon first, then known-good public nodes. We
    // only gate on Wallet_init's return value — earlier attempts to
    // verify the daemon's reported tip at boot ran into monero_c's
    // approximate-tip fallback (it returns a compile-time constant
    // until a real RPC succeeds, which on slow / roaming networks
    // can take longer than any reasonable boot timeout). Heights are
    // surfaced in the UI so a stale daemon is visible to the user —
    // we don't need to refuse to connect over it.
    final candidates = <String>{daemonUri, ...kMoneroFallbackNodes}.toList();
    String? activeHostPort;
    bool activeSsl = false;
    String lastError = '';
    for (final url in candidates) {
      final ep = MoneroDaemonEndpoint.parse(url);
      stage('init ${ep.hostPort} (ssl=${ep.useSsl})');
      final ok = monero.Wallet_init(
        w,
        daemonAddress: ep.hostPort,
        useSsl: ep.useSsl,
      );
      if (ok) {
        activeHostPort = ep.hostPort;
        activeSsl = ep.useSsl;
        break;
      }
      lastError = monero.Wallet_errorString(w);
      stage('init failed on ${ep.hostPort}: ${lastError.isEmpty ? "(no detail)" : lastError}');
    }

    if (activeHostPort == null) {
      throw Exception(
          'Wallet_init rejected every candidate. Last error: ${lastError.isEmpty ? "(none)" : lastError}');
    }

    stage('attached $activeHostPort (ssl=$activeSsl)');

    // For freshly-created wallets only: ask the daemon what the real
    // chain tip is and adjust where scanning starts. The hint passed
    // in by the caller is necessarily a baked-in compile-time guess —
    // if it's higher than today's tip the wallet skips every real
    // block (which is exactly what happened in peek_xmr_v2); if it's
    // much lower the user wastes time scanning months of empty
    // history. Clamp to (real tip - 5000) so we cover ~1 week of
    // recent receives without burning hours of decryption.
    //
    // Wallet_daemonBlockChainHeight populates ~5–15s after Wallet_init
    // succeeds (it takes one real /get_height RPC to fill in). Poll
    // up to 15s; if we never get a value, fall back to the caller's
    // hint — slow but bounded.
    if (justCreated) {
      stage('querying daemon tip…');
      int observedTip = 0;
      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        observedTip = monero.Wallet_daemonBlockChainHeight(w);
        if (observedTip > 1000000) break;
      }
      if (observedTip > 1000000) {
        final adjusted = observedTip - 5000;
        stage('clamp restoreHeight $restoreHeight -> $adjusted (tip=$observedTip)');
        try {
          monero.Wallet_setRefreshFromBlockHeight(
            w,
            refresh_from_block_height: adjusted,
          );
        } catch (e) {
          stage('setRefreshFromBlockHeight failed: $e — using $restoreHeight');
        }
      } else {
        stage('daemon tip not reported in 15s — using hint $restoreHeight');
      }
    }

    stage('starting refresh');
    monero.Wallet_startRefresh(w);
    stage('ready');

    return MoneroWallet._(w, keys.primaryAddress);
  }

  /// Daemon-reported chain tip. Stays 0 until refresh successfully
  /// fetches `/get_height` at least once — so a >0 value is the most
  /// reliable signal that we're actually talking to a node.
  int get daemonTipHeight => monero.Wallet_daemonBlockChainHeight(_ptr);

  /// Local chain height — how far the wallet has scanned. Sits
  /// somewhere between restoreHeight and daemonTipHeight while sync
  /// is running.
  int get currentHeight => monero.Wallet_blockChainHeight(_ptr);

  /// True once the daemon has answered at least one RPC. More reliable
  /// than Wallet_connected, which in this monero_c build seems to
  /// remain 0 even when refresh is making progress.
  bool get isDaemonConnected => daemonTipHeight > 0;

  /// Last daemon-side error string from the native wallet, or null when
  /// there's nothing to report.
  String? get daemonError {
    final s = monero.Wallet_errorString(_ptr);
    return s.isEmpty ? null : s;
  }

  /// Piconero balance (1 XMR = 10^12 piconero). Reads whatever the
  /// sync worker has accumulated so far; returns 0 until at least
  /// some blocks have been scanned.
  int get balancePiconero =>
      monero.Wallet_balance(_ptr, accountIndex: 0);

  double get balanceXmr => balancePiconero / 1e12;

  /// True once the local chain has caught up with the daemon's tip.
  /// Tolerates a few blocks of lag — monero_c's Wallet_synchronized
  /// flips back to false every time a new daemon block lands, so a
  /// strict equality check would flicker the UI back to "Syncing X%"
  /// every ~2 min in steady state. 5 blocks ≈ 10 minutes of leeway.
  bool get isSynced {
    if (monero.Wallet_synchronized(_ptr)) return true;
    final tip = daemonTipHeight;
    if (tip <= 0) return false;
    return (tip - currentHeight) <= 5;
  }

  /// 0–100 percentage based on `current / tip`. Returns 0 while we're
  /// still waiting for the daemon to respond with the tip. Floors —
  /// not rounds — so a ratio of 99.88% reports as 99 instead of 100;
  /// otherwise the label would read "Syncing 100%" for several blocks
  /// before isSynced actually flips. The cur >= tip early-return
  /// covers the truly-caught-up case.
  int get syncProgressPct {
    final tip = monero.Wallet_daemonBlockChainHeight(_ptr);
    if (tip <= 0) return 0;
    final cur = monero.Wallet_blockChainHeight(_ptr);
    if (cur >= tip) return 100;
    return ((cur / tip) * 100).clamp(0.0, 100.0).floor();
  }

  /// Number of subaddresses currently generated under account 0
  /// (includes the primary at index 0). Call [addSubaddress] to
  /// extend this; the count survives across launches because monero_c
  /// persists subaddresses in the wallet file.
  int get subaddressCount =>
      monero.Wallet_numSubaddresses(_ptr, accountIndex: 0);

  /// Address string at the given subaddress index of account 0.
  /// Index 0 is the primary address (same as [address]); higher
  /// indices are Cake-compatible subaddresses (network byte 0x2A,
  /// '8' prefix). Same BIP39 seed in another wallet produces the
  /// same string at the same index.
  String subaddress(int index) =>
      monero.Wallet_address(_ptr, accountIndex: 0, addressIndex: index);

  /// User-set label for a subaddress, or empty string if none. The
  /// monero_c default label is "Primary account" / "" — we treat
  /// empty as unlabeled.
  String subaddressLabel(int index) {
    final s = monero.Wallet_getSubaddressLabel(
      _ptr,
      accountIndex: 0,
      addressIndex: index,
    );
    return s;
  }

  /// Generate a fresh subaddress under account 0 with optional label.
  /// Returns the new address string (same as `subaddress(subaddressCount - 1)`
  /// after the call). Persists immediately to the wallet file.
  String addSubaddress({String label = ''}) {
    monero.Wallet_addSubaddress(_ptr, accountIndex: 0, label: label);
    final idx = subaddressCount - 1;
    return subaddress(idx);
  }

  /// Rename an existing subaddress. Use empty string to clear.
  void setSubaddressLabel({required int index, required String label}) {
    monero.Wallet_setSubaddressLabel(
      _ptr,
      accountIndex: 0,
      addressIndex: index,
      label: label,
    );
  }

  /// Build a transaction without broadcasting it. Returns a PendingTx
  /// the UI can show fees / totals on; call [commit] to actually
  /// relay it. Throws if the native side reports an error (insufficient
  /// funds, malformed address, daemon unreachable, etc.).
  ///
  /// [amountPiconero] — amount in piconero (1 XMR = 1e12 piconero).
  /// [priority] — 1 (low / slow / cheap) to 4 (priority / fast).
  PendingMoneroTx buildTransaction({
    required String destAddress,
    required int amountPiconero,
    int priority = 2,
    String paymentId = '',
  }) {
    final pt = monero.Wallet_createTransaction(
      _ptr,
      dst_addr: destAddress,
      payment_id: paymentId,
      amount: amountPiconero,
      mixin_count: 0, // ignored on v17+ (network enforces ring size)
      pendingTransactionPriority: priority,
      subaddr_account: 0,
    );
    final status = monero.PendingTransaction_status(pt);
    if (status != 0) {
      final err = monero.PendingTransaction_errorString(pt);
      throw Exception(err.isEmpty
          ? 'Could not build transaction (status=$status)'
          : err);
    }
    return PendingMoneroTx._(pt);
  }

  /// Read the wallet's transaction history. Refreshes the underlying
  /// monero_c TransactionHistory pointer first so newly-arrived txs
  /// land in the list. Cheap call — just iterates the cached list,
  /// no RPC.
  List<MoneroTx> transactions() {
    final history = monero.Wallet_history(_ptr);
    monero.TransactionHistory_refresh(history);
    final count = monero.TransactionHistory_count(history);
    final out = <MoneroTx>[];
    for (var i = 0; i < count; i++) {
      final t = monero.TransactionHistory_transaction(history, index: i);
      out.add(MoneroTx._(
        hash: monero.TransactionInfo_hash(t),
        amountPiconero: monero.TransactionInfo_amount(t),
        feePiconero: monero.TransactionInfo_fee(t),
        // TransactionInfo_Direction is an enum { In, Out } in the
        // bindings — match against .In rather than its ordinal so
        // an upstream reorder can't silently flip the sign.
        isIncoming: monero.TransactionInfo_direction(t) ==
            monero.TransactionInfo_Direction.In,
        timestampSec: monero.TransactionInfo_timestamp(t),
        blockHeight: monero.TransactionInfo_blockHeight(t),
        isPending: monero.TransactionInfo_isPending(t),
        isFailed: monero.TransactionInfo_isFailed(t),
        confirmations: monero.TransactionInfo_confirmations(t),
        paymentId: monero.TransactionInfo_paymentId(t),
      ));
    }
    // Newest first.
    out.sort((a, b) => b.timestampSec.compareTo(a.timestampSec));
    return out;
  }

  /// Close the wallet, flushing the wallet file to disk. Call from
  /// the lock handler so the on-disk file is fresh next time.
  void close() {
    try {
      final wm = monero.WalletManagerFactory_getWalletManager();
      monero.WalletManager_closeWallet(wm, _ptr, true);
    } catch (_) {/* best effort */}
  }
}

/// A built-but-unbroadcast Monero transaction. Holds the C-side
/// PendingTransaction pointer so the UI can show the fee + total
/// before the user commits.
class PendingMoneroTx {
  PendingMoneroTx._(this._ptr);
  final dynamic _ptr;

  /// Total amount being sent in piconero (excludes fee).
  int get amountPiconero => monero.PendingTransaction_amount(_ptr);

  /// Network fee in piconero.
  int get feePiconero => monero.PendingTransaction_fee(_ptr);

  double get amountXmr => amountPiconero / 1e12;
  double get feeXmr => feePiconero / 1e12;

  /// Number of sub-transactions monero_c will broadcast for this
  /// send (usually 1; multi-output / large sends can split).
  int get txCount => monero.PendingTransaction_txCount(_ptr);

  /// Broadcast the transaction to the daemon. Returns the txid (or
  /// joined txids if the send was split). Throws on relay failure.
  String commit() {
    final ok = monero.PendingTransaction_commit(
      _ptr,
      filename: '',
      overwrite: false,
    );
    if (!ok) {
      final err = monero.PendingTransaction_errorString(_ptr);
      throw Exception(
          err.isEmpty ? 'Daemon rejected the transaction' : err);
    }
    return monero.PendingTransaction_txid(_ptr, ', ');
  }
}

/// A confirmed (or in-flight) Monero transaction as seen by the wallet.
/// Immutable snapshot — call MoneroWallet.transactions() again to
/// pick up new arrivals.
class MoneroTx {
  const MoneroTx._({
    required this.hash,
    required this.amountPiconero,
    required this.feePiconero,
    required this.isIncoming,
    required this.timestampSec,
    required this.blockHeight,
    required this.isPending,
    required this.isFailed,
    required this.confirmations,
    required this.paymentId,
  });
  final String hash;
  final int amountPiconero;
  final int feePiconero;
  final bool isIncoming;
  final int timestampSec;
  final int blockHeight;
  final bool isPending;
  final bool isFailed;
  final int confirmations;
  final String paymentId;

  double get amountXmr => amountPiconero / 1e12;
  double get feeXmr => feePiconero / 1e12;
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
}

/// Process-wide singleton holding the current wallet (if any).
/// `MoneroSession.I.start(mnemonic)` is called once after unlock; the
/// UI then polls `MoneroSession.I.wallet?.balanceXmr` etc.
class MoneroSession {
  MoneroSession._();
  static final I = MoneroSession._();

  MoneroWallet? _wallet;
  String? _lastError;
  String? _stage;
  Future<MoneroWallet?>? _inFlight;

  MoneroWallet? get wallet => _wallet;
  String? get lastError => _lastError;
  bool get isStarting => _inFlight != null;
  /// Last stage label emitted by MoneroWallet.open — surfaced in the
  /// UI so the user can see what part of the boot is taking time.
  String? get stage => _stage;

  /// Idempotent — concurrent callers share the same in-flight Future
  /// instead of one of them getting a spurious null. Calling after the
  /// wallet is already open returns the existing instance.
  Future<MoneroWallet?> start({
    required String mnemonic,
    required int restoreHeight,
    required String daemonUri,
    required String walletPassword,
    String passphrase = '',
  }) {
    if (_wallet != null) return Future.value(_wallet);
    return _inFlight ??= _doStart(
      mnemonic: mnemonic,
      restoreHeight: restoreHeight,
      daemonUri: daemonUri,
      walletPassword: walletPassword,
      passphrase: passphrase,
    ).whenComplete(() => _inFlight = null);
  }

  Future<MoneroWallet?> _doStart({
    required String mnemonic,
    required int restoreHeight,
    required String daemonUri,
    required String walletPassword,
    required String passphrase,
  }) async {
    _lastError = null;
    try {
      _wallet = await MoneroWallet.open(
        mnemonic: mnemonic,
        passphrase: passphrase,
        restoreHeight: restoreHeight,
        daemonUri: daemonUri,
        walletPassword: walletPassword,
        onStage: (s) => _stage = s,
      );
      return _wallet;
    } catch (e, st) {
      _lastError = e.toString();
      // ignore: avoid_print
      print('MoneroSession.start failed: $e\n$st');
      return null;
    }
  }

  void stop() {
    _wallet?.close();
    _wallet = null;
    _stage = null;
  }
}

/// Default daemon for the Monero wallet. Cake's well-maintained public
/// node — used by Cake Wallet itself, kept current with the chain.
/// xmr-rpc.iamhch.com (Peek's old proxy in front of an older Cake
/// node) was previously the default but its underlying node went
/// stale; left in kMoneroFallbackNodes for now in case it comes back.
const String kDefaultMoneroDaemon = 'https://xmr-node.cakewallet.com:18081';

/// Public Monero RPC nodes we fall back to when the user's preferred
/// daemon is unreachable. Order matters — first one Wallet_init
/// accepts wins.
const List<String> kMoneroFallbackNodes = [
  'https://nodes.hashvault.pro:18081',
  'https://node.sethforprivacy.com:443',
  'https://xmr-rpc.iamhch.com',
];

/// Splits a user-friendly daemon URL into the host:port + useSsl pair
/// that monero_c's Wallet_init expects. Accepts:
///   https://host             -> host:443  ssl
///   https://host:port        -> host:port ssl
///   http://host[:port]       -> host:port no ssl  (default 18081)
///   host[:port]              -> host:port no ssl  (default 18081)
///
/// Exposed publicly so the Settings UI can preview what a user-entered
/// URL will be parsed to, and validate before saving.
class MoneroDaemonEndpoint {
  const MoneroDaemonEndpoint(this.hostPort, this.useSsl);
  final String hostPort;
  final bool useSsl;

  static MoneroDaemonEndpoint parse(String input) {
    final raw = input.trim();
    final hasScheme = raw.contains('://');
    final uri = Uri.parse(hasScheme ? raw : 'tcp://$raw');
    final ssl = uri.scheme == 'https';
    final host = uri.host;
    final port = uri.hasPort ? uri.port : (ssl ? 443 : 18081);
    return MoneroDaemonEndpoint('$host:$port', ssl);
  }

  /// True when [input] parses to a non-empty host. Used as a cheap
  /// pre-save sanity check in the Settings form.
  static bool isValid(String input) {
    try {
      final ep = parse(input);
      return ep.hostPort.split(':').first.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// Whether the host platform can load the monero_c .so / .dylib.
/// Used by the UI to decide whether to attempt MoneroSession.start.
bool moneroNativeAvailable() {
  if (Platform.isIOS) return false; // pending iOS framework wiring
  return Platform.isAndroid || Platform.isLinux || Platform.isMacOS;
}
