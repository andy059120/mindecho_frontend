import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/app.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';

import '../support.dart';

import 'package:mindecho_flutter/core/platform/media_picker.dart';

void main() {
  testWidgets('登入 → 聊天列表 → 紀錄 → 發訊息 → 登出，移除敏感畫面', (tester) async {
    final client = MockClient((request) async {
      Object result = {};
      switch (request.url.path) {
        case '/api/auth/login':
          result = {
            'token': 'token',
            'user': {'id': 'u1'},
          };
        case '/api/main/dailyQuestions':
          result = {'dailyQuestions': []};
        case '/api/diaries':
          result = {'entries': []};
        case '/api/main/scales/sessions':
          result = {'scales': []};
        case '/api/user/profile':
          result = {
            'user': {'id': 'u1', 'email': 'user@example.com'},
          };
        case '/api/chat/sessions':
          result = {
            'sessions': [
              {
                'id': 's1',
                'title': '我的對話',
                'chatbotType': 'CBT',
                'createdAt': '2026-10-30T00:00:00Z',
              },
            ],
          };
        case '/api/chat/sessions/s1/messages':
          result = request.method == 'POST'
              ? {'reply': '我在這裡傾聽', 'messageId': 'm2'}
              : {
                  'messages': [
                    {'id': 'm1', 'content': '歡迎', 'isFromUser': false},
                  ],
                };
      }
      return http.Response(
        jsonEncode(result),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final auth = AuthController(ApiClient(client: client), MemoryStore());
    await tester.pumpWidget(
      MindEchoApp(
        auth: auth,
        content: testChatContent,
        catalog: testCatalog,
        accountStore: MemoryAccountStore(),
        mediaPicker: MediaPicker(pendingStore: MemoryAccountStore()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('專業心理支持'), findsOneWidget);
    await tester.tap(find.text('立即登入'));
    await tester.pumpAndSettle();
    expect(find.text('歡迎回來'), findsOneWidget);
    await tester.enterText(
      find.byType(CupertinoTextField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'password');
    await tester.ensureVisible(find.widgetWithText(CupertinoButton, '登入'));
    await tester.tap(find.widgetWithText(CupertinoButton, '登入'));
    await tester.pumpAndSettle();
    expect(find.text('每日檢測'), findsOneWidget);
    await tester.tap(find.text('關閉'));
    await tester.pumpAndSettle();
    expect(find.text('功能介紹'), findsOneWidget);
    await tester.tap(find.text('聊天'));
    await tester.pumpAndSettle();
    expect(find.text('我的對話'), findsOneWidget);
    await tester.tap(find.text('我的對話'));
    await tester.pumpAndSettle();
    expect(find.text('歡迎'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextField), '今天有點累');
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.arrow_up_circle_fill));
    await tester.pumpAndSettle();
    expect(find.text('我在這裡傾聽'), findsOneWidget);
    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.text('專業心理支持'), findsOneWidget);
    expect(find.text('我在這裡傾聽'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
