import '../../core/network/api_client.dart';
import '../auth/auth_controller.dart';
import 'models.dart';

class DashboardRepository {
  const DashboardRepository(this.auth);
  final AuthController auth;
  String get userId =>
      (auth.session?.user['userId'] ?? auth.session?.user['id'] ?? '')
          as String;
  Future<List<DailyRecord>> metrics() async {
    final json = await auth.authorized(
      'GET',
      '/main/dailyQuestions',
      query: {'userId': userId},
    );
    final records = (json['dailyQuestions'] as List).map(
      (e) => DailyRecord.fromJson(e as Map<String, dynamic>),
    );
    final byDay = <String, DailyRecord>{};
    for (final record in records) {
      byDay[dayKey(record.date)] = record;
    }
    return byDay.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> checkIn(List<int> values, DateTime date) async {
    if (values.length != 5 || values.any((v) => v < 1 || v > 5)) {
      throw const ApiException('請完成五項每日檢測');
    }
    // 與 Swift sendDailyQuestions 相同的題序與後端欄位。
    await auth.authorized(
      'POST',
      '/main/dailyQuestions',
      body: {
        'userId': userId,
        'physical': values[0],
        'mental': values[1],
        'emotion': values[2],
        'sleep': values[3],
        'diet': values[4],
        'entryDate': dayKey(date),
      },
    );
  }

  Future<List<DiaryEntry>> diaries({DateTime? month}) async {
    final query = <String, String>{};
    if (month != null) {
      query['startDate'] = DateTime(
        month.year,
        month.month,
      ).toUtc().toIso8601String();
      query['endDate'] = DateTime(
        month.year,
        month.month + 1,
      ).subtract(const Duration(milliseconds: 1)).toUtc().toIso8601String();
    }
    final json = await auth.authorized(
      'GET',
      '/diaries',
      query: query.isEmpty ? null : query,
    );
    return (json['entries'] as List)
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<DiaryEntry> saveDiary({
    String? id,
    required String content,
    required String mood,
    required DateTime date,
  }) async {
    if (content.trim().isEmpty) throw const ApiException('請先寫下日記內容');
    final json = await auth.authorized(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/diaries' : '/diaries/${Uri.encodeComponent(id)}',
      body: {
        'content': content.trim(),
        'mood': mood,
        'entryDate': calendarDay(date).toUtc().toIso8601String(),
      },
    );
    return DiaryEntry.fromJson(json['entry'] as Map<String, dynamic>);
  }

  Future<void> deleteDiary(String id) async {
    await auth.authorized('DELETE', '/diaries/${Uri.encodeComponent(id)}');
  }

  Future<Map<String, dynamic>> profile() async {
    final json = await auth.authorized('GET', '/user/profile');
    return (json['user'] ?? json) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String email,
    required String name,
  }) async {
    final parts = name.trim().split(RegExp(r'\s+'));
    final cjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(name);
    final lastName = cjk
        ? String.fromCharCode(name.trim().runes.first)
        : parts.first;
    final firstName = cjk
        ? String.fromCharCodes(name.trim().runes.skip(1))
        : parts.skip(1).join(' ');
    final json = await auth.authorized(
      'PATCH',
      '/user/profile',
      body: {
        'user_id': userId,
        'email': email.trim(),
        'firstName': firstName,
        'lastName': lastName,
      },
    );
    return (json['user'] ?? json) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> scales() async {
    final json = await auth.authorized(
      'GET',
      '/main/scales/sessions',
      query: {'userId': userId},
    );
    return (json['scales'] as List).cast<Map<String, dynamic>>();
  }
}
