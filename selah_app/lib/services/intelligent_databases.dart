// lib/services/intelligent_databases.dart

import 'intelligent_duration_calculator.dart';
import 'semantic_passage_boundary_service_v2.dart';
import 'bible_verses_database.dart';

/// 🧠 Service central des bases de données intelligentes
/// 
/// Orchestre toutes les données intelligentes pour fournir des calculs
/// d'impact spirituel précis et des recommandations personnalisées.
class IntelligentDatabases {
  
  // ============ CALCULS D'IMPACT INTELLIGENTS ============
  
  /// Calcule l'impact spirituel total d'un livre sur un objectif
  /// avec prise en compte de la posture du cœur
  static double calculateBookImpactOnGoal({
    required String book,
    required String goal,
    String? posture,
  }) {
    // Calcul d'impact basique basé sur le livre et l'objectif
    double baseImpact = _calculateBasicBookImpact(book, goal);
    
    // Ajustement selon la posture du cœur
    if (posture != null) {
      baseImpact *= _getPostureMultiplier(posture);
    }
    
    return baseImpact.clamp(0.0, 1.0);
  }
  
  /// Calcule l'impact de base d'un livre sur un objectif
  static double _calculateBasicBookImpact(String book, String goal) {
    // Mapping simplifié des livres vers les objectifs
    final bookGoalMapping = {
      'Jean': {'Rencontrer Jésus dans la Parole': 0.9, 'Développer l\'intimité avec Dieu': 0.8},
      'Psaumes': {'Mieux prier': 0.9, 'Trouver de l\'encouragement': 0.8},
      'Proverbes': {'Sagesse': 0.9, 'Développer mon caractère': 0.8},
      'Romains': {'Approfondir la Parole': 0.9, 'Grandir dans la foi': 0.8},
      'Éphésiens': {'Développer mon caractère': 0.8, 'Renouveler mes pensées': 0.9},
    };
    
    return bookGoalMapping[book]?[goal] ?? 0.5;
  }
  
  /// Multiplicateur selon la posture du cœur
  static double _getPostureMultiplier(String posture) {
    final multipliers = {
      'Rencontrer Jésus personnellement': 1.2,
      'Être transformé par l\'Esprit': 1.1,
      'Écouter la voix de Dieu': 1.0,
      'Approfondir ma connaissance': 0.9,
      'Recevoir la puissance de l\'Esprit': 1.1,
      'Développer l\'intimité avec le Père': 1.2,
    };
    
    return multipliers[posture] ?? 1.0;
  }
  
  /// Récupère les livres les plus pertinents pour un profil complet
  static List<String> getRecommendedBooksForProfile({
    required String goal,
    String? posture,
    String? motivation,
    int limit = 5,
  }) {
    // 1. Calculer l'impact de base pour tous les livres
    final allBooks = _getAllBibleBooks();
    final bookScores = <String, double>{};
    
    for (final book in allBooks) {
      double impact = calculateBookImpactOnGoal(
        book: book,
        goal: goal,
        posture: posture,
      );
      
      // 2. Bonus si le livre correspond à la posture
      if (posture != null) {
        final postureBonus = _getPostureBonus(book, posture);
        impact = (impact * (1.0 + postureBonus)).clamp(0.0, 1.0);
      }
      
      // 3. Seuil minimum de pertinence
      if (impact > 0.5) {
        bookScores[book] = impact;
      }
    }
    
    // 4. Trier par score décroissant
    final sortedBooks = bookScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedBooks.take(limit).map((entry) => entry.key).toList();
  }
  
  /// Calcule la durée optimale d'un plan avec données intelligentes
  static int calculateOptimalDuration({
    required String goal,
    required String level,
    required int dailyMinutes,
    required String meditationType,
    String? motivation,
    String? posture,
  }) {
    // 1. Durée de base calculée selon l'objectif et le niveau
    int baseDuration = _calculateBaseDuration(goal, level, dailyMinutes);
    
    // 2. Ajustement selon la motivation
    if (motivation != null) {
      final factor = _getMotivationFactor(motivation);
      baseDuration = (baseDuration * factor).round();
    }
    
    // 3. Ajustement selon la posture
    if (posture != null) {
      final postureFactor = _getPostureMultiplier(posture);
      baseDuration = (baseDuration * postureFactor).round();
    }
    
    return baseDuration;
  }
  
