import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindecho_flutter/core/platform/media_files_web.dart' as web;

import '../support.dart';

void main() {
  test('網頁媒體可跨 store adapter 重讀、刪除且不影響其他帳號', () async {
    final first = MemoryAccountStore();
    final second = MemoryAccountStore();
    final data = Uint8List.fromList([0, 1, 128, 255]);
    await web.writeMedia('a', first, 'test.mp4', data);
    expect(await web.readMedia('a', first, 'test.mp4'), data);
    expect(await web.readMedia('b', second, 'test.mp4'), isNull);
    expect(await web.mediaPath('a', first, 'test.mp4'), equals('data:application/octet-stream;base64,AAGA/w=='));
    await web.deleteMedia('a', first, 'test.mp4');
    expect(await web.readMedia('a', first, 'test.mp4'), isNull);
    await expectLater(web.mediaPath('a', first, 'test.mp4'), throwsFormatException);
  });
}
