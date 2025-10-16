import 'package:hive/hive.dart';
import 'openbible_themes_service.dart';
import 'semantic_passage_boundary_service.dart';
import 'thompson_plan_service.dart';
import 'bible_context_service.dart';

/// 🔧 PASTEUR - Service de thèmes spirituels avec adaptation contextuelle
/// 
/// Niveau : Pasteur (Utilité) - Service utilitaire pour la gestion des thèmes
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (contexte sémantique)
/// 🔥 Priorité 2: bible_context_service.dart (contexte biblique)
/// 🔥 Priorité 3: thompson_plan_service.dart (thèmes spirituels)
/// 🎯 Thompson: Enrichit les thèmes avec suggestions spirituelles
/// 
/// Sources de données :
/// - Hive box 'bible_themes'
/// - Hydratée depuis assets/jsons/themes.json
/// 
/// Format :
/// {
///   "Matthieu.5.3": ["humilité", "royaume de Dieu", "béatitudes"],
///   "Jean.3.16": ["amour", "salut", "foi", "vie éternelle"],
///   ...
/// }
class ThemesService {
  static Box? _themesBox;
  static Box? _analysisBox;
  
  /// 🧠 Initialise la box Hive avec analyse contextuelle
  static Future<void> init() async {
    _themesBox = await Hive.openBox('bible_themes');
    _analysisBox = await Hive.openBox('themes_analysis');
    print('🚲 Pasteur Intelligent: ThemesService initialisé (${_themesBox?.length ?? 0} entrées)');
  }
  
