import 'package:cloud_firestore/cloud_firestore.dart';

class DailyTrackingCloudData {
  const DailyTrackingCloudData({
    this.steps,
    this.distanceMeters,
    this.sleepMinutes,
    this.goalType,
    this.goalValue,
  });

  final int? steps;
  final double? distanceMeters;
  final int? sleepMinutes;
  final String? goalType;
  final double? goalValue;
}

class MovementConfigCloudData {
  const MovementConfigCloudData({this.dailyGoalKm, this.distanceHistoryKm});

  final double? dailyGoalKm;
  final Map<String, double>? distanceHistoryKm;
}

class HealthCloudSyncService {
  HealthCloudSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<DailyTrackingCloudData?> loadTodayTracking({
    required String uid,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('health_tracking')
        .doc(_dayKey(DateTime.now()))
        .get();

    final data = doc.data();
    if (data == null) return null;

    return DailyTrackingCloudData(
      steps: (data['steps'] as num?)?.toInt(),
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble(),
      sleepMinutes: (data['sleepMinutes'] as num?)?.toInt(),
      goalType: data['goalType'] as String?,
      goalValue: (data['goalValue'] as num?)?.toDouble(),
    );
  }

  Future<void> saveTodayTracking({
    required String uid,
    required int steps,
    required double distanceMeters,
    required int sleepMinutes,
    required String goalType,
    required double goalValue,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('health_tracking')
        .doc(_dayKey(DateTime.now()))
        .set({
      'steps': steps,
      'distanceMeters': distanceMeters,
      'sleepMinutes': sleepMinutes,
      'goalType': goalType,
      'goalValue': goalValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<MovementConfigCloudData?> loadMovementConfig({
    required String uid,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('health_tracking_config')
        .doc('movement')
        .get();

    final data = doc.data();
    if (data == null) return null;

    final rawHistory = data['distanceHistoryKm'];
    final history = <String, double>{};
    if (rawHistory is Map<String, dynamic>) {
      for (final entry in rawHistory.entries) {
        final value = entry.value;
        if (value is num) {
          history[entry.key] = value.toDouble();
        }
      }
    }

    return MovementConfigCloudData(
      dailyGoalKm: (data['dailyGoalKm'] as num?)?.toDouble(),
      distanceHistoryKm: history.isEmpty ? null : history,
    );
  }

  Future<void> saveMovementConfig({
    required String uid,
    required double dailyGoalKm,
    required Map<String, double> distanceHistoryKm,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('health_tracking_config')
        .doc('movement')
        .set({
      'dailyGoalKm': dailyGoalKm,
      'distanceHistoryKm': distanceHistoryKm,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
