import 'package:flutter/material.dart';

import '../../controllers/main_navigation_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../services/google_calendar_sync_service.dart';
import '../../services/journal_note_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/workout_widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  final GoogleCalendarSyncService _calendarSyncService =
      const GoogleCalendarSyncService();
  final JournalNoteService _journalNoteService = const JournalNoteService();
  bool _syncing = false;
  bool _saving = false;
  DateTime? _scheduledAt;

  bool get _isEnglish => AppStrings.isEnglish(context);

  String _formatScheduledAt(DateTime value) {
    final date = MaterialLocalizations.of(context).formatShortDate(value);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
    );
    return '$date $time';
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

  Future<void> _syncToGoogleCalendar() async {
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
      await _journalNoteService.saveEntry(
        note: note,
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      _noteController.clear();
      setState(() => _scheduledAt = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Note saved. Opening Journal...'
                : 'Đã lưu ghi chú. Đang mở Nhật ký...',
          ),
        ),
      );
      MainNavigationController().setIndex(4);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Unable to save note.'
                : 'Không thể lưu ghi chú.',
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
    _noteController.dispose();
    super.dispose();
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
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: 46,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  AppStrings.tapToRecord(context),
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
                  AppStrings.notesPrompt(context),
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
                      minLines: 3,
                      maxLines: 6,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _isEnglish
                            ? 'Sync calendar'
                            : 'Đồng bộ lịch',
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
    );
  }
}
