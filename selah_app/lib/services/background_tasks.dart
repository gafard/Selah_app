import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'telemetry_console.dart';

class BackgroundTasks {
  final FlutterLocalNotificationsPlugin _notifs = FlutterLocalNotificationsPlugin();
  final TelemetryConsole telemetry;

  BackgroundTasks({required this.telemetry});

  Future<void> initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifs.initialize(const InitializationSettings(android: android));
  }

  Future<void> queueBible(String version) async {
    telemetry.event('bible_download_enqueued', {'version': version});
    await _notifs.show(
      1001,
      'Téléchargement',
      'Version $version — démarrage…',
      const NotificationDetails(android: AndroidNotificationDetails('dl', 'Downloads')),
    );

    await Workmanager().registerOneOffTask(
      'bible-$version',
      'bible.download',
      inputData: {'version': version},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  // Option: rappel quotidien "alarme"
  Future<void> scheduleDailyAlarm({required int hour, required int minute}) async {
    await initNotifications();
    await _notifs.zonedSchedule(
      2001,
      'C\'est l\'heure de méditer',
      'Prends ta Bible physique et viens dans Selah.',
      tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute, 0),
      const NotificationDetails(android: AndroidNotificationDetails('remind', 'Reminders', importance: Importance.max, priority: Priority.high)),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}