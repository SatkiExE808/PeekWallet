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
    // Bumped to _v2 to force a fresh wallet file on devices that
    // were stuck syncing against the stale xmr-rpc.iamhch.com proxy
    // (whose tip sat ~115k blocks behind reality). Old wallet files
    // under peek_xmr/ are left on disk but ignored — the seed in
    // secure storage is the source of truth.
    final walletDir = Directory('${docs.path}/peek_xmr_v2');
    if (!walletDir.existsSync()) walletDir.createSync(recursive: true);
    final walletPath = '${walletDir.path}/wallet';

    stage('getting wallet manager');
    final wm = monero.WalletManagerFactory_getWalletManager();

    dynamic w;
    var fileExists = monero.WalletManager_walletExists(wm, walletPath);

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

    // Try the user's daemon first, then known-good public nodes. For
    // each candidate we kick refresh and wait briefly for the daemon
    // to report a tip. A stale daemon — one whose underlying node
    // hasn't kept up with the chain — accepts Wallet_init just fine
    // and reports a tip ~hundreds-of-thousands of blocks behind real
    // tip (that's exactly how xmr-rpc.iamhch.com parked us at 98%
    // forever scanning toward a fake-2024 head). Reject anything
    // below kMinSensibleTip and fall through to the next candidate.
    final candidates = <String>{daemonUri, ...kMoneroFallbackNodes}.toList();
    String? activeHostPort;
    bool activeSsl = false;
    String lastError = '';
    for (final url in candidates) {
      final ep = _DaemonEndpoint.parse(url);
      stage('init ${ep.hostPort} (ssl=${ep.useSsl})');
      final ok = monero.Wallet_init(
        w,
        daemonAddress: ep.hostPort,
        useSsl: ep.useSsl,
      );
      if (!ok) {
        lastError = monero.Wallet_errorString(w);
        stage('init failed on ${ep.hostPort}: ${lastError.isEmpty ? "(no detail)" : lastError}');
        continue;
      }
      // Kick refresh and poll for a sensible tip. monero_c falls back
      // to a compile-time approximate_blockchain_height if the daemon
      // never responds, so we have to wait for the value to *exceed*
      // that approximation rather than just be >0.
      monero.Wallet_startRefresh(w);
      int observedTip = 0;
      for (var i = 0; i < 16; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        observedTip = monero.Wallet_daemonBlockChainHeight(w);
        if (observedTip >= kMinSensibleTip) break;
      }
      if (observedTip >= kMinSensibleTip) {
        activeHostPort = ep.hostPort;
        activeSsl = ep.useSsl;
        break;
      }
      lastError = monero.Wallet_errorString(w);
      stage('${ep.hostPort} stale (tip=$observedTip < $kMinSensibleTip${lastError.isEmpty ? "" : ", $lastError"}) — trying next');
      // Pause refresh before trying the next candidate so we don't
      // accidentally race two refresh threads against the same wallet.
      try {
        monero.Wallet_pauseRefresh(w);
      } catch (_) {/* best effort */}
    }

    if (activeHostPort == null) {
      throw Exception(
          'No Monero node returned a current chain tip (≥ $kMinSensibleTip). '
          'Last error: ${lastError.isEmpty ? "(none)" : lastError}');
    }

    stage('attached $activeHostPort (ssl=$activeSsl) — synced refresh');

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
  /// still waiting for the daemon to respond with the tip. Rounds —
  /// not truncates — and snaps to 100 when we're caught up, so a 1-
  /// block lag against a 3.7M-block tip doesn't park us at 99 forever
  /// (it would otherwise compute to 99.99997…% and `.toInt()` to 99).
  int get syncProgressPct {
    final tip = monero.Wallet_daemonBlockChainHeight(_ptr);
    if (tip <= 0) return 0;
    final cur = monero.Wallet_blockChainHeight(_ptr);
    if (cur >= tip) return 100;
    return ((cur / tip) * 100).clamp(0.0, 100.0).round();
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
/// daemon is unreachable *or* serving a stale chain tip. Order
/// matters — first one to report a sensible tip wins.
const List<String> kMoneroFallbackNodes = [
  'https://nodes.hashvault.pro:18081',
  'https://node.sethforprivacy.com:443',
  'https://xmr-rpc.iamhch.com',
];

/// Minimum chain height we trust a daemon to be reporting. Anything
/// below this is treated as a stale / dead node and the fallback loop
/// moves on. Bake-time constant; bump on each release. As of May 2026
/// real tip is roughly 3,790,000+ and grows ~720 blocks/day, so a
/// 30k-block floor leaves comfortable margin for an "almost-current"
/// node without accepting one that's months behind.
const int kMinSensibleTip = 3760000;

/// Splits a user-friendly daemon URL into the host:port + useSsl pair
/// that monero_c's Wallet_init expects. Accepts:
///   https://host             -> host:443  ssl
///   https://host:port        -> host:port ssl
///   http://host[:port]       -> host:port no ssl  (default 18081)
///   host[:port]              -> host:port no ssl  (default 18081)
class _DaemonEndpoint {
  const _DaemonEndpoint(this.hostPort, this.useSsl);
  final String hostPort;
  final bool useSsl;

  static _DaemonEndpoint parse(String input) {
    final raw = input.trim();
    final hasScheme = raw.contains('://');
    final uri = Uri.parse(hasScheme ? raw : 'tcp://$raw');
    final ssl = uri.scheme == 'https';
    final host = uri.host;
    final port = uri.hasPort ? uri.port : (ssl ? 443 : 18081);
    return _DaemonEndpoint('$host:$port', ssl);
  }
}

/// Whether the host platform can load the monero_c .so / .dylib.
/// Used by the UI to decide whether to attempt MoneroSession.start.
bool moneroNativeAvailable() {
  if (Platform.isIOS) return false; // pending iOS framework wiring
  return Platform.isAndroid || Platform.isLinux || Platform.isMacOS;
}
