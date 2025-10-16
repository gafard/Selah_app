import 'dart:math' as math;


/// Service intelligent pour calculer la durée optimale des plans de lecture
/// basé sur la science comportementale et cognitive
class IntelligentDurationCalculator {
  
  // ============ CONSTANTES CENTRALISÉES ============
  
  /// Bornes de durée pour différents niveaux et contextes
  static const _DurationBounds = (
    minPlanDays: 7,           // Minimum absolu
    newConvertMax: 60,        // Maximum pour nouveaux convertis (protection overwhelm)
    backsliderMax: 90,        // Maximum pour rétrogrades
    maxIf5Min: 120,          // Maximum si ≤5min/jour
    minIf30Min: 21,          // Minimum si ≥30min/jour
    leaderMin: 30,           // Minimum pour leaders
  );
  
  /// Seuils d'intensité basés sur densité quotidienne et charge totale
  static const _IntensityThresholds = (
    lightDensity: 10,        // ≤10min/jour
    lightTotal: 600,         // ≤10h total (600min)
    moderateDensity: 15,     // ≤15min/jour
    moderateTotal: 1200,     // ≤20h total (1200min)
    intensiveDensity: 25,    // ≤25min/jour
    intensiveTotal: 1800,    // ≤30h total (1800min)
  );
  
  /// Multiplicateurs d'ajustement émotionnel
  static const _EmotionalAdjustments = (
    excellentAlignment: 0.9,   // -10% si alignement > 70%
    goodAlignment: 0.97,       // -3% si alignement 40-70%
    poorAlignment: 1.08,       // +8% si alignement < 20%
    overwhelmReduction: 0.9,   // -10% pour éviter overwhelm/burnout
    complacencyBoost: 1.05,    // +5% pour éviter complaisance
    focusMatch: 0.95,          // -5% si focus émotionnel aligné
  );
  
  /// Multiplicateurs d'ajustement témoignages
  static const _TestimonyAdjustments = (
    excellentMatch: 0.9,       // -10% si excellent alignement
    goodMatch: 0.97,           // -3% si bon alignement
    poorMatch: 1.08,           // +8% si faible alignement
  );
  
  /// Multiplicateurs par type de méditation
  static const _MeditationTypeFactors = (
    lectioDivina: 1.05,       // +5% pour Lectio Divina (plus contemplatif)
    contemplation: 1.10,      // +10% pour Contemplation
    priereSilencieuse: 1.0,   // Neutre pour Prière silencieuse
    meditationBiblique: 1.0,  // Neutre pour Méditation biblique (défaut)
  );
  
  // ============ HELPERS DE SÉCURITÉ ============
  
  /// Calcule un ratio de manière sécurisée, évite les divisions par 0
  static double _safeRatio(int numerator, int denominator, {double fallback = 0.0}) {
    return denominator == 0 ? fallback : numerator / denominator;
  }
  
  /// Clamp une valeur entre min et max avec logging optionnel
  static int _safeClamp(int value, int min, int max, {String? context}) {
    final clamped = value.clamp(min, max);
    if (clamped != value && context != null) {
      print('🔧 Clamp appliqué ($context): $value → $clamped');
    }
    return clamped;
  }
  
  // ============ BLENDING INTELLIGENT MIN/AVG/MAX ============
  
  /// Calcule les poids de blending selon le contexte utilisateur
  static ({double minW, double avgW, double maxW}) _calculateTimeBlendWeights({
    required int dailyMinutes, 
    required String level
  }) {
    // Base: centrée sur avg
    double minW = 0.2, avgW = 0.6, maxW = 0.2;

    // Plus de minutes/jour → tirer vers min (plan plus court et plus dense)
    if (dailyMinutes >= 25) { 
      minW += 0.15; 
      avgW -= 0.10; 
      maxW -= 0.05; 
    }
    if (dailyMinutes <= 10) { 
      maxW += 0.15; 
      avgW -= 0.10; 
      minW -= 0.05; 
    }

    // Niveau: nouveaux convertis/rétrogrades → tolérer plus long (maxW ↑)
    if (level == 'Nouveau converti' || level == 'Rétrograde') { 
      maxW += 0.10; 
      avgW -= 0.10; 
    }
    
    // Serviteur/leader → plans plus longs et structurés (minW ↑)
    if (level == 'Serviteur/leader') {
      minW += 0.05;
      maxW -= 0.05;
    }

    // Normalisation pour garantir que la somme = 1
    final sum = minW + avgW + maxW;
    return (
      minW: minW / sum, 
      avgW: avgW / sum, 
      maxW: maxW / sum
    );
  }
  
  /// Calcule un blending intelligent entre min, avg et max selon le contexte
  static int _blendBaseDays(
    Map<String, dynamic> behavioralData, {
    required int dailyMinutes,
    required String level,
  }) {
    final minD = behavioralData['min_days'] as int;
    final avgD = behavioralData['avg_days'] as int;
    final maxD = behavioralData['max_days'] as int;
    
    // Sécurité : éviter les valeurs invalides
    if (minD <= 0 || avgD <= 0 || maxD <= 0 || minD > avgD || avgD > maxD) {
      print('⚠️ Données comportementales invalides, utilisation de avg: $avgD');
      return avgD;
    }
    
    // Calcul des poids contextuels
    final w = _calculateTimeBlendWeights(dailyMinutes: dailyMinutes, level: level);
    
    // Blending pondéré
    final blended = (minD * w.minW + avgD * w.avgW + maxD * w.maxW).round();
    
    // Clamp avec logging
    final result = _safeClamp(blended, minD, maxD, context: 'blending min/avg/max');
    
    print('📊 Blending: min=$minD (${(w.minW*100).round()}%), avg=$avgD (${(w.avgW*100).round()}%), max=$maxD (${(w.maxW*100).round()}%) → $result jours');
    
    return result;
  }
  
  
  /// Facteur de méditation pour ajuster la durée
  static double _meditationTypeFactor(String? meditationType) {
    switch (meditationType) {
      case 'Lectio Divina': return _MeditationTypeFactors.lectioDivina;
      case 'Contemplation': return _MeditationTypeFactors.contemplation;
      case 'Prière silencieuse': return _MeditationTypeFactors.priereSilencieuse;
      case 'Méditation biblique': return _MeditationTypeFactors.meditationBiblique;
      default: return _MeditationTypeFactors.meditationBiblique;
    }
  }
  
