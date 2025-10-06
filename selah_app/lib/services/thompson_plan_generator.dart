import 'dart:math';
import '../models/thompson_plan_models.dart';

/// Générateur de plans basé sur la Bible d'étude Thompson 21
/// Utilise les chaînes thématiques, encarts et portraits pour créer des parcours personnalisés
class ThompsonPlanGenerator {
  final String Function(String key) imageFor; // e.g. ImageService.getImage
  final Random _random = Random();

  ThompsonPlanGenerator({required this.imageFor});

  /// Génère un plan Thompson personnalisé basé sur le profil utilisateur
  ThompsonPlanPreset build(CompleteProfile profile) {
    print('🎯 Génération plan Thompson pour: ${profile.goals.join(", ")}');
    
    // 1) Contexte & durée
    final durationDays = _suggestDuration(profile);
    final start = DateTime(profile.startDate.year, profile.startDate.month, profile.startDate.day);
    final themeKeys = _pickThemes(profile);
    final selectedSeeds = THOMPSON_SEEDS.where((s) => themeKeys.contains(s.key)).toList();

    print('📅 Durée: $durationDays jours');
    print('🎨 Thèmes sélectionnés: ${themeKeys.join(", ")}');
    print('📖 Seeds utilisés: ${selectedSeeds.map((s) => s.display).join(", ")}');

    // 2) Titre & cover
    final title = _titleFor(themeKeys, profile);
    final coverKey = _coverFor(themeKeys);
    final description = _descriptionFor(themeKeys, profile);

    // 3) Construction jour par jour
    final days = <ThompsonPlanDay>[];
    int seedIdx = 0;
    int refIdx = 0;

    for (int d = 0; d < durationDays; d++) {
      final date = start.add(Duration(days: d));
      final isRest = _isRestDay(profile, d);

      if (isRest) {
        days.add(ThompsonPlanDay(
          date: date,
          tasks: _restDayTasks(profile),
        ));
        continue;
      }

      // Alterner sur les seeds choisis
      final seed = selectedSeeds[seedIdx % selectedSeeds.length];
      final chunkRefs = _refsForDay(seed, refIdx, profile.minutesPerDay);

      // Avancer les curseurs
      refIdx += chunkRefs.length;
      if (refIdx >= seed.refs.length) {
        refIdx = 0;
        seedIdx++;
      }

      final tasks = _buildTasksForDay(profile, seed, chunkRefs, coverKey, d);
      days.add(ThompsonPlanDay(date: date, tasks: tasks));
    }

    final preset = ThompsonPlanPreset(
      id: 'thompson:${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      startDate: start,
      durationDays: durationDays,
      days: days,
      meta: {
        'source': 'Thompson21.Selection',
        'themeKeys': themeKeys,
        'coverImage': imageFor(coverKey),
        'requiresPhysicalBible': profile.hasPhysicalBible,
        'minutesPerDay': profile.minutesPerDay,
        'daysPerWeek': profile.daysPerWeek,
        'experience': profile.experience,
        'language': profile.language,
        'generatedAt': DateTime.now().toIso8601String(),
      },
    );

    print('✅ Plan Thompson généré: "$title"');
    print('📊 ${days.length} jours, ${days.fold(0, (sum, day) => sum + day.tasks.length)} tâches total');
    
    return preset;
  }

  // ----- Heuristiques -----
  
  /// Suggère la durée du plan selon le profil
  int _suggestDuration(CompleteProfile profile) {
    // Plus l'utilisateur a de minutes/jour & maturité, plus on peut allonger
    if (profile.minutesPerDay >= 20 && profile.experience != 'new') return 28;
    if (profile.minutesPerDay >= 15) return 21;
    if (profile.minutesPerDay >= 10) return 14;
    return 7; // Minimum pour un parcours significatif
  }

  /// Détermine si c'est un jour de repos
  bool _isRestDay(CompleteProfile profile, int dayIndex) {
    final cadence = profile.daysPerWeek.clamp(3, 7);
    if (cadence == 7) return false;
    
    // Simple: on "pose" les (7-cadence) jours comme off en réparti
    return (dayIndex % 7) >= cadence;
  }

