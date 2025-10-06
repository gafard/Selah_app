import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_storage_service.dart';

/// Service de téléchargement et stockage local des versions de Bible
class BibleDownloadService {
  static const Map<String, String> _bibleUrls = {
    'LSG': 'https://api.bible.com/bible/lsg/',
    'S21': 'https://api.bible.com/bible/s21/',
    'NIV': 'https://api.bible.com/bible/niv/',
    'ESV': 'https://api.bible.com/bible/esv/',
    'KJV': 'https://api.bible.com/bible/kjv/',
  };
  
  /// Vérifie si une version de Bible est disponible localement
  static bool isBibleVersionAvailable(String version) {
    return LocalStorageService.getAvailableBibleVersions().contains(version);
  }
  
  /// Télécharge une version de Bible (nécessite une connexion)
  static Future<bool> downloadBibleVersion(String version) async {
    if (!await LocalStorageService.isOnline) {
      throw Exception('Connexion Internet requise pour télécharger la Bible');
    }
    
    try {
      print('📥 Téléchargement de la version $version...');
      
      // Simuler le téléchargement (remplacer par vraie API)
      final bibleData = await _fetchBibleData(version);
      
      // Sauvegarder localement
      await LocalStorageService.saveBibleVersion(version, bibleData);
      
      print('✅ Version $version téléchargée et sauvegardée localement');
      return true;
      
    } catch (e) {
      print('❌ Erreur lors du téléchargement de $version: $e');
      return false;
    }
  }
  
  /// Récupère les données de Bible depuis l'API
  static Future<Map<String, dynamic>> _fetchBibleData(String version) async {
    // Simulation - remplacer par vraie API
    await Future.delayed(const Duration(seconds: 2)); // Simuler le téléchargement
    
    return {
      'version': version,
      'name': _getBibleName(version),
      'books': _getBibleBooks(version),
      'downloaded_at': DateTime.now().toIso8601String(),
      'size_mb': _getBibleSize(version),
    };
  }
  
  /// Récupère le nom complet de la version
  static String _getBibleName(String version) {
    const names = {
      'LSG': 'Louis Segond 1910',
      'S21': 'Segond 21',
      'NIV': 'New International Version',
      'ESV': 'English Standard Version',
      'KJV': 'King James Version',
    };
    return names[version] ?? version;
  }
  
  /// Récupère la liste des livres pour une version
  static List<Map<String, dynamic>> _getBibleBooks(String version) {
    // Simulation - remplacer par vraie structure
    return [
      {'name': 'Genèse', 'chapters': 50, 'abbreviation': 'Gn'},
      {'name': 'Exode', 'chapters': 40, 'abbreviation': 'Ex'},
      {'name': 'Lévitique', 'chapters': 27, 'abbreviation': 'Lv'},
      // ... autres livres
    ];
  }
  
  /// Récupère la taille estimée de la version
  static double _getBibleSize(String version) {
    const sizes = {
      'LSG': 2.5,
      'S21': 2.8,
      'NIV': 3.2,
      'ESV': 3.0,
      'KJV': 2.9,
    };
    return sizes[version] ?? 3.0;
  }
  
  /// Récupère un passage de Bible depuis le stockage local
  static Future<Map<String, dynamic>?> getBiblePassage({
    required String version,
    required String book,
    required int chapter,
    int? verse,
  }) async {
    if (!isBibleVersionAvailable(version)) {
      throw Exception('Version $version non disponible localement');
    }
    
    final bibleData = LocalStorageService.getBibleVersion(version);
    if (bibleData == null) {
      throw Exception('Données de la version $version corrompues');
    }
    
    // Simulation - remplacer par vraie récupération
    return {
      'version': version,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': 'Texte du passage...', // Remplacer par vrai texte
      'reference': verse != null ? '$book $chapter:$verse' : '$book $chapter',
    };
  }
  
  /// Récupère plusieurs passages
  static Future<List<Map<String, dynamic>>> getBiblePassages({
    required String version,
    required List<Map<String, dynamic>> references,
  }) async {
    final passages = <Map<String, dynamic>>[];
    
    for (final ref in references) {
      try {
        final passage = await getBiblePassage(
          version: version,
          book: ref['book'],
          chapter: ref['chapter'],
          verse: ref['verse'],
        );
        if (passage != null) {
          passages.add(passage);
        }
      } catch (e) {
        print('Erreur pour ${ref['book']} ${ref['chapter']}: $e');
      }
    }
    
    return passages;
  }
  
  /// Recherche dans la Bible locale
  static Future<List<Map<String, dynamic>>> searchBible({
    required String version,
    required String query,
  }) async {
    if (!isBibleVersionAvailable(version)) {
      throw Exception('Version $version non disponible localement');
    }
    
    // Simulation - remplacer par vraie recherche
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      {
        'book': 'Jean',
        'chapter': 3,
        'verse': 16,
        'text': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique...',
        'reference': 'Jean 3:16',
      },
      // ... autres résultats
    ];
  }
  
  /// Supprime une version de Bible locale
  static Future<void> removeBibleVersion(String version) async {
    // TODO: Implémenter la suppression via LocalStorageService
    print('🗑️ Version $version supprimée du stockage local');
  }
  
  /// Récupère les statistiques de stockage
  static Map<String, dynamic> getStorageStats() {
    final versions = LocalStorageService.getAvailableBibleVersions();
    double totalSize = 0;
    
    for (final version in versions) {
      final data = LocalStorageService.getBibleVersion(version);
      if (data != null) {
        totalSize += data['size_mb'] ?? 0;
      }
    }
    
    return {
      'available_versions': versions,
      'total_size_mb': totalSize,
      'count': versions.length,
    };
  }
  
  /// Vérifie les mises à jour disponibles (nécessite une connexion)
  static Future<List<String>> checkForUpdates() async {
    if (!await LocalStorageService.isOnline) {
      return []; // Pas de vérification offline
    }
    
    // Simulation - remplacer par vraie vérification
    await Future.delayed(const Duration(seconds: 1));
    
    final localVersions = LocalStorageService.getAvailableBibleVersions();
    final availableVersions = _bibleUrls.keys.toList();
    
    // Retourner les versions non téléchargées
    return availableVersions.where((v) => !localVersions.contains(v)).toList();
  }
}