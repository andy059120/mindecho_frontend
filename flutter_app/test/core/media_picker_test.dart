import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindecho_flutter/core/platform/local_media_store.dart';
import 'package:mindecho_flutter/core/platform/media_picker.dart';

import '../support.dart';

class LostPicker extends ImagePicker {
  int calls = 0;
  @override
  Future<LostDataResponse> retrieveLostData() async {
    calls++;
    return LostDataResponse(files: [XFile('/test/image.jpg')]);
  }
}

class RecoveredMedia extends LocalMediaStore {
  RecoveredMedia(String account) : super(account, MemoryAccountStore());
  bool fail = false;
  String? avatarPath;
  @override
  Future<LocalItem> importFile(
    String source,
    String kind, {
    String? operationId,
  }) async {
    if (fail) throw StateError('disk full');
    return LocalItem(
      id: operationId!,
      kind: kind,
      title: kind,
      detail: '',
      date: DateTime(2026),
      filename: source,
    );
  }

  @override
  Future<void> setAvatar(String source, {String? operationId}) async {
    avatarPath = source;
  }
}

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final purpose in ['image', 'video', 'avatar']) {
    test('背景回收後恢復 $purpose 至原帳號與原用途', () async {
      final pending = MemoryAccountStore();
      await pending.write(
        'pending.v1',
        jsonEncode({'account': 'u1', 'purpose': purpose, 'id': 'op1'}),
      );
      final media = RecoveredMedia('u1');
      final picker = LostPicker();
      await MediaPicker(picker: picker, pendingStore: pending).recover(media);
      expect(picker.calls, 1);
      if (purpose == 'avatar') {
        expect(media.avatarPath, '/test/image.jpg');
      } else {
        expect((await media.load()).single.kind, purpose);
      }
      expect(await pending.read('pending.v1'), isNull);
    });
  }

  test('不將原帳號的媒體結果交給另一帳號', () async {
    final pending = MemoryAccountStore();
    await pending.write(
      'pending.v1',
      jsonEncode({'account': 'u1', 'purpose': 'image', 'id': 'op1'}),
    );
    final picker = LostPicker();
    final media = RecoveredMedia('u2');
    await MediaPicker(picker: picker, pendingStore: pending).recover(media);
    expect(picker.calls, 0);
    expect(await media.load(), isEmpty);
    expect(await pending.read('pending.v1'), isNotNull);
  });

  test('匯入失敗後保留已消耗的選取結果，重試不重複新增', () async {
    final pending = MemoryAccountStore();
    await pending.write(
      'pending.v1',
      jsonEncode({'account': 'u1', 'purpose': 'image', 'id': 'op1'}),
    );
    final picker = LostPicker();
    final media = RecoveredMedia('u1')..fail = true;
    final service = MediaPicker(picker: picker, pendingStore: pending);
    await expectLater(service.recover(media), throwsStateError);
    expect(
      jsonDecode((await pending.read('pending.v1'))!)['path'],
      '/test/image.jpg',
    );
    media.fail = false;
    await service.recover(media);
    expect(picker.calls, 1);
    expect((await media.load()).length, 1);
    await pending.write(
      'pending.v1',
      jsonEncode({
        'account': 'u1',
        'purpose': 'image',
        'id': 'op1',
        'path': '/test/image.jpg',
      }),
    );
    await service.recover(media);
    expect((await media.load()).length, 1);
  });
}
