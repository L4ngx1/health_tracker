import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRecord {
  const NotificationRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.isImportant,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String message;
  final bool isImportant;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'message': message,
      'isImportant': isImportant,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static NotificationRecord fromMap(String id, Map<String, dynamic> map) {
    final dynamic createdAtRaw = map['createdAt'];
    final dynamic readAtRaw = map['readAt'];

    final createdAt =
        createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now();
    final readAt = readAtRaw is Timestamp ? readAtRaw.toDate() : null;

    return NotificationRecord(
      id: id,
      title: (map['title'] as String?)?.trim() ?? '',
      message: (map['message'] as String?)?.trim() ?? '',
      isImportant: map['isImportant'] == true,
      isRead: map['isRead'] == true,
      createdAt: createdAt,
      readAt: readAt,
    );
  }
}
