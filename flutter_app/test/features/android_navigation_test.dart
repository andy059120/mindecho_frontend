import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/main_shell.dart';
import 'package:mindecho_flutter/core/platform/media_picker.dart';

import '../support.dart';
import 'dashboard_test.dart' as fixtures;

void main() {
  testWidgets('系統返回只移除作用中分頁的子頁，保留其他分頁導覽', (tester) async {
    final auth = await fixtures.signedIn(
      MockClient((r) async => fixtures.response(fixtures.fixture(r.url.path))),
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: MainShell(
          auth: auth,
          content: testChatContent,
          catalog: testCatalog,
          store: MemoryAccountStore(),
          mediaPicker: MediaPicker(pendingStore: MemoryAccountStore()),
          promptCheckIn: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tabs = tester
        .widgetList<CupertinoTabView>(
          find.byType(CupertinoTabView, skipOffstage: false),
        )
        .toList();
    tabs[0].navigatorKey!.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => const CupertinoPageScaffold(child: Text('首頁子頁')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('聊天').last);
    await tester.pumpAndSettle();
    tabs[1].navigatorKey!.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => const CupertinoPageScaffold(child: Text('聊天子頁')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('聊天子頁'), findsNothing);
    await tester.tap(find.text('首頁').last);
    await tester.pumpAndSettle();
    expect(find.text('首頁子頁'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('首頁子頁'), findsNothing);
    await tester.tap(find.text('功能介紹'));
    await tester.pumpAndSettle();
    expect(find.text('總覽你的狀態與每日提醒。'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('總覽你的狀態與每日提醒。'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
