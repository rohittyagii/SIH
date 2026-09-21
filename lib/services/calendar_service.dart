import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  // ── Permissions ──────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    var res = await _plugin.hasPermissions();
    if (res.isSuccess && res.data == true) return true;
    res = await _plugin.requestPermissions();
    return res.isSuccess && res.data == true;
  }


  // ── Read: upcoming events ────────────────────────────────────────────────────

  /// Fetches native calendar events for the next [days] days.
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
