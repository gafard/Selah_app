/// 🕊️ SERVICE DE FILTRAGE BIBLIQUE DES PRESETS
/// 
/// Basé sur les critères bibliques fondamentaux :
/// 1. La doctrine de Christ (1 Jean 4:1-3)
/// 2. L'autorité de la Bible (2 Timothée 3:16, Apocalypse 22:18)
/// 3. L'évangile de Jésus-Christ (Galates 1:6-9)
/// 
/// Ce service filtre et classe les presets selon leur alignement
/// avec la vérité biblique et la doctrine apostolique.
library;

import '../models/plan_preset.dart';

class BiblicalPresetFilter {
  
  /// 🕊️ Critères bibliques fondamentaux
  static const Map<String, List<String>> _biblicalCriteria = {
    // 1. Doctrine de Christ (1 Jean 4:1-3)
    'doctrine_christ': [
      'jésus est venu en chair',
      'jésus est le fils de dieu',
      'jésus est christ',
      'jésus est seigneur',
      'jésus est sauveur',
      'jésus est messie',
      'incarnation',
      'divinité de christ',
      'humanité de christ',
      'mort expiatoire',
      'résurrection',
      'ascension',
    ],
    
    // 2. Autorité de la Bible (2 Timothée 3:16, Apocalypse 22:18)
    'authority_bible': [
      'inspiration divine',
      'infaillibilité',
      'autorité suprême',
      'parole de dieu',
      'écriture sainte',
      'révélation divine',
      'canon biblique',
      'intégrité des écritures',
      'vérité absolue',
      'norme de foi',
    ],
    
    // 3. Évangile de Jésus-Christ (Galates 1:6-9)
    'gospel_jesus': [
      'salut par grâce',
      'foi en jésus',
      'mort et résurrection',
      'réconciliation avec dieu',
      'nouvelle naissance',
      'justification par la foi',
      'rédemption',
      'expiation',
      'adoption divine',
      'héritage éternel',
      'royaume de dieu',
      'retour de christ',
    ],
  };
  
  /// 🕊️ Livres bibliques par catégorie doctrinale
  static const Map<String, List<String>> _doctrinalBooks = {
    'doctrine_christ': [
      'jean', 'matthieu', 'marc', 'luc', 'actes', 'romains', 'galates',
      'philippiens', 'colossiens', 'hébreux', '1 jean', '2 jean', '3 jean',
      'apocalypse'
    ],
    'authority_bible': [
      'psaumes', 'proverbes', 'écclésiaste', 'cantique', '2 timothée',
      '2 pierre', 'jude', 'apocalypse'
    ],
    'gospel_jesus': [
      'matthieu', 'marc', 'luc', 'jean', 'actes', 'romains', 'galates',
      'éphésiens', 'philippiens', 'colossiens', '1 thessaloniciens',
      '2 thessaloniciens', '1 timothée', '2 timothée', 'tite', 'philémon',
      'hébreux', 'jacques', '1 pierre', '2 pierre', '1 jean', '2 jean',
      '3 jean', 'jude', 'apocalypse'
    ],
  };
  
  /// 🕊️ Filtre les presets selon les critères bibliques
  static List<PlanPreset> filterPresetsByBiblicalCriteria(
    List<PlanPreset> presets,
    Map<String, dynamic> userProfile,
  ) {
    print('🕊️ Filtrage biblique des presets...');
    
    final filteredPresets = <PlanPreset>[];
    
    for (final preset in presets) {
      final biblicalScore = _calculateBiblicalScore(preset, userProfile);
      
      // Seuls les presets avec un score biblique élevé sont retenus
      if (biblicalScore >= 0.7) {
        final enrichedPreset = _enrichPresetWithBiblicalData(preset, biblicalScore);
        filteredPresets.add(enrichedPreset);
      }
    }
    
    // Trier par score biblique décroissant
    filteredPresets.sort((a, b) {
      final scoreA = a.parameters?['biblical_score'] as double? ?? 0.0;
      final scoreB = b.parameters?['biblical_score'] as double? ?? 0.0;
      return scoreB.compareTo(scoreA);
    });
    
    print('🕊️ ${filteredPresets.length} presets filtrés selon les critères bibliques');
    return filteredPresets;
  }
  
