import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class IOSAlarmService {
  static const int DAILY_ALARM_ID = 1001;
  static const int SNOOZE_ALARM_ID = 1002;
  static const String ALARM_CHANNEL_ID = 'selah_ios_alarm';
  
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static final IOSAlarmService _instance = IOSAlarmService._internal();
  factory IOSAlarmService() => _instance;
  IOSAlarmService._internal();
  
  static IOSAlarmService get instance => _instance;
  
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    await _notifications.initialize(
      const InitializationSettings(iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    print('🔔 IOSAlarmService initialisé');
  }
  
  Future<void> scheduleAlarm(TimeOfDay time) async {
    try {
      // Annuler les alarmes existantes
      await cancelAllAlarms();
      
      // Programmer notification quotidienne iOS
      await _scheduleDailyNotification(time);
      
      // Marquer comme programmé
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ios_alarm_scheduled', true);
      
      print('🔔 Alarme iOS programmée à ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Erreur programmation alarme iOS: $e');
    }
  }
  
  Future<void> _scheduleDailyNotification(TimeOfDay time) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _notifications.zonedSchedule(
      DAILY_ALARM_ID,
      'Selah - Moment de méditation',
      'C\'est l\'heure de ta méditation quotidienne 🙏',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.critical,
          sound: 'alarm_sound.caf',
          categoryIdentifier: 'SELAH_ALARM_CATEGORY',
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  Future<void> cancelAllAlarms() async {
    await _notifications.cancel(DAILY_ALARM_ID);
    await _notifications.cancel(SNOOZE_ALARM_ID);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ios_alarm_scheduled', false);
    
    print('🚫 Toutes les alarmes iOS annulées');
  }
  
  Future<bool> isAlarmScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ios_alarm_scheduled') ?? false;
  }
  
  static void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    print('📱 Notification iOS reçue: $title');
  }
  
  static void _onNotificationResponse(NotificationResponse response) {
    final action = response.actionId;
    
    switch (action) {
      case 'start_now':
        _handleStartNow();
        break;
      case 'snooze_10min':
        _handleSnooze();
        break;
      case 'dismiss':
        _handleDismiss();
        break;
      default:
        _handleStartNow();
    }
  }
  
  static void _handleStartNow() {
    print('📱 Commencer maintenant - iOS');
    // L'app s'ouvrira automatiquement
  }
  
  static void _handleSnooze() {
    print('⏰ Rappel dans 10 minutes - iOS');
    // Programmer rappel iOS
    _scheduleSnoozeNotification();
  }
  
  static void _handleDismiss() {
    print('🚫 Alarme ignorée - iOS');
  }
  
  static Future<void> _scheduleSnoozeNotification() async {
    final now = DateTime.now();
    final snoozeTime = now.add(const Duration(minutes: 10));
    
    await FlutterLocalNotificationsPlugin().zonedSchedule(
      SNOOZE_ALARM_ID,
      'Selah - Rappel de méditation',
      'Rappel: C\'est l\'heure de ta méditation 🙏',
      tz.TZDateTime.from(snoozeTime, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.critical,
          sound: 'alarm_sound.caf',
          categoryIdentifier: 'SELAH_ALARM_CATEGORY',
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
