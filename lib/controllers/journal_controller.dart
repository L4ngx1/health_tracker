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

  DateTime? _parseSortDate(Map<String, dynamic> raw) {
    final kind = (raw['entryType'] ?? 'note').toString().trim();
    if (kind == 'daily_summary') {
      final dayKey = (raw['dayKey'] ?? '').toString().trim();
      if (dayKey.isNotEmpty) {
        return DateTime.tryParse('${dayKey}T00:00:00');
      }
    }

    final createdAtRaw = (raw['createdAt'] ?? '').toString();
    final scheduledAtRaw = (raw['scheduledAt'] ?? '').toString();
    return DateTime.tryParse(createdAtRaw) ?? DateTime.tryParse(scheduledAtRaw);
  }

  String? _metricSubtitle(
    MaterialLocalizations localizations,
    Map<String, dynamic> raw,
  ) {
    final kind = (raw['entryType'] ?? 'note').toString().trim();
    if (kind != 'daily_summary') return null;

    final day = _parseSortDate(raw);
    final dayText = day == null ? 'Hôm nay' : _formatDateTime(localizations, day);
    final steps = int.tryParse('${raw['steps'] ?? ''}') ?? 0;
    final sleepMinutes = int.tryParse('${raw['sleepMinutes'] ?? ''}') ?? 0;
    final waterMl = int.tryParse('${raw['waterMl'] ?? ''}') ?? 0;
    final waterGoalMl = int.tryParse('${raw['waterGoalMl'] ?? ''}') ?? 0;
    final distanceKm = double.tryParse('${raw['distanceKm'] ?? ''}');
    final caloriesKcal = double.tryParse('${raw['caloriesKcal'] ?? ''}');

    final sleepHours = sleepMinutes ~/ 60;
    final sleepRemain = sleepMinutes % 60;
    final sleepText = sleepMinutes <= 0
        ? '0 phút'
        : sleepHours > 0
            ? '${sleepHours}h ${sleepRemain}m'
            : '$sleepMinutes phút';

    final parts = <String>[
      'Ngày: $dayText',
      'Bước: $steps',
      'Ngủ: $sleepText',
      'Nước: $waterMl${waterGoalMl > 0 ? '/$waterGoalMl ml' : ' ml'}',
      if (distanceKm != null) 'Quãng đường: ${distanceKm.toStringAsFixed(1)} km',
      if (caloriesKcal != null) 'Calories: ${caloriesKcal.round()} kcal',
    ];
    return parts.join(' • ');
  }

  JournalEntryItem _mapRawToEntry(
    BuildContext context,
    Map<String, dynamic> raw,
  ) {
    final localizations = MaterialLocalizations.of(context);
    final frameTitle = AppStrings.journalFrameTitle(context);
    final note = (raw['note'] ?? '').toString().trim();
    final createdAtRaw = (raw['createdAt'] ?? '').toString();
    final scheduledAtRaw = (raw['scheduledAt'] ?? '').toString();
    final createdAt = _parseSortDate(raw) ?? DateTime.tryParse(createdAtRaw);
    final scheduledAt = DateTime.tryParse(scheduledAtRaw);
    final kind = (raw['entryType'] ?? 'note').toString().trim();
    final title = kind == 'daily_summary'
        ? 'Tổng hợp sức khỏe trong ngày'
        : (note.isEmpty ? frameTitle : note);

    String? subtitle;
    if (kind == 'daily_summary') {
      subtitle = _metricSubtitle(localizations, raw);
    } else if (scheduledAt != null) {
      subtitle =
          'Lịch: ${_formatDateTime(localizations, scheduledAt)} • Lưu: ${createdAt != null ? _formatDateTime(localizations, createdAt) : '-'}';
    } else if (createdAt != null) {
      subtitle = 'Lưu lúc: ${_formatDateTime(localizations, createdAt)}';
    }

    return JournalEntryItem(
      title: title,
      subtitle: subtitle,
      canManage: true,
      note: note,
      createdAtIso: createdAtRaw,
      scheduledAtIso: scheduledAtRaw.isEmpty ? null : scheduledAtRaw,
      sortAt: createdAt ?? scheduledAt,
      kind: kind,
      steps: int.tryParse('${raw['steps'] ?? ''}'),
      sleepMinutes: int.tryParse('${raw['sleepMinutes'] ?? ''}'),
      waterMl: int.tryParse('${raw['waterMl'] ?? ''}'),
      waterGoalMl: int.tryParse('${raw['waterGoalMl'] ?? ''}'),
    );
  }

  Future<List<JournalEntryItem>> getFallbackEntries(BuildContext context) async {
    final frameSubtitle = AppStrings.journalFrameSubtitle(context);
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
      return _mapRawToEntry(context, raw);
    }).toList(growable: false);
  }

  Future<List<JournalEntryItem>> getEntries(BuildContext context) async {
    final frameSubtitle = AppStrings.journalFrameSubtitle(context);
    final fallback = List<JournalEntryItem>.generate(
      6,
      (index) => JournalEntryItem(
        title: AppStrings.journalSampleEntry(context, index + 1),
        subtitle: frameSubtitle,
      ),
    );
    final noteRaws = await _noteService.loadRawEntries();

    final timeline = noteRaws.map((raw) {
      final item = _mapRawToEntry(context, raw);
      return (
        sortAt: item.sortAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        item: item,
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
              canManage: false,
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

  Future<bool> addNote(String note) {
    return _noteService.saveEntryWithSyncStatus(note: note);
  }

  Future<bool> updateNote({
    required JournalEntryItem entry,
    required String note,
  }) async {
    final createdAt = entry.createdAtIso;
    if (createdAt == null || createdAt.isEmpty) return false;
    return _noteService.updateEntryByCreatedAt(
      createdAt: createdAt,
      note: note,
      scheduledAt: entry.scheduledAtIso,
    );
  }

  Future<bool> deleteNote(JournalEntryItem entry) async {
    final createdAt = entry.createdAtIso;
    if (createdAt == null || createdAt.isEmpty) return false;
    return _noteService.deleteEntryByCreatedAt(
      createdAt: createdAt,
      note: entry.note,
      scheduledAt: entry.scheduledAtIso,
    );
  }
}
