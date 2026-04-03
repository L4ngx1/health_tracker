class WorkoutHistoryItem {
  const WorkoutHistoryItem({
    required this.name,
    required this.date,
    required this.duration,
    required this.kcal,
    this.timestampMs,
  });

  final String name;
  final String date;
  final String duration;
  final String kcal;
  final int? timestampMs;
}
