import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';
import 'package:mindecho_flutter/features/chat/chat_repository.dart';

import '../support.dart';

void main() {
  testWidgets('聊天超過 30 秒仍可收到回覆，POST 僅送出一次', (tester) async {
    var sends = 0;
    final api = ApiClient(
      client: MockClient((request) async {
        sends++;
        await Future<void>.delayed(const Duration(seconds: 31));
        return http.Response('{"reply":"hello"}', 200);
      }),
    );
    final auth = AuthController(api, MemoryStore())
      ..session = AuthSession(token: 'test', user: {}, savedAt: DateTime.now());
    Map<String, dynamic>? result;
    final pending = ChatRepository(auth)
        .send('test', 'hello')
        .then((value) => result = value);
    await tester.pump(const Duration(seconds: 31));
    await pending;
    expect(result?['reply'], 'hello');
    expect(sends, 1);
    auth.dispose();
  });
}
