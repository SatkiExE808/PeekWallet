import 'package:flutter_test/flutter_test.dart';
import 'package:peek_wallet/coins/monero/monero_wallet.dart';

/// Tests for the host:port parser handed to monero_c's Wallet_init.
/// Getting these wrong silently routes sync to the wrong endpoint or
/// fails authentication — UX-fatal because the error surface is
/// monero_c's "init returned false" with no detail.
void main() {
  group('plain hostnames', () {
    test('https with explicit port', () {
      final ep =
          MoneroDaemonEndpoint.parse('https://node.example.com:18081');
      expect(ep.hostPort, 'node.example.com:18081');
      expect(ep.useSsl, isTrue);
    });

    test('https with no port defaults to 443', () {
      final ep = MoneroDaemonEndpoint.parse('https://node.example.com');
      expect(ep.hostPort, 'node.example.com:443');
      expect(ep.useSsl, isTrue);
    });

    test('http defaults to 18081', () {
      final ep = MoneroDaemonEndpoint.parse('http://node.example.com');
      expect(ep.hostPort, 'node.example.com:18081');
      expect(ep.useSsl, isFalse);
    });

    test('bare host:port assumes tcp/no-ssl', () {
      final ep = MoneroDaemonEndpoint.parse('node.example.com:18089');
      expect(ep.hostPort, 'node.example.com:18089');
      expect(ep.useSsl, isFalse);
    });

    test('trims whitespace', () {
      final ep =
          MoneroDaemonEndpoint.parse('  https://node.example.com:18081  ');
      expect(ep.hostPort, 'node.example.com:18081');
    });
  });

  group('IPv6 literals', () {
    test('https with bracketed IPv6 and explicit port', () {
      final ep =
          MoneroDaemonEndpoint.parse('https://[2001:db8::1]:18081');
      // monero_c needs the brackets back — the hostPort string is
      // parsed by C-side code that splits on the last colon.
      expect(ep.hostPort, '[2001:db8::1]:18081');
      expect(ep.useSsl, isTrue);
    });

    test('IPv6 without port defaults correctly', () {
      final ep = MoneroDaemonEndpoint.parse('https://[::1]');
      expect(ep.hostPort, '[::1]:443');
    });

    test('non-IPv6 host stays unbracketed', () {
      final ep =
          MoneroDaemonEndpoint.parse('https://node.example.com');
      expect(ep.hostPort.startsWith('['), isFalse);
    });
  });

  group('isValid', () {
    test('accepts valid URLs', () {
      expect(MoneroDaemonEndpoint.isValid('https://x.com:18081'), isTrue);
      expect(MoneroDaemonEndpoint.isValid('x.com:18081'), isTrue);
    });

    test('rejects empty input', () {
      expect(MoneroDaemonEndpoint.isValid(''), isFalse);
    });

    test('rejects unparseable garbage', () {
      // ':::' is unparseable in dart's Uri.parse.
      expect(MoneroDaemonEndpoint.isValid(':::::'), isFalse);
    });
  });
}
