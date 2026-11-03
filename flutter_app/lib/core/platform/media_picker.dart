import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../storage/account_store.dart';
import 'local_media_store.dart';

/// 先保存帳號與用途，避免 Activity 重建後把選取結果匯入錯誤帳號。
class MediaPicker {
  MediaPicker({ImagePicker? picker, AccountStore? pendingStore})
    : picker = picker ?? ImagePicker(),
      pendingStore = pendingStore ?? KeychainAccountStore('__media_picker__');

  final ImagePicker picker;
  final AccountStore pendingStore;
  static const _key = 'pending.v1';
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> pick(
    LocalMediaStore media,
    String purpose, {
    ImageSource source = ImageSource.gallery,
  }) async {
    final operation = <String, dynamic>{
      'account': media.accountId,
      'purpose': purpose,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
    };
    if (_android) {
      if (await pendingStore.read(_key) != null) {
        throw const FormatException('尚有未完成的媒體匯入，請先以原帳號重新啟動 App 完成恢復');
      }
      await pendingStore.write(_key, jsonEncode(operation));
    }
    XFile? file;
    try {
      file = purpose == 'video'
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(
              source: source,
              maxWidth: purpose == 'avatar' ? 1024 : null,
              maxHeight: purpose == 'avatar' ? 1024 : null,
              imageQuality: purpose == 'avatar' ? 90 : null,
            );
    } catch (_) {
      if (_android) await pendingStore.write(_key, null);
      rethrow;
    }
    if (file != null) {
      operation['path'] = file.path;
      if (_android) await pendingStore.write(_key, jsonEncode(operation));
      await _import(media, operation);
    }
    if (_android) await pendingStore.write(_key, null);
  }

  Future<void> recover(LocalMediaStore media) async {
    if (!_android) return;
    final raw = await pendingStore.read(_key);
    if (raw == null) return;
    final operation = jsonDecode(raw) as Map<String, dynamic>;
    if (operation['account'] != media.accountId) return;
    if (operation['path'] == null) {
      final lost = await picker.retrieveLostData();
      if (lost.exception != null) {
        await pendingStore.write(_key, null);
        throw lost.exception!;
      }
      if (lost.files?.isNotEmpty != true) {
        await pendingStore.write(_key, null);
        return;
      }
      operation['path'] = lost.files!.first.path;
      // retrieveLostData 會消耗結果；先保存路徑，寫入失敗時仍可重試。
      await pendingStore.write(_key, jsonEncode(operation));
    }
    await _import(media, operation);
    await pendingStore.write(_key, null);
  }

  Future<void> _import(
    LocalMediaStore media,
    Map<String, dynamic> operation,
  ) async {
    final path = operation['path'] as String;
    final id = operation['id'] as String;
    final purpose = operation['purpose'] as String;
    if (purpose == 'avatar') {
      await media.setAvatar(path, operationId: id);
    } else {
      final items = await media.load();
      if (items.any((item) => item.id == id)) return;
      final item = await media.importFile(path, purpose, operationId: id);
      await media.save([...items, item]);
    }
  }
}
