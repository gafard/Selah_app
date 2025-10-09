# 🔄 GUIDE DE MIGRATION - Chiffrement Hive

**Objectif** : Migrer de Hive non chiffré vers Hive chiffré sans perte de données

---

## 📋 ÉTAPES DE MIGRATION

### 1. Installer les nouvelles dépendances

```bash
flutter pub add flutter_secure_storage:^9.0.0
flutter pub get
```

### 2. Créer le service de chiffrement

Créer le fichier : `lib/core/encryption_service.dart`
(Le code est déjà fourni dans `GUIDE_SECURITE_STORAGE.md`)

### 3. Migration des données existantes

**Fichier** : `lib/core/storage_migration.dart`

```dart
import 'package:hive/hive.dart';
import 'encryption_service.dart';
import '../services/local_storage_service.dart';

/// Service de migration des données Hive non chiffrées vers chiffrées
class StorageMigration {
  
  /// Migre toutes les boxes vers le chiffrement
  static Future<void> migrateToEncryption() async {
    print('🔄 Démarrage migration vers chiffrement...');
    
    try {
      // 1. Migrer local_user
      await _migrateBox('local_user');
      
      // 2. Migrer local_plans
      await _migrateBox('local_plans');
      
      // 3. Migrer local_progress
      await _migrateBox('local_progress');
      
      print('✅ Migration terminée avec succès !');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }
  
  /// Migre une box individuelle
  static Future<void> _migrateBox(String boxName) async {
    print('  📦 Migration de $boxName...');
    
    try {
      // 1. Ouvrir la box non chiffrée existante
      final oldBox = await Hive.openBox(boxName);
      
      // 2. Récupérer toutes les données
      final allData = <String, dynamic>{};
      for (final key in oldBox.keys) {
        allData[key.toString()] = oldBox.get(key);
      }
      
      print('    📊 ${allData.length} élément(s) à migrer');
      
      // 3. Fermer et supprimer l'ancienne box
      await oldBox.close();
      await Hive.deleteBoxFromDisk(boxName);
      print('    🗑️ Ancienne box supprimée');
      
      // 4. Générer une clé de chiffrement
      final encryptionKey = await EncryptionService.getEncryptionKey(boxName);
      
      // 5. Créer la nouvelle box chiffrée
      final newBox = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      
      // 6. Restaurer toutes les données dans la box chiffrée
      for (final entry in allData.entries) {
        await newBox.put(entry.key, entry.value);
      }
      
      print('    ✅ $boxName migrée avec succès (${allData.length} éléments)');
      
      // 7. Fermer la nouvelle box
      await newBox.close();
      
    } catch (e) {
      print('    ❌ Erreur lors de la migration de $boxName: $e');
      rethrow;
    }
  }
  
  /// Vérifie si une migration est nécessaire
  static Future<bool> needsMigration() async {
    try {
      // Vérifier si les clés de chiffrement existent
      final hasUserKey = await EncryptionService.hasEncryptionKey('local_user');
      final hasPlansKey = await EncryptionService.hasEncryptionKey('local_plans');
      final hasProgressKey = await EncryptionService.hasEncryptionKey('local_progress');
      
      // Si au moins une clé manque, migration nécessaire
      return !hasUserKey || !hasPlansKey || !hasProgressKey;
    } catch (e) {
      print('⚠️ Erreur lors de la vérification de migration: $e');
      return true; // Par sécurité, supposer qu'une migration est nécessaire
    }
  }
  
  /// Crée un backup avant migration
  static Future<String> createBackup() async {
    print('💾 Création backup avant migration...');
    
    final backup = <String, dynamic>{};
    
    try {
      // Backup local_user
      final userBox = await Hive.openBox('local_user');
      backup['local_user'] = userBox.toMap();
      await userBox.close();
      
      // Backup local_plans
      final plansBox = await Hive.openBox('local_plans');
      backup['local_plans'] = plansBox.toMap();
      await plansBox.close();
      
      // Backup local_progress
      final progressBox = await Hive.openBox('local_progress');
      backup['local_progress'] = progressBox.toMap();
      await progressBox.close();
      
      // Sauvegarder en JSON
      final json = jsonEncode(backup);
      final file = File('${(await getApplicationDocumentsDirectory()).path}/hive_backup.json');
      await file.writeAsString(json);
      
      print('✅ Backup créé : ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ Erreur lors de la création du backup: $e');
      rethrow;
    }
  }
  
  /// Restaure depuis un backup
  static Future<void> restoreFromBackup(String backupPath) async {
    print('📥 Restauration depuis backup...');
    
    try {
      final file = File(backupPath);
      final json = await file.readAsString();
      final backup = jsonDecode(json) as Map<String, dynamic>;
      
      // Restaurer local_user
      if (backup.containsKey('local_user')) {
        final userBox = await Hive.openBox('local_user');
        final userData = backup['local_user'] as Map<String, dynamic>;
        for (final entry in userData.entries) {
          await userBox.put(entry.key, entry.value);
        }
        await userBox.close();
        print('  ✅ local_user restauré');
      }
      
      // Restaurer local_plans
      if (backup.containsKey('local_plans')) {
        final plansBox = await Hive.openBox('local_plans');
        final plansData = backup['local_plans'] as Map<String, dynamic>;
        for (final entry in plansData.entries) {
          await plansBox.put(entry.key, entry.value);
        }
        await plansBox.close();
        print('  ✅ local_plans restauré');
      }
      
      // Restaurer local_progress
      if (backup.containsKey('local_progress')) {
        final progressBox = await Hive.openBox('local_progress');
        final progressData = backup['local_progress'] as Map<String, dynamic>;
        for (final entry in progressData.entries) {
          await progressBox.put(entry.key, entry.value);
        }
        await progressBox.close();
        print('  ✅ local_progress restauré');
      }
      
      print('✅ Restauration terminée !');
    } catch (e) {
      print('❌ Erreur lors de la restauration: $e');
      rethrow;
    }
  }
}
```

