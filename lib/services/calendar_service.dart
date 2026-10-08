// Import the device_calendar package which allows us to interact with the device's native calendars (like Google Calendar or Apple Calendar).
import 'package:device_calendar/device_calendar.dart';
// Import Riverpod, which is a state management and dependency injection framework for Flutter. It helps us manage our application's state and dependencies easily.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import the intl package, which provides internationalization and localization facilities, including date and time formatting.
import 'package:intl/intl.dart';

// Create a global provider for our CalendarService. Providers are like global variables but safer and manageable.
// This allows other parts of our app to easily access the CalendarService instance without creating a new one every time.
final calendarServiceProvider = Provider<CalendarService>((ref) => CalendarService());

/// A custom class representing a device calendar event fetched from the native calendar.
/// We use this custom class to hold only the data we need (id, title, date, startTime) rather than dealing with the complex Event class from the plugin everywhere.
class DeviceCalendarEvent {
  // A constant constructor for the class. Using 'const' here can improve performance if we create instances with constant values.
  // The 'required' keyword means that whoever creates a DeviceCalendarEvent MUST provide all these values.
  const DeviceCalendarEvent({
    required this.id, // The unique identifier for the event.
    required this.title, // The name or title of the event.
    required this.date, // The full date and time when the event starts.
    required this.startTime, // A formatted string representing only the start time (e.g., "14:30").
  });
  
  // The unique identifier for the event, declared as a final String meaning it cannot be changed after creation.
  final String id;
  // The title of the event, declared as a final String.
  final String title;
  // The start date and time of the event, declared as a final DateTime object.
  final DateTime date;
  // The formatted start time of the event, declared as a final String.
  final String startTime;
}

// The main service class that handles interactions with the device's calendar.
class CalendarService {
  // Create a private instance of the DeviceCalendarPlugin. 
  // The underscore (_) before the name makes it private, meaning it can only be accessed from within this file.
  // This plugin provides the actual methods to read/write to the device's calendar.
  final _plugin = DeviceCalendarPlugin();

  // ── Permissions ──────────────────────────────────────────────────────────────

  // A method to check and request calendar permissions from the user.
  // It returns a Future<bool>, which means it will eventually provide a true or false value (true if permission is granted, false otherwise).
  Future<bool> requestPermission() async {
    // Check if the app already has permission to access the calendar.
    var res = await _plugin.hasPermissions();
    // If the check was successful and permission is already granted (true), return true.
    if (res.isSuccess && res.data == true) return true;
    
    // If we don't have permission yet, ask the user for it. A system dialog will pop up.
    res = await _plugin.requestPermissions();
    // Return true if the request was successful and the user granted permission, otherwise false.
    return res.isSuccess && res.data == true;
  }


  // ── Read: upcoming events ────────────────────────────────────────────────────

  /// Fetches native calendar events for the next [days] days. By default, it fetches events for the next 30 days.
  // Returns a Future containing a List of our custom DeviceCalendarEvent objects.
  Future<List<DeviceCalendarEvent>> fetchUpcomingEvents({int days = 30}) async {
    // First, try to get permission. If permission is denied, return an empty list immediately.
    if (!await requestPermission()) return [];

    // Retrieve all calendars available on the device (e.g., Work calendar, Personal calendar, Birthdays).
    final calsResult = await _plugin.retrieveCalendars();
    // If retrieving calendars failed or if there are no calendars found, return an empty list.
    if (!calsResult.isSuccess || (calsResult.data?.isEmpty ?? true)) return [];

    // Get the current date and time.
    final now = DateTime.now();
    // Calculate the end date by adding the specified number of 'days' to the current time.
    final end = now.add(Duration(days: days));
    // Create an empty list to store the events we find. This will hold our custom DeviceCalendarEvent objects.
    final events = <DeviceCalendarEvent>[];

    // Loop through each calendar we found on the device.
    for (final cal in calsResult.data!) {
      // For each calendar, ask the plugin to retrieve events that fall between 'now' and 'end'.
      final result = await _plugin.retrieveEvents(
        cal.id, // The ID of the specific calendar we are currently checking.
        RetrieveEventsParams(startDate: now, endDate: end), // The time range for the events.
      );
      // If fetching events for this calendar failed, or if it returned null data, skip to the next calendar using 'continue'.
      if (!result.isSuccess || result.data == null) continue;
      
      // Loop through each event found in the current calendar.
      for (final e in result.data!) {
        // If the event doesn't have a start time for some reason, ignore it and skip to the next event.
        if (e.start == null) continue;
        
        // Convert the native event into our custom DeviceCalendarEvent object and add it to our list.
        events.add(DeviceCalendarEvent(
          // Use the event's ID, or an empty string if it's null (using the ?? operator).
          id:        e.eventId ?? '',
          // Use the event's title, or '(No title)' if it doesn't have one.
          title:     e.title ?? '(No title)',
          // The start time of the event (we know it's not null because we checked above).
          date:      e.start!,
          // Format the start time into a 24-hour hour:minute format string (e.g., "14:30") using the intl package.
          startTime: DateFormat('HH:mm').format(e.start!),
        ));
      }
    }

    // After gathering all events from all calendars, sort them in chronological order.
    // The compareTo method compares the start dates of two events (a and b) and orders them from earliest to latest.
    events.sort((a, b) => a.date.compareTo(b.date));
    
    // Finally, return the sorted list of upcoming events.
    return events;
  }
}
