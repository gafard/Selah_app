import 'dart:async';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'fullscreen_notification_service.dart';

/// 🧠 Service d'alarme intelligent avec rappel automatique
/// 
/// Gère les alarmes système Android avec rappel de 10 minutes
/// si l'application n'est pas ouverte par l'utilisateur
class IntelligentAlarmService {
  static const int DAILY_ALARM_ID = 1001;
  static const int SNOOZE_ALARM_ID = 1002;
  static const String LAST_ALARM_TIME_KEY = 'last_alarm_time';
  static const String LAST_APP_OPEN_KEY = 'last_app_open_time';
  
  static final IntelligentAlarmService _instance = IntelligentAlarmService._internal();
  factory IntelligentAlarmService() => _instance;
  IntelligentAlarmService._internal();

  static IntelligentAlarmService get instance => _instance;

  /// Initialise le service d'alarme
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    print('🔔 IntelligentAlarmService initialisé');
  }

  /// Programme une alarme quotidienne à l'heure spécifiée
  Future<void> scheduleAlarm(TimeOfDay time) async {
    try {
      // Vérifier les permissions
      if (!await _checkPermissions()) {
        print('⚠️ Permissions d\'alarme refusées');
        return;
      }

      // Annuler les alarmes existantes
      await cancelAllAlarms();

      // Calculer la prochaine heure
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Programmer l'alarme quotidienne
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        DAILY_ALARM_ID,
        _onAlarmTriggered,
        startAt: scheduledTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      // Marquer l'alarme comme programmée
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('alarm_scheduled', true);

      print('🔔 Alarme programmée à ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Erreur programmation alarme: $e');
    }
  }

  /// Annule toutes les alarmes
  Future<void> cancelAllAlarms() async {
    await AndroidAlarmManager.cancel(DAILY_ALARM_ID);
    await AndroidAlarmManager.cancel(SNOOZE_ALARM_ID);
    
    // Marquer l'alarme comme annulée
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_scheduled', false);
    
    print('🚫 Toutes les alarmes annulées');
  }

  /// Vérifie les permissions nécessaires
  Future<bool> _checkPermissions() async {
    // Vérifier permission d'alarme exacte (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    // Vérifier permission de notification
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  /// Callback exécuté quand l'alarme principale se déclenche
  @pragma('vm:entry-point')
  static Future<void> _onAlarmTriggered() async {
    print('🔔 Alarme déclenchée - Affichage notification plein écran');
    
    try {
      // 1. Afficher notification plein écran
      await FullScreenNotificationService.showFullScreenAlarm();
      
      // 2. Programmer un rappel dans 10 minutes
      await AndroidAlarmManager.oneShot(
        const Duration(minutes: 10),
        SNOOZE_ALARM_ID,
        _onSnoozeAlarmTriggered,
        exact: true,
        wakeup: true,
      );
      
      // 3. Stocker l'heure du déclenchement
      await _storeLastAlarmTime();
      
      print('🔔 Rappel programmé dans 10 minutes');
    } catch (e) {
      print('❌ Erreur lors du déclenchement alarme: $e');
    }
  }

  /// Callback exécuté quand le rappel de 10 minutes se déclenche
  @pragma('vm:entry-point')
  static Future<void> _onSnoozeAlarmTriggered() async {
    print('🔔 Rappel de 10 minutes déclenché');
    
    try {
      // Vérifier si l'app a été ouverte depuis la dernière alarme
      final wasOpened = await _checkIfAppWasOpened();
      
      if (!wasOpened) {
        print('🔔 App non ouverte - Re-déclenchement de l\'alarme');
        // Re-déclencher l'alarme
        await _onAlarmTriggered();
      } else {
        print('🔔 App ouverte - Rappel annulé');
      }
    } catch (e) {
      print('❌ Erreur lors du rappel: $e');
    }
  }

  /// Stocke l'heure de la dernière alarme
  static Future<void> _storeLastAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_ALARM_TIME_KEY, DateTime.now().millisecondsSinceEpoch);
  }

  /// Vérifie si l'app a été ouverte depuis la dernière alarme
  static Future<bool> _checkIfAppWasOpened() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAlarmTime = prefs.getInt(LAST_ALARM_TIME_KEY) ?? 0;
      final lastAppOpenTime = prefs.getInt(LAST_APP_OPEN_KEY) ?? 0;
      
      // Si l'app a été ouverte après la dernière alarme
      return lastAppOpenTime > lastAlarmTime;
    } catch (e) {
      print('❌ Erreur vérification ouverture app: $e');
      return false;
    }
  }

  /// Enregistre l'ouverture de l'application
  static Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_APP_OPEN_KEY, DateTime.now().millisecondsSinceEpoch);
    print('📱 Ouverture app enregistrée');
  }

  /// Vérifie si une alarme est programmée
  Future<bool> isAlarmScheduled() async {
    try {
      // Note: isAlarmActive n'est pas disponible dans android_alarm_manager_plus
      // On peut utiliser une approche alternative avec SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('alarm_scheduled') ?? false;
    } catch (e) {
      print('❌ Erreur vérification alarme: $e');
      return false;
    }
  }

  /// Obtient l'heure de la prochaine alarme
  Future<DateTime?> getNextAlarmTime() async {
    try {
      // Cette méthode nécessiterait une implémentation native
      // Pour l'instant, on retourne null
      return null;
    } catch (e) {
      print('❌ Erreur obtention prochaine alarme: $e');
      return null;
    }
  }
}
