import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Service de comparaison de versions bibliques
/// Permet de comparer jusqu'à 14 versions différentes d'un même verset
class BibleComparisonService {
  static Map<String, dynamic>? _versionsMetadata;
  static bool _isInitialized = false;

  /// Initialise le service
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Charger les métadonnées des versions
      final String jsonString = await rootBundle.loadString('assets/data/bible_versions_metadata.json');
      _versionsMetadata = json.decode(jsonString);
      _isInitialized = true;
      print('✅ BibleComparisonService initialisé avec ${_versionsMetadata?.length ?? 0} versions');
    } catch (e) {
      print('⚠️ Erreur chargement métadonnées versions: $e');
      _versionsMetadata = {};
      _isInitialized = true;
    }
  }

  /// Obtient les métadonnées de toutes les versions disponibles
  static Map<String, dynamic> getVersionsMetadata() {
    return _versionsMetadata ?? {};
  }

  /// Obtient les informations d'une version spécifique
  static Map<String, dynamic>? getVersionInfo(String versionCode) {
    return _versionsMetadata?[versionCode];
  }

  /// Recherche un verset dans toutes les versions
  static Future<List<Map<String, dynamic>>> searchVerse(String reference) async {
    await init();
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/bible_comparison.jsonl.gz');
      final bytes = gzip.decode(utf8.encode(jsonString));
      final content = utf8.decode(bytes);
      final lines = content.split('\n');
      
      final results = <Map<String, dynamic>>[];
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          if (data['reference'] == reference) {
            results.add(data);
          }
        } catch (e) {
          // Ignorer les lignes malformées
        }
      }
      
      return results;
    } catch (e) {
      print('⚠️ Erreur recherche verset $reference: $e');
      return [];
    }
  }

  /// Recherche des versets par livre et chapitre
  static Future<List<Map<String, dynamic>>> searchByBookChapter(String book, int chapter) async {
    await init();
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/bible_comparison.jsonl.gz');
      final bytes = gzip.decode(utf8.encode(jsonString));
      final content = utf8.decode(bytes);
      final lines = content.split('\n');
      
      final results = <Map<String, dynamic>>[];
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          if (data['book'] == book && data['chapter'] == chapter) {
            results.add(data);
          }
        } catch (e) {
          // Ignorer les lignes malformées
        }
      }
      
      return results;
    } catch (e) {
      print('⚠️ Erreur recherche $book $chapter: $e');
      return [];
    }
  }

  /// Recherche des versets par mot-clé dans toutes les versions
  static Future<List<Map<String, dynamic>>> searchByKeyword(String keyword) async {
    await init();
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/bible_comparison.jsonl.gz');
      final bytes = gzip.decode(utf8.encode(jsonString));
      final content = utf8.decode(bytes);
      final lines = content.split('\n');
      
      final results = <Map<String, dynamic>>[];
      final normalizedKeyword = keyword.toLowerCase();
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          final versions = data['versions'] as Map<String, dynamic>? ?? {};
          
          // Vérifier si le mot-clé est présent dans au moins une version
          bool found = false;
          for (final text in versions.values) {
            if (text.toString().toLowerCase().contains(normalizedKeyword)) {
              found = true;
              break;
            }
          }
          
          if (found) {
            results.add(data);
          }
        } catch (e) {
          // Ignorer les lignes malformées
        }
      }
      
      return results;
    } catch (e) {
      print('⚠️ Erreur recherche mot-clé $keyword: $e');
      return [];
    }
  }

  /// Compare deux versions spécifiques d'un verset
  static Future<Map<String, String>?> compareVersions(String reference, String version1, String version2) async {
    final results = await searchVerse(reference);
    
    if (results.isEmpty) return null;
    
    final verse = results.first;
    final versions = verse['versions'] as Map<String, dynamic>? ?? {};
    
    return {
      version1: versions[version1]?.toString() ?? '',
      version2: versions[version2]?.toString() ?? '',
    };
  }

  /// Obtient toutes les versions disponibles pour un verset
  static Future<Map<String, String>?> getVerseVersions(String reference) async {
    final results = await searchVerse(reference);
    
    if (results.isEmpty) return null;
    
    final verse = results.first;
    final versions = verse['versions'] as Map<String, dynamic>? ?? {};
    
    final result = <String, String>{};
    for (final entry in versions.entries) {
      result[entry.key] = entry.value.toString();
    }
    
    return result;
  }

  /// Obtient les statistiques du service
  static Future<Map<String, dynamic>> getStats() async {
    await init();
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/bible_comparison.jsonl.gz');
      final bytes = gzip.decode(utf8.encode(jsonString));
      final content = utf8.decode(bytes);
      final lines = content.split('\n');
      
      int verseCount = 0;
      final Set<String> books = {};
      final Map<String, int> versionCounts = {};
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          verseCount++;
          
          final book = data['book']?.toString() ?? '';
          if (book.isNotEmpty) books.add(book);
          
          final versions = data['versions'] as Map<String, dynamic>? ?? {};
          for (final version in versions.keys) {
            versionCounts[version] = (versionCounts[version] ?? 0) + 1;
          }
        } catch (e) {
          // Ignorer les lignes malformées
        }
      }
      
      return {
        'verse_count': verseCount,
        'book_count': books.length,
        'version_count': _versionsMetadata?.length ?? 0,
        'version_counts': versionCounts,
        'is_initialized': _isInitialized,
      };
    } catch (e) {
      print('⚠️ Erreur calcul statistiques: $e');
      return {
        'verse_count': 0,
        'book_count': 0,
        'version_count': _versionsMetadata?.length ?? 0,
        'version_counts': {},
        'is_initialized': _isInitialized,
      };
    }
  }

  /// Vérifie si le service est initialisé
  static bool get isInitialized => _isInitialized;
}
