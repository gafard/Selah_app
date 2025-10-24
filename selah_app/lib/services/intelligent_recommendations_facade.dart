// lib/services/intelligent_recommendations_facade.dart

import 'intelligent_duration_calculator.dart';
import 'intelligent_databases.dart';
import 'user_prefs.dart';

/// 🧠 Facade service pour centraliser toutes les recommandations intelligentes
/// 
/// Fournit une interface unifiée pour les calculs de durée, recommandations de livres,
/// et optimisation des passages. Utilise un pattern facade pour supporter les deux
/// systèmes (IntelligentDurationCalculator et IntelligentDatabases) avec fallback.
class IntelligentRecommendationsFacade {
  
  // ============ CALCULS DE DURÉE ============
  
  /// Calcule la durée optimale d'un plan avec données intelligentes
  /// Délègue à IntelligentDatabases avec fallback vers IntelligentDurationCalculator
  static Future<DurationCalculation> calculateOptimalDuration({
    required String goal,
    required String level,
    required int dailyMinutes,
    required String meditationType,
    Map<String, dynamic>? profile,
    String? motivation,
    String? posture,
  }) async {
    try {
      // 1. Essayer d'abord IntelligentDatabases (plus intelligent)
      final intelligentResult = IntelligentDatabases.calculateOptimalDuration(
        goal: goal,
        level: level,
        dailyMinutes: dailyMinutes,
        meditationType: meditationType,
        motivation: motivation,
        posture: posture,
      );
      
      // Convertir en DurationCalculation
      return DurationCalculation(
        optimalDays: intelligentResult,
        intensity: _getIntensityFromDays(intelligentResult, dailyMinutes),
        behavioralType: _getBehavioralTypeFromProfile(profile),
        scientificBasis: ['IntelligentDatabases', 'User Profile Analysis'],
        reasoning: 'Calculé avec IntelligentDatabases basé sur le profil utilisateur',
        totalHours: (intelligentResult * dailyMinutes) / 60.0,
        dailyMinutes: dailyMinutes,
        minDays: 7,
        maxDays: 365,
        confidence: 0.85,
      );
    } catch (e) {
      print('⚠️ IntelligentDatabases failed, fallback to IntelligentDurationCalculator: $e');
      
      // 2. Fallback vers IntelligentDurationCalculator
      return IntelligentDurationCalculator.calculateOptimalDuration(
        goal: goal,
        level: level,
        dailyMinutes: dailyMinutes,
        meditationType: meditationType,
      );
    }
  }
  
  // ============ RECOMMANDATIONS DE LIVRES ============
  
  /// Récupère les livres les plus pertinents pour un profil complet
  static Future<List<String>> getRecommendedBooks({
    required String goal,
    String? posture,
    String? motivation,
    int limit = 5,
  }) async {
    try {
      return IntelligentDatabases.getRecommendedBooksForProfile(
        goal: goal,
        posture: posture,
        motivation: motivation,
        limit: limit,
      );
    } catch (e) {
      print('⚠️ IntelligentDatabases book recommendations failed: $e');
      return _getFallbackBooks(goal, limit);
    }
  }
  
  // ============ OPTIMISATION DES PASSAGES ============
  
  /// Calcule la longueur optimale des passages selon le livre et les préférences utilisateur
  static Future<int> calculateOptimalPassageLength({
    required String book,
    required int minutes,
    required String meditationType,
    Map<String, dynamic>? userPrefs,
    int? startChapter,
    int? startVerse,
    int? endChapter,
    int? endVerse,
  }) async {
    try {
      // 1. Essayer d'abord IntelligentDatabases avec unités littéraires
      if (startChapter != null && startVerse != null && endChapter != null && endVerse != null) {
        return await IntelligentDatabases.calculateOptimalPassageLengthWithLiteraryUnits(
          book: book,
          minutes: minutes,
          meditationType: meditationType,
          startChapter: startChapter,
          startVerse: startVerse,
          endChapter: endChapter,
          endVerse: endVerse,
        );
      } else {
        return IntelligentDatabases.calculateOptimalPassageLength(
          book: book,
          minutes: minutes,
          meditationType: meditationType,
        );
      }
    } catch (e) {
      print('⚠️ IntelligentDatabases passage length failed: $e');
      
      // 2. Fallback avec calcul simple basé sur la densité
      return _calculateFallbackPassageLength(book, minutes, meditationType);
    }
  }
  
  // ============ PRESETS PERSONNALISÉS ============
  
  /// Génère des recommandations personnalisées de presets
  static Future<List<Map<String, dynamic>>> generatePersonalizedPresets({
    required String goal,
    required String level,
    required int dailyMinutes,
    String? posture,
    String? motivation,
    Map<String, dynamic>? profile,
  }) async {
    try {
      return IntelligentDatabases.generatePersonalizedPresets(
        goal: goal,
        level: level,
        dailyMinutes: dailyMinutes,
        posture: posture,
        motivation: motivation,
      );
    } catch (e) {
      print('⚠️ IntelligentDatabases personalized presets failed: $e');
      return _getFallbackPresets(goal, level, dailyMinutes);
    }
  }
  
