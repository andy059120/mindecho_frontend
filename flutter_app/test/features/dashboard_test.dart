import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/main_shell.dart';
import 'package:mindecho_flutter/app/theme.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';
import 'package:mindecho_flutter/features/check_in/check_in_page.dart';
import 'package:mindecho_flutter/features/dashboard/catalog.dart';
import 'package:mindecho_flutter/features/dashboard/controller.dart';
import 'package:mindecho_flutter/features/dashboard/models.dart';
import 'package:mindecho_flutter/features/dashboard/repository.dart';
import 'package:mindecho_flutter/features/dashboard/widgets.dart';
import 'package:mindecho_flutter/features/diary/diary_page.dart';
import 'package:mindecho_flutter/features/scales/scale_page.dart';

import '../support.dart';

Future<AuthController> signedIn(http.Client client) async {
  final auth = AuthController(ApiClient(client: client), MemoryStore());
  await auth.login('test@example.com', 'test', remember: false);
  return auth;
}

http.Response response(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Object fixture(String path) => switch (path) {
  '/api/auth/login' => {
    'token': 'test-token',
    'user': {'id': 'u1', 'email': 'test@example.com'},
  },
  '/api/main/dailyQuestions' => {'dailyQuestions': []},
  '/api/diaries' => {'entries': []},
  '/api/main/scales/sessions' => {'scales': []},
  '/api/chat/sessions' => {'sessions': []},
  '/api/user/profile' => {
    'user': {'id': 'u1', 'email': 'test@example.com', 'firstName': '測試'},
  },
  _ => {},
};
void main() {
  test('每日檢測沿用 Swift 欄位題序，失敗不改本機完成狀態', () async {
    Map<String, dynamic>? sent;
    var fail = true;
    final auth = await signedIn(
      MockClient((r) async {
        if (r.method == 'POST' && r.url.path.endsWith('/dailyQuestions')) {
          sent = jsonDecode(r.body) as Map<String, dynamic>;
          return response({'message': '測試拒絕'}, fail ? 500 : 200);
        }
        return response(fixture(r.url.path));
      }),
    );
    final controller = DashboardController(DashboardRepository(auth));
    await expectLater(
      controller.submitCheckIn([1, 2, 3, 4, 5]),
      throwsA(isA<ApiException>()),
    );
    expect(controller.completedToday, isFalse);
    expect(sent, {
      'userId': 'u1',
      'physical': 1,
      'mental': 2,
      'emotion': 3,
      'sleep': 4,
      'diet': 5,
      'entryDate': dayKey(DateTime.now()),
    });
    fail = false;
    await controller.submitCheckIn([1, 2, 3, 4, 5]);
    expect(controller.completedToday, isTrue);
    controller.dispose();
    auth.dispose();
  });
  test('更新日記失敗不刪原紀錄，也不改成本機成功', () async {
    final methods = <String>[];
    final auth = await signedIn(
      MockClient((r) async {
        if (r.url.path.endsWith('/diaries/existing')) {
          methods.add(r.method);
          return response({'message': '不支援更新'}, 405);
        }
        return response(fixture(r.url.path));
      }),
    );
    final controller = DashboardController(DashboardRepository(auth));
    final original = DiaryEntry(
      id: 'existing',
      content: '原日記',
      mood: 'OKAY',
      date: DateTime(2026, 11, 2),
    );
    controller.diaryEntries = [original];
    await expectLater(
      controller.saveDiary(
        id: 'existing',
        content: '修改',
        mood: 'GOOD',
        date: original.date,
      ),
      throwsA(isA<ApiException>()),
    );
    expect(methods, ['PATCH']);
    expect(controller.diaryEntries.single.content, '原日記');
    controller.dispose();
    auth.dispose();
  });
  test('缺少趨勢資料不補成 0；跨月、跨年時間分組正確', () {
    final date = DateTime(2026, 1, 3);
    final record = DailyRecord(DateTime(2025, 12, 31), {
      for (final i in indicators) i.key: 4,
    });
    final series = aggregateTrends([record], '本週', date);
    expect(series.first.values, [null, null, null, 4, null, null, null]);
    expect(trendStarts('最近七月', date).first, DateTime(2025, 7));
    expect(DailyRecord.normalize(80), 4);
    expect(DailyRecord.normalize(81), 5);
  });
  testWidgets('原 Swift 的 9 份量表與題數、反向計分載入正確', (tester) async {
    final catalog = (await tester.runAsync(DashboardCatalog.load))!;
    expect(catalog.quotes.length, 40);
    expect(catalog.scales.map((m) => m['count']), [
      20,
      5,
      8,
      12,
      25,
      14,
      21,
      8,
      10,
    ]);
    for (final meta in catalog.scales) {
      expect((meta['questions'] as List).length, meta['count']);
      final ids = (meta['questions'] as List).map((q) => q['id']).toSet();
      expect(ids.length, meta['count']);
    }
    final bsrs = catalog.scales.firstWhere((m) => m['code'] == 'BSRS5');
    expect(scaleTotal(bsrs, List.filled(5, 4)), 20);
    final bss = catalog.scales.firstWhere((m) => m['code'] == 'BSS21');
    expect(scaleTotal(bss, List.filled(21, 2)), 38);
    expect(rfqScores(List.filled(8, 0)), (0, 15));
    expect(rfqScores(List.filled(8, 6)), (18, 3));
  });
  testWidgets('晚到的日記資料載入編輯器；草稿保留且更新使用既有 ID', (tester) async {
    final methods = <String>[];
    final auth = await signedIn(
      MockClient((r) async {
        if (r.method == 'PATCH') {
          methods.add(r.url.path);
          return response({'message': '更新失敗'}, 500);
        }
        return response(fixture(r.url.path));
      }),
    );
    final controller = DashboardController(DashboardRepository(auth));
    final store = MemoryAccountStore();
    final date = DateTime(2026, 11, 2);
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => ListView(
                children: [
                  DiaryEditor(controller: controller, store: store, date: date),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.diaryEntries = [
      DiaryEntry(id: 'existing', content: '伺服器日記', mood: 'GOOD', date: date),
    ];
    // 模擬資料載入完成的通知。
    await controller.loadMetrics();
    await tester.pumpAndSettle();
    expect(find.text('伺服器日記'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextField), '未儲存修改');
    await tester.ensureVisible(find.text('儲存'));
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();
    expect(methods, ['/api/diaries/existing']);
    expect(store.values['diary.draft.2026-11-02'], contains('未儲存修改'));
    expect(controller.diaryEntries.single.content, '伺服器日記');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    auth.dispose();
  });
  for (final size in [const Size(320, 568), const Size(440, 956)]) {
    testWidgets('每日檢測 ${size.width}：送出失敗保留答案，重試成功才顯示結果', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var fail = true;
      var posts = 0;
      final auth = await signedIn(
        MockClient((r) async {
          if (r.method == 'POST' && r.url.path.endsWith('/dailyQuestions')) {
            posts++;
            return response({'message': '暫時失敗'}, fail ? 500 : 200);
          }
          return response(fixture(r.url.path));
        }),
      );
      final controller = DashboardController(DashboardRepository(auth));
      await tester.pumpWidget(
        CupertinoApp(
          theme: appTheme,
          home: CheckInPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('開始檢測'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        expect(find.text('問題${i + 1}/5'), findsOneWidget);
        await tester.ensureVisible(find.text('極佳'));
        await tester.tap(find.text('極佳'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(posts, 1);
      expect(find.text('今日檢測完成！'), findsNothing);
      expect(controller.completedToday, isFalse);
      fail = false;
      await tester.ensureVisible(find.text('重新送出'));
      await tester.tap(find.text('重新送出'));
      await tester.pumpAndSettle();
      expect(posts, 2);
      expect(find.text('今日檢測完成！'), findsOneWidget);
      expect(controller.completedToday, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      auth.dispose();
    });
  }
  for (final size in [
    const Size(320, 568),
    const Size(402, 874),
    const Size(440, 956),
  ]) {
    testWidgets('四個分頁在 ${size.width}x${size.height} 切換無溢位', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = await signedIn(
        MockClient((r) async => response(fixture(r.url.path))),
      );
      final catalog = (await tester.runAsync(DashboardCatalog.load))!;
      await tester.pumpWidget(
        CupertinoApp(
          theme: appTheme,
          home: MainShell(
            promptCheckIn: false,
            auth: auth,
            content: testChatContent,
            catalog: catalog,
            store: MemoryAccountStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('功能介紹'));
      await tester.pumpAndSettle();
      expect(find.text('略過'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('下一步'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.text('略過'), findsNothing);
      expect(find.text('功能介紹'), findsOneWidget);
      for (final tab in ['聊天', '追蹤', '個人檔案', '首頁']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      final scroll = find
          .descendant(
            of: find.byType(MainShell),
            matching: find.byType(CustomScrollView),
          )
          .first;
      for (var i = 0; i < 6; i++) {
        await tester.drag(scroll, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '首頁捲動 $i');
      }
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    });
  }
}
