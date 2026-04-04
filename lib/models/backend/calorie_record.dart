import 'package:cloud_firestore/cloud_firestore.dart';

class CalorieRecord {
  const CalorieRecord({
    required this.id,
    required this.itemName,
    required this.calories,
    required this.recordedAt,
    this.note,
  });

  final String id;
  final String itemName;
  final double calories;
  final DateTime recordedAt;
  final String? note;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'itemName': itemName,
      'calories': calories,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static CalorieRecord fromMap(String id, Map<String, dynamic> map) {
    final dynamic recordedAt = map['recordedAt'];
    final DateTime when =
        recordedAt is Timestamp ? recordedAt.toDate() : DateTime.now();

    return CalorieRecord(
      id: id,
      itemName: (map['itemName'] as String?)?.trim() ?? '',
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      recordedAt: when,
      note: map['note'] as String?,
    );
  }
}