### 4. Mettre à jour main.dart

**Fichier** : `lib/main.dart`

```dart
import 'core/storage_migration.dart';
import 'core/encryption_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ═══════════════════════════════════════════════════════════════════
  // ÉTAPE 1 : STOCKAGE LOCAL avec MIGRATION
  // ═══════════════════════════════════════════════════════════════════
  
  await Hive.initFlutter();
  
  // Vérifier si migration nécessaire
  final needsMigration = await StorageMigration.needsMigration();
  
  if (needsMigration) {
    debugPrint('🔄 Migration vers chiffrement nécessaire...');
    
    // Créer un backup par sécurité
    try {
      final backupPath = await StorageMigration.createBackup();
      debugPrint('💾 Backup créé : $backupPath');
      
      // Effectuer la migration
      await StorageMigration.migrateToEncryption();
      debugPrint('✅ Migration terminée avec succès !');
    } catch (e) {
      debugPrint('❌ Erreur de migration : $e');
      // En cas d'erreur, continuer sans chiffrement
      // ou restaurer le backup
    }
  }
  
  // Initialiser avec chiffrement
  await LocalStorageService.init();
  debugPrint('✅ Local storage initialized (encrypted)');
  
  // ... reste du code
}
```

---

## 🧪 TESTS DE MIGRATION

### Test 1 : Migration simple

```dart
void testSimpleMigration() async {
  // 1. Créer des données test non chiffrées
  await Hive.initFlutter();
  final testBox = await Hive.openBox('local_user');
  await testBox.put('current_user', {
    'id': 'test123',
    'email': 'test@example.com',
  });
  await testBox.close();
  
  // 2. Effectuer la migration
  await StorageMigration.migrateToEncryption();
  
  // 3. Vérifier que les données sont accessibles et chiffrées
  await LocalStorageService.init();
  final user = LocalStorageService.getLocalUser();
  
  assert(user != null);
  assert(user['id'] == 'test123');
  print('✅ Migration réussie !');
}
```