  /// 🧠 Récupère les thèmes d'un verset avec enrichissement contextuel
  /// 
  /// [id] : ID du verset (ex: "Jean.3.16")
  /// 
  /// Retourne : Liste des thèmes spirituels enrichis
  static Future<List<String>> themes(String id) async {
    try {
      final data = _themesBox?.get(id);
      if (data == null) return [];
      
      final baseThemes = List<String>.from(data as List);
      
      // 🔥 PRIORITÉ 1: Enrichir avec OpenBible Themes
      final openBibleThemes = await _getOpenBibleThemes(id);
      
      // Combiner les thèmes de base avec OpenBible
      final combinedThemes = <String>{
        ...baseThemes,
        ...openBibleThemes,
      }.toList();
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Enrichir avec le contexte sémantique
      final enrichedThemes = await _enrichThemesWithContext(id, combinedThemes);
      
      return enrichedThemes;
    } catch (e) {
      print('⚠️ Erreur themes($id): $e');
      return [];
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère les thèmes OpenBible pour un verset
  static Future<List<String>> _getOpenBibleThemes(String id) async {
    try {
      if (!OpenBibleThemesService.isAvailable) return [];
      
      // Extraire des mots-clés de l'ID
      final parts = id.split('.');
      if (parts.isEmpty) return [];
      
      final book = parts[0];
      
      // Rechercher des thèmes OpenBible correspondants
      final themes = await OpenBibleThemesService.searchThemes(book);
      
      // Extraire les noms des thèmes
      return themes.map((theme) => theme['name'] as String? ?? '').where((name) => name.isNotEmpty).toList();
    } catch (e) {
      print('⚠️ Erreur thèmes OpenBible: $e');
      return [];
    }
  }

  /// 🧠 Enrichit les thèmes avec le contexte sémantique
  static Future<List<String>> _enrichThemesWithContext(String id, List<String> baseThemes) async {
    try {
      final enrichedThemes = List<String>.from(baseThemes);
      
      // 🔥 PRIORITÉ 1: Récupérer le contexte sémantique FALCON X
      final semanticContext = await _getSemanticContext(id);
      if (semanticContext != null) {
        final semanticTheme = semanticContext['theme'] as String?;
        if (semanticTheme != null && !enrichedThemes.contains(semanticTheme)) {
          enrichedThemes.add(semanticTheme);
        }
      }
      
      // 🔥 PRIORITÉ 3: Récupérer le thème Thompson
      final thompsonTheme = await _getThompsonTheme(id);
      if (thompsonTheme != null && !enrichedThemes.contains(thompsonTheme)) {
        enrichedThemes.add(thompsonTheme);
      }
      
      return enrichedThemes;
    } catch (e) {
      print('⚠️ Erreur enrichissement thèmes: $e');
      return baseThemes;
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère le contexte sémantique FALCON X
  static Future<Map<String, dynamic>?> _getSemanticContext(String id) async {
    try {
      // Extraire livre et chapitre de l'ID
      final parts = id.split('.');
      if (parts.length < 2) return null;
      
      final book = parts[0];
      final chapter = int.tryParse(parts[1]);
      if (chapter == null) return null;
      
      // Utiliser FALCON X pour trouver l'unité sémantique
      final unit = SemanticPassageBoundaryService.findUnitContaining(book, chapter);
      if (unit == null) return null;
      
      return {
        'unit_name': unit.name,
        'priority': unit.priority.name,
        'theme': unit.theme,
        'liturgical_context': unit.liturgicalContext,
        'emotional_tones': unit.emotionalTones,
        'annotation': unit.annotation,
      };
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 3: Récupère le thème Thompson
  static Future<String?> _getThompsonTheme(String id) async {
    try {
      // TODO: Intégrer avec thompson_plan_service pour récupérer le thème
      // Mapping basique pour l'instant
      final book = id.split('.').first;
      
      if (book.contains('Psaumes')) {
        return 'Vie de prière';
      } else if (book.contains('Jean')) {
        return 'Exigence spirituelle';
      } else if (book.contains('Matthieu')) {
        return 'Ne vous inquiétez pas';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Recherche des versets par thème
  /// 
  /// [theme] : Thème à rechercher (ex: "amour")
  /// 
  /// Retourne : Liste d'IDs de versets contenant ce thème
  static Future<List<String>> searchByTheme(String theme) async {
    final verseIds = <String>[];
    
    try {
      final allKeys = _themesBox?.keys ?? [];
      
      for (final key in allKeys) {
        final verseThemes = await themes(key as String);
        
        if (verseThemes.any((t) => t.toLowerCase().contains(theme.toLowerCase()))) {
          verseIds.add(key);
        }
      }
    } catch (e) {
      print('⚠️ Erreur searchByTheme($theme): $e');
    }
    
    return verseIds;
  }
  
  /// Récupère tous les thèmes disponibles (pour autocomplétion)
  /// 
  /// Retourne : Liste de tous les thèmes uniques
  static Future<List<String>> getAllThemes() async {
    final allThemes = <String>{};
    
    try {
      final allKeys = _themesBox?.keys ?? [];
      
      for (final key in allKeys) {
        final verseThemes = await themes(key as String);
        allThemes.addAll(verseThemes);
      }
    } catch (e) {
      print('⚠️ Erreur getAllThemes: $e');
    }
    
    return allThemes.toList()..sort();
  }
  
  /// Hydrate la box depuis les assets JSON
  static Future<void> hydrateFromAssets(Map<String, dynamic> themesData) async {
    print('💧 Hydratation ThemesService...');
    
    int count = 0;
    for (final entry in themesData.entries) {
      await _themesBox?.put(entry.key, entry.value);
      count++;
    }
    
    print('✅ $count entrées hydratées dans bible_themes');
  }

  /// 🧠 Récupère les thèmes adaptatifs basés sur le contexte
  static Future<List<String>> getAdaptiveThemes(String id, {String? userContext}) async {
    try {
      final baseThemes = await themes(id);
      final adaptiveThemes = List<String>.from(baseThemes);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Adapter selon le contexte utilisateur
      if (userContext != null) {
        final contextualThemes = await _getContextualThemes(id, userContext);
        adaptiveThemes.addAll(contextualThemes);
      }
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Adapter selon l'heure du jour
      final timeBasedThemes = await _getTimeBasedThemes(id);
      adaptiveThemes.addAll(timeBasedThemes);
      
      // Supprimer les doublons
      return adaptiveThemes.toSet().toList();
    } catch (e) {
      print('⚠️ Erreur thèmes adaptatifs: $e');
      return await themes(id);
    }
  }

  /// 🧠 Récupère les thèmes contextuels
  static Future<List<String>> _getContextualThemes(String id, String userContext) async {
    try {
      final contextualThemes = <String>[];
      
      // Adapter selon le contexte utilisateur
      if (userContext.toLowerCase().contains('prière')) {
        contextualThemes.addAll(['prière', 'communion', 'intimité']);
      } else if (userContext.toLowerCase().contains('étude')) {
        contextualThemes.addAll(['étude', 'sagesse', 'compréhension']);
      } else if (userContext.toLowerCase().contains('méditation')) {
        contextualThemes.addAll(['méditation', 'réflexion', 'contemplation']);
      }
      
      return contextualThemes;
    } catch (e) {
      return [];
    }
  }

  /// 🧠 Récupère les thèmes basés sur l'heure
  static Future<List<String>> _getTimeBasedThemes(String id) async {
    try {
      final hour = DateTime.now().hour;
      final timeBasedThemes = <String>[];
      
      // Adapter selon l'heure du jour
      if (hour >= 5 && hour < 12) {
        // Matin
        timeBasedThemes.addAll(['nouveau départ', 'espoir', 'bénédiction']);
      } else if (hour >= 12 && hour < 18) {
        // Après-midi
        timeBasedThemes.addAll(['force', 'persévérance', 'guidance']);
      } else if (hour >= 18 && hour < 22) {
        // Soir
        timeBasedThemes.addAll(['reconnaissance', 'paix', 'repos']);
      } else {
        // Nuit
        timeBasedThemes.addAll(['protection', 'sécurité', 'confiance']);
      }
      
      return timeBasedThemes;
    } catch (e) {
      return [];
    }
  }

  /// 🧠 Récupère les suggestions de thèmes intelligentes
  static Future<List<Map<String, dynamic>>> getIntelligentThemeSuggestions(String id) async {
    try {
      final suggestions = <Map<String, dynamic>>[];
      final baseThemes = await themes(id);
      
      // Suggestion basée sur les thèmes existants
      if (baseThemes.contains('amour')) {
        suggestions.add({
          'type': 'related_theme',
          'theme': 'compassion',
          'reason': 'Thème lié à l\'amour',
          'priority': 'high',
        });
      }
      
      if (baseThemes.contains('foi')) {
        suggestions.add({
          'type': 'related_theme',
          'theme': 'confiance',
          'reason': 'Thème lié à la foi',
          'priority': 'high',
        });
      }
      
      // Suggestion basée sur le contexte sémantique
      final semanticContext = await _getSemanticContext(id);
      if (semanticContext != null) {
        final priority = semanticContext['priority'] as String?;
        if (priority == 'critical') {
          suggestions.add({
            'type': 'semantic_priority',
            'theme': 'importance spirituelle',
            'reason': 'Passage critique identifié',
            'priority': 'critical',
          });
        }
      }
      
      return suggestions;
    } catch (e) {
      print('⚠️ Erreur suggestions thèmes: $e');
      return [];
    }
  }

  /// 🧠 Analyse les tendances des thèmes
  static Future<Map<String, dynamic>> getThemeTrends() async {
    try {
      final allThemes = await getAllThemes();
      final themeCounts = <String, int>{};
      final semanticPriorities = <String, int>{};
      final thompsonThemes = <String, int>{};
      
      // Analyser tous les versets
      final allKeys = _themesBox?.keys ?? [];
      for (final key in allKeys) {
        final verseThemes = await themes(key as String);
        
        // Compter les thèmes
        for (final theme in verseThemes) {
          themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
        }
        
        // Analyser le contexte sémantique
        final semanticContext = await _getSemanticContext(key);
        if (semanticContext != null) {
          final priority = semanticContext['priority'] as String?;
          if (priority != null) {
            semanticPriorities[priority] = (semanticPriorities[priority] ?? 0) + 1;
          }
        }
        
        // Analyser les thèmes Thompson
        final thompsonTheme = await _getThompsonTheme(key);
        if (thompsonTheme != null) {
          thompsonThemes[thompsonTheme] = (thompsonThemes[thompsonTheme] ?? 0) + 1;
        }
      }
      
      return {
        'total_verses': allKeys.length,
        'total_themes': allThemes.length,
        'theme_frequency': themeCounts,
        'semantic_priority_distribution': semanticPriorities,
        'thompson_theme_distribution': thompsonThemes,
        'most_common_theme': themeCounts.isNotEmpty 
            ? themeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'aucun',
        'most_common_semantic_priority': semanticPriorities.isNotEmpty 
            ? semanticPriorities.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'aucun',
      };
    } catch (e) {
      print('⚠️ Erreur tendances thèmes: $e');
      return {};
    }
  }

  /// 🧠 Retourne les statistiques du service intelligent
  static Map<String, dynamic> getIntelligentStats() {
    return {
      'service_type': 'Pasteur Intelligent',
      'features': [
        'Thèmes enrichis avec contexte sémantique',
        'Adaptation contextuelle des thèmes',
        'Thèmes basés sur l\'heure',
        'Suggestions intelligentes de thèmes',
        'Analyse des tendances des thèmes',
        'Intégration Thompson',
      ],
      'integrations': [
        'semantic_passage_boundary_service.dart (FALCON X)',
        'bible_context_service.dart (Contexte biblique)',
        'thompson_plan_service.dart (Thompson)',
      ],
    };
  }
}