  /// Base de connaissances élargie sur les habitudes et le changement comportemental
  static const Map<String, Map<String, dynamic>> _behavioralScience = {
    // Formation d'habitudes (Lally et al., 2009)
    'habit_formation': {
      'min_days': 18,
      'avg_days': 66,
      'max_days': 254,
      'description': 'Formation d\'une nouvelle habitude de lecture',
      'studies': ['Lally et al. (2009) - European Journal of Social Psychology'],
      'emotional_factors': ['motivation', 'consistency', 'identity_formation']
    },
    
    // Consolidation de l'habitude (Gardner et al., 2012)
    'habit_consolidation': {
      'min_days': 21,
      'avg_days': 40,
      'max_days': 84,
      'description': 'Consolidation et automatisation de l\'habitude',
      'studies': ['Gardner et al. (2012) - Health Psychology Review'],
      'emotional_factors': ['reinforcement', 'automation', 'comfort_zone']
    },
    
    // Changement de caractère profond (Prochaska & DiClemente, 1983)
    'character_change': {
      'min_days': 90,
      'avg_days': 180,
      'max_days': 365,
      'description': 'Transformation profonde du caractère et des valeurs',
      'studies': ['Prochaska & DiClemente (1983) - Transtheoretical Model'],
      'emotional_factors': ['identity_shift', 'values_alignment', 'behavioral_change']
    },
    
    // Apprentissage cognitif (Ericsson et al., 1993)
    'cognitive_learning': {
      'min_days': 30,
      'avg_days': 60,
      'max_days': 120,
      'description': 'Acquisition de connaissances et compétences cognitives',
      'studies': ['Ericsson et al. (1993) - Psychological Review'],
      'emotional_factors': ['curiosity', 'mastery', 'confidence_building']
    },
    
    // Développement spirituel (Worthington et al., 2003)
    'spiritual_development': {
      'min_days': 21,
      'avg_days': 90,
      'max_days': 180,
      'description': 'Croissance et maturité spirituelle',
      'studies': ['Worthington et al. (2003) - Journal of Psychology and Theology'],
      'emotional_factors': ['spiritual_awakening', 'faith_deepening', 'purpose_discovery']
    },
    
    // Guérison émotionnelle et spirituelle (Pargament et al., 2005)
    'emotional_healing': {
      'min_days': 45,
      'avg_days': 120,
      'max_days': 240,
      'description': 'Guérison émotionnelle et spirituelle',
      'studies': ['Pargament et al. (2005) - Journal of Clinical Psychology'],
      'emotional_factors': ['trauma_processing', 'forgiveness', 'emotional_regulation']
    },
    
    // Développement du témoignage (Hunsberger & Jackson, 2005)
    'witness_development': {
      'min_days': 35,
      'avg_days': 75,
      'max_days': 150,
      'description': 'Développement des compétences de témoignage',
      'studies': ['Hunsberger & Jackson (2005) - Journal for the Scientific Study of Religion'],
      'emotional_factors': ['confidence_building', 'communication_skills', 'boldness']
    },
    
    // Amélioration de la prière (Laird et al., 2007)
    'prayer_enhancement': {
      'min_days': 28,
      'avg_days': 56,
      'max_days': 112,
      'description': 'Amélioration de la qualité et profondeur de la prière',
      'studies': ['Laird et al. (2007) - Psychology of Religion and Spirituality'],
      'emotional_factors': ['intimacy_with_god', 'prayer_confidence', 'spiritual_connection']
    },
    
    // Encouragement et espoir (Snyder et al., 1991)
    'hope_encouragement': {
      'min_days': 14,
      'avg_days': 42,
      'max_days': 84,
      'description': 'Développement de l\'espoir et de l\'encouragement',
      'studies': ['Snyder et al. (1991) - Journal of Personality and Social Psychology'],
      'emotional_factors': ['hope_restoration', 'optimism', 'emotional_support']
    },
    
    // Témoignages de conversion (James, 1902)
    'conversion_testimony': {
      'min_days': 21,
      'avg_days': 60,
      'max_days': 120,
      'description': 'Renforcement de la foi par les témoignages de conversion',
      'studies': ['James, W. (1902) - The Varieties of Religious Experience'],
      'emotional_factors': ['faith_strengthening', 'testimony_impact', 'spiritual_awakening']
    },
    
    // Miracles et interventions divines (Brown, 1998)
    'divine_intervention': {
      'min_days': 30,
      'avg_days': 90,
      'max_days': 180,
      'description': 'Reconnaissance et célébration des miracles divins',
      'studies': ['Brown, C. (1998) - Miracles and the Modern Mind'],
      'emotional_factors': ['awe', 'gratitude', 'faith_deepening', 'divine_connection']
    },
    
    // Restauration spirituelle (Hughes, 2001)
    'spiritual_restoration': {
      'min_days': 45,
      'avg_days': 120,
      'max_days': 240,
      'description': 'Processus de restauration spirituelle complète',
      'studies': ['Hughes, R.K. (2001) - Disciplines of a Godly Man'],
      'emotional_factors': ['healing', 'restoration', 'renewal', 'second_chances']
    },
    
    // Transformation de vie (Willard, 2002)
    'life_transformation': {
      'min_days': 60,
      'avg_days': 150,
      'max_days': 300,
      'description': 'Transformation complète de la vie par la foi',
      'studies': ['Willard, D. (2002) - Renovation of the Heart'],
      'emotional_factors': ['identity_transformation', 'purpose_discovery', 'complete_change']
    },
    
    // Victoires spirituelles (Spurgeon, 1856)
    'spiritual_victory': {
      'min_days': 28,
      'avg_days': 70,
      'max_days': 140,
      'description': 'Célébration et renforcement des victoires spirituelles',
      'studies': ['Spurgeon, C.H. (1856) - Lectures to My Students'],
      'emotional_factors': ['victory_celebration', 'strength_building', 'overcoming']
    },
    
    // Réveil spirituel (Edwards, 1734)
    'spiritual_awakening': {
      'min_days': 40,
      'avg_days': 100,
      'max_days': 200,
      'description': 'Expérience de réveil et de renaissance spirituelle',
      'studies': ['Edwards, J. (1734) - A Faithful Narrative of the Surprising Work of God'],
      'emotional_factors': ['awakening', 'revival', 'fresh_start', 'spiritual_fire']
    },
    
    // Guérison divine (Kuhlman, 1962)
    'divine_healing': {
      'min_days': 35,
      'avg_days': 90,
      'max_days': 180,
      'description': 'Expérience et témoignage de guérison divine',
      'studies': ['Kuhlman, K. (1962) - I Believe in Miracles'],
      'emotional_factors': ['healing_testimony', 'faith_healing', 'divine_power']
    },
    
    // Délivrance spirituelle (Wagner, 1991)
    'spiritual_deliverance': {
      'min_days': 50,
      'avg_days': 120,
      'max_days': 240,
      'description': 'Processus de délivrance et de libération spirituelle',
      'studies': ['Wagner, C.P. (1991) - Confronting the Powers'],
      'emotional_factors': ['deliverance', 'freedom', 'spiritual_warfare', 'victory']
    }
  };
  