  /// Sélectionne les thèmes selon les objectifs
  List<String> _pickThemes(CompleteProfile profile) {
    final themes = <String>{};
    
    if (profile.prefersThemes) {
      // Mapping objectifs -> thèmes Thompson
      for (final goal in profile.goals) {
        switch (goal.toLowerCase()) {
          case 'discipline':
          case 'holiness':
          case 'transformation':
            themes.add('spiritual_demand');
            break;
          case 'anxiety':
          case 'worry':
          case 'peace':
            themes.add('no_worry');
            break;
          case 'marriage':
          case 'relationships':
          case 'covenant':
            themes.add('marriage_duties');
            break;
          case 'community':
          case 'fellowship':
          case 'relationships':
            themes.add('companionship');
            break;
          case 'wisdom':
          case 'discernment':
          case 'avoiding_sin':
            themes.add('common_errors');
            break;
          case 'prayer':
          case 'spiritual_life':
          case 'communion':
            themes.add('prayer_life');
            break;
          case 'forgiveness':
          case 'healing':
          case 'reconciliation':
            themes.add('forgiveness');
            break;
          case 'trials':
          case 'faith':
          case 'perseverance':
            themes.add('faith_trials');
            break;
        }
      }
    }
    
    // Si aucun thème trouvé, utiliser des défauts selon l'expérience
    if (themes.isEmpty) {
      switch (profile.experience) {
        case 'new':
          themes.addAll(['no_worry', 'prayer_life', 'companionship']);
          break;
        case 'growing':
          themes.addAll(['spiritual_demand', 'forgiveness', 'common_errors']);
          break;
        case 'mature':
          themes.addAll(['spiritual_demand', 'faith_trials', 'marriage_duties']);
          break;
        default:
          themes.addAll(['spiritual_demand', 'companionship', 'no_worry']);
      }
    }
    
    return themes.toList();
  }

  /// Génère un titre selon les thèmes
  String _titleFor(List<String> themeKeys, CompleteProfile profile) {
    if (themeKeys.contains('spiritual_demand') && themeKeys.contains('no_worry')) {
      return 'Tenir ferme & paix du cœur';
    }
    if (themeKeys.contains('marriage_duties')) {
      return 'Cheminer en couple selon la Parole';
    }
    if (themeKeys.contains('companionship') && themeKeys.contains('prayer_life')) {
      return 'Communion & prière — Marcher ensemble';
    }
    if (themeKeys.contains('forgiveness') && themeKeys.contains('healing')) {
      return 'Pardon & guérison — Libération du cœur';
    }
    if (themeKeys.contains('faith_trials') && themeKeys.contains('perseverance')) {
      return 'Foi dans l\'épreuve — Persévérance';
    }
    
    if (themeKeys.length == 1) {
      switch (themeKeys.first) {
        case 'companionship': 
          return 'Marcher à deux — Compagnonnage biblique';
        case 'no_worry': 
          return 'Ne vous inquiétez pas — Apprentissages de Mt 6';
        case 'common_errors': 
          return 'Sagesse pratique — Corriger nos erreurs';
        case 'prayer_life':
          return 'Vie de prière — Souffle spirituel';
        case 'forgiveness':
          return 'Pardon & réconciliation — Cœur libéré';
        case 'faith_trials':
          return 'Foi dans l\'épreuve — Ténacité';
        case 'spiritual_demand':
          return 'Exigence spirituelle — Transformation profonde';
      }
    }
    
    return 'Parcours de méditation — Thompson 21';
  }

  /// Sélectionne l'image de couverture
  String _coverFor(List<String> themeKeys) {
    if (themeKeys.contains('no_worry')) return 'peace';
    if (themeKeys.contains('spiritual_demand')) return 'discipline';
    if (themeKeys.contains('marriage_duties')) return 'marriage';
    if (themeKeys.contains('companionship')) return 'community_fellowship';
    if (themeKeys.contains('prayer_life')) return 'prayer';
    if (themeKeys.contains('forgiveness')) return 'healing';
    if (themeKeys.contains('faith_trials')) return 'perseverance';
    return 'bible_reading';
  }

