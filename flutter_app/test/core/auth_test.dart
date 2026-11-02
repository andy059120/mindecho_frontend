import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';

import '../support.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, dynamic> sessionJson({
  String token = 'old',
  String? refresh = 'refresh',
}) => {
  'token': token,
  'refreshToken': refresh,
  'user': {'id': 'u1', 'email': 'user@example.com'},
  'savedAt': DateTime.now().toIso8601String(),
};

void main() {
  test('註冊沿用既有接口並儲存後端 session', () async {
    final store = MemoryStore();
    final body = <String, dynamic>{
      'email': 'new@example.com',
      'password': 'test-password',
      'name': '測試',
      'dateOfBirth': '2000-01-01',
      'birthYear': 2000,
      'birthMonth': 1,
      'gender': '其他',
      'educationLevel': 4,
      'dataAnalysisConsent': false,
      'emergencyContacts': <Object>[],
      'mostImportantReasons': '測試資料',
    };
    final auth = AuthController(
      ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/register');
          expect(jsonDecode(request.body), body);
          return jsonResponse(sessionJson(token: 'registered'));
        }),
      ),
      store,
    );
    await auth.register(body);
    expect(auth.session!.token, 'registered');
    expect(store.value, isNotNull);
  });

  test('重設密碼僅呼叫原 API，不變更目前登入 session', () async {
    final auth = AuthController(
      ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/reset-password');
          expect(jsonDecode(request.body), {
            'name': '測試',
            'email': 'test@example.com',
            'newPassword': 'test-password',
          });
          return jsonResponse({'success': true});
        }),
      ),
      MemoryStore(),
    );
    await auth.resetPassword(
      name: ' 測試 ',
      email: ' test@example.com ',
      password: 'test-password',
    );
    expect(auth.session, isNull);
  });

  test('登入沿用 API 欄位並接受 accessToken/userData 別名', () async {
    final store = MemoryStore();
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'password': 'password',
        });
        return jsonResponse({
          'accessToken': 'access',
          'userData': {'id': 'u1'},
          'refreshToken': 'r',
        });
      }),
    );
    final auth = AuthController(api, store);
    await auth.login(' user@example.com ', 'password', remember: true);
    expect(auth.session!.token, 'access');
    expect(store.email, 'user@example.com');
    expect(jsonDecode(store.value!)['refreshToken'], 'r');
  });

  test('錯誤密碼不建立本機 session', () async {
    final store = MemoryStore();
    final auth = AuthController(
      ApiClient(
        client: MockClient(
          (_) async => jsonResponse({'message': '電子郵件或密碼錯誤'}, 401),
        ),
      ),
      store,
    );
    await expectLater(
      auth.login('user@example.com', 'bad', remember: false),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(auth.session, isNull);
    expect(store.value, isNull);
  });

  test('兩個同時發生的 401 共用一次 refresh，並以新 token 重送', () async {
    var refreshCount = 0;
    var oldRequests = 0;
    final bothUnauthorized = Completer<void>();
    final auth = AuthController(
      ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            refreshCount++;
            expect(request.headers['Authorization'], 'Bearer refresh');
            return jsonResponse({'accessToken': 'new'});
          }
          if (request.headers['Authorization'] == 'Bearer old') {
            oldRequests++;
            if (oldRequests == 2) bothUnauthorized.complete();
            await bothUnauthorized.future;
            return jsonResponse({}, 401);
          }
          expect(request.headers['Authorization'], 'Bearer new');
          return jsonResponse({'sessions': []});
        }),
      ),
      MemoryStore(),
    )..session = AuthSession.fromJson(sessionJson());
    await Future.wait([
      auth.authorized('GET', '/chat/sessions'),
      auth.authorized('GET', '/chat/sessions'),
    ]);
    expect(refreshCount, 1);
    expect(auth.session!.refreshToken, 'refresh');
  });

  test('refresh 被拒絕時清除 session，不無限重試', () async {
    var requests = 0;
    final store = MemoryStore()..value = jsonEncode(sessionJson());
    final auth = AuthController(
      ApiClient(
        client: MockClient((_) async {
          requests++;
          return jsonResponse({}, 401);
        }),
      ),
      store,
    )..session = AuthSession.fromJson(sessionJson());
    await expectLater(
      auth.authorized('GET', '/chat/sessions'),
      throwsA(isA<ApiException>()),
    );
    expect(requests, 2);
    expect(auth.session, isNull);
    expect(store.value, isNull);
  });

  test('refresh 暫時性 500 不清除既有 session', () async {
    final auth = AuthController(
      ApiClient(
        client: MockClient(
          (request) async => jsonResponse(
            {},
            request.url.path.endsWith('/auth/refresh') ? 500 : 401,
          ),
        ),
      ),
      MemoryStore(),
    )..session = AuthSession.fromJson(sessionJson());
    await expectLater(
      auth.authorized('GET', '/chat/sessions'),
      throwsA(isA<ApiException>()),
    );
    expect(auth.session!.token, 'old');
  });

  test('無 refresh token 且超過 15 分鐘不恢復登入', () async {
    final store = MemoryStore()
      ..value = jsonEncode({
        ...sessionJson(refresh: null),
        'savedAt': DateTime.now()
            .subtract(const Duration(minutes: 16))
            .toIso8601String(),
      });
    final auth = AuthController(
      ApiClient(client: MockClient((_) async => jsonResponse({}))),
      store,
    );
    await auth.restore();
    expect(auth.session, isNull);
    expect(store.value, isNull);
    expect(auth.restoring, false);
  });

  test('refresh 回應晚於登出時不恢復已登出的 session', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final store = MemoryStore();
    final auth = AuthController(
      ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            started.complete();
            return response.future;
          }
          if (request.url.path.endsWith('/auth/logout')) {
            return jsonResponse({});
          }
          return jsonResponse({}, 401);
        }),
      ),
      store,
    )..session = AuthSession.fromJson(sessionJson());
    final request = auth.authorized('GET', '/chat/sessions');
    final result = expectLater(request, throwsA(isA<ApiException>()));
    await started.future;
    await auth.logout();
    response.complete(jsonResponse(sessionJson(token: 'new')));
    await result;
    expect(auth.session, isNull);
    expect(store.value, isNull);
  });
}
