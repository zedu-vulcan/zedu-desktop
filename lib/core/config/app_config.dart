import 'package:zedu/core/core.dart';

/// Default Google OAuth client id for the **desktop** client type; it applies
/// whenever `GOOGLE_CLIENT_ID` comes from neither `--dart-define` nor `.env`.
///
/// This is the id the app actually runs with: the locator registers
/// [AppConfig.fromEnvironment], whose fallback reads this constant, and the
/// [AppConfig] constructor default reads it too, so direct construction and
/// environment resolution can never disagree. For reference, the **web**
/// client id used by browser builds is
/// `764182056638-bi8bet0rdoabaeq24bqsdnb5iukn7ko4.apps.googleusercontent.com`.
const String kDefaultDesktopGoogleClientId =
    '764182056638-08g88e196e643mhpa2tuv5dpr7iumd1j.apps.googleusercontent.com';

/// The website's Contact Sales page, opened from the Enterprise plan.
const String kDefaultContactSalesUrl = 'https://zedu.chat/contact-sales';

/// Default Realtime WebSocket URL; applies when `REALTIME_URL` comes from neither
/// `--dart-define` nor `.env`.
const String kDefaultRealtimeUrl =
    'wss://realtime.staging.zedu.chat/connection/websocket';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.usesMockData,
    this.realtimeUrl = kDefaultRealtimeUrl,
    this.googleClientId = kDefaultDesktopGoogleClientId,
    this.googleClientSecret = '',
    this.contactSalesUrl = kDefaultContactSalesUrl,
  });

  /// Resolves config after [loadAppEnv] has run in [main] (root `.env` /
  /// `.env.example`, bundled as assets).
  ///
  /// Precedence: `--dart-define` wins, then dotenv keys from those files, then
  /// defaults. See [String.fromEnvironment](https://api.flutter.dev/flutter/dart-ui/String/String.fromEnvironment.html).
  factory AppConfig.fromEnvironment() {
    const defineApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const defineRealtimeUrl = String.fromEnvironment('REALTIME_URL');
    const defineUsesMock = String.fromEnvironment('USE_MOCK_DATA');
    const defineClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    const defineClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

    final isLoaded = dotenv.isInitialized;
    final envApiBaseUrl = isLoaded
        ? dotenv.maybeGet('API_BASE_URL')?.trim()
        : null;
    final envRealtimeUrl = isLoaded
        ? dotenv.maybeGet('REALTIME_URL')?.trim()
        : null;
    final envUsesMock = isLoaded
        ? dotenv.maybeGet('USE_MOCK_DATA')?.trim()
        : null;
    final envClientId = isLoaded
        ? dotenv.maybeGet('GOOGLE_CLIENT_ID')?.trim()
        : null;
    final envClientSecret = isLoaded
        ? dotenv.maybeGet('GOOGLE_CLIENT_SECRET')?.trim()
        : null;

    // Teams point the app at their own backend via --dart-define or .env; Zedu staging is the default.
    String apiBaseUrl = defineApiBaseUrl.isNotEmpty
        ? defineApiBaseUrl
        : (envApiBaseUrl?.isNotEmpty ?? false)
        ? envApiBaseUrl!
        : 'https://api.staging.zedu.chat/api/v1/';

    apiBaseUrl = apiBaseUrl.replaceAll('"', '').replaceAll("'", "");

    if (!apiBaseUrl.endsWith('/')) {
      apiBaseUrl += '/';
    }

    String realtimeUrl = defineRealtimeUrl.isNotEmpty
        ? defineRealtimeUrl
        : (envRealtimeUrl?.isNotEmpty ?? false)
        ? envRealtimeUrl!
        : kDefaultRealtimeUrl;

    realtimeUrl = realtimeUrl.replaceAll('"', '').replaceAll("'", "");

    final usesMockData = defineUsesMock.isNotEmpty
        ? _parseBool(defineUsesMock, defaultValue: false)
        : envUsesMock != null && envUsesMock.isNotEmpty
        ? _parseBool(envUsesMock, defaultValue: false)
        : false; // Changed to false so real backend is used by default

    final googleClientId = defineClientId.isNotEmpty
        ? defineClientId
        : (envClientId?.isNotEmpty ?? false)
        ? envClientId!
        : kDefaultDesktopGoogleClientId;

    final googleClientSecret = defineClientSecret.isNotEmpty
        ? defineClientSecret
        : (envClientSecret?.isNotEmpty ?? false)
        ? envClientSecret!
        : '';

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      usesMockData: usesMockData,
      realtimeUrl: realtimeUrl,
      googleClientId: googleClientId,
      googleClientSecret: googleClientSecret,
    );
  }

  final String apiBaseUrl;
  final bool usesMockData;
  final String realtimeUrl;
  final String googleClientId;
  final String googleClientSecret;
  final String contactSalesUrl;

  /// Helper to parse boolean environment variable values.
  static bool parseBool(String raw, {required bool defaultValue}) =>
      _parseBool(raw, defaultValue: defaultValue);
}

bool _parseBool(String raw, {required bool defaultValue}) {
  final normalized = raw.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return defaultValue;
}
