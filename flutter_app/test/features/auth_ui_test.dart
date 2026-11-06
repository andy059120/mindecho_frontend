import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindecho_flutter/app/app.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';
import 'package:mindecho_flutter/features/auth/auth_widgets.dart';
import 'package:mindecho_flutter/features/auth/forgot_password_page.dart';

import '../support.dart';
import '../privacy_fixture.dart';

Future<AuthController> startApp(
  WidgetTester tester, {
  Size size = const Size(440, 956),
  double scale = 1,
}) async {
  const policyPath = 'assets/data/privacy_policy.json';
  final policyBytes = utf8.encode(privacyPolicyFixture);
  rootBundle.evict(policyPath);
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      final path = const StringCodec().decodeMessage(message);
      return path == policyPath ? ByteData.sublistView(policyBytes) : null;
    },
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthController(
    ApiClient(client: MockClient((_) async => http.Response('{}', 500))),
    MemoryStore(),
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: MindEchoApp(
        auth: auth,
        content: testChatContent,
        catalog: testCatalog,
        accountStore: MemoryAccountStore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('未登入先顯示四頁歡迎輪播，登入頁可關閉回原入口', (tester) async {
    await startApp(tester);
    expect(find.text('專業心理支持'), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsNothing);
    await tester.drag(find.byType(PageView), const Offset(-450, 0));
    await tester.pumpAndSettle();
    expect(find.text('24/7 隨時陪伴'), findsOneWidget);
    await tester.tap(find.text('立即登入'));
    await tester.pumpAndSettle();
    expect(find.text('忘記密碼？'), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(find.text('記住帳號'), findsOneWidget);
    await tester.tap(find.byType(AuthClose));
    await tester.pumpAndSettle();
    expect(find.text('24/7 隨時陪伴'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('註冊需完成基本驗證才可前往個人資料，返回不遺失輸入', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('建立新帳號'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(CupertinoButton, '下一步');
    expect(tester.widget<CupertinoButton>(button).onPressed, isNull);
    await tester.enterText(
      find.byType(CupertinoTextField).at(0),
      'test@example.com',
    );
    await tester.enterText(
      find.byType(CupertinoTextField).at(1),
      'password123',
    );
    await tester.enterText(
      find.byType(CupertinoTextField).at(2),
      'password123',
    );
    await tester.pump();
    expect(tester.widget<CupertinoButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('個人信息'), findsOneWidget);
    expect(find.text('緊急聯絡人'), findsOneWidget);
    // 六項聲明各自切換，預設皆未同意，且返回上一步仍保留選擇。
    Finder consent(int i) => find.byKey(ValueKey('privacy-consent-$i'));
    bool checked(int i) => tester
        .widget<Semantics>(
          find.ancestor(of: consent(i), matching: find.byType(Semantics)).first,
        )
        .properties
        .checked!;
    for (var i = 0; i < 6; i++) {
      await tester.ensureVisible(consent(i));
      expect(checked(i), isFalse);
      await tester.tap(consent(i));
      await tester.pump();
      expect(checked(i), isTrue);
    }
    await tester.ensureVisible(consent(0));
    await tester.tap(consent(0));
    await tester.pump();
    expect(checked(0), isFalse);
    for (var i = 1; i < 6; i++) {
      expect(checked(i), isTrue);
    }
    final policy = find.text('查看隱私權保護政策與使用聲明');
    await tester.ensureVisible(policy);
    await tester.tap(policy);
    await tester.pumpAndSettle();
    expect(find.text('隱私政策與聲明'), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(checked(0), isFalse);
    expect(checked(5), isTrue);
    final back = find.text('返回上一步');
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('test@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('忘記密碼先驗證資料並可返回登入，不送出重設請求', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('立即登入'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('忘記密碼？'));
    await tester.tap(find.text('忘記密碼？'));
    await tester.pumpAndSettle();
    final next = find.widgetWithText(CupertinoButton, '下一步');
    expect(tester.widget<CupertinoButton>(next).onPressed, isNull);
    final resetFields = find.descendant(
      of: find.byType(ForgotPasswordPage),
      matching: find.byType(CupertinoTextField),
    );
    await tester.enterText(resetFields.at(0), '測試');
    await tester.enterText(resetFields.at(1), 'test@example.com');
    await tester.pump();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('設定新密碼'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoButton>(find.widgetWithText(CupertinoButton, '完成重設'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('歡迎回來'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('隱私政策入口可閱讀更新後完整內容並關閉', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('隱私政策'));
    await tester.pumpAndSettle();
    expect(find.text('一、前言'), findsOneWidget);
    final appendix = find.text('附錄 A：使用聲明（簡要重點）');
    await tester.scrollUntilVisible(
      appendix,
      500,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 50,
    );
    expect(appendix, findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.text('立即登入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(402, 874),
    const Size(440, 956),
  ]) {
    testWidgets('歡迎與登入在 ${size.width}x${size.height} 無版面溢位', (tester) async {
      await startApp(tester, size: size);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('立即登入'));
      await tester.tap(find.text('立即登入'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(CupertinoTextField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    });
  }
}
