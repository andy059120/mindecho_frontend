import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_store.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.savedAt,
    this.refreshToken,
  });
  final String token;
  final String? refreshToken;
  final Map<String, dynamic> user;
  final DateTime savedAt;
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'] ?? json['accessToken'];
    final user = json['user'] ?? json['userData'];
    if (json['success'] == false ||
        token is! String ||
        token.isEmpty ||
        user is! Map<String, dynamic>) {
      throw const ApiException('登入回應格式異常，請重新登入');
    }
    return AuthSession(
      token: token,
      refreshToken: json['refreshToken'] as String?,
      user: user,
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'user': user,
    'savedAt': savedAt.toIso8601String(),
  };
}

class AuthController extends ChangeNotifier {
  AuthController(this.api, this.store);
  final ApiClient api;
  final SessionStore store;
  AuthSession? session;
  bool restoring = true;
  Future<void>? _refreshing;
  Future<void> _storageQueue = Future.value();
  int _generation = 0;

  Future<void> _persist(Future<void> Function() operation) {
    final pending = _storageQueue.then((_) => operation());
    _storageQueue = pending.catchError((Object _) {});
    return pending;
  }

  Future<void> restore() async {
    try {
      final raw = await store.read();
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('登入回應格式異常');
      }
      final saved = AuthSession.fromJson(decoded);
      // 沿用 Swift：無 refresh token 的 session 僅保留 15 分鐘。
      if ((saved.refreshToken?.isNotEmpty ?? false) ||
          DateTime.now().difference(saved.savedAt) <=
              const Duration(minutes: 15)) {
        session = saved;
      } else {
        await store.clear();
      }
    } on FormatException {
      await store.clear();
    } on ApiException {
      await store.clear();
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, {
    required bool remember,
  }) async {
    final generation = ++_generation;
    final payload = await api.request(
      'POST',
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    await _acceptAuth(payload, generation, email: email, remember: remember);
  }

  Future<void> register(Map<String, dynamic> body) async {
    final generation = ++_generation;
    final payload = await api.request('POST', '/auth/register', body: body);
    await _acceptAuth(
      payload,
      generation,
      email: body['email'] as String,
      remember: false,
    );
  }

  Future<void> resetPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final payload = await api.request(
      'POST',
      '/auth/reset-password',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'newPassword': password,
      },
    );
    if (payload['success'] == false) {
      throw ApiException(payload['message'] as String? ?? '重設密碼失敗');
    }
  }

  Future<void> _acceptAuth(
    Map<String, dynamic> payload,
    int generation, {
    required String email,
    required bool remember,
  }) async {
    if (payload['success'] == false) {
      throw ApiException(payload['message'] as String? ?? '電子郵件或密碼錯誤');
    }
    final next = AuthSession.fromJson(payload);
    await _persist(() async {
      if (generation != _generation) throw const ApiException('登入狀態已變更');
      await store.write(jsonEncode(next.toJson()));
      await store.rememberEmail(remember ? email.trim() : null);
    });
    if (generation != _generation) throw const ApiException('登入狀態已變更');
    session = next;
    notifyListeners();
  }

  /// 同時收到多個 401 時只 refresh 一次；每個原請求最多重送一次。
  Future<Map<String, dynamic>> authorized(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final generation = _generation;
    final original = session;
    if (original == null) throw const ApiException('請先登入', status: 401);
    try {
      return await api.request(
        method,
        path,
        token: original.token,
        body: body,
        query: query,
        timeout: timeout,
      );
    } on ApiException catch (error) {
      if (error.status != 401) rethrow;
      if (generation != _generation) rethrow;
      if (session == null) rethrow;
      if (session!.token == original.token) await _refresh();
      final next = session;
      if (generation != _generation) throw const ApiException('登入狀態已變更');
      if (next == null) throw const ApiException('請重新登入', status: 401);
      try {
        return await api.request(
          method,
          path,
          token: next.token,
          body: body,
          query: query,
          timeout: timeout,
        );
      } on ApiException catch (retryError) {
        if (retryError.status == 401 && generation == _generation) {
          await _clear();
        }
        rethrow;
      }
    }
  }

  Future<void> _refresh() async {
    if (_refreshing != null) return _refreshing;
    final future = _performRefresh();
    _refreshing = future;
    try {
      await future;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _performRefresh() async {
    final original = session;
    final generation = _generation;
    final refresh = original?.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      await _clear();
      throw const ApiException('登入已失效，請重新登入', status: 401);
    }
    try {
      final result = await api.request('POST', '/auth/refresh', token: refresh);
      final next = AuthSession.fromJson({
        ...result,
        'user': result['user'] ?? result['userData'] ?? original!.user,
        'refreshToken': result['refreshToken'] ?? refresh,
      });
      if (generation != _generation) throw const ApiException('登入狀態已變更');
      await _persist(() async {
        if (generation != _generation) throw const ApiException('登入狀態已變更');
        await store.write(jsonEncode(next.toJson()));
      });
      if (generation != _generation) throw const ApiException('登入狀態已變更');
      session = next;
    } on ApiException catch (error) {
      if (generation == _generation &&
          (error.status == 401 ||
              error.status == 403 ||
              error.status == null && error.message.startsWith('登入回應'))) {
        await _clear();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final refresh = session?.refreshToken;
    await _clear();
    if (refresh != null) {
      try {
        await api.request(
          'POST',
          '/auth/logout',
          body: {'refreshToken': refresh},
        );
      } on ApiException {
        /* 離線時仍完成本機登出。 */
      }
    }
  }

  Future<void> _clear() async {
    _generation++;
    session = null;
    notifyListeners();
    await _persist(store.clear);
  }
}
