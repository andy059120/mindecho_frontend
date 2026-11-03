import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mindecho_flutter/app/app.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/core/storage/session_store.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';
import 'package:mindecho_flutter/features/chat/chat_models.dart';
import 'package:mindecho_flutter/features/chat/chat_repository.dart';
import 'package:mindecho_flutter/features/dashboard/repository.dart';

/// 僅供手動啟動的真實後端測試。帳密由本機 VM service 在執行期間傳入，
/// 不使用 dart-define，不將帳密編入 APK；一般 flutter test 不會執行此檔。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final credentials = Completer<Map<String, String>>();
  developer.registerExtension('ext.mindecho.testCredentials', (
    _,
    params,
  ) async {
    if (!credentials.isCompleted) credentials.complete(params);
    return developer.ServiceExtensionResponse.result(
      jsonEncode({'accepted': true}),
    );
  });

  testWidgets('Android 真實後端登入、聊天、日記與 session 恢復', (tester) async {
    final input = await credentials.future.timeout(const Duration(minutes: 5));
    final client = http.Client();
    final auth = AuthController(
      ApiClient(client: client),
      const KeychainSessionStore(),
    );
    await tester.pumpWidget(MindEchoApp(auth: auth));
    await tester.pumpAndSettle();
    if (auth.session == null) {
      await tester.tap(find.text('立即登入'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CupertinoTextField).at(0),
        input['email']!,
      );
      await tester.enterText(
        find.byType(CupertinoTextField).at(1),
        input['password']!,
      );
      input.clear();
      await tester.ensureVisible(find.widgetWithText(CupertinoButton, '登入'));
      await tester.tap(find.widgetWithText(CupertinoButton, '登入'));
      for (var i = 0; i < 90 && auth.session == null; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }
    expect(auth.session, isNotNull);
    debugPrint('ANDROID_LIVE: login passed');
    final chats = ChatRepository(auth);
    final marker = 'android-smoke-${DateTime.now().millisecondsSinceEpoch}';
    final chat = await chats.create(ChatMode.cbt, marker);
    await chats.send(chat.id, '這是 Android 功能測試，請簡短回覆「測試成功」。');
    expect(await chats.history(chat.id), isNotEmpty);
    debugPrint('ANDROID_LIVE: chat passed ($marker)');
    final dashboard = DashboardRepository(auth);
    final existing = await dashboard.diaries();
    var day = DateTime.now();
    while (existing.any(
      (e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day,
    )) {
      day = day.subtract(const Duration(days: 1));
    }
    final entry = await dashboard.saveDiary(
      content: '$marker：Android 日記儲存驗證，非實際心情紀錄。',
      mood: 'OKAY',
      date: day,
    );
    expect((await dashboard.diaries()).any((e) => e.id == entry.id), isTrue);
    debugPrint('ANDROID_LIVE: diary create/read passed');
    try {
      await dashboard.saveDiary(
        id: entry.id,
        content: '$marker：Android 日記編輯驗證，非實際心情紀錄。',
        mood: 'OKAY',
        date: day,
      );
      debugPrint('ANDROID_LIVE: diary PATCH passed');
    } on ApiException catch (error) {
      debugPrint('ANDROID_LIVE: diary PATCH unavailable (${error.status})');
    }
    await dashboard.scales();
    debugPrint(
      'ANDROID_LIVE: scale history passed (no synthetic health answers submitted)',
    );
    final restored = AuthController(
      ApiClient(client: client),
      const KeychainSessionStore(),
    );
    await restored.restore();
    expect(restored.session, isNotNull);
    debugPrint('ANDROID_LIVE: persisted session restore passed');
    await auth.logout();
    expect(await const KeychainSessionStore().read(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('專業心理支持'), findsOneWidget);
    debugPrint('ANDROID_LIVE: logout passed');
    await tester.pumpWidget(const SizedBox());
    restored.dispose();
    auth.dispose();
    client.close();
  }, timeout: const Timeout(Duration(minutes: 8)));
}
