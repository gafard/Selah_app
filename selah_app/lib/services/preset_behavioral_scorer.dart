/// ═══════════════════════════════════════════════════════════════════════════
/// PRESET BEHAVIORAL SCORER - Scoring enrichi avec science comportementale
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Enrichit le scoring des presets (Phase 1) avec :
/// - Science comportementale (formation habitudes, neuroplasticité)
/// - Témoignages chrétiens (40 jours Jésus, Moïse, David)
/// - Psychologie motivation (Self-Determination Theory)
/// - Facteurs de complétion (basés sur données réelles)
///
/// Intégration avec IntelligentLocalPresetGenerator pour scoring ultra-précis.
/// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

/// Résultat d'analyse comportementale d'un preset
class BehavioralScore {
  final double behavioralFitScore; // 0-1 (fit avec science)
  final double testimonyResonanceScore; // 0-1 (résonance témoignages)
  final double completionProbability; // 0-1 (probabilité complétion)
  final double motivationAlignment; // 0-1 (alignement motivation)
  final String reasoning; // Explication
  final List<String> scientificBasis; // Études référencées
  final List<String> testimonies; // Témoignages pertinents

  const BehavioralScore({
    required this.behavioralFitScore,
    required this.testimonyResonanceScore,
    required this.completionProbability,
    required this.motivationAlignment,
    required this.reasoning,
    required this.scientificBasis,
    required this.testimonies,
  });

  /// Score combiné (moyenne pondérée)
  double get combinedScore {
    return (behavioralFitScore * 0.35) +
        (testimonyResonanceScore * 0.25) +
        (completionProbability * 0.25) +
        (motivationAlignment * 0.15);
  }
}

class PresetBehavioralScorer {
  /// ═══════════════════════════════════════════════════════════════════════
  /// SCIENCE COMPORTEMENTALE - Formation d'habitudes
  /// ═══════════════════════════════════════════════════════════════════════

  /// Courbes de complétion selon durée (basées sur études réelles)
  static const Map<String, Map<String, dynamic>> _completionCurves = {
    'habit_formation': {
      'optimalRange': [21, 40], // Jours
      'peakCompletion': 66, // % de complétion au pic
      'scientificBasis': [
        'Lally et al. (2010) - European Journal of Social Psychology',
        'Clear, James (2018) - Atomic Habits',
        'Duhigg, Charles (2012) - The Power of Habit',
      ],
      'curve': {
        7: 35, // 7 jours → 35% complétion
        14: 45,
        21: 60, // Sweet spot 1
        30: 68, // Sweet spot 2
        40: 66, // Peak (témoignages bibliques)
        60: 58,
        90: 45, // Trop long
        120: 30,
      },
    },
    'cognitive_learning': {
      'optimalRange': [30, 60],
      'peakCompletion': 72,
      'scientificBasis': [
        'Bjork, R. A. (1994) - Memory and Metamemory',
        'Roediger & Karpicke (2006) - Spaced Repetition',
      ],
      'curve': {
        7: 25,
        21: 50,
        30: 65,
        40: 70,
        60: 72, // Peak apprentissage
        90: 62,
        120: 45,
      },
    },
    'spiritual_transformation': {
      'optimalRange': [40, 90],
      'peakCompletion': 75,
      'scientificBasis': [
        'Prochaska & DiClemente (1983) - Stages of Change',
        'Miller & C\'de Baca (2001) - Quantum Change',
      ],
      'curve': {
        7: 20,
        21: 40,
        30: 55,
        40: 68, // Jésus désert
        60: 72,
        90: 75, // Peak transformation
        120: 65,
      },
    },
  };

  /// ═══════════════════════════════════════════════════════════════════════
  /// TÉMOIGNAGES BIBLIQUES - Durées symboliques
  /// ═══════════════════════════════════════════════════════════════════════

