import 'package:firebase_auth/firebase_auth.dart';

import '../models/backend/calorie_record.dart';
import '../models/backend/notification_record.dart';
import '../models/backend/user_profile.dart';
import '../models/backend/weight_record.dart';
import '../models/backend/workout_record.dart';
import 'backend_repository.dart';

class BackendApiService {
  BackendApiService({
    BackendRepository? repository,
    FirebaseAuth? auth,
    String Function()? uidProvider,
  })  : _repository = repository ?? BackendRepository(),
        _auth = auth,
        _uidProvider = uidProvider;

  final BackendRepository _repository;
  final FirebaseAuth? _auth;
  final String Function()? _uidProvider;

  String get _uid {
    final providedUid = _uidProvider?.call();
    if (providedUid != null && providedUid.isNotEmpty) {
      return providedUid;
    }
    final uid = _safeCurrentUserUid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User is not authenticated.');
    }
    return uid;
  }

  String? get _safeCurrentUserUid {
    try {
      return (_auth ?? FirebaseAuth.instance).currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile?> getMyProfile() {
    return _repository.getUserProfile(_uid);
  }

  Future<void> saveMyProfile(UserProfile profile) {
    final uid = _uid;
    final normalized = UserProfile(
      uid: uid,
      fullName: profile.fullName,
      email: profile.email,
      photoUrl: profile.photoUrl,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
    return _repository.saveUserProfile(normalized);
  }

  Future<void> saveMyFcmToken(String token) {
    return _repository.saveUserFcmToken(uid: _uid, token: token);
  }

  Future<void> clearMyFcmToken() {
    return _repository.clearUserFcmToken(uid: _uid);
  }

  Future<String> addMyWorkout(WorkoutRecord workout) {
    return _repository.addWorkout(uid: _uid, workout: workout);
  }

  Future<void> updateMyWorkout({
    required String workoutId,
    required WorkoutRecord workout,
  }) {
    return _repository.updateWorkout(
      uid: _uid,
      workoutId: workoutId,
      workout: workout,
    );
  }

  Future<void> deleteMyWorkout(String workoutId) {
    return _repository.deleteWorkout(uid: _uid, workoutId: workoutId);
  }

  Future<List<WorkoutRecord>> getMyWorkouts({int limit = 50}) {
    return _repository.getWorkouts(uid: _uid, limit: limit);
  }

  Future<String> addMyCalorieRecord(CalorieRecord record) {
    return _repository.addCalorieRecord(uid: _uid, record: record);
  }

  Future<void> updateMyCalorieRecord({
    required String recordId,
    required CalorieRecord record,
  }) {
    return _repository.updateCalorieRecord(
      uid: _uid,
      recordId: recordId,
      record: record,
    );
  }

  Future<void> deleteMyCalorieRecord(String recordId) {
    return _repository.deleteCalorieRecord(uid: _uid, recordId: recordId);
  }

  Future<List<CalorieRecord>> getMyCalorieRecords({int limit = 100}) {
    return _repository.getCalorieRecords(uid: _uid, limit: limit);
  }

  Future<String> addMyWeightRecord(WeightRecord record) {
    return _repository.addWeightRecord(uid: _uid, record: record);
  }

  Future<void> updateMyWeightRecord({
    required String recordId,
    required WeightRecord record,
  }) {
    return _repository.updateWeightRecord(
      uid: _uid,
      recordId: recordId,
      record: record,
    );
  }

  Future<void> deleteMyWeightRecord(String recordId) {
    return _repository.deleteWeightRecord(uid: _uid, recordId: recordId);
  }

  Future<List<WeightRecord>> getMyWeightRecords({int limit = 120}) {
    return _repository.getWeightRecords(uid: _uid, limit: limit);
  }

  Stream<List<NotificationRecord>> watchMyNotifications({int limit = 100}) {
    final uid = _safeCurrentUserUid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(const <NotificationRecord>[]);
    }
    return _repository.watchNotifications(uid: uid, limit: limit);
  }

  Future<void> markMyNotificationRead(String notificationId) {
    return _repository.markNotificationRead(
      uid: _uid,
      notificationId: notificationId,
    );
  }

  Future<void> markAllMyNotificationsRead({bool? onlyImportant}) {
    return _repository.markAllNotificationsRead(
      uid: _uid,
      onlyImportant: onlyImportant,
    );
  }

  Future<String> addMyNotification({
    required String title,
    required String message,
    bool isImportant = false,
  }) {
    return _repository.addNotification(
      uid: _uid,
      notification: NotificationRecord(
        id: '',
        title: title,
        message: message,
        isImportant: isImportant,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteMyNotification(String notificationId) {
    return _repository.deleteNotification(
      uid: _uid,
      notificationId: notificationId,
    );
  }

  Future<void> saveMyUploadMetadata({
    required String key,
    required String fileUrl,
    required String contentType,
    String? tag,
  }) {
    return _repository.saveUploadMetadata(
      uid: _uid,
      key: key,
      fileUrl: fileUrl,
      contentType: contentType,
      tag: tag,
    );
  }

  Future<List<Map<String, dynamic>>> getMyUploadMetadata({int limit = 30}) {
    return _repository.getUploadMetadata(uid: _uid, limit: limit);
  }
}
