import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/workout_history_item.dart';
import '../models/workout_item.dart';
import '../services/backend_api_service.dart';

class WorkoutController {
  WorkoutController({BackendApiService? backendApiService})
    : _backendApiService = backendApiService ?? BackendApiService();

  final BackendApiService _backendApiService;

  List<WorkoutItem> getPrograms(BuildContext context) {
    return [
      WorkoutItem(
        title: AppStrings.workoutProgramRunTitle(context),
        subtitle: AppStrings.workoutProgramRunSubtitle(context),
        icon: Icons.directions_run,
      ),
      WorkoutItem(
        title: AppStrings.workoutProgramGymTitle(context),
        subtitle: AppStrings.workoutProgramGymSubtitle(context),
        icon: Icons.fitness_center,
      ),
      WorkoutItem(
        title: AppStrings.workoutProgramYogaTitle(context),
        subtitle: AppStrings.workoutProgramYogaSubtitle(context),
        icon: Icons.self_improvement,
      ),
      WorkoutItem(
        title: AppStrings.workoutProgramCyclingTitle(context),
        subtitle: AppStrings.workoutProgramCyclingSubtitle(context),
        icon: Icons.pedal_bike,
      ),
    ];
  }

  List<WorkoutHistoryItem> getFallbackHistory(BuildContext context) {
    return [
      WorkoutHistoryItem(
        name: AppStrings.workoutHistoryRunName(context),
        date: AppStrings.workoutHistoryDate1(context),
        duration: AppStrings.workoutHistoryDuration1(context),
        kcal: '320',
      ),
      WorkoutHistoryItem(
        name: AppStrings.workoutHistoryGymName(context),
        date: AppStrings.workoutHistoryDate2(context),
        duration: AppStrings.workoutHistoryDuration2(context),
        kcal: '450',
      ),
    ];
  }

  Future<List<WorkoutHistoryItem>> getHistory(BuildContext context) async {
    final fallback = getFallbackHistory(context);
    try {
      final records = await _backendApiService.getMyWorkouts(limit: 50);
      if (records.isEmpty) return fallback;

      return records.map((record) {
        final dt = record.performedAt;
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final year = dt.year.toString();
        return WorkoutHistoryItem(
          name: record.name,
          date: '$day/$month/$year',
          duration: '${record.durationMinutes} min',
          kcal: record.caloriesBurned.round().toString(),
        );
      }).toList(growable: false);
    } catch (_) {
      return fallback;
    }
  }
}
