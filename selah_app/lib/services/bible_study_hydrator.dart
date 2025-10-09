import 'dart:convert';
import 'package:flutter/services.dart';
import 'bible_context_service.dart';
import 'cross_ref_service.dart';
import 'lexicon_service.dart';
import 'themes_service.dart';
import 'mirror_verse_service.dart';

/// Service d'hydratation des données d'étude biblique
/// 
/// Responsabilités :
/// 1. Charger les JSON depuis assets/jsons/
/// 2. Hydrater les boxes Hive au premier lancement
/// 3. Vérifier si l'hydratation est nécessaire
/// 
/// Fichiers JSON attendus :
/// - assets/jsons/context_historical.json
/// - assets/jsons/context_cultural.json
/// - assets/jsons/authors.json
/// - assets/jsons/characters.json
/// - assets/jsons/crossrefs.json
/// - assets/jsons/lexicon.json
/// - assets/jsons/themes.json
/// - assets/jsons/mirrors.json
class BibleStudyHydrator {
  
  /// Vérifie si l'hydratation initiale est nécessaire
  /// 
  /// Retourne : true si c'est le premier lancement (boxes vides)
  static Future<bool> needsHydration() async {
    try {
      // Vérifier si au moins une box est vide
      final themesBox = await Hive.openBox('bible_themes');
      final isEmpty = themesBox.isEmpty;
      
      print(isEmpty 
        ? '💧 Hydratation nécessaire (premier lancement)'
        : '✅ Données déjà hydratées');
      
      return isEmpty;
    } catch (e) {
      print('⚠️ Erreur needsHydration: $e');
      return true; // Par sécurité, ré-hydrater
    }
  }
  
  /// Hydrate toutes les boxes depuis les assets
  /// 
  /// [onProgress] : Callback de progression (0.0 - 1.0)
  /// 
  /// À appeler au premier lancement de l'app
  static Future<void> hydrateAll({
    Function(double progress, String currentFile)? onProgress,
  }) async {
    print('💧 Démarrage hydratation complète...');
    
    try {
      // 1. Contexte historique
      onProgress?.call(0.0, 'Contexte historique');
      final historical = await _loadJson('assets/jsons/context_historical.json');
      
      // 2. Contexte culturel
      onProgress?.call(0.125, 'Contexte culturel');
      final cultural = await _loadJson('assets/jsons/context_cultural.json');
      
      // 3. Auteurs
      onProgress?.call(0.25, 'Auteurs');
      final authors = await _loadJson('assets/jsons/authors.json');
      
      // 4. Personnages
      onProgress?.call(0.375, 'Personnages');
      final characters = await _loadJson('assets/jsons/characters.json');
      
      // 5. Références croisées
      onProgress?.call(0.5, 'Références croisées');
      final crossrefs = await _loadJson('assets/jsons/crossrefs.json');
      await CrossRefService.hydrateFromAssets(crossrefs);
      
      // 6. Lexique
      onProgress?.call(0.625, 'Lexique grec/hébreu');
      final lexicon = await _loadJson('assets/jsons/lexicon.json');
      await LexiconService.hydrateFromAssets(lexicon);
      
      // 7. Thèmes
      onProgress?.call(0.75, 'Thèmes spirituels');
      final themes = await _loadJson('assets/jsons/themes.json');
      await ThemesService.hydrateFromAssets(themes);
      
      // 8. Versets miroirs
      onProgress?.call(0.875, 'Versets miroirs');
      final mirrors = await _loadJson('assets/jsons/mirrors.json');
      await _hydrateMirrors(mirrors);
      
      // 9. Contexte (combiné)
      onProgress?.call(0.95, 'Finalisation');
      await BibleContextService.hydrateFromAssets(
        historicalData: historical,
        culturalData: cultural,
        authorsData: authors,
        charactersData: characters,
      );
      
      onProgress?.call(1.0, 'Terminé');
      
      // Marquer comme hydraté
      final prefs = await Hive.openBox('prefs');
      await prefs.put('bible_study_hydrated', true);
      await prefs.put('hydration_date', DateTime.now().toIso8601String());
      
      print('✅ Hydratation complète terminée');
    } catch (e) {
      print('❌ Erreur lors de l\'hydratation: $e');
      rethrow;
    }
  }
  
  /// Charge un fichier JSON depuis les assets
  static Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ Fichier $assetPath non trouvé ou invalide: $e');
      print('   → Utilisation de données par défaut');
      return {}; // Retourner map vide en cas d'erreur
    }
  }
  
  /// Hydrate la box mirrors
  static Future<void> _hydrateMirrors(Map<String, dynamic> mirrorsData) async {
    final mirrorsBox = await Hive.openBox('bible_mirrors');
    
    int count = 0;
    for (final entry in mirrorsData.entries) {
      await mirrorsBox.put(entry.key, entry.value);
      count++;
    }
    
    print('✅ $count entrées hydratées dans bible_mirrors');
  }
  
  /// Réinitialise toutes les données (pour debug/maintenance)
  /// 
  /// ⚠️ ATTENTION : Supprime toutes les données d'étude !
  static Future<void> resetAll() async {
    print('🗑️ Réinitialisation de toutes les données d\'étude...');
    
    try {
      final boxes = [
        'bible_context',
        'bible_crossrefs',
        'bible_lexicon',
        'bible_themes',
        'bible_mirrors',
        'bible_versions_meta',
        'reading_mem',
      ];
      
      for (final boxName in boxes) {
        final box = await Hive.openBox(boxName);
        await box.clear();
        print('  🗑️ $boxName vidée');
      }
      
      // Réinitialiser le flag d'hydratation
      final prefs = await Hive.openBox('prefs');
      await prefs.delete('bible_study_hydrated');
      
      print('✅ Réinitialisation terminée');
    } catch (e) {
      print('❌ Erreur resetAll: $e');
    }
  }
  
  /// Obtient les statistiques d'hydratation
  /// 
  /// Retourne : Map avec le nombre d'entrées par box
  static Future<Map<String, int>> getHydrationStats() async {
    final stats = <String, int>{};
    
    try {
      stats['bible_context'] = (await Hive.openBox('bible_context')).length;
      stats['bible_crossrefs'] = (await Hive.openBox('bible_crossrefs')).length;
      stats['bible_lexicon'] = (await Hive.openBox('bible_lexicon')).length;
      stats['bible_themes'] = (await Hive.openBox('bible_themes')).length;
      stats['bible_mirrors'] = (await Hive.openBox('bible_mirrors')).length;
      stats['reading_mem'] = (await Hive.openBox('reading_mem')).length;
      
      print('📊 Stats hydratation:');
      stats.forEach((box, count) {
        print('   $box: $count entrées');
      });
    } catch (e) {
      print('⚠️ Erreur getHydrationStats: $e');
    }
    
    return stats;
  }
}

