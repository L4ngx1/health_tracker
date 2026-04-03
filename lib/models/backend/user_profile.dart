import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.heightCm,
    this.weightKg,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String? photoUrl;
  final double? heightCm;
  final double? weightKg;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? photoUrl,
    double? heightCm,
    double? weightKg,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static UserProfile fromMap(
    String uid,
    Map<String, dynamic> map,
  ) {
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return UserProfile(
      uid: uid,
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      photoUrl: map['photoUrl'] as String?,
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }
}
