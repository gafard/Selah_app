import 'prayer_subjects_builder.dart';
import '../models/spiritual_foundation.dart';
import 'spiritual_foundations_service.dart';
import 'bsb_topical_service.dart';
import 'bsb_concordance_service.dart';
import 'bible_comparison_service.dart';

/// Contexte complet pour la génération de prières intelligentes
class PrayerContext {
  final Map<String, dynamic> userProfile; // level, goal, duration, lifeContext...
  final String season;                    // Advent/Lent/Easter/Ordinary...
  final List<String> detectedThemes;      // issus de la méta-analyse
  final Map<String, Set<String>> answers; // selectedTagsByField etc.
  final String passageRef;
  final String passageText;
  final DateTime? currentDate;
  final SpiritualFoundation? foundationOfDay; // NOUVEAU: Fondation du jour

  PrayerContext({
    required this.userProfile,
    required this.season,
    required this.detectedThemes,
    required this.answers,
    required this.passageRef,
    required this.passageText,
    this.currentDate,
    this.foundationOfDay,
  });

  /// Factory pour créer un contexte depuis les données existantes
  factory PrayerContext.fromMeditation({
    required Map<String, dynamic> userProfile,
    required String passageText,
    required String passageRef,
    required Map<String, Set<String>> answers,
    List<String>? detectedThemes,
    DateTime? currentDate,
    SpiritualFoundation? foundationOfDay,
  }) {
    return PrayerContext(
      userProfile: userProfile,
      season: _detectSeason(currentDate ?? DateTime.now()),
      detectedThemes: detectedThemes ?? [],
      answers: answers,
      passageRef: passageRef,
      passageText: passageText,
      currentDate: currentDate,
      foundationOfDay: foundationOfDay,
    );
  }

  static String _detectSeason(DateTime now) {
    final month = now.month;
    final day = now.day;
    
    // Advent (décembre avant Noël)
    if (month == 12 && day <= 25) return 'advent';
    // Christmas (Noël à Épiphanie)
    if ((month == 12 && day >= 25) || (month == 1 && day <= 6)) return 'christmas';
    // Lent (40 jours avant Pâques)
    if (month == 3 || month == 4) return 'lent';
    // Easter (Pâques à Pentecôte)
    if (month == 4 || month == 5 || month == 6) return 'easter';
    // Ordinary Time
    return 'ordinary';
  }
}

/// Idée de prière enrichie avec métadonnées intelligentes
class PrayerIdea {
  final String title;
  final String body;
  final String category; // adoration/confession/thanks/intercession
  final String? verseRef;
  final String? emotion; // hope/peace/repentance...
  final List<String> tags; // ['family','healing','discipline']
  final double score;
  final Map<String, dynamic> metadata; // Pour traçabilité

  PrayerIdea({
    required this.title,
    required this.body,
    required this.category,
    required this.tags,
    this.verseRef,
    this.emotion,
    this.score = 0,
    this.metadata = const {},
  });

  PrayerIdea copyWith({
    double? score,
    String? verseRef,
    String? emotion,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? body,
  }) =>
    PrayerIdea(
      title: title,
      body: body ?? this.body,
      category: category,
      tags: tags ?? this.tags,
      verseRef: verseRef ?? this.verseRef,
      emotion: emotion ?? this.emotion,
      score: score ?? this.score,
      metadata: metadata ?? this.metadata,
    );

  /// Convertit vers le format existant pour compatibilité
  Map<String, dynamic> toPrayerItem() {
    return {
      'theme': tags.join(' · ').toUpperCase(),
      'subject': title,
      'description': body,
      'category': category,
      'verseRef': verseRef,
      'emotion': emotion,
      'score': score,
    };
  }
}

/// Profil émotionnel adapté au niveau spirituel
class EmotionProfile {
  final String level;
  final Map<String, String> primaryByCategory; // category → emotion
  final Map<String, double> categoryWeights;   // Importance relative par catégorie

  EmotionProfile(this.level, this.primaryByCategory, this.categoryWeights);

  String? primaryEmotionForCategory(String category) => primaryByCategory[category];
  double weightForCategory(String category) => categoryWeights[category] ?? 1.0;
}

