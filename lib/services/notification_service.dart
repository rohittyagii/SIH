// Importing the material design library which gives us UI components and things like TimeOfDay.
import 'package:flutter/material.dart';

// Importing the flutter_local_notifications package to create and manage local notifications.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Importing riverpod for state management. This lets us easily provide and access our NotificationService anywhere.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importing secure storage to safely save the user's notification preferences on the device.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Importing flutter_timezone to figure out which time zone the user's device is currently in.
import 'package:flutter_timezone/flutter_timezone.dart';

// Importing timezone data to initialize the timezone database so we can schedule notifications accurately.
import 'package:timezone/data/latest.dart' as tz_data;

// Importing timezone logic to work with timezone-aware date and time objects (TZDateTime).
import 'package:timezone/timezone.dart' as tz;

// Creating a global provider for our NotificationService. 
// This makes it easy for other parts of the app to access the same instance of NotificationService.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// Persisted reminder configuration.
/// This class holds the data for a reminder: whether it's on, and at what hour and minute it should fire.
class ReminderConfig {
  // A constant constructor that requires all three properties to be provided when making a new ReminderConfig.
  const ReminderConfig({
    required this.enabled, // Is the reminder turned on?
    required this.hour,    // At what hour (0-23)?
    required this.minute,  // At what minute (0-59)?
  });
  
  // The 'final' keyword means these values cannot be changed once the object is created.
  final bool enabled;
  final int hour;
  final int minute;

  // A helper "getter" method that converts our hour and minute into a Flutter TimeOfDay object.
  // This is useful because many Flutter UI components (like time pickers) use TimeOfDay.
  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

/// Callback invoked when user taps a notification.
/// Set by main.dart to navigate into the app.
// The @pragma('vm:entry-point') annotation tells the Dart compiler not to remove this function,
// because it might be called directly by the native OS (Android/iOS) when the app is in the background.
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  // This function is triggered when the user taps on a notification.
  // It calls a static callback (if it's not null) that we can set up in our main.dart file.
  // This allows us to handle the tap (like navigating to a specific screen) from the UI layer.
  NotificationService.onNotificationTap?.call(response);
}

// The main class that handles everything related to notifications.
class NotificationService {
  // A static (shared) instance of the FlutterLocalNotificationsPlugin.
  // We use this single instance to talk to the underlying Android/iOS notification systems.
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
      
  // A static instance of FlutterSecureStorage to save and load reminder settings securely.
  static const _storage = FlutterSecureStorage();

  /// External callback set by main.dart to handle notification taps.
  // A static variable that holds a function. This lets other parts of the app decide what happens when a notification is tapped.
  static void Function(NotificationResponse)? onNotificationTap;

  // Fixed notification ID — guarantees cancel/replace behaviour.
  // We use 0 as the ID for our daily reminder. If we schedule a new notification with ID 0, 
  // it automatically replaces any existing notification with ID 0.
  static const int _dailyReminderId = 0;

  // SecureStorage keys
  // These are the string names we use to save our data in secure storage.
  static const _keyEnabled = 'reminder_enabled'; // Key for saving if the reminder is on or off.
  static const _keyHour = 'reminder_hour';       // Key for saving the reminder hour.
  static const _keyMinute = 'reminder_minute';   // Key for saving the reminder minute.

  // Android notification channel
  // On Android 8.0 and above, notifications must belong to a "Channel".
  // We define a channel here with a unique ID, a name, a description, and high importance (to make it pop up).
  static const _channel = AndroidNotificationChannel(
    'sainik_saathi_reminders',            // The unique ID for the channel.
    'Check-in Reminders',                 // The user-visible name of the channel.
    description: 'Daily wellness check-in reminders', // The user-visible description.
    importance: Importance.high,          // High importance usually means it makes a sound and appears on screen.
  );

  // ── Initialisation ────────────────────────────────────────────────────────