  /// Objectifs et leurs durées recommandées avec base scientifique élargie
  static const Map<String, Map<String, dynamic>> _goalDurations = {
    'Discipline quotidienne': {
      'type': 'habit_formation',
      'base_multiplier': 1.0,
      'description': 'Établir une routine quotidienne de lecture biblique',
      'emotional_focus': 'motivation, consistency, identity_formation'
    },
    'Discipline de prière': {
      'type': 'prayer_enhancement',
      'base_multiplier': 1.2,
      'description': 'Développer une vie de prière régulière et profonde',
      'emotional_focus': 'intimacy_with_god, prayer_confidence, spiritual_connection'
    },
    'Approfondir la Parole': {
      'type': 'cognitive_learning',
      'base_multiplier': 1.5,
      'description': 'Acquérir une compréhension approfondie des Écritures',
      'emotional_focus': 'curiosity, mastery, confidence_building'
    },
    'Grandir dans la foi': {
      'type': 'spiritual_development',
      'base_multiplier': 1.3,
      'description': 'Renforcer et approfondir la foi personnelle',
      'emotional_focus': 'spiritual_awakening, faith_deepening, purpose_discovery'
    },
    'Développer mon caractère': {
      'type': 'character_change',
      'base_multiplier': 2.0,
      'description': 'Transformer le caractère selon les valeurs bibliques',
      'emotional_focus': 'identity_shift, values_alignment, behavioral_change'
    },
    'Trouver de l\'encouragement': {
      'type': 'hope_encouragement',
      'base_multiplier': 0.8,
      'description': 'Recevoir encouragement et espoir quotidien',
      'emotional_focus': 'hope_restoration, optimism, emotional_support'
    },
    'Expérimenter la guérison': {
      'type': 'emotional_healing',
      'base_multiplier': 1.4,
      'description': 'Expérimenter la guérison émotionnelle et spirituelle',
      'emotional_focus': 'trauma_processing, forgiveness, emotional_regulation'
    },
    'Partager ma foi': {
      'type': 'witness_development',
      'base_multiplier': 1.1,
      'description': 'Préparer à témoigner et partager sa foi',
      'emotional_focus': 'confidence_building, communication_skills, boldness'
    },
    'Mieux prier': {
      'type': 'prayer_enhancement',
      'base_multiplier': 1.0,
      'description': 'Améliorer la qualité et la profondeur de la prière',
      'emotional_focus': 'intimacy_with_god, prayer_confidence, spiritual_connection'
    },
    
    // Nouveaux objectifs basés sur les témoignages chrétiens
    'Renforcer ma foi': {
      'type': 'conversion_testimony',
      'base_multiplier': 1.2,
      'description': 'Renforcer la foi par les témoignages de conversion et de miracles',
      'emotional_focus': 'faith_strengthening, testimony_impact, spiritual_awakening'
    },
    
    'Vivre un miracle': {
      'type': 'divine_intervention',
      'base_multiplier': 1.4,
      'description': 'Rechercher et reconnaître les interventions divines dans ma vie',
      'emotional_focus': 'awe, gratitude, faith_deepening, divine_connection'
    },
    
    'Expérimenter la restauration': {
      'type': 'spiritual_restoration',
      'base_multiplier': 1.6,
      'description': 'Expérimenter une restauration spirituelle complète',
      'emotional_focus': 'healing, restoration, renewal, second_chances'
    },
    
    'Transformer ma vie': {
      'type': 'life_transformation',
      'base_multiplier': 1.8,
      'description': 'Vivre une transformation complète de vie par la foi',
      'emotional_focus': 'identity_transformation, purpose_discovery, complete_change'
    },
    
    'Remporter des victoires': {
      'type': 'spiritual_victory',
      'base_multiplier': 1.3,
      'description': 'Célébrer et renforcer les victoires spirituelles',
      'emotional_focus': 'victory_celebration, strength_building, overcoming'
    },
    
    'Vivre un réveil': {
      'type': 'spiritual_awakening',
      'base_multiplier': 1.5,
      'description': 'Expérimenter un réveil et une renaissance spirituelle',
      'emotional_focus': 'awakening, revival, fresh_start, spiritual_fire'
    },
    
    'Recevoir la guérison': {
      'type': 'divine_healing',
      'base_multiplier': 1.4,
      'description': 'Rechercher et témoigner de la guérison divine',
      'emotional_focus': 'healing_testimony, faith_healing, divine_power'
    },
    
    'Expérimenter la délivrance': {
      'type': 'spiritual_deliverance',
      'base_multiplier': 1.7,
      'description': 'Vivre un processus de délivrance et de libération spirituelle',
      'emotional_focus': 'deliverance, freedom, spiritual_warfare, victory'
    }
  };
  
