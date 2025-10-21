/// ═══════════════════════════════════════════════════════════════════════════
/// PRESET BEHAVIORAL CONFIG - Paramètres calibrables
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Expose les poids et seuils pour calibrage facile sans toucher au code métier.
/// Tous les paramètres sont offline (constants).
/// ═══════════════════════════════════════════════════════════════════════════
library;

class PresetBehavioralConfig {
  /// ═══════════════════════════════════════════════════════════════════════
  /// POIDS DES COMPOSANTES DU SCORE COMPORTEMENTAL
  /// ═══════════════════════════════════════════════════════════════════════

  /// Poids Behavioral Fit (courbes de complétion)
  static const double weightBehavioral = 0.35;

  /// Poids Testimony Resonance (témoignages bibliques)
  static const double weightTestimony = 0.25;

  /// Poids Completion Probability (sweet spots par niveau)
  static const double weightCompletion = 0.25;

  /// Poids Motivation Alignment (SDT factors)
  static const double weightMotivation = 0.15;

  /// Injection dans score final (25% behavioral, 75% base)
  static const double injectInFinalScore = 0.25;

  /// ═══════════════════════════════════════════════════════════════════════
  /// MAPPING ROBUSTE - Objectifs → Types comportementaux
  /// ═══════════════════════════════════════════════════════════════════════

  /// Mapping objectifs utilisateur → types comportementaux
  /// Utilise matching par mots-clés (pas de contains fragile)
  static const Map<String, String> goalsMap = {
    // Formation habitude
    'discipline quotidienne': 'habit_formation',
    'discipline': 'habit_formation',
    'régularité': 'habit_formation',
    'constance': 'habit_formation',
    'routine': 'habit_formation',

    // Apprentissage cognitif
    'approfondir la parole': 'cognitive_learning',
    'connaissance': 'cognitive_learning',
    'connaissance de la bible': 'cognitive_learning',
    'étudier': 'cognitive_learning',
    'comprendre': 'cognitive_learning',
    'apprendre': 'cognitive_learning',

    // Transformation spirituelle
    'être transformé': 'spiritual_transformation',
    'transformation': 'spiritual_transformation',
    'changer': 'spiritual_transformation',
    'grandir': 'spiritual_transformation',
    'maturité': 'spiritual_transformation',
    'sanctification': 'spiritual_transformation',

    // Prière et adoration
    'prier davantage': 'prayer_enhancement',
    'prière': 'prayer_enhancement',
    'communion': 'prayer_enhancement',
    'intimité': 'prayer_enhancement',

    // Guérison émotionnelle
    'guérison': 'emotional_healing',
    'paix': 'emotional_healing',
    'restauration': 'emotional_healing',
    'consolation': 'emotional_healing',

    // Témoignage et mission
    'partager ma foi': 'witness_development',
    'évangélisation': 'witness_development',
    'mission': 'witness_development',
    'témoigner': 'witness_development',
  };

  /// Normalise un objectif utilisateur vers type comportemental
  static String mapGoalToBehavioralType(String goal) {
    final normalized = _normalize(goal);

    // Chercher match exact d'abord
    for (final entry in goalsMap.entries) {
      if (normalized == _normalize(entry.key)) {
        return entry.value;
      }
    }

    // Chercher match partiel
    for (final entry in goalsMap.entries) {
      if (normalized.contains(_normalize(entry.key))) {
        return entry.value;
      }
    }

    // Fallback par défaut
    return 'habit_formation';
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// MAPPING ROBUSTE - Niveaux spirituels
  /// ═══════════════════════════════════════════════════════════════════════

  /// Niveaux canoniques (pour normalisation)
  static const List<String> canonicalLevels = [
    'nouveau converti',
    'rétrograde',
    'fidèle pas si régulier',
    'fidèle régulier',
    'serviteur/leader',
  ];

  /// Mapping synonymes → niveaux canoniques
  static const Map<String, String> levelsMap = {
    'nouveau': 'nouveau converti',
    'débutant': 'nouveau converti',
    'nouveau croyant': 'nouveau converti',
    'nouveau chrétien': 'nouveau converti',

    'rétrograde': 'rétrograde',
    'éloigné': 'rétrograde',
    'revenu': 'rétrograde',
    'retour': 'rétrograde',

    'irrégulier': 'fidèle pas si régulier',
    'pas régulier': 'fidèle pas si régulier',
    'occasionnel': 'fidèle pas si régulier',

    'régulier': 'fidèle régulier',
    'constant': 'fidèle régulier',
    'fidèle': 'fidèle régulier',

    'leader': 'serviteur/leader',
    'serviteur': 'serviteur/leader',
    'responsable': 'serviteur/leader',
    'ministre': 'serviteur/leader',
  };

  /// Normalise un niveau utilisateur vers niveau canonique
  static String mapLevel(String level) {
    final normalized = _normalize(level);

    // Match exact
    for (final entry in levelsMap.entries) {
      if (normalized == _normalize(entry.key)) {
        return entry.value;
      }
    }

    // Match partiel
    for (final entry in levelsMap.entries) {
      if (normalized.contains(_normalize(entry.key))) {
        return entry.value;
      }
    }

    // Fallback par défaut
    return 'fidèle régulier';
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// SEUILS ET CONTRAINTES
  /// ═══════════════════════════════════════════════════════════════════════

  /// Seuil probabilité complétion pour afficher suggestion
  static const double lowCompletionThreshold = 0.45;

  /// Seuil proximité témoignage pour afficher badge
  static const double testimonyRelevanceThreshold = 0.6;

  /// Bonus si plan respecte jours/semaine choisis
  static const double dayPatternBonus = 0.03;

  /// Durées min/max absolues
  static const int minDuration = 7;
  static const int maxDuration = 365;

  /// ═══════════════════════════════════════════════════════════════════════
  /// HELPERS PRIVÉS
  /// ═══════════════════════════════════════════════════════════════════════

  /// Normalise une string (minuscules, trim, sans accents)
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c');
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// TELEMETRY (optionnel, désactivable)
  /// ═══════════════════════════════════════════════════════════════════════

  /// Activer la télémétrie (logs anonymes pour calibrage)
  static const bool enableTelemetry = false; // Mettre à true en prod si souhaité

  /// Log événement comportemental (si activé)
  static void logBehavioralEvent({
    required String event,
    required Map<String, dynamic> data,
  }) {
    if (!enableTelemetry) return;

    // Log local ou envoi anonyme (à implémenter)
    // print('[TELEMETRY] $event: $data');
    
    // Exemple intégration future :
    // AnalyticsService.track(event, data);
  }
}


