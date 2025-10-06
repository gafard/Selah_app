import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

/// ID de notification fixe pour le rappel journalier
const int kDailyNotifId = 7771;

class DailyScheduler {
  DailyScheduler._();

  /// Planifie un rappel quotidien à l'heure indiquée.
  static Future<void> scheduleDaily(TimeOfDay time) async {
    // Annule la notification existante
    await NotificationService.instance.cancel(kDailyNotifId);

    // Calcule la prochaine heure
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute,
    );
    
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    // Programme la notification récurrente quotidienne
    await NotificationService.instance.zonedDaily(
      id: kDailyNotifId,
      title: 'Selah',
      body: 'C\'est l\'heure de ta méditation 🙏',
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'selah_daily',
          'Rappels quotidiens',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      scheduledDate: next,
    );
  }

  /// Annule tout rappel planifié
  static Future<void> cancel() async {
    await NotificationService.instance.cancel(kDailyNotifId);
  }
}