### Test 2 : Backup et restauration

```dart
void testBackupRestore() async {
  // 1. Créer un backup
  final backupPath = await StorageMigration.createBackup();
  
  // 2. Supprimer toutes les boxes
  await Hive.deleteBoxFromDisk('local_user');
  await Hive.deleteBoxFromDisk('local_plans');
  await Hive.deleteBoxFromDisk('local_progress');
  
  // 3. Restaurer depuis le backup
  await StorageMigration.restoreFromBackup(backupPath);
  
  // 4. Vérifier les données
  await LocalStorageService.init();
  final user = LocalStorageService.getLocalUser();
  
  assert(user != null);
  print('✅ Backup/Restore réussi !');
}
```

---

## ⚠️ PRÉCAUTIONS

### 1. Perte de clés

**Si l'utilisateur désinstalle l'app** :
- ❌ Les clés de chiffrement sont perdues (Keychain/KeyStore effacé)
- ❌ Les données chiffrées deviennent inaccessibles

**Solution** :
```dart
// Backup cloud automatique avant désinstallation
Future<void> backupToSupabase() async {
  final user = LocalStorageService.getLocalUser();
  final plans = LocalStorageService.getAllLocalPlans();
  
  await supabase.from('user_backups').upsert({
    'user_id': user['id'],
    'backup_data': {
      'user': user,
      'plans': plans,
    },
    'created_at': DateTime.now().toIso8601String(),
  });
}
```

### 2. Migration échouée

**Si la migration échoue** :
- Le backup permet de restaurer
- L'app peut continuer sans chiffrement (mode dégradé)

```dart
try {
  await StorageMigration.migrateToEncryption();
} catch (e) {
  // Restaurer le backup
  await StorageMigration.restoreFromBackup(backupPath);
  
  // Continuer sans chiffrement
  debugPrint('⚠️ Fonctionnement en mode non chiffré');
}
```

### 3. Performance

**Impact du chiffrement** :
- Lecture : +5-10% de temps
- Écriture : +10-15% de temps

**Optimisation** :
```dart
// Batch writes pour réduire l'overhead
await _plansBox?.putAll({
  'plan1': plan1Data,
  'plan2': plan2Data,
  'plan3': plan3Data,
});
```

---

## 📊 CHECKLIST DE MIGRATION

### Avant migration
- [ ] Tester sur appareil de développement
- [ ] Créer backup automatique
- [ ] Vérifier disponibilité flutter_secure_storage
- [ ] Tester sur Android < 6.0 (si supporté)

### Pendant migration
- [ ] Logger toutes les étapes
- [ ] Gérer les erreurs proprement
- [ ] Ne pas bloquer l'UI
- [ ] Afficher progression à l'utilisateur

### Après migration
- [ ] Vérifier accès aux données
- [ ] Tester lecture/écriture
- [ ] Vérifier les clés dans Keychain/KeyStore
- [ ] Supprimer l'ancien backup (optionnel)

---

## 🚀 DÉPLOIEMENT

### Version 1.1.0 (avec chiffrement)

1. **Mettre à jour pubspec.yaml** :
   ```yaml
   version: 1.1.0+2
   ```

2. **Release notes** :
   ```
   v1.1.0
   - 🔒 Chiffrement AES-256 des données utilisateur
   - 🔄 Migration automatique des données existantes
   - 🛡️ Sécurité renforcée (Keychain/KeyStore)
   ```

3. **Migration automatique** :
   - Détection automatique au démarrage
   - Backup avant migration
   - Pas d'action utilisateur requise

4. **Rollback plan** :
   - Version 1.0.x reste disponible
   - Backup Supabase automatique
   - Instructions de restauration

---

**✅ Votre application est maintenant prête pour le chiffrement !**