  /// Calcule la durée de base selon l'objectif et le niveau
  static int _calculateBaseDuration(String goal, String level, int dailyMinutes) {
    // Durée de base selon le niveau
    final levelDays = {
      'Débutant': 14,
      'Intermédiaire': 21,
      'Avancé': 30,
    };
    
    int baseDays = levelDays[level] ?? 21;
    
    // Ajustement selon l'objectif
    final goalMultiplier = {
      'Rencontrer Jésus dans la Parole': 1.2,
      'Développer l\'intimité avec Dieu': 1.3,
      'Approfondir la Parole': 1.1,
      'Mieux prier': 1.0,
      'Trouver de l\'encouragement': 0.9,
      'Sagesse': 1.1,
      'Développer mon caractère': 1.2,
      'Grandir dans la foi': 1.1,
      'Renouveler mes pensées': 1.0,
    };
    
    final multiplier = goalMultiplier[goal] ?? 1.0;
    return (baseDays * multiplier).round();
  }
  
  /// Facteur de motivation pour ajuster la durée
  static double _getMotivationFactor(String motivation) {
    final factors = {
      'Passion pour Christ': 0.9,
      'Amour pour Dieu': 0.95,
      'Obéissance joyeuse': 1.0,
      'Désir de connaître Dieu': 1.1,
      'Besoin de transformation': 1.2,
      'Recherche de direction': 1.1,
      'Discipline spirituelle': 1.0,
    };
    
    return factors[motivation] ?? 1.0;
  }
  
  /// Calcule la longueur optimale des passages selon le livre
  static int calculateOptimalPassageLength({
    required String book,
    required int minutes,
    required String meditationType,
  }) {
    // Calcul basé sur la densité du livre et le temps disponible
    final bookDensity = _getBookDensity(book);
    final baseVerses = (minutes * bookDensity).round();
    
    // Ajustement selon le type de méditation
    final meditationMultiplier = _getMeditationMultiplier(meditationType);
    final adjustedVerses = (baseVerses * meditationMultiplier).round();
    
    // Limites raisonnables
    return adjustedVerses.clamp(3, 25);
  }
  
  /// Calcule la longueur optimale avec unités littéraires
  static Future<int> calculateOptimalPassageLengthWithLiteraryUnits({
    required String book,
    required int minutes,
    required String meditationType,
    required int startChapter,
    required int startVerse,
    required int endChapter,
    required int endVerse,
  }) async {
    try {
      // 1. Analyser les unités littéraires
      final literaryUnits = await SemanticPassageBoundaryService.adjustPassageVerses(
        book: book,
        startChapter: startChapter,
        startVerse: startVerse,
        endChapter: endChapter,
        endVerse: endVerse,
      );
      
      // 2. Calculer la longueur optimale
      final baseLength = calculateOptimalPassageLength(
        book: book,
        minutes: minutes,
        meditationType: meditationType,
      );
      
      // 3. Ajuster selon les unités littéraires
      if (literaryUnits.isNotEmpty) {
        final unitLength = literaryUnits.length;
        return (baseLength * (1.0 + (unitLength * 0.1))).round().clamp(3, 30);
      }
      
      return baseLength;
    } catch (e) {
      print('⚠️ Literary units analysis failed: $e');
      return calculateOptimalPassageLength(
        book: book,
        minutes: minutes,
        meditationType: meditationType,
      );
    }
  }
  
  /// Génère des presets personnalisés
  static List<Map<String, dynamic>> generatePersonalizedPresets({
    required String goal,
    required String level,
    required int dailyMinutes,
    String? posture,
    String? motivation,
  }) {
    final presets = <Map<String, dynamic>>[];
    
    // Preset 1: Focus sur l'objectif principal
    presets.add({
      'name': 'Focus ${goal}',
      'description': 'Plan concentré sur votre objectif principal',
      'duration': calculateOptimalDuration(
        goal: goal,
        level: level,
        dailyMinutes: dailyMinutes,
        meditationType: 'Méditation Biblique',
        motivation: motivation,
        posture: posture,
      ),
      'books': getRecommendedBooksForProfile(
        goal: goal,
        posture: posture,
        motivation: motivation,
        limit: 3,
      ),
    });
    
    // Preset 2: Équilibre spirituel
    presets.add({
      'name': 'Équilibre Spirituel',
      'description': 'Plan équilibré pour une croissance complète',
      'duration': calculateOptimalDuration(
        goal: goal,
        level: level,
        dailyMinutes: dailyMinutes,
        meditationType: 'Méditation Biblique',
        motivation: motivation,
        posture: posture,
      ) + 7,
      'books': getRecommendedBooksForProfile(
        goal: goal,
        posture: posture,
        motivation: motivation,
        limit: 5,
      ),
    });
    
    return presets;
  }
  
