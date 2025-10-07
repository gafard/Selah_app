# 🎯 PROCHAINES ÉTAPES - Selah App

## 📅 Plan d'Action

### 🔥 Priorité CRITIQUE (À faire immédiatement)

#### 1. Finir Migration GoRouter (14 pages)
**Temps estimé** : 2-3 heures  
**Impact** : Haute - Nécessaire pour que toute la navigation fonctionne

**Pages à migrer** :
```
Priority 1 (Flux principal) :
  - [ ] onboarding_dynamic_page.dart
  - [ ] congrats_discipline_page.dart  
  - [ ] custom_plan_generator_page.dart
  - [ ] home_page.dart

Priority 2 (Fonctionnalités clés) :
  - [ ] reader_page_modern.dart
  - [ ] meditation_chooser_page.dart
  - [ ] meditation_free_page.dart
  - [ ] meditation_qcm_page.dart
  - [ ] meditation_auto_qcm_page.dart

Priority 3 (Secondaires) :
  - [ ] prayer_subjects_page.dart
  - [ ] pre_meditation_prayer_page.dart
  - [ ] verse_poster_page.dart
  - [ ] spiritual_wall_page.dart
  - [ ] gratitude_page.dart
  - [ ] coming_soon_page.dart
```

**Comment faire** :
```bash
# 1. Ouvrir le fichier
# 2. Ajouter import
import 'package:go_router/go_router.dart';

# 3. Remplacer tous les Navigator.pushNamed
Navigator.pushNamed(context, '/route', arguments: {...})
→ context.go('/route', extra: {...})

# 4. Remplacer tous les Navigator.push(MaterialPageRoute)
Navigator.push(context, MaterialPageRoute(builder: (_) => MyPage(...)))
→ context.push('/route', extra: {...})

# 5. Tester la page
```

---

#### 2. Déployer Schéma Supabase
**Temps estimé** : 30 minutes  
**Impact** : Haute - Nécessaire pour sync online