  // ============ PRÉFÉRENCES UTILISATEUR ============
  
  /// Récupère les préférences de lecture de versets de l'utilisateur
  static Future<VerseReadingPreferences> getVerseReadingPreferences() async {
    try {
      final profile = await UserPrefs.getProfile();
      return VerseReadingPreferences.fromProfile(profile);
    } catch (e) {
      print('⚠️ Failed to get user preferences: $e');
      return VerseReadingPreferences.defaults();
    }
  }
  
  /// Définit les préférences de lecture de versets de l'utilisateur
  static Future<void> setVerseReadingPreferences(VerseReadingPreferences prefs) async {
    try {
      await UserPrefs.setVerseReadingPreferencesFromObject(prefs.toMap());
    } catch (e) {
      print('⚠️ Failed to set user preferences: $e');
    }
  }
  
  // ============ MÉTHODES UTILITAIRES ============
  
  static IntensityLevel _getIntensityFromDays(int days, int dailyMinutes) {
    final totalMinutes = days * dailyMinutes;
    if (totalMinutes <= 600) return IntensityLevel.light;
    if (totalMinutes <= 1200) return IntensityLevel.moderate;
    if (totalMinutes <= 1800) return IntensityLevel.intensive;
    return IntensityLevel.intensive;
  }
  
  static String _getBehavioralTypeFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return 'standard';
    
    final level = profile['level'] as String? ?? '';
    if (level.contains('Nouveau')) return 'new_convert';
    if (level.contains('Leader')) return 'leader';
    if (level.contains('Serviteur')) return 'servant';
    return 'regular';
  }
  
  static List<String> _getFallbackBooks(String goal, int limit) {
    // Livres de fallback basés sur l'objectif
    final fallbackBooks = {
      '💎 Rencontrer Jésus personnellement': ['Jean', 'Matthieu', 'Marc', 'Luc'],
      '🔥 Être transformé à son image': ['Romains', 'Galates', 'Éphésiens'],
      '❤️ Développer l\'intimité avec le Père': ['Psaumes', 'Jean', 'Cantique des Cantiques'],
      '📚 Approfondir ma connaissance': ['Hébreux', '1 Corinthiens', 'Colossiens'],
      '⚡ Recevoir la puissance de l\'Esprit': ['Actes', 'Éphésiens', 'Galates'],
    };
    
    return fallbackBooks[goal]?.take(limit).toList() ?? 
           ['Jean', 'Psaumes', 'Romains', 'Éphésiens', 'Philippiens'].take(limit).toList();
  }
  
  static int _calculateFallbackPassageLength(String book, int minutes, String meditationType) {
    // Densité moyenne par défaut
    double vpm = 2.5;
    
    // Ajustements par type de méditation
    switch (meditationType.toLowerCase()) {
      case 'méditation profonde':
        vpm *= 0.7;
        break;
      case 'lecture rapide':
        vpm *= 1.3;
        break;
      case 'étude approfondie':
        vpm *= 0.5;
        break;
    }
    
    final verses = (minutes * vpm).round();
    return verses.clamp(5, 30);
  }
  
  static List<Map<String, dynamic>> _getFallbackPresets(String goal, String level, int dailyMinutes) {
    return [
      {
        'name': 'Méditation Biblique Générale',
        'description': 'Plan équilibré pour la croissance spirituelle',
        'books': ['Psaumes', 'Jean'],
        'duration_days': 30,
        'minutes_per_day': dailyMinutes,
        'impact_score': 0.7,
        'meditation_type': 'Méditation Biblique',
        'level': level,
        'goal': goal,
      },
    ];
  }
}

/// Préférences de lecture de versets de l'utilisateur
class VerseReadingPreferences {
  final int minVerses;
  final int maxVerses;
  final String meditationType;
  final bool respectLiteraryUnits;
  final bool useIntelligentLimits;
  
  VerseReadingPreferences({
    required this.minVerses,
    required this.maxVerses,
    required this.meditationType,
    required this.respectLiteraryUnits,
    required this.useIntelligentLimits,
  });
  
  factory VerseReadingPreferences.fromProfile(Map<String, dynamic>? profile) {
        if (profile == null) return VerseReadingPreferences.defaults();
    
    return VerseReadingPreferences(
      minVerses: profile['minVerses'] as int? ?? 4,
      maxVerses: profile['maxVerses'] as int? ?? 18,
      meditationType: profile['meditationType'] as String? ?? 'Méditation Biblique',
      respectLiteraryUnits: profile['respectLiteraryUnits'] as bool? ?? true,
      useIntelligentLimits: profile['useIntelligentLimits'] as bool? ?? true,
    );
  }
  
  factory VerseReadingPreferences.defaults() {
    return VerseReadingPreferences(
      minVerses: 4,
      maxVerses: 18,
      meditationType: 'Méditation Biblique',
      respectLiteraryUnits: true,
      useIntelligentLimits: true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'minVerses': minVerses,
      'maxVerses': maxVerses,
      'meditationType': meditationType,
      'respectLiteraryUnits': respectLiteraryUnits,
      'useIntelligentLimits': useIntelligentLimits,
    };
  }
}
