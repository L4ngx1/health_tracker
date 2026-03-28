import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const _trackingTask = 'tracking_background_task';
const _prefDistance = 'tracking.distanceMeters';
const _prefSleepMinutes = 'tracking.sleepMinutes';
const _prefLastLat = 'tracking.lastLat';
const _prefLastLon = 'tracking.lastLon';
const _prefDayKey = 'tracking.dayKey';
const _prefStillStart = 'tracking.stillStart';

@immutable
class TrackingSnapshot {
  const TrackingSnapshot({
    required this.distanceMeters,
    required this.sleepMinutes,
    required this.isSleeping,
    this.lastUpdate,
  });

  const TrackingSnapshot.initial()
    : distanceMeters = 0,
      sleepMinutes = 0,
      isSleeping = false,
      lastUpdate = null;

  final double distanceMeters;
  final int sleepMinutes;
  final bool isSleeping;
  final DateTime? lastUpdate;

  TrackingSnapshot copyWith({
    double? distanceMeters,
    int? sleepMinutes,
    bool? isSleeping,
    DateTime? lastUpdate,
  }) {
    return TrackingSnapshot(
      distanceMeters: distanceMeters ?? this.distanceMeters,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      isSleeping: isSleeping ?? this.isSleeping,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class TrackingController {
  TrackingController();

  final ValueNotifier<TrackingSnapshot> snapshot =
      ValueNotifier<TrackingSnapshot>(const TrackingSnapshot.initial());

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Position? _lastPosition;
  DateTime _currentDay = _truncateToDay(DateTime.now());
  DateTime? _stillStart;
  DateTime? _lastMotion;
  SharedPreferences? _prefs;

  static DateTime _truncateToDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  Future<void> start() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadFromPrefs();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

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
      _lastPosition = null;
      snapshot.value = const TrackingSnapshot.initial();
      _prefs?.setString(_prefDayKey, _dayKey(today));
      _prefs?.setDouble(_prefDistance, 0);
      _prefs?.setInt(_prefSleepMinutes, 0);
    }

    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance > 1 && distance < 500) {
        final newDistance = snapshot.value.distanceMeters + distance;
        snapshot.value = snapshot.value.copyWith(
          distanceMeters: newDistance,
          lastUpdate: now,
        );
        _prefs?.setDouble(_prefDistance, newDistance);
      } else {
        snapshot.value = snapshot.value.copyWith(lastUpdate: now);
      }
    } else {
      snapshot.value = snapshot.value.copyWith(lastUpdate: now);
    }

    _lastPosition = position;
    _prefs?.setDouble(_prefLastLat, position.latitude);
    _prefs?.setDouble(_prefLastLon, position.longitude);
  }

  void _onAccelerometer(AccelerometerEvent event) {
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
          snapshot.value = snapshot.value.copyWith(isSleeping: true);
          _prefs?.setString(_prefStillStart, _stillStart!.toIso8601String());
        }
      }
    } else {
      _lastMotion = now;
      if (snapshot.value.isSleeping && _stillStart != null) {
        final sleptMinutes = now.difference(_stillStart!).inMinutes;
        if (sleptMinutes > 0) {
          final total = snapshot.value.sleepMinutes + sleptMinutes;
          snapshot.value = snapshot.value.copyWith(
            sleepMinutes: total,
            isSleeping: false,
          );
          _prefs?.setInt(_prefSleepMinutes, total);
        } else {
          snapshot.value = snapshot.value.copyWith(isSleeping: false);
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
      constraints: Constraints(networkType: NetworkType.not_required),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  void dispose() {
    _positionSub?.cancel();
    _accelSub?.cancel();
    snapshot.dispose();
  }

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _loadFromPrefs() async {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final storedDay = _prefs?.getString(_prefDayKey);
    if (storedDay != null && storedDay != todayKey) {
      snapshot.value = const TrackingSnapshot.initial();
      await _prefs?.setString(_prefDayKey, todayKey);
      await _prefs?.setDouble(_prefDistance, 0);
      await _prefs?.setInt(_prefSleepMinutes, 0);
    } else {
      final distance = _prefs?.getDouble(_prefDistance) ?? 0;
      final sleepMinutes = _prefs?.getInt(_prefSleepMinutes) ?? 0;
      final stillStartIso = _prefs?.getString(_prefStillStart);
      snapshot.value = snapshot.value.copyWith(
        distanceMeters: distance,
        sleepMinutes: sleepMinutes,
        isSleeping: stillStartIso != null,
      );
      if (stillStartIso != null) {
        _stillStart = DateTime.tryParse(stillStartIso);
      }
    }
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
        await prefs.setDouble(_prefDistance, 0);
        await prefs.setInt(_prefSleepMinutes, 0);
      }

      if (lastLat != null && lastLon != null) {
        final segment = Geolocator.distanceBetween(
          lastLat,
          lastLon,
          position.latitude,
          position.longitude,
        );
        if (segment > 1 && segment < 500) {
          final current = prefs.getDouble(_prefDistance) ?? 0;
          await prefs.setDouble(_prefDistance, current + segment);
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
