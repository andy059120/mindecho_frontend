import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';
import 'package:mindecho_flutter/features/chat/chat_content.dart';
import 'package:mindecho_flutter/features/chat/chat_models.dart';
import 'package:mindecho_flutter/features/chat/chat_repository.dart';

import '../support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('建立聊天室指定 Claude，發訊息不自動重送失敗 POST', () async {
    var posts = 0;
    final auth = AuthController(
      ApiClient(
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token');
          if (request.url.path == '/api/chat/sessions') {
            expect(jsonDecode(request.body), {
              'chatbotType': 'CBT',
              'provider': 'anthropic',
              'title': '今天',
            });
            return http.Response(
              jsonEncode({
                'session': {
                  'id': 's1',
                  'title': '今天',
                  'chatbotType': 'CBT',
                  'createdAt': '2026-10-30T00:00:00Z',
                },
              }),
              201,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          expect(request.url.path, '/api/chat/sessions/s1/messages');
          expect(jsonDecode(request.body), {'message': '你好'});
          posts++;
          return http.Response('{}', 500);
        }),
      ),
      MemoryStore(),
    )..session = AuthSession(token: 'token', user: {}, savedAt: DateTime.now());
    final repository = ChatRepository(auth);
    final session = await repository.create(ChatMode.cbt, ' 今天 ');
    expect(session.mode, ChatMode.cbt);
    await expectLater(
      repository.send(session.id, '你好'),
      throwsA(isA<ApiException>()),
    );
    expect(posts, 1);
  });

  test('讀取既有固定語料，保留 HIGH 優先與否定語境判斷', () async {
    final content = await ChatContent.load();
    expect(content.welcomes.keys.toSet(), {
      'INITIAL',
      'CBT',
      'DBT',
      'MBT',
      'MBCT',
    });
    expect(content.containsCrisisTerms('我想自殺'), true);
    expect(content.containsCrisisTerms('今天心情不錯'), false);
    final negations =
        content.corpus['NEGATION_CONTEXTS'] as Map<String, dynamic>;
    for (final phrases in negations.values) {
      expect(
        content.containsCrisisTerms((phrases as List).first as String),
        false,
      );
    }
  });
}
