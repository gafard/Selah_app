import 'package:flutter/material.dart';
import '../models/spiritual_foundation.dart';
import '../models/plan_models.dart';
import 'spiritual_foundations_service.dart';
import 'notification_service.dart';

/// Service de gestion des notifications liées aux fondations spirituelles
class FoundationsNotificationService {
  static const int _morningNotificationId = 1000;
  static const int _eveningNotificationId = 1001;

  /// Planifie le rappel du matin avec la fondation du jour
  static Future<void> scheduleMorningReminder({
    required TimeOfDay time,
    required SpiritualFoundation foundation,
    required int dailyMinutes,
  }) async {
    final title = '🧱 Fondation du jour: ${foundation.name}';
    final body = 'Lis $dailyMinutes min et médite sur ce que tu vas mettre en pratique.';
    
    // Utiliser le service de notifications existant
    await NotificationService.instance.scheduleNotification(
      id: _morningNotificationId,
      title: title,
      body: body,
      scheduledTime: time,
      payload: {
        'type': 'foundation_morning',
        'foundationId': foundation.id,
        'foundationName': foundation.name,
        'dailyMinutes': dailyMinutes.toString(),
      },
    );
    
    print('🔔 Rappel matin planifié: ${foundation.name} à ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }
  
  /// Planifie le rappel du soir (optionnel)
  static Future<void> scheduleEveningReminder({
    required TimeOfDay time,
    required SpiritualFoundation foundation,
  }) async {
    final title = 'As-tu pratiqué ${foundation.name} aujourd\'hui ?';
    const body = 'Prends un instant pour réfléchir à ta journée spirituelle.';
    
    await NotificationService.instance.scheduleNotification(
      id: _eveningNotificationId,
      title: title,
      body: body,
      scheduledTime: time,
      payload: {
        'type': 'foundation_evening',
        'foundationId': foundation.id,
        'foundationName': foundation.name,
      },
    );
    
    print('🔔 Rappel soir planifié: ${foundation.name} à ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Planifie les notifications quotidiennes avec la fondation du jour
  static Future<void> scheduleDailyNotifications({
    required TimeOfDay morningTime,
    required TimeOfDay? eveningTime,
    required int dailyMinutes,
    required Map<String, dynamic> userProfile,
    Plan? activePlan,
  }) async {
    try {
      // Récupérer la fondation du jour
      final dayNumber = DateTime.now().day;
      final foundation = await SpiritualFoundationsService.getFoundationOfDay(
        activePlan,
        dayNumber,
        userProfile,
      );

      // Planifier le rappel du matin
      await scheduleMorningReminder(
        time: morningTime,
        foundation: foundation,
        dailyMinutes: dailyMinutes,
      );

      // Planifier le rappel du soir si demandé
      if (eveningTime != null) {
        await scheduleEveningReminder(
          time: eveningTime,
          foundation: foundation,
        );
      }

      print('✅ Notifications de fondation planifiées pour ${foundation.name}');
    } catch (e) {
      print('❌ Erreur planification notifications fondation: $e');
    }
  }

  /// Annule les notifications de fondation
  static Future<void> cancelFoundationNotifications() async {
    await NotificationService.instance.cancelNotification(_morningNotificationId);
    await NotificationService.instance.cancelNotification(_eveningNotificationId);
    print('🚫 Notifications de fondation annulées');
  }

  /// Met à jour les notifications avec une nouvelle fondation
  static Future<void> updateFoundationNotifications({
    required SpiritualFoundation foundation,
    required TimeOfDay morningTime,
    required TimeOfDay? eveningTime,
    required int dailyMinutes,
  }) async {
    // Annuler les anciennes notifications
    await cancelFoundationNotifications();
    
    // Planifier les nouvelles
    await scheduleMorningReminder(
      time: morningTime,
      foundation: foundation,
      dailyMinutes: dailyMinutes,
    );

    if (eveningTime != null) {
      await scheduleEveningReminder(
        time: eveningTime,
        foundation: foundation,
      );
    }
  }

  /// Génère un message de notification personnalisé selon la fondation
  static String generateNotificationMessage(SpiritualFoundation foundation, String type) {
    switch (type) {
      case 'morning':
        return 'Aujourd\'hui, ${foundation.shortDescription}';
      case 'evening':
        return 'As-tu vécu ${foundation.name} dans ta journée ?';
      default:
        return foundation.shortDescription;
    }
  }

  /// Vérifie si les notifications de fondation sont activées
  static Future<bool> areFoundationNotificationsEnabled() async {
    // Vérifier si les notifications générales sont activées
    return await NotificationService.instance.areNotificationsEnabled();
  }
}
