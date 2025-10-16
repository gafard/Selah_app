import 'package:sqflite/sqflite.dart';
import 'bible_pack_manager.dart';

/// Service OpenBible Themes
/// 
/// Fournit l'accès aux thèmes spirituels OpenBible
class OpenBibleThemesService {
  static Database? _database;
  
  /// Initialise le service OpenBible Themes
  static Future<void> init() async {
    try {
      _database = await BiblePackManager.getPackDatabase('openbible_themes');
      if (_database != null) {
        print('✅ OpenBibleThemesService initialisé');
      } else {
        print('⚠️ OpenBibleThemesService: Pack OpenBible Themes non disponible');
      }
    } catch (e) {
      print('❌ Erreur initialisation OpenBibleThemesService: $e');
    }
  }
  
  /// Récupère un thème par nom
  static Future<Map<String, dynamic>?> getTheme(String themeName) async {
    if (_database == null) {
      print('⚠️ OpenBibleThemesService non initialisé');
      return null;
    }
    
    try {
      final results = await _database!.query(
        'themes',
        where: 'name = ? OR slug = ?',
        whereArgs: [themeName, themeName],
        limit: 1,
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('⚠️ Erreur thème OpenBible $themeName: $e');
      return null;
    }
  }
  
  /// Recherche des thèmes par mot-clé
  static Future<List<Map<String, dynamic>>> searchThemes(String keyword) async {
    if (_database == null) {
      print('⚠️ OpenBibleThemesService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.query(
        'themes',
        where: 'name LIKE ? OR description LIKE ? OR keywords LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
        orderBy: 'name ASC',
        limit: 20,
      );
      
      return results;
    } catch (e) {
      print('⚠️ Erreur recherche thèmes OpenBible $keyword: $e');
      return [];
    }
  }
  
  /// Récupère tous les thèmes
  static Future<List<Map<String, dynamic>>> getAllThemes() async {
    if (_database == null) {
      print('⚠️ OpenBibleThemesService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.query(
        'themes',
        orderBy: 'name ASC',
      );
      
      return results;
    } catch (e) {
      print('⚠️ Erreur tous les thèmes OpenBible: $e');
      return [];
    }
  }
  
  /// Récupère les versets associés à un thème
  static Future<List<Map<String, dynamic>>> getThemeVerses(String themeName) async {
    if (_database == null) {
      print('⚠️ OpenBibleThemesService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.query(
        'theme_verses',
        where: 'theme_name = ?',
        whereArgs: [themeName],
        orderBy: 'reference ASC',
      );
      
      return results;
    } catch (e) {
      print('⚠️ Erreur versets thème OpenBible $themeName: $e');
      return [];
    }
  }
  
  /// Récupère les thèmes par catégorie
  static Future<List<Map<String, dynamic>>> getThemesByCategory(String category) async {
    if (_database == null) {
      print('⚠️ OpenBibleThemesService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.query(
        'themes',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );
      
      return results;
    } catch (e) {
      print('⚠️ Erreur catégorie thèmes OpenBible $category: $e');
      return [];
    }
  }
  
  /// Récupère les catégories disponibles
  static Future<List<String>> getCategories() async {
    if (_database == null) {
      print('⚠️ OpenBibleThemesService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.rawQuery(
        'SELECT DISTINCT category FROM themes WHERE category IS NOT NULL ORDER BY category'
      );
      
      return results.map((row) => row['category'] as String).toList();
    } catch (e) {
      print('⚠️ Erreur catégories thèmes OpenBible: $e');
      return [];
    }
  }
  
  /// Récupère les thèmes populaires (par nombre de versets)
  static Future<List<Map<String, dynamic>>> getPopularThemes({int limit = 10}) async {
    if (_database == null) {
      print('⚠️ OpenBibleThemesService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.rawQuery('''
        SELECT t.*, COUNT(tv.id) as verse_count
        FROM themes t
        LEFT JOIN theme_verses tv ON t.name = tv.theme_name
        GROUP BY t.id
        ORDER BY verse_count DESC
        LIMIT ?
      ''', [limit]);
      
      return results;
    } catch (e) {
      print('⚠️ Erreur thèmes populaires OpenBible: $e');
      return [];
    }
  }
  
  /// Vérifie si le service est disponible
  static bool get isAvailable => _database != null;
  
  /// Ferme la base de données
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🔒 OpenBibleThemesService fermé');
    }
  }
}
