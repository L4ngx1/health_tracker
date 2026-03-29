import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const _trackingTask = 'tracking_background_task';
const _prefSteps = 'tracking.steps';
const _prefDistance = 'tracking.distanceMeters';
const _prefLastStep = 'tracking.lastStepCount';
const _prefLastLat = 'tracking.lastLat';
const _prefLastLon = 'tracking.lastLon';
const _prefSleepMinutes = 'tracking.sleepMinutes';
const _prefDayKey = 'tracking.dayKey';
const _prefStillStart = 'tracking.stillStart';
const _prefGoalType = 'tracking.goalType';
const _prefGoalValue = 'tracking.goalValue';

enum DailyGoalType { steps, distanceKm }

const _defaultStepGoal = 8000.0;
const _defaultDistanceGoalKm = 6.0;

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

  void _safeSetSnapshot(TrackingSnapshot newValue) {
    if (_isDisposed) return;
    try {
      snapshot.value = newValue;
    } catch (_) {
      // ignore if notifier was disposed concurrently
    }
  }

  void _safeUpdateSnapshot(
    TrackingSnapshot Function(TrackingSnapshot) updater,
  ) {
    if (_isDisposed) return;
    try {
      snapshot.value = updater(snapshot.value);
    } catch (_) {
      // ignore if notifier was disposed concurrently
    }
  }

  static DateTime _truncateToDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

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
    await _prefs?.setString(_prefGoalType, type.name);
    await _prefs?.setDouble(_prefGoalValue, normalized);
  }

  Future<void> start() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_isDisposed) return;

    await _loadFromPrefs();
    if (_isDisposed) return;

    if (kIsWeb) return;

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

  void _onPosition(Position position) {
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
      _prefs?.setString(_prefDayKey, _dayKey(today));
      return;
    }
    final lat = position.latitude;
    final lon = position.longitude;
    if (_lastLat != null && _lastLon != null) {
      final distance = _distanceBetween(_lastLat!, _lastLon!, lat, lon);
      if (distance > 1 && distance < 500) {
        final newDistance = snapshot.value.distanceMeters + distance;
        _safeUpdateSnapshot(
          (current) =>
              current.copyWith(distanceMeters: newDistance, lastUpdate: now),
        );
      }
    }
    _lastLat = lat;
    _lastLon = lon;
    _prefs?.setDouble(_prefDistance, snapshot.value.distanceMeters);
    _prefs?.setDouble(_prefLastLat, lat);
    _prefs?.setDouble(_prefLastLon, lon);
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth radius in meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  void _onStepCount(StepCount event) {
    final now = DateTime.now();
    final today = _truncateToDay(now);
    if (today != _currentDay) {
      _currentDay = today;
      snapshot.value = snapshot.value.copyWith(
        steps: 0,
        distanceMeters: 0,
        sleepMinutes: 0,
        isSleeping: false,
        lastUpdate: now,
      );
      _prefs?.setString(_prefDayKey, _dayKey(today));
      _prefs?.setInt(_prefSteps, 0);
      _prefs?.setDouble(_prefDistance, 0);
      _prefs?.setInt(_prefSleepMinutes, 0);
      _prefs?.remove(_prefLastLat);
      _prefs?.remove(_prefLastLon);
      _prefs?.setInt(_prefLastStep, event.steps);
      _lastStepCount = event.steps;
      _lastLat = null;
      _lastLon = null;
      return;
    }

    final storedSteps = _prefs?.getInt(_prefSteps) ?? 0;
    if (_lastStepCount == null) {
      _lastStepCount = event.steps;
      _safeUpdateSnapshot(
        (current) => current.copyWith(steps: storedSteps, lastUpdate: now),
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
      _prefs?.setInt(_prefSteps, newSteps);
    } else {
      _safeUpdateSnapshot((current) => current.copyWith(lastUpdate: now));
    }
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
          _prefs?.setString(_prefStillStart, _stillStart!.toIso8601String());
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
          _prefs?.setInt(_prefSleepMinutes, total);
        } else {
          _safeUpdateSnapshot((current) => current.copyWith(isSleeping: false));
        }
      }
      _stillStart = null;
      _prefs?.remove(_prefStillStart);
    }
  }

  Future<void> registerBackgroundTracking() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      _trackingTask,
      _trackingTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
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

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _loadFromPrefs() async {
    if (_isDisposed) return;
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final storedDay = _prefs?.getString(_prefDayKey);
    final goalType = _goalTypeFromString(_prefs?.getString(_prefGoalType));
    final storedGoalValue = _prefs?.getDouble(_prefGoalValue);
    final goalValue = _normalizeGoalValue(
      goalType,
      storedGoalValue ??
          (goalType == DailyGoalType.steps
              ? _defaultStepGoal
              : _defaultDistanceGoalKm),
    );
    if (storedDay != null && storedDay != todayKey) {
<<<<<<< HEAD
      _safeSetSnapshot(const TrackingSnapshot.initial());
      if (_isDisposed) return;
=======
      snapshot.value = snapshot.value.copyWith(
        steps: 0,
        distanceMeters: 0,
        sleepMinutes: 0,
        isSleeping: false,
        goalType: goalType,
        goalValue: goalValue,
      );
>>>>>>> TTuan
      await _prefs?.setString(_prefDayKey, todayKey);
      await _prefs?.setInt(_prefSteps, 0);
      await _prefs?.setDouble(_prefDistance, 0);
      await _prefs?.setInt(_prefSleepMinutes, 0);
      await _prefs?.setString(_prefGoalType, goalType.name);
      await _prefs?.setDouble(_prefGoalValue, goalValue);
      await _prefs?.remove(_prefLastLat);
      await _prefs?.remove(_prefLastLon);
      _lastLat = null;
      _lastLon = null;
    } else {
      final steps = _prefs?.getInt(_prefSteps) ?? 0;
      final distance = _prefs?.getDouble(_prefDistance) ?? 0.0;
      final sleepMinutes = _prefs?.getInt(_prefSleepMinutes) ?? 0;
      final stillStartIso = _prefs?.getString(_prefStillStart);
      final lastLat = _prefs?.getDouble(_prefLastLat);
      final lastLon = _prefs?.getDouble(_prefLastLon);
      _lastLat = lastLat;
      _lastLon = lastLon;
<<<<<<< HEAD
      if (_isDisposed) return;
      _safeUpdateSnapshot(
        (current) => current.copyWith(
          steps: steps,
          distanceMeters: distance,
          sleepMinutes: sleepMinutes,
          isSleeping: stillStartIso != null,
        ),
=======
      snapshot.value = snapshot.value.copyWith(
        steps: steps,
        distanceMeters: distance,
        sleepMinutes: sleepMinutes,
        isSleeping: stillStartIso != null,
        goalType: goalType,
        goalValue: goalValue,
>>>>>>> TTuan
      );
      if (stillStartIso != null) {
        _stillStart = DateTime.tryParse(stillStartIso);
      }
    }
  }

  DailyGoalType _goalTypeFromString(String? raw) {
    if (raw == DailyGoalType.distanceKm.name) {
      return DailyGoalType.distanceKm;
    }
    return DailyGoalType.steps;
  }

  double _normalizeGoalValue(DailyGoalType type, double value) {
    if (type == DailyGoalType.steps) {
      final rounded = (value / 100).round() * 100;
      return rounded.clamp(1000, 50000).toDouble();
    }
    final normalized = (value * 10).round() / 10;
    return normalized.clamp(1.0, 50.0).toDouble();
  }
}

