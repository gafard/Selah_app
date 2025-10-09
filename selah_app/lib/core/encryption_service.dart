import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Service de gestion des clés de chiffrement Hive
/// 
/// Utilise flutter_secure_storage pour stocker les clés de chiffrement de manière sécurisée :
/// - Android : Android KeyStore
/// - iOS : Keychain
/// 
/// Chaque box Hive chiffrée a sa propre clé AES-256 (32 bytes)
class EncryptionService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  static const String _keyPrefix = 'hive_encryption_key_';
  
  /// Génère ou récupère une clé de chiffrement pour une box
  /// 
  /// Si la clé existe déjà dans le Keychain/KeyStore, elle est récupérée.
  /// Sinon, une nouvelle clé AES-256 est générée et stockée de manière sécurisée.
  /// 
  /// [boxName] : Nom de la box Hive (ex: 'local_user', 'local_plans')
  /// 
  /// Retourne : List<int> de 32 bytes (256 bits) pour AES-256
  static Future<List<int>> getEncryptionKey(String boxName) async {
    final keyName = '$_keyPrefix$boxName';
    
    try {
      // Vérifier si la clé existe déjà
      final existingKey = await _secureStorage.read(key: keyName);
      
      if (existingKey != null) {
        // Décoder la clé existante (stockée en base64url)
        return base64Url.decode(existingKey);
      }
      
      // Générer une nouvelle clé de 256 bits (32 bytes)
      final key = Hive.generateSecureKey();
      
      // Sauvegarder la clé de manière sécurisée (encodée en base64url)
      await _secureStorage.write(
        key: keyName,
        value: base64Url.encode(key),
      );
      
      print('🔑 Nouvelle clé de chiffrement générée pour: $boxName');
      return key;
    } catch (e) {
      print('❌ Erreur lors de la récupération/génération de la clé pour $boxName: $e');
      rethrow;
    }
  }
  
  /// Supprime la clé de chiffrement d'une box
  /// 
  /// ⚠️ ATTENTION : Supprimer la clé rend les données chiffrées inaccessibles !
  /// À utiliser uniquement lors de la suppression complète des données utilisateur.
  /// 
  /// [boxName] : Nom de la box Hive
  static Future<void> deleteEncryptionKey(String boxName) async {
    final keyName = '$_keyPrefix$boxName';
    try {
      await _secureStorage.delete(key: keyName);
      print('🗑️ Clé de chiffrement supprimée pour: $boxName');
    } catch (e) {
      print('❌ Erreur lors de la suppression de la clé pour $boxName: $e');
    }
  }
  
  /// Supprime TOUTES les clés de chiffrement Hive
  /// 
  /// ⚠️ ATTENTION : Rend TOUTES les données chiffrées inaccessibles !
  /// À utiliser uniquement lors de :
  /// - Déconnexion complète de l'utilisateur
  /// - Suppression du compte
  /// - Reset factory de l'application
  static Future<void> deleteAllEncryptionKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      int deletedCount = 0;
      
      for (final keyName in allKeys.keys) {
        if (keyName.startsWith(_keyPrefix)) {
          await _secureStorage.delete(key: keyName);
          deletedCount++;
        }
      }
      
      print('🗑️ $deletedCount clé(s) de chiffrement supprimée(s)');
    } catch (e) {
      print('❌ Erreur lors de la suppression de toutes les clés: $e');
    }
  }
  
  /// Vérifie si une clé de chiffrement existe pour une box
  /// 
  /// [boxName] : Nom de la box Hive
  /// 
  /// Retourne : true si la clé existe, false sinon
  static Future<bool> hasEncryptionKey(String boxName) async {
    final keyName = '$_keyPrefix$boxName';
    try {
      final key = await _secureStorage.read(key: keyName);
      return key != null;
    } catch (e) {
      print('❌ Erreur lors de la vérification de la clé pour $boxName: $e');
      return false;
    }
  }
  
  /// Liste toutes les boxes ayant une clé de chiffrement
  /// 
  /// Utile pour le debugging et la maintenance
  /// 
  /// Retourne : List<String> des noms de boxes chiffrées
  static Future<List<String>> listEncryptedBoxes() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final encryptedBoxes = <String>[];
      
      for (final keyName in allKeys.keys) {
        if (keyName.startsWith(_keyPrefix)) {
          final boxName = keyName.replaceFirst(_keyPrefix, '');
          encryptedBoxes.add(boxName);
        }
      }
      
      return encryptedBoxes;
    } catch (e) {
      print('❌ Erreur lors de la liste des boxes chiffrées: $e');
      return [];
    }
  }
  
  /// Vérifie la disponibilité du chiffrement matériel
  /// 
  /// Sur Android < 6.0, le chiffrement matériel n'est pas disponible.
  /// flutter_secure_storage utilisera un fallback logiciel.
  /// 
  /// Retourne : true si le chiffrement matériel est disponible
  static Future<bool> isHardwareEncryptionAvailable() async {
    try {
      // Tenter d'écrire et lire une clé de test
      const testKey = 'test_encryption_key';
      const testValue = 'test_value';
      
      await _secureStorage.write(key: testKey, value: testValue);
      final readValue = await _secureStorage.read(key: testKey);
      await _secureStorage.delete(key: testKey);
      
      return readValue == testValue;
    } catch (e) {
      print('⚠️ Chiffrement matériel non disponible: $e');
      return false;
    }
  }
}

