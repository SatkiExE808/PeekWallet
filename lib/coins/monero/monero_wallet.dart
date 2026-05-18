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
//   2. WalletManager_createWalletFromKeys()
//                                   — hands keys to the native wallet,
//                                      which writes a wallet file to
//                                      `walletDir`.
//   3. Wallet_init(daemonAddress)   — points the wallet at our
//                                      CORS-friendly xmr-rpc.iamhch.com
//                                      proxy.
//   4. Wallet_startRefresh()         — background sync. Balance ticks
//                                      up as blocks scan.
//   5. balanceXmr / syncProgressPct  — UI polls these.
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
    String passphrase = '',
    String walletPassword = 'peek-monero-internal',
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
    final walletDir = Directory('${docs.path}/peek_xmr');
    if (!walletDir.existsSync()) walletDir.createSync(recursive: true);
    final walletPath = '${walletDir.path}/wallet';

    stage('getting wallet manager');
    final wm = monero.WalletManagerFactory_getWalletManager();

    final dynamic w;
    if (monero.WalletManager_walletExists(wm, walletPath)) {
      stage('opening existing wallet file');
      w = monero.WalletManager_openWallet(
        wm,
        path: walletPath,
        password: walletPassword,
      );
    } else {
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

    // Try the user's daemon first, then known-good public nodes. We
    // *only* gate on Wallet_init's return value — Wallet_connected
    // reports a cached status that stays 0 until refresh actually
    // pulls something, so using it as a boot-time probe causes the
    // loop to reject every candidate. The real connectivity test is
    // whether daemonTipHeight goes >0 once refresh runs (UI surfaces
    // that as "Connecting to daemon…" vs sync %).
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

    stage('attached $activeHostPort (ssl=$activeSsl) — starting refresh');
    monero.Wallet_startRefresh(w);
    stage('ready');

    return MoneroWallet._(w, keys.primaryAddress);
  }

  /// Daemon-reported chain tip. Stays 0 until refresh successfully
  /// fetches `/get_height` at least once — so a >0 value is the most
  /// reliable signal that we're actually talking to a node.
  int get daemonTipHeight => monero.Wallet_daemonBlockChainHeight(_ptr);

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
  bool get isSynced => monero.Wallet_synchronized(_ptr);

  /// 0–100 percentage based on `current / tip`. Returns 0 while we're
  /// still waiting for the daemon to respond with the tip.
  int get syncProgressPct {
    final tip = monero.Wallet_daemonBlockChainHeight(_ptr);
    if (tip <= 0) return 0;
    final cur = monero.Wallet_blockChainHeight(_ptr);
    final pct = ((cur / tip) * 100).clamp(0, 100);
    return pct.toInt();
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
    String passphrase = '',
  }) {
    if (_wallet != null) return Future.value(_wallet);
    return _inFlight ??= _doStart(
      mnemonic: mnemonic,
      restoreHeight: restoreHeight,
      daemonUri: daemonUri,
      passphrase: passphrase,
    ).whenComplete(() => _inFlight = null);
  }

  Future<MoneroWallet?> _doStart({
    required String mnemonic,
    required int restoreHeight,
    required String daemonUri,
    required String passphrase,
  }) async {
    _lastError = null;
    try {
      _wallet = await MoneroWallet.open(
        mnemonic: mnemonic,
        passphrase: passphrase,
        restoreHeight: restoreHeight,
        daemonUri: daemonUri,
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

/// Default daemon for the Monero wallet — Peek's CORS-friendly proxy
/// in front of Cake's public node. Override per device via Settings →
/// Monero Node (saved in shared prefs).
const String kDefaultMoneroDaemon = 'https://xmr-rpc.iamhch.com';

/// Public Monero RPC nodes we fall back to when the user's preferred
/// daemon (or our own proxy) is unreachable. Order matters — first
/// one to respond wins. All advertise SSL.
const List<String> kMoneroFallbackNodes = [
  'https://xmr-node.cakewallet.com:18081',
  'https://nodes.hashvault.pro:18081',
  'https://node.sethforprivacy.com:443',
];

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
