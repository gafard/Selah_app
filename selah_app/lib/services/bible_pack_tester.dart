import 'bible_pack_manager.dart';
import 'isbe_service.dart';
import 'openbible_themes_service.dart';

/// Service de test pour valider l'intégration des packs bibliques
class BiblePackTester {
  
  /// Teste l'extraction et l'accès à tous les packs
  static Future<Map<String, dynamic>> testAllPacks() async {
    print('🧪 Démarrage des tests des packs bibliques...');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'packs': <String, Map<String, dynamic>>{},
      'summary': <String, dynamic>{}
    };
    
    // 1. Test des statistiques des packs
    print('📊 Test des statistiques...');
    final stats = await BiblePackManager.getPackStats();
    results['summary']['total_packs'] = stats['total'];
    results['summary']['extracted_packs'] = stats['extracted'];
    
    // 2. Test de chaque pack
    final availablePacks = BiblePackManager.getAvailablePacks();
    
    for (final packId in availablePacks.keys) {
      print('🔍 Test du pack $packId...');
      final packResult = await _testPack(packId);
      results['packs'][packId] = packResult;
    }
    
    // 3. Test des services spécialisés
    print('🔧 Test des services spécialisés...');
    results['services'] = await _testSpecializedServices();
    
    // 4. Résumé final
    results['summary']['success_rate'] = _calculateSuccessRate(results['packs']);
    results['summary']['status'] = results['summary']['success_rate'] > 0.8 ? 'SUCCESS' : 'PARTIAL';
    
    print('✅ Tests terminés - Taux de réussite: ${(results['summary']['success_rate'] * 100).toStringAsFixed(1)}%');
    
    return results;
  }
  
  /// Teste un pack spécifique
  static Future<Map<String, dynamic>> _testPack(String packId) async {
    final result = <String, dynamic>{
      'pack_id': packId,
      'extracted': false,
      'database_accessible': false,
      'manifest_available': false,
      'sample_data': null,
      'error': null
    };
    
    try {
      // Test d'extraction
      result['extracted'] = await BiblePackManager.isPackExtracted(packId);
      
      if (!result['extracted']) {
        print('📦 Extraction du pack $packId...');
        result['extracted'] = await BiblePackManager.extractPack(packId);
      }
      
      if (result['extracted']) {
        // Test d'accès à la base
        final database = await BiblePackManager.getPackDatabase(packId);
        result['database_accessible'] = database != null;
        
        // Test du manifest
        final manifest = await BiblePackManager.getPackManifest(packId);
        result['manifest_available'] = manifest != null;
        
        // Test de données d'exemple
        if (database != null) {
          result['sample_data'] = await _getSampleData(packId, database);
        }
      }
      
    } catch (e) {
      result['error'] = e.toString();
      print('❌ Erreur test pack $packId: $e');
    }
    
    return result;
  }
  
  /// Récupère des données d'exemple d'un pack
  static Future<Map<String, dynamic>?> _getSampleData(String packId, dynamic database) async {
    try {
      switch (packId) {
        case 'isbe':
          final entries = await database.query('entries', limit: 3);
          return {'table': 'entries', 'count': entries.length, 'sample': entries.firstOrNull};
          
        case 'openbible_themes':
          final themes = await database.query('themes', limit: 3);
          return {'table': 'themes', 'count': themes.length, 'sample': themes.firstOrNull};
          
        case 'strongs':
          final lexicon = await database.query('lexicon', limit: 3);
          return {'table': 'lexicon', 'count': lexicon.length, 'sample': lexicon.firstOrNull};
          
        case 'tsk':
          final crossrefs = await database.query('crossrefs', limit: 3);
          return {'table': 'crossrefs', 'count': crossrefs.length, 'sample': crossrefs.firstOrNull};
          
        default:
          // Essayer de lister les tables
          final tables = await database.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table'"
          );
          return {'tables': tables.map((t) => t['name']).toList()};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Teste les services spécialisés
  static Future<Map<String, dynamic>> _testSpecializedServices() async {
    final results = <String, dynamic>{};
    
    // Test ISBE Service
    try {
      results['isbe'] = {
        'available': ISBEService.isAvailable,
        'categories': await ISBEService.getCategories(),
        'sample_search': await ISBEService.searchEntries('jesus'),
      };
    } catch (e) {
      results['isbe'] = {'error': e.toString()};
    }
    
    // Test OpenBible Themes Service
    try {
      results['openbible_themes'] = {
        'available': OpenBibleThemesService.isAvailable,
        'categories': await OpenBibleThemesService.getCategories(),
        'popular_themes': await OpenBibleThemesService.getPopularThemes(limit: 5),
      };
    } catch (e) {
      results['openbible_themes'] = {'error': e.toString()};
    }
    
    return results;
  }
  
  /// Calcule le taux de réussite
  static double _calculateSuccessRate(Map<String, dynamic> packs) {
    if (packs.isEmpty) return 0.0;
    
    int successful = 0;
    for (final pack in packs.values) {
      final packData = pack as Map<String, dynamic>;
      if (packData['extracted'] == true && packData['database_accessible'] == true) {
        successful++;
      }
    }
    
    return successful / packs.length;
  }
  
  /// Génère un rapport de test
  static String generateTestReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('📋 RAPPORT DE TEST DES PACKS BIBLIQUES');
    buffer.writeln('=' * 50);
    buffer.writeln('Timestamp: ${results['timestamp']}');
    buffer.writeln('Statut: ${results['summary']['status']}');
    buffer.writeln('Taux de réussite: ${(results['summary']['success_rate'] * 100).toStringAsFixed(1)}%');
    buffer.writeln('Packs extraits: ${results['summary']['extracted_packs']}/${results['summary']['total_packs']}');
    buffer.writeln();
    
    // Détails par pack
    buffer.writeln('📦 DÉTAILS PAR PACK:');
    buffer.writeln('-' * 30);
    
    final packs = results['packs'] as Map<String, dynamic>;
    for (final entry in packs.entries) {
      final packId = entry.key;
      final packData = entry.value as Map<String, dynamic>;
      
      buffer.writeln('Pack: $packId');
      buffer.writeln('  ✅ Extrait: ${packData['extracted']}');
      buffer.writeln('  ✅ Base accessible: ${packData['database_accessible']}');
      buffer.writeln('  ✅ Manifest disponible: ${packData['manifest_available']}');
      
      if (packData['sample_data'] != null) {
        final sample = packData['sample_data'] as Map<String, dynamic>;
        buffer.writeln('  📊 Données d\'exemple: ${sample['count']} entrées');
      }
      
      if (packData['error'] != null) {
        buffer.writeln('  ❌ Erreur: ${packData['error']}');
      }
      
      buffer.writeln();
    }
    
    // Services spécialisés
    if (results['services'] != null) {
      buffer.writeln('🔧 SERVICES SPÉCIALISÉS:');
      buffer.writeln('-' * 30);
      
      final services = results['services'] as Map<String, dynamic>;
      for (final entry in services.entries) {
        final serviceName = entry.key;
        final serviceData = entry.value as Map<String, dynamic>;
        
        buffer.writeln('Service: $serviceName');
        buffer.writeln('  ✅ Disponible: ${serviceData['available']}');
        
        if (serviceData['categories'] != null) {
          final categories = serviceData['categories'] as List;
          buffer.writeln('  📂 Catégories: ${categories.length}');
        }
        
        if (serviceData['error'] != null) {
          buffer.writeln('  ❌ Erreur: ${serviceData['error']}');
        }
        
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }
}
