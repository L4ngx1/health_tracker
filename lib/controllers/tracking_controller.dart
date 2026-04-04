import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/localization/locale_service.dart';
import '../l10n/app_localizations.dart';
import '../models/sleep_session.dart';
import '../services/health_cloud_sync_service.dart';
import '../services/widget_sync_service.dart';

const _trackingTask = 'tracking_background_task';
const _prefSteps = 'tracking.steps';
const _prefStepBase = 'tracking.stepBase';
const _prefDistance = 'tracking.distanceMeters';
const _prefLastLat = 'tracking.lastLat';
const _prefLastLon = 'tracking.lastLon';
const _prefSleepMinutes = 'tracking.sleepMinutes';
const _prefSleepSessionStart = 'tracking.sleepSessionStart';
const _prefSleepHistory = 'tracking.sleepHistory';
const _prefCaloriesKcal = 'tracking.caloriesKcal';
const _prefWeightKg = 'profile.weightKg';
const _prefDayKey = 'tracking.dayKey';
const _prefGoalType = 'tracking.goalType';
const _prefGoalValue = 'tracking.goalValue';
const _prefMigrationDone = 'tracking.migration.v1';

enum DailyGoalType { steps, distanceKm }

const _defaultStepGoal = 8000.0;
const _defaultDistanceGoalKm = 6.0;
// Điểm vào (entry point) cho Workmanager khi tác vụ chạy nền được hệ điều hành kích hoạt.
@pragma('vm:entry-point')
void trackingCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return true;
  });
}

bool get _supportsRealtimeTrackingOnCurrentPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool get _supportsWorkmanagerOnCurrentPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

@immutable
class TrackingSnapshot {
  const TrackingSnapshot({
    required this.steps,
    required this.distanceMeters,
    required this.caloriesKcal,
    required this.speedMps,
    required this.grade,
    required this.sleepMinutes,
    required this.isSleeping,
    required this.goalType,
    required this.goalValue,
    this.lastUpdate,
  });

  const TrackingSnapshot.initial()
      : steps = 0,
        distanceMeters = 0.0,
        caloriesKcal = 0.0,
        speedMps = 0.0,
        grade = 0.0,
        sleepMinutes = 0,
        isSleeping = false,
        goalType = DailyGoalType.steps,
        goalValue = _defaultStepGoal,
        lastUpdate = null;

  final int steps;
  final double distanceMeters;
  final double caloriesKcal;
  final double speedMps;
  final double grade;
  final int sleepMinutes;
  final bool isSleeping;
  final DailyGoalType goalType;
  final double goalValue;
  final DateTime? lastUpdate;

