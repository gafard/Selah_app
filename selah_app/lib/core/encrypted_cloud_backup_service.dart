import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import 'encryption_service.dart';

/// Service de backup cloud chiffré dans Supabase
/// 
/// Architecture de sécurité :
/// 1. Les données sont chiffrées LOCALEMENT avant l'upload
/// 2. Chiffrement AES-256-CBC avec clé dérivée du mot de passe utilisateur
/// 3. Supabase ne stocke que les données chiffrées (zero-knowledge)
/// 4. Seul l'utilisateur avec son mot de passe peut déchiffrer
/// 
/// Table Supabase requise :
/// ```sql
/// CREATE TABLE encrypted_backups (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
///   backup_type TEXT NOT NULL, -- 'full', 'user', 'plans', 'progress'
///   encrypted_data TEXT NOT NULL, -- Données chiffrées en base64
///   encryption_iv TEXT NOT NULL, -- IV pour AES-CBC
///   data_hash TEXT NOT NULL, -- Hash SHA-256 pour vérifier intégrité
///   device_id TEXT, -- Identifiant de l'appareil source
///   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
///   metadata JSONB DEFAULT '{}'
/// );
/// 
/// CREATE INDEX idx_backups_user_id ON encrypted_backups(user_id);
/// CREATE INDEX idx_backups_created_at ON encrypted_backups(created_at DESC);
/// ```
class EncryptedCloudBackupService {
  static final _supabase = Supabase.instance.client;
  
