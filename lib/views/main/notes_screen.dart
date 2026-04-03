import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../services/google_calendar_sync_service.dart';
import '../../services/journal_note_service.dart';
import '../widgets/common_widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final MainNavigationController _navController = MainNavigationController();
  final GoogleCalendarSyncService _calendarSyncService =
      const GoogleCalendarSyncService();
  final JournalNoteService _journalNoteService = const JournalNoteService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _syncing = false;
  bool _saving = false;
  bool _speechReady = false;
  bool _listening = false;
  String _speechLocaleId = 'vi_VN';
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _navController.addListener(_onNavChanged);
    unawaited(_initializeSpeech());
  }

  @override
  void dispose() {
    _navController.removeListener(_onNavChanged);
    _speechToText.stop();
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNavChanged() {
    if (_navController.index != 3) {
      _noteFocusNode.unfocus();
    }
  }

  bool get _isEnglish => AppStrings.isEnglish(context);

  Future<void> _initializeSpeech() async {
    final available = await _speechToText.initialize();
    if (!mounted) return;
    setState(() {
      _speechReady = available;
      _speechLocaleId = 'vi_VN';
    });
  }

  Future<void> _toggleSpeechToText() async {
    if (!_speechReady) {
      await _initializeSpeech();
    }
    if (!_speechReady) return;

    if (_speechToText.isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      return;
    }

    await _speechToText.listen(
      localeId: _speechLocaleId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        onDevice: false,
      ),
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (!mounted || words.isEmpty) return;
        if (result.finalResult) {
          final current = _noteController.text.trim();
          final next = current.isEmpty ? words : '$current $words';
          _noteController.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
          setState(() => _listening = false);
        }
      },
    );

    if (!mounted) return;
    setState(() => _listening = true);
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(minutes: 10));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveToJournal() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _journalNoteService.saveEntryWithSyncStatus(
        note: note,
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      _noteController.clear();
      setState(() => _scheduledAt = null);
      MainNavigationController().setIndex(4);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncToGoogleCalendar() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;
    setState(() => _syncing = true);
    try {
      await _calendarSyncService.syncNoteToCalendar(
        noteText: note,
        eventStart: _scheduledAt,
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: AppStrings.notesScreenTitle(context),
                onUserTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                focusNode: _noteFocusNode,
                minLines: 6,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: AppStrings.notePlaceholder(context),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickScheduleDateTime,
                      icon: const Icon(Icons.schedule),
                      label: const Text('Schedule'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _speechReady ? _toggleSpeechToText : null,
                      icon: Icon(_listening ? Icons.stop : Icons.mic),
                      label: Text(_isEnglish ? 'Voice' : 'Giong noi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveToJournal,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save note'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _syncing ? null : _syncToGoogleCalendar,
                      icon: _syncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calendar_month_outlined),
                      label: const Text('Sync calendar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
