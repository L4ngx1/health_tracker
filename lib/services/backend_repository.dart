<<<<<<< HEAD
﻿import 'package:cloud_firestore/cloud_firestore.dart';
=======
import 'package:cloud_firestore/cloud_firestore.dart';
>>>>>>> origin/main

import '../models/backend/calorie_record.dart';
import '../models/backend/notification_record.dart';
import '../models/backend/user_profile.dart';
import '../models/backend/weight_record.dart';
import '../models/backend/workout_record.dart';

class BackendRepository {
  BackendRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _workoutCol(String uid) {
    return _userDoc(uid).collection('workouts');
  }

  CollectionReference<Map<String, dynamic>> _calorieCol(String uid) {
    return _userDoc(uid).collection('calories');
  }

  CollectionReference<Map<String, dynamic>> _weightCol(String uid) {
    return _userDoc(uid).collection('weights');
  }

  CollectionReference<Map<String, dynamic>> _notificationCol(String uid) {
    return _userDoc(uid).collection('notifications');
  }

  CollectionReference<Map<String, dynamic>> get _r2UploadsCol {
    return _firestore.collection('r2_uploads');
  }

  Future<void> ensureUserProfile({
    required String uid,
    required String email,
    required String fullName,
    String? photoUrl,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _userDoc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set(<String, dynamic>{
        'fullName': fullName,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.set(<String, dynamic>{
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromMap(uid, data);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _userDoc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<String> addWorkout({
    required String uid,
    required WorkoutRecord workout,
  }) async {
    final ref = _workoutCol(uid).doc();
    await ref.set(workout.toMap());
    return ref.id;
  }

  Future<void> updateWorkout({
    required String uid,
    required String workoutId,
    required WorkoutRecord workout,
  }) async {
    await _workoutCol(uid).doc(workoutId).set(
          workout.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteWorkout({
    required String uid,
    required String workoutId,
  }) async {
    await _workoutCol(uid).doc(workoutId).delete();
  }

  Future<List<WorkoutRecord>> getWorkouts({
    required String uid,
    int limit = 50,
  }) async {
    final query = await _workoutCol(uid)
        .orderBy('performedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => WorkoutRecord.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  Future<String> addCalorieRecord({
    required String uid,
    required CalorieRecord record,
  }) async {
    final ref = _calorieCol(uid).doc();
    await ref.set(record.toMap());
    return ref.id;
  }

  Future<void> updateCalorieRecord({
    required String uid,
    required String recordId,
    required CalorieRecord record,
  }) async {
    await _calorieCol(uid).doc(recordId).set(
          record.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteCalorieRecord({
    required String uid,
    required String recordId,
  }) async {
    await _calorieCol(uid).doc(recordId).delete();
  }

  Future<List<CalorieRecord>> getCalorieRecords({
    required String uid,
    int limit = 100,
  }) async {
    final query = await _calorieCol(uid)
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => CalorieRecord.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  Future<String> addWeightRecord({
    required String uid,
    required WeightRecord record,
  }) async {
    final ref = _weightCol(uid).doc();
    await ref.set(record.toMap());

    await _userDoc(uid).set(<String, dynamic>{
      'weightKg': record.weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return ref.id;
  }

  Future<void> updateWeightRecord({
    required String uid,
    required String recordId,
    required WeightRecord record,
  }) async {
    await _weightCol(uid).doc(recordId).set(
          record.toMap(),
          SetOptions(merge: true),
        );

    await _userDoc(uid).set(<String, dynamic>{
      'weightKg': record.weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteWeightRecord({
    required String uid,
    required String recordId,
  }) async {
    await _weightCol(uid).doc(recordId).delete();
  }

  Future<List<WeightRecord>> getWeightRecords({
    required String uid,
    int limit = 120,
  }) async {
    final query = await _weightCol(uid)
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => WeightRecord.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  Stream<List<NotificationRecord>> watchNotifications({
    required String uid,
    int limit = 100,
  }) {
    return _notificationCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (query) => query.docs
              .map((doc) => NotificationRecord.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> markNotificationRead({
    required String uid,
    required String notificationId,
  }) async {
    await _notificationCol(uid).doc(notificationId).set(<String, dynamic>{
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllNotificationsRead({
    required String uid,
    bool? onlyImportant,
  }) async {
    Query<Map<String, dynamic>> query = _notificationCol(uid)
        .where('isRead', isEqualTo: false)
        .limit(300);

    if (onlyImportant != null) {
      query = query.where('isImportant', isEqualTo: onlyImportant);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, <String, dynamic>{
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<String> addNotification({
    required String uid,
    required NotificationRecord notification,
  }) async {
    final ref = _notificationCol(uid).doc();
    await ref.set(notification.toMap());
    return ref.id;
  }

  Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  }) async {
    await _notificationCol(uid).doc(notificationId).delete();
  }

  Future<void> saveUploadMetadata({
    required String uid,
    required String key,
    required String fileUrl,
    required String contentType,
    String? tag,
  }) async {
    await _r2UploadsCol.add(<String, dynamic>{
      'uid': uid,
      'key': key,
      'url': fileUrl,
      'contentType': contentType,
      'tag': tag,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUploadMetadata({
    required String uid,
    int limit = 30,
  }) async {
    final query = await _r2UploadsCol
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'id': doc.id,
        ...data,
      };
    }).toList(growable: false);
  }
}