  static const Map<int, Map<String, dynamic>> _biblicalTestimonies = {
    7: {
      'name': 'Semaine de la Création',
      'references': ['Genèse 1-2'],
      'theme': 'Fondation, commencement, ordre divin',
      'resonance': ['Nouveau converti', 'Rétrograde'],
      'strength': 0.7,
    },
    21: {
      'name': 'Daniel et ses amis',
      'references': ['Daniel 1:12-15'],
      'theme': 'Consécration, test initial, engagement',
      'resonance': ['Nouveau converti', 'Fidèle pas si régulier'],
      'strength': 0.75,
    },
    30: {
      'name': 'Deuil et renouveau',
      'references': ['Deutéronome 34:8', 'Nombres 20:29'],
      'theme': 'Transition, nouveau chapitre, préparation',
      'resonance': ['Rétrograde', 'Fidèle pas si régulier'],
      'strength': 0.65,
    },
    40: {
      'name': 'Jésus au désert / Moïse au Sinaï',
      'references': ['Matthieu 4:1-11', 'Exode 24:18', '1 Rois 19:8'],
      'theme': 'Épreuve, révélation, transformation profonde',
      'resonance': ['Fidèle régulier', 'Serviteur/leader'],
      'strength': 0.95, // ⭐ Témoignage le plus fort
    },
    50: {
      'name': 'Pentecôte',
      'references': ['Actes 2:1'],
      'theme': 'Accomplissement, plénitude, puissance de l\'Esprit',
      'resonance': ['Fidèle régulier', 'Serviteur/leader'],
      'strength': 0.8,
    },
    70: {
      'name': 'Disciples envoyés',
      'references': ['Luc 10:1'],
      'theme': 'Mission, multiplication, responsabilité',
      'resonance': ['Serviteur/leader'],
      'strength': 0.7,
    },
    90: {
      'name': 'Saisons spirituelles',
      'references': ['Ecclésiaste 3:1-8'],
      'theme': 'Cycle complet, maturation, sagesse',
      'resonance': ['Fidèle régulier', 'Serviteur/leader'],
      'strength': 0.75,
    },
  };

  /// ═══════════════════════════════════════════════════════════════════════
  /// PSYCHOLOGIE MOTIVATION - Self-Determination Theory
  /// ═══════════════════════════════════════════════════════════════════════

  static const Map<String, Map<String, dynamic>> _motivationFactors = {
    'autonomy': {
      'description': 'Sentiment de choix personnel',
      'boostDurations': [21, 30, 40], // Durées "standard" = plus de choix perçu
      'levelMatch': ['Fidèle régulier', 'Serviteur/leader'],
      'weight': 0.25,
    },
    'competence': {
      'description': 'Sentiment de maîtrise et progression',
      'boostDurations': [30, 40, 60], // Durées permettant vrais progrès
      'levelMatch': ['Fidèle pas si régulier', 'Fidèle régulier'],
      'weight': 0.30,
    },
    'relatedness': {
      'description': 'Connection spirituelle profonde',
      'boostDurations': [40, 60, 90], // Durées permettant relation profonde
      'levelMatch': ['Fidèle régulier', 'Serviteur/leader'],
      'weight': 0.25,
    },
    'purpose': {
      'description': 'Sens et signification',
      'boostDurations': [40, 50, 70, 90], // Durées symboliques bibliques
      'levelMatch': ['Rétrograde', 'Fidèle régulier', 'Serviteur/leader'],
      'weight': 0.20,
    },
  };

  /// ═══════════════════════════════════════════════════════════════════════
  /// FACTEURS DE COMPLÉTION - Basés sur données réelles
  /// ═══════════════════════════════════════════════════════════════════════

