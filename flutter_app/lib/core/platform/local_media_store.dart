import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'media_files_io.dart'
    if (dart.library.js_interop) 'media_files_web.dart' as files;

import '../storage/account_store.dart';

class LocalItem {
  const LocalItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.date,
    this.filename,
  });
  final String id, kind, title, detail;
  final DateTime date;
  final String? filename;
  factory LocalItem.fromJson(Map<String, dynamic> json) => LocalItem(
    id: json['id'] as String,
    kind: json['kind'] as String,
    title: json['title'] as String,
    detail: json['detail'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
    filename: json['filename'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'title': title,
    'detail': detail,
    'date': date.toIso8601String(),
    'filename': filename,
  };
}

class LocalMediaStore {
  LocalMediaStore(this.accountId, this.store);
  final String accountId;
  final AccountStore store;
  Future<String> path(String filename) => files.mediaPath(accountId, store, filename);

  Future<List<LocalItem>> load() async {
    final raw = await store.read('treasure.v1');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => LocalItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<LocalItem> items) => store.write(
    'treasure.v1',
    jsonEncode(items.map((e) => e.toJson()).toList()),
  );
  Future<LocalItem> importFile(String source, String kind) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final file = XFile(source);
    final extension = !kIsWeb && source.contains('.')
        ? source.split('.').last.replaceAll(RegExp('[^a-zA-Z0-9]'), '')
        : kind == 'image' ? 'jpg' : 'mp4';
    final filename = '$id.$extension';
    final data = await file.readAsBytes();
    // 瀏覽器資料與其他帳號資料共用儲存配額，首版限制單檔大小。
    if (kIsWeb && data.length > 2 * 1024 * 1024) {
      throw const FormatException('網頁版目前支援 2 MB 以下的圖片或影片');
    }
    await files.writeMedia(accountId, store, filename, data);
    return LocalItem(
      id: id,
      kind: kind,
      title: kind == 'image' ? '圖片' : '影片',
      detail: '',
      date: DateTime.now(),
      filename: filename,
    );
  }

  Future<Uint8List?> bytes(String filename) =>
      files.readMedia(accountId, store, filename);

  Future<void> removeFile(String filename) =>
      files.deleteMedia(accountId, store, filename);

  Future<void> setAvatar(String source) async {
    final name = 'avatar-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final data = await XFile(source).readAsBytes();
    if (kIsWeb && data.length > 2 * 1024 * 1024) {
      throw const FormatException('網頁版目前支援 2 MB 以下的頭貼');
    }
    await files.writeMedia(accountId, store, name, data);
    final old = await store.read('avatar');
    await store.write('avatar', name);
    if (old != null) await removeFile(old);
  }

  Future<Uint8List?> avatar() async {
    final name = await store.read('avatar');
    return name == null ? null : bytes(name);
  }
}
