import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindecho_flutter/core/platform/local_media_store.dart';
import 'package:mindecho_flutter/core/platform/media_picker.dart';
import 'package:mindecho_flutter/core/storage/account_store.dart';
import 'package:path_provider/path_provider.dart';

/// seed 後由測試操作者將 App 移至背景並終止程序，再以 restore 啟動。
/// 使用獨立本機測試帳號，不操作真實後端。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android 程序重啟後恢復草稿、收藏與未完成的媒體匯入', (tester) async {
    const phase = String.fromEnvironment('RESTART_PHASE', defaultValue: 'seed');
    final store = KeychainAccountStore('__android_restart_test__');
    final media = LocalMediaStore('__android_restart_test__', store);
    final pending = KeychainAccountStore('__android_restart_picker_test__');
    if (phase == 'seed') {
      await store.write('diary.draft.test', '程序重啟草稿');
      final temp = File(
        '${(await getTemporaryDirectory()).path}/restart-test.png',
      );
      await temp.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
        ),
      );
      final item = await media.importFile(temp.path, 'image');
      await media.save([item]);
      await pending.write(
        'pending.v1',
        jsonEncode({
          'account': media.accountId,
          'purpose': 'image',
          'id': 'interrupted-import',
          'path': temp.path,
        }),
      );
    } else {
      expect(await store.read('diary.draft.test'), '程序重啟草稿');
      expect(await media.load(), hasLength(1));
      await MediaPicker(pendingStore: pending).recover(media);
      final items = await media.load();
      expect(items, hasLength(2));
      expect(items.any((item) => item.id == 'interrupted-import'), isTrue);
      for (final item in items) {
        expect(await media.bytes(item.filename!), isNotEmpty);
        await media.removeFile(item.filename!);
      }
      expect(await pending.read('pending.v1'), isNull);
      await store.write('diary.draft.test', null);
      await store.write('treasure.v1', null);
    }
  });
}
