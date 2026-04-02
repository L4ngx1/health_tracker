class SleepSession {
  const SleepSession({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get durationMinutes => end.difference(start).inMinutes;

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  static SleepSession? fromJson(Map<String, dynamic> json) {
    final startRaw = json['start'];
    final endRaw = json['end'];
    if (startRaw is! String || endRaw is! String) {
      return null;
    }
    final start = DateTime.tryParse(startRaw);
    final end = DateTime.tryParse(endRaw);
    if (start == null || end == null || !end.isAfter(start)) {
      return null;
    }
    return SleepSession(start: start, end: end);
  }
}
