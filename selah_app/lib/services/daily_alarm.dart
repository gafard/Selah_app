import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Gestionnaire d'alarme quotidienne avec vraie alarme système
class DailyAlarm {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return; // Pas de notifications sur web
    
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  static Future<void> requestPermissionsIfNeeded() async {
    if (kIsWeb) return; // Pas de permissions sur web
    
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission(); // Android 12+
  }

  static tz.TZDateTime _next(String hhmm) {
    final parts = hhmm.split(':');
    final now = tz.TZDateTime.now(tz.local);
    var sched = tz.TZDateTime(tz.local, now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
    if (sched.isBefore(now)) sched = sched.add(const Duration(days: 1));
    return sched;
  }

  static Future<void> scheduleDaily(String hhmm) async {
    if (kIsWeb) return; // Pas de notifications sur web
    
    await _plugin.zonedSchedule(
      1001,
      'Rendez-vous Selah',
      'Ton moment pour méditer la Parole.',
      _next(hhmm),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'selah_daily', 'Rappel quotidien',
          channelDescription: 'Notifications quotidiennes Selah',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDaily() async {
    if (kIsWeb) return; // Pas de notifications sur web
    await _plugin.cancel(1001);
  }
}
