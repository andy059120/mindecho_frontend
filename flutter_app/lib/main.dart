import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'app/app.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_store.dart';
import 'features/auth/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient(client: http.Client());
  runApp(MindEchoApp(auth: AuthController(api, const KeychainSessionStore())));
}
