class MagicLinkDeepLinkParser {
  const MagicLinkDeepLinkParser._();

  static const Set<String> _allowedHosts = {
    'zedu.chat',
    'app.zedu.chat',
    'api.zedu.chat',
    'staging.zedu.chat',
    'app.staging.zedu.chat',
    'api.staging.zedu.chat',
    'localhost',
    '127.0.0.1',
  };

  static String? extractToken(Uri uri) {
    if (!_isSupportedMagicLinkUri(uri)) return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static bool _isSupportedMagicLinkUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = _normalizePath(uri.path);

    if (scheme == 'zedu' && host == 'auth' && path == '/magick-link/verify') {
      return true;
    }

    if (!_isSupportedWebScheme(scheme, host)) {
      return false;
    }

    if (!_isAllowedHost(host)) {
      return false;
    }

    if (path == '/auth/magick-link/verify' ||
        path == '/magick-link/verify' ||
        path.endsWith('/auth/magick-link/verify')) {
      return true;
    }

    return false;
  }

  static bool _isSupportedWebScheme(String scheme, String host) {
    if (scheme == 'https') return true;
    if (scheme == 'http' && (host == 'localhost' || host == '127.0.0.1')) {
      return true;
    }
    return false;
  }

  static bool _isAllowedHost(String host) {
    if (host.isEmpty) return false;
    if (_allowedHosts.contains(host)) return true;
    if (host.endsWith('.zedu.chat')) {
      final prefix = host.substring(0, host.length - '.zedu.chat'.length);
      return RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)*$').hasMatch(prefix);
    }
    return false;
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