/// Générateur de profils émotionnels
class EmotionProfiles {
  static EmotionProfile forLevel(String? level) {
    switch ((level ?? '').toLowerCase()) {
      case 'nouveau converti':
        return EmotionProfile('Nouveau converti', {
          'adoration': 'joy',
          'confession': 'cleansing',
          'thanks': 'gratitude',
          'intercession': 'sharing',
        }, {
          'adoration': 1.2,    // Favoriser l'adoration pour la joie
          'confession': 0.8,   // Moins de confession pour éviter la culpabilité
          'thanks': 1.3,       // Beaucoup de reconnaissance
          'intercession': 1.0,
        });
        
      case 'rétrograde':
        return EmotionProfile('Rétrograde', {
          'adoration': 'awe',
          'confession': 'repentance',
          'thanks': 'restoration',
          'intercession': 'return',
        }, {
          'adoration': 1.1,
          'confession': 1.4,   // Plus de confession pour le retour
          'thanks': 1.2,       // Reconnaissance de la restauration
          'intercession': 0.9,
        });
        
      case 'fidèle pas si régulier':
        return EmotionProfile('Fidèle pas si régulier', {
          'adoration': 'longing',
          'confession': 'resolve',
          'thanks': 'awareness',
          'intercession': 'discipline',
        }, {
          'adoration': 1.0,
          'confession': 1.1,
          'thanks': 1.1,
          'intercession': 1.3, // Favoriser l'intercession pour la discipline
        });
        
      case 'serviteur/leader':
        return EmotionProfile('Serviteur/leader', {
          'adoration': 'holiness',
          'confession': 'humility',
          'thanks': 'stewardship',
          'intercession': 'burden',
        }, {
          'adoration': 1.1,
          'confession': 1.2,   // Humilité importante pour les leaders
          'thanks': 1.0,
          'intercession': 1.4, // Beaucoup d'intercession pour le fardeau
        });
        
      default: // fidèle régulier
        return EmotionProfile('Fidèle régulier', {
          'adoration': 'faithfulness',
          'confession': 'alignment',
          'thanks': 'contentment',
          'intercession': 'perseverance',
        }, {
          'adoration': 1.0,
          'confession': 1.0,
          'thanks': 1.0,
          'intercession': 1.0, // Équilibre parfait
        });
    }
  }
}

/// Générateur de prières intelligentes
class IntelligentPrayerGenerator {
  /// Point d'entrée principal
  static List<PrayerIdea> generate(PrayerContext ctx) {
    print('🧠 Génération de prières intelligentes...');
    
    // 1) Idées brutes (logique existante)
    final rawIdeas = _baselineIdeas(ctx);
    print('📝 ${rawIdeas.length} idées brutes générées');

    // 2) Enrichissements intelligents
    final emotionProfile = EmotionProfiles.forLevel(ctx.userProfile['level']);
    final activeTheme = _getActiveThemeForGoal(ctx.userProfile['goal']);
    
    // 🚀 NOUVEAU - Enrichissement avec données BSB
    final bsbThemes = _getBSBThemesForPassage(ctx.passageRef);
    final concordanceWords = _getConcordanceWordsForPassage(ctx.passageRef);
    final comparisonInsights = _getComparisonInsightsForPassage(ctx.passageRef);
    
    final expanded = _expandWithKB(
      ideas: rawIdeas,
      theme: activeTheme,
      season: ctx.season,
      emotionProfile: emotionProfile,
      passageRef: ctx.passageRef,
      userProfile: ctx.userProfile,
      // bsbThemes: bsbThemes,
      // concordanceWords: concordanceWords,
      // comparisonInsights: comparisonInsights,
    );
    print('✨ ${expanded.length} idées enrichies');

    // 3) Re-scoring personnalisé
    final rescored = _rescore(expanded, ctx);
    print('🎯 Re-scoring appliqué');

    // 4) Normalisation (équilibre ACTS + diversité)
    final balanced = _rebalanceACTS(rescored, emotionProfile);
    print('⚖️ Équilibre ACTS appliqué');

    // 5) Top-N final
    final finalIdeas = balanced.take(5).toList();
    print('✅ ${finalIdeas.length} prières finales générées');
    
    return finalIdeas;
  }

  /// 🚀 NOUVEAU - Obtenir les thèmes BSB pour un passage
  static Future<List<String>> _getBSBThemesForPassage(String passageRef) async {
    try {
      await BSBTopicalService.init();
      
      // Extraire le livre du passage
      final book = _extractBookFromReference(passageRef);
      if (book.isNotEmpty) {
        final themes = await BSBTopicalService.searchTheme(book);
        return themes.take(5).toList(); // Limiter à 5 thèmes
      }
      
      return [];
    } catch (e) {
      print('❌ Erreur récupération thèmes BSB: $e');
      return [];
    }
  }

