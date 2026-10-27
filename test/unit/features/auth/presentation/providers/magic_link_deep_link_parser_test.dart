import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('MagicLinkDeepLinkParser', () {
    test('extracts token from custom zedu scheme link', () {
      final uri = Uri.parse('zedu://auth/magick-link/verify?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('extracts token from https auth link', () {
      final uri = Uri.parse(
        'https://api.staging.zedu.chat/auth/magick-link/verify?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('extracts token from standard web email magic link', () {
      final uri = Uri.parse(
        'https://zedu.chat/auth/login/magic-link?token=emailToken789',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'emailToken789');
    });

    test('extracts token from web magic link with trailing slash', () {
      final uri = Uri.parse(
        'https://zedu.chat/auth/login/magic-link/?token=emailToken789',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'emailToken789');
    });

    test('extracts token from web /auth/magiclink link', () {
      final uri = Uri.parse(
        'https://staging.zedu.chat/auth/magiclink?token=magic456',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'magic456');
    });

    test('extracts token from custom scheme web login magic-link route', () {
      final uri = Uri.parse(
        'zedu://auth/login/magic-link?token=customScheme123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'customScheme123');
    });

    test('returns null for missing token query parameter', () {
      final uri = Uri.parse('zedu://auth/magick-link/verify');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('returns null for empty token query parameter', () {
      final uri = Uri.parse(
        'https://zedu.chat/auth/login/magic-link?token=   ',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('returns null for unsupported path', () {
      final uri = Uri.parse('zedu://auth/magick-link?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });
  });
}
