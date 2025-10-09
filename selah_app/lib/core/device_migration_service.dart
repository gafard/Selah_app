import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/local_storage_service.dart';

/// Service d'export/import manuel pour migration entre appareils
/// 
/// Permet à l'utilisateur de :
/// 1. Exporter toutes ses données dans un fichier chiffré (.selah)
/// 2. Partager ce fichier via AirDrop, email, cloud, etc.
/// 3. Importer le fichier sur un nouvel appareil
/// 
/// Sécurité :
/// - Fichier chiffré AES-256 avec mot de passe utilisateur
/// - QR Code optionnel pour transfert local
/// - Vérification d'intégrité (SHA-256)
/// 
/// Format du fichier .selah :
/// ```json
/// {
///   "version": "1.0",
///   "encrypted_data": "base64...",
///   "encryption_iv": "base64...",
///   "data_hash": "sha256...",
///   "metadata": {
///     "export_date": "ISO8601",
///     "device_name": "iPhone 15",
///     "app_version": "1.0.0"
///   }
/// }
/// ```
class DeviceMigrationService {
  static const String _fileExtension = '.selah';
  static const String _exportVersion = '1.0';
  
  /// Exporte toutes les données dans un fichier chiffré
  /// 
  /// [password] : Mot de passe pour chiffrer le fichier
  /// [includeProgress] : Inclure la progression des plans (défaut: true)
  /// [deviceName] : Nom de l'appareil source (optionnel)
  /// 
  /// Retourne : Chemin du fichier exporté
  static Future<String> exportToFile({
    required String password,
    bool includeProgress = true,
    String? deviceName,
  }) async {
    print('📤 Export des données pour migration...');
    
    _validatePassword(password);
    
    try {
      // 1. Collecter toutes les données
      final exportData = await _collectExportData(
        includeProgress: includeProgress,
      );
      print('  📊 ${_countItems(exportData)} élément(s) à exporter');
      
      // 2. Chiffrer les données
      final encryptedResult = await _encryptData(
        data: exportData,
        password: password,
      );
      print('  🔒 Données chiffrées');
      
      // 3. Créer le fichier .selah
      final exportFile = await _createExportFile(
        encryptedData: encryptedResult['encrypted']!,
        iv: encryptedResult['iv']!,
        hash: encryptedResult['hash']!,
        deviceName: deviceName,
      );
      print('✅ Fichier exporté : ${exportFile.path}');
      
      return exportFile.path;
    } catch (e) {
      print('❌ Erreur lors de l\'export: $e');
      rethrow;
    }
  }
  
