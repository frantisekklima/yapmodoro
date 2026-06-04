import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';


class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const MethodChannel _serviceChannel = MethodChannel('com.yapmodoro.app/timer_service');

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Register Notification Channels on Android
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Channel 1: pomodoro_timer (Low importance, silent, no vibration)
      const AndroidNotificationChannel timerChannel = AndroidNotificationChannel(
        'pomodoro_timer',
        'Pomodoro Active Timer',
        description: 'Displays a live, silent countdown timer in the status drawer.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      // Channel 2: pomodoro_alarm_v3 (High importance, vibration, default system sound)
      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
        'pomodoro_alarm_v3',
        'Pomodoro Session Alarm',
        description: 'Rings and alerts when focus or break sessions complete.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin.createNotificationChannel(timerChannel);
      await androidPlugin.createNotificationChannel(alarmChannel);
    }
  }

  // Show or update persistent status tray notification
  Future<void> updateTimerNotification({
    required String title,
    required String body,
    required DateTime endTime,
    required bool isCountdown,
  }) async {
    final int timeoutMs = endTime.difference(DateTime.now()).inMilliseconds;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_timer',
      'Pomodoro Active Timer',
      channelDescription: 'Displays a live, silent countdown timer in the status drawer.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      usesChronometer: true,
      chronometerCountDown: isCountdown,
      when: endTime.millisecondsSinceEpoch,
      timeoutAfter: timeoutMs > 0 ? timeoutMs : 1,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        final bool isBreak = title.toLowerCase().contains("break");
        await _serviceChannel.invokeMethod('startService', {
          'title': title,
          'body': body,
          'endTimeMillis': endTime.millisecondsSinceEpoch,
          'isCountdown': isCountdown,
          'alarmTitle': isBreak ? "Break Completed!" : "Focus Segment Completed!",
          'alarmBody': isBreak ? "Ready to start focusing again?" : "Time to take a well-deserved break!",
        });
      } catch (e) {
        await androidPlugin.startForegroundService(
          888,
          title,
          body,
          notificationDetails: androidDetails,
          foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeDataSync},
        );
      }
    } else {
      await _notificationsPlugin.show(
        888, // Constant ID for active timer
        title,
        body,
        notificationDetails,
      );
    }
  }

  // Show static paused notification
  Future<void> showPausedNotification({
    required String title,
    required String timeRemainingText,
  }) async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await _serviceChannel.invokeMethod('stopService');
      } catch (e) {
        await androidPlugin.stopForegroundService();
      }
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_timer',
      'Pomodoro Active Timer',
      channelDescription: 'Displays a live, silent countdown timer in the status drawer.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: false,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      usesChronometer: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      888, // Constant ID for active timer
      title,
      timeRemainingText,
      notificationDetails,
    );
  }

  // Schedule exact completion alarm
  Future<void> scheduleCompletionAlarm({
    required String title,
    required String body,
    required DateTime endTime,
  }) async {
    // Cancel any previous alarm first
    await _notificationsPlugin.cancel(999);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_alarm_v3',
      'Pomodoro Session Alarm',
      channelDescription: 'Rings and alerts when focus or break sessions complete.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Schedule using AlarmManager's exact allow-while-idle mode
    await _notificationsPlugin.zonedSchedule(
      999, // Constant ID for completion alarm
      title,
      body,
      tz.TZDateTime.now(tz.local).add(endTime.difference(DateTime.now())),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel only the scheduled completion alarm
  Future<void> cancelAlarmNotification() async {
    await _notificationsPlugin.cancel(999);
  }

  // Cancel notifications
  Future<void> cancelTimerNotifications() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await _serviceChannel.invokeMethod('stopService');
      } catch (e) {
        await androidPlugin.stopForegroundService();
      }
    }
    await _notificationsPlugin.cancel(888);
    await _notificationsPlugin.cancel(999);
  }

  // Show static session complete notification
  Future<void> showSessionCompleteNotification({
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_alarm_v3',
      'Pomodoro Session Alarm',
      channelDescription: 'Rings and alerts when focus or break sessions complete.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ongoing: false,
      autoCancel: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      777, // Constant ID for session completion reminder card
      title,
      body,
      notificationDetails,
    );
  }

  // Cancel the completion reminder card
  Future<void> cancelCompletionReminder() async {
    await _notificationsPlugin.cancel(777);
  }
}
