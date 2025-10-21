import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// 🔔 Service de notification plein écran pour les alarmes
/// 
/// Gère l'affichage des notifications plein écran avec actions interactives
class FullScreenNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const String ALARM_CHANNEL_ID = 'selah_alarm_channel';
  static const String ALARM_CHANNEL_NAME = 'Alarmes Selah';
  static const int ALARM_NOTIFICATION_ID = 2001;

  /// Initialise le service de notifications
  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Créer le canal d'alarme
    await _createAlarmChannel();
  }

  /// Crée le canal de notification pour les alarmes
  static Future<void> _createAlarmChannel() async {
    const androidChannel = AndroidNotificationChannel(
      ALARM_CHANNEL_ID,
      ALARM_CHANNEL_NAME,
      description: 'Notifications d\'alarme pour les rappels de méditation',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Affiche une notification plein écran d'alarme
  static Future<void> showFullScreenAlarm() async {
    try {
      final androidDetails = AndroidNotificationDetails(
        ALARM_CHANNEL_ID,
        ALARM_CHANNEL_NAME,
        importance: Importance.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        styleInformation: const BigTextStyleInformation(
          'C\'est l\'heure de ta méditation quotidienne 🙏\n\n'
          'Prends un moment pour te connecter avec Dieu et méditer sa Parole.',
          contentTitle: 'Selah - Moment de méditation',
        ),
        actions: [
          AndroidNotificationAction(
            'open_app',
            'Commencer maintenant',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'snooze_10min',
            'Rappel dans 10min',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          AndroidNotificationAction(
            'dismiss',
            'Ignorer',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'ALARM_CATEGORY',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        ALARM_NOTIFICATION_ID,
        'Selah - Moment de méditation',
        'C\'est l\'heure de ta méditation quotidienne 🙏',
        notificationDetails,
      );

      print('🔔 Notification plein écran affichée');
    } catch (e) {
      print('❌ Erreur affichage notification: $e');
    }
  }

  /// Gère les réponses aux notifications
  static void _onNotificationResponse(NotificationResponse response) {
    final action = response.actionId;
    
    switch (action) {
      case 'open_app':
        _handleOpenApp();
        break;
      case 'snooze_10min':
        _handleSnooze();
        break;
      case 'dismiss':
        _handleDismiss();
        break;
      default:
        // Tap sur la notification
        _handleOpenApp();
    }
  }

  /// Ouvre l'application
  static void _handleOpenApp() {
    print('📱 Ouverture de l\'application depuis la notification');
    // L'application s'ouvrira automatiquement
    // On peut ajouter une navigation spécifique si nécessaire
  }

  /// Programme un rappel dans 10 minutes
  static void _handleSnooze() {
    print('⏰ Rappel programmé dans 10 minutes');
    // Le rappel est déjà géré par IntelligentAlarmService
  }

  /// Ignore l'alarme
  static void _handleDismiss() {
    print('🚫 Alarme ignorée');
    // L'utilisateur a choisi d'ignorer l'alarme
  }

  /// Annule la notification d'alarme
  static Future<void> cancelAlarmNotification() async {
    await _notifications.cancel(ALARM_NOTIFICATION_ID);
    print('🚫 Notification d\'alarme annulée');
  }

  /// Vérifie si les notifications sont activées
  static Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } catch (e) {
      print('❌ Erreur vérification notifications: $e');
      return false;
    }
  }
}
