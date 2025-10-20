// lib/services/intelligent_databases.dart

import 'intelligent_duration_calculator.dart';

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
    if (posture != null) {
      return IntelligentDurationCalculator.calculateBookImpactWithPosture(
        book: book,
        goal: goal,
        posture: posture,
      );
    } else {
      return IntelligentDurationCalculator.calculateBookImpactOnGoal(book, goal);
    }
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
    // 1. Durée de base
    final baseDuration = IntelligentDurationCalculator.calculateOptimalDuration(
      goal: goal,
      level: level,
      dailyMinutes: dailyMinutes,
      meditationType: meditationType,
    ).optimalDays;
    
    // 2. Ajustement selon la motivation
    if (motivation != null) {
      final multipliers = IntelligentDurationCalculator.getMotivationMultipliers();
      final motivationData = multipliers.firstWhere(
        (m) => m['motivation'] == motivation,
        orElse: () => {'duration_factor': 1.0},
      );
      
      final factor = motivationData['duration_factor'] as double? ?? 1.0;
      return (baseDuration * factor).round();
    }
    
    return baseDuration;
  }
  
  /// Calcule la longueur optimale des passages selon le livre
  static int calculateOptimalPassageLength({
    required String book,
    required int minutes,
    required String meditationType,
  }) {
    // 1. Utiliser la densité du livre depuis BookDensityCalculator
    final density = _getBookDensity(book);
    double vpm = density.versesPerMinute;
    
    switch (meditationType.toLowerCase()) {
      case 'méditation profonde':
        vpm *= 0.7; // Plus lent pour la méditation
        break;
      case 'lecture rapide':
        vpm *= 1.3; // Plus rapide
        break;
      case 'étude approfondie':
        vpm *= 0.5; // Très lent pour l'étude
        break;
      default:
        // Méditation normale
        break;
    }
    
    // 3. Calculer le nombre de versets
    final verses = (minutes * vpm).round();
    return verses.clamp(5, 30); // Entre 5 et 30 versets
  }
  
  /// Génère des recommandations personnalisées de presets
  static List<Map<String, dynamic>> generatePersonalizedPresets({
    required String goal,
    required String level,
    required int dailyMinutes,
    String? posture,
    String? motivation,
  }) {
    final recommendedBooks = getRecommendedBooksForProfile(
      goal: goal,
      posture: posture,
      motivation: motivation,
      limit: 3,
    );
    
    if (recommendedBooks.isEmpty) {
      return _getDefaultPresets();
    }
    
    // Générer des presets basés sur les livres recommandés
    final presets = <Map<String, dynamic>>[];
    
    for (int i = 0; i < recommendedBooks.length; i++) {
      final book = recommendedBooks[i];
      final impact = calculateBookImpactOnGoal(
        book: book,
        goal: goal,
        posture: posture,
      );
      
      final duration = calculateOptimalDuration(
        goal: goal,
        level: level,
        dailyMinutes: dailyMinutes,
        meditationType: 'Méditation Biblique',
        motivation: motivation,
        posture: posture,
      );
      
      presets.add({
        'name': '${_getPresetNameForBook(book)} - ${_getGoalShortName(goal)}',
        'description': _getPresetDescription(book, goal, impact),
        'books': [book],
        'duration_days': duration,
        'minutes_per_day': dailyMinutes,
        'impact_score': impact,
        'meditation_type': 'Méditation Biblique',
        'level': level,
        'goal': goal,
        'posture': posture,
        'motivation': motivation,
      });
    }
    
    return presets;
  }
  
  // ============ MÉTHODES UTILITAIRES ============
  
  /// Récupère la densité d'un livre (fallback simple)
  static _BookDensity _getBookDensity(String book) {
    // Mapping simplifié des livres vers leur densité
    final bookDensities = {
      'Jean': _BookDensity(versesPerMinute: 2.5),
      'Psaumes': _BookDensity(versesPerMinute: 3.2),
      'Romains': _BookDensity(versesPerMinute: 2.0),
      'Actes': _BookDensity(versesPerMinute: 2.7),
      'Éphésiens': _BookDensity(versesPerMinute: 2.0),
      'Philippiens': _BookDensity(versesPerMinute: 2.4),
      'Colossiens': _BookDensity(versesPerMinute: 2.1),
      '1 Corinthiens': _BookDensity(versesPerMinute: 2.3),
      '2 Corinthiens': _BookDensity(versesPerMinute: 2.2),
      'Galates': _BookDensity(versesPerMinute: 2.1),
      '1 Thessaloniciens': _BookDensity(versesPerMinute: 2.4),
      '2 Thessaloniciens': _BookDensity(versesPerMinute: 2.3),
      '1 Timothée': _BookDensity(versesPerMinute: 2.2),
      '2 Timothée': _BookDensity(versesPerMinute: 2.3),
      'Tite': _BookDensity(versesPerMinute: 2.4),
      'Philémon': _BookDensity(versesPerMinute: 2.5),
      'Hébreux': _BookDensity(versesPerMinute: 1.9),
      'Jacques': _BookDensity(versesPerMinute: 2.5),
      '1 Pierre': _BookDensity(versesPerMinute: 2.3),
      '2 Pierre': _BookDensity(versesPerMinute: 2.1),
      '1 Jean': _BookDensity(versesPerMinute: 2.4),
      '2 Jean': _BookDensity(versesPerMinute: 2.6),
      '3 Jean': _BookDensity(versesPerMinute: 2.6),
      'Jude': _BookDensity(versesPerMinute: 2.2),
      'Apocalypse': _BookDensity(versesPerMinute: 1.8),
      'Matthieu': _BookDensity(versesPerMinute: 2.7),
      'Marc': _BookDensity(versesPerMinute: 2.8),
      'Luc': _BookDensity(versesPerMinute: 2.6),
      'Genèse': _BookDensity(versesPerMinute: 2.8),
      'Exode': _BookDensity(versesPerMinute: 2.5),
      'Lévitique': _BookDensity(versesPerMinute: 1.8),
      'Nombres': _BookDensity(versesPerMinute: 2.3),
      'Deutéronome': _BookDensity(versesPerMinute: 2.0),
      'Josué': _BookDensity(versesPerMinute: 2.7),
      'Juges': _BookDensity(versesPerMinute: 2.6),
      'Ruth': _BookDensity(versesPerMinute: 3.0),
      '1 Samuel': _BookDensity(versesPerMinute: 2.6),
      '2 Samuel': _BookDensity(versesPerMinute: 2.6),
      '1 Rois': _BookDensity(versesPerMinute: 2.5),
      '2 Rois': _BookDensity(versesPerMinute: 2.5),
      '1 Chroniques': _BookDensity(versesPerMinute: 2.4),
      '2 Chroniques': _BookDensity(versesPerMinute: 2.4),
      'Esdras': _BookDensity(versesPerMinute: 2.6),
      'Néhémie': _BookDensity(versesPerMinute: 2.6),
      'Esther': _BookDensity(versesPerMinute: 2.7),
      'Job': _BookDensity(versesPerMinute: 1.9),
      'Proverbes': _BookDensity(versesPerMinute: 2.5),
      'Ecclésiaste': _BookDensity(versesPerMinute: 2.3),
      'Cantique des Cantiques': _BookDensity(versesPerMinute: 2.8),
      'Ésaïe': _BookDensity(versesPerMinute: 2.2),
      'Jérémie': _BookDensity(versesPerMinute: 2.1),
      'Lamentations': _BookDensity(versesPerMinute: 2.5),
      'Ézéchiel': _BookDensity(versesPerMinute: 2.0),
      'Daniel': _BookDensity(versesPerMinute: 2.3),
      'Osée': _BookDensity(versesPerMinute: 2.2),
      'Joël': _BookDensity(versesPerMinute: 2.4),
      'Amos': _BookDensity(versesPerMinute: 2.3),
      'Abdias': _BookDensity(versesPerMinute: 2.5),
      'Jonas': _BookDensity(versesPerMinute: 2.9),
      'Michée': _BookDensity(versesPerMinute: 2.3),
      'Nahum': _BookDensity(versesPerMinute: 2.4),
      'Habacuc': _BookDensity(versesPerMinute: 2.3),
      'Sophonie': _BookDensity(versesPerMinute: 2.4),
      'Aggée': _BookDensity(versesPerMinute: 2.5),
      'Zacharie': _BookDensity(versesPerMinute: 2.2),
      'Malachie': _BookDensity(versesPerMinute: 2.5),
    };
    
    return bookDensities[book] ?? _BookDensity(versesPerMinute: 2.5);
  }
  
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
      'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée',
      '2 Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques',
      '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean',
      'Jude', 'Apocalypse'
    ];
  }
  
  /// Génère un nom de preset pour un livre
  static String _getPresetNameForBook(String book) {
    final bookNames = {
      'Jean': 'Rencontre avec Jésus',
      'Psaumes': 'Louange et Adoration',
      'Romains': 'Fondements de la Foi',
      'Actes': 'Puissance de l\'Esprit',
      'Éphésiens': 'Identité en Christ',
      'Philippiens': 'Joie dans l\'Épreuve',
      'Colossiens': 'Souveraineté de Christ',
      '1 Corinthiens': 'Vie Chrétienne Pratique',
      '2 Corinthiens': 'Ministère et Souffrance',
      'Galates': 'Liberté en Christ',
      '1 Thessaloniciens': 'Espérance du Retour',
      '2 Thessaloniciens': 'Préparation à l\'Avenir',
      '1 Timothée': 'Leadership Chrétien',
      '2 Timothée': 'Fidélité jusqu\'au Bout',
      'Tite': 'Ordre dans l\'Église',
      'Philémon': 'Réconciliation',
      'Hébreux': 'Supériorité de Christ',
      'Jacques': 'Foi en Action',
      '1 Pierre': 'Souffrance et Gloire',
      '2 Pierre': 'Croissance Spirituelle',
      '1 Jean': 'Amour et Vérité',
      '2 Jean': 'Marche dans la Vérité',
      '3 Jean': 'Hospitalité Chrétienne',
      'Jude': 'Contre l\'Apostasie',
      'Apocalypse': 'Révélation de l\'Avenir',
    };
    
    return bookNames[book] ?? 'Étude de $book';
  }
  
  /// Génère une description de preset
  static String _getPresetDescription(String book, String goal, double impact) {
    final impactPercent = (impact * 100).round();
    return 'Étude de $book pour ${_getGoalShortName(goal)}. Impact spirituel: $impactPercent%';
  }
  
  /// Récupère le nom court d'un objectif
  static String _getGoalShortName(String goal) {
    final shortNames = {
      '🔥 Être transformé à son image': 'Transformation',
      '❤️ Développer l\'intimité avec le Père': 'Intimité',
      '💎 Rencontrer Jésus personnellement': 'Rencontre',
      '🔥 Être transformé par l\'Esprit': 'Transformation',
      '📚 Approfondir ma connaissance': 'Connaissance',
      '⚡ Recevoir la puissance de l\'Esprit': 'Puissance',
      '🕊️ Marcher par l\'Esprit': 'Marche',
      '🙏 Écouter la voix de Dieu': 'Écoute',
      '🎯 Découvrir ma mission': 'Mission',
      '💪 Grandir dans la foi': 'Foi',
      '🕊️ Vivre dans la sainteté': 'Sainteté',
      '❤️ Aimer comme Jésus': 'Amour',
      '🌟 Briller pour Dieu': 'Témoignage',
      '🛡️ Résister aux tentations': 'Résistance',
      '🎁 Recevoir les bénédictions': 'Bénédictions',
      '🌱 Grandir spirituellement': 'Croissance',
      '🔍 Comprendre la Parole': 'Compréhension',
      '🎯 Accomplir ma destinée': 'Destinée',
    };
    
    return shortNames[goal] ?? 'Objectif spirituel';
  }
  
  /// Presets par défaut en cas d'échec
  static List<Map<String, dynamic>> _getDefaultPresets() {
    return [
      {
        'name': 'Méditation Biblique Générale',
        'description': 'Plan équilibré pour la croissance spirituelle',
        'books': ['Psaumes', 'Jean'],
        'duration_days': 30,
        'minutes_per_day': 15,
        'impact_score': 0.7,
        'meditation_type': 'Méditation Biblique',
        'level': 'Intermédiaire',
      },
      {
        'name': 'Étude Approfondie',
        'description': 'Plan intensif pour approfondir la connaissance',
        'books': ['Romains', 'Hébreux'],
        'duration_days': 45,
        'minutes_per_day': 25,
        'impact_score': 0.8,
        'meditation_type': 'Étude Approfondie',
        'level': 'Avancé',
      },
    ];
  }
  
  // ============ MÉTHODES DE DEBUG ============
  
  /// Affiche les statistiques des bases de données
  static void printDatabaseStats() {
    print('📊 Statistiques des Bases de Données Intelligentes:');
    print('   - Livres bibliques: ${_getAllBibleBooks().length}');
    print('   - Thèmes disponibles: 10 (faith, identity, character, etc.)');
    print('   - Objectifs spirituels: 18');
    print('   - Postures du cœur: 6');
    print('   - Motivations: ${IntelligentDurationCalculator.getMotivationMultipliers().length}');
    print('   - VPM par livre: ${_getAllBibleBooks().length}');
  }
  
  /// Teste le calcul d'impact pour un exemple
  static void testImpactCalculation() {
    print('🧪 Test de calcul d\'impact:');
    
    final book = 'Jean';
    final goal = '💎 Rencontrer Jésus personnellement';
    final posture = '💎 Rencontrer Jésus personnellement';
    
    final impact = calculateBookImpactOnGoal(
      book: book,
      goal: goal,
      posture: posture,
    );
    
    print('   - Livre: $book');
    print('   - Objectif: $goal');
    print('   - Posture: $posture');
    print('   - Impact calculé: ${(impact * 100).toStringAsFixed(1)}%');
  }
  
  /// Retourne le bonus de posture pour un livre
  static double _getPostureBonus(String book, String posture) {
    final bookLower = book.toLowerCase();
    
    switch (posture) {
      case 'Rencontrer Jésus':
        if (bookLower.contains('jean') || bookLower.contains('matthieu') || 
            bookLower.contains('marc') || bookLower.contains('luc')) {
          return 0.2;
        }
        return 0.0;
      case 'transformé':
        if (bookLower.contains('romains') || bookLower.contains('galates') || 
            bookLower.contains('éphésiens')) {
          return 0.2;
        }
        return 0.0;
      case 'Écouter':
        if (bookLower.contains('proverbes') || bookLower.contains('psaumes')) {
          return 0.2;
        }
        return 0.0;
      case 'intimité':
        if (bookLower.contains('jean') || bookLower.contains('psaumes') || 
            bookLower.contains('cantiques')) {
          return 0.2;
        }
        return 0.0;
      default:
        return 0.0;
    }
  }

  /// Calcule la pertinence d'un thème pour un nom de preset
  static double getThemeRelevance(String presetName, String theme) {
    final name = presetName.toLowerCase();
    final themeLower = theme.toLowerCase();
    
    // Mapping des thèmes vers des mots-clés
    final themeKeywords = {
      'fondations de la foi': ['fondation', 'base', 'christ', 'jésus', 'évangile', 'salut'],
      'discipline spirituelle': ['discipline', 'régularité', 'habitude', 'constance'],
      'repentance et pardon': ['repentance', 'pardon', 'péché', 'confession'],
      'intimité avec dieu': ['intimité', 'prière', 'adoration', 'psaumes'],
      'sagesse et connaissance': ['sagesse', 'connaissance', 'proverbes', 'étude'],
      'mission et service': ['mission', 'service', 'évangélisation', 'témoignage'],
    };
    
    final keywords = themeKeywords[themeLower] ?? [];
    if (keywords.isEmpty) return 0.5;
    
    // Compter les mots-clés trouvés
    int matches = 0;
    for (final keyword in keywords) {
      if (name.contains(keyword)) {
        matches++;
      }
    }
    
    // Retourner un score basé sur le nombre de correspondances
    return (matches / keywords.length).clamp(0.0, 1.0);
  }
}

/// Classe simple pour la densité d'un livre
class _BookDensity {
  final double versesPerMinute;
  
  const _BookDensity({required this.versesPerMinute});
}