  /// Génère la description du plan
  String _descriptionFor(List<String> themeKeys, CompleteProfile profile) {
    final selectedSeeds = THOMPSON_SEEDS.where((s) => themeKeys.contains(s.key)).toList();
    final themes = selectedSeeds.map((s) => s.display).join(', ');
    
    String base = 'Un parcours de méditation basé sur les chaînes thématiques de la Bible d\'étude Thompson 21. ';
    
    if (profile.experience == 'new') {
      base += 'Parfait pour découvrir les fondements de la foi chrétienne.';
    } else if (profile.experience == 'growing') {
      base += 'Idéal pour approfondir ta marche avec Dieu.';
    } else {
      base += 'Pour les chrétiens matures cherchant à aller plus loin.';
    }
    
    base += ' Thèmes abordés: $themes.';
    
    if (profile.hasPhysicalBible) {
      base += ' Prépare ta Bible physique pour chaque session.';
    }
    
    return base;
  }

  /// Sélectionne les références pour un jour
  List<String> _refsForDay(ChainSeed seed, int startRefIndex, int minutes) {
    // 5–7 min => 1 réf; 10–15 => 2; 20+ => 2–3 (selon encarts)
    final bucket = (minutes >= 20) ? 3 : (minutes >= 10) ? 2 : 1;
    final slice = <String>[];
    
    for (int i = 0; i < bucket && (startRefIndex + i) < seed.refs.length; i++) {
      slice.add(seed.refs[startRefIndex + i]);
    }
    
    return slice.isEmpty ? [seed.refs.last] : slice;
  }

  /// Tâches pour un jour de repos
  List<ThompsonPlanTask> _restDayTasks(CompleteProfile profile) {
    return [
      ThompsonPlanTask(
        kind: ThompsonTaskKind.prepare,
        title: 'Sabbat de méditation — silence & action de grâce',
        payload: {
          'timerMin': 5, 
          'prompt': 'Respire. Remercie. Note une grâce de la semaine.',
          'imageKey': 'rest',
        },
      ),
      ThompsonPlanTask(
        kind: ThompsonTaskKind.prayer,
        title: 'Prière simple',
        payload: {
          'prompt': 'Notre Père (Mt 6:9-13). Répète lentement, médite chaque ligne.',
          'timerMin': 10,
        },
      ),
      ThompsonPlanTask(
        kind: ThompsonTaskKind.reflection,
        title: 'Réflexion sur la semaine',
        payload: {
          'prompt': 'Qu\'as-tu appris cette semaine ? Comment Dieu t\'a-t-il parlé ?',
          'timerMin': 5,
        },
      ),
    ];
  }

