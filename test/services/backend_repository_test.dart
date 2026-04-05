import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/models/backend/calorie_record.dart';
import 'package:health_tracker/models/backend/user_profile.dart';
import 'package:health_tracker/models/backend/weight_record.dart';
import 'package:health_tracker/models/backend/workout_record.dart';
import 'package:health_tracker/services/backend_repository.dart';

void main() {
  group('BackendRepository', () {
    late FakeFirebaseFirestore firestore;
    late BackendRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = BackendRepository(firestore: firestore);
    });

    test('ensureUserProfile creates then updates profile', () async {
      await repository.ensureUserProfile(
        uid: 'u1',
        email: 'u1@example.com',
        fullName: 'User One',
      );

      await repository.ensureUserProfile(
        uid: 'u1',
        email: 'u1@example.com',
        fullName: 'User One Updated',
      );

      final profile = await repository.getUserProfile('u1');
      expect(profile, isNotNull);
      expect(profile!.fullName, 'User One Updated');
      expect(profile.email, 'u1@example.com');
    });

    test('workout CRUD works', () async {
      final id = await repository.addWorkout(
        uid: 'u1',
        workout: WorkoutRecord(
          id: '',
          name: 'Running',
          durationMinutes: 30,
          caloriesBurned: 260,
          performedAt: DateTime(2026, 4, 3),
        ),
      );

      await repository.updateWorkout(
        uid: 'u1',
        workoutId: id,
        workout: WorkoutRecord(
          id: id,
          name: 'Running Pro',
          durationMinutes: 45,
          caloriesBurned: 370,
          performedAt: DateTime(2026, 4, 3),
        ),
      );

      final list = await repository.getWorkouts(uid: 'u1');
      expect(list, isNotEmpty);
      expect(list.first.name, 'Running Pro');

      await repository.deleteWorkout(uid: 'u1', workoutId: id);
      final afterDelete = await repository.getWorkouts(uid: 'u1');
      expect(afterDelete, isEmpty);
    });

    test('calorie CRUD works', () async {
      final id = await repository.addCalorieRecord(
        uid: 'u1',
        record: CalorieRecord(
          id: '',
          itemName: 'Pho',
          calories: 520,
          recordedAt: DateTime(2026, 4, 3),
        ),
      );

      await repository.updateCalorieRecord(
        uid: 'u1',
        recordId: id,
        record: CalorieRecord(
          id: id,
          itemName: 'Pho bo',
          calories: 560,
          recordedAt: DateTime(2026, 4, 3),
        ),
      );

      final list = await repository.getCalorieRecords(uid: 'u1');
      expect(list, isNotEmpty);
      expect(list.first.itemName, 'Pho bo');

      await repository.deleteCalorieRecord(uid: 'u1', recordId: id);
      final afterDelete = await repository.getCalorieRecords(uid: 'u1');
      expect(afterDelete, isEmpty);
    });

    test('weight CRUD updates profile weight', () async {
      final id = await repository.addWeightRecord(
        uid: 'u1',
        record: WeightRecord(
          id: '',
          weightKg: 67.5,
          recordedAt: DateTime(2026, 4, 3),
        ),
      );

      await repository.updateWeightRecord(
        uid: 'u1',
        recordId: id,
        record: WeightRecord(
          id: id,
          weightKg: 66.8,
          recordedAt: DateTime(2026, 4, 4),
        ),
      );

      final weights = await repository.getWeightRecords(uid: 'u1');
      expect(weights, isNotEmpty);
      expect(weights.first.weightKg, 66.8);

      final profileDoc = await firestore.collection('users').doc('u1').get();
      expect(profileDoc.data()?['weightKg'], 66.8);

      await repository.deleteWeightRecord(uid: 'u1', recordId: id);
      final afterDelete = await repository.getWeightRecords(uid: 'u1');
      expect(afterDelete, isEmpty);
    });

    test('save and get upload metadata scoped by uid', () async {
      await repository.saveUploadMetadata(
        uid: 'u1',
        key: 'foods/u1/1.jpg',
        fileUrl: 'https://worker.dev/foods/u1/1.jpg',
        contentType: 'image/jpeg',
        tag: 'food',
      );
      await repository.saveUploadMetadata(
        uid: 'u2',
        key: 'foods/u2/1.jpg',
        fileUrl: 'https://worker.dev/foods/u2/1.jpg',
        contentType: 'image/jpeg',
        tag: 'food',
      );

      final uploads = await repository.getUploadMetadata(uid: 'u1');
      expect(uploads.length, 1);
      expect(uploads.first['uid'], 'u1');
    });

    test('saveUserProfile merges fields', () async {
      final profile = UserProfile(
        uid: 'u1',
        fullName: 'Merge User',
        email: 'merge@example.com',
        weightKg: 70,
      );

      await repository.saveUserProfile(profile);
      final saved = await repository.getUserProfile('u1');

      expect(saved, isNotNull);
      expect(saved!.fullName, 'Merge User');
      expect(saved.email, 'merge@example.com');
      expect(saved.weightKg, 70);
    });
  });
}