  // ============ MÉTHODES UTILITAIRES ============
  
  /// Récupère tous les livres bibliques
  static List<String> _getAllBibleBooks() {
    return [
      'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
      'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
      '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques', 'Esdras',
      'Néhémie', 'Esther', 'Job', 'Psaumes', 'Proverbes',
      'Ecclésiaste', 'Cantique des Cantiques', 'Ésaïe', 'Jérémie', 'Lamentations',
      'Ézéchiel', 'Daniel', 'Osée', 'Joël', 'Amos',
      'Abdias', 'Jonas', 'Michée', 'Nahum', 'Habacuc',
      'Sophonie', 'Aggée', 'Zacharie', 'Malachie',
      'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
      'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens',
      'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens',
      '1 Timothée', '2 Timothée', 'Tite', 'Philémon', 'Hébreux',
      'Jacques', '1 Pierre', '2 Pierre', '1 Jean', '2 Jean',
      '3 Jean', 'Jude', 'Apocalypse'
    ];
  }
  
  /// Calcule la densité d'un livre biblique
  static double _getBookDensity(String book) {
    final densities = {
      'Psaumes': 0.8,
      'Proverbes': 0.7,
      'Jean': 0.9,
      'Romains': 0.6,
      'Éphésiens': 0.8,
      'Philippiens': 0.7,
      'Colossiens': 0.8,
      '1 Jean': 0.9,
      '2 Jean': 0.8,
      '3 Jean': 0.8,
      'Jude': 0.9,
    };
    
    return densities[book] ?? 0.5;
  }
  
  /// Multiplicateur selon le type de méditation
  static double _getMeditationMultiplier(String meditationType) {
    final multipliers = {
      'Méditation Biblique': 1.0,
      'Lecture Rapide': 1.5,
      'Étude Approfondie': 0.7,
      'Méditation Contemplative': 0.8,
    };
    
    return multipliers[meditationType] ?? 1.0;
  }
  
  /// Bonus de posture pour un livre
  static double _getPostureBonus(String book, String posture) {
    final bonuses = {
      'Jean': {'Rencontrer Jésus personnellement': 0.2, 'Développer l\'intimité avec le Père': 0.3},
      'Psaumes': {'Mieux prier': 0.3, 'Écouter la voix de Dieu': 0.2},
      'Proverbes': {'Sagesse': 0.2, 'Développer mon caractère': 0.3},
      'Romains': {'Approfondir la Parole': 0.2, 'Grandir dans la foi': 0.3},
      'Éphésiens': {'Développer mon caractère': 0.3, 'Renouveler mes pensées': 0.2},
    };
    
    return bonuses[book]?[posture] ?? 0.0;
  }
  
  // ============ MÉTHODES DE DEBUG ============
  
  /// Affiche les statistiques des bases de données
  static void printStatistics() {
    print('📊 Statistiques des Bases de Données Intelligentes:');
    print('   - Livres bibliques: ${_getAllBibleBooks().length}');
    print('   - Thèmes disponibles: 10 (faith, identity, character, etc.)');
    print('   - Objectifs spirituels: 18');
    print('   - Postures du cœur: 6');
    print('   - Motivations: ${_getMotivationFactor('Passion pour Christ')}');
    print('   - VPM par livre: ${_getAllBibleBooks().length}');
  }
  
  /// Teste le calcul d'impact pour un exemple
  static void testImpactCalculation() {
    final impact = calculateBookImpactOnGoal(
      book: 'Jean',
      goal: 'Rencontrer Jésus dans la Parole',
      posture: 'Rencontrer Jésus personnellement',
    );
    
    print('🧪 Test d\'impact: Jean + Rencontrer Jésus = $impact');
  }
}