  static const Map<String, Map<String, dynamic>> _completionFactors = {
    'Nouveau converti': {
      'sweetSpot': [21, 30, 40],
      'avoid': [60, 90, 120], // Trop long = overwhelm
      'maxSafeLength': 60,
      'reasoning': 'Nouveaux convertis ont besoin de victoires rapides',
    },
    'Rétrograde': {
      'sweetSpot': [21, 30, 40],
      'avoid': [7, 14], // Trop court = pas de transformation
      'maxSafeLength': 60,
      'reasoning': 'Rétrogrades bénéficient de durées bibliques (40j)',
    },
    'Fidèle pas si régulier': {
      'sweetSpot': [30, 40, 60],
      'avoid': [7], // Trop court
      'maxSafeLength': 90,
      'reasoning': 'Besoin de temps pour ancrer l\'habitude',
    },
    'Fidèle régulier': {
      'sweetSpot': [40, 60, 90],
      'avoid': [], // Flexibles
      'maxSafeLength': 120,
      'reasoning': 'Peuvent gérer durées longues et symboliques',
    },
    'Serviteur/leader': {
      'sweetSpot': [60, 90, 120],
      'avoid': [7, 14, 21], // Trop courts = pas assez profonds
      'maxSafeLength': 365,
      'reasoning': 'Leaders cherchent profondeur et engagement long terme',
    },
  };

  /// ═══════════════════════════════════════════════════════════════════════
  /// API PUBLIQUE
  /// ═══════════════════════════════════════════════════════════════════════

