import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Lightweight price oracle. Polls CoinGecko's public API every 5
/// minutes for the configured coins and fiat currency, caches the
/// result, exposes a ChangeNotifier so listening widgets repaint when
/// new prices land.
///
/// CoinGecko's free endpoint allows 10-30 req/min — well under our
/// every-5-minute cadence. No API key required. No PII sent to the
/// service: the request body lists only coin ids and target
/// currencies.
///
/// Opt-out: PriceFeed.I.disable() stops the timer and clears the
/// cached values. Settings → Display Currency drives the choice of
/// fiat (USD by default).
class PriceFeed extends ChangeNotifier {
  PriceFeed._();
  static final PriceFeed I = PriceFeed._();

  static const _endpoint = 'https://api.coingecko.com/api/v3/simple/price';
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const _currencyKey = 'prices.display_currency.v1';
  static const _enabledKey = 'prices.enabled.v1';
  static const _defaultCurrency = 'usd';

  /// coinId → CoinGecko id. Each CoinModule's id is the user-facing
  /// symbol; the API takes specific names instead.
  static const Map<String, String> _coinGeckoIds = {
    'XMR': 'monero',
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'LTC': 'litecoin',
    'BCH': 'bitcoin-cash',
    'SOL': 'solana',
    'TRX': 'tron',
    'POL': 'polygon-ecosystem-token',
    'DOGE': 'dogecoin',
    // Stablecoins — required for ERC-20 token rows to show fiat.
    // Always ~$1 but querying explicitly handles depegs (rare) and
    // non-USD pricing (e.g. user has display currency = EUR).
    'USDT': 'tether',
    'USDC': 'usd-coin',
    'DAI': 'dai',
    // Polygon ecosystem majors. WMATIC tracks POL (post-migration);
    // WETH tracks ETH. We list them separately so the row labels
    // match the wallet's display symbol.
    'WMATIC': 'polygon-ecosystem-token',
    'WETH': 'weth',
    'LINK': 'chainlink',
    'AAVE': 'aave',
  };

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final http.Client _http = http.Client();
  Timer? _timer;
  bool _disposed = false;

  /// Per-coin price in the active fiat currency. Empty until the
  /// first fetch lands; non-empty values are sticky across timer
  /// cycles so transient API failures don't blank the UI.
  final Map<String, double> _prices = {};
  Map<String, double> get prices => Map.unmodifiable(_prices);

  /// ISO 4217-ish lowercase currency code ("usd", "eur", "jpy"…).
  /// CoinGecko accepts ~50.
  String _currency = _defaultCurrency;
  String get currency => _currency;

  /// User opted-in flag. Defaults to enabled. When false, no network
  /// requests are made and [prices] stays empty.
  bool _enabled = true;
  bool get enabled => _enabled;

  /// Boot the feed: load saved prefs + kick a first fetch. Safe to
  /// call multiple times — successive calls re-arm the timer.
  Future<void> start() async {
    if (_disposed) return;
    _enabled = (await _storage.read(key: _enabledKey)) != 'false';
    _currency = (await _storage.read(key: _currencyKey)) ?? _defaultCurrency;
    _timer?.cancel();
    if (!_enabled) return;
    // Fire one fetch immediately so the UI doesn't sit at "—" for 5
    // minutes after launch.
    unawaited(_fetch());
    _timer = Timer.periodic(_refreshInterval, (_) => _fetch());
  }

  Future<void> setCurrency(String code) async {
    _currency = code.toLowerCase();
    await _storage.write(key: _currencyKey, value: _currency);
    _prices.clear();
    notifyListeners();
    if (_enabled) unawaited(_fetch());
  }

  Future<void> setEnabled(bool on) async {
    _enabled = on;
    await _storage.write(key: _enabledKey, value: on ? 'true' : 'false');
    if (on) {
      await start();
    } else {
      _timer?.cancel();
      _prices.clear();
      notifyListeners();
    }
  }

  Future<void> _fetch() async {
    if (!_enabled) return;
    try {
      final ids = _coinGeckoIds.values.join(',');
      final uri = Uri.parse('$_endpoint?ids=$ids&vs_currencies=$_currency');
      final resp = await _http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      // Reverse the coingecko-id map so we can write back per
      // app-side coin id.
      final inverse = _coinGeckoIds.map((k, v) => MapEntry(v, k));
      for (final entry in json.entries) {
        final coinId = inverse[entry.key];
        if (coinId == null) continue;
        final inner = entry.value as Map<String, dynamic>?;
        final price = inner?[_currency];
        if (price is num) {
          _prices[coinId] = price.toDouble();
        }
      }
      notifyListeners();
    } catch (_) {
      // Transient errors don't propagate — stale price is better
      // than a blank UI. Real errors will be caught by the user
      // noticing prices haven't refreshed in 30+ min.
    }
  }

  /// Format `amount` (in the coin's whole units, not minor units) as
  /// "$X.XX USD". Returns empty when the price isn't known yet.
  String formatFiat(String coinId, double amount) {
    final px = _prices[coinId];
    if (px == null) return '';
    final fiat = amount * px;
    final code = _currency.toUpperCase();
    if (fiat == 0) return '\$0.00 $code';
    final digits = fiat.abs() >= 100 ? 0 : 2;
    return '\$${fiat.toStringAsFixed(digits)} $code';
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _http.close();
    super.dispose();
  }
}
