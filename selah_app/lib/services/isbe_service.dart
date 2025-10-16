import 'package:sqflite/sqflite.dart';
import 'bible_pack_manager.dart';
import 'web_fallback_service.dart';

/// Service ISBE (International Standard Bible Encyclopedia)
/// 
/// Fournit l'accès à l'encyclopédie biblique complète
class ISBEService {
  static Database? _database;
  
  /// Initialise le service ISBE
  static Future<void> init() async {
    try {
      _database = await BiblePackManager.getPackDatabase('isbe');
      if (_database != null) {
        print('✅ ISBEService initialisé');
      } else {
        print('⚠️ ISBEService: Pack ISBE non disponible');
      }
    } catch (e) {
      print('❌ Erreur initialisation ISBEService: $e');
    }
  }
  
  /// Récupère une entrée de l'encyclopédie par mot-clé
  static Future<Map<String, dynamic>?> getEntry(String keyword) async {
    // 🌐 FALLBACK WEB - Utiliser les données par défaut si pas de base
    if (_database == null || WebFallbackService.isActive) {
      print('🌐 Mode fallback: Recherche ISBE par défaut pour $keyword');
      return WebFallbackService.getDefaultISBEEntry(keyword);
    }
    
    try {
      final results = await _database!.query(
        'entries',
        where: 'keyword LIKE ? OR title LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%'],
        limit: 1,
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('⚠️ Erreur recherche ISBE $keyword: $e');
      // Fallback en cas d'erreur
      return WebFallbackService.getDefaultISBEEntry(keyword);
    }
  }
  
  /// Récupère toutes les entrées contenant un mot-clé
  static Future<List<Map<String, dynamic>>> searchEntries(String keyword) async {
    // 🌐 FALLBACK WEB - Utiliser les données par défaut si pas de base
    if (_database == null || WebFallbackService.isActive) {
      print('🌐 Mode fallback: Recherche ISBE par défaut pour $keyword');
      return WebFallbackService.searchDefaultISBE(keyword);
    }
    
    try {
      final results = await _database!.query(
        'entries',
        where: 'keyword LIKE ? OR title LIKE ? OR content LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
        orderBy: 'title ASC',
        limit: 20,
      );
      
      return results;
    } catch (e) {
      print('⚠️ Erreur recherche ISBE $keyword: $e');
      // Fallback en cas d'erreur
      return WebFallbackService.searchDefaultISBE(keyword);
    }
  }
  
  /// Récupère les entrées par catégorie
  static Future<List<Map<String, dynamic>>> getEntriesByCategory(String category) async {
    if (_database == null) {
      print('⚠️ ISBEService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.query(
        'entries',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'title ASC',
      );
      
      return results;
    } catch (e) {
      print('⚠️ Erreur catégorie ISBE $category: $e');
      return [];
    }
  }
  
  /// Récupère les catégories disponibles
  static Future<List<String>> getCategories() async {
    if (_database == null) {
      print('⚠️ ISBEService non initialisé');
      return [];
    }
    
    try {
      final results = await _database!.rawQuery(
        'SELECT DISTINCT category FROM entries WHERE category IS NOT NULL ORDER BY category'
      );
      
      return results.map((row) => row['category'] as String).toList();
    } catch (e) {
      print('⚠️ Erreur catégories ISBE: $e');
      return [];
    }
  }
  
  /// Récupère une entrée par ID
  static Future<Map<String, dynamic>?> getEntryById(int id) async {
    if (_database == null) {
      print('⚠️ ISBEService non initialisé');
      return null;
    }
    
    try {
      final results = await _database!.query(
        'entries',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('⚠️ Erreur entrée ISBE $id: $e');
      return null;
    }
  }
  
  /// Vérifie si le service est disponible
  static bool get isAvailable => _database != null;
  
  /// Ferme la base de données
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🔒 ISBEService fermé');
    }
  }
}