  /// 🚀 NOUVEAU - Obtenir les mots de concordance pour un passage
  static Future<List<String>> _getConcordanceWordsForPassage(String passageRef) async {
    try {
      await BSBConcordanceService.init();
      
      // Mots-clés spirituels communs
      final spiritualWords = ['amour', 'grâce', 'foi', 'espérance', 'paix', 'joie', 'sagesse'];
      final foundWords = <String>[];
      
      for (final word in spiritualWords) {
        final results = await BSBConcordanceService.searchWord(word);
        if (results.isNotEmpty) {
          foundWords.add(word);
        }
      }
      
      return foundWords.take(3).toList(); // Limiter à 3 mots
    } catch (e) {
      print('❌ Erreur récupération concordance: $e');
      return [];
    }
  }

  /// 🚀 NOUVEAU - Obtenir les insights de comparaison pour un passage
  static Future<Map<String, dynamic>> _getComparisonInsightsForPassage(String passageRef) async {
    try {
      await BibleComparisonService.init();
      
      final comparison = await BibleComparisonService.getVerseVersions(passageRef);
      if (comparison != null && comparison.isNotEmpty) {
        return {
          'availableVersions': comparison.keys.length,
          'hasComparison': true,
          'passageRef': passageRef,
        };
      }
      
      return {'hasComparison': false, 'passageRef': passageRef};
    } catch (e) {
      print('❌ Erreur récupération comparaison: $e');
      return {'hasComparison': false, 'passageRef': passageRef};
    }
  }

  /// Extrait le livre d'une référence biblique
  static String _extractBookFromReference(String passageRef) {
    // Extraire le livre (ex: "Jean 3:16" -> "Jean")
    final parts = passageRef.split(' ');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return '';
  }

  // === Étape 1 : Idées brutes (intégration avec PrayerSubjectsBuilder existant) ===
  static List<PrayerIdea> _baselineIdeas(PrayerContext ctx) {
    print('🔗 Intégration avec PrayerSubjectsBuilder...');
    
    // Utiliser la logique existante de PrayerSubjectsBuilder
    final prayerSubjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: ctx.answers,
      freeTexts: _extractFreeTexts(ctx.answers),
    );
    
    // Convertir PrayerSubject vers PrayerIdea
    final ideas = prayerSubjects.map((subject) {
      return PrayerIdea(
        title: subject.label,
        body: _enhancePrayerBody(subject.label, subject.category),
        category: _mapCategory(subject.category),
        tags: [subject.category],
        score: _getBaseScore(subject.category),
        metadata: {
          'source': 'prayer_subjects_builder',
          'originalCategory': subject.category,
        },
      );
    }).toList();
    
    // Ajouter des idées basées sur les thèmes détectés dans le texte
    final textBasedIdeas = _generateTextBasedIdeas(ctx);
    ideas.addAll(textBasedIdeas);
    
    // NOUVEAU: Ajouter des prières basées sur la fondation du jour
    int foundationPrayersCount = 0;
    if (ctx.foundationOfDay != null) {
      final foundationPrayers = _generateFoundationPrayers(ctx.foundationOfDay!);
      ideas.addAll(foundationPrayers);
      foundationPrayersCount = foundationPrayers.length;
      print('🙏 ${foundationPrayersCount} prières de fondation ajoutées');
    }
    
