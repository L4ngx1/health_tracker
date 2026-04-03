import 'package:add_2_calendar/add_2_calendar.dart';

class GoogleCalendarSyncService {
  const GoogleCalendarSyncService();

  Future<void> syncNoteToCalendar({
    required String noteText,
    DateTime? eventStart,
  }) async {
    final now = DateTime.now();
    final start = eventStart ?? now.add(const Duration(minutes: 5));
    final end = start.add(const Duration(minutes: 30));

    final event = Event(
      title: 'Health Note',
      description: noteText,
      location: 'Health Tracker',
      startDate: start,
      endDate: end,
      iosParams: const IOSParams(reminder: Duration(minutes: 15)),
      androidParams: const AndroidParams(),
    );

    await Add2Calendar.addEvent2Cal(event);
  }
}
