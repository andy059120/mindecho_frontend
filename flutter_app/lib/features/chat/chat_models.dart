import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';

enum ChatMode {
  initial('INITIAL', '初談', '溫暖接住，建立安全感', CupertinoIcons.sparkles),
  mbt('MBT', 'MBT', '理解自己與他人感受，增進關係', CupertinoIcons.person_2_fill),
  cbt('CBT', 'CBT', '探索想法－情緒－行為的連結', CupertinoIcons.person_crop_circle),
  dbt('DBT', 'DBT', '穩定情緒、降低衝動，練習界線與應對', CupertinoIcons.waveform_path_ecg),
  mbct('MBCT', 'MBCT', '正念覺察，安定情緒起伏', CupertinoIcons.leaf_arrow_circlepath);

  const ChatMode(this.apiValue, this.title, this.subtitle, this.icon);
  final String apiValue;
  final String title;
  final String subtitle;
  final IconData icon;
  Color get color => switch (this) {
    initial => AppColors.userBubble,
    mbt => const Color(0xFF994D1A),
    dbt => const Color(0xFFAB5429),
    _ => AppColors.title,
  };
  static ChatMode parse(String? value) => ChatMode.values.firstWhere(
    (mode) => mode.apiValue == value,
    orElse: () => initial,
  );
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.mode,
    required this.createdAt,
  });
  final String id;
  final String title;
  final ChatMode mode;
  final DateTime? createdAt;
  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    title: json['title'] as String,
    mode: ChatMode.parse(json['chatbotType'] as String?),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
  });
  final String id;
  final String content;
  final bool isFromUser;
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    content: json['content'] as String,
    isFromUser: json['isFromUser'] as bool,
  );
}
