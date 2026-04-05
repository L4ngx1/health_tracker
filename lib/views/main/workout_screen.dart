import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../controllers/workout_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/workout_item.dart';
import '../../models/workout_history_item.dart';
import '../../models/backend/workout_record.dart';
import '../../services/backend_api_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';
import '../../core/theme/responsive.dart';

class _DayWorkoutPlan {
  const _DayWorkoutPlan({required this.day, required this.items});

  final String day;
  final List<String> items;
}

class _PendingWorkoutDelete {
  const _PendingWorkoutDelete({
    required this.identityKey,
    required this.queuedAtMs,
    this.cloudId,
  });

  final String identityKey;
  final int queuedAtMs;
  final String? cloudId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'identityKey': identityKey,
      'queuedAtMs': queuedAtMs,
      'cloudId': cloudId,
    };
  }

  static _PendingWorkoutDelete? fromMap(Map<dynamic, dynamic> map) {
    final identityKey = (map['identityKey'] ?? '').toString().trim();
    if (identityKey.isEmpty) return null;

    final queuedAtMs = map['queuedAtMs'] is int
        ? map['queuedAtMs'] as int
        : int.tryParse('${map['queuedAtMs']}') ??
            DateTime.now().millisecondsSinceEpoch;

    final cloudIdRaw = (map['cloudId'] ?? '').toString().trim();
    return _PendingWorkoutDelete(
      identityKey: identityKey,
      queuedAtMs: queuedAtMs,
      cloudId: cloudIdRaw.isEmpty ? null : cloudIdRaw,
    );
  }

  String get queueKey => '${cloudId ?? ''}|$identityKey';
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  static const _prefWeightKg = 'profile.weightKg';
  static const _prefWorkoutHistory = 'workout.history.v1';
  static const _prefPendingDelete = 'workout.pendingDelete.v1';
  static const _prefPlanProgress = 'workout.planProgress.v1';
  static const _prefWeeklyPlan = 'workout.weeklyPlan.v1';
  final AIController _aiController = AIController();
  final BackendApiService _backendApiService = BackendApiService();
  final MainNavigationController _navController = MainNavigationController();
  Timer? _weightSyncTimer;
  Timer? _pendingDeleteSyncTimer;
  Timer? _goalBannerTimer;
  bool _isSyncingPendingDeletes = false;
  final WorkoutController _workoutController = WorkoutController();
  String? _aiWorkoutPlan;
  List<_DayWorkoutPlan> _weeklyPlan = const [];
  List<WorkoutHistoryItem> _history = const [];
  bool _isLoading = false;
  bool _isSavingPlan = false;
  double? _weightKg;
  String _currentPlanSignature = '';
  int _selectedGoalIndex = 0;
  int _selectedLevelIndex = 0;
  int _sessionsPerWeek = 4;
  int _historyFilterDays = 0; // 0=all, 7, 30
  int _selectedProgramFilter = -1; // -1 = tất cả
  Map<String, bool> _planProgress = <String, bool>{};
  final PageController _goalBannerController = PageController();
  final ValueNotifier<int> _goalBannerIndex = ValueNotifier<int>(0);

  static const List<(String label, String prompt)> _goalOptions = [
    ('Giảm mỡ', 'Giảm mỡ và nâng cao sức bền'),
    ('Tăng cơ', 'Tăng cơ và cải thiện sức mạnh'),
    ('Tăng sức bền', 'Tăng sức bền tim mạch và độ bền toàn thân'),
    ('Duy trì', 'Duy trì sức khỏe và vận động đều đặn'),
  ];

  static const List<(String label, String prompt)> _levelOptions = [
    ('Mới bắt đầu', 'Mới bắt đầu, tập 2 buổi/tuần'),
    ('Trung cấp', 'Trung cấp, tập 3-4 buổi/tuần'),
    ('Nâng cao', 'Nâng cao, tập 5 buổi/tuần'),
  ];

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _accountKey(String base) => '$base.$_userScope';

  @override
  void initState() {
    super.initState();
    _navController.addListener(_onNavChanged);
    _loadWeight();
    _loadWorkoutHistory();
    _loadSavedWeeklyPlan();
    _startWeightSync();
    _startPendingDeleteSync();
    _startGoalBannerAutoSlide();
  }

  @override
  void dispose() {
    _weightSyncTimer?.cancel();
    _pendingDeleteSyncTimer?.cancel();
    _goalBannerTimer?.cancel();
    _goalBannerController.dispose();
    _goalBannerIndex.dispose();
    _navController.removeListener(_onNavChanged);
    super.dispose();
  }

  void _startGoalBannerAutoSlide() {
    _goalBannerTimer?.cancel();
    _goalBannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_goalBannerController.hasClients) return;
      final target = (_goalBannerIndex.value + 1) % 3;
      _goalBannerController.animateToPage(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onNavChanged() {
    if (_navController.index == 1) {
      _loadWeight();
      unawaited(_syncPendingCloudDeletes());
    }
  }

  void _startWeightSync() {
    _weightSyncTimer?.cancel();
    _weightSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _loadWeight(onlyIfChanged: true);
    });
  }

  void _startPendingDeleteSync() {
    _pendingDeleteSyncTimer?.cancel();
    _pendingDeleteSyncTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      unawaited(_syncPendingCloudDeletes());
    });
  }

  Future<void> _loadWeight({bool onlyIfChanged = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = _accountKey(_prefWeightKg);
    if (!prefs.containsKey(scopedKey) && prefs.containsKey(_prefWeightKg)) {
      final legacyWeight = prefs.getDouble(_prefWeightKg);
      if (legacyWeight != null) {
        await prefs.setDouble(scopedKey, legacyWeight);
      }
      await prefs.remove(_prefWeightKg);
    }
    final latest = prefs.getDouble(scopedKey);
    if (!mounted) return;
    if (onlyIfChanged && latest == _weightKg) {
      return;
    }
    setState(() {
      _weightKg = latest;
    });
  }

  Future<void> _loadWorkoutHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final localHistory = _readLocalHistory(prefs);
    List<WorkoutHistoryItem> cloudHistory = const [];
    var cloudLoaded = false;

    try {
      final records = await _backendApiService.getMyWorkouts(limit: 100);
      cloudHistory =
          records.map(_mapWorkoutRecordToHistory).toList(growable: false);
      cloudLoaded = true;

      await _syncLocalHistoryToCloud(localHistory, cloudHistory);

      // Re-read cloud after pushing local items to ensure UI shows synced data.
      final refreshed = await _backendApiService.getMyWorkouts(limit: 100);
      cloudHistory =
          refreshed.map(_mapWorkoutRecordToHistory).toList(growable: false);
    } catch (e) {
      debugPrint('load workout cloud history failed: $e');
    }

    final merged = _mergeHistory(
      cloudLoaded ? cloudHistory : const [],
      localHistory,
    );

    if (!mounted) return;
    setState(() => _history = merged);
    await _persistWorkoutHistoryList(merged);
    await _syncPendingCloudDeletes();
    await _loadPlanProgress();
  }

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  DateTime _startOfWeek(DateTime value) {
    final base = DateTime(value.year, value.month, value.day);
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  String _weekKey([DateTime? value]) {
    final start = _startOfWeek(value ?? DateTime.now());
    return _dayKey(start);
  }

  String _planProgressKey(String day, String item) =>
      '${_weekKey()}|$_currentPlanSignature|$day|$item';

  String _weeklyPlanSignature(List<_DayWorkoutPlan> plan) {
    return plan.map((day) => '${day.day}:${day.items.join('||')}').join('##');
  }

  String _normalizePlanNote(String note) {
    final metaIndex = note.indexOf('[[PLAN_META]]');
    final visible = metaIndex >= 0 ? note.substring(0, metaIndex) : note;
    final lines = visible
        .split('\n')
        .map((line) {
          final cleaned = line.replaceFirst(
            RegExp(r'^\s*\[(?:x| )\]\s*', caseSensitive: false),
            '',
          );
          return cleaned.trim();
        })
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return lines.join('\n');
  }

  DateTime? _historyItemDate(WorkoutHistoryItem item) {
    final ts = item.timestampMs;
    if (ts != null) return DateTime.fromMillisecondsSinceEpoch(ts);
    final parsed = DateTime.tryParse(item.date);
    if (parsed != null) return parsed;
    final match =
        RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(item.date.trim());
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _buildWeeklyPlanNote() {
    final goal = _goalOptions[_selectedGoalIndex].$1;
    final level = _levelOptions[_selectedLevelIndex].$1;
    final buffer = StringBuffer()
      ..writeln('Kế hoạch tập tuần')
      ..writeln('Mục tiêu: $goal')
      ..writeln('Trình độ: $level')
      ..writeln('Số buổi/tuần: $_sessionsPerWeek')
      ..writeln(
        _weightKg == null
            ? 'Cân nặng: chưa cập nhật'
            : 'Cân nặng: ${_weightKg!.toStringAsFixed(1)} kg',
      )
      ..writeln('');

    for (final day in _weeklyPlan) {
      buffer.writeln('${day.day}:');
      for (final item in day.items) {
        final checked = _planProgress[_planProgressKey(day.day, item)] == true;
        buffer.writeln('${checked ? '[x]' : '[ ]'} $item');
      }
    }
    return buffer.toString().trimRight();
  }

  int _findWeeklyPlanHistoryIndex({
    required String normalizedNote,
    required DateTime weekDate,
  }) {
    final targetWeekKey = _weekKey(weekDate);
    for (var index = 0; index < _history.length; index++) {
      final item = _history[index];
      if (!_isWeeklyPlanHistoryItem(item)) continue;
      final date = _historyItemDate(item);
      if (date == null || _weekKey(date) != targetWeekKey) continue;
      if (_normalizePlanNote(item.note ?? '') == normalizedNote) {
        return index;
      }
    }
    return -1;
  }

  void _setActiveWeeklyPlan(List<_DayWorkoutPlan> plan) {
    _currentPlanSignature = _weeklyPlanSignature(plan);
  }

  Future<void> _loadPlanProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountKey(_prefPlanProgress));
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() => _planProgress = <String, bool>{});
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final parsed = <String, bool>{};
      decoded.forEach((key, value) {
        parsed['$key'] = value == true;
      });
      if (!mounted) return;
      setState(() => _planProgress = parsed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _planProgress = <String, bool>{});
    }
  }

  Future<void> _persistPlanProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountKey(_prefPlanProgress),
      jsonEncode(_planProgress),
    );
  }

  void _initializePlanProgress(List<_DayWorkoutPlan> plan,
      {bool reset = false}) {
    _setActiveWeeklyPlan(plan);
    final next = <String, bool>{};
    for (final day in plan) {
      for (final item in day.items) {
        if (!_isExerciseTask(item)) continue;
        final key = _planProgressKey(day.day, item);
        next[key] = reset ? false : (_planProgress[key] ?? false);
      }
    }
    _planProgress = next;
  }

  bool _isExerciseTask(String item) {
    return RegExp(r'~\s*\d+\s*kcal', caseSensitive: false).hasMatch(item);
  }

  int _extractEstimatedCalories(String item) {
    final match =
        RegExp(r'~\s*(\d+)\s*kcal', caseSensitive: false).firstMatch(item);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  int _parseKcalInt(String raw) {
    final normalized = raw.replaceAll(',', '.').trim();
    final direct = double.tryParse(normalized);
    if (direct != null) return direct.round();
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
    if (match == null) return 0;
    return (double.tryParse(match.group(1) ?? '') ?? 0).round();
  }

  int _inferCaloriesFromNote(String? note, {bool checkedOnly = true}) {
    final raw = (note ?? '').trim();
    if (raw.isEmpty) return 0;

    var total = 0;
    final lines = raw.split('\n');
    for (final line in lines) {
      final itemText = line.trim();
      if (itemText.isEmpty) continue;
      if (checkedOnly && !itemText.startsWith('[x]')) continue;
      total += _extractEstimatedCalories(itemText);
    }
    return total;
  }

  int _normalizeHistoryCalories({
    required String name,
    required String kcalRaw,
    String? note,
  }) {
    final parsed = _parseKcalInt(kcalRaw);
    if (parsed > 0) return parsed;

    final lowerName = name.trim().toLowerCase();
    final isWeeklyPlan = lowerName.contains('kế hoạch tập tuần') ||
        lowerName.contains('ke hoach tap tuan');
    if (!isWeeklyPlan) return parsed;

    final checkedCalories = _inferCaloriesFromNote(note, checkedOnly: true);
    if (checkedCalories > 0) return checkedCalories;
    return _inferCaloriesFromNote(note, checkedOnly: false);
  }

  int _estimateAiExerciseCalories(String exerciseText) {
    final lower = exerciseText.toLowerCase();
    final weight = _weightKg ?? 65;
    final level = _levelOptions[_selectedLevelIndex].$1.toLowerCase();
    final levelFactor = level.contains('nâng cao')
        ? 1.20
        : (level.contains('trung cấp') ? 1.0 : 0.85);

    var base = 70.0;
    if (lower.contains('chạy') ||
        lower.contains('run') ||
        lower.contains('cardio')) {
      base = 120;
    } else if (lower.contains('đạp xe') || lower.contains('cycling')) {
      base = 95;
    } else if (lower.contains('plank') || lower.contains('core')) {
      base = 55;
    } else if (lower.contains('squat') ||
        lower.contains('lunge') ||
        lower.contains('chân')) {
      base = 90;
    } else if (lower.contains('hít đất') ||
        lower.contains('push') ||
        lower.contains('ngực')) {
      base = 80;
    } else if (lower.contains('kéo') ||
        lower.contains('row') ||
        lower.contains('lưng')) {
      base = 78;
    }

    final weightFactor = (weight / 65).clamp(0.7, 1.6);
    return (base * weightFactor * levelFactor).round();
  }

  int _plannedCompletedSessions() {
    var completed = 0;
    for (final day in _weeklyPlan) {
      final tasks = day.items.where(_isExerciseTask).toList(growable: false);
      if (tasks.isEmpty) continue;
      final allDone = tasks.every(
        (item) => _planProgress[_planProgressKey(day.day, item)] == true,
      );
      if (allDone) completed += 1;
    }
    return completed;
  }

  int _manualWorkoutSessionsThisWeek() {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    var sessions = 0;
    for (final entry in _history) {
      if (_isWeeklyPlanHistoryItem(entry)) continue;
      final date = _historyItemDate(entry);
      if (date == null) continue;
      if (date.isBefore(weekStart) || !date.isBefore(weekEndExclusive)) {
        continue;
      }
      sessions += 1;
    }
    return sessions;
  }

  int? _weekdayFromPlanDay(String day) {
    final normalized = day.toLowerCase().trim();
    if (normalized == 'thứ 2') return DateTime.monday;
    if (normalized == 'thứ 3') return DateTime.tuesday;
    if (normalized == 'thứ 4') return DateTime.wednesday;
    if (normalized == 'thứ 5') return DateTime.thursday;
    if (normalized == 'thứ 6') return DateTime.friday;
    if (normalized == 'thứ 7') return DateTime.saturday;
    if (normalized == 'chủ nhật') return DateTime.sunday;
    return null;
  }

  Map<int, int> _weeklyCaloriesByWeekday(
    List<WorkoutHistoryItem> weekRealSessions,
  ) {
    final byDay = <int, int>{
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        weekday: 0,
    };

    for (final session in weekRealSessions) {
      final date = _historyItemDate(session);
      if (date == null) continue;
      byDay[date.weekday] =
          (byDay[date.weekday] ?? 0) + _parseKcalInt(session.kcal);
    }

    for (final day in _weeklyPlan) {
      final weekday = _weekdayFromPlanDay(day.day);
      if (weekday == null) continue;
      for (final item in day.items) {
        if (!_isExerciseTask(item)) continue;
        if (_planProgress[_planProgressKey(day.day, item)] == true) {
          byDay[weekday] =
              (byDay[weekday] ?? 0) + _extractEstimatedCalories(item);
        }
      }
    }

    return byDay;
  }

  int _aiPlanStreakDays() {
    final aiCompletedSessions = _plannedCompletedSessions();
    final manualSessions = _manualWorkoutSessionsThisWeek();
    final combined = aiCompletedSessions + manualSessions;
    if (combined < 0) return 0;
    return combined;
  }

  String _aiStreakDescription() {
    final hasAiPlan = _weeklyPlan.any((day) => day.items.any(_isExerciseTask));
    if (!hasAiPlan) {
      return 'Tạo kế hoạch AI để bắt đầu theo dõi streak tập luyện.';
    }
    return 'Streak tăng theo tổng số buổi trong tuần: buổi AI hoàn thành + buổi tập trong Chế độ tập luyện.';
  }

  int _plannedCheckedCalories() {
    var total = 0;
    for (final day in _weeklyPlan) {
      for (final item in day.items) {
        if (!_isExerciseTask(item)) continue;
        if (_planProgress[_planProgressKey(day.day, item)] == true) {
          total += _extractEstimatedCalories(item);
        }
      }
    }
    return total;
  }

  int _plannedTotalCalories() {
    var total = 0;
    for (final day in _weeklyPlan) {
      for (final item in day.items) {
        if (!_isExerciseTask(item)) continue;
        total += _extractEstimatedCalories(item);
      }
    }
    return total;
  }

  double _planProgressRatio() {
    if (_weeklyPlan.isEmpty) return 0;
    var total = 0;
    var done = 0;
    for (final day in _weeklyPlan) {
      for (final item in day.items) {
        if (!_isExerciseTask(item)) continue;
        total += 1;
        if (_planProgress[_planProgressKey(day.day, item)] == true) {
          done += 1;
        }
      }
    }
    if (total == 0) return 0;
    return done / total;
  }

  Future<void> _persistSavedWeeklyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _weeklyPlan
        .map(
          (e) => <String, dynamic>{
            'day': e.day,
            'items': e.items,
          },
        )
        .toList(growable: false);
    await prefs.setString(_accountKey(_prefWeeklyPlan), jsonEncode(payload));
  }

  Future<void> _loadSavedWeeklyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountKey(_prefWeeklyPlan));
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <_DayWorkoutPlan>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final day = (item['day'] ?? '').toString().trim();
        final listRaw = item['items'];
        if (day.isEmpty || listRaw is! List) continue;
        final list = listRaw.map((e) => '$e').toList(growable: false);
        loaded.add(_DayWorkoutPlan(day: day, items: list));
      }
      if (loaded.isEmpty || !mounted) return;
      final savedSessionCount = loaded
          .where((day) => day.items.any(_isExerciseTask))
          .length
          .clamp(3, 6);
      setState(() {
        _weeklyPlan = loaded;
        _sessionsPerWeek = savedSessionCount;
        _initializePlanProgress(loaded);
      });
    } catch (_) {
      // Ignore malformed saved plan.
    }
  }

  Future<void> _clearSavedWeeklyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountKey(_prefWeeklyPlan));
  }

  Future<void> _persistWorkoutHistory() async {
    await _persistWorkoutHistoryList(_history);
  }

  Future<void> _persistWorkoutHistoryList(List<WorkoutHistoryItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = list
        .map(
          (e) => {
            'name': e.name,
            'date': e.date,
            'duration': e.duration,
            'kcal': e.kcal,
            'timestampMs': e.timestampMs,
            'cloudId': e.cloudId,
            'note': e.note,
          },
        )
        .toList(growable: false);
    await prefs.setString(
        _accountKey(_prefWorkoutHistory), jsonEncode(payload));
  }

  List<_PendingWorkoutDelete> _readPendingCloudDeletes(
      SharedPreferences prefs) {
    final raw = prefs.getString(_accountKey(_prefPendingDelete));
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = <_PendingWorkoutDelete>[];
      for (final element in decoded) {
        if (element is! Map) continue;
        final parsed = _PendingWorkoutDelete.fromMap(element);
        if (parsed == null) continue;
        items.add(parsed);
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persistPendingCloudDeletes(
    List<_PendingWorkoutDelete> pending,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = pending.map((e) => e.toMap()).toList(growable: false);
    await prefs.setString(_accountKey(_prefPendingDelete), jsonEncode(payload));
  }

  Future<void> _queuePendingCloudDelete(WorkoutHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _readPendingCloudDeletes(prefs).toList(growable: true);
    final queued = _PendingWorkoutDelete(
      identityKey: _historyIdentityKey(item),
      cloudId: item.cloudId?.trim().isEmpty == true ? null : item.cloudId,
      queuedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    final exists = pending.any((e) => e.queueKey == queued.queueKey);
    if (exists) return;
    pending.add(queued);
    await _persistPendingCloudDeletes(pending);
  }

  Future<void> _syncPendingCloudDeletes() async {
    if (_isSyncingPendingDeletes) return;
    _isSyncingPendingDeletes = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = _readPendingCloudDeletes(prefs);
      if (pending.isEmpty) return;

      List<WorkoutRecord>? recordsCache;
      final remaining = <_PendingWorkoutDelete>[];

      for (final task in pending) {
        try {
          final directId = task.cloudId?.trim();
          if (directId != null && directId.isNotEmpty) {
            await _backendApiService.deleteMyWorkout(directId);
            continue;
          }

          recordsCache ??= await _backendApiService.getMyWorkouts(limit: 250);
          final matched = recordsCache
              .where(
                (record) =>
                    _historyIdentityKey(_mapWorkoutRecordToHistory(record)) ==
                    task.identityKey,
              )
              .toList(growable: false);

          if (matched.isEmpty) {
            continue;
          }

          for (final record in matched) {
            await _backendApiService.deleteMyWorkout(record.id);
          }

          final deletedIds = matched.map((e) => e.id).toSet();
          recordsCache = recordsCache
              .where((record) => !deletedIds.contains(record.id))
              .toList(growable: false);
        } catch (_) {
          remaining.add(task);
        }
      }

      await _persistPendingCloudDeletes(remaining);
    } finally {
      _isSyncingPendingDeletes = false;
    }
  }

  List<WorkoutHistoryItem> _readLocalHistory(SharedPreferences prefs) {
    final raw = prefs.getString(_accountKey(_prefWorkoutHistory));
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final list = <WorkoutHistoryItem>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final timestampMs = item['timestampMs'] is int
            ? item['timestampMs'] as int
            : int.tryParse('${item['timestampMs']}');
        if (timestampMs == null) continue;
        final name = (item['name'] ?? '').toString();
        final note = (item['note'] ?? '').toString().trim().isEmpty
            ? null
            : (item['note'] ?? '').toString();
        final kcal = _normalizeHistoryCalories(
          name: name,
          kcalRaw: (item['kcal'] ?? '').toString(),
          note: note,
        );
        list.add(
          WorkoutHistoryItem(
            name: name,
            date: (item['date'] ?? '').toString(),
            duration: (item['duration'] ?? '').toString(),
            kcal: kcal.toString(),
            timestampMs: timestampMs,
            cloudId: (item['cloudId'] ?? '').toString().trim().isEmpty
                ? null
                : (item['cloudId'] ?? '').toString(),
            note: note,
          ),
        );
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  WorkoutHistoryItem _mapWorkoutRecordToHistory(WorkoutRecord record) {
    final dt = record.performedAt;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final kcal = _normalizeHistoryCalories(
      name: record.name,
      kcalRaw: record.caloriesBurned.round().toString(),
      note: record.note,
    );
    return WorkoutHistoryItem(
      name: record.name,
      date: '$day/$month/$year',
      duration: '${record.durationMinutes} phút',
      kcal: kcal.toString(),
      timestampMs: dt.millisecondsSinceEpoch,
      cloudId: record.id,
      note: record.note,
    );
  }

  Future<void> _showHistoryDetails(WorkoutHistoryItem item) async {
    final detailNote = _normalizePlanNote((item.note ?? '').trim());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chi tiết bài tập'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tên bài tập: ${item.name}'),
                const SizedBox(height: 6),
                Text('Ngày: ${item.date}'),
                const SizedBox(height: 6),
                Text('Thời lượng: ${item.duration}'),
                const SizedBox(height: 6),
                Text('Calories: ${item.kcal} kcal'),
                if (detailNote.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Ghi chú:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(detailNote),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  List<WorkoutHistoryItem> _mergeHistory(
    List<WorkoutHistoryItem> cloud,
    List<WorkoutHistoryItem> local,
  ) {
    final merged = <String, WorkoutHistoryItem>{};
    for (final item in cloud) {
      merged[_historyIdentityKey(item)] = item;
    }
    for (final item in local) {
      merged.putIfAbsent(_historyIdentityKey(item), () => item);
    }

    final list = merged.values.toList(growable: false);
    list.sort((a, b) => (b.timestampMs ?? 0).compareTo(a.timestampMs ?? 0));
    return list.take(50).toList(growable: false);
  }

  String _historyIdentityKey(WorkoutHistoryItem item) {
    return '${item.timestampMs ?? 0}|${item.name.trim().toLowerCase()}|${item.duration.trim()}|${item.kcal.trim()}';
  }

  Future<void> _syncLocalHistoryToCloud(
    List<WorkoutHistoryItem> local,
    List<WorkoutHistoryItem> cloud,
  ) async {
    if (local.isEmpty) return;
    final cloudKeys = cloud.map(_historyIdentityKey).toSet();
    for (final item in local) {
      final ts = item.timestampMs;
      if (ts == null) continue;
      if (cloudKeys.contains(_historyIdentityKey(item))) continue;

      final performedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final durationMinutes = _parseDurationMinutes(item.duration);
      final calories = _parseCalories(item.kcal);

      try {
        await _backendApiService.addMyWorkout(
          WorkoutRecord(
            id: '',
            name: item.name,
            durationMinutes: durationMinutes,
            caloriesBurned: calories,
            performedAt: performedAt,
            note: 'local-sync',
          ),
        );
      } catch (e) {
        debugPrint('sync local workout history failed: $e');
      }
    }
  }

  int _parseDurationMinutes(String raw) {
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '') ?? 30;
  }

  double _parseCalories(String raw) {
    return _parseKcalInt(raw).toDouble();
  }

  List<WorkoutHistoryItem> _applyHistoryFilter(
      List<WorkoutHistoryItem> source) {
    if (_historyFilterDays == 0) return source;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final maxAgeMs = Duration(days: _historyFilterDays).inMilliseconds;
    return source.where((entry) {
      final ts = entry.timestampMs;
      if (ts == null) return false;
      return nowMs - ts <= maxAgeMs;
    }).toList(growable: false);
  }

  List<WorkoutHistoryItem> _currentWeekHistory(
      List<WorkoutHistoryItem> source) {
    final now = DateTime.now();
    final weekdayOffset = now.weekday - DateTime.monday;
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekdayOffset));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final weekStartMs = weekStart.millisecondsSinceEpoch;
    final weekEndMs = weekEndExclusive.millisecondsSinceEpoch;
    return source.where((entry) {
      final ts = entry.timestampMs;
      if (ts == null) return false;
      return ts >= weekStartMs && ts < weekEndMs;
    }).toList(growable: false);
  }

  bool _isWeeklyPlanHistoryItem(WorkoutHistoryItem item) {
    final name = item.name.trim().toLowerCase();
    return name.contains('kế hoạch tập tuần') ||
        name.contains('ke hoach tap tuan');
  }

  int _extractSessionsFromDuration(String raw) {
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  WorkoutHistoryItem? _latestSavedWeeklyPlan(List<WorkoutHistoryItem> source) {
    WorkoutHistoryItem? latest;
    for (final item in source) {
      if (!_isWeeklyPlanHistoryItem(item)) continue;
      if (latest == null ||
          (item.timestampMs ?? 0) > (latest.timestampMs ?? 0)) {
        latest = item;
      }
    }
    return latest;
  }

  Future<void> _deleteHistoryAt(
      int indexInFiltered, List<WorkoutHistoryItem> filtered) async {
    if (indexInFiltered < 0 || indexInFiltered >= filtered.length) return;
    final target = filtered[indexInFiltered];
    final idx = _history.indexWhere((e) =>
        e.name == target.name &&
        e.date == target.date &&
        e.duration == target.duration &&
        e.kcal == target.kcal &&
        e.timestampMs == target.timestampMs);
    if (idx < 0) return;
    setState(() {
      _history = List<WorkoutHistoryItem>.from(_history)..removeAt(idx);
    });
    await _persistWorkoutHistory();

    final deletedInCloud = await _deleteHistoryFromCloud(target);
    if (!mounted || deletedInCloud) return;
    final messenger = ScaffoldMessenger.of(context);
    await _queuePendingCloudDelete(target);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã xóa cục bộ, sẽ tự đồng bộ xóa cloud khi có mạng.'),
      ),
    );
  }

  Future<void> _confirmClearAllHistory() async {
    if (_history.isEmpty) return;
    final removedItems =
        List<WorkoutHistoryItem>.from(_history, growable: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử tập luyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _history = const [];
    });
    await _persistWorkoutHistory();

    try {
      final records = await _backendApiService.getMyWorkouts(limit: 200);
      for (final record in records) {
        await _backendApiService.deleteMyWorkout(record.id);
      }
    } catch (e) {
      debugPrint('clear workout history on cloud failed: $e');
      for (final item in removedItems) {
        await _queuePendingCloudDelete(item);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa cục bộ, sẽ tự đồng bộ xóa cloud khi có mạng.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa toàn bộ lịch sử tập luyện.')),
    );
  }

  Future<bool> _deleteHistoryFromCloud(WorkoutHistoryItem target) async {
    try {
      final directId = target.cloudId?.trim();
      if (directId != null && directId.isNotEmpty) {
        await _backendApiService.deleteMyWorkout(directId);
        return true;
      }

      // Fallback for old local entries that were saved before cloudId existed.
      final records = await _backendApiService.getMyWorkouts(limit: 150);
      final matched = records.where((record) {
        final mapped = _mapWorkoutRecordToHistory(record);
        return _historyIdentityKey(mapped) == _historyIdentityKey(target);
      }).toList(growable: false);

      if (matched.isEmpty) {
        return true;
      }

      for (final record in matched) {
        await _backendApiService.deleteMyWorkout(record.id);
      }
      return true;
    } catch (e) {
      debugPrint('delete workout history on cloud failed: $e');
      return false;
    }
  }

  int _estimateCalories(String workoutName, int durationMin) {
    final weight = _weightKg ?? 65.0;
    final key = workoutName.toLowerCase();
    double met = 6.0;
    if (key.contains('run') || key.contains('chạy')) {
      met = 8.0;
    } else if (key.contains('gym')) {
      met = 6.0;
    } else if (key.contains('yoga')) {
      met = 3.2;
    } else if (key.contains('cycling') || key.contains('đạp')) {
      met = 7.0;
    }
    final kcal = met * 3.5 * weight / 200 * durationMin;
    return kcal.round();
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _logWorkoutSession(WorkoutItem item) async {
    int draftDuration = 30;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final estimated = _estimateCalories(item.title, draftDuration);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi nhận buổi tập: ${item.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Thời lượng: $draftDuration phút'),
                    Slider(
                      value: draftDuration.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 22,
                      label: '$draftDuration phút',
                      onChanged: (value) {
                        setModalState(() => draftDuration = value.round());
                      },
                    ),
                    Text('Calories ước tính: $estimated kcal'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final performedAt = DateTime.now();
                          final entry = WorkoutHistoryItem(
                            name: item.title,
                            date: _todayLabel(),
                            duration: '$draftDuration phút',
                            kcal: '$estimated',
                            timestampMs: performedAt.millisecondsSinceEpoch,
                            note: 'manual-log',
                          );
                          if (!mounted) return;
                          setState(() {
                            _history = [entry, ..._history].take(50).toList();
                          });
                          await _persistWorkoutHistory();

                          var syncedToCloud = false;
                          try {
                            final cloudId =
                                await _backendApiService.addMyWorkout(
                              WorkoutRecord(
                                id: '',
                                name: item.title,
                                durationMinutes: draftDuration,
                                caloriesBurned: estimated.toDouble(),
                                performedAt: performedAt,
                                note: 'manual-log',
                              ),
                            );
                            final saved = WorkoutHistoryItem(
                              name: entry.name,
                              date: entry.date,
                              duration: entry.duration,
                              kcal: entry.kcal,
                              timestampMs: entry.timestampMs,
                              cloudId: cloudId,
                              note: entry.note,
                            );
                            if (mounted) {
                              setState(() {
                                _history = _history
                                    .map((e) => _historyIdentityKey(e) ==
                                            _historyIdentityKey(entry)
                                        ? saved
                                        : e)
                                    .toList(growable: false);
                              });
                            }
                            await _persistWorkoutHistory();
                            await _backendApiService.addMyNotification(
                              title: 'Buổi tập đã được lưu',
                              message:
                                  'Bạn vừa lưu ${item.title} ($draftDuration phút, $estimated kcal).',
                              isImportant: false,
                            );
                            syncedToCloud = true;
                          } catch (e) {
                            debugPrint('save workout to cloud failed: $e');
                          }

                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                syncedToCloud
                                    ? 'Đã lưu và đồng bộ buổi tập'
                                    : 'Đồng bộ dữ liệu không thành công (Vui lòng kiểm tra kết nối mạng).',
                              ),
                            ),
                          );
                        },
                        child: const Text('Lưu buổi tập'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _getAIWorkout() async {
    await _loadWeight(onlyIfChanged: true);
    setState(() => _isLoading = true);
    final selectedGoal = _goalOptions[_selectedGoalIndex].$2;
    final selectedLevel = _levelOptions[_selectedLevelIndex].$2;

    final plan = await _aiController.getPersonalizedWorkout(
      selectedGoal,
      selectedLevel,
      weightKg: _weightKg,
    );
    final nextPlan = _buildWeeklyPlan(plan);
    setState(() {
      _aiWorkoutPlan = plan;
      _weeklyPlan = nextPlan;
      _initializePlanProgress(nextPlan, reset: true);
      _isLoading = false;
    });
    await _persistPlanProgress();
    await _persistSavedWeeklyPlan();

    try {
      await _backendApiService.addMyNotification(
        title: 'AI đã tạo kế hoạch mới',
        message:
            'Kế hoạch tập luyện đã được cập nhật theo mục tiêu và cân nặng hiện tại.',
        isImportant: true,
      );
    } catch (e) {
      debugPrint('save ai workout notification failed: $e');
    }
  }

  List<String> _extractExercises(String raw) {
    final lines = raw.split('\n');
    final extracted = <String>[];
    final numbered = RegExp(r'^\s*\d+\.\s*(.+)$');
    for (final line in lines) {
      final match = numbered.firstMatch(line);
      if (match == null) continue;
      final text = (match.group(1) ?? '').trim();
      if (text.isNotEmpty) {
        extracted.add(text);
      }
    }
    if (extracted.isNotEmpty) {
      return extracted;
    }

    // Fallback when response is free text without numbering.
    for (final line in lines) {
      final text = line.trim();
      if (text.isEmpty) continue;
      if (text.length < 4) continue;
      if (text.toLowerCase().startsWith('nguon:')) continue;
      if (text.toLowerCase().startsWith('lich de xuat:')) continue;
      extracted.add(text);
      if (extracted.length >= 8) break;
    }
    return extracted;
  }

  String _translateExerciseName(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('squat bodyweight')) {
      return 'Squat với trọng lượng cơ thể';
    }
    if (lower.contains('push-up')) {
      return 'Hít đất';
    }
    if (lower.contains('plank')) {
      return 'Plank (giữ thân người)';
    }
    if (lower.contains('dumbbell row')) {
      return 'Kéo tạ đơn (Dumbbell Row)';
    }
    if (lower.contains('row dây')) {
      return 'Kéo cáp (Row dây)';
    }
    if (lower.contains('glute bridge')) {
      return 'Nâng hông (Glute Bridge)';
    }
    if (lower.contains('cycling')) {
      return 'Đạp xe';
    }
    if (lower.contains('walking')) {
      return 'Đi bộ';
    }
    if (lower.contains('running') || lower.contains('run')) {
      return 'Chạy bộ';
    }
    if (lower.contains('yoga')) {
      return 'Yoga';
    }
    return input;
  }

  String _translateCategory(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('legs')) return 'Chân';
    if (lower.contains('chest')) return 'Ngực';
    if (lower.contains('back')) return 'Lưng';
    if (lower.contains('core')) return 'Cơ trung tâm';
    if (lower.contains('shoulder')) return 'Vai';
    if (lower.contains('arms')) return 'Tay';
    return input;
  }

  String _translateExerciseLine(String raw) {
    var text = raw.trim();
    // Strong translation fallback for API text variants.
    final replacements = <String, String>{
      'Squat bodyweight': 'Squat với trọng lượng cơ thể',
      'Push-up': 'Hít đất',
      'Push up': 'Hít đất',
      'Plank': 'Plank (giữ thân người)',
      'Dumbbell Row': 'Kéo tạ đơn',
      'Row dây': 'Kéo cáp',
      'Glute Bridge': 'Nâng hông',
      'Lower body': 'Thân dưới',
      'Legs': 'Chân',
      'Chest': 'Ngực',
      'Back': 'Lưng',
      'Core': 'Cơ trung tâm',
      'reps': 'lần',
    };
    replacements.forEach((k, v) {
      text = text.replaceAll(k, v);
    });

    final match = RegExp(r'^(.+?)\s*\(([^)]+)\)$').firstMatch(text);
    if (match != null) {
      final name = (match.group(1) ?? '').trim();
      final category = (match.group(2) ?? '').trim();
      final viName = _translateExerciseName(name);
      final viCategory = _translateCategory(category);
      return '$viName ($viCategory)';
    }
    return _translateExerciseName(text);
  }

  String _viLevelLabel(String input) {
    final lower = input.toLowerCase().trim();
    if (lower == 'beginner') return 'Mới bắt đầu';
    if (lower == 'intermediate') return 'Trung cấp';
    if (lower == 'advanced') return 'Nâng cao';
    return input;
  }

  String _viDayLabel(String input) {
    final lower = input.toLowerCase().trim();
    if (lower == 'thu 2') return 'Thứ 2';
    if (lower == 'thu 3') return 'Thứ 3';
    if (lower == 'thu 4') return 'Thứ 4';
    if (lower == 'thu 5') return 'Thứ 5';
    if (lower == 'thu 6') return 'Thứ 6';
    if (lower == 'thu 7') return 'Thứ 7';
    if (lower == 'chu nhat') return 'Chủ nhật';
    return input;
  }

  String _translatePlanItemText(String input) {
    var text = input;
    final replacements = <Pattern, String>{
      RegExp(r'squat bodyweight', caseSensitive: false):
          'Squat với trọng lượng cơ thể',
      RegExp(r'push\s*-?\s*up', caseSensitive: false): 'Hít đất',
      RegExp(r'plank', caseSensitive: false): 'Plank (giữ thân người)',
      RegExp(r'dumbbell row', caseSensitive: false): 'Kéo tạ đơn',
      RegExp(r'glute bridge', caseSensitive: false): 'Nâng hông',
      RegExp(r'lower body', caseSensitive: false): 'Thân dưới',
      RegExp(r'legs', caseSensitive: false): 'Chân',
      RegExp(r'chest', caseSensitive: false): 'Ngực',
      RegExp(r'back', caseSensitive: false): 'Lưng',
      RegExp(r'core', caseSensitive: false): 'Cơ trung tâm',
      RegExp(r'\breps\b', caseSensitive: false): 'lần',
      RegExp(r'\bhiep\b', caseSensitive: false): 'hiệp',
      RegExp(r'\bnghi chu dong\b', caseSensitive: false): 'Nghỉ chủ động',
      RegExp(r'\bdi bo nhe\b', caseSensitive: false): 'đi bộ nhẹ',
      RegExp(r'\bgian co\b', caseSensitive: false): 'giãn cơ',
    };
    replacements.forEach((pattern, replacement) {
      text = text.replaceAll(pattern, replacement);
    });
    return text;
  }

  String _workPrescription({required bool firstExercise}) {
    final goal = _goalOptions[_selectedGoalIndex].$1.toLowerCase();
    final level = _levelOptions[_selectedLevelIndex].$1.toLowerCase();

    final isBeginner = level.contains('mới bắt đầu');
    final isAdvanced = level.contains('nâng cao');

    if (goal.contains('giảm mỡ')) {
      if (isAdvanced) {
        return firstExercise ? '4 hiệp x 12-15 lần' : '4 hiệp x 10-12 lần';
      }
      if (isBeginner) {
        return firstExercise ? '3 hiệp x 10-12 lần' : '3 hiệp x 8-10 lần';
      }
      return firstExercise ? '4 hiệp x 10-12 lần' : '3 hiệp x 10-12 lần';
    }

    if (goal.contains('tăng cơ')) {
      if (isAdvanced) {
        return firstExercise ? '5 hiệp x 6-8 lần' : '4 hiệp x 8-10 lần';
      }
      if (isBeginner) {
        return firstExercise ? '3 hiệp x 8-10 lần' : '3 hiệp x 10-12 lần';
      }
      return firstExercise ? '4 hiệp x 8-10 lần' : '4 hiệp x 10-12 lần';
    }

    if (goal.contains('sức bền')) {
      if (isAdvanced) {
        return firstExercise ? '4 hiệp x 15-20 lần' : '4 hiệp x 12-15 lần';
      }
      if (isBeginner) {
        return firstExercise ? '3 hiệp x 12-15 lần' : '3 hiệp x 10-12 lần';
      }
      return firstExercise ? '4 hiệp x 12-15 lần' : '3 hiệp x 12-15 lần';
    }

    if (isAdvanced) {
      return firstExercise ? '4 hiệp x 10-12 lần' : '4 hiệp x 8-10 lần';
    }
    if (isBeginner) {
      return firstExercise ? '3 hiệp x 8-10 lần' : '3 hiệp x 8-10 lần';
    }
    return firstExercise ? '4 hiệp x 8-10 lần' : '3 hiệp x 10-12 lần';
  }

  String _dayFocusLabel(int index) {
    final goal = _goalOptions[_selectedGoalIndex].$1.toLowerCase();
    if (goal.contains('giảm mỡ')) {
      const labels = [
        'Đốt mỡ toàn thân',
        'Sức bền + nhịp tim',
        'Core + chân',
        'Đốt mỡ tăng tốc',
      ];
      return labels[index % labels.length];
    }
    if (goal.contains('tăng cơ')) {
      const labels = [
        'Push (Ngực - Vai - Tay sau)',
        'Pull (Lưng - Tay trước)',
        'Chân + Mông',
        'Sức mạnh tổng hợp',
      ];
      return labels[index % labels.length];
    }
    if (goal.contains('sức bền')) {
      const labels = [
        'Cardio nền',
        'Sức bền cơ bắp',
        'Core ổn định',
        'Cardio biến tốc',
      ];
      return labels[index % labels.length];
    }
    const labels = [
      'Duy trì thể lực',
      'Sức mạnh cơ bản',
      'Độ linh hoạt',
      'Vận động toàn thân',
    ];
    return labels[index % labels.length];
  }

  List<_DayWorkoutPlan> _buildWeeklyPlan(String raw) {
    final exercises = _extractExercises(raw);
    final days = <String>[
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    if (exercises.isEmpty) {
      return days
          .map(
            (day) => _DayWorkoutPlan(
              day: day,
              items: const ['Khởi động 10 phút và đi bộ nhẹ 20 phút.'],
            ),
          )
          .toList(growable: false);
    }

    final sessionSlots = <int>{};
    if (_sessionsPerWeek >= 6) {
      sessionSlots.addAll(const [0, 1, 2, 4, 5, 6]);
    } else if (_sessionsPerWeek == 5) {
      sessionSlots.addAll(const [0, 1, 3, 4, 6]);
    } else if (_sessionsPerWeek == 4) {
      sessionSlots.addAll(const [0, 2, 4, 6]);
    } else {
      sessionSlots.addAll(const [0, 3, 5]);
    }

    return List<_DayWorkoutPlan>.generate(days.length, (index) {
      if (!sessionSlots.contains(index)) {
        return _DayWorkoutPlan(
          day: days[index],
          items: const ['Nghỉ chủ động: đi bộ nhẹ và giãn cơ 15 phút.'],
        );
      }
      final base = exercises[index % exercises.length];
      final second = exercises[(index + 1) % exercises.length];
      final baseVi = _translateExerciseLine(base);
      final secondVi = _translateExerciseLine(second);
      final firstPrescription = _workPrescription(firstExercise: true);
      final secondPrescription = _workPrescription(firstExercise: false);
      final firstKcal = _estimateAiExerciseCalories(baseVi);
      final secondKcal = _estimateAiExerciseCalories(secondVi);
      final focus = _dayFocusLabel(index);
      return _DayWorkoutPlan(
        day: days[index],
        items: [
          'Trọng tâm: $focus',
          '$baseVi - $firstPrescription • ~$firstKcal kcal',
          '$secondVi - $secondPrescription • ~$secondKcal kcal',
        ],
      );
    });
  }

  Future<void> _saveWeeklyPlanToJournal() async {
    if (_weeklyPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy tạo kế hoạch trước khi lưu.')),
      );
      return;
    }

    setState(() => _isSavingPlan = true);
    try {
      final completedCalories = _plannedCheckedCalories();
      final plannedCalories = _plannedTotalCalories();
      final savedCalories =
          completedCalories > 0 ? completedCalories : plannedCalories;
      final note = _buildWeeklyPlanNote();
      final noteSignature = _normalizePlanNote(note);
      final today = DateTime.now();
      final existingSamePlanIndex = _findWeeklyPlanHistoryIndex(
        normalizedNote: noteSignature,
        weekDate: today,
      );
      final previousItem =
          existingSamePlanIndex >= 0 ? _history[existingSamePlanIndex] : null;
      final timestamp =
          previousItem?.timestampMs ?? today.millisecondsSinceEpoch;
      final performedAt = previousItem?.timestampMs == null
          ? today
          : DateTime.fromMillisecondsSinceEpoch(previousItem!.timestampMs!);
      final cloudId = previousItem?.cloudId;
      final duration = '$_sessionsPerWeek buổi';
      final historyItem = WorkoutHistoryItem(
        name: 'Kế hoạch tập tuần',
        date: _todayLabel(),
        duration: duration,
        kcal: '$savedCalories',
        timestampMs: timestamp,
        cloudId: cloudId,
        note: note,
      );

      final updatedHistory = List<WorkoutHistoryItem>.from(_history);
      if (existingSamePlanIndex >= 0) {
        updatedHistory[existingSamePlanIndex] = historyItem;
      } else {
        updatedHistory.insert(0, historyItem);
      }
      final cappedHistory = updatedHistory.take(50).toList(growable: false);
      if (mounted) {
        setState(() {
          _history = cappedHistory;
        });
      }
      await _persistWorkoutHistoryList(cappedHistory);

      try {
        if (previousItem?.cloudId != null &&
            previousItem!.cloudId!.isNotEmpty) {
          await _backendApiService.updateMyWorkout(
            workoutId: previousItem.cloudId!,
            workout: WorkoutRecord(
              id: previousItem.cloudId!,
              name: 'Kế hoạch tập tuần',
              durationMinutes: _sessionsPerWeek * 30,
              caloriesBurned: savedCalories.toDouble(),
              performedAt: performedAt,
              note: note,
            ),
          );
        } else {
          final cloudId = await _backendApiService.addMyWorkout(
            WorkoutRecord(
              id: '',
              name: 'Kế hoạch tập tuần',
              durationMinutes: _sessionsPerWeek * 30,
              caloriesBurned: savedCalories.toDouble(),
              performedAt: performedAt,
              note: note,
            ),
          );
          if (mounted) {
            final refreshed = List<WorkoutHistoryItem>.from(_history);
            final targetIndex =
                existingSamePlanIndex >= 0 ? existingSamePlanIndex : 0;
            if (targetIndex >= 0 && targetIndex < refreshed.length) {
              refreshed[targetIndex] = WorkoutHistoryItem(
                name: historyItem.name,
                date: historyItem.date,
                duration: historyItem.duration,
                kcal: historyItem.kcal,
                timestampMs: historyItem.timestampMs,
                cloudId: cloudId,
                note: historyItem.note,
              );
              setState(
                  () => _history = refreshed.take(50).toList(growable: false));
            }
          }
        }
      } catch (_) {
        // Keep local history entry even if cloud sync fails.
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu kế hoạch vào lịch sử tập luyện.')),
      );
      MainNavigationController().setIndex(1);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu kế hoạch.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingPlan = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final programs = _workoutController.getPrograms(context);
    final bool aiEnabled = _aiController.isAiConfigured;
    final history = _history;
    final filteredHistory = _applyHistoryFilter(history);
    final weekHistory = _currentWeekHistory(history);
    final weekRealSessions = weekHistory
        .where((e) => !_isWeeklyPlanHistoryItem(e))
        .toList(growable: false);
    final latestPlan = _latestSavedWeeklyPlan(weekHistory);
    final historySessions = weekRealSessions.length;
    final historyKcal = weekRealSessions.fold<int>(
      0,
      (sum, e) => sum + _parseKcalInt(e.kcal),
    );
    final planSessions = _plannedCompletedSessions();
    final planKcal = _plannedCheckedCalories();
    final weekSessions =
        _weeklyPlan.isNotEmpty ? planSessions : historySessions;
    final weekKcal = _weeklyPlan.isNotEmpty ? planKcal : historyKcal;
    final targetFromHistory = _extractSessionsFromDuration(
      latestPlan?.duration ?? '',
    );
    final weekTargetSessions = targetFromHistory > 0
        ? targetFromHistory
        : (_weeklyPlan.isNotEmpty ? _sessionsPerWeek : 5);
    final weeklyCaloriesByDay = _weeklyCaloriesByWeekday(weekRealSessions);
    final maxDailyCalories = weeklyCaloriesByDay.values.fold<int>(
      0,
      (maxValue, value) => value > maxValue ? value : maxValue,
    );
    final List<WorkoutItem> shownPrograms = _selectedProgramFilter == -1
        ? programs
        : <WorkoutItem>[programs[_selectedProgramFilter]];
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 150),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.isDesktop(context) ? 800 : 600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopBar(
                    title: AppStrings.workoutScreenTitle(context),
                    onUserTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.profile),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.84),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 122,
                          child: PageView(
                            controller: _goalBannerController,
                            onPageChanged: (index) {
                              _goalBannerIndex.value = index;
                            },
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$weekSessions/$weekTargetSessions Buổi tập',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$weekKcal kcal đã đốt',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tiến độ ${(_planProgressRatio() * 100).round()}%',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary
                                          .withValues(alpha: 0.92),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Builder(
                                builder: (context) {
                                  final streakDays = _aiPlanStreakDays();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: colorScheme.onPrimary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'AI Streak',
                                            style: TextStyle(
                                              color: colorScheme.onPrimary
                                                  .withValues(alpha: 0.9),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '$streakDays Ngày tập luyện',
                                              maxLines: 1,
                                              style: TextStyle(
                                                color: colorScheme.onPrimary,
                                                fontSize: 34,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _aiStreakDescription(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colorScheme.onPrimary
                                              .withValues(alpha: 0.9),
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Calories theo ngày',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary
                                          .withValues(alpha: 0.92),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$weekKcal kcal tuần này',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary
                                          .withValues(alpha: 0.86),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: List.generate(7, (index) {
                                        final weekday = DateTime.monday + index;
                                        final labels = const [
                                          'T2',
                                          'T3',
                                          'T4',
                                          'T5',
                                          'T6',
                                          'T7',
                                          'CN',
                                        ];
                                        final value =
                                            weeklyCaloriesByDay[weekday] ?? 0;
                                        final ratio = maxDailyCalories == 0
                                            ? 0.0
                                            : value / maxDailyCalories;
                                        final barHeight = 6 + (ratio * 36);

                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  height: barHeight,
                                                  decoration: BoxDecoration(
                                                    color: value > 0
                                                        ? colorScheme.onPrimary
                                                        : colorScheme.onPrimary
                                                            .withValues(
                                                                alpha: 0.28),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  labels[index],
                                                  style: TextStyle(
                                                    color: colorScheme.onPrimary
                                                        .withValues(
                                                            alpha: 0.92),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ValueListenableBuilder<int>(
                          valueListenable: _goalBannerIndex,
                          builder: (context, currentIndex, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                final active = currentIndex == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: active ? 18 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: active
                                        ? colorScheme.onPrimary
                                        : colorScheme.onPrimary
                                            .withValues(alpha: 0.45),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // AI Workout Suggestion Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.aiWorkoutSuggestionTitle(context),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _weightKg == null
                              ? 'Chưa cập nhật cân nặng. Gợi ý sẽ ở mức chung.'
                              : 'Cân nặng hiện tại: ${_weightKg!.toStringAsFixed(1)} kg (gợi ý theo cân nặng).',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mục tiêu tập luyện',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_goalOptions.length, (index) {
                            final selected = _selectedGoalIndex == index;
                            return ChoiceChip(
                              label: Text(_goalOptions[index].$1),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedGoalIndex = index;
                                  _aiWorkoutPlan = null;
                                  _weeklyPlan = const [];
                                  _planProgress = <String, bool>{};
                                });
                                _persistPlanProgress();
                                _clearSavedWeeklyPlan();
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Trình độ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              List.generate(_levelOptions.length, (index) {
                            final selected = _selectedLevelIndex == index;
                            return ChoiceChip(
                              label:
                                  Text(_viLevelLabel(_levelOptions[index].$1)),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedLevelIndex = index;
                                  _aiWorkoutPlan = null;
                                  _weeklyPlan = const [];
                                  _planProgress = <String, bool>{};
                                });
                                _persistPlanProgress();
                                _clearSavedWeeklyPlan();
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Số buổi/tuần: $_sessionsPerWeek',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            DropdownButton<int>(
                              value: _sessionsPerWeek,
                              items: const [3, 4, 5]
                                  .map(
                                    (v) => DropdownMenuItem<int>(
                                      value: v,
                                      child: Text('$v buổi'),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _sessionsPerWeek = value;
                                  if (_aiWorkoutPlan != null) {
                                    final nextPlan =
                                        _buildWeeklyPlan(_aiWorkoutPlan!);
                                    _weeklyPlan = nextPlan;
                                    _initializePlanProgress(nextPlan,
                                        reset: true);
                                  }
                                });
                                _persistPlanProgress();
                                _persistSavedWeeklyPlan();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_weeklyPlan.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (context) {
                                  final ratio = _planProgressRatio();
                                  final percent = (ratio * 100).round();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tiến độ kế hoạch: $percent%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: ratio,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Kế hoạch theo ngày',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._weeklyPlan.map(
                                (dayPlan) => Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _viDayLabel(dayPlan.day),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...dayPlan.items.map(
                                        (item) => _isExerciseTask(item)
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 2),
                                                child: CheckboxListTile(
                                                  value: _planProgress[
                                                          _planProgressKey(
                                                              dayPlan.day,
                                                              item)] ==
                                                      true,
                                                  dense: true,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  controlAffinity:
                                                      ListTileControlAffinity
                                                          .leading,
                                                  title: Text(
                                                      _translatePlanItemText(
                                                          item)),
                                                  onChanged: (checked) {
                                                    setState(() {
                                                      _planProgress[
                                                              _planProgressKey(
                                                                  dayPlan.day,
                                                                  item)] =
                                                          checked == true;
                                                    });
                                                    _persistPlanProgress();
                                                  },
                                                ),
                                              )
                                            : Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4),
                                                child: Text(
                                                    '- ${_translatePlanItemText(item)}'),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(AppStrings.aiWorkoutSuggestionHint(context)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: aiEnabled ? _getAIWorkout : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              aiEnabled
                                  ? AppStrings.aiGeneratePlanButton(context)
                                  : 'AI tam khoa: thieu GEMINI_API_KEY',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isSavingPlan ? null : _saveWeeklyPlanToJournal,
                            icon: _isSavingPlan
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text(
                                'Lưu kế hoạch vào lịch sử tập luyện'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.programModesTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _selectedProgramFilter == -1,
                        onSelected: (_) {
                          setState(() => _selectedProgramFilter = -1);
                        },
                      ),
                      ...List.generate(programs.length, (index) {
                        final selected = _selectedProgramFilter == index;
                        return ChoiceChip(
                          label: Text(programs[index].title),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedProgramFilter = index);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    itemCount: shownPrograms.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (_, index) => InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _logWorkoutSession(shownPrograms[index]),
                      child: WorkoutCard(item: shownPrograms[index]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.workoutHistoryTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _historyFilterDays == 0,
                        onSelected: (_) =>
                            setState(() => _historyFilterDays = 0),
                      ),
                      ChoiceChip(
                        label: const Text('7 ngày'),
                        selected: _historyFilterDays == 7,
                        onSelected: (_) =>
                            setState(() => _historyFilterDays = 7),
                      ),
                      ChoiceChip(
                        label: const Text('30 ngày'),
                        selected: _historyFilterDays == 30,
                        onSelected: (_) =>
                            setState(() => _historyFilterDays = 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          _history.isEmpty ? null : _confirmClearAllHistory,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Xóa toàn bộ'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filteredHistory.isEmpty)
                    Text(
                      'Chưa có dữ liệu cho bộ lọc này.',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ...filteredHistory.asMap().entries.map(
                        (pair) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey(
                              '${pair.value.name}|${pair.value.date}|${pair.value.duration}|${pair.value.kcal}|${pair.value.timestampMs ?? pair.key}',
                            ),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Xóa',
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Xóa mục lịch sử'),
                                  content: const Text(
                                      'Bạn có chắc muốn xóa mục lịch sử buổi tập này?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext)
                                              .pop(false),
                                      child: const Text('Hủy'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              return ok == true;
                            },
                            onDismissed: (_) =>
                                _deleteHistoryAt(pair.key, filteredHistory),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _showHistoryDetails(pair.value),
                              child: HistoryTile(item: pair.value),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
