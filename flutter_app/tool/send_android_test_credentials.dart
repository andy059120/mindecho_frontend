import 'dart:async';
import 'dart:convert';
import 'dart:io';

// 僅對本機 VM service 傳遞手動測試帳密；不接受命令列帳密或寫入檔案。
Future<void> main(List<String> args) async {
  if (args.length != 1 || !stdin.hasTerminal) {
    stderr.writeln(
      '用法：fvm dart run tool/send_android_test_credentials.dart <vmservice-out-file>',
    );
    exitCode = 1;
    return;
  }
  final uri = Uri.parse((await File(args.single).readAsString()).trim());
  if (uri.scheme != 'ws' ||
      !['127.0.0.1', 'localhost', '::1'].contains(uri.host)) {
    throw const FormatException('僅接受本機 WebSocket VM service');
  }
  final socket = await WebSocket.connect(uri.toString());
  var serial = 0;
  final pending = <String, Completer<Map<String, dynamic>>>{};
  final subscription = socket.listen((event) {
    final message = jsonDecode(event as String) as Map<String, dynamic>;
    final completer = pending.remove(message['id']);
    if (completer == null) return;
    if (message.containsKey('error')) {
      completer.completeError(StateError('VM service 拒絕測試請求'));
    } else {
      completer.complete(message['result'] as Map<String, dynamic>);
    }
  });
  Future<Map<String, dynamic>> rpc(
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final id = '${++serial}';
    final completer = Completer<Map<String, dynamic>>();
    pending[id] = completer;
    socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params ?? {},
      }),
    );
    return completer.future.timeout(const Duration(seconds: 20));
  }

  String readSecret(String label) {
    stdout.write(label);
    final echo = stdin.echoMode;
    try {
      stdin.echoMode = false;
      return stdin.readLineSync() ?? '';
    } finally {
      stdin.echoMode = echo;
      stdout.writeln();
    }
  }

  try {
    final vm = await rpc('getVM');
    final isolate = (vm['isolates'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((i) => i['name'] == 'main');
    final details = await rpc('getIsolate', {'isolateId': isolate['id']});
    if (!(details['extensionRPCs'] as List).contains(
      'ext.mindecho.testCredentials',
    )) {
      throw StateError('請先啟動 android_live_test.dart');
    }
    await rpc('ext.mindecho.testCredentials', {
      'isolateId': isolate['id'],
      'email': readSecret('測試帳號：'),
      'password': readSecret('測試密碼：'),
    });
    stdout.writeln('已於執行期間傳入測試資料，未建立帳密檔案。');
  } finally {
    await subscription.cancel();
    await socket.close();
  }
}
