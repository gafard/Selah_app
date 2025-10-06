import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

/// ID de notification fixe pour le rappel journalier
const int kDailyNotifId = 7771;
/// ID d'alarm manager (doit être unique)
const int kAlarmId = 990071;

/// Callback top-level requis par AndroidAlarmManager.
/// Montre la notif et reprogramme le prochain déclenchement.
void dailyAlarmCallback() async {
  // Affiche la notification
  await NotificationService.instance.showNow(
    id: kDailyNotifId,
    title: 'Selah',
    body: 'C\'est l\'heure de ta méditation 🙏',
  );
  // Replanifie pour demain même heure (sécurité côté Android pur)
  await DailyScheduler._rescheduleTomorrow();
}

class DailyScheduler {
  DailyScheduler._();

  /// Planifie un rappel quotidien à l'heure indiquée.
  /// - Android: AlarmManager + reschedule.
  /// - iOS / autres: zonedSchedule quotidien via FLN.
  static Future<void> scheduleDaily(TimeOfDay time) async {
    if (!kIsWeb && Platform.isAndroid) {
      await _scheduleAndroid(time);
    } else {
      await _scheduleIosLike(time);
    }
  }

  /// Annule tout rappel planifié
  static Future<void> cancel() async {
    if (!kIsWeb && Platform.isAndroid) {
      await AndroidAlarmManager.cancel(kAlarmId);
    }
    await NotificationService.instance.cancel(kDailyNotifId);
  }

  // ---------- ANDROID ----------
  static Future<void> _scheduleAndroid(TimeOfDay time) async {
    // On annule l'éventuel rappel en cours
    await AndroidAlarmManager.cancel(kAlarmId);

    final now = DateTime.now();
    DateTime next = DateTime(
      now.year, now.month, now.day, time.hour, time.minute,
    );

    if (!next.isAfter(now)) {
      // si l'heure est déjà passée aujourd'hui → demain
      next = next.add(const Duration(days: 1));
    }

    // Planifie un one-shot; la callback replanifiera pour le lendemain
    await AndroidAlarmManager.oneShotAt(
      next,
      kAlarmId,
      dailyAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  /// Reprogrammer pour demain même heure (appelée depuis la callback)
  static Future<void> _rescheduleTomorrow() async {
    // On récupère éventuellement une heure stockée par l'app (via Hive)
    // Pour faire simple ici : on remet pour dans 24h depuis maintenant.
    final next = DateTime.now().add(const Duration(days: 1));
    await AndroidAlarmManager.oneShotAt(
      next,
      kAlarmId,
      dailyAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  // ---------- iOS / autres (zonedSchedule) ----------
  static Future<void> _scheduleIosLike(TimeOfDay time) async {
    // Annule la notif planifiée éventuelle
    await NotificationService.instance.cancel(kDailyNotifId);

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    const android = AndroidNotificationDetails(
      'selah_daily',
      'Rappels quotidiens',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await NotificationService.instance.zonedDaily(
      id: kDailyNotifId,
      title: 'Selah',
      body: 'C\'est l\'heure de ta méditation 🙏',
      scheduledDate: next,
      details: const NotificationDetails(android: android, iOS: ios),
    );
  }
}
