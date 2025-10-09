import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

/// Service de rotation automatique des clés de chiffrement
/// 
/// Rotation des clés tous les 90 jours (configurable) pour renforcer la sécurité.
/// 
/// Processus :
/// 1. Génère une nouvelle clé de chiffrement
/// 2. Décrypte toutes les données avec l'ancienne clé
/// 3. Recrypte toutes les données avec la nouvelle clé
/// 4. Supprime l'ancienne clé
/// 5. Met à jour la date de dernière rotation
class KeyRotationService {
  static const String _lastRotationPrefix = 'key_rotation_last_';
  static const int _rotationIntervalDays = 90; // 90 jours par défaut
  
  /// Vérifie si une rotation de clé est nécessaire pour une box
  /// 
  /// [boxName] : Nom de la box Hive
  /// [intervalDays] : Intervalle de rotation en jours (défaut: 90)
  /// 
  /// Retourne : true si rotation nécessaire, false sinon
  static Future<bool> needsRotation(
    String boxName, {
    int intervalDays = _rotationIntervalDays,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRotationKey = '$_lastRotationPrefix$boxName';
      final lastRotationTimestamp = prefs.getInt(lastRotationKey);
      
      if (lastRotationTimestamp == null) {
        // Jamais effectué de rotation, considérer comme nécessaire
        return true;
      }
      
      final lastRotation = DateTime.fromMillisecondsSinceEpoch(lastRotationTimestamp);
      final daysSinceRotation = DateTime.now().difference(lastRotation).inDays;
      
      return daysSinceRotation >= intervalDays;
    } catch (e) {
      print('⚠️ Erreur lors de la vérification de rotation pour $boxName: $e');
      return false;
    }
  }
  
  /// Effectue la rotation de clé pour une box
  /// 
  /// [boxName] : Nom de la box Hive
  /// [onProgress] : Callback optionnel pour suivre la progression (0.0 - 1.0)
  /// 
  /// Process :
  /// 1. Lit toutes les données avec l'ancienne clé
  /// 2. Génère une nouvelle clé
  /// 3. Réécrit toutes les données avec la nouvelle clé
  /// 4. Supprime l'ancienne clé
  static Future<void> rotateKey(
    String boxName, {
    Function(double progress)? onProgress,
  }) async {
    print('🔄 Rotation de clé pour $boxName...');
    
    try {
      // 1. Récupérer l'ancienne clé
      final oldKey = await EncryptionService.getEncryptionKey(boxName);
      onProgress?.call(0.1);
      
      // 2. Ouvrir la box avec l'ancienne clé
      final oldBox = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(oldKey),
      );
      onProgress?.call(0.2);
      
      // 3. Lire toutes les données
      final allData = <String, dynamic>{};
      final totalKeys = oldBox.keys.length;
      int processedKeys = 0;
      
      for (final key in oldBox.keys) {
        allData[key.toString()] = oldBox.get(key);
        processedKeys++;
        onProgress?.call(0.2 + (0.3 * processedKeys / totalKeys));
      }
      
      print('  📊 ${allData.length} élément(s) à ré-encrypter');
      
      // 4. Fermer et supprimer l'ancienne box
      await oldBox.close();
      await Hive.deleteBoxFromDisk(boxName);
      onProgress?.call(0.6);
      
      // 5. Supprimer l'ancienne clé de chiffrement
      await EncryptionService.deleteEncryptionKey(boxName);
      onProgress?.call(0.65);
      
      // 6. Générer une NOUVELLE clé
      final newKey = await EncryptionService.getEncryptionKey(boxName);
      onProgress?.call(0.7);
      
      // 7. Créer la box avec la nouvelle clé
      final newBox = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(newKey),
      );
      onProgress?.call(0.8);
      
      // 8. Réencrypter toutes les données avec la nouvelle clé
      processedKeys = 0;
      for (final entry in allData.entries) {
        await newBox.put(entry.key, entry.value);
        processedKeys++;
        onProgress?.call(0.8 + (0.15 * processedKeys / allData.length));
      }
      
      // 9. Fermer la nouvelle box
      await newBox.close();
      onProgress?.call(0.95);
      
      // 10. Enregistrer la date de rotation
      await _recordRotation(boxName);
      onProgress?.call(1.0);
      