  /// Niveaux spirituels et leurs facteurs d'ajustement avec états émotionnels
  static const Map<String, Map<String, dynamic>> _levelAdjustments = {
    'Nouveau converti': {
      'duration_factor': 0.7, // Plans plus courts pour éviter l'overwhelm
      'intensity_factor': 0.8, // Intensité réduite
      'description': 'Débutant - Plans courts et progressifs',
      'emotional_state': ['joy', 'anticipation', 'foundation', 'curiosity', 'first_love'],
      'emotional_needs': ['gentle_guidance', 'basic_understanding', 'encouragement', 'testimony_strength'],
      'risk_factors': ['overwhelm', 'confusion', 'discouragement'],
      'spiritual_testimonies': ['conversion_stories', 'first_miracles', 'early_faith']
    },
    'Rétrograde': {
      'duration_factor': 0.9, // Plans légèrement plus courts
      'intensity_factor': 0.9, // Réintroduction progressive
      'description': 'Retour - Plans de réintégration douce',
      'emotional_state': ['repentance', 'hope', 'restoration', 'vulnerability', 'second_chance'],
      'emotional_needs': ['gentle_restoration', 'forgiveness_assurance', 'hope_building', 'redemption_stories'],
      'risk_factors': ['guilt', 'self_doubt', 'isolation'],
      'spiritual_testimonies': ['prodigal_son', 'restoration_stories', 'forgiveness_miracles']
    },
    'Fidèle pas si régulier': {
      'duration_factor': 1.0, // Durée standard
      'intensity_factor': 1.0, // Intensité standard
      'description': 'Irregular - Plans pour retrouver la régularité',
      'emotional_state': ['encouragement', 'peace', 'renewal', 'motivation', 'fresh_start'],
      'emotional_needs': ['consistency_building', 'routine_establishment', 'motivation', 'faith_reminders'],
      'risk_factors': ['inconsistency', 'discouragement', 'perfectionism'],
      'spiritual_testimonies': ['perseverance_stories', 'faithfulness_rewards', 'consistency_victories']
    },
    'Fidèle régulier': {
      'duration_factor': 1.2, // Plans plus longs
      'intensity_factor': 1.1, // Intensité légèrement plus élevée
      'description': 'Régulier - Plans d\'approfondissement',
      'emotional_state': ['stability', 'growth_desire', 'commitment', 'satisfaction', 'maturity'],
      'emotional_needs': ['deeper_understanding', 'challenge', 'spiritual_growth', 'advanced_testimonies'],
      'risk_factors': ['complacency', 'routine_boredom', 'plateau'],
      'spiritual_testimonies': ['deep_faith', 'mature_miracles', 'leadership_calling']
    },
    'Serviteur/leader': {
      'duration_factor': 1.5, // Plans les plus longs
      'intensity_factor': 1.3, // Intensité élevée pour leadership
      'description': 'Leader - Plans de formation et de leadership',
      'emotional_state': ['responsibility', 'wisdom', 'vision', 'burden_carrying', 'anointing'],
      'emotional_needs': ['leadership_development', 'wisdom_seeking', 'others_serving', 'powerful_testimonies'],
      'risk_factors': ['burnout', 'pride', 'isolation', 'perfectionism'],
      'spiritual_testimonies': ['leadership_miracles', 'revival_stories', 'spiritual_authority']
    }
  };
  
