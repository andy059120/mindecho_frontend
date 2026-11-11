import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/main_shell.dart';
import 'package:mindecho_flutter/app/theme.dart';
import 'package:mindecho_flutter/core/platform/media_picker.dart';
import 'package:mindecho_flutter/features/chat/chat_detail_page.dart';
import 'package:mindecho_flutter/features/chat/chat_models.dart';
import 'package:mindecho_flutter/features/chat/chat_repository.dart';
import 'package:mindecho_flutter/features/dashboard/widgets.dart';
import 'package:mindecho_flutter/shared/tab_tour_overlay.dart';

import '../support.dart';
import 'auth_ui_test.dart' show startApp;
import 'dashboard_test.dart' as fixtures;

void main() {
  for (final size in [
    const Size(1032, 1376),
    const Size(1376, 1032),
    const Size(744, 1133),
    const Size(507, 1032),
  ]) {
    testWidgets('原生 iPad $size：登入表單限制寬度，鍵盤不遮住內容', (tester) async {
      final auth = await startApp(tester, size: size);
      expect(find.text('心理健康的智慧夥伴'), findsOneWidget);
      await tester.tap(find.text('立即登入').last);
      await tester.pumpAndSettle();
      final fields = find.byType(CupertinoTextField);
      expect(tester.getSize(fields.first).width, lessThanOrEqualTo(560));
      await tester.enterText(fields.first, 'tablet@example.com');
      tester.view.viewInsets = const FakeViewPadding(bottom: 380);
      await tester.pumpAndSettle();
      await tester.ensureVisible(fields.last);
      expect(tester.getBottomLeft(fields.last).dy, lessThan(size.height - 380));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets('iPad 旋轉及分割視窗保留聊天室路由、未送出文字與分頁', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1376, 1032);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    final auth = await fixtures.signedIn(
      MockClient(
        (r) async => fixtures.response(
          r.url.path.endsWith("/messages")
              ? {"messages": []}
              : fixtures.fixture(r.url.path),
        ),
      ),
    );
    await tester.pumpWidget(
      CupertinoApp(
        theme: appTheme,
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
    expect(
      tester.getTopLeft(find.byType(IndicatorCard)).dy,
      lessThan(tester.getTopLeft(find.byType(ScoresCard)).dy),
    );
    expect(
      tester.getSize(find.byType(IndicatorCard)).width,
      greaterThan(1376 * .85),
    );
    await tester.tap(find.text('功能介紹'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TabTourOverlay>(find.byType(TabTourOverlay)).sidebar,
      isFalse,
    );
    await tester.tap(find.text('略過'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('首頁').last).dy, greaterThan(900));
    expect(
      tester.getCenter(find.text('個人檔案').last).dx -
          tester.getCenter(find.text('首頁').last).dx,
      lessThan(760),
    );
    await tester.tap(find.text('聊天').first);
    await tester.pumpAndSettle();
    final tabs = tester
        .widgetList<CupertinoTabView>(
          find.byType(CupertinoTabView, skipOffstage: false),
        )
        .toList();
    tabs[1].navigatorKey!.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => ChatDetailPage(
          session: const ChatSession(
            id: 'tablet',
            title: '平板對話',
            mode: ChatMode.initial,
            createdAt: null,
          ),
          repository: ChatRepository(auth),
          content: testChatContent,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), '旋轉後仍保留的文字');
    for (final size in [
      const Size(1032, 1376),
      const Size(744, 1133),
      const Size(507, 1032),
      const Size(320, 568),
      const Size(1376, 1032),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('平板對話'), findsOneWidget);
      expect(find.text('旋轉後仍保留的文字'), findsOneWidget);
      expect(
        tester.getSize(find.byType(CupertinoTextField)).width,
        lessThanOrEqualTo(860),
      );
      expect(tester.takeException(), isNull);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    for (final tab in ['追蹤', '個人檔案', '首頁']) {
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    for (final width in [1032.0, 900.0, 744.0, 507.0, 1376.0]) {
      tester.view.physicalSize = Size(width, 1032);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(IndicatorCard)).width,
        greaterThan(width * .85),
      );
      expect(
        tester.getTopLeft(find.byType(IndicatorCard)).dy,
        lessThan(tester.getTopLeft(find.byType(ScoresCard)).dy),
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
