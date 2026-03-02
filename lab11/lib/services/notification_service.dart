import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize all time zones
    tz.initializeTimeZones();

    // Set the local timezone from the device so scheduled times are correct
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: null,
          macOS: null,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Request notification permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+)
    // This opens the Settings page for the user to allow it
    final bool? canScheduleExact = await androidPlugin
        ?.canScheduleExactNotifications();
    if (canScheduleExact != true) {
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Only schedule if the date is in the future
    if (scheduledDate.isBefore(DateTime.now())) {
      print(
        'Notification skipped: scheduledDate is in the past ($scheduledDate)',
      );
      return;
    }

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool canExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexact;

    print(
      'Scheduling notification id=$id at $scheduledDate (exact=$canExact, tz=${tz.local.name})',
    );
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders_channel',
          'Event Reminders',
          channelDescription: 'Channel for Event Reminder Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: scheduleMode,
    );
    print('Notification scheduled successfully! mode=$scheduleMode');
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
