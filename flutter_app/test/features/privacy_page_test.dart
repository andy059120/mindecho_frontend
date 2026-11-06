import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../privacy_fixture.dart';
import 'auth_ui_test.dart' show startApp;

void main() {
  testWidgets('政策載入失敗後可重試，大字與短視窗仍可閱讀', (tester) async {
    await startApp(tester, size: const Size(320, 568), scale: 1.5);
    var fail = true;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final path = const StringCodec().decodeMessage(message);
        return path == 'assets/data/privacy_policy.json' && !fail
            ? ByteData.sublistView(utf8.encode(privacyPolicyFixture))
            : null;
      },
    );
    final policy = find.text('隱私政策');
    await tester.ensureVisible(policy);
    await tester.tap(policy);
    await tester.pumpAndSettle();
    expect(find.text('無法載入隱私政策，請稍後再試'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('重試'));
    await tester.pumpAndSettle();
    expect(find.text('一、前言'), findsOneWidget);
    await tester.ensureVisible(find.text('附錄 A：使用聲明（簡要重點）'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
  });
}
