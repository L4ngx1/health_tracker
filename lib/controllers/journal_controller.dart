import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/journal_entry_item.dart';
import '../services/backend_api_service.dart';

class JournalController {
  JournalController({BackendApiService? backendApiService})
    : _backendApiService = backendApiService ?? BackendApiService();

  final BackendApiService _backendApiService;

  List<JournalEntryItem> getFallbackEntries(BuildContext context) {
    return List<JournalEntryItem>.generate(
      6,
      (index) => JournalEntryItem(
        title: AppStrings.journalSampleEntry(context, index + 1),
      ),
    );
  }

  Future<List<JournalEntryItem>> getEntries(BuildContext context) async {
    final fallback = getFallbackEntries(context);
    try {
      final records = await _backendApiService.getMyCalorieRecords(limit: 50);
      if (records.isEmpty) return fallback;

      return records.map((record) {
        return JournalEntryItem(
          title: '${record.itemName} - ${record.calories.round()} kcal',
        );
      }).toList(growable: false);
    } catch (_) {
      return fallback;
    }
  }
}