  /// Calcule la durée optimale d'un plan basée sur les paramètres utilisateur et états émotionnels
  static DurationCalculation calculateOptimalDuration({
    required String goal,
    required String level,
    required int dailyMinutes,
    String? meditationType,
  }) {
    // 1. Récupérer les données de base pour l'objectif
    final goalData = _goalDurations[goal] ?? _goalDurations['Discipline quotidienne']!;
    final behavioralType = goalData['type'] as String;
    final baseMultiplier = goalData['base_multiplier'] as double;
    final emotionalFocus = goalData['emotional_focus'] as String;
    
    // 2. Récupérer les données comportementales avec blending intelligent
    final behavioralData = _behavioralScience[behavioralType]!;
    final baseDays = _blendBaseDays(
      behavioralData,
      dailyMinutes: dailyMinutes,
      level: level,
    );
    
    // 3. Appliquer les ajustements du niveau avec états émotionnels
    final levelData = _levelAdjustments[level] ?? _levelAdjustments['Fidèle régulier']!;
    final levelFactor = levelData['duration_factor'] as double;
    final emotionalState = levelData['emotional_state'] as List<String>;
    final emotionalNeeds = levelData['emotional_needs'] as List<String>;
    final riskFactors = levelData['risk_factors'] as List<String>;
    final spiritualTestimonies = levelData['spiritual_testimonies'] as List<String>;
    
    // 4. Calculer la durée de base
    var calculatedDays = (baseDays * baseMultiplier * levelFactor).round();
    
    // 5. Ajuster selon le temps quotidien disponible
    final timeAdjustment = _calculateTimeAdjustment(dailyMinutes);
    calculatedDays = (calculatedDays * timeAdjustment).round();
    
    // 6. Ajuster selon l'alignement émotionnel
    final emotionalAdjustment = _calculateEmotionalAdjustment(
      emotionalFocus, emotionalState, emotionalNeeds, riskFactors
    );
    calculatedDays = (calculatedDays * emotionalAdjustment).round();
    
    // 7. Ajuster selon les témoignages spirituels pertinents
    final testimonyAdjustment = _calculateTestimonyAdjustment(
      behavioralType, spiritualTestimonies, emotionalState
    );
    calculatedDays = (calculatedDays * testimonyAdjustment).round();
    
    // 8. Ajuster selon le type de méditation
    final meditationFactor = _meditationTypeFactor(meditationType);
    calculatedDays = (calculatedDays * meditationFactor).round();
    
    // 9. Appliquer les contraintes de bon sens
    calculatedDays = _applyConstraints(calculatedDays, level, dailyMinutes);
    
    // 10. Calculer l'intensité recommandée
    final intensity = _calculateIntensity(level, dailyMinutes, calculatedDays);
    
    // 🧠 Calculer les bornes et la confiance
    final bounds = _calculateBounds(level, dailyMinutes, goal);
    final confidence = _calculateConfidence(level, dailyMinutes, calculatedDays, goal);
    final warnings = _generateWarnings(level, dailyMinutes, calculatedDays, goal);
    
    return DurationCalculation(
      optimalDays: calculatedDays,
      dailyMinutes: dailyMinutes,
      totalHours: (calculatedDays * dailyMinutes) / 60,
      intensity: intensity,
      behavioralType: behavioralType,
      scientificBasis: behavioralData['studies'] as List<String>,
      reasoning: _generateEnhancedReasoning(goal, level, dailyMinutes, calculatedDays, behavioralType, emotionalState, emotionalNeeds),
      minDays: bounds['min']!,
      maxDays: bounds['max']!,
      confidence: confidence,
      warnings: warnings,
    );
  }
  
  /// Calcule l'ajustement basé sur le temps quotidien
  static double _calculateTimeAdjustment(int dailyMinutes) {
    // Plus de temps quotidien = plan plus court (plus d'intensité)
    // Moins de temps quotidien = plan plus long (moins d'intensité)
    
    if (dailyMinutes <= 5) return 1.5; // Très peu de temps = plan très long
    if (dailyMinutes <= 10) return 1.3; // Peu de temps = plan long
    if (dailyMinutes <= 15) return 1.0; // Temps standard = plan standard
    if (dailyMinutes <= 20) return 0.9; // Plus de temps = plan plus court
    if (dailyMinutes <= 30) return 0.8; // Beaucoup de temps = plan court
    return 0.7; // Très beaucoup de temps = plan très court
  }
  
  /// Applique les contraintes de bon sens avec ordre clair et logging
  static int _applyConstraints(int days, String level, int dailyMinutes) {
    final originalDays = days;
    
    // 1. Bornes globales absolues
    days = _safeClamp(days, _DurationBounds.minPlanDays, 365, context: 'borne globale');
    
    // 2. Contraintes par niveau spirituel
    if (level == 'Nouveau converti') {
      days = _safeClamp(days, _DurationBounds.minPlanDays, _DurationBounds.newConvertMax, 
          context: 'nouveau converti (protection overwhelm)');
    } else if (level == 'Rétrograde') {
      days = _safeClamp(days, _DurationBounds.minPlanDays, _DurationBounds.backsliderMax, 
          context: 'rétrograde (éviter lassitude)');
    } else if (level == 'Serviteur/leader') {
      days = _safeClamp(days, _DurationBounds.leaderMin, 365, 
          context: 'serviteur/leader (minimum exigé)');
    }
    
    // 3. Contraintes par temps quotidien
    if (dailyMinutes <= 5) {
      days = _safeClamp(days, _DurationBounds.minPlanDays, _DurationBounds.maxIf5Min, 
          context: '≤5min/jour (limitation durée)');
    } else if (dailyMinutes >= 30) {
      days = _safeClamp(days, _DurationBounds.minIf30Min, 365, 
          context: '≥30min/jour (minimum requis)');
    }
    
    // Logging final si contraintes appliquées
    if (days != originalDays) {
      print('🔧 Contraintes appliquées: $originalDays → $days jours ($level, ${dailyMinutes}min/j)');
    }
    
    return days;
  }
  
