class JournalEntryItem {
  const JournalEntryItem({
    required this.title,
    this.subtitle,
    this.canManage = false,
    this.note,
    this.createdAtIso,
    this.scheduledAtIso,
  });

  final String title;
  final String? subtitle;
  final bool canManage;
  final String? note;
  final String? createdAtIso;
  final String? scheduledAtIso;
}
