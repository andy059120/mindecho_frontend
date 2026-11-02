import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../storage/account_store.dart';

Future<String> mediaPath(String accountId, AccountStore store, String name) async {
  if (name.contains('/') || name.contains('\\') || name == '..') {
    throw const FormatException('無效的本機檔名');
  }
  final base = await getApplicationDocumentsDirectory();
  final folder = Directory('${base.path}/mindecho/${base64Url.encode(utf8.encode(accountId))}');
  await folder.create(recursive: true);
  return '${folder.path}/$name';
}

Future<void> writeMedia(String id, AccountStore store, String name, Uint8List data) async {
  await File(await mediaPath(id, store, name)).writeAsBytes(data);
}

Future<Uint8List?> readMedia(String id, AccountStore store, String name) async {
  final file = File(await mediaPath(id, store, name));
  return await file.exists() ? file.readAsBytes() : null;
}

Future<void> deleteMedia(String id, AccountStore store, String name) async {
  final file = File(await mediaPath(id, store, name));
  if (await file.exists()) await file.delete();
}

VideoPlayerController videoController(String path) => VideoPlayerController.file(File(path));
