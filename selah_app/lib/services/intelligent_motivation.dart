// lib/services/intelligent_motivation.dart

/// Service pour ajuster les plans selon la motivation spirituelle (Hébreux 11:6)
/// "Sans la foi, il est impossible de plaire à Dieu"
class IntelligentMotivation {
  /// Multiplicateurs de durée et intensité par motivation
  static const Map<String, Map<String, double>> motivationMultipliers = {
    '🔥 Passion pour Christ': {
      'durationDays': 0.8,    // -20% durée (court)
      'minutesPerDay': 1.2,   // +20% intensité (intense)
    },
    '❤️ Amour pour Dieu': {
      'durationDays': 1.0,    // Normal
      'minutesPerDay': 1.0,   // Normal
    },
    '🎯 Obéissance joyeuse': {
      'durationDays': 1.2,    // +20% durée (long)
      'minutesPerDay': 0.9,   // -10% intensité (régulier)
    },
    '📖 Désir de connaître Dieu': {
      'durationDays': 1.5,    // +50% durée (très long)
      'minutesPerDay': 1.3,   // +30% intensité (approfondi)
    },
    '⚡ Besoin de transformation': {
      'durationDays': 0.9,    // -10% durée
      'minutesPerDay': 1.1,   // +10% intensité
    },
    '🙏 Recherche de direction': {
      'durationDays': 0.7,    // -30% durée (court)
      'minutesPerDay': 1.0,   // Normal (ciblé)
    },
    '💪 Discipline spirituelle': {
      'durationDays': 1.0,    // Normal
      'minutesPerDay': 1.0,   // Normal
    },
  };
  
  /// Heure recommandée selon la motivation
  static const Map<String, String> motivationTiming = {
    '🔥 Passion pour Christ': '06:00',          // Aube
    '❤️ Amour pour Dieu': '07:00',             // Matin
    '🎯 Obéissance joyeuse': '07:30',          // Matin
    '📖 Désir de connaître Dieu': '09:00',     // Matinée
    '⚡ Besoin de transformation': '06:30',     // Aube
    '🙏 Recherche de direction': '05:30',      // Très tôt
    '💪 Discipline spirituelle': '07:00',      // Matin
  };
  
  /// Obtient les multiplicateurs pour une motivation
  static Map<String, double> getMultipliers(String motivation) {
    return motivationMultipliers[motivation] ?? {'durationDays': 1.0, 'minutesPerDay': 1.0};
  }
  
  /// Obtient l'heure recommandée pour une motivation
  static String getRecommendedTime(String motivation) {
    return motivationTiming[motivation] ?? '07:00';
  }
  
  /// Ajuste la durée d'un plan selon la motivation
  static int adjustDuration(int baseDuration, String motivation) {
    final multiplier = getMultipliers(motivation)['durationDays'] ?? 1.0;
    return (baseDuration * multiplier).round().clamp(7, 365);
  }
  
  /// Ajuste l'intensité (minutes/jour) selon la motivation
  static int adjustIntensity(int baseMinutes, String motivation) {
    final multiplier = getMultipliers(motivation)['minutesPerDay'] ?? 1.0;
    return (baseMinutes * multiplier).round().clamp(5, 120);
  }
}

