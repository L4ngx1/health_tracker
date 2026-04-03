class JournalEntryItem {
  const JournalEntryItem({
    required this.title,
    this.subtitle,
    this.canManage = false,
    this.note,
    this.createdAtIso,
    this.scheduledAtIso,
    this.sortAt,
    this.kind,
    this.steps,
    this.sleepMinutes,
    this.waterMl,
    this.waterGoalMl,
  });

  final String title;
  final String? subtitle;
  final bool canManage;
  final String? note;
  final String? createdAtIso;
  final String? scheduledAtIso;
  final DateTime? sortAt;
  final String? kind;
  final int? steps;
  final int? sleepMinutes;
  final int? waterMl;
  final int? waterGoalMl;
}
