/// ═══════════════════════════════════════════════════════════════════════════
/// SERVICE DE GÉNÉRATION DE QUESTIONS INTELLIGENTES BASÉES SUR LE CONTENU
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:math';
import '../models/content_analysis_models.dart';
import '../models/quiz_question.dart';
import '../models/passage_analysis.dart';
import 'bible_text_service.dart';
import 'treasury_crossref_service.dart';
import 'semantic_passage_boundary_service_v2.dart';
import 'matthew_henry_service.dart';
import 'bsb_book_outlines_service.dart';
import '../bootstrap.dart' as bootstrap;

class IntelligentContentQuizGenerator {
  static final Random _random = Random();

  /// ═══════════════════════════════════════════════════════════════════════════
  /// MÉTHODE PRINCIPALE DE GÉNÉRATION
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Génère des questions personnalisées basées sur le contenu et l'historique
  static Future<List<QuizQuestion>> generatePersonalizedQuestions({
    required String currentPassageText,
    required String currentPassageRef,
    required String currentPlanId,
    int questionCount = 10,
    String? targetDifficulty,
  }) async {
    print('🧠 Génération de questions personnalisées...');
    print('   Passage: $currentPassageRef');
    print('   Plan: $currentPlanId');
    print('   Questions demandées: $questionCount');

    try {
      // 1. ANALYSER LE CONTENU ACTUEL
      final contentAnalysis = await _analyzeCurrentPassage(
        currentPassageText,
        currentPassageRef,
      );

      // 2. ANALYSER L'HISTORIQUE DU PLAN
      final historyAnalysis = await _analyzePlanHistory(currentPlanId);

      // 3. RÉCUPÉRER LES RÉFÉRENCES CROISÉES
      final crossRefs = await _getCrossReferences(currentPassageRef);

      // 4. GÉNÉRER LES QUESTIONS PAR CATÉGORIE
      final contentQuestions = _generateContentQuestions(contentAnalysis, targetDifficulty);
      final semanticQuestions = _generateSemanticContextQuestions(contentAnalysis, targetDifficulty);
      final historyQuestions = _generateHistoryComparisonQuestions(
        contentAnalysis,
        historyAnalysis,
        targetDifficulty,
      );
      final crossRefQuestions = _generateCrossRefQuestions(
        contentAnalysis,
        crossRefs,
        targetDifficulty,
      );
      
      // 4.5. GÉNÉRER LES QUESTIONS NEUTRES (QUI/QUOI/OÙ/QUAND)
      final neutralQuestions = _generateNeutralQuestions(contentAnalysis, targetDifficulty);

      // 5. COMBINER ET SÉLECTIONNER LES MEILLEURES QUESTIONS
      final allQuestions = [
        ...contentQuestions,
        ...semanticQuestions,
        ...historyQuestions,
        ...crossRefQuestions,
        ...neutralQuestions,
      ];

      // Mélanger et sélectionner le nombre demandé
      allQuestions.shuffle(_random);
      final selectedQuestions = allQuestions.take(questionCount).toList();

      print('✅ ${selectedQuestions.length} questions générées:');
      print('   - Contenu: ${contentQuestions.length}');
      print('   - Sémantique: ${semanticQuestions.length}');
      print('   - Historique: ${historyQuestions.length}');
      print('   - Références croisées: ${crossRefQuestions.length}');

      return selectedQuestions;
    } catch (e) {
      print('❌ Erreur génération questions: $e');
      return _generateFallbackQuestions(currentPassageRef);
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// ANALYSE DU CONTENU ACTUEL
  /// ═══════════════════════════════════════════════════════════════════════════

  static Future<ContentAnalysis> _analyzeCurrentPassage(
    String passageText,
    String passageRef,
  ) async {
    print('🔍 Analyse du contenu actuel: $passageRef');

    // Utiliser l'analyse existante
    final facts = extractFacts(passageText);

    // Enrichir avec l'analyse sémantique
    final semanticContext = await _getSemanticContext(passageRef);

    // Enrichir avec Matthew Henry
    final henryCommentary = await _getMatthewHenryCommentary(passageRef);
    if (henryCommentary != null) {
      semanticContext['theological_commentary'] = henryCommentary;
    }

    // Enrichir avec BSB Book Outlines
    final bookOutline = await _getBSBBookOutline(passageRef);
    if (bookOutline != null) {
      semanticContext['book_outline'] = bookOutline;
    }

    // Extraire les thèmes et mots-clés
    final themes = _extractThemes(passageText);
    final keywords = _extractKeywords(passageText);

    return ContentAnalysis(
      passageRef: passageRef,
      passageText: passageText,
      characters: facts.people.toList(),
      themes: themes,
      events: facts.keyEvents,
      keywords: keywords,
      semanticContext: semanticContext,
      analyzedAt: DateTime.now(),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// ANALYSE DE L'HISTORIQUE DU PLAN
  /// ═══════════════════════════════════════════════════════════════════════════

  static Future<PlanHistoryAnalysis> _analyzePlanHistory(String planId) async {
    print('📚 Analyse de l\'historique du plan: $planId');

    final planService = bootstrap.planService;
    final planDays = await planService.getPlanDays(planId);

    // Filtrer les jours complétés
    final completedDays = planDays.where((day) => day.completed).toList();
    print('   Jours complétés: ${completedDays.length}');

    // Récupérer le contenu de chaque passage
    final completedPassages = <CompletedPassage>[];
    for (final day in completedDays) {
      if (day.readings.isEmpty) continue;

      final reading = day.readings.first;
      final passageRef = '${reading.book} ${reading.range}';
      final passageText = await BibleTextService.getPassageText(passageRef);

      if (passageText != null) {
        completedPassages.add(CompletedPassage(
          passageRef: passageRef,
          passageText: passageText,
          completedAt: DateTime.now(), // day.completedAt si disponible
          dayIndex: day.dayIndex,
        ));
      }
    }

    // Analyser les patterns
    return _extractPatterns(completedPassages);
  }

  static PlanHistoryAnalysis _extractPatterns(List<CompletedPassage> passages) {
    final themeFreq = <String, int>{};
    final characterFreq = <String, int>{};
    final keywordFreq = <String, int>{};
    final allThemes = <String>[];
    final allCharacters = <String>[];

    for (final passage in passages) {
      // Analyser chaque passage
      final facts = extractFacts(passage.passageText);

      // Compter les personnages
      for (final character in facts.people) {
        characterFreq[character] = (characterFreq[character] ?? 0) + 1;
        if (!allCharacters.contains(character)) allCharacters.add(character);
      }

      // Extraire les thèmes
      final themes = _extractThemes(passage.passageText);
      for (final theme in themes) {
        themeFreq[theme] = (themeFreq[theme] ?? 0) + 1;
        if (!allThemes.contains(theme)) allThemes.add(theme);
      }

      // Extraire les mots-clés
      final keywords = _extractKeywords(passage.passageText);
      for (final keyword in keywords) {
        keywordFreq[keyword] = (keywordFreq[keyword] ?? 0) + 1;
      }
    }

    return PlanHistoryAnalysis(
      completedPassages: passages,
      recurringThemes: allThemes,
      recurringCharacters: allCharacters,
      themeFrequency: themeFreq,
      characterFrequency: characterFreq,
      keywordFrequency: keywordFreq,
      analyzedAt: DateTime.now(),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// GÉNÉRATION DE QUESTIONS SUR LE CONTENU
  /// ═══════════════════════════════════════════════════════════════════════════

  static List<QuizQuestion> _generateContentQuestions(ContentAnalysis analysis, String? targetDifficulty) {
    final questions = <QuizQuestion>[];

    // 1. Questions sur les personnages
    if (analysis.characters.isNotEmpty) {
      questions.add(QuizQuestion(
        id: 'content_characters_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quels personnages apparaissent dans ce passage ?',
        options: _buildCharacterOptions(analysis.characters),
        correctAnswerIndices: [0],
        explanation: 'Ce passage présente ${analysis.characters.join(", ")}',
        difficulty: targetDifficulty ?? 'easy',
        category: 'comprehension',
        passageReference: analysis.passageRef,
        verseText: '${analysis.passageText.substring(0, 100)}...',
      ));
    }

    // 2. Questions sur les événements
    if (analysis.events.isNotEmpty) {
      questions.add(QuizQuestion(
        id: 'content_events_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Que se passe-t-il dans ce passage ?',
        options: _buildEventOptions(analysis.events),
        correctAnswerIndices: [0],
        explanation: 'Ce passage décrit ${_paraphraseEvent(analysis.events.first)}',
        difficulty: targetDifficulty ?? 'medium',
        category: 'comprehension',
        passageReference: analysis.passageRef,
      ));
    }

    // 3. Questions sur les thèmes
    if (analysis.themes.isNotEmpty) {
      questions.add(QuizQuestion(
        id: 'content_themes_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quel est le thème principal de ce passage ?',
        options: _buildThemeOptions(analysis.themes),
        correctAnswerIndices: [0],
        explanation: 'Le thème principal est ${analysis.themes.first}',
        difficulty: targetDifficulty ?? 'medium',
        category: 'analysis',
        passageReference: analysis.passageRef,
      ));
    }

    return questions;
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// GÉNÉRATION DE QUESTIONS BASÉES SUR LE CONTEXTE SÉMANTIQUE
  /// ═══════════════════════════════════════════════════════════════════════════

  static List<QuizQuestion> _generateSemanticContextQuestions(ContentAnalysis analysis, String? targetDifficulty) {
    final questions = <QuizQuestion>[];
    final semanticContext = analysis.semanticContext;
    
    // 1. Questions sur l'unité littéraire
    if (semanticContext['unit_name'] != null) {
      questions.add(QuizQuestion(
        id: 'semantic_unit_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Ce passage fait partie de quelle unité littéraire ?',
        options: [
          semanticContext['unit_name'],
          _generateDistractorUnit(),
          _generateDistractorUnit(),
          'Passage isolé',
        ],
        correctAnswerIndices: [0],
        explanation: 'Cette section est "${semanticContext['unit_name']}" qui traite de ${semanticContext['theme'] ?? 'thème biblique'}',
        difficulty: targetDifficulty ?? 'medium',
        category: 'analysis',
        passageReference: analysis.passageRef,
        metadata: {
          'type': 'semantic_unit',
          'unit_name': semanticContext['unit_name'],
          'unit_type': semanticContext['unit_type'],
        },
      ));
    }
    
    // 2. Questions basées sur le commentaire de Matthew Henry
    if (semanticContext['theological_commentary'] != null) {
      final commentary = semanticContext['theological_commentary'] as String;
      questions.add(_generateTheologicalQuestion(analysis.passageRef, commentary, targetDifficulty));
    }
    
    // 3. Questions sur la structure littéraire
    if (semanticContext['literary_structure'] != null) {
      questions.add(QuizQuestion(
        id: 'literary_structure_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quelle est la structure littéraire de ce passage ?',
        options: [
          semanticContext['literary_structure'],
          'Narrative simple',
          'Discours direct',
          'Parabole',
        ],
        correctAnswerIndices: [0],
        explanation: 'Ce passage utilise une structure ${semanticContext['literary_structure']}',
        difficulty: targetDifficulty ?? 'hard',
        category: 'analysis',
        passageReference: analysis.passageRef,
      ));
    }
    
    // 4. Questions sur les tons émotionnels
    if (semanticContext['emotional_tones'] != null) {
      final tones = semanticContext['emotional_tones'] as List<dynamic>?;
      if (tones != null && tones.isNotEmpty) {
        questions.add(QuizQuestion(
          id: 'emotional_tones_${DateTime.now().millisecondsSinceEpoch}',
          question: 'Quels sont les tons émotionnels dominants de ce passage ?',
          options: [
            tones.first.toString(),
            ...tones.skip(1).take(3).map((t) => t.toString()),
          ],
          correctAnswerIndices: [0],
          explanation: 'Ce passage exprime principalement ${tones.first}',
          difficulty: targetDifficulty ?? 'medium',
          category: 'analysis',
          passageReference: analysis.passageRef,
        ));
      }
    }

    // 5. Questions basées sur les thèmes BSB
    if (semanticContext['bsb_themes'] != null) {
      final bsbThemes = semanticContext['bsb_themes'] as List<dynamic>?;
      if (bsbThemes != null && bsbThemes.isNotEmpty) {
        questions.add(QuizQuestion(
          id: 'bsb_theme_${DateTime.now().millisecondsSinceEpoch}',
          question: 'Selon le plan du livre BSB, ce passage développe quel thème principal ?',
          options: [
            bsbThemes.first.toString(),
            ...bsbThemes.skip(1).take(3).map((t) => t.toString()),
          ],
          correctAnswerIndices: [0],
          explanation: 'Ce passage fait partie de la section "${semanticContext['bsb_section']}" qui traite de ${bsbThemes.first}',
          difficulty: targetDifficulty ?? 'medium',
          category: 'analysis',
          passageReference: analysis.passageRef,
          metadata: {
            'type': 'bsb_theme',
            'bsb_section': semanticContext['bsb_section'],
            'bsb_period': semanticContext['bsb_period'],
          },
        ));
      }
    }

    // 6. Questions sur la période BSB
    if (semanticContext['bsb_period'] != null) {
      questions.add(QuizQuestion(
        id: 'bsb_period_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Dans quelle période biblique se situe ce livre ?',
        options: [
          semanticContext['bsb_period'],
          'Patriarches',
          'Sagesse',
          'Église primitive',
        ],
        correctAnswerIndices: [0],
        explanation: 'Ce livre appartient à la période "${semanticContext['bsb_period']}"',
        difficulty: targetDifficulty ?? 'easy',
        category: 'comprehension',
        passageReference: analysis.passageRef,
      ));
    }
    
    return questions;
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// GÉNÉRATION DE QUESTIONS COMPARATIVES AVEC L'HISTORIQUE
  /// ═══════════════════════════════════════════════════════════════════════════

  static List<QuizQuestion> _generateHistoryComparisonQuestions(
    ContentAnalysis current,
    PlanHistoryAnalysis history,
    String? targetDifficulty,
  ) {
    final questions = <QuizQuestion>[];

    // 1. Questions sur les personnages récurrents
    final commonCharacters = current.characters
        .where((c) => history.characterFrequency.containsKey(c))
        .toList();

    if (commonCharacters.isNotEmpty) {
      final character = commonCharacters.first;
      final frequency = history.characterFrequency[character]!;
      final previousPassages = history.completedPassages
          .where((p) => p.passageText.contains(character))
          .map((p) => p.passageRef)
          .take(3)
          .toList();

      questions.add(QuizQuestion(
        id: 'history_character_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Dans vos passages précédents, vous avez déjà rencontré $character '
                 'dans $frequency passages. Comment sa présentation évolue-t-elle ici ?',
        options: [
          'Il révèle un nouvel aspect de son caractère',
          'Il accomplit une action similaire',
          'Il interagit avec de nouveaux personnages',
          'Sa présentation reste identique',
        ],
        correctAnswerIndices: [0],
        explanation: 'Ce passage développe un nouvel aspect de $character',
        difficulty: targetDifficulty ?? 'hard',
        category: 'application',
        passageReference: current.passageRef,
        metadata: {
          'type': 'history_comparison',
          'character': character,
          'frequency': frequency,
          'previous_passages': previousPassages,
        },
      ));
    }

    // 2. Questions sur les thèmes récurrents
    final commonThemes = current.themes
        .where((t) => history.themeFrequency.containsKey(t))
        .toList();

    if (commonThemes.isNotEmpty) {
      final theme = commonThemes.first;
      final frequency = history.themeFrequency[theme]!;

      questions.add(QuizQuestion(
        id: 'history_theme_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Le thème "$theme" apparaît dans $frequency de vos passages précédents. '
                 'Comment ce passage l\'approfondit-il ?',
        options: [
          'Il montre une nouvelle dimension du thème',
          'Il l\'illustre par un exemple concret',
          'Il le relie à d\'autres concepts',
          'Il développe tous ces aspects',
        ],
        correctAnswerIndices: [3],
        explanation: 'Ce passage enrichit le thème de $theme de plusieurs façons',
        difficulty: targetDifficulty ?? 'hard',
        category: 'synthesis',
        passageReference: current.passageRef,
        metadata: {
          'type': 'theme_evolution',
          'theme': theme,
          'frequency': frequency,
        },
      ));
    }

    return questions;
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// GÉNÉRATION DE QUESTIONS AVEC RÉFÉRENCES CROISÉES
  /// ═══════════════════════════════════════════════════════════════════════════

  static List<QuizQuestion> _generateCrossRefQuestions(
    ContentAnalysis current,
    List<CrossReference> crossRefs,
    String? targetDifficulty,
  ) {
    final questions = <QuizQuestion>[];

    if (crossRefs.isNotEmpty) {
      final topRef = crossRefs.first;
      questions.add(QuizQuestion(
        id: 'crossref_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quel passage biblique fait le mieux écho à ce texte ?',
        options: [
          topRef.reference,
          ...crossRefs.skip(1).take(3).map((r) => r.reference),
        ],
        correctAnswerIndices: [0],
        explanation: '${topRef.reference} partage le thème de ${topRef.theme}',
        difficulty: targetDifficulty ?? 'medium',
        category: 'analysis',
        passageReference: current.passageRef,
        metadata: {
          'type': 'cross_reference',
          'crossrefs': crossRefs.map((r) => r.toJson()).toList(),
        },
      ));
    }

    return questions;
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// MÉTHODES UTILITAIRES
  /// ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> _getSemanticContext(String passageRef) async {
    try {
      // Parser la référence pour extraire livre et chapitre
      final parts = passageRef.split(' ');
      if (parts.length < 2) return {};

      final book = parts.sublist(0, parts.length - 1).join(' ');
      final range = parts.last;
      
      // Parser le chapitre depuis la référence
      final chapterMatch = RegExp(r'(\d+):').firstMatch(range);
      final chapter = chapterMatch != null ? int.tryParse(chapterMatch.group(1)!) ?? 1 : 1;

      // Utiliser le service sémantique pour obtenir le contexte
      final result = await SemanticPassageBoundaryService.adjustPassageVerses(
        book: book,
        startChapter: chapter,
        startVerse: 1,
        endChapter: chapter,
        endVerse: 1,
      );

      return {
        'unit_name': result.includedUnit?.name,
        'unit_type': result.includedUnit?.type.name,
        'unit_priority': result.includedUnit?.priority.name,
        'theme': result.includedUnit?.description,
        'literary_structure': 'Narrative',
        'emotional_tones': ['Neutre'],
        'description': result.includedUnit?.description,
        'adjusted': result.adjusted,
        // 🆕 Contexte BSB enrichi
        'bsb_themes': result.includedUnit?.bsbThemes,
        'bsb_section': result.includedUnit?.bsbSection,
        'bsb_period': result.includedUnit?.bsbPeriod,
        'bsb_context': result.includedUnit?.bsbContext,
      };
    } catch (e) {
      print('⚠️ Erreur contexte sémantique: $e');
      return {};
    }
  }

  /// Récupère le commentaire de Matthew Henry pour un passage
  static Future<String?> _getMatthewHenryCommentary(String passageRef) async {
    try {
      final parts = passageRef.split(' ');
      if (parts.length < 2) return null;

      final book = parts.sublist(0, parts.length - 1).join(' ');
      final range = parts.last;
      
      // Parser le chapitre depuis la référence
      final chapterMatch = RegExp(r'(\d+):').firstMatch(range);
      final chapter = chapterMatch != null ? int.tryParse(chapterMatch.group(1)!) ?? 1 : 1;
      
      // Parser le verset si disponible
      final verseMatch = RegExp(r':(\d+)').firstMatch(range);
      final verse = verseMatch != null ? int.tryParse(verseMatch.group(1)!) : null;

      final commentary = await MatthewHenryService.getCommentaryForVerse(book, chapter, verse);
      return commentary;
    } catch (e) {
      print('⚠️ Erreur commentaire Matthew Henry: $e');
      return null;
    }
  }

  /// Récupère le plan du livre BSB pour un passage
  static Future<Map<String, dynamic>?> _getBSBBookOutline(String passageRef) async {
    try {
      final parts = passageRef.split(' ');
      if (parts.length < 2) return null;

      final book = parts.sublist(0, parts.length - 1).join(' ');
      
      final outline = await BSBBookOutlinesService.getBookOutline(book);
      if (outline != null) {
        // Récupérer les sections pertinentes pour le thème
        final theme = outline['sections']?.isNotEmpty == true 
            ? (outline['sections'] as List).first['themes']?.first?.toString() 
            : null;
        
        if (theme != null) {
          final sections = await BSBBookOutlinesService.getSectionsForTheme(book, theme);
          return {
            'book_outline': outline,
            'relevant_sections': sections,
            'theme': theme,
          };
        }
      }
      
      return outline;
    } catch (e) {
      print('⚠️ Erreur plan BSB: $e');
      return null;
    }
  }

  static Future<List<CrossReference>> _getCrossReferences(String passageRef) async {
    try {
      // Utiliser le service de références croisées existant
      final references = await TreasuryCrossRefService.getCrossReferences(passageRef);

      return references.take(5).map((ref) => CrossReference(
        reference: ref['reference'] as String,
        theme: 'Thème connexe',
        description: 'Passage lié thématiquement',
        relevanceScore: (ref['relevanceScore'] as num?)?.toDouble() ?? 0.8,
      )).toList();
    } catch (e) {
      print('⚠️ Erreur références croisées: $e');
      return [];
    }
  }

  static List<String> _extractThemes(String text) {
    // Thèmes bibliques communs à rechercher
    final themeKeywords = {
      'amour': 'Amour de Dieu',
      'foi': 'Foi et confiance',
      'grâce': 'Grâce divine',
      'salut': 'Salut et rédemption',
      'prière': 'Prière et communion',
      'royaume': 'Royaume de Dieu',
      'paix': 'Paix et consolation',
      'sagesse': 'Sagesse divine',
      'justice': 'Justice et droiture',
      'miséricorde': 'Miséricorde divine',
    };

    final themes = <String>[];
    for (final entry in themeKeywords.entries) {
      if (text.toLowerCase().contains(entry.key)) {
        themes.add(entry.value);
      }
    }
    return themes;
  }

  static List<String> _extractKeywords(String text) {
    // Extraire les mots-clés importants
    final words = text.toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 4)
        .where((word) => !RegExp(r'^[0-9]+$').hasMatch(word))
        .toList();

    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }

    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(5).map((e) => e.key).toList();
  }

  static List<String> _buildCharacterOptions(List<String> characters) {
    final options = <String>[];
    if (characters.isNotEmpty) {
      options.add(characters.first);
      options.addAll(characters.skip(1).take(3));
    }
    while (options.length < 4) {
      options.add('Autre personnage');
    }
    return options;
  }

  static List<String> _buildEventOptions(List<String> events) {
    final options = <String>[];
    if (events.isNotEmpty) {
      // Paraphraser le premier événement (bonne réponse)
      options.add(_paraphraseEvent(events.first));
      // Paraphraser les autres événements
      for (final event in events.skip(1).take(3)) {
        options.add(_paraphraseEvent(event));
      }
    }
    while (options.length < 4) {
      options.add('Autre événement');
    }
    return options;
  }

  static List<String> _buildThemeOptions(List<String> themes) {
    final options = <String>[];
    if (themes.isNotEmpty) {
      options.add(themes.first);
      options.addAll(themes.skip(1).take(3));
    }
    while (options.length < 4) {
      options.add('Autre thème');
    }
    return options;
  }

  static List<QuizQuestion> _generateFallbackQuestions(String passageRef) {
    return [
      QuizQuestion(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quel est le message principal de ce passage ?',
        options: [
          'L\'amour de Dieu pour l\'humanité',
          'La nécessité de la foi',
          'Le salut par grâce',
          'La vie éternelle',
        ],
        correctAnswerIndices: [0],
        explanation: 'Ce passage révèle l\'amour de Dieu',
        difficulty: 'medium',
        category: 'comprehension',
        passageReference: passageRef,
      ),
    ];
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// MÉTHODES UTILITAIRES POUR LES QUESTIONS SÉMANTIQUES
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Génère une unité littéraire distractor pour les questions
  static String _generateDistractorUnit() {
    final distractors = [
      'Discours prophétique',
      'Narrative historique',
      'Enseignement parabolique',
      'Prière liturgique',
      'Récit de miracle',
      'Dialogue théologique',
    ];
    return distractors[_random.nextInt(distractors.length)];
  }

  /// Génère une question théologique basée sur le commentaire de Matthew Henry
  static QuizQuestion _generateTheologicalQuestion(String passageRef, String commentary, String? targetDifficulty) {
    // Extraire un point clé du commentaire (simplifié)
    final sentences = commentary.split('.');
    final keyPoint = sentences.isNotEmpty ? sentences.first.trim() : 'Commentaire théologique';
    
    // Reformuler le point clé pour qu'il ne soit pas trop évident
    final reformulatedKeyPoint = _reformulateTheologicalPoint(keyPoint);
    
    return QuizQuestion(
      id: 'theological_${DateTime.now().millisecondsSinceEpoch}',
      question: 'Selon ce passage, quel aspect spirituel est particulièrement mis en évidence ?',
      options: _buildTheologicalOptions(reformulatedKeyPoint),
        correctAnswerIndices: [0],
      explanation: 'Selon ce passage, $reformulatedKeyPoint',
      difficulty: targetDifficulty ?? 'hard',
      category: 'synthesis',
      passageReference: passageRef,
      metadata: {
        'type': 'theological_commentary',
        'commentary_source': 'Matthew Henry',
      },
    );
  }

  /// Reformule un point théologique pour qu'il soit moins évident
  static String _reformulateTheologicalPoint(String originalPoint) {
    // Patterns de reformulation pour éviter la répétition littérale
    final reformulationPatterns = {
      'soumission': 'L\'importance de la soumission',
      'obéissance': 'La valeur de l\'obéissance',
      'sainteté': 'L\'appel à la sainteté',
      'amour': 'La centralité de l\'amour',
      'foi': 'La nécessité de la foi',
      'espérance': 'L\'espérance chrétienne',
      'grâce': 'La manifestation de la grâce',
      'souffrance': 'Le sens de la souffrance',
      'persévérance': 'L\'importance de persévérer',
      'humilité': 'La valeur de l\'humilité',
      'service': 'L\'appel au service',
      'témoignage': 'L\'importance du témoignage',
      'prière': 'Le rôle de la prière',
      'communion': 'La vie en communion',
      'mission': 'L\'appel à la mission',
    };
    
    final lowerPoint = originalPoint.toLowerCase();
    
    // Chercher un pattern correspondant
    for (final entry in reformulationPatterns.entries) {
      if (lowerPoint.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Si aucun pattern trouvé, créer une reformulation générique
    if (originalPoint.length > 50) {
      return 'Un enseignement spirituel important';
    }
    
    return 'Un aspect théologique central';
  }

  /// Construit les options pour les questions théologiques
  static List<String> _buildTheologicalOptions(String correctAnswer) {
    final options = <String>[correctAnswer];
    
    // Distracteurs théologiques variés
    final distractors = [
      'La soumission aux autorités',
      'L\'importance de la prière',
      'La nécessité de la foi',
      'La valeur de l\'humilité',
      'L\'appel à la sainteté',
      'La centralité de l\'amour',
      'L\'espérance chrétienne',
      'La manifestation de la grâce',
      'Le sens de la souffrance',
      'L\'importance de persévérer',
      'L\'appel au service',
      'L\'importance du témoignage',
      'Le rôle de la prière',
      'La vie en communion',
      'L\'appel à la mission',
      'La repentance',
      'La sanctification',
      'La rédemption',
      'La justification',
      'La régénération',
    ];
    
    // Mélanger et sélectionner 4 distracteurs
    distractors.shuffle(_random);
    for (final distractor in distractors) {
      if (!options.contains(distractor) && options.length < 5) {
        options.add(distractor);
      }
    }
    
    return options;
  }

  /// Paraphrase un événement pour qu'il soit moins évident
  static String _paraphraseEvent(String event) {
    // Patterns de paraphrase pour éviter la répétition littérale
    final paraphrasePatterns = {
      'écrit': 'Une lettre adressée',
      'enseigne': 'Un enseignement sur',
      'parle': 'Un discours concernant',
      'dit': 'Une déclaration sur',
      'command': 'Un ordre concernant',
      'prièr': 'Une prière pour',
      'soumis': 'Un enseignement sur la soumission',
      'saintet': 'Un appel à la sainteté',
      'souffr': 'Une exhortation face à la souffrance',
      'foi': 'Un encouragement à la foi',
      'espérance': 'Un message d\'espérance',
      'grâce': 'Un enseignement sur la grâce',
      'rédemption': 'Un message de rédemption',
      'salut': 'Un enseignement sur le salut',
      'disciples': 'Les apôtres',
      'apôtres': 'Les disciples',
      'chrétiens': 'Les croyants',
      'croyants': 'Les fidèles',
      'fidèles': 'Les chrétiens',
      'église': 'La communauté',
      'communauté': 'L\'assemblée',
      'assemblée': 'L\'église',
      'souffrance': 'l\'épreuve',
      'épreuve': 'la souffrance',
      'gloire': 'l\'honneur',
      'honneur': 'la gloire',
      'saint': 'consacré',
      'juste': 'droit',
      'humble': 'modeste',
      'pur': 'sans tache',
      'sacré': 'divin',
      'éternel': 'perpétuel',
      'parfait': 'accompli',
      'gracieux': 'bienveillant',
      'miséricordieux': 'compassionnel',
      'amour': 'charité',
      'paix': 'sérénité',
      'joie': 'allégresse',
      'sagesse': 'intelligence',
      'force': 'puissance',
      'respect': 'estime',
      'obéissance': 'soumission',
      'service': 'ministère',
      'témoignage': 'confession',
      'prophétie': 'révélation',
      'persécution': 'oppression',
      'tribulation': 'difficulté',
      'péché': 'faute',
      'repentance': 'conversion',
      'régénération': 'nouvelle naissance',
      'sanctification': 'consécration',
      'vocation': 'appel',
      'élection': 'choix',
      'prédestination': 'décret',
      'adoption': 'filiation',
      'héritage': 'patrimoine',
      'promesse': 'engagement',
      'alliance': 'pacte',
      'testament': 'alliance',
    };
    
    String paraphrased = event;
    
    // Appliquer les patterns de paraphrase
    for (final entry in paraphrasePatterns.entries) {
      paraphrased = paraphrased.replaceAll(entry.key, entry.value);
    }
    
    // Si le texte commence par un nom propre, le reformuler
    if (RegExp(r'^[A-Z][a-z]+').hasMatch(paraphrased)) {
      final words = paraphrased.split(' ');
      if (words.length > 1) {
        paraphrased = 'Un ${words.skip(1).join(' ').toLowerCase()}';
      }
    }
    
    // Si le texte est trop long, le raccourcir
    if (paraphrased.length > 80) {
      paraphrased = paraphrased.substring(0, 77) + '...';
    }
    
    return paraphrased;
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// GÉNÉRATION DE QUESTIONS NEUTRES (QUI/QUOI/OÙ/QUAND)
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Génère des questions neutres basées sur les faits du passage
  static List<QuizQuestion> _generateNeutralQuestions(ContentAnalysis analysis, String? targetDifficulty) {
    final questions = <QuizQuestion>[];
    final facts = extractFacts(analysis.passageText);

    // 1. Question sur les personnages (QUI) - Multi-choix
    if (facts.people.isNotEmpty) {
      final peopleList = facts.people.toList();
      final peopleOptions = _buildNeutralPeopleOptions(peopleList);
      final correctIndices = _getCorrectPeopleIndices(peopleList, peopleOptions);
      
      // Mélanger les options pour éviter que les bonnes réponses soient toujours en premier
      final shuffledOptions = _shuffleOptions(peopleOptions, correctIndices);
      final newCorrectIndices = _getNewCorrectIndices(peopleList, shuffledOptions);
      
      questions.add(QuizQuestion(
        id: 'neutral_who_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quels personnages sont mentionnés dans ce passage ?',
        options: shuffledOptions,
        correctAnswerIndices: newCorrectIndices,
        explanation: 'Ce passage mentionne ${peopleList.join(", ")}',
        difficulty: targetDifficulty ?? 'easy',
        category: 'comprehension',
        type: QuizType.multi,
        passageReference: analysis.passageRef,
      ));
    }

    // 2. Question sur les événements (QUOI) - Multi-choix
    if (facts.keyEvents.isNotEmpty) {
      final eventsList = facts.keyEvents.toList();
      final eventOptions = _buildNeutralEventOptions(eventsList);
      final correctIndices = _getCorrectEventIndices(eventsList, eventOptions);
      
      // Mélanger les options
      final shuffledOptions = _shuffleOptions(eventOptions, correctIndices);
      final newCorrectIndices = _getNewCorrectIndices(eventsList, shuffledOptions);
      
      questions.add(QuizQuestion(
        id: 'neutral_what_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quels événements se produisent dans ce passage ?',
        options: shuffledOptions,
        correctAnswerIndices: newCorrectIndices,
        explanation: 'Ce passage décrit ${eventsList.join(", ")}',
        difficulty: targetDifficulty ?? 'easy',
        category: 'comprehension',
        type: QuizType.multi,
        passageReference: analysis.passageRef,
      ));
    }

    // 3. Question sur le lieu (OÙ) - Choix simple
    final locationOptions = _buildNeutralLocationOptions(analysis.passageText);
    if (locationOptions.isNotEmpty) {
      // Mélanger les options pour éviter que la bonne réponse soit toujours en premier
      final shuffledOptions = _shuffleOptions(locationOptions, [0]);
      final correctIndex = shuffledOptions.indexOf(locationOptions.first);
      
      questions.add(QuizQuestion(
        id: 'neutral_where_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Où se déroule cette scène ?',
        options: shuffledOptions,
        correctAnswerIndices: [correctIndex],
        explanation: 'Cette scène se déroule ${locationOptions.first}',
        difficulty: targetDifficulty ?? 'easy',
        category: 'comprehension',
        type: QuizType.single,
        passageReference: analysis.passageRef,
      ));
    }

    // 4. Question sur le moment (QUAND) - Choix simple
    final timeOptions = _buildNeutralTimeOptions(analysis.passageText);
    if (timeOptions.isNotEmpty) {
      // Mélanger les options
      final shuffledOptions = _shuffleOptions(timeOptions, [0]);
      final correctIndex = shuffledOptions.indexOf(timeOptions.first);
      
      questions.add(QuizQuestion(
        id: 'neutral_when_${DateTime.now().millisecondsSinceEpoch}',
        question: 'À quel moment cela se passe-t-il ?',
        options: shuffledOptions,
        correctAnswerIndices: [correctIndex],
        explanation: 'Cette scène se déroule ${timeOptions.first}',
        difficulty: targetDifficulty ?? 'easy',
        category: 'comprehension',
        type: QuizType.single,
        passageReference: analysis.passageRef,
      ));
    }

    return questions;
  }

  /// Mélange les options tout en gardant trace des bonnes réponses
  static List<String> _shuffleOptions(List<String> options, List<int> correctIndices) {
    final shuffled = List<String>.from(options);
    shuffled.shuffle();
    return shuffled;
  }

  /// Recalcule les indices corrects après mélange
  static List<int> _getNewCorrectIndices(List<String> correctItems, List<String> shuffledOptions) {
    final correctIndices = <int>[];
    for (int i = 0; i < shuffledOptions.length; i++) {
      if (correctItems.any((item) => shuffledOptions[i].contains(item))) {
        correctIndices.add(i);
      }
    }
    return correctIndices;
  }

  /// Résume un événement ou un texte en une phrase courte
  static String _summarizeEvent(String event) {
    // Patterns de résumé pour différents types d'événements
    final summaryPatterns = {
      'enseign': 'Un enseignement sur',
      'parl': 'Un discours concernant',
      'dit': 'Une déclaration sur',
      'command': 'Un ordre concernant',
      'prièr': 'Une prière pour',
      'soumis': 'Un enseignement sur la soumission',
      'saintet': 'Un appel à la sainteté',
      'souffr': 'Une exhortation face à la souffrance',
      'amour': 'Un message sur l\'amour',
      'foi': 'Un encouragement à la foi',
    };
    
    // Rechercher le pattern correspondant
    final lowerEvent = event.toLowerCase();
    for (final entry in summaryPatterns.entries) {
      if (lowerEvent.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Si pas de pattern, créer un résumé générique
    if (event.length > 50) {
      return 'Un enseignement biblique important';
    }
    
    return event;
  }

  /// Résume une description de personnage
  static String _summarizeCharacter(String person) {
    // Nettoyer le nom du personnage
    final cleanPerson = person.trim();
    
    // Si c'est un nom propre biblique connu, le garder tel quel
    final biblicalNames = {
      'Jésus', 'Christ', 'Messie', 'Pierre', 'Paul', 'Jean', 'Jacques', 'André',
      'Philippe', 'Barthélemy', 'Thomas', 'Matthieu', 'Simon', 'Judas',
      'Marie', 'Joseph', 'Anne', 'Élisabeth', 'Zacharie', 'Jean-Baptiste',
      'Hérode', 'Pilate', 'Caïphe', 'Annas', 'Nicodème', 'Joseph d\'Arimathée',
      'Lazare', 'Marthe', 'Marie de Magdala', 'Salomé', 'Cléopas', 'Emmaüs',
      'Barnabas', 'Silas', 'Timothée', 'Tite', 'Onésime', 'Épaphras',
      'Archippe', 'Philémon', 'Tychique', 'Trophime', 'Démas', 'Luc', 'Marc',
      'Apollos', 'Aquilas', 'Priscille', 'Lydie', 'Dorcas', 'Étienne',
      'Corneille', 'Agrippa', 'Bérénice', 'Festus', 'Gamaliel', 'Saül',
      'Ananias', 'Saphira', 'Simon le magicien', 'Élymas'
    };
    
    if (biblicalNames.contains(cleanPerson)) {
      return cleanPerson;
    }
    
    // Si c'est un nom propre (commence par une majuscule), le garder
    if (RegExp(r'^[A-Z][a-z]+').hasMatch(cleanPerson)) {
      return cleanPerson;
    }
    
    // Sinon, créer une description générique
    return 'Un personnage biblique';
  }

  /// Construit les options pour les questions sur les personnages
  static List<String> _buildNeutralPeopleOptions(List<String> people) {
    final options = <String>[];
    
    // Ajouter les personnages réels (noms propres gardés, descriptions résumées)
    for (final person in people.take(2)) {
      final summarized = _summarizeCharacter(person);
      if (!options.contains(summarized)) {
        options.add(summarized);
      }
    }
    
    // Ajouter des distracteurs contextuels
    final distractors = [
      'Des autorités religieuses',
      'Des disciples',
      'Des croyants',
      'Des opposants',
      'Des témoins',
      'Des personnes dans le besoin',
      'Des enseignants',
    ];
    
    // Ajouter des distracteurs jusqu'à avoir 4-5 options
    distractors.shuffle(_random);
    for (final distractor in distractors) {
      if (!options.contains(distractor) && options.length < 5) {
        options.add(distractor);
      }
    }
    
    return options;
  }

  /// Construit les options pour les questions sur les événements
  static List<String> _buildNeutralEventOptions(List<String> events) {
    final options = <String>[];
    
    // Résumer les événements réels du passage
    for (final event in events.take(2)) {
      final summarized = _summarizeEvent(event);
      if (!options.contains(summarized)) {
        options.add(summarized);
      }
    }
    
    // Ajouter des distracteurs résumés et contextuels
    final distractors = [
      'Un appel à la repentance',
      'Une promesse de bénédiction',
      'Une mise en garde contre le péché',
      'Un récit de miracle',
      'Une explication prophétique',
      'Un encouragement à persévérer',
      'Une instruction pratique',
    ];
    
    // Ajouter des distracteurs jusqu'à avoir 4-5 options
    distractors.shuffle(_random);
    for (final distractor in distractors) {
      if (!options.contains(distractor) && options.length < 5) {
        options.add(distractor);
      }
    }
    
    return options;
  }

  /// Construit les options pour les questions sur le lieu
  static List<String> _buildNeutralLocationOptions(String passageText) {
    final options = <String>[];
    
    // Détecter et résumer le lieu principal
    final locationKeywords = {
      'temple': 'Au temple',
      'synagogue': 'Dans une synagogue',
      'maison': 'Dans une maison',
      'montagne': 'Sur une montagne',
      'mer': 'Près de la mer',
      'désert': 'Dans le désert',
      'jérusalem': 'À Jérusalem',
      'galilée': 'En Galilée',
      'ville': 'Dans une ville',
      'village': 'Dans un village',
    };
    
    String? detectedLocation;
    for (final entry in locationKeywords.entries) {
      if (passageText.toLowerCase().contains(entry.key)) {
        detectedLocation = entry.value;
        break;
      }
    }
    
    if (detectedLocation != null) {
      options.add(detectedLocation);
    } else {
      options.add('Dans un contexte communautaire');
    }
    
    // Ajouter des distracteurs résumés
    final distractors = [
      'En plein air',
      'Dans un lieu de culte',
      'Dans un espace privé',
      'En chemin',
    ];
    
    distractors.shuffle(_random);
    options.addAll(distractors.take(3));
    
    return options;
  }

  /// Construit les options pour les questions sur le moment
  static List<String> _buildNeutralTimeOptions(String passageText) {
    final options = <String>[];
    
    // Détecter et résumer le moment
    final timeKeywords = {
      'sabbat': 'Le jour du sabbat',
      'fête': 'Pendant une fête religieuse',
      'pâque': 'Pendant la Pâque',
      'matin': 'Le matin',
      'soir': 'Le soir',
      'nuit': 'La nuit',
      'jour': 'En plein jour',
    };
    
    String? detectedTime;
    for (final entry in timeKeywords.entries) {
      if (passageText.toLowerCase().contains(entry.key)) {
        detectedTime = entry.value;
        break;
      }
    }
    
    if (detectedTime != null) {
      options.add(detectedTime);
    } else {
      options.add('Dans la vie quotidienne');
    }
    
    // Ajouter des distracteurs résumés
    final distractors = [
      'À un moment clé',
      'Pendant le ministère',
      'Dans un contexte particulier',
      'Au temps opportun',
    ];
    
    distractors.shuffle(_random);
    options.addAll(distractors.take(3));
    
    return options;
  }

  /// Retourne les indices des bonnes réponses pour les personnages
  static List<int> _getCorrectPeopleIndices(List<String> people, List<String> options) {
    final correctIndices = <int>[];
    for (int i = 0; i < options.length; i++) {
      if (people.any((person) => options[i].contains(person))) {
        correctIndices.add(i);
      }
    }
    return correctIndices;
  }

  /// Retourne les indices des bonnes réponses pour les événements
  static List<int> _getCorrectEventIndices(List<String> events, List<String> options) {
    final correctIndices = <int>[];
    for (int i = 0; i < options.length; i++) {
      if (events.any((event) => options[i].contains(event))) {
        correctIndices.add(i);
      }
    }
    return correctIndices;
  }
}
