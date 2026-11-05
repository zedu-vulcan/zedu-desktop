import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  setUp(() {
    dotenv.clean();
  });

  tearDown(() {
    dotenv.clean();
  });

  group('AppConfig defaults', () {
    test('uses fallback constants when environment has no entries', () {
      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'https://api.staging.zedu.chat/api/v1/');
      expect(config.realtimeUrl, kDefaultRealtimeUrl);
      expect(config.usesMockData, isFalse);
      expect(config.googleClientId, kDefaultDesktopGoogleClientId);
      expect(config.googleClientSecret, isEmpty);
      expect(config.contactSalesUrl, kDefaultContactSalesUrl);
    });

    test('constructor applies default realtimeUrl and googleClientId', () {
      const config = AppConfig(
        apiBaseUrl: 'https://example.com/api/',
        usesMockData: true,
      );

      expect(config.realtimeUrl, kDefaultRealtimeUrl);
      expect(config.googleClientId, kDefaultDesktopGoogleClientId);
      expect(config.contactSalesUrl, kDefaultContactSalesUrl);
    });
  });

  group('AppConfig .env parsing and precedence', () {
    test('reads API_BASE_URL, REALTIME_URL, and credentials from .env', () {
      dotenv.loadFromString(
        envString: '''
API_BASE_URL=https://custom-api.example.com/api/v1
REALTIME_URL=wss://custom-realtime.example.com/socket
USE_MOCK_DATA=true
GOOGLE_CLIENT_ID=custom-client-id
GOOGLE_CLIENT_SECRET=custom-secret
''',
      );

      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'https://custom-api.example.com/api/v1/');
      expect(config.realtimeUrl, 'wss://custom-realtime.example.com/socket');
      expect(config.usesMockData, isTrue);
      expect(config.googleClientId, 'custom-client-id');
      expect(config.googleClientSecret, 'custom-secret');
    });

    test(
      'normalizes apiBaseUrl by adding trailing slash and stripping quotes',
      () {
        dotenv.loadFromString(
          envString: '''
API_BASE_URL="https://quoted-api.example.com/api"
REALTIME_URL='wss://quoted-realtime.example.com'
''',
        );

        final config = AppConfig.fromEnvironment();

        expect(config.apiBaseUrl, 'https://quoted-api.example.com/api/');
        expect(config.realtimeUrl, 'wss://quoted-realtime.example.com');
      },
    );
  });

  group('AppConfig boolean parsing for USE_MOCK_DATA', () {
    test('parses truthy values ("true", "1", "yes") as true', () {
      for (final truthy in ['true', 'TRUE', 'True', '1', 'yes', 'YES']) {
        dotenv.clean();
        dotenv.loadFromString(envString: 'USE_MOCK_DATA=$truthy\n');
        final config = AppConfig.fromEnvironment();
        expect(
          config.usesMockData,
          isTrue,
          reason: 'Failed for truthy value: $truthy',
        );
      }
    });

    test('parses falsy values ("false", "0", "no") as false', () {
      for (final falsy in ['false', 'FALSE', 'False', '0', 'no', 'NO']) {
        dotenv.clean();
        dotenv.loadFromString(envString: 'USE_MOCK_DATA=$falsy\n');
        final config = AppConfig.fromEnvironment();
        expect(
          config.usesMockData,
          isFalse,
          reason: 'Failed for falsy value: $falsy',
        );
      }
    });

    test(
      'falls back to defaultValue for empty, invalid, or unrecognized strings',
      () {
        expect(AppConfig.parseBool('', defaultValue: false), isFalse);
        expect(AppConfig.parseBool('', defaultValue: true), isTrue);
        expect(AppConfig.parseBool('invalid', defaultValue: false), isFalse);
        expect(AppConfig.parseBool('random', defaultValue: true), isTrue);
      },
    );
  });
}