  /// 🕊️ Calcule le score biblique d'un preset
  static double _calculateBiblicalScore(PlanPreset preset, Map<String, dynamic> userProfile) {
    double score = 0.0;
    int criteriaCount = 0;
    
    // 1. Vérifier la doctrine de Christ
    final doctrineScore = _evaluateDoctrineOfChrist(preset);
    score += doctrineScore;
    criteriaCount++;
    
    // 2. Vérifier l'autorité de la Bible
    final authorityScore = _evaluateBibleAuthority(preset);
    score += authorityScore;
    criteriaCount++;
    
    // 3. Vérifier l'évangile de Jésus-Christ
    final gospelScore = _evaluateGospelOfJesus(preset);
    score += gospelScore;
    criteriaCount++;
    
    // 4. Vérifier l'alignement avec le profil utilisateur
    final alignmentScore = _evaluateUserAlignment(preset, userProfile);
    score += alignmentScore;
    criteriaCount++;
    
    return criteriaCount > 0 ? score / criteriaCount : 0.0;
  }
  
  /// 🕊️ Évalue l'alignement avec la doctrine de Christ
  static double _evaluateDoctrineOfChrist(PlanPreset preset) {
    double score = 0.0;
    
    // Vérifier les livres inclus
    final books = preset.books.toLowerCase();
    final doctrinalBooks = _doctrinalBooks['doctrine_christ']!;
    
    int matchingBooks = 0;
    for (final book in doctrinalBooks) {
      if (books.contains(book)) {
        matchingBooks++;
      }
    }
    
    // Score basé sur la proportion de livres doctrinaux
    if (doctrinalBooks.isNotEmpty) {
      score = matchingBooks / doctrinalBooks.length;
    }
    
    // Bonus pour les presets centrés sur Christ
    if (preset.name.toLowerCase().contains('évangiles') ||
        preset.name.toLowerCase().contains('nouveau testament') ||
        preset.name.toLowerCase().contains('jésus')) {
      score = (score + 1.0) / 2; // Moyenne avec bonus
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// 🕊️ Évalue l'alignement avec l'autorité de la Bible
  static double _evaluateBibleAuthority(PlanPreset preset) {
    double score = 0.0;
    
    // Vérifier si le preset couvre toute la Bible
    if (preset.books.toLowerCase().contains('toute') ||
        preset.books.toLowerCase().contains('complète') ||
        preset.books.toLowerCase().contains('bible entière')) {
      score = 1.0;
    } else {
      // Score basé sur la diversité des livres
      final books = preset.books.toLowerCase();
      final authorityBooks = _doctrinalBooks['authority_bible']!;
      
      int matchingBooks = 0;
      for (final book in authorityBooks) {
        if (books.contains(book)) {
          matchingBooks++;
        }
      }
      
      if (authorityBooks.isNotEmpty) {
        score = matchingBooks / authorityBooks.length;
      }
    }
    
    // Bonus pour les presets qui respectent l'intégrité biblique
    if (preset.name.toLowerCase().contains('chronologique') ||
        preset.name.toLowerCase().contains('traditionnel')) {
      score = (score + 0.8) / 2; // Moyenne avec bonus
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// 🕊️ Évalue l'alignement avec l'évangile de Jésus-Christ
  static double _evaluateGospelOfJesus(PlanPreset preset) {
    double score = 0.0;
    
    // Vérifier les livres évangéliques
    final books = preset.books.toLowerCase();
    final gospelBooks = _doctrinalBooks['gospel_jesus']!;
    
    int matchingBooks = 0;
    for (final book in gospelBooks) {
      if (books.contains(book)) {
        matchingBooks++;
      }
    }
    
    if (gospelBooks.isNotEmpty) {
      score = matchingBooks / gospelBooks.length;
    }
    
    // Bonus pour les presets centrés sur l'évangile
    if (preset.name.toLowerCase().contains('évangile') ||
        preset.name.toLowerCase().contains('salut') ||
        preset.name.toLowerCase().contains('grâce')) {
      score = (score + 1.0) / 2; // Moyenne avec bonus
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// 🕊️ Évalue l'alignement avec le profil utilisateur
  static double _evaluateUserAlignment(PlanPreset preset, Map<String, dynamic> userProfile) {
    double score = 0.0;
    
    // Vérifier l'alignement avec l'objectif spirituel
    final userGoal = userProfile['goal'] as String? ?? '';
    final presetName = preset.name.toLowerCase();
    
    if (userGoal.isNotEmpty) {
      if (userGoal.contains('Rencontrer Jésus') && presetName.contains('évangiles')) {
        score += 0.3;
      }
      if (userGoal.contains('Voir Jésus') && presetName.contains('nouveau testament')) {
        score += 0.3;
      }
      if (userGoal.contains('Transformé') && presetName.contains('romains')) {
        score += 0.3;
      }
      if (userGoal.contains('Intimité') && presetName.contains('jean')) {
        score += 0.3;
      }
      if (userGoal.contains('Prier') && presetName.contains('psaumes')) {
        score += 0.3;
      }
      if (userGoal.contains('Voix de Dieu') && presetName.contains('proverbes')) {
        score += 0.3;
      }
    }
    
    // Vérifier l'alignement avec le niveau spirituel
    final userLevel = userProfile['level'] as String? ?? '';
    final presetDuration = preset.durationDays;
    
    if (userLevel == 'Nouveau converti' && presetDuration <= 30) {
      score += 0.2;
    } else if (userLevel == 'Fidèle régulier' && presetDuration <= 90) {
      score += 0.2;
    } else if (userLevel == 'Serviteur/leader' && presetDuration >= 60) {
      score += 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// 🕊️ Enrichit un preset avec les données bibliques
  static PlanPreset _enrichPresetWithBiblicalData(PlanPreset preset, double biblicalScore) {
    final biblicalData = {
      'biblical_score': biblicalScore,
      'biblical_grade': _getBiblicalGrade(biblicalScore),
      'biblical_reasoning': _generateBiblicalReasoning(preset, biblicalScore),
      'biblical_warnings': _generateBiblicalWarnings(preset, biblicalScore),
      'doctrinal_alignment': {
        'doctrine_christ': _evaluateDoctrineOfChrist(preset),
        'authority_bible': _evaluateBibleAuthority(preset),
        'gospel_jesus': _evaluateGospelOfJesus(preset),
      },
    };
    
    return preset.copyWith(
      parameters: {
        ...preset.parameters ?? {},
        ...biblicalData,
      },
    );
  }
  
  /// 🕊️ Détermine la note biblique
  static String _getBiblicalGrade(double score) {
    if (score >= 0.9) return 'A+ (Excellent)';
    if (score >= 0.8) return 'A (Très bon)';
    if (score >= 0.7) return 'B+ (Bon)';
    if (score >= 0.6) return 'B (Satisfaisant)';
    if (score >= 0.5) return 'C (Moyen)';
    return 'D (Insuffisant)';
  }
  
  /// 🕊️ Génère le raisonnement biblique
  static String _generateBiblicalReasoning(PlanPreset preset, double score) {
    final reasoning = <String>[];
    
    if (score >= 0.8) {
      reasoning.add('✅ Excellent alignement avec la doctrine biblique');
      reasoning.add('✅ Respecte l\'autorité de la Parole de Dieu');
      reasoning.add('✅ Centré sur l\'évangile de Jésus-Christ');
    } else if (score >= 0.7) {
      reasoning.add('✅ Bon alignement avec les critères bibliques');
      reasoning.add('✅ Respecte les fondements de la foi');
    } else {
      reasoning.add('⚠️ Alignement partiel avec les critères bibliques');
    }
    
    // Ajouter des détails spécifiques
    if (preset.name.toLowerCase().contains('évangiles')) {
      reasoning.add('📖 Focus sur la vie et l\'enseignement de Jésus');
    }
    if (preset.name.toLowerCase().contains('nouveau testament')) {
      reasoning.add('📖 Couvre l\'accomplissement des prophéties');
    }
    if (preset.name.toLowerCase().contains('psaumes')) {
      reasoning.add('📖 Enrichit la vie de prière et d\'adoration');
    }
    
    return reasoning.join('\n');
  }
  
  /// 🕊️ Génère les avertissements bibliques
  static List<String> _generateBiblicalWarnings(PlanPreset preset, double score) {
    final warnings = <String>[];
    
    if (score < 0.7) {
      warnings.add('⚠️ Score biblique insuffisant - vérifiez l\'alignement doctrinal');
    }
    
    if (preset.durationDays > 365) {
      warnings.add('⚠️ Durée très longue - risque de découragement');
    }
    
    if (preset.durationDays < 7) {
      warnings.add('⚠️ Durée très courte - transformation limitée');
    }
    
    return warnings;
  }
  
  /// 🕊️ Obtient les recommandations bibliques pour un preset
  static Map<String, dynamic> getBiblicalRecommendations(PlanPreset preset) {
    final score = preset.parameters?['biblical_score'] as double? ?? 0.0;
    final doctrinalAlignment = preset.parameters?['doctrinal_alignment'] as Map<String, dynamic>? ?? {};
    
    return {
      'overall_score': score,
      'grade': _getBiblicalGrade(score),
      'doctrine_christ_score': doctrinalAlignment['doctrine_christ'] ?? 0.0,
      'authority_bible_score': doctrinalAlignment['authority_bible'] ?? 0.0,
      'gospel_jesus_score': doctrinalAlignment['gospel_jesus'] ?? 0.0,
      'recommendation': _getBiblicalRecommendation(score),
      'scripture_references': _getRelevantScriptures(preset),
    };
  }
  
  /// 🕊️ Génère la recommandation biblique
  static String _getBiblicalRecommendation(double score) {
    if (score >= 0.9) {
      return 'Excellente recommandation biblique - parfaitement aligné avec la doctrine apostolique';
    } else if (score >= 0.8) {
      return 'Très bonne recommandation biblique - respecte les fondements de la foi';
    } else if (score >= 0.7) {
      return 'Bonne recommandation biblique - aligné avec les critères fondamentaux';
    } else {
      return 'Recommandation biblique limitée - vérifiez l\'alignement doctrinal';
    }
  }
  
  /// 🕊️ Obtient les références bibliques pertinentes
  static List<String> _getRelevantScriptures(PlanPreset preset) {
    final scriptures = <String>[];
    
    if (preset.name.toLowerCase().contains('évangiles')) {
      scriptures.addAll([
        '1 Jean 4:1-3 - Doctrine de Christ',
        'Jean 1:1-14 - Incarnation',
        'Philippiens 2:5-11 - Humilité de Christ',
      ]);
    }
    
    if (preset.name.toLowerCase().contains('bible') || preset.name.toLowerCase().contains('toute')) {
      scriptures.addAll([
        '2 Timothée 3:16 - Inspiration des Écritures',
        'Apocalypse 22:18-19 - Intégrité de la Parole',
        'Psaume 119:105 - Lampe à mes pieds',
      ]);
    }
    
    if (preset.name.toLowerCase().contains('salut') || preset.name.toLowerCase().contains('grâce')) {
      scriptures.addAll([
        'Galates 1:6-9 - Évangile de Jésus-Christ',
        'Éphésiens 2:8-9 - Salut par grâce',
        'Romains 3:23-24 - Justification gratuite',
      ]);
    }
    
    return scriptures;
  }
}
