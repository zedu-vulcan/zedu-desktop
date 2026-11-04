import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('MagicLinkDeepLinkParser', () {
    test('extracts token from custom zedu scheme link', () {
      final uri = Uri.parse('zedu://auth/magick-link/verify?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('extracts token from https auth link on api.staging.zedu.chat', () {
      final uri = Uri.parse(
        'https://api.staging.zedu.chat/auth/magick-link/verify?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('extracts token from allowed production and staging hosts', () {
      final hosts = [
        'zedu.chat',
        'app.zedu.chat',
        'api.zedu.chat',
        'staging.zedu.chat',
        'app.staging.zedu.chat',
        'custom.subdomain.zedu.chat',
      ];

      for (final host in hosts) {
        final uri = Uri.parse(
          'https://$host/auth/magick-link/verify?token=token-$host',
        );
        expect(
          MagicLinkDeepLinkParser.extractToken(uri),
          'token-$host',
          reason: 'Failed for host: $host',
        );
      }
    });

    test('extracts token from localhost and 127.0.0.1 with http and https', () {
      for (final host in ['localhost', '127.0.0.1']) {
        final httpUri = Uri.parse(
          'http://$host/auth/magick-link/verify?token=dev-$host-http',
        );
        final httpsUri = Uri.parse(
          'https://$host/auth/magick-link/verify?token=dev-$host-https',
        );

        expect(MagicLinkDeepLinkParser.extractToken(httpUri), 'dev-$host-http');
        expect(
          MagicLinkDeepLinkParser.extractToken(httpsUri),
          'dev-$host-https',
        );
      }
    });

    test('rejects unencrypted http on remote trusted hosts', () {
      final unencryptedUris = [
        'http://zedu.chat/auth/magick-link/verify?token=abc123',
        'http://app.zedu.chat/auth/magick-link/verify?token=abc123',
        'http://api.staging.zedu.chat/auth/magick-link/verify?token=abc123',
      ];

      for (final raw in unencryptedUris) {
        expect(
          MagicLinkDeepLinkParser.extractToken(Uri.parse(raw)),
          isNull,
          reason: 'Should reject unencrypted http: $raw',
        );
      }
    });

    test('rejects arbitrary untrusted and phishing hosts', () {
      final untrustedUris = [
        'https://anything.example/auth/magick-link/verify?token=abc123',
        'https://evil.com/auth/magick-link/verify?token=abc123',
        'https://zedu.chat.attacker.com/auth/magick-link/verify?token=abc123',
        'https://attackerzedu.chat/auth/magick-link/verify?token=abc123',
        'https://app-zedu.chat/auth/magick-link/verify?token=abc123',
        'https://phishing.site/auth/magick-link/verify?token=abc123',
      ];

      for (final raw in untrustedUris) {
        expect(
          MagicLinkDeepLinkParser.extractToken(Uri.parse(raw)),
          isNull,
          reason: 'Should reject untrusted host: $raw',
        );
      }
    });

    test('returns null for missing, empty, or whitespace-only token', () {
      final emptyTokens = [
        'https://app.zedu.chat/auth/magick-link/verify',
        'https://app.zedu.chat/auth/magick-link/verify?token=',
        'https://app.zedu.chat/auth/magick-link/verify?token=   ',
        'zedu://auth/magick-link/verify',
        'zedu://auth/magick-link/verify?token=',
      ];

      for (final raw in emptyTokens) {
        expect(
          MagicLinkDeepLinkParser.extractToken(Uri.parse(raw)),
          isNull,
          reason: 'Should return null for missing/empty token: $raw',
        );
      }
    });

    test('returns null for unsupported path', () {
      final invalidPaths = [
        'zedu://auth/magick-link?token=abc123',
        'https://app.zedu.chat/login?token=abc123',
        'https://app.zedu.chat/verify?token=abc123',
        'https://app.zedu.chat/auth/other?token=abc123',
      ];

      for (final raw in invalidPaths) {
        expect(
          MagicLinkDeepLinkParser.extractToken(Uri.parse(raw)),
          isNull,
          reason: 'Should return null for unsupported path: $raw',
        );
      }
    });
  });
}