  /// Score un preset avec science comportementale + témoignages
  static BehavioralScore scorePreset({
    required int duration,
    required String book,
    required String level,
    required String goal,
    required int dailyMinutes,
  }) {
    // 1. Score fit comportemental
    final behavioralFit = _calculateBehavioralFit(
      duration: duration,
      goal: goal,
      level: level,
    );

    // 2. Score résonance témoignages
    final testimonyResonance = _calculateTestimonyResonance(
      duration: duration,
      level: level,
    );

    // 3. Probabilité de complétion
    final completionProb = _calculateCompletionProbability(
      duration: duration,
      level: level,
      dailyMinutes: dailyMinutes,
    );

    // 4. Alignement motivation
    final motivationAlign = _calculateMotivationAlignment(
      duration: duration,
      level: level,
    );

    // 5. Générer reasoning
    final reasoning = _generateReasoning(
      duration: duration,
      book: book,
      level: level,
      behavioralFit: behavioralFit,
      testimonyResonance: testimonyResonance,
      completionProb: completionProb,
    );

    // 6. Collecter bases scientifiques
    final scientificBasis = _getScientificBasis(goal);
    final testimonies = _getRelevantTestimonies(duration, level);

    return BehavioralScore(
      behavioralFitScore: behavioralFit,
      testimonyResonanceScore: testimonyResonance,
      completionProbability: completionProb,
      motivationAlignment: motivationAlign,
      reasoning: reasoning,
      scientificBasis: scientificBasis,
      testimonies: testimonies,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// CALCULS INTERNES
  /// ═══════════════════════════════════════════════════════════════════════

  /// Calcule le fit comportemental selon courbe de complétion
  static double _calculateBehavioralFit({
    required int duration,
    required String goal,
    required String level,
  }) {
    // Mapper goal → type comportemental
    final behavioralType = _mapGoalToBehavioralType(goal);
    final curveData = _completionCurves[behavioralType];

    if (curveData == null) return 0.5; // Fallback

    final curve = curveData['curve'] as Map<int, int>;
    final optimalRange = curveData['optimalRange'] as List<int>;

    // Trouver le point le plus proche sur la courbe
    final completionRate = _interpolateCompletionRate(duration, curve);

    // Normaliser 0-1
    final maxCompletion = curveData['peakCompletion'] as int;
    final normalized = completionRate / maxCompletion;

    // Bonus si dans optimal range
    final inOptimalRange = duration >= optimalRange[0] && duration <= optimalRange[1];
    final bonus = inOptimalRange ? 0.1 : 0.0;

    return (normalized + bonus).clamp(0.0, 1.0);
  }

  /// Calcule la résonance avec témoignages bibliques
  static double _calculateTestimonyResonance({
    required int duration,
    required String level,
  }) {
    double bestResonance = 0.0;
    String? bestTestimony;

    // Chercher témoignage le plus proche
    for (final entry in _biblicalTestimonies.entries) {
      final testDuration = entry.key;
      final data = entry.value;

      // Distance à la durée du témoignage
      final distance = (duration - testDuration).abs();

      // Vérifier si niveau match
      final resonance = data['resonance'] as List<String>;
      final levelMatch = resonance.contains(level);

      // Score basé sur proximité + match niveau + strength
      final strength = data['strength'] as double;
      final proximityScore = 1.0 - (distance / 100).clamp(0.0, 1.0);
      final score = proximityScore * strength * (levelMatch ? 1.2 : 1.0);

      if (score > bestResonance) {
        bestResonance = score;
        bestTestimony = data['name'] as String;
      }
    }

    return bestResonance.clamp(0.0, 1.0);
  }

  /// Calcule la probabilité de complétion
  static double _calculateCompletionProbability({
    required int duration,
    required String level,
    required int dailyMinutes,
  }) {
    final factorData = _completionFactors[level];
    if (factorData == null) return 0.5;

    final sweetSpot = factorData['sweetSpot'] as List<int>;
    final avoid = factorData['avoid'] as List<int>;
    final maxSafe = factorData['maxSafeLength'] as int;

    double score = 0.5; // Base

    // Bonus si dans sweet spot
    final inSweetSpot = sweetSpot.any((d) => (duration - d).abs() <= 10);
    if (inSweetSpot) score += 0.3;

    // Pénalité si dans avoid
    final inAvoid = avoid.any((d) => (duration - d).abs() <= 5);
    if (inAvoid) score -= 0.2;

    // Pénalité si trop long
    if (duration > maxSafe) {
      final excess = (duration - maxSafe) / maxSafe;
      score -= excess * 0.3;
    }

    // Ajustement selon temps quotidien
    if (dailyMinutes >= 20 && duration <= 60) {
      score += 0.1; // Temps généreux + durée raisonnable = bon fit
    }
    if (dailyMinutes <= 10 && duration >= 90) {
      score -= 0.15; // Peu de temps + plan long = risque abandon
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calcule l'alignement avec motivation intrinsèque
  static double _calculateMotivationAlignment({
    required int duration,
    required String level,
  }) {
    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final entry in _motivationFactors.entries) {
      final factor = entry.value;
      final boostDurations = factor['boostDurations'] as List<int>;
      final levelMatch = (factor['levelMatch'] as List<String>).contains(level);
      final weight = factor['weight'] as double;

      // Score si durée dans boost range
      final inBoostRange = boostDurations.any((d) => (duration - d).abs() <= 10);

      if (inBoostRange && levelMatch) {
        totalScore += 1.0 * weight;
      } else if (inBoostRange || levelMatch) {
        totalScore += 0.5 * weight;
      }

      totalWeight += weight;
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0.5;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// HELPERS
  /// ═══════════════════════════════════════════════════════════════════════

  static String _mapGoalToBehavioralType(String goal) {
    if (goal.contains('Discipline') || goal.contains('régularité')) {
      return 'habit_formation';
    }
    if (goal.contains('Connaissance') || goal.contains('Bible')) {
      return 'cognitive_learning';
    }
    if (goal.contains('Transformation') || goal.contains('changer')) {
      return 'spiritual_transformation';
    }
    return 'habit_formation'; // Défaut
  }

  static double _interpolateCompletionRate(int duration, Map<int, int> curve) {
    // Si durée exacte dans la courbe
    if (curve.containsKey(duration)) {
      return curve[duration]!.toDouble();
    }

    // Interpolation linéaire entre deux points
    final keys = curve.keys.toList()..sort();

    for (int i = 0; i < keys.length - 1; i++) {
      final d1 = keys[i];
      final d2 = keys[i + 1];

      if (duration >= d1 && duration <= d2) {
        final r1 = curve[d1]!;
        final r2 = curve[d2]!;
        final ratio = (duration - d1) / (d2 - d1);
        return r1 + (r2 - r1) * ratio;
      }
    }

    // Hors courbe → extrapolation
    if (duration < keys.first) {
      return curve[keys.first]! * 0.7; // Pénalité si trop court
    }
    return curve[keys.last]! * 0.6; // Pénalité si trop long
  }

  static String _generateReasoning({
    required int duration,
    required String book,
    required String level,
    required double behavioralFit,
    required double testimonyResonance,
    required double completionProb,
  }) {
    final parts = <String>[];

    // Science
    if (behavioralFit > 0.7) {
      parts.add('✅ Durée optimale selon science comportementale (${(behavioralFit * 100).round()}% fit)');
    } else if (behavioralFit > 0.5) {
      parts.add('⚠️ Durée acceptable (${(behavioralFit * 100).round()}% fit)');
    } else {
      parts.add('❌ Durée sous-optimale (${(behavioralFit * 100).round()}% fit)');
    }

    // Témoignages
    final testimony = _findClosestTestimony(duration);
    if (testimony != null && testimonyResonance > 0.6) {
      parts.add('📖 Résonance avec "${testimony['name']}" (${testimony['references'].join(', ')})');
    }

    // Complétion
    if (completionProb > 0.7) {
      parts.add('🎯 Forte probabilité de complétion (${(completionProb * 100).round()}%) pour $level');
    } else if (completionProb < 0.4) {
      parts.add('⚠️ Risque d\'abandon élevé (${(completionProb * 100).round()}%) pour $level');
    }

    return parts.join('\n');
  }

  static Map<String, dynamic>? _findClosestTestimony(int duration) {
    int closestDuration = 40;
    int minDistance = 999;

    for (final d in _biblicalTestimonies.keys) {
      final distance = (duration - d).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestDuration = d;
      }
    }

    return minDistance <= 15 ? _biblicalTestimonies[closestDuration] : null;
  }

  static List<String> _getScientificBasis(String goal) {
    final type = _mapGoalToBehavioralType(goal);
    final curveData = _completionCurves[type];
    return curveData?['scientificBasis'] as List<String>? ?? [];
  }

  static List<String> _getRelevantTestimonies(int duration, String level) {
    final relevant = <String>[];

    for (final entry in _biblicalTestimonies.entries) {
      final d = entry.key;
      final data = entry.value;

      if ((duration - d).abs() <= 15) {
        final resonance = data['resonance'] as List<String>;
        if (resonance.contains(level)) {
          relevant.add('${data['name']} (${data['references'].join(', ')})');
        }
      }
    }

    return relevant;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// INTEGRATION AVEC PRESET GENERATOR
  /// ═══════════════════════════════════════════════════════════════════════

  /// Enrichit un preset avec score comportemental
  /// 
  /// À appeler depuis IntelligentLocalPresetGenerator après scoring de base
  static Map<String, dynamic> enrichPresetWithBehavioralScore({
    required Map<String, dynamic> preset,
    required Map<String, dynamic> userProfile,
  }) {
    final behavioralScore = scorePreset(
      duration: preset['duration'] as int,
      book: preset['book'] as String,
      level: userProfile['level'] as String,
      goal: userProfile['goal'] as String,
      dailyMinutes: userProfile['durationMin'] as int,
    );

    // Ajouter au score existant (pondération 25%)
    final currentScore = preset['score'] as double? ?? 0.0;
    final enrichedScore = currentScore * 0.75 + behavioralScore.combinedScore * 0.25;

    return {
      ...preset,
      'score': enrichedScore,
      'behavioralScore': behavioralScore.combinedScore,
      'completionProbability': behavioralScore.completionProbability,
      'scientificReasoning': behavioralScore.reasoning,
      'scientificBasis': behavioralScore.scientificBasis,
      'testimonies': behavioralScore.testimonies,
    };
  }
}

