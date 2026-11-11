import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/main_shell.dart';
import 'package:mindecho_flutter/app/theme.dart';
import 'package:mindecho_flutter/core/platform/media_picker.dart';
import 'package:mindecho_flutter/features/dashboard/catalog.dart';
import 'package:mindecho_flutter/features/dashboard/home_page.dart';

import '../support.dart';
import 'dashboard_test.dart' as fixtures;

void main() {
  for (final size in [
    const Size(507, 1032),
    const Size(900, 700),
    const Size(1032, 1376),
  ]) {
    testWidgets('平板 $size 大字體：完整卡片與長箴言可捲動，不裁切', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = (await tester.runAsync(DashboardCatalog.load))!;
      final longQuote = List.filled(15, '讓自己慢下來，溫柔地照顧今天的感受。').join();
      final catalog = DashboardCatalog(
        quotes: [
          {'title': '給自己的話', 'content': longQuote},
        ],
        scales: source.scales,
        resources: source.resources,
        videos: source.videos,
      );
      final auth = await fixtures.signedIn(
        MockClient(
          (r) async => fixtures.response(fixtures.fixture(r.url.path)),
        ),
      );
      await tester.pumpWidget(
        CupertinoApp(
          theme: appTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: MainShell(
            auth: auth,
            content: testChatContent,
            catalog: catalog,
            store: MemoryAccountStore(),
            mediaPicker: MediaPicker(pendingStore: MemoryAccountStore()),
            promptCheckIn: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(QuoteCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(QuoteCard));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text(longQuote));
      expect(text.maxLines, isNull);
      final homeScroll = find
          .descendant(
            of: find.byType(HomePage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('求助資源'),
        400,
        scrollable: homeScroll,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('儲存日記'),
        300,
        scrollable: homeScroll,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('聊天').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('個人檔案').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }
}
