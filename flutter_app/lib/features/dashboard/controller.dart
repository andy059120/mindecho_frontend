import 'package:flutter/foundation.dart';

import 'models.dart';
import 'repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this.repository);
  final DashboardRepository repository;
  List<DailyRecord> records = [];
  List<DiaryEntry> diaryEntries = [];
  List<Map<String, dynamic>> scaleRecords = [];
  Map<String, dynamic> get user =>
      _profile ?? repository.auth.session?.user ?? {};
  Map<String, dynamic>? _profile;
  final errors = <String, String>{};
  final loading = <String>{};
  bool _disposed = false;
  DateTime get today => calendarDay(DateTime.now());
  bool get completedToday =>
      records.any((record) => calendarDay(record.date) == today);
  DailyRecord? get todayRecord =>
      records.where((r) => calendarDay(r.date) == today).firstOrNull;
  DiaryEntry? diaryOn(DateTime date) => diaryEntries
      .where((e) => calendarDay(e.date) == calendarDay(date))
      .firstOrNull;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _load(String key, Future<void> Function() task) async {
    if (loading.contains(key)) return;
    loading.add(key);
    errors.remove(key);
    _notify();
    try {
      await task();
    } catch (error) {
      errors[key] = error.toString();
    } finally {
      loading.remove(key);
      _notify();
    }
  }

  Future<void> loadMetrics() => _load('metrics', () async {
    records = await repository.metrics();
  });
  Future<void> loadDiaries() => _load('diary', () async {
    diaryEntries = await repository.diaries();
  });
  Future<void> loadScales() => _load('scales', () async {
    scaleRecords = await repository.scales();
  });
  Future<void> loadProfile() => _load('profile', () async {
    _profile = await repository.profile();
  });
  Future<void> refresh() async {
    await Future.wait([
      loadMetrics(),
      loadDiaries(),
      loadScales(),
      loadProfile(),
    ]);
  }

  Future<void> submitCheckIn(List<int> values) async {
    final date = today;
    await repository.checkIn(values, date);
    await loadMetrics();
    if (!records.any((r) => calendarDay(r.date) == date)) {
      records.insert(
        0,
        DailyRecord.fromJson({
          'entryDate': dayKey(date),
          'physical': values[0],
          'mental': values[1],
          'emotion': values[2],
          'sleep': values[3],
          'diet': values[4],
        }),
      );
      _notify();
    }
  }

  Future<DiaryEntry> saveDiary({
    String? id,
    required String content,
    required String mood,
    required DateTime date,
  }) async {
    final entry = await repository.saveDiary(
      id: id,
      content: content,
      mood: mood,
      date: date,
    );
    diaryEntries.removeWhere((e) => e.id == id || e.id == entry.id);
    diaryEntries.add(entry);
    diaryEntries.sort((a, b) => b.date.compareTo(a.date));
    _notify();
    return entry;
  }

  Future<void> deleteDiary(String id) async {
    await repository.deleteDiary(id);
    diaryEntries.removeWhere((e) => e.id == id);
    _notify();
  }

  Future<void> updateProfile(String email, String name) async {
    _profile = await repository.updateProfile(email: email, name: name);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
