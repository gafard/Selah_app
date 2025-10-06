import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fln = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _fln.initialize(initSettings);

    if (!kIsWeb && Platform.isAndroid) {
      await _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'selah_daily',
            'Rappels quotidiens',
            description: 'Notifications de méditation/prière Selah',
            importance: Importance.high,
          ));
    }
  }

  Future<void> showNow({
    int id = 1001,
    String title = 'Selah',
    String body = 'C\'est l\'heure de ta méditation ✨',
  }) async {
    const android = AndroidNotificationDetails(
      'selah_daily',
      'Rappels quotidiens',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _fln.show(id, title, body, const NotificationDetails(android: android, iOS: ios));
  }

  Future<void> cancel(int id) => _fln.cancel(id);

  Future<void> zonedDaily({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _fln.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time, // tous les jours même heure
    );
  }
}