import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/theme.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';
import 'package:mindecho_flutter/features/chat/chat_detail_page.dart';
import 'package:mindecho_flutter/features/chat/chat_models.dart';
import 'package:mindecho_flutter/features/chat/chat_repository.dart';
import 'package:mindecho_flutter/features/chat/chat_visuals.dart';
import 'package:mindecho_flutter/features/dashboard/catalog.dart';
import 'package:mindecho_flutter/features/dashboard/controller.dart';
import 'package:mindecho_flutter/features/dashboard/repository.dart';
import 'package:mindecho_flutter/features/diary/diary_page.dart';
import 'package:mindecho_flutter/features/resources/resources_page.dart';
import 'package:mindecho_flutter/features/scales/scale_page.dart';

import '../support.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(402, 874),
    const Size(440, 956),
  ]) {
    testWidgets('彈出頁面 ${size.width}：介紹、資源、量表與日記無溢位，不送出資料', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var writes = 0;
      final auth = AuthController(
        ApiClient(
          client: MockClient((r) async {
            if (r.method != 'GET' && r.url.path != '/api/auth/login') writes++;
            final body = r.url.path == '/api/auth/login'
                ? {
                    'token': 'test',
                    'user': {'id': 'u1'},
                  }
                : <String, dynamic>{};
            return http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
        MemoryStore(),
      );
      await auth.login('test@example.com', 'test', remember: false);
      final controller = DashboardController(DashboardRepository(auth));
      final catalog = (await tester.runAsync(DashboardCatalog.load))!;
      Future<void> show(Widget page) async {
        await tester.pumpWidget(CupertinoApp(theme: appTheme, home: page));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      for (final mode in ChatMode.values) {
        await show(ModeIntroductionPage(key: ValueKey(mode), mode: mode));
        expect(find.text('特色功能：'), findsOneWidget);
      }
      for (final kind in ['hotline', 'techniques', 'relax']) {
        await show(
          ResourcePage(key: ValueKey(kind), kind: kind, catalog: catalog),
        );
        final scroll = find.byType(ListView).first;
        for (var i = 0; i < 4; i++) {
          await tester.drag(scroll, const Offset(0, -350));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: kind);
        }
      }
      for (final code in ['BSRS5', 'RFQ8']) {
        final meta = catalog.scales.firstWhere((m) => m['code'] == code);
        await show(
          ScalePage(key: ValueKey(code), meta: meta, controller: controller),
        );
        expect(find.text('測驗前說明'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('開始測驗'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('開始測驗'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await show(
        CupertinoPageScaffold(
          child: SafeArea(
            child: DiaryPage(
              controller: controller,
              store: MemoryAccountStore(),
              initialDate: DateTime(2026, 11, 2),
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.byType(CupertinoTextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(CupertinoTextField), '僅在本機的畫面測試');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(writes, 0);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      auth.dispose();
    });
  }
  testWidgets('快速回覆只填入文字，不呼叫傳送 API；鍵盤出現仍可編輯', (tester) async {
    var writes = 0;
    final auth = AuthController(
      ApiClient(
        client: MockClient((r) async {
          final login = r.url.path == '/api/auth/login';
          if (!login && r.method != 'GET') writes++;
          return http.Response(
            jsonEncode(
              login
                  ? {
                      'token': 'test',
                      'user': {'id': 'u1'},
                    }
                  : {'messages': []},
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
      MemoryStore(),
    );
    await auth.login('test@example.com', 'test', remember: false);
    await tester.pumpWidget(
      CupertinoApp(
        theme: appTheme,
        home: ChatDetailPage(
          session: ChatSession(
            id: 's1',
            title: '畫面測試',
            mode: ChatMode.initial,
            createdAt: DateTime(2026, 11, 2),
          ),
          repository: ChatRepository(auth),
          content: testChatContent,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.plus_circle));
    await tester.pumpAndSettle();
    expect(find.text('快速回覆'), findsOneWidget);
    await tester.tap(find.text('我不知道從哪說起'));
    await tester.pumpAndSettle();
    expect(
      find.byType(CupertinoTextField).evaluate().single.widget
          is CupertinoTextField,
      isTrue,
    );
    expect(
      (tester.widget<CupertinoTextField>(find.byType(CupertinoTextField)))
          .controller!
          .text,
      '我不知道從哪說起',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(writes, 0);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
