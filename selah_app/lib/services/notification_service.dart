import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

/// 🧠 Contexte de notification intelligent
class NotificationContext {
  final String? planId;
  final String? readingReference;
  final String? theme;
  final Map<String, dynamic>? metadata;
  
  NotificationContext({
    this.planId,
    this.readingReference,
    this.theme,
    this.metadata,
  });
}

/// 🧠 Contenu intelligent pour notifications
class IntelligentContent {
  final String title;
  final String body;
  
  IntelligentContent({
    required this.title,
    required this.body,
  });
}

/// 🧠 PROPHÈTE - Service de notifications avec contexte Thompson
/// 
/// Niveau : Prophète (Intelligent) - Service intelligent pour les notifications contextuelles
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: thompson_plan_service.dart (thèmes spirituels)
/// 🔥 Priorité 2: intelligent_local_preset_generator.dart (contexte)
/// 🔥 Priorité 3: meditation_journal_service.dart (historique)
/// 🎯 Thompson: Enrichit les messages avec thèmes spirituels
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

  /// 🧠 Affiche une notification intelligente avec contexte Thompson
  Future<void> showNow({
    int id = 1001,
    String? title,
    String? body,
    NotificationContext? context,
  }) async {
    // 🧠 INTELLIGENCE CONTEXTUELLE - Générer contenu intelligent
    final intelligentContent = await _generateIntelligentContent(context);
    
    final finalTitle = title ?? intelligentContent.title;
    final finalBody = body ?? intelligentContent.body;
    
    const android = AndroidNotificationDetails(
      'selah_daily',
      'Rappels quotidiens intelligents',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(''),
    );
    const ios = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: 'INTELLIGENT_REMINDER',
    );
    await _fln.show(id, finalTitle, finalBody, const NotificationDetails(android: android, iOS: ios));
    
    print('🏎️ Prophète Intelligent: Notification contextuelle envoyée');
  }

  /// 🧠 Génère du contenu intelligent basé sur le contexte
  Future<IntelligentContent> _generateIntelligentContent(NotificationContext? context) async {
    try {
      // 🔥 PRIORITÉ 1: Récupérer le thème Thompson
      final thompsonTheme = await _getThompsonTheme(context);
      
      // 🔥 PRIORITÉ 2: Récupérer le contexte de lecture
      final readingContext = await _getReadingContext(context);
      
      // 🔥 PRIORITÉ 3: Analyser l'historique de méditation
      final meditationHistory = await _getMeditationHistory();
      
      return IntelligentContent(
        title: _generateContextualTitle(thompsonTheme, readingContext),
        body: _generateContextualBody(thompsonTheme, readingContext, meditationHistory),
      );
      
    } catch (e) {
      print('⚠️ Erreur génération contenu intelligent: $e');
      return IntelligentContent(
        title: 'Selah',
        body: 'C\'est l\'heure de ta méditation ✨',
      );
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère le thème Thompson pour le contexte
  Future<String?> _getThompsonTheme(NotificationContext? context) async {
    try {
      if (context?.planId != null) {
        // TODO: Intégrer avec thompson_plan_service pour récupérer le thème du plan
        return 'Exigence spirituelle — Transformation profonde';
      }
      
      // TODO: Récupérer le thème du jour selon le plan actif
      return 'Vie de prière — Souffle spirituel';
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 2: Récupère le contexte de lecture
  Future<String?> _getReadingContext(NotificationContext? context) async {
    try {
      if (context?.readingReference != null) {
        // TODO: Intégrer avec semantic_passage_boundary_service pour enrichir le contexte
        return 'Lecture: ${context!.readingReference}';
      }
      
      // TODO: Récupérer la lecture du jour depuis le plan actif
      return 'Lecture du jour: Psaumes 23';
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 3: Analyse l'historique de méditation
  Future<String?> _getMeditationHistory() async {
    try {
      // TODO: Intégrer avec meditation_journal_service pour analyser l'historique
      return 'Continue ton parcours spirituel';
    } catch (e) {
      return null;
    }
  }

  /// 🎯 Génère un titre contextuel avec Thompson
  String _generateContextualTitle(String? thompsonTheme, String? readingContext) {
    if (thompsonTheme != null) {
      return thompsonTheme;
    }
    return 'Selah';
  }

  /// 🧠 Génère un corps contextuel intelligent
  String _generateContextualBody(String? thompsonTheme, String? readingContext, String? meditationHistory) {
    final parts = <String>[];
    
    if (readingContext != null) {
      parts.add(readingContext);
    }
    
    if (thompsonTheme != null) {
      parts.add('Thème: ${thompsonTheme.split(' — ').last}');
    }
    
    if (meditationHistory != null) {
      parts.add(meditationHistory);
    }
    
    if (parts.isEmpty) {
      return 'C\'est l\'heure de ta méditation ✨';
    }
    
    return parts.join('\n\n');
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