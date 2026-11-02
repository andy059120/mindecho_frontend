import 'package:flutter/cupertino.dart';

DateTime calendarDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);
String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime? parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

class Indicator {
  const Indicator(this.key, this.label, this.emoji, this.color);
  final String key, label, emoji;
  final Color color;
}

const indicators = [
  Indicator('physical', '生理', '💪', CupertinoColors.systemRed),
  Indicator('emotion', '心情', '🙂', CupertinoColors.systemBlue),
  Indicator('sleep', '睡眠', '😴', CupertinoColors.systemPurple),
  Indicator('mental', '精神', '⚡', CupertinoColors.systemOrange),
  Indicator('diet', '食慾', '🍽', CupertinoColors.systemGreen),
];

class Mood {
  const Mood(this.code, this.emoji, this.label);
  final String code, emoji, label;
}

const moods = [
  Mood('VERY_BAD', '😫', '很差'),
  Mood('BAD', '😐', '不好'),
  Mood('OKAY', '🙂', '一般'),
  Mood('GOOD', '😃', '良好'),
  Mood('HAPPY', '🤩', '極佳'),
];
Mood moodFor(String? code) =>
    moods.firstWhere((mood) => mood.code == code, orElse: () => moods[2]);

class DailyRecord {
  const DailyRecord(this.date, this.values);
  final DateTime date;
  final Map<String, int> values;
  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    final date = parseDate(json['entryDate']);
    if (date == null) throw const FormatException('每日檢測日期格式異常');
    return DailyRecord(date, {
      for (final indicator in indicators)
        indicator.key: normalize((json[indicator.key] as num).toInt()),
    });
  }
  static int normalize(int score) => score <= 5
      ? score.clamp(1, 5)
      : score < 21
      ? 1
      : score < 41
      ? 2
      : score < 61
      ? 3
      : score < 81
      ? 4
      : 5;
}

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.content,
    required this.mood,
    required this.date,
  });
  final String id, content, mood;
  final DateTime date;
  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: (json['id'] ?? json['diaryId']) as String,
    content: json['content'] as String? ?? '',
    mood: json['mood'] as String? ?? 'OKAY',
    date:
        parseDate(json['entryDate'] ?? json['createdAt']) ??
        (throw const FormatException('日記日期格式異常')),
  );
}
