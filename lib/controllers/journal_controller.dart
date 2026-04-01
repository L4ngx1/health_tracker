import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/journal_entry_item.dart';

class JournalController {
  const JournalController();

  List<JournalEntryItem> getEntries(BuildContext context) {
    return List<JournalEntryItem>.generate(
      6,
      (index) => JournalEntryItem(
        title: AppStrings.journalSampleEntry(context, index + 1),
      ),
    );
  }
}
