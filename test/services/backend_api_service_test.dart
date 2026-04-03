import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/models/backend/calorie_record.dart';
import 'package:health_tracker/models/backend/weight_record.dart';
import 'package:health_tracker/models/backend/workout_record.dart';
import 'package:health_tracker/services/backend_api_service.dart';
import 'package:health_tracker/services/backend_repository.dart';

void main() {
  group('BackendApiService', () {
    late FakeFirebaseFirestore firestore;
    late BackendRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = BackendRepository(firestore: firestore);
    });

    test('uses injected uidProvider to scope writes', () async {
      final service = BackendApiService(
        repository: repository,
        uidProvider: () => 'user_a',
      );

      await service.addMyWorkout(
        WorkoutRecord(
          id: '',
          name: 'Gym',
          durationMinutes: 50,
          caloriesBurned: 420,
          performedAt: DateTime(2026, 4, 3),
        ),
      );

      final docs = await firestore
          .collection('users')
          .doc('user_a')
          .collection('workouts')
          .get();

      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['name'], 'Gym');
    });

    test('throws StateError without auth and uidProvider', () async {
      final service = BackendApiService(repository: repository);

      expect(
        () => service.getMyWorkouts(),
        throwsA(isA<StateError>()),
      );
    });

    test('calorie and weight api methods roundtrip', () async {
      final service = BackendApiService(
        repository: repository,
        uidProvider: () => 'user_a',
      );

      await service.addMyCalorieRecord(
        CalorieRecord(
          id: '',
          itemName: 'Banh mi',
          calories: 330,
          recordedAt: DateTime(2026, 4, 3),
        ),
      );
      await service.addMyWeightRecord(
        WeightRecord(
          id: '',
          weightKg: 65.2,
          recordedAt: DateTime(2026, 4, 3),
        ),
      );

      final calories = await service.getMyCalorieRecords();
      final weights = await service.getMyWeightRecords();

      expect(calories, isNotEmpty);
      expect(calories.first.itemName, 'Banh mi');
      expect(weights, isNotEmpty);
      expect(weights.first.weightKg, 65.2);
    });
  });
}
