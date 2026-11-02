import '../../features/auth/auth_controller.dart';
import 'chat_models.dart';

class ChatRepository {
  const ChatRepository(this.auth);
  final AuthController auth;

  Future<List<ChatSession>> sessions({int offset = 0}) async {
    final json = await auth.authorized(
      'GET',
      '/chat/sessions',
      query: {'limit': '20', 'offset': '$offset'},
    );
    return (json['sessions'] as List)
        .map((entry) => ChatSession.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<ChatSession> create(ChatMode mode, String title) async {
    final json = await auth.authorized(
      'POST',
      '/chat/sessions',
      body: {
        'chatbotType': mode.apiValue,
        if (title.trim().isNotEmpty) 'title': title.trim(),
      },
    );
    return ChatSession.fromJson(json['session'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await auth.authorized(
      'DELETE',
      '/chat/sessions/${Uri.encodeComponent(id)}',
    );
  }

  Future<List<ChatMessage>> history(String id) async {
    final json = await auth.authorized(
      'GET',
      '/chat/sessions/${Uri.encodeComponent(id)}/messages',
    );
    return (json['messages'] as List)
        .map((entry) => ChatMessage.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> send(String id, String message) =>
      auth.authorized(
        'POST',
        '/chat/sessions/${Uri.encodeComponent(id)}/messages',
        body: {'message': message},
      );
}
