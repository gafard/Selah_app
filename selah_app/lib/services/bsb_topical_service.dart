import 'dart:convert';
import 'package:flutter/services.dart';

/// Service BSB Topical pour l'index thématique de la Bible Study Bible
/// 
/// Utilise bsb_topical_index_optimized.json pour :
/// - Recherche thématique
/// - Enrichissement des passages
/// - Génération de présets cohérents
class BSBTopicalService {
  static Map<String, dynamic>? _topicalData;
  static bool _isLoading = false;

  /// Initialise le service (chargement à la demande)
  static Future<void> init() async {
    if (_topicalData != null || _isLoading) return;

    _isLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/bsb_topical_index_optimized.json');
      _topicalData = json.decode(jsonString);
      print('✅ BSBTopicalService initialisé avec ${_topicalData?.length ?? 0} thèmes');
    } catch (e) {
      print('⚠️ Erreur chargement BSBTopicalService: $e');
      _topicalData = {};
    } finally {
      _isLoading = false;
    }
  }

  /// Recherche des thèmes par mot-clé
  static Future<List<Map<String, dynamic>>> searchThemes(String query) async {
    await init();
    
    if (_topicalData == null) return [];

    final results = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    for (final entry in _topicalData!.entries) {
      final themeId = entry.key;
      final themeData = entry.value as Map<String, dynamic>;
      final references = themeData['references'] as List<dynamic>? ?? [];
      
      // Rechercher dans les références bibliques et le texte
      bool matches = false;
      for (final ref in references) {
        if (ref.toString().toLowerCase().contains(queryLower)) {
          matches = true;
          break;
        }
      }
      
      if (matches) {
        results.add({
          'id': themeId,
          'references': references,
          'count': themeData['count'] ?? 0,
        });
      }
    }

    return results;
  }

  /// Recherche un thème spécifique (pour compatibilité)
  static Future<List<String>> searchTheme(String theme) async {
    await init();
    
    if (_topicalData == null) return [];
    
    final normalizedTheme = theme.toLowerCase().trim();
    
    // Recherche exacte d'abord
    for (final key in _topicalData!.keys) {
      if (key.toLowerCase() == normalizedTheme) {
        return List<String>.from(_topicalData![key]['references'] ?? []);
      }
    }
    
    // Recherche partielle (limité à 30 résultats)
    final matches = <String>[];
    for (final key in _topicalData!.keys) {
      if (key.toLowerCase().contains(normalizedTheme)) {
        matches.addAll(_topicalData![key]['references'] ?? []);
        if (matches.length >= 30) break; // Limiter les résultats
      }
    }
    
    return matches;
  }

  /// Obtient les thèmes populaires
  static Future<List<String>> getPopularThemes() async {
    await init();
    
    if (_topicalData == null) return [];
    
    final themes = <String>[];
    for (final entry in _topicalData!.entries) {
      final themeData = entry.value as Map<String, dynamic>;
      final count = themeData['count'] ?? 0;
      if (count > 5) { // Seulement les thèmes avec plus de 5 références
        themes.add(entry.key);
      }
    }
    
    return themes.take(50).toList()..sort(); // Limiter à 50 thèmes populaires
  }

  /// Recherche partielle de thèmes
  static Future<List<String>> searchPartialTheme(String partial) async {
    await init();
    
    if (_topicalData == null) return [];
    
    final normalizedPartial = partial.toLowerCase().trim();
    final matches = <String>[];
    
    for (final theme in _topicalData!.keys) {
      if (theme.toLowerCase().contains(normalizedPartial)) {
        matches.add(theme);
        if (matches.length >= 20) break; // Limiter les résultats
      }
    }
    
    return matches;
  }

  /// Recherche les références d'un thème
  static Future<List<String>> searchThemeReferences(String theme) async {
    await init();
    
    if (_topicalData == null) return [];
    
    final normalizedTheme = theme.toLowerCase().trim();
    
    // Recherche exacte d'abord
    for (final key in _topicalData!.keys) {
      if (key.toLowerCase() == normalizedTheme) {
        return List<String>.from(_topicalData![key]['references'] ?? []);
      }
    }
    
    return [];
  }

  /// Récupère les thèmes pour un passage biblique spécifique
  static Future<List<String>> getThemesForPassage(String reference) async {
    await init();
    
    if (_topicalData == null) return [];

    final themes = <String>[];
    final refLower = reference.toLowerCase();
    
    // Extraire le livre et les versets du passage
    final bookMatch = RegExp(r'^([^0-9]+)').firstMatch(refLower);
    if (bookMatch == null) return [];
    
    String book = bookMatch.group(1)?.trim() ?? '';
    
    // Convertir les noms de livres français vers anglais pour BSB
    final bookMappings = {
      'pierre': 'peter',
      '1 pierre': '1 peter',
      '2 pierre': '2 peter',
      'jean': 'john',
      'jacques': 'james',
      'romains': 'romans',
      'corinthiens': 'corinthians',
      'galates': 'galatians',
      'éphésiens': 'ephesians',
      'philippiens': 'philippians',
      'colossiens': 'colossians',
      'thessaloniciens': 'thessalonians',
      'timothée': 'timothy',
      'tite': 'titus',
      'philémon': 'philemon',
      'hébreux': 'hebrews',
      'apocalypse': 'revelation',
    };
    
    book = bookMappings[book] ?? book;
    
    final verseMatch = RegExp(r'(\d+):(\d+)(?:-(\d+))?').firstMatch(refLower);
    
    if (verseMatch == null) return [];
    
    final chapter = int.tryParse(verseMatch.group(1) ?? '') ?? 0;
    final startVerse = int.tryParse(verseMatch.group(2) ?? '') ?? 0;
    final endVerse = int.tryParse(verseMatch.group(3) ?? '') ?? startVerse;

    for (final entry in _topicalData!.entries) {
      final themeData = entry.value as Map<String, dynamic>;
      final references = themeData['references'] as List<dynamic>? ?? [];
      
      // Vérifier si le passage correspond
      for (final ref in references) {
        final refStr = ref.toString().toLowerCase();
        
        // Vérifier si c'est le même livre et chapitre
        if (refStr.contains(book) && refStr.contains('$chapter:')) {
          // Extraire les versets de la référence
          final refVerseMatch = RegExp(r'(\d+):(\d+)(?:-(\d+))?').firstMatch(refStr);
          if (refVerseMatch != null) {
            final refStartVerse = int.tryParse(refVerseMatch.group(2) ?? '') ?? 0;
            final refEndVerse = int.tryParse(refVerseMatch.group(3) ?? '') ?? refStartVerse;
            
            // Vérifier si les versets se chevauchent
            if (refStartVerse <= endVerse && refEndVerse >= startVerse) {
              // Extraire le thème principal du texte
              final text = references.length > 2 ? references[2].toString() : '';
              if (text.isNotEmpty) {
                themes.add(_extractThemeFromText(text));
              }
              break;
            }
          }
        }
      }
    }

    // Si aucun thème spécifique trouvé, essayer une recherche plus large par livre
    if (themes.isEmpty) {
      return await _getThemesForBook(book);
    }

    return themes.toSet().toList(); // Supprimer les doublons
  }

  /// Récupère les thèmes généraux pour un livre
  static Future<List<String>> _getThemesForBook(String book) async {
    final themes = <String>[];
    
    for (final entry in _topicalData!.entries) {
      final themeData = entry.value as Map<String, dynamic>;
      final references = themeData['references'] as List<dynamic>? ?? [];
      
      // Vérifier si le livre est mentionné dans les références
      for (final ref in references) {
        if (ref.toString().toLowerCase().contains(book.toLowerCase())) {
          final text = references.length > 2 ? references[2].toString() : '';
          if (text.isNotEmpty) {
            themes.add(_extractThemeFromText(text));
          }
          break;
        }
      }
    }

    return themes.take(5).toList(); // Limiter à 5 thèmes généraux
  }

  /// Récupère les références pour un thème spécifique
  static Future<List<Map<String, dynamic>>> getThemeReferences(String theme) async {
    await init();
    
    if (_topicalData == null) return [];

    final results = <Map<String, dynamic>>[];
    final themeLower = theme.toLowerCase();

    for (final entry in _topicalData!.entries) {
      final themeId = entry.key;
      final themeData = entry.value as Map<String, dynamic>;
      final references = themeData['references'] as List<dynamic>? ?? [];
      
      // Vérifier si le thème correspond
      bool matches = false;
      for (final ref in references) {
        if (ref.toString().toLowerCase().contains(themeLower)) {
          matches = true;
          break;
        }
      }
      
      if (matches) {
        results.add({
          'id': themeId,
          'references': references,
          'count': themeData['count'] ?? 0,
        });
      }
    }

    return results;
  }

  /// Récupère les thèmes pertinents pour un objectif spirituel
  static Future<List<String>> getThemesForGoal(String goal) async {
    await init();
    
    // Mapping des objectifs vers les thèmes BSB
    final goalThemeMapping = {
      'Témoigner avec audace': ['witness', 'testimony', 'evangelism', 'mission', 'boldness'],
      'Évangéliser en ligne': ['evangelism', 'digital', 'online', 'sharing', 'gospel'],
      'Partager ma foi': ['faith', 'sharing', 'testimony', 'witness', 'gospel'],
      'Mieux prier': ['prayer', 'worship', 'communion', 'intimacy', 'devotion'],
      'Sagesse': ['wisdom', 'understanding', 'discernment', 'counsel', 'knowledge'],
      'Croissance spirituelle': ['growth', 'maturity', 'discipleship', 'transformation', 'sanctification'],
      'Paix intérieure': ['peace', 'rest', 'comfort', 'tranquility', 'serenity'],
      'Force dans l\'épreuve': ['strength', 'endurance', 'trial', 'suffering', 'perseverance'],
      'Amour et relations': ['love', 'relationships', 'marriage', 'family', 'friendship'],
      'Service et ministère': ['service', 'ministry', 'calling', 'gifts', 'leadership'],
    };

    final relevantThemes = goalThemeMapping[goal] ?? ['spiritual', 'growth', 'faith'];
    
    // Rechercher les thèmes correspondants dans l'index BSB
    final foundThemes = <String>[];
    for (final theme in relevantThemes) {
      final results = await searchThemes(theme);
      for (final result in results.take(3)) { // Limiter à 3 résultats par thème
        final references = result['references'] as List<dynamic>;
        if (references.length > 2) {
          final text = references[2].toString();
          foundThemes.add(_extractThemeFromText(text));
        }
      }
    }

    return foundThemes.toSet().toList();
  }

  /// Extrait un thème principal du texte biblique
  static String _extractThemeFromText(String text) {
    // Mots-clés thématiques communs
    final themeKeywords = [
      'love', 'faith', 'hope', 'grace', 'mercy', 'peace', 'joy', 'wisdom',
      'prayer', 'worship', 'salvation', 'redemption', 'forgiveness', 'healing',
      'strength', 'courage', 'patience', 'kindness', 'goodness', 'faithfulness',
      'gentleness', 'self-control', 'righteousness', 'holiness', 'purity',
      'service', 'ministry', 'calling', 'mission', 'witness', 'testimony',
      'fellowship', 'community', 'church', 'body', 'unity', 'harmony',
      'truth', 'light', 'darkness', 'sin', 'repentance', 'conversion',
      'kingdom', 'eternity', 'heaven', 'judgment', 'blessing', 'promise'
    ];

    final textLower = text.toLowerCase();
    for (final keyword in themeKeywords) {
      if (textLower.contains(keyword)) {
        return keyword.capitalize();
      }
    }

    // Si aucun mot-clé trouvé, extraire le premier mot significatif
    final words = text.split(' ').where((w) => w.length > 4).toList();
    return words.isNotEmpty ? words.first.capitalize() : 'Spiritual';
  }

  /// Récupère tous les thèmes disponibles
  static Future<List<String>> getAllThemes() async {
    await init();
    
    if (_topicalData == null) return [];

    final themes = <String>[];
    for (final entry in _topicalData!.entries) {
      final themeData = entry.value as Map<String, dynamic>;
      final references = themeData['references'] as List<dynamic>? ?? [];
      
      if (references.length > 2) {
        final text = references[2].toString();
        themes.add(_extractThemeFromText(text));
      }
    }

    return themes.toSet().toList();
  }

  /// Calcule la pertinence thématique d'un passage pour un objectif
  static Future<double> calculateThematicRelevance(
    String passageReference, 
    String goal
  ) async {
    final passageThemes = await getThemesForPassage(passageReference);
    final goalThemes = await getThemesForGoal(goal);
    
    if (passageThemes.isEmpty || goalThemes.isEmpty) return 0.0;
    
    int matches = 0;
    for (final passageTheme in passageThemes) {
      for (final goalTheme in goalThemes) {
        if (passageTheme.toLowerCase().contains(goalTheme.toLowerCase()) ||
            goalTheme.toLowerCase().contains(passageTheme.toLowerCase())) {
          matches++;
          break;
        }
      }
    }
    
    return matches / goalThemes.length;
  }

  /// Vérifie si le service est initialisé
  static bool get isInitialized => _topicalData != null;

  /// Obtient le nombre de thèmes disponibles
  static int get themeCount => _topicalData?.length ?? 0;
}

/// Extension pour capitaliser les chaînes
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}