  /// Calcule l'intensité recommandée
  static IntensityLevel _calculateIntensity(String level, int dailyMinutes, int totalDays) {
    final totalMinutes = dailyMinutes * totalDays;
    final density = dailyMinutes; // effort quotidien
    
    // Heuristique: d'abord densité, puis total
    if (density <= _IntensityThresholds.lightDensity && totalMinutes <= _IntensityThresholds.lightTotal) {
      return IntensityLevel.light;        // ≤10min/j, ≤10h total
    }
    if (density <= _IntensityThresholds.moderateDensity && totalMinutes <= _IntensityThresholds.moderateTotal) {
      return IntensityLevel.moderate;     // ≤15min/j, ≤20h total
    }
    if (density <= _IntensityThresholds.intensiveDensity && totalMinutes <= _IntensityThresholds.intensiveTotal) {
      return IntensityLevel.intensive;    // ≤25min/j, ≤30h total
    }
    return IntensityLevel.challenging;    // >25min/j ou >30h total
  }
  
  /// Calcule l'ajustement émotionnel basé sur l'alignement objectif-niveau (sécurisé)
  static double _calculateEmotionalAdjustment(
    String emotionalFocus,
    List<String> emotionalState,
    List<String> emotionalNeeds,
    List<String> riskFactors,
  ) {
    double alignment = 1.0;
    
    // Pas de besoins émotionnels → neutre
    if (emotionalNeeds.isEmpty) return alignment;
    
    // Calculer l'alignement de manière sécurisée
    final matched = emotionalNeeds.where((need) => 
      emotionalState.any((state) => _isEmotionallyCompatible(need, state))
    ).length;
    
    final needsAlignment = _safeRatio(matched, emotionalNeeds.length, fallback: 0.0);
    
    // Ajustements basés sur l'alignement
    if (needsAlignment > 0.7) {
      alignment *= _EmotionalAdjustments.excellentAlignment;
    } else if (needsAlignment > 0.4) {
      alignment *= _EmotionalAdjustments.goodAlignment;
    } else if (needsAlignment < 0.2) {
      alignment *= _EmotionalAdjustments.poorAlignment;
    }
    
    // Ajustements par facteurs de risque
    final riskSet = Set.of(riskFactors);
    if (riskSet.contains('overwhelm') || riskSet.contains('burnout')) {
      alignment *= _EmotionalAdjustments.overwhelmReduction;
    }
    
    if (riskSet.contains('complacency') || riskSet.contains('plateau')) {
      alignment *= _EmotionalAdjustments.complacencyBoost;
    }
    
    // Amélioration : utiliser emotionalFocus (du goal) de manière plus intelligente
    final focusElements = emotionalFocus.split(',').map((f) => f.trim()).toList();
    
    // 1. Vérifier si le focus est présent dans l'état émotionnel actuel
    final focusInState = focusElements.where((f) => emotionalState.contains(f)).length;
    final focusAlignment = _safeRatio(focusInState, focusElements.length, fallback: 0.0);
    
    // 2. Bonus si focus bien aligné (meilleure efficacité du plan)
    if (focusAlignment > 0.5) {
      alignment *= _EmotionalAdjustments.focusMatch; // -5% (plan plus efficace)
      print('🎯 Focus émotionnel aligné à ${(focusAlignment*100).round()}% → réduction durée');
    }
    
    // 3. Vérifier si le focus correspond aux besoins (double check de pertinence)
    final focusMatchesNeeds = focusElements.any((f) => 
      emotionalNeeds.any((need) => need.contains(f) || f.contains(need.split('_').first))
    );
    
    if (focusMatchesNeeds) {
      alignment *= 0.98; // -2% supplémentaire si le focus répond aux besoins
      print('💡 Focus répond aux besoins émotionnels → optimisation');
    }
    
    return alignment.clamp(0.75, 1.3);
  }
  
  /// Vérifie la compatibilité émotionnelle entre besoin et état
  static bool _isEmotionallyCompatible(String need, String state) {
    final compatibilityMap = {
      'gentle_guidance': ['curiosity', 'foundation'],
      'basic_understanding': ['anticipation', 'curiosity'],
      'encouragement': ['joy', 'hope'],
      'gentle_restoration': ['repentance', 'hope'],
      'forgiveness_assurance': ['repentance', 'restoration'],
      'hope_building': ['hope', 'restoration'],
      'consistency_building': ['motivation', 'encouragement'],
      'routine_establishment': ['peace', 'renewal'],
      'deeper_understanding': ['growth_desire', 'commitment'],
      'challenge': ['growth_desire', 'satisfaction'],
      'spiritual_growth': ['stability', 'growth_desire'],
      'leadership_development': ['responsibility', 'vision'],
      'wisdom_seeking': ['wisdom', 'responsibility'],
      'others_serving': ['burden_carrying', 'vision'],
      'testimony_strength': ['first_love', 'joy', 'anticipation'],
      'redemption_stories': ['second_chance', 'repentance', 'hope'],
      'faith_reminders': ['fresh_start', 'motivation', 'renewal'],
      'advanced_testimonies': ['maturity', 'growth_desire', 'commitment'],
      'powerful_testimonies': ['anointing', 'responsibility', 'vision'],
    };
    
    return compatibilityMap[need]?.contains(state) ?? false;
  }
  
