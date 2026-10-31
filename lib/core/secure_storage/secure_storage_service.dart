import 'package:zedu/core/core.dart';

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _sessionOnlyKey = 'session_only';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> deleteAccessToken() => _storage.delete(key: _accessTokenKey);

  /// Marks the stored token as valid for this app run only ("Remember me"
  /// unticked), so it is discarded on the next launch.
  Future<void> setSessionOnly(bool sessionOnly) => sessionOnly
      ? _storage.write(key: _sessionOnlyKey, value: 'true')
      : _storage.delete(key: _sessionOnlyKey);

  Future<bool> isSessionOnly() async =>
      await _storage.read(key: _sessionOnlyKey) == 'true';

  Future<void> writeData(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<String?> readData(String key) => _storage.read(key: key);

  Future<void> deleteValue(String key) => _storage.delete(key: key);

  Future<void> clearAll() => _storage.deleteAll();
}
