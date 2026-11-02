import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AccountStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class KeychainAccountStore implements AccountStore {
  KeychainAccountStore(String accountId)
    : prefix = 'mindecho.${base64Url.encode(utf8.encode(accountId))}';
  final String prefix;
  static const _storage = FlutterSecureStorage();
  Future<void> _queue = Future.value();
  @override
  Future<String?> read(String key) async {
    await _queue;
    return _storage.read(key: '$prefix.$key');
  }

  @override
  Future<void> write(String key, String? value) {
    final operation = _queue.then(
      (_) => value == null
          ? _storage.delete(key: '$prefix.$key')
          : _storage.write(key: '$prefix.$key', value: value),
    );
    _queue = operation.catchError((Object _) {});
    return operation;
  }
}
