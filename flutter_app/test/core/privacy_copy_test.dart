import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindecho_flutter/features/auth/privacy_consent.dart';

import '../privacy_fixture.dart';

void main() {
  test('Chrome 政策 fixture 與正式政策一致，附錄逐項確認與原文相同', () {
    final original = jsonDecode(
      File('assets/data/privacy_policy.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(jsonDecode(privacyPolicyFixture), original);
    final appendix = original['appendixSection'] as String;
    for (final statement in privacyConsentStatements) {
      expect(appendix, contains(statement));
    }
  });
}
