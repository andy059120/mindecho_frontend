import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindecho_flutter/core/platform/local_media_store.dart';
import 'package:mindecho_flutter/core/storage/account_store.dart';
import 'package:path_provider/path_provider.dart';

import '../test/features/app_test.dart' as app_flow;
import '../test/features/android_navigation_test.dart' as navigation;
import '../test/features/android_forms_test.dart' as forms;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app_flow.main();
  navigation.main();
  forms.main();

  testWidgets('Android 加密草稿與媒體在重建 store 後可讀取，帳號互相隔離', (tester) async {
    final id = 'android-smoke-${DateTime.now().microsecondsSinceEpoch}';
    final store = KeychainAccountStore(id);
    final media = LocalMediaStore(id, store);
    final temp = File('${(await getTemporaryDirectory()).path}/$id.png');
    await temp.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      ),
    );
    try {
      await store.write('diary.draft.smoke', 'Android 測試草稿');
      final item = await media.importFile(temp.path, 'image');
      await media.save([item]);
      await media.setAvatar(temp.path);
      final restoredStore = KeychainAccountStore(id);
      final restored = LocalMediaStore(id, restoredStore);
      expect(await restoredStore.read('diary.draft.smoke'), 'Android 測試草稿');
      expect(await restored.load(), hasLength(1));
      expect(await restored.bytes(item.filename!), await temp.readAsBytes());
      expect(await restored.avatar(), await temp.readAsBytes());
      expect(
        await KeychainAccountStore('$id-other').read('diary.draft.smoke'),
        isNull,
      );
      await restored.removeFile(item.filename!);
      final avatar = await restoredStore.read('avatar');
      await restored.removeFile(avatar!);
    } finally {
      for (final key in ['diary.draft.smoke', 'treasure.v1', 'avatar']) {
        await store.write(key, null);
      }
      await temp.delete();
    }
  });
}
