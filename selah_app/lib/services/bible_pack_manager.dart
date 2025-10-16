import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Gestionnaire des packs bibliques ZIP
/// 
/// Gère l'extraction et l'intégration des packs :
/// - ISBE (International Standard Bible Encyclopedia)
/// - OpenBible Themes
/// - Strong's Concordance
/// - Treasury of Scripture Knowledge (TSK)
class BiblePackManager {
  static const String _packsDir = 'assets/packs_real';
  
  /// Packs disponibles
  static const Map<String, Map<String, String>> _availablePacks = {
    'isbe': {
      'name': 'International Standard Bible Encyclopedia',
      'file': 'context.isbe.zip',
      'dbName': 'context.sqlite',
      'description': 'Encyclopédie biblique complète'
    },
    'openbible_themes': {
      'name': 'OpenBible Themes',
      'file': 'themes.openbible.zip',
      'dbName': 'themes.sqlite',
      'description': 'Thèmes spirituels OpenBible'
    },
    'strongs': {
      'name': 'Strong\'s Concordance',
      'file': 'lexicon.strongs.zip',
      'dbName': 'lexicon.sqlite',
      'description': 'Lexique grec/hébreu Strong'
    },
    'tsk': {
      'name': 'Treasury of Scripture Knowledge',
      'file': 'refs.tsk.zip',
      'dbName': 'crossrefs.sqlite',
      'description': 'Références croisées TSK'
    }
  };

  /// Vérifie si un pack est déjà extrait
  static Future<bool> isPackExtracted(String packId) async {
    try {
      final packInfo = _availablePacks[packId];
      if (packInfo == null) return false;
      
      final dbPath = await _getPackDbPath(packId);
      return await File(dbPath).exists();
    } catch (e) {
      print('⚠️ Erreur vérification pack $packId: $e');
      return false;
    }
  }

  /// Extrait un pack ZIP
  static Future<bool> extractPack(String packId) async {
    try {
      final packInfo = _availablePacks[packId];
      if (packInfo == null) {
        print('❌ Pack $packId non trouvé');
        return false;
      }

      print('📦 Extraction du pack ${packInfo['name']}...');
      
      // Vérifier si déjà extrait
      if (await isPackExtracted(packId)) {
        print('✅ Pack $packId déjà extrait');
        return true;
      }

      // 🌐 COMPATIBILITÉ WEB - Désactiver l'extraction sur le web
      if (kIsWeb) {
        print('⚠️ Extraction des packs désactivée sur le web (offline-first maintenu via assets)');
        return false;
      }

      // Créer le répertoire de destination
      final destDir = await _getPacksDirectory();
      await destDir.create(recursive: true);

      // Chemin du fichier ZIP
      final zipPath = path.join(
        Directory.current.path,
        'assets',
        'packs_real',
        packInfo['file']!
      );

      if (!await File(zipPath).exists()) {
        print('❌ Fichier ZIP non trouvé: $zipPath');
        return false;
      }

      // Extraire le ZIP
      final result = await Process.run('unzip', [
        '-o', // Overwrite
        zipPath,
        '-d', destDir.path
      ]);

      if (result.exitCode != 0) {
        print('❌ Erreur extraction: ${result.stderr}');
        return false;
      }

      // Vérifier l'extraction
      final dbPath = await _getPackDbPath(packId);
      if (await File(dbPath).exists()) {
        print('✅ Pack $packId extrait avec succès');
        return true;
      } else {
        print('❌ Base de données non trouvée après extraction');
        return false;
      }

    } catch (e) {
      print('❌ Erreur extraction pack $packId: $e');
      return false;
    }
  }

  /// Extrait tous les packs disponibles
  static Future<Map<String, bool>> extractAllPacks() async {
    final results = <String, bool>{};
    
    for (final packId in _availablePacks.keys) {
      print('📦 Extraction du pack $packId...');
      results[packId] = await extractPack(packId);
    }
    
    return results;
  }

  /// Récupère la base de données d'un pack
  static Future<Database?> getPackDatabase(String packId) async {
    try {
      if (!await isPackExtracted(packId)) {
        print('⚠️ Pack $packId non extrait, tentative d\'extraction...');
        final extracted = await extractPack(packId);
        if (!extracted) return null;
      }

      final dbPath = await _getPackDbPath(packId);
      return await openDatabase(dbPath, readOnly: true);
    } catch (e) {
      print('❌ Erreur ouverture base pack $packId: $e');
      return null;
    }
  }

  /// Récupère le manifest d'un pack
  static Future<Map<String, dynamic>?> getPackManifest(String packId) async {
    try {
      final packInfo = _availablePacks[packId];
      if (packInfo == null) return null;

      final manifestPath = path.join(
        (await _getPacksDirectory()).path,
        'manifest.json'
      );

      if (!await File(manifestPath).exists()) return null;

      final content = await File(manifestPath).readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ Erreur lecture manifest $packId: $e');
      return null;
    }
  }

  /// Récupère les informations sur tous les packs
  static Map<String, Map<String, String>> getAvailablePacks() {
    return Map.from(_availablePacks);
  }

  /// Récupère le répertoire des packs extraits
  static Future<Directory> _getPacksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'bible_packs'));
  }

  /// Récupère le chemin de la base de données d'un pack
  static Future<String> _getPackDbPath(String packId) async {
    final packInfo = _availablePacks[packId];
    if (packInfo == null) throw Exception('Pack $packId non trouvé');
    
    final packsDir = await _getPacksDirectory();
    return path.join(packsDir.path, packInfo['dbName']!);
  }

  /// Supprime un pack extrait
  static Future<bool> removePack(String packId) async {
    try {
      final dbPath = await _getPackDbPath(packId);
      final file = File(dbPath);
      
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Pack $packId supprimé');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur suppression pack $packId: $e');
      return false;
    }
  }

  /// Récupère les statistiques des packs
  static Future<Map<String, dynamic>> getPackStats() async {
    final stats = <String, dynamic>{
      'total': _availablePacks.length,
      'extracted': 0,
      'packs': <String, Map<String, dynamic>>{}
    };

    for (final packId in _availablePacks.keys) {
      final packInfo = _availablePacks[packId]!;
      final isExtracted = await isPackExtracted(packId);
      
      if (isExtracted) stats['extracted']++;
      
      stats['packs'][packId] = {
        'name': packInfo['name'],
        'description': packInfo['description'],
        'extracted': isExtracted,
        'size': isExtracted ? await _getPackSize(packId) : 0,
      };
    }

    return stats;
  }

  /// Récupère la taille d'un pack extrait
  static Future<int> _getPackSize(String packId) async {
    try {
      final dbPath = await _getPackDbPath(packId);
      final file = File(dbPath);
      return await file.exists() ? await file.length() : 0;
    } catch (e) {
      return 0;
    }
  }
}
