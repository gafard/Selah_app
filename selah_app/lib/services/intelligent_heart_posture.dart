// lib/services/intelligent_heart_posture.dart

/// Service pour filtrer les presets selon la posture du cœur (Jean 5:40)
/// "Vous sondez les Écritures... venez à moi pour avoir la vie !"
class IntelligentHeartPosture {
  /// Mapping posture → livres bibliques recommandés
  static const Map<String, List<String>> postureToBooks = {
    '💎 Rencontrer Jésus personnellement': [
      'Jean', 'Marc', 'Luc', 'Matthieu', '1 Jean', '2 Jean', '3 Jean',
    ],
    '🔥 Être transformé par l\'Esprit': [
      'Romains', 'Galates', '2 Corinthiens', 'Éphésiens', 'Colossiens', 'Philippiens',
    ],
    '🙏 Écouter la voix de Dieu': [
      'Psaumes', 'Ésaïe', 'Jérémie', '1 Samuel', '1 Rois', 'Job',
    ],
    '📚 Approfondir ma connaissance': [
      'Romains', 'Hébreux', 'Actes', 'Daniel', 'Genèse', 'Exode',
    ],
    '⚡ Recevoir la puissance de l\'Esprit': [
      'Actes', 'Éphésiens', 'Jean', '1 Corinthiens', '2 Timothée',
    ],
    '❤️ Développer l\'intimité avec le Père': [
      'Psaumes', 'Cantique', 'Jean', 'Philippiens', '1 Jean', 'Lamentations',
    ],
  };
  
  /// Bonus d'impact si le livre correspond à la posture
  static const Map<String, Map<String, double>> postureBookBonus = {
    'Jean': {
      '💎 Rencontrer Jésus personnellement': 0.30,
      '❤️ Développer l\'intimité avec le Père': 0.25,
      '🙏 Écouter la voix de Dieu': 0.20,
    },
    'Psaumes': {
      '🙏 Écouter la voix de Dieu': 0.35,
      '❤️ Développer l\'intimité avec le Père': 0.30,
      '💎 Rencontrer Jésus personnellement': 0.15,
    },
    'Romains': {
      '🔥 Être transformé par l\'Esprit': 0.30,
      '📚 Approfondir ma connaissance': 0.25,
      '⚡ Recevoir la puissance de l\'Esprit': 0.20,
    },
    'Actes': {
      '⚡ Recevoir la puissance de l\'Esprit': 0.35,
      '🔥 Être transformé par l\'Esprit': 0.20,
      '📚 Approfondir ma connaissance': 0.15,
    },
    'Éphésiens': {
      '⚡ Recevoir la puissance de l\'Esprit': 0.30,
      '🔥 Être transformé par l\'Esprit': 0.28,
      '❤️ Développer l\'intimité avec le Père': 0.20,
    },
    'Galates': {
      '🔥 Être transformé par l\'Esprit': 0.32,
      '🕊️ Marcher par l\'Esprit': 0.30,
    },
    'Marc': {
      '💎 Rencontrer Jésus personnellement': 0.28,
    },
    'Luc': {
      '💎 Rencontrer Jésus personnellement': 0.26,
    },
    '1 Jean': {
      '❤️ Développer l\'intimité avec le Père': 0.28,
      '💎 Rencontrer Jésus personnellement': 0.25,
    },
  };
  
  /// Calcule le bonus d'impact pour un livre selon la posture
  static double getPostureBonus(String book, String posture) {
    return postureBookBonus[book]?[posture] ?? 0.0;
  }
  
  /// Vérifie si un livre est recommandé pour une posture
  static bool isRecommendedForPosture(String book, String posture) {
    final recommendedBooks = postureToBooks[posture] ?? [];
    return recommendedBooks.any((b) => book.contains(b) || b.contains(book));
  }
  
  /// Score de pertinence d'un preset pour une posture (0.0 à 1.0)
  static double calculatePostureRelevance(
    String books, // "Jean, Marc, Luc"
    String posture,
  ) {
    if (books.isEmpty) return 0.5;
    
    final bookList = books.split(',').map((b) => b.trim()).toList();
    final recommendedBooks = postureToBooks[posture] ?? [];
    
    if (recommendedBooks.isEmpty) return 0.5;
    
    int matchCount = 0;
    for (final book in bookList) {
      if (recommendedBooks.any((rb) => book.contains(rb) || rb.contains(book))) {
        matchCount++;
      }
    }
    
    return (matchCount / bookList.length).clamp(0.0, 1.0);
  }
}