@pragma('vm:entry-point')
void trackingCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final lastLat = prefs.getDouble(_prefLastLat);
      final lastLon = prefs.getDouble(_prefLastLon);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final now = DateTime.now();
      final dayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final storedDay = prefs.getString(_prefDayKey);
      if (storedDay != dayKey) {
        await prefs.setString(_prefDayKey, dayKey);
        await prefs.setInt(_prefSteps, 0);
        await prefs.setDouble(_prefDistance, 0);
        await prefs.setInt(_prefSleepMinutes, 0);
        await prefs.remove(_prefLastLat);
        await prefs.remove(_prefLastLon);
      }

      if (lastLat != null && lastLon != null) {
        final latitude = position.latitude;
        final longitude = position.longitude;
        final distance = _backgroundDistanceBetween(
          lastLat,
          lastLon,
          latitude,
          longitude,
        );
        if (distance > 1 && distance < 500) {
          final currentDistance = prefs.getDouble(_prefDistance) ?? 0;
          await prefs.setDouble(_prefDistance, currentDistance + distance);
        }
      }

      await prefs.setDouble(_prefLastLat, position.latitude);
      await prefs.setDouble(_prefLastLon, position.longitude);
      return true;
    } catch (e) {
      debugPrint('Background tracking error: $e');
      return true;
    }
  });
}

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

double _backgroundDeg2rad(double deg) => deg * (pi / 180.0);