  /// Construit les tâches pour un jour normal
  List<ThompsonPlanTask> _buildTasksForDay(
    CompleteProfile profile,
    ChainSeed seed,
    List<String> refs,
    String coverKey,
    int dayIndex,
  ) {
    final tasks = <ThompsonPlanTask>[];

    // Jour 1: Introduction spéciale
    if (dayIndex == 0) {
      tasks.add(ThompsonPlanTask(
        kind: ThompsonTaskKind.prepare,
        title: 'Pourquoi la méditation ?',
        payload: {
          'prompt': 'La méditation biblique n\'est pas de la lecture passive, mais une rencontre active avec Dieu. Prépare ton cœur à écouter.',
          'imageKey': 'meditation_intro',
          'timerMin': 3,
        },
      ));
    }

    // Préparation avec Bible physique
    if (profile.hasPhysicalBible) {
      tasks.add(ThompsonPlanTask(
        kind: ThompsonTaskKind.prepare,
        title: 'Prépare ta Bible physique',
        payload: {
          'imageKey': coverKey, 
          'prompt': 'Choisis un endroit calme. Mets ton téléphone en mode avion. Ouvre ta Bible à la page d\'aujourd\'hui.',
          'timerMin': 2,
        },
      ));
    }

    // Lecture
    tasks.add(ThompsonPlanTask(
      kind: ThompsonTaskKind.reading,
      title: 'Lecture — ${seed.display}',
      passageRef: refs.join(' ; '),
      payload: {
        'suggestedVersion': profile.language == 'fr' ? 'S21' : 'default', 
        'timerMin': (profile.minutesPerDay / 2).ceil().clamp(5, 15),
        'theme': seed.display,
        'description': seed.description,
      },
    ));

    // Méditation (Selah)
    tasks.add(ThompsonPlanTask(
      kind: ThompsonTaskKind.meditation,
      title: 'Selah — rumine & note',
      payload: {
        'prompt': _promptFor(seed.key),
        'timerMin': (profile.minutesPerDay / 3).floor().clamp(3, 10),
        'imageKey': 'meditation',
      },
    ));

    // Prière
    tasks.add(ThompsonPlanTask(
      kind: ThompsonTaskKind.prayer,
      title: 'Prière — réponds à Dieu',
      payload: {
        'prompt': 'Réponds avec tes mots : adoration, confession, action de grâce, supplication.',
        'timerMin': (profile.minutesPerDay / 4).floor().clamp(3, 8),
      },
    ));

    // Application (pour utilisateurs expérimentés)
    if (profile.experience != 'new') {
      tasks.add(ThompsonPlanTask(
        kind: ThompsonTaskKind.application,
        title: 'Mettre en pratique aujourd\'hui',
        payload: {
          'prompt': 'Quel geste concret vas-tu faire dans les 24h ? Écris-le.',
          'timerMin': 3,
        },
      ));
    }

    // Mémorisation (1 jour sur 3)
    final dayHash = dayIndex % 3;
    if (dayHash == 0 && refs.isNotEmpty) {
      tasks.add(ThompsonPlanTask(
        kind: ThompsonTaskKind.memorize,
        title: 'Mémorisation — 1 verset',
        passageRef: refs.first,
        payload: {
          'tip': 'Répète à voix haute 5× matin/soir.',
          'timerMin': 5,
        },
      ));
    }

    return tasks;
  }

  /// Génère un prompt de méditation selon le thème
  String _promptFor(String key) {
    switch (key) {
      case 'no_worry':
        return 'Quelles inquiétudes ressortent ? Que dit Jésus sur la provision du Père (Mt 6) ? Comment puis-je faire confiance aujourd\'hui ?';
      case 'spiritual_demand':
        return 'Où ma "justice" ressemble-t-elle à de l\'apparence ? Qu\'est-ce que Jésus demande vraiment ? Comment être authentique ?';
      case 'companionship':
        return 'Qui Dieu place-t-il à mes côtés pour marcher à deux (Nb 10:31; Ec 4:9) ? Comment puis-je être un meilleur compagnon ?';
      case 'marriage_duties':
        return 'Comment honorer l\'alliance aujourd\'hui (Gn 2:24; Dt 24:5) ? Qu\'est-ce que l\'amour inconditionnel dans ma relation ?';
      case 'common_errors':
        return 'Laquelle de ces erreurs me guette (Gn 3; Mt 6.7; Jc 4.13-14) et quel contre-pas faire ? Comment éviter les pièges ?';
      case 'prayer_life':
        return 'Comment ma prière ressemble-t-elle à celle de Jésus (Mt 6:5-15) ? Qu\'est-ce que Dieu veut m\'enseigner sur la prière ?';
      case 'forgiveness':
        return 'Qui ai-je besoin de pardonner ? Comment le pardon de Dieu transforme-t-il mon cœur ? Comment pardonner comme Jésus ?';
      case 'faith_trials':
        return 'Comment les épreuves révèlent-elles ma foi ? Que dit Dieu dans les difficultés ? Comment tenir ferme ?';
      default:
        return 'Que révèle ce passage sur Dieu ? Quelle réponse de mon cœur aujourd\'hui ? Comment cela change-t-il ma perspective ?';
    }
  }
}