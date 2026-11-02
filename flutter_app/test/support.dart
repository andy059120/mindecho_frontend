import 'package:mindecho_flutter/core/storage/account_store.dart';
import 'package:mindecho_flutter/features/dashboard/catalog.dart';
import 'package:mindecho_flutter/core/storage/session_store.dart';
import 'package:mindecho_flutter/features/chat/chat_content.dart';

const testChatContent = ChatContent(
  {'INITIAL': '您好！我是您的對話助手。', 'CBT': '您好！我是您的CBT助手。'},
  {
    'HIGH': <String, dynamic>{},
    'MEDIUM': <String, dynamic>{},
    'NEGATION_CONTEXTS': <String, dynamic>{},
  },
);

class MemoryStore implements SessionStore {
  String? value;
  String? email;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<String?> readRememberedEmail() async => email;
  @override
  Future<void> rememberEmail(String? email) async {
    this.email = email;
  }
}

final testCatalog = DashboardCatalog(
  quotes: [
    {'title': '測試箴言', 'content': '測試內容'},
  ],
  scales: [],
  resources: {},
  videos: [],
);

class MemoryAccountStore implements AccountStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
