import 'dart:convert';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

import '../storage/account_store.dart';

// AccountStore 已依帳號隔離；瀏覽器版透過 secure storage 保存小型媒體。
Future<void> writeMedia(String id, AccountStore store, String name, Uint8List data) =>
    store.write('media.$name', base64Encode(data));

Future<Uint8List?> readMedia(String id, AccountStore store, String name) async {
  final raw = await store.read('media.$name');
  return raw == null ? null : base64Decode(raw);
}

Future<void> deleteMedia(String id, AccountStore store, String name) =>
    store.write('media.$name', null);

Future<String> mediaPath(String id, AccountStore store, String name) async {
  final raw = await store.read('media.$name');
  if (raw == null) throw const FormatException('找不到媒體檔案');
  // 避免假設匯入影片的格式；播放器會依檔案內容辨識。
  return 'data:application/octet-stream;base64,$raw';
}

VideoPlayerController videoController(String path) => VideoPlayerController.networkUrl(Uri.parse(path));
