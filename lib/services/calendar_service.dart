import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final calendarServiceProvider = Provider<CalendarService>((ref) => CalendarService());

/// A device calendar event fetched from the native calendar.
class DeviceCalendarEvent {
  const DeviceCalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
  });
  final String id;
  final String title;
  final DateTime date;
  final String startTime;
}

class CalendarService {
  final _plugin = DeviceCalendarPlugin();
  final _storage = const FlutterSecureStorage();

  static const _reminderEventIdKey  = 'cal_reminder_event_id';
  static const _reminderCalIdKey    = 'cal_reminder_cal_id';
  static const _reminderTitle       = 'SainikSaathi Check-in Reminder';

  // ── Permissions ──────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    var res = await _plugin.hasPermissions();
    if (res.isSuccess && res.data == true) return true;
    res = await _plugin.requestPermissions();
    return res.isSuccess && res.data == true;
  }

  // ── Write: daily reminder ────────────────────────────────────────────────────

  Future<bool> scheduleReminder(TimeOfDay time) async {
    if (!await requestPermission()) return false;
    await removeReminder();

    final calsResult = await _plugin.retrieveCalendars();
    if (!calsResult.isSuccess || (calsResult.data?.isEmpty ?? true)) return false;

    final cal = calsResult.data!.firstWhere(
      (c) => c.isReadOnly == false,
      orElse: () => calsResult.data!.first,
    );

    final now = DateTime.now();
    tz_data.initializeTimeZones();
    final local = tz.local;
    var tzStart = tz.TZDateTime(local, now.year, now.month, now.day, time.hour, time.minute);
    if (tzStart.isBefore(tz.TZDateTime.now(local))) {
      tzStart = tzStart.add(const Duration(days: 1));
    }
    final tzEnd = tzStart.add(const Duration(minutes: 15));

    final event = Event(
      cal.id,
      title: _reminderTitle,
      start: tzStart,
      end: tzEnd,
      recurrenceRule: RecurrenceRule(RecurrenceFrequency.Daily, interval: 1, totalOccurrences: 365),
      description: 'Daily SainikSaathi wellness check-in reminder.',
    );

    final result = await _plugin.createOrUpdateEvent(event);
    if (result != null && result.isSuccess && (result.data?.isNotEmpty ?? false)) {
      await _storage.write(key: _reminderEventIdKey, value: result.data);
      await _storage.write(key: _reminderCalIdKey,   value: cal.id);
      return true;
    }
    return false;
  }

  Future<void> removeReminder() async {
    final eventId = await _storage.read(key: _reminderEventIdKey);
    final calId   = await _storage.read(key: _reminderCalIdKey);
    if (eventId != null && calId != null) {
      await _plugin.deleteEvent(calId, eventId);
      await _storage.delete(key: _reminderEventIdKey);
      await _storage.delete(key: _reminderCalIdKey);
    }
  }

  // ── Read: upcoming events ────────────────────────────────────────────────────

  /// Fetches native calendar events for the next [days] days, excluding our own reminders.
  Future<List<DeviceCalendarEvent>> fetchUpcomingEvents({int days = 30}) async {
    if (!await requestPermission()) return [];

    final calsResult = await _plugin.retrieveCalendars();
    if (!calsResult.isSuccess || (calsResult.data?.isEmpty ?? true)) return [];

    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    final events = <DeviceCalendarEvent>[];

    for (final cal in calsResult.data!) {
      final result = await _plugin.retrieveEvents(
        cal.id,
        RetrieveEventsParams(startDate: now, endDate: end),
      );
      if (!result.isSuccess || result.data == null) continue;
      for (final e in result.data!) {
        if (e.title == _reminderTitle) continue;
        if (e.start == null) continue;
        events.add(DeviceCalendarEvent(
          id:        e.eventId ?? '',
          title:     e.title ?? '(No title)',
          date:      e.start!,
          startTime: DateFormat('HH:mm').format(e.start!),
        ));
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }
}
