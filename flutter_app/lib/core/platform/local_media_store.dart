import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

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
  Future<Directory> directory() async {
    final base = await getApplicationDocumentsDirectory();
    final folder = Directory(
      '${base.path}/mindecho/${base64Url.encode(utf8.encode(accountId))}',
    );
    await folder.create(recursive: true);
    return folder;
  }

  Future<String> path(String filename) async {
    if (filename.contains('/') || filename.contains('\\') || filename == '..') {
      throw const FormatException('無效的本機檔名');
    }
    return '${(await directory()).path}/$filename';
  }

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
    final extension = source.contains('.')
        ? source.split('.').last.replaceAll(RegExp('[^a-zA-Z0-9]'), '')
        : kind == 'image'
        ? 'jpg'
        : 'mp4';
    final filename = '$id.$extension';
    await File(source).copy(await path(filename));
    return LocalItem(
      id: id,
      kind: kind,
      title: kind == 'image' ? '圖片' : '影片',
      detail: '',
      date: DateTime.now(),
      filename: filename,
    );
  }

  Future<Uint8List?> bytes(String filename) async {
    final file = File(await path(filename));
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<void> removeFile(String filename) async {
    final file = File(await path(filename));
    if (await file.exists()) await file.delete();
  }

  Future<void> setAvatar(String source) async {
    final name = 'avatar-${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(source).copy(await path(name));
    final old = await store.read('avatar');
    await store.write('avatar', name);
    if (old != null) await removeFile(old);
  }

  Future<Uint8List?> avatar() async {
    final name = await store.read('avatar');
    return name == null ? null : bytes(name);
  }
}
