import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_strings.dart';
import '../models/journal_entry_item.dart';
import '../services/journal_note_service.dart';
import '../services/backend_api_service.dart';
import '../services/health_journal_service.dart';

class JournalController {
  JournalController({BackendApiService? backendApiService})
    : _backendApiService = backendApiService ?? BackendApiService();

  final BackendApiService _backendApiService;

  static const JournalNoteService _noteService = JournalNoteService();
  static const HealthJournalService _healthJournalService =
      HealthJournalService();
  static const String _prefWorkoutHistory = 'workout.history.v1';

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _accountKey(String base) => '$base.$_userScope';

  String _formatDateTime(MaterialLocalizations localizations, DateTime value) {
    final date = localizations.formatShortDate(value);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
    );
    return '$date $time';
  }

  String _formatDate(MaterialLocalizations localizations, DateTime value) {
    return localizations.formatShortDate(value);
  }

  List<JournalEntryItem> _mapWorkoutHistoryEntries(
    MaterialLocalizations localizations,
    SharedPreferences prefs,
  ) {
    final raw = prefs.getString(_accountKey(_prefWorkoutHistory));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <JournalEntryItem>[];
      for (final element in decoded) {
        if (element is! Map) continue;
        final item = element.map((k, v) => MapEntry('$k', v));
        final tsRaw = item['timestampMs'];
        final ts = tsRaw is int ? tsRaw : int.tryParse('$tsRaw');
        if (ts == null) continue;
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        final name = (item['name'] ?? '').toString().trim();
        final duration = (item['duration'] ?? '').toString().trim();
        final kcal = (item['kcal'] ?? '').toString().trim();

        out.add(
          JournalEntryItem(
            title: name.isEmpty ? 'Buổi tập' : name,
            subtitle:
                '${_formatDateTime(localizations, dt)} • $duration • $kcal kcal',
            canManage: false,
            occurredAt: dt,
            category: 'workout-history',
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
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
        canManage: true,
        note: note,
        createdAtIso: createdAtRaw,
        scheduledAtIso: scheduledAtRaw.isEmpty ? null : scheduledAtRaw,
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
        occurredAt: DateTime.now().subtract(Duration(days: index)),
      ),
    );

    await _healthJournalService.captureTodaySnapshot();
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
        item: JournalEntryItem(
          title: title,
          subtitle: subtitle,
          canManage: true,
          note: note,
          createdAtIso: createdAtRaw,
          scheduledAtIso: scheduledAtRaw.isEmpty ? null : scheduledAtRaw,
          occurredAt: createdAt ?? scheduledAt,
          category: 'note',
        ),
      );
    }).toList(growable: true);

    final healthLogs = await _healthJournalService.loadLogs();
    timeline.addAll(
      healthLogs.map(
        (log) => (
          sortAt: log.date,
          item: JournalEntryItem(
            title: 'Nhật ký sức khỏe ${_formatDate(localizations, log.date)}',
            subtitle:
                'Bước: ${log.steps} • Ngủ: ${log.sleepMinutes} phút • Nước: ${log.waterMl} ml • Tập: ${log.workoutSessions} buổi (${log.workoutCalories} kcal)',
            canManage: false,
            occurredAt: log.date,
            category: 'health-daily',
          ),
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutEntries = _mapWorkoutHistoryEntries(localizations, prefs);
      timeline.addAll(
        workoutEntries.map(
          (entry) => (
            sortAt: entry.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            item: entry,
          ),
        ),
      );
    } catch (_) {
      // Ignore local workout history parse errors.
    }

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
              occurredAt: record.recordedAt,
              category: 'calorie',
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
      scheduledAt: entry.scheduledAtIso,
    );
  }
}