      print('✅ Rotation de clé terminée pour $boxName');
    } catch (e) {
      print('❌ Erreur lors de la rotation de clé pour $boxName: $e');
      rethrow;
    }
  }
  
  /// Effectue la rotation pour toutes les boxes chiffrées
  /// 
  /// [onProgress] : Callback optionnel pour suivre la progression globale
  static Future<void> rotateAllKeys({
    Function(String boxName, double progress)? onProgress,
  }) async {
    print('🔄 Rotation de toutes les clés...');
    
    final boxesToRotate = ['local_user', 'local_plans', 'local_progress'];
    
    for (int i = 0; i < boxesToRotate.length; i++) {
      final boxName = boxesToRotate[i];
      
      try {
        await rotateKey(
          boxName,
          onProgress: (progress) {
            final globalProgress = (i + progress) / boxesToRotate.length;
            onProgress?.call(boxName, globalProgress);
          },
        );
      } catch (e) {
        print('❌ Erreur lors de la rotation de $boxName: $e');
        // Continuer avec les autres boxes même en cas d'erreur
      }
    }
    
    print('✅ Rotation de toutes les clés terminée');
  }
  
  /// Enregistre la date de dernière rotation
  static Future<void> _recordRotation(String boxName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRotationKey = '$_lastRotationPrefix$boxName';
      await prefs.setInt(lastRotationKey, DateTime.now().millisecondsSinceEpoch);
      print('  📅 Date de rotation enregistrée pour $boxName');
    } catch (e) {
      print('⚠️ Erreur lors de l\'enregistrement de la rotation: $e');
    }
  }
  
  /// Récupère la date de dernière rotation pour une box
  /// 
  /// [boxName] : Nom de la box Hive
  /// 
  /// Retourne : DateTime de la dernière rotation, ou null si jamais effectuée
  static Future<DateTime?> getLastRotationDate(String boxName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRotationKey = '$_lastRotationPrefix$boxName';
      final timestamp = prefs.getInt(lastRotationKey);
      
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      return null;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération de la date de rotation: $e');
      return null;
    }
  }
  
  /// Récupère les jours restants avant la prochaine rotation
  /// 
  /// [boxName] : Nom de la box Hive
  /// [intervalDays] : Intervalle de rotation en jours
  /// 
  /// Retourne : Nombre de jours restants, ou null si jamais effectuée
  static Future<int?> getDaysUntilNextRotation(
    String boxName, {
    int intervalDays = _rotationIntervalDays,
  }) async {
    final lastRotation = await getLastRotationDate(boxName);
    
    if (lastRotation == null) {
      return null; // Jamais effectué
    }
    
    final daysSinceRotation = DateTime.now().difference(lastRotation).inDays;
    final daysRemaining = intervalDays - daysSinceRotation;
    
    return daysRemaining.clamp(0, intervalDays);
  }
  
  /// Vérifie et effectue automatiquement la rotation si nécessaire
  /// 
  /// À appeler au démarrage de l'app ou périodiquement
  /// 
  /// [intervalDays] : Intervalle de rotation en jours (défaut: 90)
  /// [onProgress] : Callback optionnel pour suivre la progression
  static Future<void> checkAndRotateIfNeeded({
    int intervalDays = _rotationIntervalDays,
    Function(String boxName, double progress)? onProgress,
  }) async {
    print('🔍 Vérification de la nécessité de rotation...');
    
    final boxesToCheck = ['local_user', 'local_plans', 'local_progress'];
    final boxesNeedingRotation = <String>[];
    
    // Vérifier quelles boxes ont besoin de rotation
    for (final boxName in boxesToCheck) {
      if (await needsRotation(boxName, intervalDays: intervalDays)) {
        boxesNeedingRotation.add(boxName);
      }
    }
    
    if (boxesNeedingRotation.isEmpty) {
      print('✅ Aucune rotation nécessaire');
      return;
    }
    
    print('📋 ${boxesNeedingRotation.length} box(es) nécessitent une rotation');
    
    // Effectuer la rotation pour chaque box
    for (int i = 0; i < boxesNeedingRotation.length; i++) {
      final boxName = boxesNeedingRotation[i];
      
      try {
        await rotateKey(
          boxName,
          onProgress: (progress) {
            final globalProgress = (i + progress) / boxesNeedingRotation.length;
            onProgress?.call(boxName, globalProgress);
          },
        );
      } catch (e) {
        print('❌ Erreur lors de la rotation de $boxName: $e');
      }
    }
  }
  
  /// Obtient un rapport de status de rotation pour toutes les boxes
  /// 
  /// Retourne : Map<String, Map<String, dynamic>> avec les informations de rotation
  static Future<Map<String, Map<String, dynamic>>> getRotationStatus() async {
    final boxes = ['local_user', 'local_plans', 'local_progress'];
    final status = <String, Map<String, dynamic>>{};
    
    for (final boxName in boxes) {
      final lastRotation = await getLastRotationDate(boxName);
      final daysUntilNext = await getDaysUntilNextRotation(boxName);
      final needs = await needsRotation(boxName);
      
      status[boxName] = {
        'lastRotation': lastRotation?.toIso8601String(),
        'daysUntilNext': daysUntilNext,
        'needsRotation': needs,
        'daysSinceRotation': lastRotation != null 
          ? DateTime.now().difference(lastRotation).inDays 
          : null,
      };
    }
    
    return status;
  }
  
  /// Force la rotation immédiate (pour tests ou maintenance)
  /// 
  /// [boxName] : Nom de la box à forcer la rotation
  static Future<void> forceRotation(String boxName) async {
    print('⚡ Force rotation pour $boxName...');
    await rotateKey(boxName);
  }
}

