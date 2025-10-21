import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/meditation_journal_entry.dart';
import 'semantic_passage_boundary_service.dart';

/// ⚡ ÉVANGÉLISTE - Service de journal de méditation avec analyse émotionnelle
/// 
/// Niveau : Évangéliste (Fonctionnel) - Service fonctionnel pour l'analyse émotionnelle
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (contexte sémantique)
/// 🔥 Priorité 2: reading_memory_service.dart (mémoire de lecture)
/// 🔥 Priorité 3: thompson_plan_service.dart (thèmes spirituels)
/// 🎯 Thompson: Enrichit l'analyse avec thèmes spirituels
class MeditationJournalService {
  static const String _journalKey = 'meditation_journal_entries';
  static const int _maxEntries = 100; // Limiter à 100 entrées pour éviter la surcharge
  static Box? _analysisBox;

  /// 🧠 Initialise le service avec analyse émotionnelle
  static Future<void> init() async {
    try {
      _analysisBox = await Hive.openBox('meditation_analysis');
      print('🚗 Évangéliste Intelligent: Service de journal de méditation initialisé');
    } catch (e) {
      print('⚠️ Erreur initialisation journal: $e');
    }
  }

  /// 🧠 Sauvegarde une entrée avec analyse émotionnelle intelligente
  static Future<void> saveEntry(MeditationJournalEntry entry) async {
    try {
      // Initialiser la box d'analyse si nécessaire
      if (_analysisBox == null) {
        await init();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final existingEntries = await getEntries();
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Analyser l'entrée
      final emotionalAnalysis = await _analyzeEntry(entry);
      
      // Ajouter la nouvelle entrée au début
      existingEntries.insert(0, entry);
      
      // Limiter le nombre d'entrées
      if (existingEntries.length > _maxEntries) {
        existingEntries.removeRange(_maxEntries, existingEntries.length);
      }
      
      // Convertir en JSON et sauvegarder
      final entriesJson = existingEntries.map((e) => e.toMap()).toList();
      await prefs.setString(_journalKey, jsonEncode(entriesJson));
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Sauvegarder l'analyse
      await _saveEmotionalAnalysis(entry.id, emotionalAnalysis);
      
      print('🚗 Évangéliste Intelligent: Entrée sauvegardée avec analyse émotionnelle: ${entry.passageRef}');
    } catch (e) {
      print('❌ ERREUR lors de la sauvegarde du journal: $e');
    }
  }

  /// 🧠 Analyse une entrée de journal avec contexte sémantique
  static Future<Map<String, dynamic>> _analyzeEntry(MeditationJournalEntry entry) async {
    try {
      // 🔥 PRIORITÉ 1: Récupérer le contexte sémantique FALCON X
      final semanticContext = await _getSemanticContext(entry.passageRef);
      
      // 🔥 PRIORITÉ 2: Récupérer le thème Thompson
      final thompsonTheme = await _getThompsonTheme(entry.passageRef);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Analyser le contenu émotionnel
      final emotionalAnalysis = _analyzeEmotionalContent(entry);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Analyser la profondeur spirituelle
      final spiritualAnalysis = _analyzeSpiritualDepth(entry, semanticContext, thompsonTheme);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Analyser les sujets de prière
      final prayerAnalysis = _analyzePrayerSubjects(entry.prayerSubjects);
      
      return {
        'semantic_context': semanticContext,
        'thompson_theme': thompsonTheme,
        'emotional_analysis': emotionalAnalysis,
        'spiritual_analysis': spiritualAnalysis,
        'prayer_analysis': prayerAnalysis,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('⚠️ Erreur analyse entrée: $e');
      return {};
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère le contexte sémantique FALCON X
  static Future<Map<String, dynamic>?> _getSemanticContext(String passageRef) async {
    try {
      // Extraire livre et chapitre de la référence
      final parts = passageRef.split(' ');
      if (parts.length >= 2) {
        final book = parts[0];
        final chapter = int.tryParse(parts[1]);
        if (chapter != null) {
          final unit = SemanticPassageBoundaryService.findUnitContaining(book, chapter);
          if (unit != null) {
            return {
              'unit_name': unit.name,
              'priority': unit.priority.name,
              'theme': unit.theme,
              'liturgical_context': unit.liturgicalContext,
              'emotional_tones': unit.emotionalTones,
              'annotation': unit.annotation,
            };
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 3: Récupère le thème Thompson
  static Future<String?> _getThompsonTheme(String passageRef) async {
    try {
      // TODO: Intégrer avec thompson_plan_service pour récupérer le thème
      // Mapping basique pour l'instant
      final book = passageRef.split(' ').first;
      
      if (book.contains('Psaumes')) {
        return 'Vie de prière — Souffle spirituel';
      } else if (book.contains('Jean')) {
        return 'Exigence spirituelle — Transformation profonde';
      } else if (book.contains('Matthieu')) {
        return 'Ne vous inquiétez pas — Apprentissages de Mt 6';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🧠 Analyse le contenu émotionnel d'une entrée
  static Map<String, dynamic> _analyzeEmotionalContent(MeditationJournalEntry entry) {
    try {
      final prayerNotes = entry.prayerNotes.join(' ').toLowerCase();
      final passageText = entry.passageText.toLowerCase();
      
      // Analyser les émotions dans les notes de prière
      final emotions = <String, int>{};
      final emotionKeywords = {
        'joie': ['joie', 'heureux', 'béni', 'reconnaissant', 'gratitude'],
        'paix': ['paix', 'calme', 'sérénité', 'tranquillité'],
        'espoir': ['espoir', 'confiance', 'foi', 'croyance'],
        'amour': ['amour', 'affection', 'tendresse', 'compassion'],
        'réflexion': ['réflexion', 'méditation', 'pensée', 'contemplation'],
        'inquiétude': ['inquiétude', 'souci', 'anxiété', 'peur'],
        'gratitude': ['merci', 'gratitude', 'reconnaissant', 'bénédiction'],
      };
      
      for (final emotion in emotionKeywords.keys) {
        final keywords = emotionKeywords[emotion]!;
        int count = 0;
        for (final keyword in keywords) {
          count += prayerNotes.split(keyword).length - 1;
        }
        if (count > 0) {
          emotions[emotion] = count;
        }
      }
      
      // Déterminer l'émotion dominante
      String dominantEmotion = 'neutre';
      int maxCount = 0;
      for (final emotion in emotions.keys) {
        if (emotions[emotion]! > maxCount) {
          maxCount = emotions[emotion]!;
          dominantEmotion = emotion;
        }
      }
      
      return {
        'emotions_detected': emotions,
        'dominant_emotion': dominantEmotion,
        'emotional_intensity': _calculateEmotionalIntensity(emotions),
        'prayer_length': entry.prayerNotes.join(' ').length,
        'has_personal_reflection': prayerNotes.contains('je') || prayerNotes.contains('moi'),
      };
    } catch (e) {
      return {};
    }
  }

  /// 🧠 Calcule l'intensité émotionnelle
  static double _calculateEmotionalIntensity(Map<String, int> emotions) {
    if (emotions.isEmpty) return 0.0;
    
    final totalCount = emotions.values.reduce((a, b) => a + b);
    final uniqueEmotions = emotions.length;
    
    // Plus d'émotions uniques = plus d'intensité
    return (uniqueEmotions / 7.0).clamp(0.0, 1.0);
  }

  /// 🧠 Analyse la profondeur spirituelle
  static Map<String, dynamic> _analyzeSpiritualDepth(
    MeditationJournalEntry entry, 
    Map<String, dynamic>? semantic, 
    String? thompson
  ) {
    try {
      final prayerNotes = entry.prayerNotes.join(' ').toLowerCase();
      final passageText = entry.passageText.toLowerCase();
      
      // Analyser les termes spirituels
      final spiritualTerms = ['Dieu', 'Jésus', 'Christ', 'Esprit', 'prière', 'foi', 'amour', 'grâce', 'saint'];
      int spiritualTermCount = 0;
      for (final term in spiritualTerms) {
        spiritualTermCount += prayerNotes.split(term.toLowerCase()).length - 1;
      }
      
      // Analyser la profondeur de la réflexion
      double depthScore = 0.0;
      
      // Bonus pour la longueur des notes
      final noteLength = entry.prayerNotes.join(' ').length;
      if (noteLength > 200) {
        depthScore += 0.3;
      } else if (noteLength > 100) depthScore += 0.2;
      else if (noteLength > 50) depthScore += 0.1;
      
      // Bonus pour les termes spirituels
      if (spiritualTermCount > 5) {
        depthScore += 0.3;
      } else if (spiritualTermCount > 2) depthScore += 0.2;
      else if (spiritualTermCount > 0) depthScore += 0.1;
      
      // Bonus pour les questions spirituelles
      if (prayerNotes.contains('?')) depthScore += 0.2;
      
      // Bonus pour les références personnelles
      if (prayerNotes.contains('je') || prayerNotes.contains('moi')) depthScore += 0.2;
      
      // Bonus selon le contexte sémantique
      if (semantic != null) {
        final priority = semantic['priority'] as String?;
        if (priority == 'critical') {
          depthScore += 0.2;
        } else if (priority == 'high') depthScore += 0.1;
      }
      
      return {
        'depth_score': depthScore.clamp(0.0, 1.0),
        'spiritual_term_count': spiritualTermCount,
        'note_length': noteLength,
        'has_questions': prayerNotes.contains('?'),
        'has_personal_reflection': prayerNotes.contains('je') || prayerNotes.contains('moi'),
        'semantic_priority': semantic?['priority'],
        'thompson_theme': thompson,
      };
    } catch (e) {
      return {};
    }
  }

  /// 🧠 Analyse les sujets de prière
  static Map<String, dynamic> _analyzePrayerSubjects(List<String> subjects) {
    try {
      if (subjects.isEmpty) return {'count': 0, 'categories': {}};
      
      // Catégoriser les sujets de prière
      final categories = <String, int>{};
      final categoryKeywords = {
        'famille': ['famille', 'mari', 'femme', 'enfant', 'parent'],
        'santé': ['santé', 'guérison', 'maladie', 'médecin'],
        'travail': ['travail', 'emploi', 'carrière', 'collègue'],
        'spirituel': ['foi', 'spirituel', 'église', 'pasteur', 'communauté'],
        'financier': ['argent', 'financier', 'dette', 'provision'],
        'relationnel': ['ami', 'relation', 'conflit', 'pardon'],
        'personnel': ['moi', 'personnel', 'développement', 'croissance'],
      };
      
      for (final subject in subjects) {
        final lowerSubject = subject.toLowerCase();
        bool categorized = false;
        
        for (final category in categoryKeywords.keys) {
          final keywords = categoryKeywords[category]!;
          for (final keyword in keywords) {
            if (lowerSubject.contains(keyword)) {
              categories[category] = (categories[category] ?? 0) + 1;
              categorized = true;
              break;
            }
          }
          if (categorized) break;
        }
        
        if (!categorized) {
          categories['autre'] = (categories['autre'] ?? 0) + 1;
        }
      }
      
      return {
        'count': subjects.length,
        'categories': categories,
        'most_common_category': categories.isNotEmpty 
            ? categories.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'aucun',
      };
    } catch (e) {
      return {};
    }
  }

  /// 🧠 Sauvegarde l'analyse émotionnelle
  static Future<void> _saveEmotionalAnalysis(String entryId, Map<String, dynamic> analysis) async {
    try {
      await _analysisBox?.put('analysis_$entryId', analysis);
    } catch (e) {
      print('⚠️ Erreur sauvegarde analyse: $e');
    }
  }

  /// Récupérer toutes les entrées du journal
  static Future<List<MeditationJournalEntry>> getEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_journalKey);
      
      if (entriesJson == null) {
        return [];
      }
      
      final List<dynamic> entriesList = jsonDecode(entriesJson);
      return entriesList.map((entryMap) => 
        MeditationJournalEntry.fromMap(Map<String, dynamic>.from(entryMap))
      ).toList();
    } catch (e) {
      print('❌ ERREUR lors de la récupération du journal: $e');
      return [];
    }
  }

  /// Récupérer les entrées d'une période spécifique
  static Future<List<MeditationJournalEntry>> getEntriesForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allEntries = await getEntries();
    
    if (startDate == null && endDate == null) {
      return allEntries;
    }
    
    return allEntries.where((entry) {
      if (startDate != null && entry.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && entry.date.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Récupérer les entrées des 7 derniers jours
  static Future<List<MeditationJournalEntry>> getRecentEntries({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getEntriesForPeriod(startDate: startDate, endDate: endDate);
  }

  /// Récupérer les entrées d'un mois spécifique
  static Future<List<MeditationJournalEntry>> getEntriesForMonth(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return getEntriesForPeriod(startDate: startDate, endDate: endDate);
  }

  /// Supprimer une entrée spécifique
  static Future<void> deleteEntry(String entryId) async {
    try {
      final entries = await getEntries();
      entries.removeWhere((entry) => entry.id == entryId);
      
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = entries.map((e) => e.toMap()).toList();
      await prefs.setString(_journalKey, jsonEncode(entriesJson));
      
      print('🗑️ ENTRÉE SUPPRIMÉE du journal: $entryId');
    } catch (e) {
      print('❌ ERREUR lors de la suppression de l\'entrée: $e');
    }
  }

  /// Vider tout le journal
  static Future<void> clearJournal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_journalKey);
      print('🗑️ JOURNAL VIDÉ');
    } catch (e) {
      print('❌ ERREUR lors du vidage du journal: $e');
    }
  }

  /// Obtenir les statistiques du journal
  static Future<Map<String, dynamic>> getJournalStats() async {
    final entries = await getEntries();
    
    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'totalDays': 0,
        'averagePerWeek': 0.0,
        'mostUsedPassage': null,
        'mostUsedGradient': 0,
        'meditationTypes': {'free': 0, 'qcm': 0},
      };
    }
    
    // Calculer les statistiques
    final totalEntries = entries.length;
    final uniqueDays = entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet().length;
    final weeks = (DateTime.now().difference(entries.last.date).inDays / 7).clamp(1, double.infinity);
    final averagePerWeek = totalEntries / weeks;
    
    // Passage le plus utilisé
    final passageCounts = <String, int>{};
    for (final entry in entries) {
      passageCounts[entry.passageRef] = (passageCounts[entry.passageRef] ?? 0) + 1;
    }
    final mostUsedPassage = passageCounts.isNotEmpty 
        ? passageCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;
    
    // Dégradé le plus utilisé
    final gradientCounts = <int, int>{};
    for (final entry in entries) {
      gradientCounts[entry.gradientIndex] = (gradientCounts[entry.gradientIndex] ?? 0) + 1;
    }
    final mostUsedGradient = gradientCounts.isNotEmpty 
        ? gradientCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 0;
    
    // Types de méditation
    final meditationTypes = <String, int>{'free': 0, 'qcm': 0};
    for (final entry in entries) {
      meditationTypes[entry.meditationType] = (meditationTypes[entry.meditationType] ?? 0) + 1;
    }
    
    return {
      'totalEntries': totalEntries,
      'totalDays': uniqueDays,
      'averagePerWeek': averagePerWeek,
      'mostUsedPassage': mostUsedPassage,
      'mostUsedGradient': mostUsedGradient,
      'meditationTypes': meditationTypes,
    };
  }

  /// Créer une entrée depuis les données de méditation
  static MeditationJournalEntry createEntryFromMeditation({
    required String passageRef,
    required String passageText,
    required String memoryVerse,
    required String memoryVerseRef,
    required List<String> prayerSubjects,
    required List<String> prayerNotes,
    required int gradientIndex,
    Uint8List? posterImageBytes,
    required String meditationType,
    required Map<String, dynamic> meditationData,
  }) {
    return MeditationJournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      passageRef: passageRef,
      passageText: passageText,
      memoryVerse: memoryVerse,
      memoryVerseRef: memoryVerseRef,
      prayerSubjects: prayerSubjects,
      prayerNotes: prayerNotes,
      gradientIndex: gradientIndex,
      posterImageBytes: posterImageBytes,
      meditationType: meditationType,
      meditationData: meditationData,
    );
  }

  /// 🧠 Récupère l'analyse émotionnelle d'une entrée
  static Future<Map<String, dynamic>?> getEmotionalAnalysis(String entryId) async {
    try {
      if (_analysisBox == null) {
        await init();
      }
      return _analysisBox?.get('analysis_$entryId');
    } catch (e) {
      print('⚠️ Erreur récupération analyse: $e');
      return null;
    }
  }

  /// 🧠 Récupère les tendances émotionnelles du journal
  static Future<Map<String, dynamic>> getEmotionalTrends() async {
    try {
      final entries = await getEntries();
      if (entries.isEmpty) return {};

      final emotionalTrends = <String, int>{};
      final spiritualDepths = <double>[];
      final prayerCategories = <String, int>{};
      final dominantEmotions = <String, int>{};

      for (final entry in entries) {
        final analysis = await getEmotionalAnalysis(entry.id);
        if (analysis != null) {
          // Analyser les émotions dominantes
          final dominantEmotion = analysis['emotional_analysis']?['dominant_emotion'] as String?;
          if (dominantEmotion != null) {
            dominantEmotions[dominantEmotion] = (dominantEmotions[dominantEmotion] ?? 0) + 1;
          }

          // Analyser les profondeurs spirituelles
          final depthScore = analysis['spiritual_analysis']?['depth_score'] as double?;
          if (depthScore != null) {
            spiritualDepths.add(depthScore);
          }

          // Analyser les catégories de prière
          final categories = analysis['prayer_analysis']?['categories'] as Map<String, dynamic>?;
          if (categories != null) {
            for (final category in categories.keys) {
              prayerCategories[category] = (prayerCategories[category] ?? 0) + (categories[category] as int? ?? 0);
            }
          }
        }
      }

      return {
        'total_entries_analyzed': entries.length,
        'dominant_emotions': dominantEmotions,
        'average_spiritual_depth': spiritualDepths.isNotEmpty 
            ? spiritualDepths.reduce((a, b) => a + b) / spiritualDepths.length 
            : 0.0,
        'prayer_categories': prayerCategories,
        'most_common_emotion': dominantEmotions.isNotEmpty 
            ? dominantEmotions.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'neutre',
        'most_common_prayer_category': prayerCategories.isNotEmpty 
            ? prayerCategories.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'aucun',
      };
    } catch (e) {
      print('⚠️ Erreur tendances émotionnelles: $e');
      return {};
    }
  }

  /// 🧠 Récupère les suggestions intelligentes basées sur l'analyse
  static Future<List<Map<String, dynamic>>> getIntelligentSuggestions() async {
    try {
      final trends = await getEmotionalTrends();
      final suggestions = <Map<String, dynamic>>[];

      // Suggestion basée sur l'émotion dominante
      final mostCommonEmotion = trends['most_common_emotion'] as String?;
      if (mostCommonEmotion != null && mostCommonEmotion != 'neutre') {
        suggestions.add({
          'type': 'emotional_balance',
          'title': 'Équilibre émotionnel',
          'message': 'Vos méditations sont principalement $mostCommonEmotion. Explorez d\'autres aspects spirituels.',
          'priority': 'medium',
        });
      }

      // Suggestion basée sur la profondeur spirituelle
      final avgDepth = trends['average_spiritual_depth'] as double? ?? 0.0;
      if (avgDepth < 0.3) {
        suggestions.add({
          'type': 'spiritual_depth',
          'title': 'Profondeur spirituelle',
          'message': 'Vos méditations pourraient être plus approfondies. Prenez plus de temps pour la réflexion.',
          'priority': 'high',
        });
      }

      // Suggestion basée sur les catégories de prière
      final prayerCategories = trends['prayer_categories'] as Map<String, dynamic>? ?? {};
      if (prayerCategories.isEmpty || prayerCategories.length < 3) {
        suggestions.add({
          'type': 'prayer_diversity',
          'title': 'Diversité de la prière',
          'message': 'Diversifiez vos sujets de prière pour une croissance spirituelle équilibrée.',
          'priority': 'medium',
        });
      }

      return suggestions;
    } catch (e) {
      print('⚠️ Erreur suggestions intelligentes: $e');
      return [];
    }
  }

  /// 🧠 Analyse la progression spirituelle
  static Future<Map<String, dynamic>> getSpiritualProgress() async {
    try {
      final entries = await getEntries();
      if (entries.length < 2) return {};

      // Trier par date
      entries.sort((a, b) => a.date.compareTo(b.date));

      final progressData = <String, dynamic>{};
      final depths = <double>[];
      final emotionalIntensities = <double>[];

      for (final entry in entries) {
        final analysis = await getEmotionalAnalysis(entry.id);
        if (analysis != null) {
          final depth = analysis['spiritual_analysis']?['depth_score'] as double?;
          final intensity = analysis['emotional_analysis']?['emotional_intensity'] as double?;
          
          if (depth != null) depths.add(depth);
          if (intensity != null) emotionalIntensities.add(intensity);
        }
      }

      if (depths.isNotEmpty) {
        // Calculer la tendance de progression
        final firstHalf = depths.take(depths.length ~/ 2).toList();
        final secondHalf = depths.skip(depths.length ~/ 2).toList();
        
        final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
        
        progressData['depth_progression'] = secondAvg - firstAvg;
        progressData['current_depth'] = depths.last;
        progressData['average_depth'] = depths.reduce((a, b) => a + b) / depths.length;
      }

      if (emotionalIntensities.isNotEmpty) {
        progressData['current_emotional_intensity'] = emotionalIntensities.last;
        progressData['average_emotional_intensity'] = emotionalIntensities.reduce((a, b) => a + b) / emotionalIntensities.length;
      }

      return progressData;
    } catch (e) {
      print('⚠️ Erreur analyse progression: $e');
      return {};
    }
  }

  /// 🧠 Retourne les statistiques du service intelligent
  static Map<String, dynamic> getIntelligentStats() {
    return {
      'service_type': 'Évangéliste Intelligent',
      'features': [
        'Analyse émotionnelle des entrées',
        'Contexte sémantique FALCON X',
        'Thèmes Thompson enrichis',
        'Analyse de profondeur spirituelle',
        'Catégorisation des sujets de prière',
        'Tendances émotionnelles',
        'Suggestions intelligentes',
        'Progression spirituelle',
      ],
      'integrations': [
        'semantic_passage_boundary_service.dart (FALCON X)',
        'thompson_plan_service.dart (Thompson)',
        'reading_memory_service.dart (Mémoire)',
      ],
    };
  }
}