  /// Crée un backup complet chiffré dans le cloud
  /// 
  /// [password] : Mot de passe pour chiffrer les données (fourni par l'utilisateur)
  /// [deviceId] : Identifiant unique de l'appareil (optionnel)
  /// 
  /// Le mot de passe doit être :
  /// - Au moins 12 caractères
  /// - Contenir majuscules, minuscules, chiffres, symboles
  /// 
  /// Retourne : ID du backup dans Supabase
  static Future<String> createFullBackup({
    required String password,
    String? deviceId,
  }) async {
    print('☁️ Création backup cloud chiffré...');
    
    _validatePassword(password);
    
    try {
      // 1. Récupérer toutes les données locales
      final backupData = await _collectAllData();
      print('  📊 ${backupData.length} élément(s) à sauvegarder');
      
      // 2. Chiffrer les données
      final encryptedResult = await _encryptData(
        data: backupData,
        password: password,
      );
      print('  🔒 Données chiffrées (${encryptedResult['encrypted'].length} chars)');
      
      // 3. Uploader dans Supabase
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }
      
      final response = await _supabase.from('encrypted_backups').insert({
        'user_id': userId,
        'backup_type': 'full',
        'encrypted_data': encryptedResult['encrypted'],
        'encryption_iv': encryptedResult['iv'],
        'data_hash': encryptedResult['hash'],
        'device_id': deviceId ?? 'unknown',
        'metadata': {
          'app_version': '1.0.0', // TODO: Récupérer depuis package_info
          'platform': 'flutter',
          'timestamp': DateTime.now().toIso8601String(),
        },
      }).select().single();
      
      final backupId = response['id'] as String;
      print('✅ Backup créé avec succès: $backupId');
      
      return backupId;
    } catch (e) {
      print('❌ Erreur lors de la création du backup: $e');
      rethrow;
    }
  }
  
  /// Restaure un backup depuis le cloud
  /// 
  /// [backupId] : ID du backup à restaurer
  /// [password] : Mot de passe pour déchiffrer les données
  /// [overwrite] : Si true, écrase les données locales existantes (défaut: true)
  /// 
  /// Retourne : Map<String, dynamic> avec les données restaurées
  static Future<Map<String, dynamic>> restoreBackup({
    required String backupId,
    required String password,
    bool overwrite = true,
  }) async {
    print('📥 Restauration backup $backupId...');
    
    try {
      // 1. Récupérer le backup depuis Supabase
      final response = await _supabase
          .from('encrypted_backups')
          .select()
          .eq('id', backupId)
          .single();
      
      print('  📦 Backup récupéré');
      
      // 2. Déchiffrer les données
      final decryptedData = await _decryptData(
        encryptedData: response['encrypted_data'] as String,
        iv: response['encryption_iv'] as String,
        password: password,
      );
      print('  🔓 Données déchiffrées');
      
      // 3. Vérifier l'intégrité
      final expectedHash = response['data_hash'] as String;
      final actualHash = _hashData(jsonEncode(decryptedData));
      
      if (expectedHash != actualHash) {
        throw Exception('Intégrité du backup compromise (hash mismatch)');
      }
      print('  ✅ Intégrité vérifiée');
      
      // 4. Restaurer les données locales
      if (overwrite) {
        await _restoreLocalData(decryptedData);
        print('  💾 Données restaurées localement');
      }
      
      print('✅ Restauration terminée avec succès');
      return decryptedData;
    } catch (e) {
      print('❌ Erreur lors de la restauration: $e');
      rethrow;
    }
  }
  
  /// Liste tous les backups disponibles pour l'utilisateur
  /// 
  /// Retourne : List<Map<String, dynamic>> avec les infos des backups
  static Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }
      
      final response = await _supabase
          .from('encrypted_backups')
          .select('id, backup_type, device_id, created_at, metadata')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur lors de la liste des backups: $e');
      return [];
    }
  }
  
  /// Supprime un backup du cloud
  /// 
  /// [backupId] : ID du backup à supprimer
  static Future<void> deleteBackup(String backupId) async {
    print('🗑️ Suppression backup $backupId...');
    
    try {
      await _supabase.from('encrypted_backups').delete().eq('id', backupId);
      print('✅ Backup supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      rethrow;
    }
  }
  
  /// Crée un backup automatique périodique
  /// 
  /// [password] : Mot de passe pour chiffrer (stocké temporairement en mémoire)
  /// [intervalDays] : Intervalle en jours entre chaque backup (défaut: 7)
  /// 
  /// À appeler au démarrage ou périodiquement
  static Future<void> autoBackupIfNeeded({
    required String password,
    int intervalDays = 7,
  }) async {
    try {
      final backups = await listBackups();
      
      if (backups.isEmpty) {
        // Aucun backup, créer le premier
        print('🔄 Création du premier backup automatique...');
        await createFullBackup(password: password);
        return;
      }
      
      // Vérifier la date du dernier backup
      final lastBackup = backups.first;
      final lastBackupDate = DateTime.parse(lastBackup['created_at'] as String);
      final daysSinceBackup = DateTime.now().difference(lastBackupDate).inDays;
      
      if (daysSinceBackup >= intervalDays) {
        print('🔄 Backup automatique nécessaire (dernier: il y a $daysSinceBackup jours)');
        await createFullBackup(password: password);
      } else {
        print('✅ Backup récent trouvé (il y a $daysSinceBackup jours)');
      }
    } catch (e) {
      print('⚠️ Erreur lors du backup automatique: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES - Chiffrement/Déchiffrement
  // ═══════════════════════════════════════════════════════════════════
  
  /// Collecte toutes les données locales à sauvegarder
  static Future<Map<String, dynamic>> _collectAllData() async {
    return {
      'user': LocalStorageService.getLocalUser(),
      'plans': LocalStorageService.getAllLocalPlans(),
      'active_plan_id': LocalStorageService.getActiveLocalPlanId(),
      'sync_queue': LocalStorageService.getSyncQueue(),
      'bible_version': LocalStorageService.getActiveBibleVersion(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Chiffre les données avec AES-256-CBC
  /// 
  /// Dérive une clé de chiffrement depuis le mot de passe avec PBKDF2
  static Future<Map<String, String>> _encryptData({
    required Map<String, dynamic> data,
    required String password,
  }) async {
    // 1. Dériver une clé depuis le mot de passe (PBKDF2)
    final salt = 'selah_backup_salt_v1'; // Salt fixe pour reproductibilité
    final key = encrypt.Key.fromUtf8(
      _deriveKey(password, salt, keyLength: 32) // 32 bytes = 256 bits
    );
    
    // 2. Générer un IV aléatoire
    final iv = encrypt.IV.fromSecureRandom(16); // 16 bytes pour AES
    
    // 3. Créer l'encrypter
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    
    // 4. Chiffrer les données JSON
    final jsonData = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    
    // 5. Calculer le hash pour vérification d'intégrité
    final dataHash = _hashData(jsonData);
    
    return {
      'encrypted': encrypted.base64,
      'iv': iv.base64,
      'hash': dataHash,
    };
  }
  
  /// Déchiffre les données
  static Future<Map<String, dynamic>> _decryptData({
    required String encryptedData,
    required String iv,
    required String password,
  }) async {
    try {
      // 1. Dériver la même clé depuis le mot de passe
      final salt = 'selah_backup_salt_v1';
      final key = encrypt.Key.fromUtf8(
        _deriveKey(password, salt, keyLength: 32)
      );
      
      // 2. Créer l'encrypter avec l'IV fourni
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      
      // 3. Déchiffrer
      final decrypted = encrypter.decrypt64(
        encryptedData,
        iv: encrypt.IV.fromBase64(iv),
      );
      
      // 4. Parser le JSON
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Déchiffrement échoué - Mot de passe incorrect ou données corrompues');
    }
  }
  
  /// Dérive une clé de chiffrement depuis un mot de passe (PBKDF2 simplifié)
  static String _deriveKey(String password, String salt, {int keyLength = 32}) {
    // Simple dérivation avec hash itératif
    // En production, utiliser package:pointycastle pour PBKDF2 complet
    var derived = password + salt;
    
    for (int i = 0; i < 10000; i++) {
      derived = sha256.convert(utf8.encode(derived)).toString();
    }
    
    return derived.substring(0, keyLength);
  }
  
  /// Calcule le hash SHA-256 des données pour vérification d'intégrité
  static String _hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
  
  /// Restaure les données locales depuis le backup
  static Future<void> _restoreLocalData(Map<String, dynamic> backupData) async {
    // Restaurer l'utilisateur
    if (backupData.containsKey('user') && backupData['user'] != null) {
      await LocalStorageService.saveLocalUser(
        Map<String, dynamic>.from(backupData['user']),
      );
    }
    
    // Restaurer les plans
    if (backupData.containsKey('plans') && backupData['plans'] != null) {
      final plans = backupData['plans'] as List;
      for (final plan in plans) {
        final planMap = Map<String, dynamic>.from(plan);
        await LocalStorageService.saveLocalPlan(
          planMap['id'] as String,
          planMap,
        );
      }
    }
    
    // Restaurer le plan actif
    if (backupData.containsKey('active_plan_id') && backupData['active_plan_id'] != null) {
      await LocalStorageService.setActiveLocalPlan(
        backupData['active_plan_id'] as String,
      );
    }
    
    // Restaurer la version Bible active
    if (backupData.containsKey('bible_version') && backupData['bible_version'] != null) {
      await LocalStorageService.setActiveBibleVersion(
        backupData['bible_version'] as String,
      );
    }
  }
  
  /// Valide le mot de passe (sécurité minimale)
  static void _validatePassword(String password) {
    if (password.length < 12) {
      throw Exception('Le mot de passe doit contenir au moins 12 caractères');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw Exception('Le mot de passe doit contenir au moins une majuscule');
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      throw Exception('Le mot de passe doit contenir au moins une minuscule');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw Exception('Le mot de passe doit contenir au moins un chiffre');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      throw Exception('Le mot de passe doit contenir au moins un symbole');
    }
  }
}