**Étapes** :
1. Ouvrir [Supabase Dashboard](https://app.supabase.com)
2. Aller dans SQL Editor
3. Créer nouvelle query
4. Copier `SCHEMA_SUPABASE_COMPLET_V2.sql`
5. Exécuter le script
6. Vérifier tables créées (13 tables)
7. Tester fonctions RPC
8. Vérifier policies RLS

**Validation** :
```sql
-- Vérifier toutes les tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Doit retourner:
-- bible_versions
-- meditation_journals
-- notifications_queue
-- plan_days
-- plan_presets
-- plans
-- prayer_subjects
-- reader_settings
-- sync_queue
-- user_analytics
-- user_progress
-- users
-- verse_highlights
```

---

#### 3. Tester Flux Complet
**Temps estimé** : 1 heure  
**Impact** : Haute - Validation complète

**Scénario de test** :
```
1. Lancer app (Android/iOS)
   ✓ Splash → Welcome

2. Créer compte (online)
   ✓ Welcome → Auth → CompleteProfile
   ✓ Vérifier profil créé dans Supabase

3. Compléter profil
   ✓ CompleteProfile → Goals
   ✓ Vérifier préférences sauvegardées

4. Choisir plan
   ✓ Goals → Onboarding
   ✓ Vérifier plan créé

5. Terminer onboarding
   ✓ Onboarding → Home
   ✓ Vérifier navigation fluide

6. Lecture quotidienne
   ✓ Home → Reader
   ✓ Lire passage

7. Méditation
   ✓ Reader → Meditation Chooser
   ✓ Choisir type méditation
   ✓ Compléter méditation

8. Prière
   ✓ Meditation → Prayer Subjects
   ✓ Créer prières

9. Journal
   ✓ Vérifier entrée dans journal
   ✓ Vérifier sync Supabase
```

---

### ⚡ Priorité HAUTE (Cette semaine)

#### 4. Tester Mode Offline
**Temps estimé** : 30 minutes  
**Impact** : Haute - Validation architecture offline-first

**Scénario** :
```
1. Désactiver WiFi sur device
2. Lancer app → Doit fonctionner ✅
3. Créer compte local
4. Compléter profil
5. Choisir plan
6. Faire méditation
7. Vérifier données en local (Hive)
8. Réactiver WiFi
9. Vérifier sync automatique
10. Vérifier données dans Supabase
```

**Logs attendus** :
```
📴 Démarrage hors-ligne - Supabase sera initialisé au retour réseau
🎉 Selah App démarrée en mode 📴 OFFLINE
[... utilisation ...]
📡 Réseau rétabli → Init Supabase & reprise sync
🔁 Reprise de la sync (X éléments en attente)...
✅ Sync queue traitée
```

---

#### 5. Implémenter Drain de Sync Queue
**Temps estimé** : 1 heure  
**Impact** : Haute - Nécessaire pour sync complète

**Fichier** : `lib/services/sync_service.dart` (à créer)

**Implémentation** :
```dart
class SyncService {
  static Future<void> drainPendingSync() async {
    final queue = LocalStorageService.getSyncQueue();
    
    for (final item in queue) {
      try {
        await _syncItem(item);
        await LocalStorageService.removeSyncItem(item.id);
      } catch (e) {
        print('⚠️ Sync failed for ${item.id}: $e');
        // Incrémenter retry_count
      }
    }
  }
  
  static Future<void> _syncItem(SyncQueueItem item) async {
    switch (item.tableName) {
      case 'users':
        await _syncUser(item);
      case 'plans':
        await _syncPlan(item);
      case 'plan_days':
        await _syncPlanDay(item);
      // etc...
    }
  }
}
```

**TODO dans main.dart** :
```dart
// Ligne 50-55
try {
  final syncCount = LocalStorageService.getSyncQueue().length;
  if (syncCount > 0) {
    debugPrint('🔁 Reprise de la sync ($syncCount éléments en attente)...');
    await SyncService.drainPendingSync(); // ← À implémenter
    debugPrint('✅ Sync queue traitée');
  }
} catch (e) {
  debugPrint('⚠️ Erreur lors de la sync : $e');
}
```

---

### 📊 Priorité MOYENNE (Semaine prochaine)

#### 6. Améliorer Intelligence
**Temps estimé** : 2-3 heures

**Améliorations** :
- [ ] Restaurer services d'intelligence supprimés
- [ ] Intégrer dans `intelligent_local_preset_generator`
- [ ] Enrichir noms dynamiques de cartes
- [ ] Ajouter dans `goals_page` visualisation

**Fichiers concernés** :
- `lib/services/intelligent_meditation_timing.dart`
- `lib/services/bible_spiritual_impact.dart`
- `lib/services/relationship_development_intelligence.dart`
- `lib/services/holistic_intelligence_engine.dart`

---

#### 7. Configurer Supabase Storage
**Temps estimé** : 1 heure

**Pour quoi** :
- Sauvegarder posters de versets
- Avatar utilisateurs
- Images communautaires (futur)

**Buckets à créer** :
```
- verse_posters (public)
- user_avatars (private)
- plan_covers (public)
```

**Policies** :
```sql
-- Bucket verse_posters
INSERT policy: authenticated users can upload
SELECT policy: public read
UPDATE policy: owner only
DELETE policy: owner only
```

---

#### 8. Ajouter Tests Unitaires
**Temps estimé** : 2-3 heures

**Tests à créer** :
- [ ] `user_repository_test.dart`
- [ ] `local_storage_service_test.dart`
- [ ] `sync_service_test.dart`
- [ ] `plan_preset_generator_test.dart`

**Framework** :
```dart
void main() {
  group('UserRepository', () {
    test('should create local user offline', () async {
      // Arrange
      final repo = UserRepository();
      
      // Act
      final user = await repo.createLocalUser(displayName: 'Test');
      
      // Assert
      expect(user.id, isNotEmpty);
      expect(user.displayName, 'Test');
    });
  });
}
```

---

### 🔮 Priorité BASSE (Plus tard)

#### 9. Fonctionnalités Communautaires
- Partage de méditations
- Groupes de lecture
- Défis communautaires
- Mur spirituel enrichi

#### 10. Gamification
- Système de badges
- Achievements
- Leaderboards
- Récompenses quotidiennes

#### 11. Contenu Premium
- Études approfondies
- Plans premium
- Abonnements
- Paiements

---

## 🛠️ Quick Fixes Nécessaires

### Bugs Connus

1. **SnackBar Context** dans plusieurs pages
```dart
// ❌ Problème
ScaffoldMessenger.of(context).showSnackBar(...);

// ✅ Solution
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

2. **MeditationFreePage parameters**
- ✅ Déjà corrigé (passageRef, passageText restaurés)

3. **Asset directories missing**
- ✅ Déjà créé (videos, audios, rive_animations, pdfs)

---

## 📋 Checklist Complète

### Développement
- [x] Nettoyer code (50+ fichiers)
- [x] Architecture offline-first
- [x] GoRouter unifié
- [x] UserRepository créé
- [x] 5 pages migrées GoRouter
- [ ] 14 pages restantes à migrer
- [ ] Implémenter SyncService
- [ ] Tests unitaires

### Base de Données
- [x] Schéma SQL complet créé
- [x] Guide d'utilisation créé
- [x] Script de migration créé
- [ ] Déployer sur Supabase
- [ ] Tester RPC functions
- [ ] Configurer Storage

### Tests
- [x] Android fonctionnel
- [ ] iOS fonctionnel
- [ ] Web fonctionnel
- [ ] Tests offline
- [ ] Tests sync
- [ ] Tests flux complet

### Documentation
- [x] Guide schéma SQL
- [x] Bilan du jour
- [x] Récapitulatif final
- [x] Prochaines étapes
- [ ] README principal
- [ ] Guide développeur
- [ ] Changelog

---

## 🎯 Focus Immédiat

**Les 3 choses à faire EN PREMIER** :

1. **Migration GoRouter** (pages restantes)
   → Sans ça, navigation cassée

2. **Déploiement Supabase** (schéma SQL)
   → Sans ça, pas de sync online

3. **Tests complets** (flux utilisateur)
   → Sans ça, pas de validation

---

**Une fois ces 3 choses faites, l'application sera 100% fonctionnelle sur toutes les plateformes ! 🚀**
