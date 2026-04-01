import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/workout_history_item.dart';
import '../models/workout_item.dart';

class WorkoutController {
  const WorkoutController();

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

  List<WorkoutHistoryItem> getHistory(BuildContext context) {
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
}
