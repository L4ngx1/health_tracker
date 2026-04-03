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

  String _formatDateTime(MaterialLocalizations localizations, DateTime value) {
    final date = localizations.formatShortDate(value);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
    );
    return '$date $time';
  }

  Future<List<JournalEntryItem>> getFallbackEntries(BuildContext context) async {
    final localizations = MaterialLocalizations.of(context);
    final frameSubtitle = AppStrings.journalFrameSubtitle(context);
    final frameTitle = AppStrings.journalFrameTitle(context);
    final sampleEntries = List<JournalEntryItem>.generate(
      6,
      (index) => JournalEntryItem(
        title: AppStrings.journalSampleEntry(context, index + 1),
        subtitle: frameSubtitle,
      ),
    );
    final raws = await _noteService.loadRawEntries();
    if (raws.isEmpty) {
      return sampleEntries;
    }

    return raws.map((raw) {
      final note = (raw['note'] ?? '').toString().trim();
      final createdAtRaw = (raw['createdAt'] ?? '').toString();
      final scheduledAtRaw = (raw['scheduledAt'] ?? '').toString();
      final createdAt = DateTime.tryParse(createdAtRaw);
      final scheduledAt = DateTime.tryParse(scheduledAtRaw);

      final title = note.isEmpty ? frameTitle : note;

      String? subtitle;
      if (scheduledAt != null) {
        subtitle =
            'Lịch: ${_formatDateTime(localizations, scheduledAt)} • Lưu: ${createdAt != null ? _formatDateTime(localizations, createdAt) : '-'}';
      } else if (createdAt != null) {
        subtitle = 'Lưu lúc: ${_formatDateTime(localizations, createdAt)}';
      }

      return JournalEntryItem(
        title: title,
        subtitle: subtitle,
      );
    }).toList(growable: false);
  }

  Future<List<JournalEntryItem>> getEntries(BuildContext context) async {
    final localizations = MaterialLocalizations.of(context);
    final frameSubtitle = AppStrings.journalFrameSubtitle(context);
    final frameTitle = AppStrings.journalFrameTitle(context);
    final fallback = List<JournalEntryItem>.generate(
      6,
      (index) => JournalEntryItem(
        title: AppStrings.journalSampleEntry(context, index + 1),
        subtitle: frameSubtitle,
      ),
    );
    final noteRaws = await _noteService.loadRawEntries();

    final timeline = noteRaws.map((raw) {
      final note = (raw['note'] ?? '').toString().trim();
      final createdAtRaw = (raw['createdAt'] ?? '').toString();
      final scheduledAtRaw = (raw['scheduledAt'] ?? '').toString();
      final createdAt = DateTime.tryParse(createdAtRaw);
      final scheduledAt = DateTime.tryParse(scheduledAtRaw);
      final title = note.isEmpty ? frameTitle : note;
      String? subtitle;
      if (scheduledAt != null) {
        subtitle =
            'Lịch: ${_formatDateTime(localizations, scheduledAt)} • Lưu: ${createdAt != null ? _formatDateTime(localizations, createdAt) : '-'}';
      } else if (createdAt != null) {
        subtitle = 'Lưu lúc: ${_formatDateTime(localizations, createdAt)}';
      }
      return (
        sortAt: createdAt ?? scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        item: JournalEntryItem(title: title, subtitle: subtitle),
      );
    }).toList(growable: true);

    try {
      final records = await _backendApiService.getMyCalorieRecords(limit: 50);
      timeline.addAll(
        records.map(
          (record) => (
            sortAt: record.recordedAt,
            item: JournalEntryItem(
              title: '${record.itemName} - ${record.calories.round()} kcal',
              subtitle: 'Calories đã lưu',
            ),
          ),
        ),
      );
      if (timeline.isEmpty) {
        return fallback;
      }
      timeline.sort((a, b) => b.sortAt.compareTo(a.sortAt));
      return timeline.map((e) => e.item).toList(growable: false);
    } catch (_) {
      if (timeline.isEmpty) {
        return fallback;
      }
      timeline.sort((a, b) => b.sortAt.compareTo(a.sortAt));
      return timeline.map((e) => e.item).toList(growable: false);
    }
  }
}