  /// Calcule l'ajustement basé sur les témoignages spirituels pertinents (sécurisé)
  static double _calculateTestimonyAdjustment(
    String behavioralType,
    List<String> spiritualTestimonies,
    List<String> emotionalState,
  ) {
    double adjustment = 1.0;
    
    // Mapping des types comportementaux aux témoignages pertinents
    final testimonyMap = {
      'conversion_testimony': ['conversion_stories', 'first_miracles', 'early_faith'],
      'divine_intervention': ['first_miracles', 'mature_miracles', 'leadership_miracles'],
      'spiritual_restoration': ['prodigal_son', 'restoration_stories', 'forgiveness_miracles'],
      'life_transformation': ['deep_faith', 'mature_miracles', 'leadership_calling'],
      'spiritual_victory': ['consistency_victories', 'faithfulness_rewards', 'victory_celebration'],
      'spiritual_awakening': ['revival_stories', 'fresh_start', 'spiritual_fire'],
      'divine_healing': ['healing_testimony', 'faith_healing', 'divine_power'],
      'spiritual_deliverance': ['spiritual_authority', 'deliverance', 'freedom'],
      'habit_formation': ['consistency_victories', 'faithfulness_rewards'],
      'habit_consolidation': ['perseverance_stories', 'faithfulness_rewards'],
      'character_change': ['deep_faith', 'mature_miracles', 'transformation'],
      'cognitive_learning': ['leadership_calling', 'wisdom_seeking'],
      'spiritual_development': ['spiritual_authority', 'leadership_calling'],
      'emotional_healing': ['healing_testimony', 'restoration_stories'],
      'witness_development': ['leadership_miracles', 'revival_stories'],
      'prayer_enhancement': ['spiritual_authority', 'divine_power'],
      'hope_encouragement': ['early_faith', 'first_miracles', 'faithfulness_rewards'],
    };
    
    final relevantTestimonies = testimonyMap[behavioralType] ?? [];
    
    // Calculer l'alignement de manière sécurisée
    final hitsDirect = spiritualTestimonies.where(relevantTestimonies.contains).length;
    final hitsEmo = spiritualTestimonies.where((t) => _isTestimonyEmotionallyRelevant(t, emotionalState)).length;
    
    final denom = spiritualTestimonies.length + math.max(1, relevantTestimonies.length).toInt(); // jamais 0
    final alignment = _safeRatio(hitsDirect + hitsEmo, denom, fallback: 0.0);
    
    // Ajustements basés sur l'alignement
    if (alignment > 0.7) {
      adjustment *= _TestimonyAdjustments.excellentMatch;
    } else if (alignment > 0.4) {
      adjustment *= _TestimonyAdjustments.goodMatch;
    } else if (alignment < 0.2) {
      adjustment *= _TestimonyAdjustments.poorMatch;
    }
    
    return adjustment.clamp(0.85, 1.15);
  }
  
  /// Vérifie si un témoignage est émotionnellement pertinent
  static bool _isTestimonyEmotionallyRelevant(String testimony, List<String> emotionalState) {
    final relevanceMap = {
      'conversion_stories': ['joy', 'anticipation', 'first_love'],
      'first_miracles': ['awe', 'gratitude', 'faith_deepening'],
      'early_faith': ['curiosity', 'foundation', 'first_love'],
      'prodigal_son': ['repentance', 'hope', 'second_chance'],
      'restoration_stories': ['healing', 'restoration', 'renewal'],
      'forgiveness_miracles': ['repentance', 'restoration', 'second_chance'],
      'perseverance_stories': ['motivation', 'encouragement', 'fresh_start'],
      'faithfulness_rewards': ['commitment', 'satisfaction', 'maturity'],
      'consistency_victories': ['peace', 'renewal', 'stability'],
      'deep_faith': ['growth_desire', 'commitment', 'maturity'],
      'mature_miracles': ['stability', 'satisfaction', 'maturity'],
      'leadership_calling': ['responsibility', 'vision', 'anointing'],
      'leadership_miracles': ['responsibility', 'wisdom', 'anointing'],
      'revival_stories': ['awakening', 'revival', 'spiritual_fire'],
      'spiritual_authority': ['wisdom', 'vision', 'anointing'],
    };
    
    final relevantEmotions = relevanceMap[testimony] ?? [];
    return emotionalState.any((emotion) => relevantEmotions.contains(emotion));
  }
  
  /// Génère une explication enrichie du calcul
  static String _generateEnhancedReasoning(
    String goal, 
    String level, 
    int dailyMinutes, 
    int days, 
    String behavioralType,
    List<String> emotionalState,
    List<String> emotionalNeeds,
  ) {
    final goalDesc = _goalDurations[goal]?['description'] ?? 'Objectif spirituel';
    final levelDesc = _levelAdjustments[level]?['description'] ?? 'Niveau spirituel';
    final emotionalStateStr = emotionalState.take(3).join(', ');
    final emotionalNeedsStr = emotionalNeeds.take(2).join(', ');
    final spiritualTestimonies = _levelAdjustments[level]?['spiritual_testimonies'] as List<String>? ?? [];
    final testimoniesStr = spiritualTestimonies.take(2).join(', ');
    
    return '''Basé sur la science comportementale et les témoignages chrétiens ($behavioralType):
    • $goalDesc
    • $levelDesc (État: $emotionalStateStr)
    • Besoins émotionnels: $emotionalNeedsStr
    • Témoignages pertinents: $testimoniesStr
    • $dailyMinutes min/jour = ${(days * dailyMinutes / 60).toStringAsFixed(1)}h total
    • Durée optimale: $days jours pour une transformation durable, émotionnellement adaptée et ancrée dans les témoignages de foi''';
  }
  
