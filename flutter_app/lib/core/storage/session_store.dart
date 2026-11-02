import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
  Future<String?> readRememberedEmail();
  Future<void> rememberEmail(String? email);
}

class KeychainSessionStore implements SessionStore {
  const KeychainSessionStore();
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'mindecho.session.v1';
  static const _emailKey = 'mindecho.remembered_email';
  @override
  Future<String?> read() => _storage.read(key: _sessionKey);
  @override
  Future<void> write(String value) =>
      _storage.write(key: _sessionKey, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);
  @override
  Future<String?> readRememberedEmail() => _storage.read(key: _emailKey);
  @override
  Future<void> rememberEmail(String? email) => email == null
      ? _storage.delete(key: _emailKey)
      : _storage.write(key: _emailKey, value: email);
}
