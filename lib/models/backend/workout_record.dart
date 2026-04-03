import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.performedAt,
    this.note,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime performedAt;
  final String? note;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'performedAt': Timestamp.fromDate(performedAt),
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static WorkoutRecord fromMap(String id, Map<String, dynamic> map) {
    final dynamic performedAt = map['performedAt'];
    final DateTime when = performedAt is Timestamp
        ? performedAt.toDate()
        : DateTime.now();

    return WorkoutRecord(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0,
      performedAt: when,
      note: map['note'] as String?,
    );
  }
}
