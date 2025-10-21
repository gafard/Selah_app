import 'package:flutter/services.dart';
import 'dart:convert';
import 'bible_study_hydrator.dart';

/// Service pour forcer l'hydratation des services bibliques
class ForceHydrationService {
  
  /// Force l'hydratation de tous les services bibliques
  static Future<void> forceHydration() async {
    print('🔄 FORÇAGE DE L\'HYDRATATION DES SERVICES BIBLIQUES');
    print('================================================');
    
    try {
      // 1. Réinitialiser tous les services
      print('🗑️ Réinitialisation des services...');
      await BibleStudyHydrator.resetAll();
      
      // 2. Charger les données depuis les assets
      print('📚 Chargement des données depuis les assets...');
      
      // Charger les données JSON depuis les assets
      final historicalData = await _loadJsonAsset('assets/data/thomson_analysis.json');
      final culturalData = await _loadJsonAsset('assets/data/thomson_analysis.json');
      final authorsData = await _loadJsonAsset('assets/data/thomson_analysis.json');
      final charactersData = await _loadJsonAsset('assets/data/thomson_characters_enriched.json');
      final crossrefsData = await _loadJsonAsset('assets/jsons/crossrefs.json');
      final lexiconData = await _loadJsonAsset('assets/jsons/lexicon.json');
      final themesData = await _loadJsonAsset('assets/jsons/themes.json');
      final mirrorsData = await _loadJsonAsset('assets/jsons/mirrors.json');
      
      // 3. Hydrater tous les services
      print('💧 Hydratation des services...');
      await BibleStudyHydrator.hydrateAll(
        onProgress: (progress, file) {
          print('  ${(progress * 100).toInt()}% - $file');
        },
      );
      
      // 4. Vérifier les statistiques
      print('📊 Vérification des statistiques...');
      final stats = await BibleStudyHydrator.getHydrationStats();
      stats.forEach((box, count) {
        print('  $box: $count entrées');
      });
      
      print('✅ Hydratation forcée terminée avec succès');
      
    } catch (e) {
      print('❌ Erreur lors de l\'hydratation forcée: $e');
      rethrow;
    }
  }
  
  /// Charge un fichier JSON depuis les assets
  static Future<Map<String, dynamic>> _loadJsonAsset(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      return json.decode(jsonString);
    } catch (e) {
      print('⚠️ Erreur chargement $path: $e');
      return {}; // Retourner un objet vide en cas d'erreur
    }
  }
  
  /// Vérifie si l'hydratation est nécessaire
  static Future<bool> needsHydration() async {
    return await BibleStudyHydrator.needsHydration();
  }
  
  /// Obtient les statistiques d'hydratation
  static Future<Map<String, int>> getStats() async {
    return await BibleStudyHydrator.getHydrationStats();
  }
}
