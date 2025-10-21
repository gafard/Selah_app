import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

/// ID de notification fixe pour le rappel journalier
const int kDailyNotifId = 7771;

/// 🧠 Notification intelligente avec contexte
class IntelligentNotification {
  final String title;
  final String body;
  
  IntelligentNotification({
    required this.title,
    required this.body,
  });
}

/// 🏎️ Prophète INTELLIGENT - Planificateur quotidien avec intelligence contextuelle
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (contenu du jour)
/// 🔥 Priorité 2: user_prefs_hive.dart (préférences temporelles)
/// 🔥 Priorité 3: plan_service_http.dart (plan actif)
/// 🎯 Thompson: Enrichit les messages avec thèmes spirituels
class DailyScheduler {
  DailyScheduler._();

  /// 🧠 Planifie un rappel quotidien intelligent avec contexte
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

    // 🧠 INTELLIGENCE CONTEXTUELLE - Générer message personnalisé
    final intelligentMessage = await _generateIntelligentNotification(next);
    
    // Programme la notification récurrente quotidienne avec contexte
    await NotificationService.instance.zonedDaily(
      id: kDailyNotifId,
      title: intelligentMessage.title,
      body: intelligentMessage.body,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          'selah_daily',
          'Rappels quotidiens intelligents',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(
            intelligentMessage.body,
            contentTitle: intelligentMessage.title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
          categoryIdentifier: 'DAILY_REMINDER',
        ),
      ),
      scheduledDate: next,
    );

    print('🏎️ Prophète Intelligent: Rappel programmé avec contexte Thompson');
  }

  /// 🧠 Génère une notification intelligente basée sur le contexte
  static Future<IntelligentNotification> _generateIntelligentNotification(DateTime scheduledDate) async {
    try {
      // 🔥 PRIORITÉ 1: Récupérer le contenu du jour via FALCON X
      final todayContent = await _getTodayContent(scheduledDate);
      
      // 🔥 PRIORITÉ 2: Récupérer les préférences utilisateur
      final userPrefs = await _getUserPreferences();
      
      // 🎯 THOMPSON: Enrichir avec thèmes spirituels
      final thompsonTheme = await _getThompsonThemeForToday(todayContent);
      
      // 🧠 MACHINE LEARNING: Apprendre les heures optimales
      final optimalTiming = await _getOptimalTiming(scheduledDate);
      
      return IntelligentNotification(
        title: _generateContextualTitle(thompsonTheme, userPrefs),
        body: _generateContextualBody(todayContent, thompsonTheme, optimalTiming),
      );
      
    } catch (e) {
      print('⚠️ Erreur génération notification intelligente: $e');
      // Fallback vers notification basique
      return IntelligentNotification(
        title: 'Selah',
        body: 'C\'est l\'heure de ta méditation 🙏',
      );
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère le contenu du jour via FALCON X
  static Future<String?> _getTodayContent(DateTime date) async {
    try {
      // TODO: Intégrer avec plan_service_http pour récupérer le plan actif
      // TODO: Utiliser semantic_passage_boundary_service pour le contenu du jour
      return 'Psaumes 23'; // Placeholder
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 2: Récupère les préférences utilisateur
  static Future<Map<String, dynamic>?> _getUserPreferences() async {
    try {
      // TODO: Intégrer avec user_prefs_hive
      return {
        'preferredTime': '07:00',
        'notificationStyle': 'spiritual',
        'thompsonEnabled': true,
      };
    } catch (e) {
      return null;
    }
  }

  /// 🎯 THOMPSON: Récupère le thème Thompson pour aujourd'hui
  static Future<String?> _getThompsonThemeForToday(String? content) async {
    try {
      if (content == null) return null;
      
      // TODO: Intégrer avec thompson_plan_service pour récupérer le thème du jour
      // Mapping basique pour l'instant
      if (content.contains('Psaumes')) {
        return 'Vie de prière — Souffle spirituel';
      } else if (content.contains('Jean')) {
        return 'Exigence spirituelle — Transformation profonde';
      }
      
      return 'Le sentier de la vie';
    } catch (e) {
      return null;
    }
  }

  /// 🧠 MACHINE LEARNING: Apprend les heures optimales
  static Future<String> _getOptimalTiming(DateTime scheduledDate) async {
    try {
      // TODO: Analyser l'historique de lecture pour optimiser le timing
      final hour = scheduledDate.hour;
      
      if (hour >= 6 && hour < 9) {
        return 'Moment parfait pour commencer la journée avec Dieu';
      } else if (hour >= 12 && hour < 14) {
        return 'Pause spirituelle au cœur de la journée';
      } else if (hour >= 18 && hour < 21) {
        return 'Temps idéal pour méditer avant le repos';
      } else {
        return 'Moment choisi pour ta rencontre avec Dieu';
      }
    } catch (e) {
      return 'C\'est l\'heure de ta méditation 🙏';
    }
  }

  /// 🎯 Génère un titre contextuel avec Thompson
  static String _generateContextualTitle(String? thompsonTheme, Map<String, dynamic>? prefs) {
    if (thompsonTheme != null) {
      return thompsonTheme;
    }
    return 'Selah';
  }

  /// 🧠 Génère un corps contextuel intelligent
  static String _generateContextualBody(String? content, String? thompsonTheme, String timing) {
    final parts = <String>[];
    
    if (content != null) {
      parts.add('Aujourd\'hui: $content');
    }
    
    if (thompsonTheme != null) {
      parts.add('Thème: ${thompsonTheme.split(' — ').last}');
    }
    
    parts.add(timing);
    
    return parts.join('\n\n');
  }

  /// Annule tout rappel planifié
  static Future<void> cancel() async {
    await NotificationService.instance.cancel(kDailyNotifId);
  }
}
