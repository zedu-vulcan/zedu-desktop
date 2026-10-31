class MagicLinkDeepLinkParser {
  const MagicLinkDeepLinkParser._();

  static const List<String> _supportedPaths = [
    '/auth/login/magic-link',
    '/auth/magiclink',
    '/auth/magic-link',
    '/auth/magick-link/verify',
  ];

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

    if (scheme == 'zedu') {
      for (final target in _supportedPaths) {
        if (host == 'auth') {
          final stripped = target.replaceFirst('/auth', '');
          if (path == stripped || path == target) return true;
        } else {
          if (path == target || path.endsWith(target)) return true;
        }
      }
      return false;
    }

    if (scheme == 'https' || scheme == 'http') {
      for (final target in _supportedPaths) {
        if (path == target || path.endsWith(target)) {
          return true;
        }
      }
      return false;
    }

    return false;
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    final withLeading = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    if (withLeading.length > 1 && withLeading.endsWith('/')) {
      return withLeading.substring(0, withLeading.length - 1);
    }
    return withLeading;
  }
}
