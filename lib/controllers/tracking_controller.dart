import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../services/health_cloud_sync_service.dart';

const _trackingTask = 'tracking_background_task';
const _prefSteps = 'tracking.steps';
const _prefDistance = 'tracking.distanceMeters';
const _prefLastLat = 'tracking.lastLat';
const _prefLastLon = 'tracking.lastLon';
const _prefSleepMinutes = 'tracking.sleepMinutes';
const _prefDayKey = 'tracking.dayKey';
const _prefStillStart = 'tracking.stillStart';
const _prefGoalType = 'tracking.goalType';
const _prefGoalValue = 'tracking.goalValue';
const _prefMigrationDone = 'tracking.migration.v1';

enum DailyGoalType { steps, distanceKm }

const _defaultStepGoal = 8000.0;
const _defaultDistanceGoalKm = 6.0;

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
    required this.sleepMinutes,
    required this.isSleeping,
    required this.goalType,
    required this.goalValue,
    this.lastUpdate,
  });

  const TrackingSnapshot.initial()
    : steps = 0,
      distanceMeters = 0.0,
      sleepMinutes = 0,
      isSleeping = false,
      goalType = DailyGoalType.steps,
      goalValue = _defaultStepGoal,
      lastUpdate = null;

  final int steps;
  final double distanceMeters;
  final int sleepMinutes;
  final bool isSleeping;
  final DailyGoalType goalType;
  final double goalValue;
  final DateTime? lastUpdate;

  TrackingSnapshot copyWith({
    int? steps,
    double? distanceMeters,
    int? sleepMinutes,
    bool? isSleeping,
    DailyGoalType? goalType,
    double? goalValue,
    DateTime? lastUpdate,
  }) {
    return TrackingSnapshot(
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
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

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isDisposed = false;
  StreamSubscription<Position>? _positionSub;
  int? _lastStepCount;
  double? _lastLat;
  double? _lastLon;
  DateTime _currentDay = _truncateToDay(DateTime.now());
  DateTime? _stillStart;
  DateTime? _lastMotion;
  SharedPreferences? _prefs;

  bool get isDisposed => _isDisposed;

  Future<void> _migrateLegacyTrackingIfNeeded() async {
    if (_prefs == null) return;
    if (_prefs!.getBool(_migrationKey) == true) return;

    final scopedSamples = <String>[
      _scopedKey(_prefSteps),
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
      if (_prefs!.containsKey(_prefStillStart)) {
        final v = _prefs!.getString(_prefStillStart);
        if (v != null && v.isNotEmpty) {
          await _prefs!.setString(_scopedKey(_prefStillStart), v);
        }
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
    } catch (e) {
      debugPrint('Cloud merge tracking failed: $e');
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
            debugPrint('Cloud save tracking failed: $e');
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
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
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
  }

  Future<void> _loadFromPrefs() async {
    if (_isDisposed) return;
    final now = DateTime.now();
    final todayKey = _dayKey(now);
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
      await _prefs?.remove(_scopedKey(_prefLastLat));
      await _prefs?.remove(_scopedKey(_prefLastLon));
      _lastLat = null;
      _lastLon = null;
    } else {
      final steps = _prefs?.getInt(_scopedKey(_prefSteps)) ?? 0;
      final distance = _prefs?.getDouble(_scopedKey(_prefDistance)) ?? 0.0;
      final sleepMinutes = _prefs?.getInt(_scopedKey(_prefSleepMinutes)) ?? 0;
      final stillStartIso = _prefs?.getString(_scopedKey(_prefStillStart));
      final lastLat = _prefs?.getDouble(_scopedKey(_prefLastLat));
      final lastLon = _prefs?.getDouble(_scopedKey(_prefLastLon));
      _lastLat = lastLat;
      _lastLon = lastLon;
      if (_isDisposed) return;
      _safeUpdateSnapshot(
        (current) => current.copyWith(
          steps: steps,
          distanceMeters: distance,
          sleepMinutes: sleepMinutes,
          isSleeping: stillStartIso != null,
          goalType: goalType,
          goalValue: goalValue,
        ),
      );
    }
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

    if (kIsWeb || !_supportsRealtimeTrackingOnCurrentPlatform) {
      return;
    }

    _stepSub?.cancel();
    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object error) {
        debugPrint('Step counter error: $error');
      },
    );

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (_isDisposed) return;
    if (serviceEnabled) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _positionSub?.cancel();
        _positionSub =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.best,
                distanceFilter: 5,
              ),
            ).listen(
              _onPosition,
              onError: (Object error) {
                debugPrint('Location stream error: $error');
              },
            );
      }
    }

    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen(
      _onAccelerometer,
      onError: (Object error) {
        debugPrint('Accelerometer error: $error');
      },
    );
  }

  void _onStepCount(StepCount event) {
    if (_isDisposed) return;
    final now = DateTime.now();
    if (_lastStepCount == null) {
      _lastStepCount = event.steps;
      _safeUpdateSnapshot(
        (current) => current.copyWith(steps: event.steps, lastUpdate: now),
      );
      return;
    }
    final delta = event.steps - _lastStepCount!;
    _lastStepCount = event.steps;
    if (delta > 0) {
      final newSteps = snapshot.value.steps + delta;
      snapshot.value = snapshot.value.copyWith(
        steps: newSteps,
        lastUpdate: now,
      );
      _prefs?.setInt(_scopedKey(_prefSteps), newSteps);
      _syncTodayToCloud();
    } else {
      _safeUpdateSnapshot((current) => current.copyWith(lastUpdate: now));
    }
  }

  void _onPosition(Position position) {
    if (_isDisposed) return;
    final now = DateTime.now();
    final today = _truncateToDay(now);
    if (today != _currentDay) {
      _currentDay = today;
      _lastLat = null;
      _lastLon = null;
      snapshot.value = snapshot.value.copyWith(
        distanceMeters: 0.0,
        lastUpdate: now,
      );
      _prefs?.setString(_scopedKey(_prefDayKey), _dayKey(today));
    }
    // Update distance if lastLat/lon exist
    if (_lastLat != null && _lastLon != null) {
      final distance = _backgroundDistanceBetween(
        _lastLat!,
        _lastLon!,
        position.latitude,
        position.longitude,
      );
      if (distance > 1 && distance < 500) {
        final currentDistance =
            _prefs?.getDouble(_scopedKey(_prefDistance)) ?? 0.0;
        final newDistance = currentDistance + distance;
        _prefs?.setDouble(_scopedKey(_prefDistance), newDistance);
        _safeUpdateSnapshot(
          (current) =>
              current.copyWith(distanceMeters: newDistance, lastUpdate: now),
        );
        _syncTodayToCloud();
      }
    }
    _lastLat = position.latitude;
    _lastLon = position.longitude;
    _prefs?.setDouble(_scopedKey(_prefLastLat), _lastLat!);
    _prefs?.setDouble(_scopedKey(_prefLastLon), _lastLon!);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (_isDisposed) return;
    final now = DateTime.now();
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final delta = (magnitude - 9.81).abs();
    const stillThreshold = 0.5;
    const minStillMinutes = 20;
    if (delta < stillThreshold) {
      _stillStart ??= now;
      _lastMotion ??= now;
      final stillDuration = now.difference(_stillStart!).inMinutes;
      if (stillDuration >= minStillMinutes) {
        if (!snapshot.value.isSleeping) {
          _safeUpdateSnapshot((current) => current.copyWith(isSleeping: true));
          _prefs?.setString(
            _scopedKey(_prefStillStart),
            _stillStart!.toIso8601String(),
          );
          _syncTodayToCloud();
        }
      }
    } else {
      _lastMotion = now;
      if (snapshot.value.isSleeping && _stillStart != null) {
        final sleptMinutes = now.difference(_stillStart!).inMinutes;
        if (sleptMinutes > 0) {
          final total = snapshot.value.sleepMinutes + sleptMinutes;
          _safeUpdateSnapshot(
            (current) =>
                current.copyWith(sleepMinutes: total, isSleeping: false),
          );
          _prefs?.setInt(_scopedKey(_prefSleepMinutes), total);
          _syncTodayToCloud();
        } else {
          _safeUpdateSnapshot((current) => current.copyWith(isSleeping: false));
        }
      }
      _stillStart = null;
      _prefs?.remove(_scopedKey(_prefStillStart));
    }
  }

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
  }
}
