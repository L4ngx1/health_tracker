import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalNoteService {
  static const String _entriesKey = 'journal.entries.v1';

  const JournalNoteService();

  String get _userScope {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';
    if (user.isAnonymous) return 'anon_${user.uid}';
    return user.uid;
  }

  String _accountKey(String base) => '$base.$_userScope';

  String? get _cloudUid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _entriesCollection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journal_entries');
  }

  String _entryKey(Map<String, dynamic> item) {
    final entryType = (item['entryType'] ?? 'note').toString().trim();
    if (entryType == 'daily_summary') {
      final dayKey = (item['dayKey'] ?? '').toString().trim();
      return 'daily_summary|$dayKey';
    }
    final createdAt = (item['createdAt'] ?? '').toString();
    final note = (item['note'] ?? '').toString();
    final scheduledAt = (item['scheduledAt'] ?? '').toString();
    return '$createdAt|$note|$scheduledAt';
  }

  String _dayKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  int _entrySortMs(Map<String, dynamic> item) {
    final ms = item['createdAtMs'];
    if (ms is int) return ms;
    if (ms is num) return ms.toInt();
    if (ms is String) return int.tryParse(ms) ?? 0;
    final createdAt = DateTime.tryParse((item['createdAt'] ?? '').toString());
    return createdAt?.millisecondsSinceEpoch ?? 0;
  }

  List<Map<String, dynamic>> _mergeEntries({
    required List<Map<String, dynamic>> cloud,
    required List<Map<String, dynamic>> local,
  }) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final item in [...cloud, ...local]) {
      final normalized = _sanitizeEntry(item);
      if (normalized['createdAtMs'] == null) {
        final dt = DateTime.tryParse((normalized['createdAt'] ?? '').toString());
        if (dt != null) {
          normalized['createdAtMs'] = dt.millisecondsSinceEpoch;
        }
      }
      final key = _entryKey(normalized);
      if (seen.add(key)) {
        merged.add(normalized);
      }
    }

    merged.sort((a, b) => _entrySortMs(b).compareTo(_entrySortMs(a)));
    return merged.take(100).toList(growable: false);
  }

  Map<String, dynamic> _sanitizeEntry(Map<String, dynamic> source) {
    final out = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null || value is String || value is num || value is bool) {
        out[key] = value;
        return;
      }
      if (value is Timestamp) {
        out[key] = value.toDate().toIso8601String();
        return;
      }
      if (value is DateTime) {
        out[key] = value.toIso8601String();
        return;
      }
      out[key] = value.toString();
    });
    return out;
  }

  Future<void> _saveLocal(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(items.take(100).toList(growable: false));
    await prefs.setString(_accountKey(_entriesKey), payload);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      // Keep a legacy copy so guest notes are still recoverable if anon uid changes.
      await prefs.setString(_entriesKey, payload);
    }
  }

  Future<List<Map<String, dynamic>>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = prefs.getString(_accountKey(_entriesKey));
    final legacy = prefs.getString(_entriesKey);
    final json = (scoped != null && scoped.isNotEmpty) ? scoped : legacy;
    if (json == null || json.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return <Map<String, dynamic>>[];
      final mapped = decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', v)))
          .toList(growable: false);

      if ((scoped == null || scoped.isEmpty) && mapped.isNotEmpty) {
        await _saveLocal(mapped);
      }
      return mapped;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveEntry({
    required String note,
    DateTime? scheduledAt,
  }) async {
    await saveEntryWithSyncStatus(note: note, scheduledAt: scheduledAt);
  }

  Future<bool> saveEntryWithSyncStatus({
    required String note,
    DateTime? scheduledAt,
  }) async {
    final current = await loadRawEntries();
    final now = DateTime.now();

    final next = <Map<String, dynamic>>[
      {
        'entryType': 'note',
        'note': note,
        'createdAt': now.toIso8601String(),
        'createdAtMs': now.millisecondsSinceEpoch,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      },
      ...current,
    ];

    final capped = next.take(100).toList(growable: false);
    await _saveLocal(capped);

    final uid = _cloudUid;
    if (uid == null) return false;
    try {
      await _entriesCollection(uid).add({
        'entryType': 'note',
        'note': note,
        'createdAt': now.toIso8601String(),
        'createdAtMs': now.millisecondsSinceEpoch,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      // Local cache was already saved; cloud sync can retry on next load/save.
      return false;
    }
  }

  Future<bool> upsertDailySummary({
    required DateTime day,
    required int steps,
    required int sleepMinutes,
    required int waterMl,
    required int waterGoalMl,
    double? distanceKm,
    double? caloriesKcal,
  }) async {
    final current = await loadRawEntries();
    final now = DateTime.now();
    final dayKey = _dayKey(day);

    final summary = <String, dynamic>{
      'entryType': 'daily_summary',
      'dayKey': dayKey,
      'createdAt': now.toIso8601String(),
      'createdAtMs': now.millisecondsSinceEpoch,
      'steps': steps,
      'sleepMinutes': sleepMinutes,
      'waterMl': waterMl,
      'waterGoalMl': waterGoalMl,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (caloriesKcal != null) 'caloriesKcal': caloriesKcal,
    };

    final next = <Map<String, dynamic>>[
      summary,
      ...current.where((item) => _entryKey(item) != _entryKey(summary)),
    ].toList(growable: false);

    await _saveLocal(next);

    final uid = _cloudUid;
    if (uid == null) return false;
    try {
      final collection = _entriesCollection(uid);
      final snapshot = await collection
          .where('entryType', isEqualTo: 'daily_summary')
          .where('dayKey', isEqualTo: dayKey)
          .limit(10)
          .get();
      if (snapshot.docs.isEmpty) {
        await collection.add({
          ...summary,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        for (final doc in snapshot.docs) {
          await doc.reference.set({
            ...summary,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadRawEntries() async {
    final local = await _loadLocal();
    final uid = _cloudUid;
    if (uid != null) {
      try {
        List<Map<String, dynamic>> cloud = <Map<String, dynamic>>[];
        final snapshot = await _entriesCollection(uid)
            .orderBy('createdAtMs', descending: true)
            .limit(100)
            .get();
        if (snapshot.docs.isNotEmpty) {
          cloud = snapshot.docs
            .map((d) => _sanitizeEntry(d.data()))
              .toList(growable: false);
        }

        // Fallback for legacy records that only have createdAt string.
        if (cloud.isEmpty) {
          final legacySnapshot = await _entriesCollection(uid)
              .orderBy('createdAt', descending: true)
              .limit(100)
              .get();
          if (legacySnapshot.docs.isNotEmpty) {
            cloud = legacySnapshot.docs
                .map((d) => _sanitizeEntry(d.data()))
                .toList(growable: false);
          }
        }

        final merged = _mergeEntries(cloud: cloud, local: local);

        // Best-effort backfill local-only notes to cloud.
        final cloudKeys = cloud.map(_entryKey).toSet();
        for (final item in merged) {
          final key = _entryKey(item);
          if (cloudKeys.contains(key)) continue;
          try {
            final createdAt = (item['createdAt'] ?? '').toString();
            final createdAtMs = _entrySortMs(item);
            await _entriesCollection(uid).add({
              'note': (item['note'] ?? '').toString(),
              'createdAt': createdAt,
              'createdAtMs': createdAtMs,
              if (item['scheduledAt'] != null)
                'scheduledAt': (item['scheduledAt'] ?? '').toString(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            // Ignore single-item sync errors and keep merged local data visible.
          }
        }

        await _saveLocal(merged);
        return merged;
      } catch (_) {
        // Fall back to local cache below.
      }
    }

    return local;
  }

  bool _entryMatches(
    Map<String, dynamic> item, {
    required String createdAt,
    String? note,
    String? scheduledAt,
  }) {
    if ((item['createdAt'] ?? '').toString() != createdAt) {
      return false;
    }
    if (note != null && (item['note'] ?? '').toString() != note) {
      return false;
    }
    if (scheduledAt != null &&
        (item['scheduledAt'] ?? '').toString() != scheduledAt) {
      return false;
    }
    return true;
  }

  Future<bool> updateEntryByCreatedAt({
    required String createdAt,
    required String note,
    String? scheduledAt,
  }) async {
    final trimmedNote = note.trim();
    if (trimmedNote.isEmpty) return false;

    final current = await loadRawEntries();
    var updated = false;
    final next = current.map((item) {
      if (!_entryMatches(item, createdAt: createdAt, scheduledAt: scheduledAt)) {
        return item;
      }
      updated = true;
      return <String, dynamic>{
        ...item,
        'note': trimmedNote,
      };
    }).toList(growable: false);

    if (!updated) return false;
    await _saveLocal(next);

    final uid = _cloudUid;
    if (uid == null) return true;
    try {
      final snapshot = await _entriesCollection(uid)
          .where('createdAt', isEqualTo: createdAt)
          .get();
      for (final doc in snapshot.docs) {
        final data = _sanitizeEntry(doc.data());
        if (!_entryMatches(data, createdAt: createdAt, scheduledAt: scheduledAt)) {
          continue;
        }
        await doc.reference.set(<String, dynamic>{
          'note': trimmedNote,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Keep local update even if cloud update fails.
    }

    return true;
  }

  Future<bool> deleteEntryByCreatedAt({
    required String createdAt,
    String? note,
    String? scheduledAt,
  }) async {
    final current = await loadRawEntries();
    final next = current
        .where(
          (item) => !_entryMatches(
            item,
            createdAt: createdAt,
            note: note,
            scheduledAt: scheduledAt,
          ),
        )
        .toList(growable: false);

    if (next.length == current.length) {
      return false;
    }

    await _saveLocal(next);

    final uid = _cloudUid;
    if (uid == null) return true;
    try {
      final snapshot = await _entriesCollection(uid)
          .where('createdAt', isEqualTo: createdAt)
          .get();
      for (final doc in snapshot.docs) {
        final data = _sanitizeEntry(doc.data());
        if (!_entryMatches(
          data,
          createdAt: createdAt,
          note: note,
          scheduledAt: scheduledAt,
        )) {
          continue;
        }
        await doc.reference.delete();
      }
    } catch (_) {
      // Keep local delete even if cloud delete fails.
    }

    return true;
  }
}
