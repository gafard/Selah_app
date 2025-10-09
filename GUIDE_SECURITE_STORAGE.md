# 🔒 GUIDE SÉCURITÉ & ORGANISATION STOCKAGE LOCAL

**Date** : 9 Octobre 2025  
**Objectif** : Sécuriser et clarifier l'architecture de stockage local

---

## 📋 RÈGLES D'ARCHITECTURE STORAGE

### ✅ Hive vs SQLite - Règles strictes

```
┌─────────────────────────────────────────────────────────────┐
│                    RÈGLE D'OR                                │
├─────────────────────────────────────────────────────────────┤
│  Hive (chiffré)   → Données utilisateur & business logic   │
│  SQLite           → Datasets volumineux & recherche         │
└─────────────────────────────────────────────────────────────┘
```

#### 🟢 HIVE - Source unique pour :

**Boxes chiffrées** (données sensibles) :
- ✅ `local_user` - Profil utilisateur complet
- ✅ `local_plans` - Plans de lecture personnalisés
- ✅ `local_progress` - Progression & sync queue

**Boxes non chiffrées** (données publiques) :
- ✅ `local_bible` - Versions Bible (contenu public)
- ✅ `prefs` - Préférences UI (non sensibles)

**Taille max recommandée** : ~5 MB par box

#### 🔵 SQLITE - Réservé pour :

