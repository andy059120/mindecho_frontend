import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mindecho_flutter/features/dashboard/catalog.dart';
import 'package:mindecho_flutter/features/dashboard/controller.dart';
import 'package:mindecho_flutter/features/dashboard/repository.dart';
import 'package:mindecho_flutter/features/diary/diary_page.dart';
import 'package:mindecho_flutter/features/scales/scale_page.dart';

import '../support.dart';
import 'dashboard_test.dart' as fixtures;

void main() {
  testWidgets('日記新增成功後清除草稿並保留伺服器紀錄', (tester) async {
    Map<String, dynamic>? sent;
    final auth = await fixtures.signedIn(
      MockClient((r) async {
        if (r.method == 'POST' && r.url.path.endsWith('/diaries')) {
          sent = jsonDecode(r.body) as Map<String, dynamic>;
          return fixtures.response({
            'entry': {'id': 'new-diary', ...sent!},
          });
        }
        return fixtures.response(fixtures.fixture(r.url.path));
      }),
    );
    final controller = DashboardController(DashboardRepository(auth));
    final store = MemoryAccountStore();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: ListView(
              children: [
                DiaryEditor(
                  controller: controller,
                  store: store,
                  date: DateTime(2026, 11, 2),
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'Android 測試日記');
    await tester.ensureVisible(find.text('儲存日記'));
    await tester.tap(find.text('儲存日記'));
    await tester.pumpAndSettle();
    expect(sent!['content'], 'Android 測試日記');
    expect(controller.diaryEntries.single.id, 'new-diary');
    expect(await store.read('diary.draft.2026-11-02'), isNull);
    expect(find.text('日記已儲存'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    auth.dispose();
  });

  testWidgets('量表完整作答、失敗保留答案、重試成功才顯示結果', (tester) async {
    var fail = true;
    final posts = <Map<String, dynamic>>[];
    final auth = await fixtures.signedIn(
      MockClient((r) async {
        if (r.method == 'POST' && r.url.path.endsWith('/BSRS5/answers')) {
          posts.add(jsonDecode(r.body) as Map<String, dynamic>);
          return fixtures.response({'message': 'test'}, fail ? 500 : 200);
        }
        return fixtures.response(fixtures.fixture(r.url.path));
      }),
    );
    final catalog = (await tester.runAsync(DashboardCatalog.load))!;
    final meta = catalog.scales.firstWhere((s) => s['code'] == 'BSRS5');
    final controller = DashboardController(DashboardRepository(auth));
    await tester.pumpWidget(
      CupertinoApp(
        home: ScalePage(meta: meta, controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('開始測驗'), 300);
    await tester.tap(find.text('開始測驗'));
    await tester.pumpAndSettle();
    final option = (meta['options'] as List).first as Map<String, dynamic>;
    for (var i = 0; i < 5; i++) {
      await tester.ensureVisible(find.text(option['label'] as String));
      await tester.tap(find.text(option['label'] as String));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      find.widgetWithText(CupertinoButton, '確認送出'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoButton, '確認送出'));
    await tester.pumpAndSettle();
    expect(find.textContaining('送出失敗，答案仍保留'), findsOneWidget);
    expect(posts.single['answers'], hasLength(5));
    fail = false;
    await tester.ensureVisible(find.widgetWithText(CupertinoButton, '確認送出'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoButton, '確認送出'));
    await tester.pumpAndSettle();
    expect(posts, hasLength(2));
    expect(posts[0], posts[1]);
    await tester.scrollUntilVisible(find.text('量表完成'), -300);
    expect(find.text('量表完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    auth.dispose();
  });
}
