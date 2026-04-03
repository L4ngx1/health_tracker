import 'package:cloud_firestore/cloud_firestore.dart';

class WeightRecord {
  const WeightRecord({
    required this.id,
    required this.weightKg,
    required this.recordedAt,
    this.bodyFatPercent,
    this.note,
  });

  final String id;
  final double weightKg;
  final DateTime recordedAt;
  final double? bodyFatPercent;
  final String? note;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'weightKg': weightKg,
      'bodyFatPercent': bodyFatPercent,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static WeightRecord fromMap(String id, Map<String, dynamic> map) {
    final dynamic recordedAt = map['recordedAt'];
    final DateTime when = recordedAt is Timestamp
        ? recordedAt.toDate()
        : DateTime.now();

    return WeightRecord(
      id: id,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
      bodyFatPercent: (map['bodyFatPercent'] as num?)?.toDouble(),
      recordedAt: when,
      note: map['note'] as String?,
    );
  }
}