  /// Importe les données depuis un fichier .selah
  /// 
  /// [filePath] : Chemin du fichier .selah
  /// [password] : Mot de passe pour déchiffrer le fichier
  /// [overwrite] : Si true, écrase les données existantes (défaut: false)
  /// [merge] : Si true, fusionne avec les données existantes (défaut: true)
  /// 
  /// Retourne : Rapport d'import avec statistiques
  static Future<Map<String, dynamic>> importFromFile({
    required String filePath,
    required String password,
    bool overwrite = false,
    bool merge = true,
  }) async {
    print('📥 Import des données depuis $filePath...');
    
    try {
      // 1. Lire et valider le fichier
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Fichier non trouvé : $filePath');
      }
      
      final content = await file.readAsString();
      final fileData = jsonDecode(content) as Map<String, dynamic>;
      
      _validateFileFormat(fileData);
      print('  ✅ Format validé (version ${fileData['version']})');
      
      // 2. Déchiffrer les données
      final decryptedData = await _decryptData(
        encryptedData: fileData['encrypted_data'] as String,
        iv: fileData['encryption_iv'] as String,
        password: password,
      );
      print('  🔓 Données déchiffrées');
      
      // 3. Vérifier l'intégrité
      final expectedHash = fileData['data_hash'] as String;
      final actualHash = _hashData(jsonEncode(decryptedData));
      
      if (expectedHash != actualHash) {
        throw Exception('Intégrité du fichier compromise');
      }
      print('  ✅ Intégrité vérifiée');
      
      // 4. Importer les données
      final importReport = await _importData(
        data: decryptedData,
        overwrite: overwrite,
        merge: merge,
      );
      print('✅ Import terminé');
      
      return importReport;
    } catch (e) {
      print('❌ Erreur lors de l\'import: $e');
      rethrow;
    }
  }
  
  /// Partage le fichier d'export via Share Sheet (AirDrop, email, etc.)
  /// 
  /// [filePath] : Chemin du fichier à partager
  /// [message] : Message optionnel à joindre
  static Future<void> shareExportFile({
    required String filePath,
    String? message,
  }) async {
    print('📤 Partage du fichier d\'export...');
    
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Fichier non trouvé : $filePath');
      }
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: message ?? 'Backup Selah App - Fichier chiffré',
        subject: 'Migration Selah',
      );
      
      print('✅ Fichier partagé');
    } catch (e) {
      print('❌ Erreur lors du partage: $e');
      rethrow;
    }
  }
  
  /// Génère un QR Code pour transfert local rapide
  /// 
  /// [password] : Mot de passe pour chiffrer
  /// 
  /// Retourne : Données encodées pour QR Code (JSON base64)
  static Future<String> generateQRCodeData({
    required String password,
  }) async {
    print('📷 Génération QR Code pour transfert...');
    
    try {
      // Collecter données essentielles seulement (limite taille QR)
      final essentialData = await _collectEssentialData();
      
      // Chiffrer
      final encrypted = await _encryptData(
        data: essentialData,
        password: password,
      );
      
      // Encoder en JSON compact
      final qrData = {
        'v': _exportVersion,
        'd': encrypted['encrypted'],
        'i': encrypted['iv'],
        'h': encrypted['hash'],
      };
      
      final qrString = base64Url.encode(
        utf8.encode(jsonEncode(qrData)),
      );
      
      print('✅ QR Code généré (${qrString.length} chars)');
      return qrString;
    } catch (e) {
      print('❌ Erreur génération QR Code: $e');
      rethrow;
    }
  }
  
  /// Importe depuis un QR Code
  /// 
  /// [qrData] : Données scannées depuis le QR Code
  /// [password] : Mot de passe pour déchiffrer
  static Future<Map<String, dynamic>> importFromQRCode({
    required String qrData,
    required String password,
  }) async {
    print('📷 Import depuis QR Code...');
    
    try {
      // Décoder le QR
      final decodedBytes = base64Url.decode(qrData);
      final decodedJson = jsonDecode(utf8.decode(decodedBytes)) as Map<String, dynamic>;
      
      // Déchiffrer
      final decryptedData = await _decryptData(
        encryptedData: decodedJson['d'] as String,
        iv: decodedJson['i'] as String,
        password: password,
      );
      
      // Vérifier intégrité
      final expectedHash = decodedJson['h'] as String;
      final actualHash = _hashData(jsonEncode(decryptedData));
      
      if (expectedHash != actualHash) {
        throw Exception('QR Code corrompu');
      }
      
      // Importer
      final report = await _importData(
        data: decryptedData,
        overwrite: false,
        merge: true,
      );
      
      print('✅ Import QR Code terminé');
      return report;
    } catch (e) {
      print('❌ Erreur import QR Code: $e');
      rethrow;
    }
  }
  
  /// Obtient des informations sur un fichier d'export sans le déchiffrer
  /// 
  /// [filePath] : Chemin du fichier .selah
  /// 
  /// Retourne : Métadonnées du fichier
  static Future<Map<String, dynamic>> getExportFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final fileData = jsonDecode(content) as Map<String, dynamic>;
      
      return {
        'version': fileData['version'],
        'file_size': await file.length(),
        'metadata': fileData['metadata'],
        'created': DateTime.parse(
          (fileData['metadata'] as Map)['export_date'] as String,
        ),
      };
    } catch (e) {
      print('⚠️ Erreur lecture info fichier: $e');
      return {};
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ═══════════════════════════════════════════════════════════════════
  
  /// Collecte toutes les données à exporter
  static Future<Map<String, dynamic>> _collectExportData({
    required bool includeProgress,
  }) async {
    final data = <String, dynamic>{
      'user': LocalStorageService.getLocalUser(),
      'plans': LocalStorageService.getAllLocalPlans(),
      'active_plan_id': LocalStorageService.getActiveLocalPlanId(),
      'bible_version': LocalStorageService.getActiveBibleVersion(),
    };
    
    if (includeProgress) {
      // Collecter progression de tous les plans
      final plans = data['plans'] as List;
      final allProgress = <String, dynamic>{};
      
      for (final plan in plans) {
        final planId = plan['id'] as String;
        final progress = LocalStorageService.getPlanProgress(planId);
        if (progress.isNotEmpty) {
          allProgress[planId] = progress;
        }
      }
      
      data['progress'] = allProgress;
    }
    
    return data;
  }
  
  /// Collecte données essentielles seulement (pour QR Code)
  static Future<Map<String, dynamic>> _collectEssentialData() async {
    return {
      'user': LocalStorageService.getLocalUser(),
      'active_plan_id': LocalStorageService.getActiveLocalPlanId(),
      'bible_version': LocalStorageService.getActiveBibleVersion(),
    };
  }
  
  /// Compte le nombre total d'éléments
  static int _countItems(Map<String, dynamic> data) {
    int count = 0;
    
    if (data.containsKey('user') && data['user'] != null) count++;
    if (data.containsKey('plans')) {
      count += (data['plans'] as List).length;
    }
    if (data.containsKey('progress')) {
      final progress = data['progress'] as Map;
      for (final planProgress in progress.values) {
        count += (planProgress as Map).length;
      }
    }
    
    return count;
  }
  
  /// Chiffre les données
  static Future<Map<String, String>> _encryptData({
    required Map<String, dynamic> data,
    required String password,
  }) async {
    final key = encrypt.Key.fromUtf8(_deriveKey(password));
    final iv = encrypt.IV.fromSecureRandom(16);
    
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    
    final jsonData = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    
    return {
      'encrypted': encrypted.base64,
      'iv': iv.base64,
      'hash': _hashData(jsonData),
    };
  }
  
  /// Déchiffre les données
  static Future<Map<String, dynamic>> _decryptData({
    required String encryptedData,
    required String iv,
    required String password,
  }) async {
    try {
      final key = encrypt.Key.fromUtf8(_deriveKey(password));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      
      final decrypted = encrypter.decrypt64(
        encryptedData,
        iv: encrypt.IV.fromBase64(iv),
      );
      
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Mot de passe incorrect ou fichier corrompu');
    }
  }
  
  /// Crée le fichier .selah
  static Future<File> _createExportFile({
    required String encryptedData,
    required String iv,
    required String hash,
    String? deviceName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'selah_backup_$timestamp$_fileExtension';
    final file = File('${dir.path}/$fileName');
    
    final fileContent = jsonEncode({
      'version': _exportVersion,
      'encrypted_data': encryptedData,
      'encryption_iv': iv,
      'data_hash': hash,
      'metadata': {
        'export_date': DateTime.now().toIso8601String(),
        'device_name': deviceName ?? Platform.operatingSystem,
        'app_version': '1.0.0', // TODO: Package info
        'file_format': 'selah_encrypted',
      },
    });
    
    await file.writeAsString(fileContent);
    return file;
  }
  
  /// Importe les données
  static Future<Map<String, dynamic>> _importData({
    required Map<String, dynamic> data,
    required bool overwrite,
    required bool merge,
  }) async {
    int importedCount = 0;
    int skippedCount = 0;
    
    // Importer utilisateur
    if (data.containsKey('user') && data['user'] != null) {
      if (overwrite || !LocalStorageService.hasLocalUser()) {
        await LocalStorageService.saveLocalUser(
          Map<String, dynamic>.from(data['user']),
        );
        importedCount++;
      } else {
        skippedCount++;
      }
    }
    
    // Importer plans
    if (data.containsKey('plans')) {
      final plans = data['plans'] as List;
      for (final plan in plans) {
        final planMap = Map<String, dynamic>.from(plan);
        final planId = planMap['id'] as String;
        
        if (overwrite || LocalStorageService.getLocalPlan(planId) == null) {
          await LocalStorageService.saveLocalPlan(planId, planMap);
          importedCount++;
        } else if (merge) {
          // Fusionner avec les données existantes
          final existing = LocalStorageService.getLocalPlan(planId);
          final merged = {...?existing, ...planMap};
          await LocalStorageService.saveLocalPlan(planId, merged);
          importedCount++;
        } else {
          skippedCount++;
        }
      }
    }
    
    // Importer progression
    if (data.containsKey('progress')) {
      final allProgress = data['progress'] as Map;
      for (final entry in allProgress.entries) {
        final planId = entry.key;
        final progress = entry.value as Map;
        
        for (final dayEntry in progress.entries) {
          final dayIndex = int.parse(dayEntry.key);
          final dayProgress = Map<String, dynamic>.from(dayEntry.value);
          await LocalStorageService.saveDayProgress(planId, dayIndex, dayProgress);
          importedCount++;
        }
      }
    }
    
    // Plan actif
    if (data.containsKey('active_plan_id') && data['active_plan_id'] != null) {
      await LocalStorageService.setActiveLocalPlan(data['active_plan_id'] as String);
    }
    
    // Version Bible
    if (data.containsKey('bible_version') && data['bible_version'] != null) {
      await LocalStorageService.setActiveBibleVersion(data['bible_version'] as String);
    }
    
    return {
      'imported': importedCount,
      'skipped': skippedCount,
      'total': importedCount + skippedCount,
      'success': true,
    };
  }
  
  /// Valide le format du fichier
  static void _validateFileFormat(Map<String, dynamic> fileData) {
    if (!fileData.containsKey('version')) {
      throw Exception('Format de fichier invalide (version manquante)');
    }
    
    if (!fileData.containsKey('encrypted_data') || 
        !fileData.containsKey('encryption_iv') ||
        !fileData.containsKey('data_hash')) {
      throw Exception('Format de fichier invalide (données manquantes)');
    }
    
    final version = fileData['version'] as String;
    if (version != _exportVersion) {
      throw Exception('Version de fichier incompatible : $version');
    }
  }
  
  /// Dérive une clé depuis le mot de passe
  static String _deriveKey(String password) {
    var derived = password + 'selah_migration_v1';
    for (int i = 0; i < 10000; i++) {
      derived = sha256.convert(utf8.encode(derived)).toString();
    }
    return derived.substring(0, 32);
  }
  
  /// Calcule le hash SHA-256
  static String _hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
  
  /// Valide le mot de passe
  static void _validatePassword(String password) {
    if (password.length < 12) {
      throw Exception('Le mot de passe doit contenir au moins 12 caractères');
    }
  }
}

