import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// Persisted reminder configuration.
class ReminderConfig {
  const ReminderConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
  final bool enabled;
  final int hour;
  final int minute;

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

/// Callback invoked when user taps a notification.
/// Set by main.dart to navigate into the app.
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  // Handled by the static callback registered in main.dart.
  NotificationService.onNotificationTap?.call(response);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage();

  /// External callback set by main.dart to handle notification taps.
  static void Function(NotificationResponse)? onNotificationTap;

  // Fixed notification ID — guarantees cancel/replace behaviour.
  static const int _dailyReminderId = 0;

  // SecureStorage keys
  static const _keyEnabled = 'reminder_enabled';
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';

  // Android notification channel
  static const _channel = AndroidNotificationChannel(
    'sainik_saathi_reminders',
    'Check-in Reminders',
    description: 'Daily wellness check-in reminders',
    importance: Importance.high,
  );

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Create the Android notification channel.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channel.id,
        _channel.name,
        description: _channel.description,
        importance: _channel.importance,
      ),
    );

    // Request notification permission on Android 13+
    await androidPlugin?.requestNotificationsPermission();

    // Re-schedule persisted reminder (survives app restart / reboot).
    final saved = await getSavedReminder();
    if (saved != null && saved.enabled) {
      await scheduleDailyReminder(saved.timeOfDay);
    }
  }

  // ── Schedule / Cancel ─────────────────────────────────────────────────────

  /// Schedule a daily notification at [time].
  /// If a reminder already exists it is cancelled first, so this doubles as
  /// an "update" operation.
  Future<bool> scheduleDailyReminder(TimeOfDay time) async {
    // Cancel any existing reminder with the same fixed ID.
    await _plugin.cancel(_dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // If the time has already passed today, start from tomorrow.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'SainikSaathi',
      'Time for your daily wellness check-in',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );

    // Persist
    await _storage.write(key: _keyEnabled, value: 'true');
    await _storage.write(key: _keyHour, value: time.hour.toString());
    await _storage.write(key: _keyMinute, value: time.minute.toString());

    return true;
  }

  /// Cancel the active daily reminder and clear persisted config.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
    await _storage.write(key: _keyEnabled, value: 'false');
    await _storage.delete(key: _keyHour);
    await _storage.delete(key: _keyMinute);
  }

  // ── Read saved state ──────────────────────────────────────────────────────

  /// Returns the persisted reminder config, or `null` if none was ever saved.
  Future<ReminderConfig?> getSavedReminder() async {
    final enabledStr = await _storage.read(key: _keyEnabled);
    if (enabledStr == null) return null;

    final hourStr = await _storage.read(key: _keyHour);
    final minuteStr = await _storage.read(key: _keyMinute);

    return ReminderConfig(
      enabled: enabledStr == 'true',
      hour: int.tryParse(hourStr ?? '') ?? 7,
      minute: int.tryParse(minuteStr ?? '') ?? 30,
    );
  }
}