  // An asynchronous method to set up notifications when the app starts.
  Future<void> init() async {
    // 1. Initialize the time zones database so we can do timezone math.
    tz_data.initializeTimeZones();
    
    // 2. Ask the device for its current local timezone string (e.g., "America/New_York").
    var tzName = await FlutterTimezone.getLocalTimezone();
    
    // Sometimes the timezone library prefers "Asia/Kolkata" over "Asia/Calcutta".
    // If the device reports "Asia/Calcutta", we change it to "Asia/Kolkata" to avoid errors.
    if (tzName == 'Asia/Calcutta') {
      tzName = 'Asia/Kolkata';
    }
    
    // 3. Tell the timezone library to set this specific location as our local default.
    tz.setLocalLocation(tz.getLocation(tzName));

    // 4. Set up the Android-specific settings. 
    // '@mipmap/ic_launcher' tells it to use the app's default launcher icon for the notification.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 5. Set up the iOS (Darwin)-specific settings.
    // We are asking for permission to show alerts, update the app badge, and play sounds.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Combine the Android and iOS settings into one InitializationSettings object.
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // 6. Actually initialize the plugin using the settings we just created.
    // We also tell it to call 'onDidReceiveNotificationResponse' if a notification is tapped.
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // 7. Create the Android notification channel.
    // We have to specifically get the Android version of the plugin to do this.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    // If we are on Android (androidPlugin is not null), we create the channel we defined earlier.
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channel.id,          // 'sainik_saathi_reminders'
        _channel.name,        // 'Check-in Reminders'
        description: _channel.description, // 'Daily wellness check-in reminders'
        importance: _channel.importance,   // High importance
      ),
    );

    // 8. Request notification permissions from the user. 
    // This is especially important for Android 13 and above, which requires explicit permission.
    await androidPlugin?.requestNotificationsPermission();

    // 9. Check if the user previously saved a reminder schedule.
    // Re-schedule persisted reminder (survives app restart / reboot).
    final saved = await getSavedReminder();
    
    // If we found saved settings and the reminder is enabled, schedule it now!
    if (saved != null && saved.enabled) {
      await scheduleDailyReminder(saved.timeOfDay);
    }
  }

  // ── Schedule / Cancel ─────────────────────────────────────────────────────

  /// Schedule a daily notification at [time].
  /// If a reminder already exists it is cancelled first, so this doubles as
  /// an "update" operation.
  // This function takes a TimeOfDay and schedules a daily notification for that time.
  Future<bool> scheduleDailyReminder(TimeOfDay time) async {
    // 1. First, cancel any existing reminder we might have scheduled before.
    // This ensures we don't end up with multiple daily reminders at different times.
    await _plugin.cancel(_dailyReminderId);

    // 2. Get the current date and time in the local timezone.
    final now = tz.TZDateTime.now(tz.local);
    
    // 3. Create a target date and time for when the notification should fire today.
    // We keep the current year, month, and day, but plug in the hour and minute from the user.
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // 4. Check if this time has already passed today.
    // If the scheduled time is earlier than right now, it means it already passed today.
    if (scheduledDate.isBefore(now)) {
      // In that case, we add 1 day so it schedules for tomorrow instead.
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 5. Schedule the notification.
    // zonedSchedule lets us schedule a notification at a specific time in a specific time zone.
    await _plugin.zonedSchedule(
      _dailyReminderId,                               // ID (0)
      'SainikSaathi',                                 // The title of the notification
      'Time for your daily wellness check-in',        // The body text of the notification
      scheduledDate,                                  // The exact time we calculated above
      NotificationDetails(
        // Provide the details for Android (which channel to use, icon, importance).
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        // Provide the details for iOS (default is usually fine).
        iOS: const DarwinNotificationDetails(),
      ),
      // Tell Android how to handle scheduling if the device is in "doze" (power saving) mode.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Tell the system how to interpret the date (as absolute time, not relative to something else).
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // This is the magic part that makes it repeat every day at the same time.
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );

    // 6. Persist (save) the user's choice to secure storage.
    // We write 'true' for enabled, and the chosen hour and minute as strings.
    await _storage.write(key: _keyEnabled, value: 'true');
    await _storage.write(key: _keyHour, value: time.hour.toString());
    await _storage.write(key: _keyMinute, value: time.minute.toString());

    // Return true to indicate it was successfully scheduled.
    return true;
  }

  /// Cancel the active daily reminder and clear persisted config.
  // This function is used when the user wants to turn off notifications.
  Future<void> cancelDailyReminder() async {
    // 1. Cancel the currently scheduled notification using its ID (0).
    await _plugin.cancel(_dailyReminderId);
    
    // 2. Update the secure storage to reflect that notifications are now disabled.
    await _storage.write(key: _keyEnabled, value: 'false');
    
    // 3. Delete the saved hour and minute since they are no longer needed.
    await _storage.delete(key: _keyHour);
    await _storage.delete(key: _keyMinute);
  }

  // ── Read saved state ──────────────────────────────────────────────────────

  /// Returns the persisted reminder config, or `null` if none was ever saved.
  // This asynchronous function reads the saved settings from secure storage.
  Future<ReminderConfig?> getSavedReminder() async {
    // 1. Read the 'enabled' value. It's stored as a string ('true' or 'false').
    final enabledStr = await _storage.read(key: _keyEnabled);
    
    // If it's null, the user has never saved any settings, so we return null.
    if (enabledStr == null) return null;

    // 2. Read the saved hour and minute values (also stored as strings).
    final hourStr = await _storage.read(key: _keyHour);
    final minuteStr = await _storage.read(key: _keyMinute);

    // 3. Create and return a ReminderConfig object.
    return ReminderConfig(
      // If enabledStr is 'true', this becomes the boolean value true.
      enabled: enabledStr == 'true',
      
      // We try to parse the hour string into an integer. 
      // If parsing fails (or if the string is null), we provide a default of 7 (7 AM).
      hour: int.tryParse(hourStr ?? '') ?? 7,
      
      // We try to parse the minute string into an integer.
      // If parsing fails (or if the string is null), we provide a default of 30.
      minute: int.tryParse(minuteStr ?? '') ?? 30,
    );
  }
}
