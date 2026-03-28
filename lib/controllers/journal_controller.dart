import '../models/journal_entry_item.dart';

class JournalController {
  const JournalController();

  List<JournalEntryItem> getEntries() {
    return List<JournalEntryItem>.generate(
      6,
      (index) => JournalEntryItem(title: 'Muc ghi chu mau #${index + 1}'),
    );
  }
}
