class JournalEntryItem {
  const JournalEntryItem({
    required this.title,
    this.subtitle,
    this.canManage = false,
    this.note,
    this.createdAtIso,
    this.scheduledAtIso,
    this.occurredAt,
    this.category = 'general',
  });

  final String title;
  final String? subtitle;
  final bool canManage;
  final String? note;
  final String? createdAtIso;
  final String? scheduledAtIso;
  final DateTime? occurredAt;
  final String category;
}
