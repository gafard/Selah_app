import 'package:hive/hive.dart';

/// Service offline pour les thèmes spirituels par verset
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
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _themesBox = await Hive.openBox('bible_themes');
    print('✅ ThemesService initialisé (${_themesBox?.length ?? 0} entrées)');
  }
  
  /// Récupère les thèmes d'un verset
  /// 
  /// [id] : ID du verset (ex: "Jean.3.16")
  /// 
  /// Retourne : Liste des thèmes spirituels
  static Future<List<String>> themes(String id) async {
    try {
      final data = _themesBox?.get(id);
      if (data == null) return [];
      
      return List<String>.from(data as List);
    } catch (e) {
      print('⚠️ Erreur themes($id): $e');
      return [];
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
}