  TrackingSnapshot copyWith({
    int? steps,
    double? distanceMeters,
    double? caloriesKcal,
    double? speedMps,
    double? grade,
    int? sleepMinutes,
    bool? isSleeping,
    DailyGoalType? goalType,
    double? goalValue,
    DateTime? lastUpdate,
  }) {
    return TrackingSnapshot(
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      speedMps: speedMps ?? this.speedMps,
      grade: grade ?? this.grade,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      isSleeping: isSleeping ?? this.isSleeping,
      goalType: goalType ?? this.goalType,
      goalValue: goalValue ?? this.goalValue,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class TrackingController {
  final HealthCloudSyncService _cloudSync = HealthCloudSyncService();
  DateTime? _lastCloudSyncAt;

  AppLocalizations get _l10n =>
      lookupAppLocalizations(LocaleService.instance.locale.value);

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _scopedKey(String base) => '$base.$_userScope';
  String get _migrationKey => '$_prefMigrationDone.$_userScope';

  DailyGoalType _goalTypeFromString(String? raw) {
    if (raw == DailyGoalType.distanceKm.name) {
      return DailyGoalType.distanceKm;
    }
    return DailyGoalType.steps;
  }

  TrackingController();

  final ValueNotifier<TrackingSnapshot> snapshot =
      ValueNotifier<TrackingSnapshot>(const TrackingSnapshot.initial());
  final ValueNotifier<List<SleepSession>> sleepHistory =
      ValueNotifier<List<SleepSession>>(<SleepSession>[]);

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isDisposed = false;
  StreamSubscription<Position>? _positionSub;
  int? _stepBase;
  int _distanceStepAnchor = 0;
  DateTime? _lastStepIncreaseAt;
  double? _lastLat;
  double? _lastLon;
  double? _lastAltitude;
  DateTime? _lastPositionAt;
  double? _smoothedSpeedMps;
  double? _smoothedGrade;
  double? _weightKg;
  DateTime _currentDay = _truncateToDay(DateTime.now());
  DateTime? _currentEpochMinute;
  DateTime? _lastMovementSpikeAt;
  int _movementCountCurrentMinute = 0;
  int _stepsCurrentMinute = 0;
  final Map<int, int> _activityByMinute = <int, int>{};
  final Map<int, int> _stepsByMinute = <int, int>{};
  final Set<int> _finalizedSleepMinutes = <int>{};
  SharedPreferences? _prefs;
  DateTime? _sleepSessionStart;

  static const double _movementThreshold = 0.45;
  static const int _spikeCooldownMs = 800;
  static const double _sleepScoreThreshold = 3.2;
  static const int _windowKeepMinutes = 180;
  static const int _stepWakeThresholdPerMinute = 8;
  static const double _maxAcceptedAccuracyMeters = 15.0;
  static const double _minMovementDistanceMeters = 3.0;
  static const double _maxSingleJumpMeters = 60.0;
  static const double _maxStationaryDriftMeters = 10.0;
  static const int _stepMovementFreshSeconds = 75;
  static const double _minSpeedMetersPerSecond = 0.9;
  static const double _speedSmoothingFactor = 0.25;
  static const double _gradeSmoothingFactor = 0.2;
  static const double _maxGradeAbs = 0.15;

  bool get isDisposed => _isDisposed;

  Future<void> _syncDistanceWidget() {
    final double distanceKm = snapshot.value.distanceMeters / 1000.0;
    final int steps = snapshot.value.steps;
    final int calories = snapshot.value.caloriesKcal.round();
    final double goalKm = snapshot.value.goalType == DailyGoalType.distanceKm
        ? snapshot.value.goalValue
        : _defaultDistanceGoalKm;

    return WidgetSyncService.instance.syncDistanceCard(
      steps: steps,
      distanceKm: distanceKm,
      calories: calories,
      goalKm: goalKm,
    );
  }

  Future<void> _migrateLegacyTrackingIfNeeded() async {
    if (_prefs == null) return;
    if (_prefs!.getBool(_migrationKey) == true) return;

    final scopedSamples = <String>[
      _scopedKey(_prefSteps),
      _scopedKey(_prefStepBase),
      _scopedKey(_prefDistance),
      _scopedKey(_prefSleepMinutes),
      _scopedKey(_prefGoalType),
      _scopedKey(_prefGoalValue),
    ];
    final hasScoped = scopedSamples.any(_prefs!.containsKey);

    if (!hasScoped) {
      if (_prefs!.containsKey(_prefSteps)) {
        final v = _prefs!.getInt(_prefSteps);
        if (v != null) await _prefs!.setInt(_scopedKey(_prefSteps), v);
      }
      if (_prefs!.containsKey(_prefStepBase)) {
        final v = _prefs!.getInt(_prefStepBase);
        if (v != null) await _prefs!.setInt(_scopedKey(_prefStepBase), v);
      }
      if (_prefs!.containsKey(_prefDistance)) {
        final v = _prefs!.getDouble(_prefDistance);
        if (v != null) await _prefs!.setDouble(_scopedKey(_prefDistance), v);
      }
      if (_prefs!.containsKey(_prefSleepMinutes)) {
        final v = _prefs!.getInt(_prefSleepMinutes);
        if (v != null) {
          await _prefs!.setInt(_scopedKey(_prefSleepMinutes), v);
        }
      }
      if (_prefs!.containsKey(_prefGoalType)) {
        final v = _prefs!.getString(_prefGoalType);
        if (v != null && v.isNotEmpty) {
          await _prefs!.setString(_scopedKey(_prefGoalType), v);
        }
      }
      if (_prefs!.containsKey(_prefGoalValue)) {
        final v = _prefs!.getDouble(_prefGoalValue);
        if (v != null) await _prefs!.setDouble(_scopedKey(_prefGoalValue), v);
      }
      if (_prefs!.containsKey(_prefDayKey)) {
        final v = _prefs!.getString(_prefDayKey);
        if (v != null && v.isNotEmpty) {
          await _prefs!.setString(_scopedKey(_prefDayKey), v);
        }
      }
      if (_prefs!.containsKey(_prefLastLat)) {
        final v = _prefs!.getDouble(_prefLastLat);
        if (v != null) await _prefs!.setDouble(_scopedKey(_prefLastLat), v);
      }
      if (_prefs!.containsKey(_prefLastLon)) {
        final v = _prefs!.getDouble(_prefLastLon);
        if (v != null) await _prefs!.setDouble(_scopedKey(_prefLastLon), v);
      }
    }

    await _prefs!.setBool(_migrationKey, true);
  }

  Future<void> _mergeTodayFromCloud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final cloud = await _cloudSync.loadTodayTracking(uid: uid);
      if (cloud == null || _isDisposed) return;

      final current = snapshot.value;
      final cloudGoalType = cloud.goalType == null
          ? current.goalType
          : _goalTypeFromString(cloud.goalType);
      final cloudGoalValue = cloud.goalValue == null
          ? current.goalValue
          : _normalizeGoalValue(cloudGoalType, cloud.goalValue!);

      final merged = current.copyWith(
        steps: max(current.steps, cloud.steps ?? 0),
        distanceMeters: max(current.distanceMeters, cloud.distanceMeters ?? 0),
        sleepMinutes: max(current.sleepMinutes, cloud.sleepMinutes ?? 0),
        goalType: cloudGoalType,
        goalValue: cloudGoalValue,
        lastUpdate: DateTime.now(),
      );

      _safeSetSnapshot(merged);
      await _prefs?.setInt(_scopedKey(_prefSteps), merged.steps);
      await _prefs?.setDouble(_scopedKey(_prefDistance), merged.distanceMeters);
      await _prefs?.setInt(_scopedKey(_prefSleepMinutes), merged.sleepMinutes);
      await _prefs?.setString(_scopedKey(_prefGoalType), merged.goalType.name);
      await _prefs?.setDouble(_scopedKey(_prefGoalValue), merged.goalValue);
      await _prefs?.setString(_scopedKey(_prefDayKey), _dayKey(DateTime.now()));
      unawaited(_syncDistanceWidget());
    } catch (e) {
      debugPrint(_l10n.trackingLogCloudMergeFailed('$e'));
    }
  }

  void _syncTodayToCloud({bool force = false}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    if (!force &&
        _lastCloudSyncAt != null &&
        now.difference(_lastCloudSyncAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastCloudSyncAt = now;

    final current = snapshot.value;
    unawaited(
      _cloudSync
          .saveTodayTracking(
        uid: uid,
        steps: current.steps,
        distanceMeters: current.distanceMeters,
        sleepMinutes: current.sleepMinutes,
        goalType: current.goalType.name,
        goalValue: current.goalValue,
      )
          .catchError((Object e) {
        debugPrint(_l10n.trackingLogCloudSaveFailed('$e'));
      }),
    );
  }

  void _safeSetSnapshot(TrackingSnapshot newValue) {
    if (_isDisposed) return;
    try {
      snapshot.value = newValue;
    } catch (_) {}
  }

  void _safeUpdateSnapshot(
    TrackingSnapshot Function(TrackingSnapshot) updater,
  ) {
    if (_isDisposed) return;
    try {
      snapshot.value = updater(snapshot.value);
    } catch (_) {}
  }

  static DateTime _truncateToDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  double _normalizeGoalValue(DailyGoalType type, double value) {
    if (type == DailyGoalType.steps) {
      final rounded = (value / 100).round() * 100;
      return rounded.clamp(1000, 50000).toDouble();
    }
    final normalized = (value * 10).round() / 10;
    return normalized.clamp(1.0, 50.0).toDouble();
  }

  double _backgroundDeg2rad(double deg) => deg * (pi / 180.0);

  double _backgroundDistanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000;
    final dLat = _backgroundDeg2rad(lat2 - lat1);
    final dLon = _backgroundDeg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_backgroundDeg2rad(lat1)) *
            cos(_backgroundDeg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> setDailyGoal({
    required DailyGoalType type,
    required double value,
  }) async {
    final normalized = _normalizeGoalValue(type, value);
    snapshot.value = snapshot.value.copyWith(
      goalType: type,
      goalValue: normalized,
      lastUpdate: DateTime.now(),
    );
    await _prefs?.setString(_scopedKey(_prefGoalType), type.name);
    await _prefs?.setDouble(_scopedKey(_prefGoalValue), normalized);
    _syncTodayToCloud(force: true);
    unawaited(_syncDistanceWidget());
  }

  Future<void> resetTodayMovement() async {
    final DateTime now = DateTime.now();
    final String todayKey = _dayKey(now);

    if (_stepBase != null) {
      _stepBase = _stepBase! + snapshot.value.steps;
      await _prefs?.setInt(_scopedKey(_prefStepBase), _stepBase!);
    } else {
      await _prefs?.remove(_scopedKey(_prefStepBase));
    }

    _lastLat = null;
    _lastLon = null;
    _lastAltitude = null;
    _lastPositionAt = null;
    await _prefs?.remove(_scopedKey(_prefLastLat));
    await _prefs?.remove(_scopedKey(_prefLastLon));

    _stepsCurrentMinute = 0;
    _stepsByMinute.clear();
    _distanceStepAnchor = 0;
    _lastStepIncreaseAt = null;

    _safeUpdateSnapshot(
      (current) => current.copyWith(
        steps: 0,
        distanceMeters: 0.0,
        caloriesKcal: 0.0,
        speedMps: 0.0,
        grade: 0.0,
        lastUpdate: now,
      ),
    );

    await _prefs?.setInt(_scopedKey(_prefSteps), 0);
    await _prefs?.setDouble(_scopedKey(_prefDistance), 0.0);
    await _prefs?.setDouble(_scopedKey(_prefCaloriesKcal), 0.0);
    await _prefs?.setString(_scopedKey(_prefDayKey), todayKey);

    _syncTodayToCloud(force: true);
    await _syncDistanceWidget();
  }

  Future<void> _loadFromPrefs() async {
    if (_isDisposed) return;
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    _loadSleepHistoryFromPrefs();
    await _loadWeightFromPrefs();
    final storedDay = _prefs?.getString(_scopedKey(_prefDayKey));
    final goalType = _goalTypeFromString(
      _prefs?.getString(_scopedKey(_prefGoalType)),
    );
    final storedGoalValue = _prefs?.getDouble(_scopedKey(_prefGoalValue));
    final goalValue = _normalizeGoalValue(
      goalType,
      storedGoalValue ??
          (goalType == DailyGoalType.steps
              ? _defaultStepGoal
              : _defaultDistanceGoalKm),
    );
    if (storedDay != null && storedDay != todayKey) {
      _safeSetSnapshot(
        TrackingSnapshot.initial().copyWith(
          goalType: goalType,
          goalValue: goalValue,
        ),
      );
      if (_isDisposed) return;
      _sleepSessionStart = null;
      await _prefs?.remove(_scopedKey(_prefSleepSessionStart));
      await _prefs?.setDouble(_scopedKey(_prefCaloriesKcal), 0.0);
      await _prefs?.remove(_scopedKey(_prefLastLat));
      await _prefs?.remove(_scopedKey(_prefLastLon));
      await _prefs?.remove(_scopedKey(_prefStepBase));
      _lastLat = null;
      _lastLon = null;
      _stepBase = null;
      await _prefs?.setString(_scopedKey(_prefDayKey), todayKey);
    } else {
      final steps = _prefs?.getInt(_scopedKey(_prefSteps)) ?? 0;
      final distance = _prefs?.getDouble(_scopedKey(_prefDistance)) ?? 0.0;
      final calories = _prefs?.getDouble(_scopedKey(_prefCaloriesKcal)) ?? 0.0;
      final sleepMinutes = _prefs?.getInt(_scopedKey(_prefSleepMinutes)) ?? 0;
      final stepBase = _prefs?.getInt(_scopedKey(_prefStepBase));
      final lastLat = _prefs?.getDouble(_scopedKey(_prefLastLat));
      final lastLon = _prefs?.getDouble(_scopedKey(_prefLastLon));
      final sleepStartRaw = _prefs?.getString(
        _scopedKey(_prefSleepSessionStart),
      );
      _sleepSessionStart =
          sleepStartRaw == null ? null : DateTime.tryParse(sleepStartRaw);
      _stepBase = stepBase;
      _distanceStepAnchor = steps;
      _lastLat = lastLat;
      _lastLon = lastLon;
      if (_isDisposed) return;
      _safeUpdateSnapshot(
        (current) => current.copyWith(
          steps: steps,
          distanceMeters: distance,
          caloriesKcal: calories,
          sleepMinutes: sleepMinutes,
          isSleeping: false,
          goalType: goalType,
          goalValue: goalValue,
        ),
      );
      if (storedDay == null || storedDay.isEmpty) {
        await _prefs?.setString(_scopedKey(_prefDayKey), todayKey);
      }
      unawaited(_syncDistanceWidget());
    }
  }

  int _minuteIndex(DateTime dt) => dt.millisecondsSinceEpoch ~/ 60000;

  DateTime _minuteStart(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);

  bool _isSleepingMinute(int minuteIndex) {
    final int pMinus2 = _activityByMinute[minuteIndex - 2] ?? 0;
    final int pMinus1 = _activityByMinute[minuteIndex - 1] ?? 0;
    final int p0 = _activityByMinute[minuteIndex] ?? 0;
    final int pPlus1 = _activityByMinute[minuteIndex + 1] ?? 0;
    final int stepDelta = _stepsByMinute[minuteIndex] ?? 0;

    if (stepDelta >= _stepWakeThresholdPerMinute) {
      return false;
    }

    final double score = (0.15 * pMinus2) +
        (0.25 * pMinus1) +
        (0.4 * p0) +
        (0.2 * pPlus1) +
        (stepDelta * 0.25);
    return score < _sleepScoreThreshold;
  }

  void _finalizeSleepMinuteIfReady(int minuteIndex, DateTime now) {
    if (_finalizedSleepMinutes.contains(minuteIndex)) {
      return;
    }
    if (!_activityByMinute.containsKey(minuteIndex + 1)) {
      return;
    }

    _finalizedSleepMinutes.add(minuteIndex);
    final bool sleeping = _isSleepingMinute(minuteIndex);

    final bool wasSleeping = snapshot.value.isSleeping;

    if (sleeping) {
      if (!wasSleeping) {
        _recordSleepStart(now);
      }
      final int nextTotal = wasSleeping ? (snapshot.value.sleepMinutes + 1) : 1;
      _safeUpdateSnapshot(
        (current) => current.copyWith(
          sleepMinutes: nextTotal,
          isSleeping: true,
          lastUpdate: now,
        ),
      );
      _prefs?.setInt(_scopedKey(_prefSleepMinutes), nextTotal);
      _syncTodayToCloud();
      return;
    }

    if (wasSleeping) {
      _recordSleepEnd(now);
      _safeUpdateSnapshot(
        (current) => current.copyWith(isSleeping: false, lastUpdate: now),
      );
      _syncTodayToCloud();
    }
  }

// Lưu mốc thời gian bắt đầu ngủ vào bộ nhớ cục bộ để dùng khi tính tổng thời lượng ngủ của phiên.
  void _recordSleepStart(DateTime now) {
    _sleepSessionStart ??= _minuteStart(now);
    _prefs?.setString(
      _scopedKey(_prefSleepSessionStart),
      _sleepSessionStart!.toIso8601String(),
    );
  }

// Chốt thời gian kết thúc phiên ngủ, tạo bản ghi `SleepSession`, sắp xếp lịch sử ngủ và giới hạn số phiên lưu trữ.
  void _recordSleepEnd(DateTime now) {
    final DateTime end = _minuteStart(now);
    DateTime? start = _sleepSessionStart;
    if (start == null) {
      final int minutes = snapshot.value.sleepMinutes;
      start = end.subtract(Duration(minutes: minutes));
    }

    if (!end.isAfter(start)) {
      _sleepSessionStart = null;
      _prefs?.remove(_scopedKey(_prefSleepSessionStart));
      return;
    }

    final sessions = List<SleepSession>.from(sleepHistory.value);
    sessions.add(SleepSession(start: start, end: end));
    sessions.sort((a, b) => b.end.compareTo(a.end));
    if (sessions.length > 30) {
      sessions.removeRange(30, sessions.length);
    }
    sleepHistory.value = sessions;
    _persistSleepHistory(sessions);
    _sleepSessionStart = null;
    _prefs?.remove(_scopedKey(_prefSleepSessionStart));
  }

  void _loadSleepHistoryFromPrefs() {
    final raw = _prefs?.getString(_scopedKey(_prefSleepHistory));
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final sessions = <SleepSession>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final session = SleepSession.fromJson(item);
          if (session != null) sessions.add(session);
        } else if (item is Map) {
          final session = SleepSession.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          );
          if (session != null) sessions.add(session);
        }
      }
      sessions.sort((a, b) => b.end.compareTo(a.end));
      sleepHistory.value = sessions;
    } catch (_) {}
  }

  void _persistSleepHistory(List<SleepSession> sessions) {
    final encoded = jsonEncode(sessions.map((e) => e.toJson()).toList());
    _prefs?.setString(_scopedKey(_prefSleepHistory), encoded);
  }

  DateTime? get currentSleepStart => _sleepSessionStart;

  void _pruneSleepWindows(int currentMinuteIndex) {
    final int keepFrom = currentMinuteIndex - _windowKeepMinutes;
    _activityByMinute.removeWhere((key, _) => key < keepFrom);
    _stepsByMinute.removeWhere((key, _) => key < keepFrom);
    _finalizedSleepMinutes.removeWhere((key) => key < keepFrom);
  }

  void _resetForNewDay(DateTime now) {
    final today = _truncateToDay(now);
    _currentDay = today;

    _lastLat = null;
    _lastLon = null;
    _lastAltitude = null;
    _lastPositionAt = null;
    _stepBase = null;
    _distanceStepAnchor = 0;
    _lastStepIncreaseAt = null;

    _safeUpdateSnapshot(
      (current) => current.copyWith(
        steps: 0,
        distanceMeters: 0.0,
        caloriesKcal: 0.0,
        speedMps: 0.0,
        grade: 0.0,
        lastUpdate: now,
      ),
    );

    _prefs?.setString(_scopedKey(_prefDayKey), _dayKey(today));
    _prefs?.setInt(_scopedKey(_prefSteps), 0);
    _prefs?.setDouble(_scopedKey(_prefDistance), 0.0);
    _prefs?.setDouble(_scopedKey(_prefCaloriesKcal), 0.0);
    _prefs?.remove(_scopedKey(_prefStepBase));
    _prefs?.remove(_scopedKey(_prefLastLat));
    _prefs?.remove(_scopedKey(_prefLastLon));

    _syncTodayToCloud(force: true);
    unawaited(_syncDistanceWidget());
  }

  void _ensureToday(DateTime now) {
    final today = _truncateToDay(now);
    if (today != _currentDay) {
      _resetForNewDay(now);
      return;
    }

    final String todayKey = _dayKey(now);
    final String? storedDay = _prefs?.getString(_scopedKey(_prefDayKey));
    if (storedDay != null && storedDay.isNotEmpty && storedDay != todayKey) {
      _resetForNewDay(now);
    }
  }

  void _rollEpochWindow(DateTime now) {
    final DateTime minute = _minuteStart(now);
    _currentEpochMinute ??= minute;

    if (minute == _currentEpochMinute) {
      return;
    }

    final int previousMinuteIndex = _minuteIndex(_currentEpochMinute!);
    final int currentMinuteIndex = _minuteIndex(minute);

    _activityByMinute[previousMinuteIndex] = _movementCountCurrentMinute;
    _stepsByMinute[previousMinuteIndex] = _stepsCurrentMinute;
    _finalizeSleepMinuteIfReady(previousMinuteIndex - 1, now);

    for (int idx = previousMinuteIndex + 1; idx < currentMinuteIndex; idx++) {
      _activityByMinute[idx] = 0;
      _stepsByMinute[idx] = 0;
      _finalizeSleepMinuteIfReady(idx - 1, now);
    }

    _movementCountCurrentMinute = 0;
    _stepsCurrentMinute = 0;
    _currentEpochMinute = minute;
    _pruneSleepWindows(currentMinuteIndex);
  }

  Future<void> start() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_isDisposed) return;

    await _migrateLegacyTrackingIfNeeded();
    if (_isDisposed) return;

    await _loadFromPrefs();
    if (_isDisposed) return;
    await _mergeTodayFromCloud();
    if (_isDisposed) return;
    _syncTodayToCloud(force: true);
    unawaited(_syncDistanceWidget());

    if (kIsWeb || !_supportsRealtimeTrackingOnCurrentPlatform) {
      return;
    }

    _stepSub?.cancel();
    // Đăng ký kênh lắng nghe dữ liệu bước chân thời gian thực từ cảm biến hệ điều hành.
    //Nếu stream lỗi, hệ thống ghi log để theo dõi.
    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object error) {
        debugPrint(_l10n.trackingLogStepCounterError('$error'));
      },
    );

    var permission = await Geolocator.checkPermission();
    if (_isDisposed) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (_isDisposed) return;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(_l10n.trackingLogLocationPermissionDeniedForever);
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (_isDisposed) return;
      if (!serviceEnabled) {
        debugPrint(_l10n.trackingLogLocationServicesDisabled);
      } else {
        _positionSub?.cancel();
        //Mở luồng vị trí GPS liên tục với cấu hình độ chính xác cao và lọc dịch chuyển tối thiểu 5m để giảm nhiễu.
        _positionSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen(
          _onPosition,
          onError: (Object error) {
            debugPrint(_l10n.trackingLogLocationStreamError('$error'));
          },
        );
      }
    }

    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen(
      _onAccelerometer,
      onError: (Object error) {
        debugPrint(_l10n.trackingLogAccelerometerError('$error'));
      },
    );
  }

  void _onStepCount(StepCount event) {
    if (_isDisposed) return;
    final now = DateTime.now();
    _ensureToday(now);
    _rollEpochWindow(now);

    final String todayKey = _dayKey(now);
    final String? storedDay = _prefs?.getString(_scopedKey(_prefDayKey));
    if (storedDay != todayKey) {
      _resetForNewDay(now);
      _prefs?.setInt(_scopedKey(_prefStepBase), event.steps);
      _stepBase = event.steps;
      return;
    }

    if (_stepBase == null) {
      _stepBase = _prefs?.getInt(_scopedKey(_prefStepBase)) ?? event.steps;
      _prefs?.setInt(_scopedKey(_prefStepBase), _stepBase!);
    }

    final int nextSteps = max(0, event.steps - _stepBase!);
    final int delta = max(0, nextSteps - snapshot.value.steps);
    if (delta > 0) {
      _stepsCurrentMinute += delta;
      _lastStepIncreaseAt = now;
    }

    if (nextSteps != snapshot.value.steps) {
      snapshot.value = snapshot.value.copyWith(
        steps: nextSteps,
        lastUpdate: now,
      );
      _prefs?.setInt(_scopedKey(_prefSteps), nextSteps);
      _syncTodayToCloud();
      unawaited(_syncDistanceWidget());
      return;
    }

    _safeUpdateSnapshot((current) => current.copyWith(lastUpdate: now));
  }

  void _onPosition(Position position) {
    if (_isDisposed) return;
    final now = DateTime.now();
    final timestamp = position.timestamp;
    final today = _truncateToDay(now);
    if (today != _currentDay) {
      _resetForNewDay(now);
    }

    final accuracy = position.accuracy;
    if (accuracy > _maxAcceptedAccuracyMeters) {
      if (_lastLat == null || _lastLon == null) {
        _lastLat = position.latitude;
        _lastLon = position.longitude;
        _lastAltitude = position.altitude;
        _lastPositionAt = timestamp;
        _prefs?.setDouble(_scopedKey(_prefLastLat), _lastLat!);
        _prefs?.setDouble(_scopedKey(_prefLastLon), _lastLon!);
      }
      return;
    }

    if (_lastLat == null || _lastLon == null) {
      _lastLat = position.latitude;
      _lastLon = position.longitude;
      _lastAltitude = position.altitude;
      _lastPositionAt = timestamp;
      _prefs?.setDouble(_scopedKey(_prefLastLat), _lastLat!);
      _prefs?.setDouble(_scopedKey(_prefLastLon), _lastLon!);
      return;
    }

    if (_lastLat != null && _lastLon != null) {
      final distance = _backgroundDistanceBetween(
        _lastLat!,
        _lastLon!,
        position.latitude,
        position.longitude,
      );
      final Duration? deltaTime = _lastPositionAt == null
          ? null
          : timestamp.difference(_lastPositionAt!);
      final double rawSpeedMps = _selectSpeedMps(
        position,
        distance,
        deltaTime,
      );
      _smoothedSpeedMps = _smoothValue(
        previous: _smoothedSpeedMps,
        next: rawSpeedMps,
        factor: _speedSmoothingFactor,
      );

      final double? rawGrade = _calculateGrade(
        lastAltitude: _lastAltitude,
        currentAltitude: position.altitude,
        distanceMeters: distance,
      );
      if (rawGrade != null) {
        _smoothedGrade = _smoothValue(
          previous: _smoothedGrade,
          next: rawGrade,
          factor: _gradeSmoothingFactor,
        );
      }

      final int stepDeltaSinceAnchor = max(
        0,
        snapshot.value.steps - _distanceStepAnchor,
      );
      final bool hasRecentStep = _lastStepIncreaseAt != null &&
          now.difference(_lastStepIncreaseAt!).inSeconds <=
              _stepMovementFreshSeconds;
      final bool speedSuggestsMovement =
          (_smoothedSpeedMps ?? 0) >= _minSpeedMetersPerSecond;
      final bool movementLikely =
          hasRecentStep || (stepDeltaSinceAnchor > 0 && speedSuggestsMovement);

      if (!movementLikely) {
        if (distance <= _maxStationaryDriftMeters) {
          _lastLat = position.latitude;
          _lastLon = position.longitude;
          _lastAltitude = position.altitude;
          _lastPositionAt = timestamp;
          _prefs?.setDouble(_scopedKey(_prefLastLat), _lastLat!);
          _prefs?.setDouble(_scopedKey(_prefLastLon), _lastLon!);
        }
        return;
      }

      if (distance >= _minMovementDistanceMeters &&
          distance <= _maxSingleJumpMeters) {
        final currentDistance =
            _prefs?.getDouble(_scopedKey(_prefDistance)) ?? 0.0;
        final newDistance = currentDistance + distance;
        final currentCalories =
            _prefs?.getDouble(_scopedKey(_prefCaloriesKcal)) ??
                snapshot.value.caloriesKcal;
        final double deltaCalories = _estimateCaloriesDelta(
          distanceMeters: distance,
          duration: deltaTime,
          speedMps: _smoothedSpeedMps ?? 0.0,
          grade: _smoothedGrade ?? 0.0,
        );
        final double newCalories = currentCalories + deltaCalories;
        _prefs?.setDouble(_scopedKey(_prefDistance), newDistance);
        _prefs?.setDouble(_scopedKey(_prefCaloriesKcal), newCalories);
        _distanceStepAnchor = snapshot.value.steps;
        _safeUpdateSnapshot(
          (current) => current.copyWith(
            distanceMeters: newDistance,
            caloriesKcal: newCalories,
            speedMps: _smoothedSpeedMps ?? current.speedMps,
            grade: _smoothedGrade ?? current.grade,
            lastUpdate: now,
          ),
        );
        _syncTodayToCloud();
        unawaited(_syncDistanceWidget());
      } else if (distance > _maxSingleJumpMeters) {
        _lastLat = position.latitude;
        _lastLon = position.longitude;
        _lastAltitude = position.altitude;
        _lastPositionAt = timestamp;
        _prefs?.setDouble(_scopedKey(_prefLastLat), _lastLat!);
        _prefs?.setDouble(_scopedKey(_prefLastLon), _lastLon!);
        return;
      }
    }
    _lastLat = position.latitude;
    _lastLon = position.longitude;
    _lastAltitude = position.altitude;
    _lastPositionAt = timestamp;
    _prefs?.setDouble(_scopedKey(_prefLastLat), _lastLat!);
    _prefs?.setDouble(_scopedKey(_prefLastLon), _lastLon!);
  }

  double _selectSpeedMps(
    Position position,
    double distanceMeters,
    Duration? deltaTime,
  ) {
    double speed = position.speed;
    if (speed.isNaN || speed.isInfinite || speed < 0) {
      speed = 0.0;
    }

    if (speed <= 0 && deltaTime != null && deltaTime.inMilliseconds > 0) {
      final seconds = deltaTime.inMilliseconds / 1000.0;
      if (seconds > 0) {
        speed = distanceMeters / seconds;
      }
    }

    if (speed.isNaN || speed.isInfinite || speed < 0) {
      speed = 0.0;
    }
    if (speed > 12.0) {
      speed = 12.0;
    }
    return speed;
  }

  double? _calculateGrade({
    required double? lastAltitude,
    required double currentAltitude,
    required double distanceMeters,
  }) {
    if (lastAltitude == null) return null;
    if (distanceMeters < 5.0) return null;
    final raw = (currentAltitude - lastAltitude) / distanceMeters;
    if (raw.isNaN || raw.isInfinite) return null;
    return raw.clamp(-_maxGradeAbs, _maxGradeAbs);
  }

  double _smoothValue({
    required double? previous,
    required double next,
    required double factor,
  }) {
    if (previous == null) return next;
    return (previous * (1 - factor)) + (next * factor);
  }

  double _estimateCaloriesDelta({
    required double distanceMeters,
    required Duration? duration,
    required double speedMps,
    required double grade,
  }) {
    if (_weightKg == null || _weightKg! <= 0) {
      return (distanceMeters / 1000.0) * 55.0;
    }
    if (duration == null || duration.inSeconds <= 0) {
      return (distanceMeters / 1000.0) * 55.0;
    }

    final speedMpm = max(0.0, speedMps) * 60.0;
    if (speedMpm < 30) {
      return (distanceMeters / 1000.0) * 55.0;
    }

    final g = grade.clamp(-_maxGradeAbs, _maxGradeAbs);
    final bool isRunning = speedMpm >= 134.0;
    final double vo2 = isRunning
        ? (3.5 + (0.2 * speedMpm) + (0.9 * speedMpm * g))
        : (3.5 + (0.1 * speedMpm) + (1.8 * speedMpm * g));
    final double kcalPerMin = (vo2 * _weightKg! / 1000.0) * 5.0;
    final double minutes = duration.inSeconds / 60.0;
    return max(0.0, kcalPerMin * minutes);
  }

  Future<void> _loadWeightFromPrefs() async {
    _weightKg = _prefs?.getDouble(_scopedKey(_prefWeightKg));
  }

  void setWeightKg(double? weightKg) {
    _weightKg = weightKg;
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (_isDisposed) return;
    final now = DateTime.now();
    _ensureToday(now);

    _rollEpochWindow(now);

    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final delta = (magnitude - 9.81).abs();

    if (delta > _movementThreshold) {
      final bool canCountSpike = _lastMovementSpikeAt == null ||
          now.difference(_lastMovementSpikeAt!).inMilliseconds >=
              _spikeCooldownMs;
      if (canCountSpike) {
        _movementCountCurrentMinute++;
        _lastMovementSpikeAt = now;
      }
    }
  }

// Yêu cầu hệ điều hành chạy tác vụ nền định kỳ mỗi 15 phút để duy trì theo dõi khi app không mở foreground.
  Future<void> registerBackgroundTracking() async {
    if (!_supportsWorkmanagerOnCurrentPlatform) return;
    await Workmanager().registerPeriodicTask(
      _trackingTask,
      _trackingTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.not_required),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _stepSub?.cancel();
    _positionSub?.cancel();
    _positionSub = null;
    _accelSub?.cancel();
    _accelSub = null;
    snapshot.dispose();
    sleepHistory.dispose();
  }
}
