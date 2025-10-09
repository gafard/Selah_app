# 🔐 GUIDE - Fonctionnalités de Sécurité Avancées

**Date** : 9 Octobre 2025  
**Services implémentés** :
1. Rotation automatique des clés de chiffrement
2. Backup cloud chiffré dans Supabase
3. Export/Import manuel pour migration d'appareil

---

## 📋 TABLE DES MATIÈRES

1. [Rotation automatique des clés](#1-rotation-automatique-des-clés)
2. [Backup cloud chiffré](#2-backup-cloud-chiffré)
3. [Migration entre appareils](#3-migration-entre-appareils)
4. [Intégration complète](#4-intégration-complète)
5. [Tests](#5-tests)

---

## 1. ROTATION AUTOMATIQUE DES CLÉS

### 🎯 Objectif

Renouveler périodiquement les clés de chiffrement pour renforcer la sécurité (tous les 90 jours par défaut).

### 📝 Utilisation de base

```dart
import 'package:selah_app/core/key_rotation_service.dart';

// Au démarrage de l'app
void initApp() async {
  // Vérifier et effectuer la rotation si nécessaire
  await KeyRotationService.checkAndRotateIfNeeded(
    intervalDays: 90, // Rotation tous les 90 jours
    onProgress: (boxName, progress) {
      print('Rotation $boxName : ${(progress * 100).toInt()}%');
    },
  );
}
```

### 🔄 Rotation manuelle

```dart
// Forcer la rotation d'une box spécifique
await KeyRotationService.forceRotation('local_user');

// Ou toutes les boxes
await KeyRotationService.rotateAllKeys(
  onProgress: (boxName, progress) {
    setState(() {
      _rotationProgress[boxName] = progress;
    });
  },
);
```

### 📊 Vérifier le status

```dart
// Obtenir le status de rotation
final status = await KeyRotationService.getRotationStatus();

print('Status rotation:');
status.forEach((boxName, info) {
  print('$boxName:');
  print('  Dernière rotation: ${info['lastRotation']}');
  print('  Jours restants: ${info['daysUntilNext']}');
  print('  Rotation nécessaire: ${info['needsRotation']}');
});
```

### 🎨 UI - Afficher le status

```dart
class RotationStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: KeyRotationService.getRotationStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        return ListView(
          children: snapshot.data!.entries.map((entry) {
            final boxName = entry.key;
            final info = entry.value;
            final daysUntilNext = info['daysUntilNext'] ?? 0;
            final needsRotation = info['needsRotation'] ?? false;
            
            return ListTile(
              title: Text(boxName),
              subtitle: Text(
                needsRotation 
                  ? 'Rotation recommandée' 
                  : '$daysUntilNext jours restants'
              ),
              trailing: needsRotation 
                ? Icon(Icons.warning, color: Colors.orange)
                : Icon(Icons.check_circle, color: Colors.green),
            );
          }).toList(),
        );
      },
    );
  }
}
```

### ⏰ Rotation automatique planifiée

```dart
import 'package:workmanager/workmanager.dart';

// Enregistrer une tâche de rotation périodique
void scheduleKeyRotation() {
  Workmanager().registerPeriodicTask(
    'key-rotation',
    'keyRotationTask',
    frequency: Duration(days: 30), // Vérifier tous les 30 jours
  );
}

// Callback Workmanager
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'keyRotationTask') {
      await KeyRotationService.checkAndRotateIfNeeded();
    }
    return Future.value(true);
  });
}
```

---

## 2. BACKUP CLOUD CHIFFRÉ

### 🎯 Objectif

Sauvegarder les données chiffrées dans Supabase pour récupération en cas de perte d'appareil.

### 📊 Table Supabase requise

```sql
-- À exécuter dans Supabase SQL Editor

CREATE TABLE encrypted_backups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  backup_type TEXT NOT NULL CHECK (backup_type IN ('full', 'user', 'plans', 'progress')),
  encrypted_data TEXT NOT NULL,
  encryption_iv TEXT NOT NULL,
  data_hash TEXT NOT NULL,
  device_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_backups_user_id ON encrypted_backups(user_id);
CREATE INDEX idx_backups_created_at ON encrypted_backups(created_at DESC);

-- RLS Policies
ALTER TABLE encrypted_backups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own backups"
ON encrypted_backups FOR ALL
USING (auth.uid() = user_id);
```

### 📝 Créer un backup

```dart
import 'package:selah_app/core/encrypted_cloud_backup_service.dart';

// Créer un backup complet
Future<void> createBackup() async {
  try {
    // Demander le mot de passe à l'utilisateur
    final password = await _showPasswordDialog();
    
    // Créer le backup
    final backupId = await EncryptedCloudBackupService.createFullBackup(
      password: password,
      deviceId: 'iPhone 15', // Optionnel
    );
    
    print('✅ Backup créé: $backupId');
    
    // Afficher confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup créé avec succès !')),
    );
  } catch (e) {
    print('❌ Erreur: $e');
    _showErrorDialog(e.toString());
  }
}
```

### 📥 Restaurer un backup

```dart
// Lister les backups disponibles
Future<void> showBackupsList() async {
  final backups = await EncryptedCloudBackupService.listBackups();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Backups disponibles'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: backups.length,
          itemBuilder: (context, index) {
            final backup = backups[index];
            final date = DateTime.parse(backup['created_at']);
            
            return ListTile(
              title: Text('Backup du ${_formatDate(date)}'),
              subtitle: Text(backup['device_id'] ?? 'Appareil inconnu'),
              trailing: IconButton(
                icon: Icon(Icons.download),
                onPressed: () => _restoreBackup(backup['id']),
              ),
            );
          },
        ),
      ),
    ),
  );
}

// Restaurer un backup
Future<void> _restoreBackup(String backupId) async {
  final password = await _showPasswordDialog();
  
  try {
    final data = await EncryptedCloudBackupService.restoreBackup(
      backupId: backupId,
      password: password,
      overwrite: true,
    );
    
    print('✅ ${data.length} élément(s) restaurés');
    
    // Redémarrer l'app
    Phoenix.rebirth(context);
  } catch (e) {
    _showErrorDialog('Mot de passe incorrect ou backup corrompu');
  }
}
```

### ⏰ Backup automatique

```dart
// Au démarrage ou périodiquement
void setupAutoBackup() async {
  // Vérifier si l'utilisateur a activé les backups automatiques
  final autoBackupEnabled = await _getAutoBackupPreference();
  
  if (autoBackupEnabled) {
    final password = await _getStoredBackupPassword(); // Optionnel: stocker de manière sécurisée
    
    await EncryptedCloudBackupService.autoBackupIfNeeded(
      password: password,
      intervalDays: 7, // Backup hebdomadaire
    );
  }
}
```

### 🎨 UI - Page de gestion des backups

```dart
class BackupsPage extends StatefulWidget {
  @override
  _BackupsPageState createState() => _BackupsPageState();
}

class _BackupsPageState extends State<BackupsPage> {
  List<Map<String, dynamic>> _backups = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadBackups();
  }
  
  Future<void> _loadBackups() async {
    setState(() => _loading = true);
    _backups = await EncryptedCloudBackupService.listBackups();
    setState(() => _loading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backups Cloud')),
      body: _loading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _backups.length,
            itemBuilder: (context, index) {
              final backup = _backups[index];
              return _buildBackupCard(backup);
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewBackup,
        child: Icon(Icons.cloud_upload),
        tooltip: 'Créer un nouveau backup',
      ),
    );
  }
  
  Widget _buildBackupCard(Map<String, dynamic> backup) {
    final date = DateTime.parse(backup['created_at']);
    
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(Icons.cloud, size: 40),
        title: Text('Backup ${_formatDate(date)}'),
        subtitle: Text(backup['device_id'] ?? 'Appareil inconnu'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _restore(backup['id']),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _delete(backup['id']),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. MIGRATION ENTRE APPAREILS

### 🎯 Objectif

Permettre à l'utilisateur d'exporter ses données vers un fichier `.selah` pour les transférer sur un nouvel appareil.

### 📤 Export des données

```dart
import 'package:selah_app/core/device_migration_service.dart';

// Exporter vers un fichier
Future<void> exportData() async {
  try {
    // Demander le mot de passe
    final password = await _showPasswordDialog(
      title: 'Mot de passe d\'export',
      hint: 'Choisissez un mot de passe fort (min 12 caractères)',
    );
    
    // Exporter
    final filePath = await DeviceMigrationService.exportToFile(
      password: password,
      includeProgress: true,
      deviceName: 'iPhone 15 Pro',
    );
    
    print('✅ Fichier créé: $filePath');
    
    // Partager le fichier
    await DeviceMigrationService.shareExportFile(
      filePath: filePath,
      message: 'Backup Selah - Fichier chiffré',
    );
  } catch (e) {
    _showError('Erreur d\'export: $e');
  }
}
```

### 📥 Import des données

```dart
// Importer depuis un fichier
Future<void> importData() async {
  try {
    // Sélectionner le fichier
    final filePath = await _pickFile(extension: '.selah');
    
    if (filePath == null) return;
    
    // Afficher les infos du fichier
    final info = await DeviceMigrationService.getExportFileInfo(filePath);
    print('Fichier du ${info['created']}');
    
    // Demander le mot de passe
    final password = await _showPasswordDialog(
      title: 'Mot de passe d\'import',
      hint: 'Entrez le mot de passe du fichier',
    );
    
    // Importer
    final report = await DeviceMigrationService.importFromFile(
      filePath: filePath,
      password: password,
      overwrite: false, // Ne pas écraser
      merge: true,      // Fusionner
    );
    
    print('✅ Import réussi:');
    print('  - ${report['imported']} élément(s) importés');
    print('  - ${report['skipped']} élément(s) ignorés');
    
    // Redémarrer l'app
    Phoenix.rebirth(context);
  } catch (e) {
    _showError('Import échoué: $e');
  }
}
```

### 📷 Transfert via QR Code

```dart
// Générer un QR Code
Future<void> generateTransferQRCode() async {
  final password = await _showPasswordDialog();
  
  final qrData = await DeviceMigrationService.generateQRCodeData(
    password: password,
  );
  
  // Afficher le QR Code
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Scanner avec le nouvel appareil'),
      content: QrImageView(
        data: qrData,
        size: 300,
      ),
    ),
  );
}

// Scanner et importer
Future<void> scanAndImportQRCode() async {
  final qrData = await _scanQRCode();
  final password = await _showPasswordDialog();
  
  final report = await DeviceMigrationService.importFromQRCode(
    qrData: qrData,
    password: password,
  );
  
  print('✅ Import QR terminé');
}
```

### 🎨 UI - Page de migration

```dart
class MigrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Migration d\'appareil')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildExportSection(),
          SizedBox(height: 24),
          _buildImportSection(),
          SizedBox(height: 24),
          _buildQRSection(),
        ],
      ),
    );
  }
  
  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exporter mes données', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Créez un fichier .selah chiffré pour transférer vos données'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => exportData(),
              icon: Icon(Icons.file_upload),
              label: Text('Créer un fichier d\'export'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Importer depuis un fichier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Restaurez vos données depuis un fichier .selah'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => importData(),
              icon: Icon(Icons.file_download),
              label: Text('Sélectionner un fichier'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQRSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfert rapide (QR Code)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Transférez vos données essentielles via QR Code'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => generateTransferQRCode(),
                    icon: Icon(Icons.qr_code),
                    label: Text('Générer'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => scanAndImportQRCode(),
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text('Scanner'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. INTÉGRATION COMPLÈTE

### 📱 Dans `main.dart`

```dart
import 'package:selah_app/core/key_rotation_service.dart';
import 'package:selah_app/core/encrypted_cloud_backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... initialisation Hive, LocalStorage ...
  
  // ═══════════════════════════════════════════════════════════════════
  // SÉCURITÉ AVANCÉE
  // ═══════════════════════════════════════════════════════════════════
  
  // 1. Vérifier et effectuer rotation de clés si nécessaire
  await KeyRotationService.checkAndRotateIfNeeded(
    intervalDays: 90,
    onProgress: (boxName, progress) {
      debugPrint('Rotation $boxName: ${(progress * 100).toInt()}%');
    },
  );
  debugPrint('✅ Rotation de clés vérifiée');
  
  // 2. Backup automatique (si activé par l'utilisateur)
  final autoBackupEnabled = await _getAutoBackupPreference();
  if (autoBackupEnabled) {
    final backupPassword = await _getBackupPassword();
    if (backupPassword != null) {
      await EncryptedCloudBackupService.autoBackupIfNeeded(
        password: backupPassword,
        intervalDays: 7, // Hebdomadaire
      );
      debugPrint('✅ Backup automatique vérifié');
    }
  }
  
  runApp(SelahApp());
}
```

### ⚙️ Dans Settings Page

```dart
class SecuritySettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sécurité')),
      body: ListView(
        children: [
          _buildKeyRotationSection(),
          Divider(),
          _buildCloudBackupSection(),
          Divider(),
          _buildDeviceMigrationSection(),
        ],
      ),
    );
  }
  
  Widget _buildKeyRotationSection() {
    return ListTile(
      leading: Icon(Icons.vpn_key),
      title: Text('Rotation des clés'),
      subtitle: Text('Renouveler les clés de chiffrement'),
      trailing: IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () => _forceKeyRotation(),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => KeyRotationStatusPage()),
      ),
    );
  }
  
  Widget _buildCloudBackupSection() {
    return ListTile(
      leading: Icon(Icons.cloud),
      title: Text('Backups cloud'),
      subtitle: Text('Gérer vos sauvegardes chiffrées'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BackupsPage()),
      ),
    );
  }
  
  Widget _buildDeviceMigrationSection() {
    return ListTile(
      leading: Icon(Icons.phone_android),
      title: Text('Migration d\'appareil'),
      subtitle: Text('Exporter/Importer vos données'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MigrationPage()),
      ),
    );
  }
}
```

---

## 5. TESTS

### 🧪 Test de rotation de clés

```dart
void testKeyRotation() async {
  print('🧪 Test rotation de clés...');
  
  // 1. Créer des données test
  await LocalStorageService.saveLocalUser({'name': 'Test User'});
  
  // 2. Forcer une rotation
  await KeyRotationService.forceRotation('local_user');
  
  // 3. Vérifier que les données sont toujours accessibles
  final user = LocalStorageService.getLocalUser();
  assert(user != null);
  assert(user['name'] == 'Test User');
  
  print('✅ Test réussi: Données accessibles après rotation');
}
```

### 🧪 Test de backup cloud

```dart
void testCloudBackup() async {
  print('🧪 Test backup cloud...');
  
  final password = 'TestPassword123!@#';
  
  // 1. Créer un backup
  final backupId = await EncryptedCloudBackupService.createFullBackup(
    password: password,
    deviceId: 'Test Device',
  );
  assert(backupId.isNotEmpty);
  
  // 2. Supprimer les données locales
  await LocalStorageService.clearAllData();
  
  // 3. Restaurer le backup
  final data = await EncryptedCloudBackupService.restoreBackup(
    backupId: backupId,
    password: password,
  );
  assert(data.isNotEmpty);
  
  // 4. Vérifier les données
  final user = LocalStorageService.getLocalUser();
  assert(user != null);
  
  print('✅ Test réussi: Backup/Restore fonctionnel');
}
```

### 🧪 Test de migration d'appareil

```dart
void testDeviceMigration() async {
  print('🧪 Test migration...');
  
  final password = 'MigrationTest123!@#';
  
  // 1. Exporter
  final exportPath = await DeviceMigrationService.exportToFile(
    password: password,
    includeProgress: true,
  );
  assert(File(exportPath).existsSync());
  
  // 2. Supprimer données locales
  await LocalStorageService.clearAllData();
  
  // 3. Importer
  final report = await DeviceMigrationService.importFromFile(
    filePath: exportPath,
    password: password,
  );
  assert(report['success'] == true);
  assert(report['imported'] > 0);
  
  // 4. Vérifier
  final user = LocalStorageService.getLocalUser();
  assert(user != null);
  
  print('✅ Test réussi: Migration fonctionnelle');
}
```

---

## 📋 CHECKLIST DE DÉPLOIEMENT

### Avant le déploiement

- [ ] Installer les dépendances (`flutter pub get`)
- [ ] Créer la table `encrypted_backups` dans Supabase
- [ ] Tester la rotation de clés
- [ ] Tester le backup/restore
- [ ] Tester l'export/import

### Configuration utilisateur

- [ ] Ajouter préférence "Activer backups automatiques"
- [ ] Ajouter préférence "Intervalle de backup" (jours)
- [ ] Ajouter guide d'utilisation dans l'app

### Documentation

- [ ] Documenter le processus de migration
- [ ] Créer FAQ sur la sécurité
- [ ] Expliquer la récupération en cas de perte

---

## 🎯 RÉSUMÉ

### ✅ Ce qui est implémenté

1. **Rotation de clés** : Tous les 90 jours (configurable)
2. **Backup cloud** : Chiffré zero-knowledge dans Supabase
3. **Migration** : Export/Import via fichier .selah ou QR Code

### 🔒 Sécurité

- **AES-256** pour le chiffrement
- **PBKDF2** pour dérivation de clés
- **SHA-256** pour vérification d'intégrité
- **Zero-knowledge** : Supabase ne peut pas déchiffrer

### 📈 Bénéfices

- Protection renforcée des données
- Récupération en cas de perte
- Migration facile entre appareils
- Conformité RGPD

---

**🚀 Vos données sont maintenant ultra-sécurisées !**

