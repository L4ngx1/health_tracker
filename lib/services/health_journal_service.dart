import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthDailyLog {
  const HealthDailyLog({
    required this.date,
    required this.steps,
    required this.sleepMinutes,
    required this.waterMl,
    required this.workoutSessions,
    required this.workoutCalories,
    required this.updatedAt,
  });

  final DateTime date;
  final int steps;
  final int sleepMinutes;
  final int waterMl;
  final int workoutSessions;
  final int workoutCalories;
  final DateTime updatedAt;

  String get dateKey => _dateKey(date);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dateKey': dateKey,
      'steps': steps,
      'sleepMinutes': sleepMinutes,
      'waterMl': waterMl,
      'workoutSessions': workoutSessions,
      'workoutCalories': workoutCalories,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static HealthDailyLog? fromMap(Map<dynamic, dynamic> map) {
    final dateKey = (map['dateKey'] ?? '').toString().trim();
    if (dateKey.isEmpty) return null;
    final date = _parseDateKey(dateKey);
    if (date == null) return null;

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse('$value') ?? 0;
    }

    final updatedAt = DateTime.tryParse((map['updatedAt'] ?? '').toString()) ??
        DateTime.now();

    return HealthDailyLog(
      date: date,
      steps: parseInt(map['steps']),
      sleepMinutes: parseInt(map['sleepMinutes']),
      waterMl: parseInt(map['waterMl']),
      workoutSessions: parseInt(map['workoutSessions']),
      workoutCalories: parseInt(map['workoutCalories']),
      updatedAt: updatedAt,
    );
  }

  static String _dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime? _parseDateKey(String key) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
    if (match == null) return null;
    final y = int.tryParse(match.group(1) ?? '');
    final m = int.tryParse(match.group(2) ?? '');
    final d = int.tryParse(match.group(3) ?? '');
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}

class HealthJournalService {
  const HealthJournalService();

  static const String _prefHealthDaily = 'journal.healthDaily.v1';
  static const String _prefSteps = 'tracking.steps';
  static const String _prefSleepMinutes = 'tracking.sleepMinutes';
  static const String _prefWaterIntakeMl = 'home.waterIntakeMl';
  static const String _prefWorkoutHistory = 'workout.history.v1';

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _scoped(String base) => '$base.$_userScope';

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Map<String, dynamic>> _decodeWorkoutHistory(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', v)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, HealthDailyLog>> _loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoped(_prefHealthDaily));
    if (raw == null || raw.isEmpty) return <String, HealthDailyLog>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String, HealthDailyLog>{};
      final out = <String, HealthDailyLog>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        final log = HealthDailyLog.fromMap(item);
        if (log == null) continue;
        out[log.dateKey] = log;
      }
      return out;
    } catch (_) {
      return <String, HealthDailyLog>{};
    }
  }

  Future<void> _saveMap(Map<String, HealthDailyLog> map) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = map.values.toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));
    final capped = sorted.take(365).map((e) => e.toMap()).toList(growable: false);
    await prefs.setString(_scoped(_prefHealthDaily), jsonEncode(capped));
  }

  Future<void> captureTodaySnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    final steps = prefs.getInt(_scoped(_prefSteps)) ?? 0;
    final sleepMinutes = prefs.getInt(_scoped(_prefSleepMinutes)) ?? 0;
    final waterMl = prefs.getInt(_scoped(_prefWaterIntakeMl)) ?? 0;

    final historyRaw = prefs.getString(_scoped(_prefWorkoutHistory)) ?? '';
    final history = _decodeWorkoutHistory(historyRaw);

    var workoutSessions = 0;
    var workoutCalories = 0;

    for (final item in history) {
      final ts = item['timestampMs'];
      final timestamp = ts is int ? ts : int.tryParse('$ts');
      if (timestamp == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (!_sameDay(dt, today)) continue;

      workoutSessions += 1;
      final kcalRaw = (item['kcal'] ?? '').toString().replaceAll(',', '.');
      final kcal = double.tryParse(kcalRaw) ??
          (int.tryParse(kcalRaw) ?? 0).toDouble();
      workoutCalories += kcal.round();
    }

    final currentMap = await _loadMap();
    currentMap[todayKey] = HealthDailyLog(
      date: DateTime(today.year, today.month, today.day),
      steps: steps,
      sleepMinutes: sleepMinutes,
      waterMl: waterMl,
      workoutSessions: workoutSessions,
      workoutCalories: workoutCalories,
      updatedAt: DateTime.now(),
    );

    await _saveMap(currentMap);
  }

  Future<List<HealthDailyLog>> loadLogs() async {
    final map = await _loadMap();
    final list = map.values.toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