  /// 🧠 Calcule les bornes min/max pour le slider
  static Map<String, int> _calculateBounds(String level, int dailyMinutes, String goal) {
    int minDays = _DurationBounds.minPlanDays;
    int maxDays = 365; // Maximum absolu
    
    // Ajustements selon le niveau
    switch (level) {
      case 'Nouveau converti':
        maxDays = _DurationBounds.newConvertMax;
        minDays = math.max(minDays, 14); // Minimum 2 semaines
        break;
      case 'Rétrograde':
        maxDays = _DurationBounds.backsliderMax;
        minDays = math.max(minDays, 21); // Minimum 3 semaines
        break;
      case 'Serviteur/leader':
        minDays = _DurationBounds.leaderMin;
        maxDays = 180; // Maximum 6 mois
        break;
      default:
        maxDays = 120; // Maximum 4 mois pour fidèles réguliers
    }
    
    // Ajustements selon le temps quotidien
    if (dailyMinutes <= 5) {
      maxDays = _DurationBounds.maxIf5Min;
    } else if (dailyMinutes >= 30) {
      minDays = _DurationBounds.minIf30Min;
    }
    
    // Ajustements selon l'objectif
    if (goal.contains('Discipline') || goal.contains('quotidienne')) {
      minDays = math.max(minDays, 21); // Minimum 3 semaines pour la discipline
    } else if (goal.contains('Approfondir') || goal.contains('Parole')) {
      minDays = math.max(minDays, 30); // Minimum 1 mois pour approfondir
    }
    
    return {'min': minDays, 'max': maxDays};
  }
  
  /// 🧠 Calcule le niveau de confiance du calcul
  static double _calculateConfidence(String level, int dailyMinutes, int days, String goal) {
    double confidence = 0.7; // Base de 70%
    
    // Bonus pour données cohérentes
    if (level == 'Fidèle régulier' && dailyMinutes >= 15 && dailyMinutes <= 25) {
      confidence += 0.15; // +15% pour profil standard
    }
    
    if (days >= 21 && days <= 90) {
      confidence += 0.1; // +10% pour durée dans la zone optimale
    }
    
    // Bonus pour objectifs clairs
    if (goal.contains('Discipline') || goal.contains('Approfondir')) {
      confidence += 0.05; // +5% pour objectifs précis
    }
    
    // Malus pour profils extrêmes
    if (level == 'Nouveau converti' && days > 60) {
      confidence -= 0.1; // -10% pour risque d'overwhelm
    }
    
    if (dailyMinutes < 5 || dailyMinutes > 45) {
      confidence -= 0.05; // -5% pour temps extrêmes
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// 🧠 Génère les avertissements si nécessaire
  static List<String> _generateWarnings(String level, int dailyMinutes, int days, String goal) {
    List<String> warnings = [];
    
    // Avertissement overwhelm
    if (level == 'Nouveau converti' && days > 45) {
      warnings.add('⚠️ Durée élevée pour un nouveau converti - risque d\'overwhelm spirituel');
    }
    
    // Avertissement temps insuffisant
    if (dailyMinutes < 5) {
      warnings.add('⚠️ Temps quotidien très court - transformation limitée possible');
    }
    
    // Avertissement temps excessif
    if (dailyMinutes > 45) {
      warnings.add('⚠️ Temps quotidien élevé - risque de fatigue spirituelle');
    }
    
    // Avertissement durée courte
    if (days < 14) {
      warnings.add('⚠️ Durée très courte - habitudes peu durables');
    }
    
    // Avertissement durée longue
    if (days > 120 && level != 'Serviteur/leader') {
      warnings.add('⚠️ Durée très longue - risque d\'abandon en cours de route');
    }
    
    return warnings;
  }
}

/// Résultat du calcul de durée optimale
class DurationCalculation {
  final int optimalDays;
  final int dailyMinutes;
  final double totalHours;
  final IntensityLevel intensity;
  final String behavioralType;
  final List<String> scientificBasis;
  final String reasoning;
  
  // 🧠 Nouvelles propriétés pour l'interface utilisateur
  final int minDays;
  final int maxDays;
  final double confidence;
  final List<String> warnings;
  
  DurationCalculation({
    required this.optimalDays,
    required this.dailyMinutes,
    required this.totalHours,
    required this.intensity,
    required this.behavioralType,
    required this.scientificBasis,
    required this.reasoning,
    required this.minDays,
    required this.maxDays,
    required this.confidence,
    this.warnings = const [],
  });
  
  /// Retourne le temps total formaté
  String get formattedTotalTime {
    if (totalHours < 1) {
      return '${(totalHours * 60).round()} minutes';
    } else if (totalHours < 24) {
      return '${totalHours.toStringAsFixed(1)} heures';
    } else {
      return '${(totalHours / 24).toStringAsFixed(1)} jours';
    }
  }
  
  /// Retourne l'intensité formatée
  String get formattedIntensity {
    switch (intensity) {
      case IntensityLevel.light:
        return 'Léger';
      case IntensityLevel.moderate:
        return 'Modéré';
      case IntensityLevel.intensive:
        return 'Intensif';
      case IntensityLevel.challenging:
        return 'Challenging';
    }
  }
}

/// Niveaux d'intensité
enum IntensityLevel {
  light,
  moderate,
  intensive,
  challenging,
}
