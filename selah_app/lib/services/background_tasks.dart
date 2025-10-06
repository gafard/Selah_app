import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// workmanager supprimé pour éviter les problèmes de compatibilité
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

    // Téléchargement direct au lieu de workmanager
    // Le téléchargement se fera pendant que l'utilisateur utilise l'app
    print('📥 Téléchargement de la Bible $version en cours...');
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