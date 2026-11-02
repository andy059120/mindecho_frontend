import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/theme.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';
import 'package:mindecho_flutter/features/dashboard/controller.dart';
import 'package:mindecho_flutter/features/dashboard/widgets.dart';
import 'package:mindecho_flutter/features/dashboard/models.dart';
import 'package:mindecho_flutter/features/dashboard/repository.dart';
import 'package:mindecho_flutter/features/diary/diary_page.dart';
import 'package:mindecho_flutter/features/profile/profile_page.dart';
import 'package:mindecho_flutter/shared/swift_menu_button.dart';

import '../support.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(402, 874),
    const Size(440, 956),
  ]) {
    testWidgets('浮動選單 ${size.width}：完整清單可捲動、選取及取消，邊界不溢位', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final options = List.generate(20, (i) => '選項 ${i + 1}');
      String? selected;
      await tester.pumpWidget(
        CupertinoApp(
          theme: appTheme,
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SwiftMenuButton(
                        label: '本週',
                        accessibilityLabel: '時間週期',
                        options: options,
                        onSelected: (v) => selected = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('時間週期，本週'), findsOneWidget);
      await tester.tap(find.text('本週'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsNothing);
      final bounds = tester.getRect(find.byType(ListView));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.bottom, lessThanOrEqualTo(size.height));
      await tester.scrollUntilVisible(find.text('選項 20'), 160);
      await tester.pumpAndSettle();
      await tester.tap(find.text('選項 20'));
      await tester.pumpAndSettle();
      expect(selected, '選項 20');
      expect(find.byType(ListView), findsNothing);
      await tester.tap(find.text('本週'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(selected, '選項 20');
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('個人資訊 ${size.width}：頭像卡片、出生年月、編輯與鍵盤，不送出資料', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var writes = 0, avatarRequests = 0;
      final auth = AuthController(
        ApiClient(
          client: MockClient((r) async {
            if (r.url.path != '/api/auth/login' && r.method != 'GET') writes++;
            return http.Response(
              jsonEncode({
                'token': 'test',
                'user': {
                  'id': 'u1',
                  'lastName': '陳',
                  'firstName': '小安',
                  'email': 'test@example.com',
                  'birthYear': 2002,
                  'birthMonth': 3,
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
        MemoryStore(),
      );
      await auth.login('test@example.com', 'test', remember: false);
      final controller = DashboardController(DashboardRepository(auth));
      await tester.pumpWidget(
        CupertinoApp(
          theme: appTheme,
          home: PersonalInfoPage(
            controller: controller,
            onAvatarTap: () async {
              avatarRequests++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('更換頭貼'), findsOneWidget);
      expect(find.text('2002-03'), findsOneWidget);
      await tester.tap(find.text('小陳'));
      await tester.pumpAndSettle();
      expect(avatarRequests, 1);
      await tester.scrollUntilVisible(
        find.text('編輯個人資訊'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('編輯個人資訊'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoTextFormFieldRow), findsNWidgets(2));
      expect(find.text('出生年月'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(CupertinoTextField).last, '尚未送出的姓名');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(writes, 0);
      expect(controller.user['firstName'], '小安');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      auth.dispose();
    });
  }
  testWidgets('圖表在窄螢幕切換單一指標與時間週期，保留資料且不溢位', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final records = List.generate(
      3,
      (i) => DailyRecord(DateTime.now().subtract(Duration(days: i)), {
        for (final indicator in indicators) indicator.key: i * 2 + 1,
      }),
    );
    await tester.pumpWidget(
      CupertinoApp(
        theme: appTheme,
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: ListView(children: [IndicatorCard(records: records)]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('選擇指標，全部'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生理').last);
    await tester.pumpAndSettle();
    expect(find.text('可從右上角切換回全部或改看其他指標'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('時間週期，本週'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('最近三年半'));
    await tester.pumpAndSettle();
    expect(find.text('暫無數據'), findsNothing);
    expect(records.length, 3);
    expect(records.first.values['physical'], 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('月曆跨月份與閏年，月份選擇只切換顯示，點日期才更改選取', (tester) async {
    DateTime? chosen;
    await tester.pumpWidget(
      CupertinoApp(
        theme: appTheme,
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: SingleChildScrollView(
              child: CalendarMonth(
                selected: DateTime(2028, 2, 29),
                entries: const [],
                onSelected: (v) => chosen = v,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('29'), findsOneWidget);
    expect(find.text('30'), findsNothing);
    await tester.tap(find.bySemanticsLabel('下一個月'));
    await tester.pumpAndSettle();
    expect(find.text('2028年3月'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(chosen, isNull);
    await tester.tap(find.bySemanticsLabel('上一個月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2028年2月'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(chosen, isNull);
    await tester.tap(find.text('2028年2月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('28'));
    await tester.pumpAndSettle();
    expect(chosen, DateTime(2028, 2, 28));
    expect(tester.takeException(), isNull);
  });
}
