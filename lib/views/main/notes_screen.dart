import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../services/google_calendar_sync_service.dart';
import '../../services/journal_note_service.dart';
import '../../services/permission_queue.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _syncing = false;
  bool _saving = false;
  bool _speechReady = false;
  bool _isListening = false;
  String? _speechHint;
  String? _speechLocaleId;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _navController.addListener(_onNavChanged);
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      var micPermission = await Permission.microphone.status;
      if (!micPermission.isGranted && !micPermission.isLimited) {
        micPermission = await PermissionQueue.instance.enqueue(
          () => Permission.microphone.request(),
        );
      }

      if (!micPermission.isGranted && !micPermission.isLimited) {
        if (!mounted) return;
        setState(() {
          _speechReady = false;
          _speechHint = _isEnglish
              ? 'Microphone permission is required.'
              : 'Cần quyền micro để ghi âm.';
        });
        return;
      }

      final available = await _speech.initialize(
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _speechHint = _isEnglish
                ? 'Speech error: ${error.errorMsg}'
                : 'Lỗi ghi âm: ${error.errorMsg}';
            _isListening = false;
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _isListening = status == 'listening';
          });
        },
      );
      if (!mounted) return;
      String? preferredLocale;
      if (available) {
        try {
          final locales = await _speech.locales();
          for (final locale in locales) {
            final id = locale.localeId.toLowerCase();
            if (id == 'vi_vn' || id == 'vi-vn') {
              preferredLocale = locale.localeId;
              break;
            }
          }
          preferredLocale ??= locales
              .map((e) => e.localeId)
              .firstWhere(
                (id) => id.toLowerCase().startsWith('vi'),
                orElse: () => '',
              );
          if (preferredLocale.isEmpty) {
            preferredLocale = null;
          }
        } catch (_) {
          preferredLocale = null;
        }
      }
      setState(() {
        _speechReady = available;
        _speechLocaleId = preferredLocale;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechReady = false;
        _speechLocaleId = null;
      });
    }
  }

  Future<void> _toggleSpeech() async {
    if (!_speechReady) {
      await _initializeSpeech();
    }
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Speech recognition is not available on this device.'
                : 'Thiết bị này chưa sẵn sàng nhận diện giọng nói.',
          ),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _speechHint = _isEnglish ? 'Recording stopped.' : 'Đã dừng ghi âm.';
      });
      return;
    }

    setState(() {
      _speechHint = _isEnglish
          ? 'Listening in Vietnamese...'
          : 'Đang nghe tiếng Việt...';
    });

    await _speech.listen(
      localeId: _speechLocaleId,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 6),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted) return;
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        setState(() {
          _noteController.text = text;
          _noteController.selection = TextSelection.fromPosition(
            TextPosition(offset: _noteController.text.length),
          );
          _isListening = !result.finalResult;
          _speechHint = result.finalResult
              ? (_isEnglish
                  ? 'Speech converted to text.'
                  : 'Đã chuyển giọng nói thành văn bản.')
              : (_isEnglish
                  ? 'Listening in Vietnamese...'
                  : 'Đang nghe tiếng Việt...');
        });
      },
    );

    if (!mounted) return;
    if (!_speech.isListening) {
      setState(() {
        _speechHint = _isEnglish
            ? 'Cannot start microphone. Check permission/network.'
            : 'Không thể bắt đầu ghi âm. Hãy kiểm tra quyền micro hoặc mạng.';
      });
    }
  }

  void _onNavChanged() {
    if (_navController.index != 3) {
      _noteFocusNode.unfocus();
    }
  }

  bool get _isEnglish => AppStrings.isEnglish(context);

  String _formatScheduledAt(DateTime value) {
    final date = MaterialLocalizations.of(context).formatShortDate(value);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
    );
    return '$date $time';
  }

  Future<void> _pickScheduleDateTime() async {
    _noteFocusNode.unfocus();
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

  Future<void> _syncToGoogleCalendar() async {
    _noteFocusNode.unfocus();
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Please enter note content before syncing.'
                : 'Vui lòng nhập nội dung ghi chú trước khi đồng bộ.',
          ),
        ),
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      await _calendarSyncService.syncNoteToCalendar(
        noteText: note,
        eventStart: _scheduledAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Note synced to Google Calendar.'
                : 'Đã đồng bộ ghi chú lên Google Calendar.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Unable to sync with Google Calendar.'
                : 'Không thể đồng bộ với Google Calendar.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _saveToJournal() async {
    _noteFocusNode.unfocus();
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Please enter note content before saving.'
                : 'Vui lòng nhập nội dung ghi chú trước khi lưu.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final cloudSynced = await _journalNoteService.saveEntryWithSyncStatus(
        note: note,
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      _noteController.clear();
      setState(() => _scheduledAt = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cloudSynced
                ? (_isEnglish
                    ? 'Note saved to database. Opening Journal...'
                    : 'Đã lưu ghi chú lên CSDL. Đang mở Nhật ký...')
                : (_isEnglish
                    ? 'Saved locally. Cloud sync pending.'
                    : 'Đã lưu cục bộ. Đồng bộ CSDL đang chờ.'),
          ),
        ),
      );
      MainNavigationController().setIndex(4);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish ? 'Unable to save note.' : 'Không thể lưu ghi chú.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _navController.removeListener(_onNavChanged);
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _noteFocusNode.unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TopBar(
                  title: AppStrings.notesScreenTitle(context),
                  onUserTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.profile),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _toggleSpeech,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: _isListening
                          ? colorScheme.error
                          : colorScheme.primary,
                      child: Icon(
                        _isListening
                            ? Icons.stop_rounded
                            : Icons.mic_none_rounded,
                        size: 46,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isListening
                        ? (_isEnglish ? 'Recording' : 'Đang ghi âm')
                        : AppStrings.tapToRecord(context),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _speechHint ?? AppStrings.notesPrompt(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.notesContentTitle(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.autoDetect(context),
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                          Icon(Icons.auto_awesome, color: colorScheme.primary),
                        ],
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        autofocus: false,
                        minLines: 3,
                        maxLines: 6,
                        onTapOutside: (_) => _noteFocusNode.unfocus(),
                        decoration: InputDecoration(
                          hintText: AppStrings.notePlaceholder(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickScheduleDateTime,
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                _scheduledAt == null
                                    ? (_isEnglish
                                        ? 'Pick date & time'
                                        : 'Chọn ngày và giờ')
                                    : _formatScheduledAt(_scheduledAt!),
                              ),
                            ),
                          ),
                          if (_scheduledAt != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() => _scheduledAt = null);
                              },
                              tooltip: _isEnglish ? 'Clear' : 'Xóa',
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scheduledAt == null
                            ? (_isEnglish
                                ? 'No schedule selected: event will be created for now + 5 minutes.'
                                : 'Chưa chọn lịch: sự kiện sẽ được tạo ở thời điểm hiện tại + 5 phút.')
                            : (_isEnglish
                                ? 'Selected schedule for calendar event.'
                                : 'Đã chọn thời gian cho sự kiện lịch.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChipLabel(AppStrings.tagHealth(context)),
                          ChipLabel(AppStrings.tagDaily(context)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _saveToJournal,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isEnglish ? 'Save note' : 'Lưu ghi chú',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _syncing ? null : _syncToGoogleCalendar,
                        icon: _syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _isEnglish ? 'Sync calendar' : 'Đồng bộ lịch',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        title: AppStrings.quickMealTitle(context),
                        subtitle: AppStrings.quickMealSubtitle(context),
                        icon: Icons.restaurant_menu,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: QuickActionCard(
                        title: AppStrings.quickMoodTitle(context),
                        subtitle: AppStrings.quickMoodSubtitle(context),
                        icon: Icons.sentiment_satisfied_alt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
