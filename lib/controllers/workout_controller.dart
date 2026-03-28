import 'package:flutter/material.dart';

import '../models/workout_history_item.dart';
import '../models/workout_item.dart';

class WorkoutController {
  const WorkoutController();

  List<WorkoutItem> getPrograms() {
    return const [
      WorkoutItem(
        title: 'Chay bo',
        subtitle: 'Cardio chuyen\nsau',
        icon: Icons.directions_run,
      ),
      WorkoutItem(
        title: 'Gym',
        subtitle: 'Tang cuong co bap',
        icon: Icons.fitness_center,
      ),
      WorkoutItem(
        title: 'Yoga',
        subtitle: 'Thu gian tam tri',
        icon: Icons.self_improvement,
      ),
      WorkoutItem(
        title: 'Dap xe',
        subtitle: 'Dot mo hieu\nqua',
        icon: Icons.pedal_bike,
      ),
    ];
  }

  List<WorkoutHistoryItem> getHistory() {
    return const [
      WorkoutHistoryItem(
        name: 'Chay bo',
        date: '14 Th05, 2024',
        duration: '45 phut',
        kcal: '320',
      ),
      WorkoutHistoryItem(
        name: 'Gym',
        date: '12 Th05, 2024',
        duration: '60 phut',
        kcal: '450',
      ),
    ];
  }
}