    print('📝 ${ideas.length} idées générées (${prayerSubjects.length} du builder + ${textBasedIdeas.length} du texte + ${foundationPrayersCount} fondations)');
    return ideas;
  }

  /// Extrait les textes libres des réponses utilisateur
  static Map<String, String> _extractFreeTexts(Map<String, Set<String>> answers) {
    final freeTexts = <String, String>{};
    
    // Chercher des patterns de texte libre dans les réponses
    for (final entry in answers.entries) {
      final field = entry.key;
      final values = entry.value;
      
      // Si c'est un champ de texte libre (contient des guillemets ou est long)
      for (final value in values) {
        if (value.length > 20 && (value.contains('"') || value.contains('\''))) {
          freeTexts[field] = value.replaceAll('"', '').replaceAll('\'', '').trim();
        }
      }
    }
    
    return freeTexts;
  }

  /// Améliore le corps de la prière selon la catégorie
  static String _enhancePrayerBody(String label, String category) {
    final baseBody = label;
    
    switch (category) {
      case 'gratitude':
        return 'Seigneur, $baseBody. Merci pour ta fidélité et tes bénédictions dans ma vie.';
      case 'repentance':
        return 'Père de grâce, $baseBody. Aide-moi à marcher dans ta justice et ta vérité.';
      case 'obedience':
        return 'Seigneur, $baseBody. Donne-moi la force et la sagesse pour te suivre fidèlement.';
      case 'promise':
        return 'Père céleste, $baseBody. Je m\'appuie sur ta parole qui ne passe jamais.';
      case 'intercession':
        return 'Seigneur d\'amour, $baseBody. Que ta volonté s\'accomplisse dans leurs vies.';
      case 'praise':
        return 'Seigneur, $baseBody. Tu es digne de toute louange et de tout honneur.';
      case 'trust':
        return 'Père de paix, $baseBody. Je remets tout entre tes mains.';
      case 'guidance':
        return 'Seigneur de sagesse, $baseBody. Éclaire mon chemin et guide mes pas.';
      case 'warning':
        return 'Seigneur, $baseBody. Garde-moi de chuter et fortifie ma marche.';
      default:
        return 'Seigneur, $baseBody. Bénis ce temps de prière.';
    }
  }

  /// Mappe les catégories du builder vers les catégories ACTS
  static String _mapCategory(String builderCategory) {
    final mapping = {
      'gratitude': 'thanks',
      'repentance': 'confession',
      'obedience': 'intercession',
      'promise': 'adoration',
      'intercession': 'intercession',
      'praise': 'adoration',
      'trust': 'intercession',
      'guidance': 'intercession',
      'warning': 'confession',
      'other': 'intercession',
    };
    return mapping[builderCategory] ?? 'intercession';
  }

  /// Attribue un score de base selon la catégorie
  static double _getBaseScore(String category) {
    final scores = {
      'gratitude': 0.8,
      'repentance': 0.7,
      'obedience': 0.6,
      'promise': 0.9,
      'intercession': 0.7,
      'praise': 0.8,
      'trust': 0.6,
      'guidance': 0.7,
      'warning': 0.6,
      'other': 0.5,
    };
    return scores[category] ?? 0.5;
  }

  /// Génère des idées basées sur l'analyse du texte biblique
  static List<PrayerIdea> _generateTextBasedIdeas(PrayerContext ctx) {
    final ideas = <PrayerIdea>[];
    final text = ctx.passageText.toLowerCase();
    final detectedThemes = ctx.detectedThemes;
    
    // Analyser le texte pour des thèmes spécifiques
    if (detectedThemes.contains('family') || text.contains('famille') || text.contains('père') || text.contains('mère')) {
      ideas.add(PrayerIdea(
        title: 'Prière pour ma famille',
        body: 'Seigneur, je te confie ma famille. Bénis chacun de ses membres et unis nos cœurs dans ton amour.',
        category: 'intercession',
        tags: ['family', 'blessing', 'text-based'],
        score: 0.8,
        metadata: {'source': 'text_analysis', 'trigger': 'family_keywords'},
      ));
    }
    
    if (detectedThemes.contains('healing') || text.contains('guérison') || text.contains('santé') || text.contains('maladie')) {
      ideas.add(PrayerIdea(
        title: 'Demande de guérison',
        body: 'Père céleste, je te demande la guérison et la restauration pour ceux qui souffrent.',
        category: 'intercession',
        tags: ['healing', 'restoration', 'text-based'],
        score: 0.7,
        metadata: {'source': 'text_analysis', 'trigger': 'healing_keywords'},
      ));
    }
    
    if (text.contains('amour') || text.contains('charité') || detectedThemes.contains('love')) {
      ideas.add(PrayerIdea(
        title: 'Prière pour l\'amour',
        body: 'Seigneur, enseigne-moi à aimer comme tu aimes. Remplis mon cœur de ton amour.',
        category: 'intercession',
        tags: ['love', 'character', 'text-based'],
        score: 0.6,
        metadata: {'source': 'text_analysis', 'trigger': 'love_keywords'},
      ));
    }
    
    if (text.contains('foi') || text.contains('croire') || detectedThemes.contains('faith')) {
      ideas.add(PrayerIdea(
        title: 'Prière pour la foi',
        body: 'Seigneur, augmente ma foi. Aide-moi à te faire confiance en toutes circonstances.',
        category: 'intercession',
        tags: ['faith', 'trust', 'text-based'],
        score: 0.6,
        metadata: {'source': 'text_analysis', 'trigger': 'faith_keywords'},
      ));
    }
    
    return ideas;
  }

  // === Étape 2 : Expansion via la base de connaissances ===
  static List<PrayerIdea> _expandWithKB({
    required List<PrayerIdea> ideas,
    required String theme,
    required String season,
    required EmotionProfile emotionProfile,
    required String passageRef,
    required Map<String, dynamic> userProfile,
  }) {
    return ideas.map((idea) {
      // Verset d'ancrage prioritaire
      final verse = _getAnchoringVerse(theme, season, passageRef);
      
      // Ton émotionnel adapté
      final emotion = emotionProfile.primaryEmotionForCategory(idea.category);
      
      // Tags enrichis
      final extraTags = <String>[
        theme,
        'season:$season',
        if (emotion != null) 'emotion:$emotion',
        'level:${userProfile['level']}',
      ];
      
      // Réécriture du corps avec ton adapté
      final tonedBody = _applyEmotionalTone(idea.body, emotion, idea.category);
      
      // Métadonnées pour traçabilité
      final metadata = {
        'theme': theme,
        'season': season,
        'emotion': emotion,
        'passageRef': passageRef,
        'userLevel': userProfile['level'],
        'userGoal': userProfile['goal'],
        'source': 'intelligent_prayer_v2',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return idea.copyWith(
        verseRef: verse,
        emotion: emotion,
        tags: [...idea.tags, ...extraTags],
        score: idea.score + _bonusFromSeasonAndTheme(idea, theme, season),
        metadata: metadata,
      ).copyWith(
        body: tonedBody, // Utiliser le corps avec ton émotionnel adapté
      );
    }).toList();
  }

  // === Étape 3 : Scoring personnalisé ===
  static List<PrayerIdea> _rescore(List<PrayerIdea> ideas, PrayerContext ctx) {
    final level = (ctx.userProfile['level'] as String?) ?? 'Fidèle régulier';
    final goal = (ctx.userProfile['goal'] as String?) ?? 'Discipline quotidienne';
    final durationMin = (ctx.userProfile['durationMin'] as int?) ?? 15;

    final rescored = ideas.map((idea) {
      double score = idea.score;

      // Adéquation objectif → thème/catégorie
      if (goal.toLowerCase().contains('prière') && idea.category == 'intercession') {
        score += 0.25;
      }
      if (goal.toLowerCase().contains('discipline') && idea.tags.contains('spiritual_growth')) {
        score += 0.2;
      }

      // Niveau émotionnel
      final emotion = idea.emotion ?? '';
      if (level.toLowerCase().contains('rétrograde') && 
          (emotion == 'repentance' || idea.category == 'confession')) {
        score += 0.35;
      }
      if (level.toLowerCase().contains('leader') && 
          (emotion == 'burden' || idea.category == 'intercession')) {
        score += 0.35;
      }

      // Temps disponible : favoriser concision si durée courte
      if (durationMin <= 10 && idea.body.length < 180) {
        score += 0.1;
      }

      return idea.copyWith(score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
      
    return rescored;
  }

  // === Étape 4 : Équilibre ACTS ===
  static List<PrayerIdea> _rebalanceACTS(List<PrayerIdea> ideas, EmotionProfile emotionProfile) {
    final byCategory = <String, List<PrayerIdea>>{
      'adoration': [],
      'confession': [],
      'thanks': [],
      'intercession': [],
    };
    
    for (final idea in ideas) {
      byCategory[idea.category]?.add(idea);
    }

    final balanced = <PrayerIdea>[];
    
    // Sélection équilibrée avec poids du profil émotionnel
    void pick(String category, int baseCount) {
      final weight = emotionProfile.weightForCategory(category);
      final count = (baseCount * weight).round().clamp(1, 2);
      final categoryIdeas = byCategory[category] ?? [];
      balanced.addAll(categoryIdeas.take(count));
    }

    pick('adoration', 1);
    pick('confession', 1);
    pick('thanks', 1);
    pick('intercession', 2);

    // Compléter si moins de 5
    if (balanced.length < 5) {
      final remaining = ideas.where((i) => !balanced.contains(i)).toList();
      balanced.addAll(remaining.take(5 - balanced.length));
    }

    return balanced;
  }

  // === Méthodes utilitaires ===
  static String _getActiveThemeForGoal(String? goal) {
    final goalMapping = {
      'Discipline quotidienne': 'spiritual_growth',
      'Discipline de prière': 'prayer_life',
      'Approfondir la Parole': 'wisdom_understanding',
      'Grandir dans la foi': 'faith_foundation',
      'Développer mon caractère': 'christian_character',
      'Trouver l\'encouragement': 'hope_encouragement',
      'Expérimenter la guérison': 'forgiveness_healing',
      'Partager ma foi': 'mission_evangelism',
      'Mieux prier': 'prayer_life',
    };
    return goalMapping[goal] ?? 'spiritual_growth';
  }

  static double _bonusFromSeasonAndTheme(PrayerIdea idea, String theme, String season) {
    double bonus = 0;
    if (idea.tags.contains(theme)) bonus += 0.3;
    if (season == 'lent' && idea.category == 'confession') bonus += 0.4;
    if (season == 'easter' && idea.category == 'adoration') bonus += 0.3;
    if (season == 'advent' && idea.category == 'thanks') bonus += 0.2;
    return bonus;
  }

  static String _getAnchoringVerse(String theme, String season, String passageRef) {
    // Logique pour trouver un verset d'ancrage approprié
    // TODO: Intégrer avec la base de connaissances biblique
    final themeVerses = {
      'prayer_life': 'Matthieu 6:9-13',
      'spiritual_growth': '2 Pierre 3:18',
      'hope_encouragement': 'Romains 15:13',
      'forgiveness_healing': 'Psaume 103:3',
    };
    
    return themeVerses[theme] ?? passageRef;
  }

  static String _applyEmotionalTone(String body, String? emotion, String category) {
    // Appliquer un ton émotionnel adapté
    if (emotion == null) return body;
    
    switch (emotion) {
      case 'joy':
        return body.replaceAll('Seigneur', 'Cher Seigneur').replaceAll('Père', 'Père bien-aimé');
      case 'repentance':
        return body.replaceAll('Seigneur', 'Seigneur miséricordieux').replaceAll('Père', 'Père de grâce');
      case 'burden':
        return body.replaceAll('Seigneur', 'Seigneur de compassion').replaceAll('Père', 'Père compatissant');
      default:
        return body;
    }
  }

  /// NOUVEAU: Génère des prières basées sur la fondation spirituelle du jour
  static List<PrayerIdea> _generateFoundationPrayers(SpiritualFoundation foundation) {
    final prayers = <PrayerIdea>[];
    
    // Récupérer les prières contextuelles de la fondation
    final foundationPrayers = SpiritualFoundationsService.getFoundationPrayers(foundation);
    
    for (int i = 0; i < foundationPrayers.length; i++) {
      final prayer = foundationPrayers[i];
      prayers.add(PrayerIdea(
        title: 'Prière pour ${foundation.name}',
        body: prayer,
        category: _mapFoundationPrayerTone(foundation.prayerTone),
        tags: ['foundation', foundation.id, foundation.prayerTone],
        score: 0.9, // Score élevé car c'est la fondation du jour
        metadata: {
          'source': 'spiritual_foundation',
          'foundationId': foundation.id,
          'foundationName': foundation.name,
          'prayerTone': foundation.prayerTone,
          'verseReference': foundation.verseReference,
        },
      ));
    }
    
    // Ajouter une prière basée sur le verset de la fondation
    prayers.add(PrayerIdea(
      title: 'Méditation sur ${foundation.verseReference}',
      body: 'Seigneur, aide-moi à méditer sur ce verset: "${foundation.verseText}". Que cette parole transforme ma vie aujourd\'hui.',
      category: 'adoration',
      tags: ['foundation', foundation.id, 'verse_meditation'],
      score: 0.85,
      metadata: {
        'source': 'foundation_verse',
        'foundationId': foundation.id,
        'verseReference': foundation.verseReference,
        'verseText': foundation.verseText,
      },
    ));
    
    return prayers;
  }

  /// Mappe le ton de prière de la fondation vers les catégories ACTS
  static String _mapFoundationPrayerTone(String prayerTone) {
    switch (prayerTone) {
      case 'adoration':
        return 'adoration';
      case 'intercession':
        return 'intercession';
      case 'repentance':
        return 'confession';
      case 'thanks':
        return 'thanks';
      default:
        return 'intercession';
    }
  }
}

/// Détecteur de saison liturgique
class SeasonDetector {
  static String detect([DateTime? date]) {
    final now = date ?? DateTime.now();
    return PrayerContext._detectSeason(now);
  }
}

/// Styliseur de texte pour appliquer des tons émotionnels
class TextStyler {
  static String applyTone(String text, String? emotion) {
    return IntelligentPrayerGenerator._applyEmotionalTone(text, emotion, '');
  }
}
