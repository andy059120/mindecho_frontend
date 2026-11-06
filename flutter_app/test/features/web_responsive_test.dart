import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/main_shell.dart';
import 'package:mindecho_flutter/app/theme.dart';
import 'package:mindecho_flutter/core/platform/media_picker.dart';
import 'package:mindecho_flutter/features/auth/privacy_page.dart';
import 'package:mindecho_flutter/features/dashboard/widgets.dart';
import 'package:mindecho_flutter/features/dashboard/catalog.dart';
import 'package:mindecho_flutter/features/dashboard/home_page.dart';
import 'package:mindecho_flutter/shared/tab_tour_overlay.dart';

import '../support.dart';
import 'auth_ui_test.dart' show startApp;
import 'dashboard_test.dart' show signedIn, fixture, response;

void main() {
  if (!kIsWeb) return;

  for (final size in [
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    testWidgets('Web ${size.width}：歡迎、政策閱讀與返回無溢位', (tester) async {
      await startApp(tester, size: size);
      final policy = find.text('隱私政策').last;
      await tester.ensureVisible(policy);
      await tester.tap(policy);
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width >= 900) {
        expect(find.text('閱讀目錄'), findsOneWidget);
        await tester.tap(find.text('網頁版資料保存說明').first);
      } else {
        await tester.ensureVisible(find.text('網頁版資料保存說明'));
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('不儲存密碼。'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('網頁版資料保存說明').last).dy,
        lessThan(size.height),
      );
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.text('立即登入'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Web 調整視窗保留分頁狀態，側邊導覽、雙欄與功能介紹可操作', (tester) async {
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      printOnFailure(details.toString());
      reportError!(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = await signedIn(
      MockClient((r) async => response(fixture(r.url.path))),
    );
    final catalog = DashboardCatalog(
      quotes: testCatalog.quotes,
      scales: List.generate(
        9,
        (i) => {
          'title': '測試量表${i + 1}',
          'subtitle': '了解近期狀態',
          'icon': 'doc.text',
          'count': 20,
        },
      ),
      resources: testCatalog.resources,
      videos: testCatalog.videos,
    );
    await tester.pumpWidget(
      CupertinoApp(
        theme: appTheme,
        localizationsDelegates: const [
          ...GlobalCupertinoLocalizations.delegates,
          GlobalMaterialLocalizations.delegate,
        ],
        home: MainShell(
          auth: auth,
          content: testChatContent,
          catalog: catalog,
          store: MemoryAccountStore(),
          promptCheckIn: false,
          mediaPicker: MediaPicker(pendingStore: MemoryAccountStore()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(IndicatorCard)).dy,
      closeTo(tester.getTopLeft(find.byType(ScoresCard)).dy, 1),
    );
    expect(
      tester.getTopLeft(find.byType(ScoresCard)).dx,
      greaterThan(tester.getTopLeft(find.byType(IndicatorCard)).dx),
    );
    await tester.tap(find.text('功能介紹'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TabTourOverlay>(find.byType(TabTourOverlay)).sidebar,
      isTrue,
    );
    await tester.tap(find.text('略過'));
    await tester.pumpAndSettle();
    final homeScroll = find
        .descendant(
          of: find.byType(HomePage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('測試量表9'),
      400,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('測試量表9'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('測試量表9')).dy,
      greaterThan(tester.getTopLeft(find.text('測試量表1')).dy),
    );
    expect(tester.takeException(), isNull);
    for (final tab in ['聊天', '追蹤', '個人檔案']) {
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    for (final size in [
      const Size(768, 1024),
      const Size(320, 568),
      const Size(1440, 900),
      const Size(1024, 500),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('查看與編輯個人資訊'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('首頁').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('功能介紹'),
      -400,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('功能介紹'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
