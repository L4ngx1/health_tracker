import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';
import '../models/journal_entry_item.dart';
import '../services/journal_note_service.dart';
import '../services/backend_api_service.dart';

class JournalController {
  JournalController({BackendApiService? backendApiService})
    : _backendApiService = backendApiService ?? BackendApiService();

  final BackendApiService _backendApiService;

  static const JournalNoteService _noteService = JournalNoteService();

  String _formatDateTime(BuildContext context, DateTime value) {
    final date = MaterialLocalizations.of(context).formatShortDate(value);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
    );
    return '$date $time';
  }

  Future<List<JournalEntryItem>> getFallbackEntries(BuildContext context) async {
    final raws = await _noteService.loadRawEntries();
    if (raws.isEmpty) {
      return List<JournalEntryItem>.generate(
        6,
        (index) => JournalEntryItem(
          title: AppStrings.journalSampleEntry(context, index + 1),
          subtitle: AppStrings.journalFrameSubtitle(context),
        ),
      );
    }

    return raws.map((raw) {
      final note = (raw['note'] ?? '').toString().trim();
      final createdAtRaw = (raw['createdAt'] ?? '').toString();
      final scheduledAtRaw = (raw['scheduledAt'] ?? '').toString();
      final createdAt = DateTime.tryParse(createdAtRaw);
      final scheduledAt = DateTime.tryParse(scheduledAtRaw);

      final title = note.isEmpty
          ? AppStrings.journalFrameTitle(context)
          : note;

      String? subtitle;
      if (scheduledAt != null) {
        subtitle =
            'Lịch: ${_formatDateTime(context, scheduledAt)} • Lưu: ${createdAt != null ? _formatDateTime(context, createdAt) : '-'}';
      } else if (createdAt != null) {
        subtitle = 'Lưu lúc: ${_formatDateTime(context, createdAt)}';
      }

      return JournalEntryItem(
        title: title,
        subtitle: subtitle,
      );
    }).toList(growable: false);
  }

  Future<List<JournalEntryItem>> getEntries(BuildContext context) async {
    final fallback = await getFallbackEntries(context);
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