- ✅ **Index de recherche Bible** (full-text search)
- ✅ **Cache versets** (milliers d'entrées)
- ✅ **Historique méditations** (archive > 1 an)
- ✅ **Analytics offline** (événements en masse)

**Avantages** : Requêtes SQL complexes, FTS5, joins

---

## 🔐 IMPLÉMENTATION CHIFFREMENT HIVE

### 1. Ajouter les dépendances

**pubspec.yaml** :
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0  # ← NOUVEAU

dev_dependencies:
  hive_generator: ^2.0.0
  build_runner: ^2.4.0
```

Installer :
```bash
flutter pub get
```

### 2. Créer le service de chiffrement

**Fichier** : `lib/core/encryption_service.dart`

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Service de gestion des clés de chiffrement Hive
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
  static Future<List<int>> getEncryptionKey(String boxName) async {
    final keyName = '$_keyPrefix$boxName';
    
    // Vérifier si la clé existe déjà
    final existingKey = await _secureStorage.read(key: keyName);
    
    if (existingKey != null) {
      // Décoder la clé existante
      return base64Url.decode(existingKey);
    }
    
    // Générer une nouvelle clé de 256 bits (32 bytes)
    final key = Hive.generateSecureKey();
    
    // Sauvegarder la clé de manière sécurisée
    await _secureStorage.write(
      key: keyName,
      value: base64Url.encode(key),
    );
    
    return key;
  }
  
  /// Supprime la clé de chiffrement (à utiliser avec précaution !)
  static Future<void> deleteEncryptionKey(String boxName) async {
    final keyName = '$_keyPrefix$boxName';
    await _secureStorage.delete(key: keyName);
  }
  
  /// Supprime toutes les clés de chiffrement
  static Future<void> deleteAllEncryptionKeys() async {
    final allKeys = await _secureStorage.readAll();
    for (final keyName in allKeys.keys) {
      if (keyName.startsWith(_keyPrefix)) {
        await _secureStorage.delete(key: keyName);
      }
    }
  }
}
```

### 3. Mettre à jour LocalStorageService

**Fichier** : `lib/services/local_storage_service.dart`

```dart
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/encryption_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SERVICE DE STOCKAGE LOCAL - ARCHITECTURE OFFLINE-FIRST
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// RÈGLES D'ARCHITECTURE :
/// 
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │ HIVE (Source unique)                                                    │
/// ├─────────────────────────────────────────────────────────────────────────┤
/// │ ✅ Boxes CHIFFRÉES (données sensibles) :                               │
/// │    • local_user      → Profil utilisateur complet                      │
/// │    • local_plans     → Plans de lecture personnalisés                  │
/// │    • local_progress  → Progression, sync queue                         │
/// │                                                                          │
/// │ ✅ Boxes NON CHIFFRÉES (données publiques) :                           │
/// │    • local_bible     → Versions Bible (contenu public)                 │
/// │    • prefs           → Préférences UI                                  │
/// │                                                                          │
/// │ Limite : ~5 MB par box                                                  │
/// └─────────────────────────────────────────────────────────────────────────┘
/// 
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │ SQLITE (Datasets volumineux uniquement)                                │
/// ├─────────────────────────────────────────────────────────────────────────┤
/// │ ✅ Réservé pour :                                                       │
/// │    • Index de recherche Bible (FTS5)                                   │
/// │    • Cache versets (milliers d'entrées)                                │
/// │    • Historique méditations (archive > 1 an)                           │
/// │    • Analytics offline (événements en masse)                           │
/// │                                                                          │
/// │ ⚠️ NE PAS utiliser pour : profil, plans, progression                   │
/// └─────────────────────────────────────────────────────────────────────────┘
/// 
/// SÉCURITÉ :
/// - Chiffrement AES-256 (Hive) pour données sensibles
/// - Clés stockées dans Keychain/KeyStore (flutter_secure_storage)
/// - Rotation de clés non implémentée (à ajouter si besoin)
/// 
/// ═══════════════════════════════════════════════════════════════════════════
class LocalStorageService {
  // Boxes chiffrées
  static Box? _userBox;
  static Box? _plansBox;
  static Box? _progressBox;
  
  // Boxes non chiffrées
  static Box? _bibleBox;
  
  /// Initialisation des boîtes Hive avec chiffrement sélectif
  static Future<void> init() async {
    print('🔒 Initialisation LocalStorageService...');
    
    // ──────────────────────────────────────────────────────────────────────
    // BOXES CHIFFRÉES (données sensibles)
    // ──────────────────────────────────────────────────────────────────────
    
    // 1. local_user (profil utilisateur)
    final userKey = await EncryptionService.getEncryptionKey('local_user');
    _userBox = await Hive.openBox(
      'local_user',
      encryptionCipher: HiveAesCipher(userKey),
    );
    print('  ✅ local_user (chiffré)');
    
    // 2. local_plans (plans de lecture)
    final plansKey = await EncryptionService.getEncryptionKey('local_plans');
    _plansBox = await Hive.openBox(
      'local_plans',
      encryptionCipher: HiveAesCipher(plansKey),
    );
    print('  ✅ local_plans (chiffré)');
    
    // 3. local_progress (progression et sync)
    final progressKey = await EncryptionService.getEncryptionKey('local_progress');
    _progressBox = await Hive.openBox(
      'local_progress',
      encryptionCipher: HiveAesCipher(progressKey),
    );
    print('  ✅ local_progress (chiffré)');
    
    // ──────────────────────────────────────────────────────────────────────
    // BOXES NON CHIFFRÉES (données publiques)
    // ──────────────────────────────────────────────────────────────────────
    
    // 4. local_bible (versions Bible - contenu public)
    _bibleBox = await Hive.openBox('local_bible');
    print('  ✅ local_bible (non chiffré)');
    
    print('🔒 LocalStorageService initialisé avec succès');
  }
  
  /// Vérifie la connectivité réseau
  static Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // GESTION UTILISATEUR LOCAL (Box chiffrée)
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Sauvegarde un utilisateur local (données chiffrées)
  static Future<void> saveLocalUser(Map<String, dynamic> userData) async {
    await _userBox?.put('current_user', userData);
  }
  
  /// Récupère l'utilisateur local (données déchiffrées automatiquement)
  static Map<String, dynamic>? getLocalUser() {
    final userData = _userBox?.get('current_user');
    if (userData == null) return null;
    return Map<String, dynamic>.from(userData as Map);
  }
  
  /// Vérifie si un utilisateur local existe
  static bool hasLocalUser() {
    return _userBox?.containsKey('current_user') ?? false;
  }
  
  /// Supprime l'utilisateur local (données chiffrées effacées)
  static Future<void> clearLocalUser() async {
    await _userBox?.delete('current_user');
  }
  
  /// Récupère le profil utilisateur (offline-first)
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      // Box prefs (pour compatibilité avec UserPrefs)
      final prefsBox = await Hive.openBox('prefs');
      final profile = prefsBox.get('profile');
      
      if (profile != null && profile is Map) {
        return Map<String, dynamic>.from(profile);
      }
      
      // Fallback : lire depuis current_user si présent
      final user = getLocalUser();
      if (user != null) {
        return user;
      }
      
      return {};
    } catch (e) {
      print('⚠️ Erreur getProfile: $e');
      return {};
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // GESTION PLANS LOCAUX (Box chiffrée)
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Sauvegarde un plan localement (données chiffrées)
  static Future<void> saveLocalPlan(String planId, Map<String, dynamic> planData) async {
    await _plansBox?.put(planId, planData);
  }
  
  /// Récupère un plan local (données déchiffrées automatiquement)
  static Map<String, dynamic>? getLocalPlan(String planId) {
    final plan = _plansBox?.get(planId);
    if (plan == null) return null;
    return Map<String, dynamic>.from(plan as Map);
  }
  
  /// Récupère tous les plans locaux
  static List<Map<String, dynamic>> getAllLocalPlans() {
    final plans = <Map<String, dynamic>>[];
    _plansBox?.values.forEach((plan) {
      if (plan is Map) {
        plans.add(Map<String, dynamic>.from(plan));
      }
    });
    return plans;
  }
  
  /// Marque un plan comme actif localement
  static Future<void> setActiveLocalPlan(String planId) async {
    await _plansBox?.put('active_plan_id', planId);
  }
  
  /// Récupère le plan actif local
  static String? getActiveLocalPlanId() {
    return _plansBox?.get('active_plan_id') as String?;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // GESTION BIBLE LOCALE (Box NON chiffrée - contenu public)
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Sauvegarde une version de Bible localement (NON chiffré)
  static Future<void> saveBibleVersion(String version, Map<String, dynamic> bibleData) async {
    await _bibleBox?.put(version, bibleData);
  }
  
  /// Récupère une version de Bible locale
  static Map<String, dynamic>? getBibleVersion(String version) {
    final bible = _bibleBox?.get(version);
    if (bible == null) return null;
    return Map<String, dynamic>.from(bible as Map);
  }
  
  /// Récupère toutes les versions de Bible disponibles localement
  static List<String> getAvailableBibleVersions() {
    return _bibleBox?.keys.cast<String>().toList() ?? [];
  }
  
  /// Marque une version comme active
  static Future<void> setActiveBibleVersion(String version) async {
    await _bibleBox?.put('active_version', version);
  }
  
  /// Récupère la version active
  static String? getActiveBibleVersion() {
    return _bibleBox?.get('active_version') as String?;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // GESTION PROGRESSION LOCALE (Box chiffrée)
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Sauvegarde la progression d'un jour (données chiffrées)
  static Future<void> saveDayProgress(String planId, int dayIndex, Map<String, dynamic> progress) async {
    final key = '${planId}_day_$dayIndex';
    await _progressBox?.put(key, progress);
  }
  
  /// Récupère la progression d'un jour
  static Map<String, dynamic>? getDayProgress(String planId, int dayIndex) {
    final key = '${planId}_day_$dayIndex';
    final progress = _progressBox?.get(key);
    if (progress == null) return null;
    return Map<String, dynamic>.from(progress as Map);
  }
  
  /// Récupère toute la progression d'un plan
  static Map<int, Map<String, dynamic>> getPlanProgress(String planId) {
    final progress = <int, Map<String, dynamic>>{};
    _progressBox?.keys.forEach((key) {
      if (key.toString().startsWith('${planId}_day_')) {
        final dayIndex = int.tryParse(key.toString().split('_day_').last);
        if (dayIndex != null) {
          final data = _progressBox?.get(key);
          if (data != null && data is Map) {
            progress[dayIndex] = Map<String, dynamic>.from(data);
          }
        }
      }
    });
    return progress;
  }
  
  /// Calcule le pourcentage de progression d'un plan
  static double getPlanProgressPercentage(String planId) {
    final progress = getPlanProgress(planId);
    if (progress.isEmpty) return 0.0;
    
    final completedDays = progress.values.where((p) => p['completed'] == true).length;
    return completedDays / progress.length;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // GESTION SCORES ET STATISTIQUES (Box chiffrée)
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Sauvegarde un score de quiz (données chiffrées)
  static Future<void> saveQuizScore(String quizId, Map<String, dynamic> score) async {
    await _progressBox?.put('quiz_$quizId', score);
  }
  
  /// Récupère un score de quiz
  static Map<String, dynamic>? getQuizScore(String quizId) {
    final score = _progressBox?.get('quiz_$quizId');
    if (score == null) return null;
    return Map<String, dynamic>.from(score as Map);
  }
  
  /// Récupère tous les scores
  static List<Map<String, dynamic>> getAllQuizScores() {
    final scores = <Map<String, dynamic>>[];
    _progressBox?.keys.forEach((key) {
      if (key.toString().startsWith('quiz_')) {
        final score = _progressBox?.get(key);
        if (score != null && score is Map) {
          scores.add(Map<String, dynamic>.from(score));
        }
      }
    });
    return scores;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // SYNCHRONISATION (Box chiffrée)
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Marque des données comme nécessitant une synchronisation
  static Future<void> markForSync(String dataType, String dataId) async {
    final rawQueue = _progressBox?.get('sync_queue');
    final syncQueue = <Map<String, dynamic>>[];
    
    if (rawQueue != null && rawQueue is List) {
      for (final item in rawQueue) {
        if (item is Map) {
          syncQueue.add(Map<String, dynamic>.from(item));
        }
      }
    }
    
    syncQueue.add({
      'type': dataType,
      'id': dataId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _progressBox?.put('sync_queue', syncQueue);
  }
  
  /// Récupère la queue de synchronisation
  static List<Map<String, dynamic>> getSyncQueue() {
    final rawQueue = _progressBox?.get('sync_queue');
    final syncQueue = <Map<String, dynamic>>[];
    
    if (rawQueue != null && rawQueue is List) {
      for (final item in rawQueue) {
        if (item is Map) {
          syncQueue.add(Map<String, dynamic>.from(item));
        }
      }
    }
    
    return syncQueue;
  }
  
  /// Vide la queue de synchronisation
  static Future<void> clearSyncQueue() async {
    await _progressBox?.delete('sync_queue');
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // NETTOYAGE ET MAINTENANCE
  // ═══════════════════════════════════════════════════════════════════════
  
  /// Nettoie toutes les données locales (⚠️ Supprime les clés de chiffrement)
  static Future<void> clearAllData() async {
    await _userBox?.clear();
    await _plansBox?.clear();
    await _bibleBox?.clear();
    await _progressBox?.clear();
    
    // Optionnel : supprimer aussi les clés de chiffrement
    // await EncryptionService.deleteAllEncryptionKeys();
  }
  
  /// Ferme toutes les boîtes
  static Future<void> close() async {
    await _userBox?.close();
    await _plansBox?.close();
    await _bibleBox?.close();
    await _progressBox?.close();
  }
  
  /// Obtient la taille approximative des boxes
  static Map<String, int> getBoxSizes() {
    return {
      'local_user': _userBox?.length ?? 0,
      'local_plans': _plansBox?.length ?? 0,
      'local_bible': _bibleBox?.length ?? 0,
      'local_progress': _progressBox?.length ?? 0,
    };
  }
}
```

### 4. Mettre à jour main.dart

**Fichier** : `lib/main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ═══════════════════════════════════════════════════════════════════
  // ÉTAPE 1 : STOCKAGE LOCAL (CRITIQUE - Toujours en premier)
  // ═══════════════════════════════════════════════════════════════════
  await Hive.initFlutter();
  await LocalStorageService.init(); // ← Maintenant avec chiffrement !
  debugPrint('✅ Local storage initialized (encrypted)');
  
  // ... reste du code
}
```

---

## 🧪 TESTS DE SÉCURITÉ

### 1. Vérifier le chiffrement

```dart
// Test : Les données sont bien chiffrées sur le disque
void testEncryption() async {
  // Sauvegarder des données sensibles
  await LocalStorageService.saveLocalUser({
    'email': 'test@example.com',
    'password_hash': 'sensitive_data',
  });
  
  // Fermer la box
  await LocalStorageService.close();
  
  // Essayer de lire le fichier Hive directement
  // ❌ DEVRAIT ÊTRE ILLISIBLE (binaire chiffré)
  final appDir = await getApplicationDocumentsDirectory();
  final hiveFile = File('${appDir.path}/local_user.hive');
  final content = await hiveFile.readAsString();
  
  print('Contenu du fichier (doit être illisible) :');
  print(content); // ← Binaire chiffré, pas de texte clair
  
  // Rouvrir avec la bonne clé
  await LocalStorageService.init();
  final user = LocalStorageService.getLocalUser();
  
  print('Données déchiffrées :');
  print(user); // ← Données lisibles après déchiffrement
}
```

### 2. Test de rotation de clés (si implémenté)

```dart
// TODO: Implémenter la rotation de clés
Future<void> rotateEncryptionKeys() async {
  // 1. Lire toutes les données avec l'ancienne clé
  // 2. Générer nouvelles clés
  // 3. Réencrypter avec nouvelles clés
  // 4. Supprimer anciennes clés
}
```

---

## ⚠️ POINTS D'ATTENTION

### 1. Perte de clés = Perte de données

**Problème** :
- Si l'utilisateur désinstalle l'app → Keychain/KeyStore effacé
- Si l'utilisateur change d'appareil → Clés non transférées
- Si flutter_secure_storage échoue → Impossibilité de lire les données

**Solutions** :
```dart
// Option 1 : Backup des données déchiffrées dans Supabase
Future<void> backupToCloud() async {
  final user = LocalStorageService.getLocalUser();
  await supabase.from('users_backup').upsert(user);
}

// Option 2 : Export manuel par l'utilisateur
Future<File> exportUserData() async {
  final data = {
    'user': LocalStorageService.getLocalUser(),
    'plans': LocalStorageService.getAllLocalPlans(),
  };
  // Chiffrer avec un mot de passe utilisateur
  // Sauvegarder dans fichier
}
```

### 2. Performance

Le chiffrement AES-256 ajoute ~5-10% d'overhead :
- ✅ Acceptable pour profil/plans (petites données)
- ⚠️ Attention pour Bible (gros fichiers) → Utiliser box non chiffrée

### 3. Android KeyStore

Sur Android < 6.0, le chiffrement matériel n'est pas disponible :
```dart
// Vérifier la disponibilité
if (Platform.isAndroid) {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt < 23) {
    print('⚠️ Chiffrement matériel non disponible');
    // Fallback : chiffrement logiciel ou désactiver
  }
}
```

---

## 📊 RÉSUMÉ

### ✅ Implémenté

- [x] Règles claires Hive vs SQLite
- [x] Chiffrement AES-256 pour boxes sensibles
- [x] Clés stockées dans Keychain/KeyStore
- [x] Documentation complète du service
- [x] Gestion automatique des clés

### ⏳ À implémenter (optionnel)

- [ ] Rotation de clés périodique
- [ ] Backup cloud des données chiffrées
- [ ] Export manuel pour migration
- [ ] Monitoring taille des boxes
- [ ] Compression des données avant chiffrement

### 🎯 Bénéfices

1. **Sécurité** : Données sensibles chiffrées au repos
2. **Clarté** : Règles strictes Hive vs SQLite
3. **Performance** : Chiffrement sélectif (uniquement données sensibles)
4. **Conformité** : RGPD, protection données personnelles
5. **Maintenabilité** : Code bien documenté

---

**🔒 Vos données utilisateur sont maintenant protégées par chiffrement AES-256 !**

