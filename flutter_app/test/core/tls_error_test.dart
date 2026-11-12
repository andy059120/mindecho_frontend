import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mindecho_flutter/core/network/api_client.dart';
import 'package:mindecho_flutter/features/auth/auth_controller.dart';

import '../support.dart';

void main() {
  test('TLS 握手失敗顯示安全連線提示，不建立登入 session', () async {
    final store = MemoryStore();
    final auth = AuthController(
      ApiClient(
        client: MockClient((_) async {
          throw const HandshakeException('CERTIFICATE_VERIFY_FAILED');
        }),
      ),
      store,
    );

    await expectLater(
      auth.login('user@example.com', 'password', remember: false),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '無法建立安全連線，伺服器憑證可能已過期或無效，請稍後再試',
        ),
      ),
    );
    expect(auth.session, isNull);
    expect(store.value, isNull);
  });
}
