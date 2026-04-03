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

  Future<void> _saveLocal(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(items.take(100).toList(growable: false));
    await prefs.setString(_accountKey(_entriesKey), payload);
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
    final current = await loadRawEntries();
    final now = DateTime.now();

    final next = <Map<String, dynamic>>[
      {
        'note': note,
        'createdAt': now.toIso8601String(),
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      },
      ...current,
    ];

    final capped = next.take(100).toList(growable: false);
    await _saveLocal(capped);

    final uid = _cloudUid;
    if (uid == null) return;
    try {
      await _entriesCollection(uid)
          .doc(now.millisecondsSinceEpoch.toString())
          .set({
            'note': note,
            'createdAt': now.toIso8601String(),
            if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Local cache was already saved; cloud sync can retry on next load/save.
    }
  }

  Future<List<Map<String, dynamic>>> loadRawEntries() async {
    final uid = _cloudUid;
    if (uid != null) {
      try {
        final snapshot = await _entriesCollection(uid)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final cloud = snapshot.docs
              .map((d) => d.data())
              .toList(growable: false);
          await _saveLocal(cloud);
          return cloud;
        }
      } catch (_) {
        // Fall back to local cache below.
      }
    }

    return _loadLocal();
  }
}
