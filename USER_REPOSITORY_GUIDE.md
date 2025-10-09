# 📚 UserRepository - Guide Complet

## 🎯 Principe Offline-First

Le `UserRepository` respecte strictement le principe **offline-first** :

### Priorités

1. **🥇 LOCAL D'ABORD** - Hive/LocalStorage
2. **🥈 SYNC ARRIÈRE-PLAN** - Supabase (si en ligne)
3. **🥉 FALLBACK** - Continue offline si sync échoue

---

## 🏗️ Architecture

```
UserRepository
├── LOCAL (Hive) ← Priorité absolue
│   ├── Lecture instantanée
│   ├── Écriture immédiate
│   └── Fonctionne toujours
│
├── SUPABASE (Optional) ← Sync en arrière-plan
│   ├── Lecture si local vide
│   ├── Sync non bloquante
│   └── Retry automatique via queue
│
└── SYNC QUEUE
    ├── Marque les changements
    ├── Synchronise quand possible
    └── Gère les conflits
```

---

## 📖 UTILISATION

### 1. Vérifier si Authentifié

```dart
final userRepo = UserRepository();

// Vérifie local d'abord, puis Supabase si disponible
final isAuth = userRepo.isAuthenticated();

if (isAuth) {
  print('✅ Utilisateur connecté');
} else {
  print('❌ Pas d'utilisateur');
}
```

### 2. Récupérer l'Utilisateur Actuel

```dart
// Récupère depuis local, fallback sur Supabase si nécessaire
final user = await userRepo.getCurrentUser();

if (user != null) {
  print('User: ${user.displayName}');
  print('Profil complet: ${user.isComplete}');
  print('Onboarding fait: ${user.hasOnboarded}');
  print('Plan actif: ${user.currentPlanId}');
}
```

### 3. Créer un Utilisateur Local (Offline)

```dart
// Fonctionne SANS Internet
final localUser = await userRepo.createLocalUser(
  displayName: 'Jean',
  email: 'jean@example.com', // Optionnel
);

print('✅ Utilisateur local créé: ${localUser.id}');
// ID format: local_1234567890
```

### 4. Créer un Utilisateur Supabase (Online)

```dart
// Nécessite Internet
try {
  final user = await userRepo.createSupabaseUser(
    email: 'jean@example.com',
    password: 'motdepasse123',
    displayName: 'Jean',
  );
  
  print('✅ Compte Supabase créé: ${user?.id}');
} catch (e) {
  print('❌ Erreur (pas de connexion ?) : $e');
  // Fallback : Créer utilisateur local
  final localUser = await userRepo.createLocalUser(displayName: 'Jean');
}
```

### 5. Mettre à Jour le Profil (Optimistic)

```dart
// Mise à jour LOCALE immédiate
// Sync Supabase en arrière-plan
await userRepo.updateProfile({
  'display_name': 'Jean Dupont',
  'age': 25,
  'favorite_bible': 'LSG',
});

print('✅ Profil mis à jour localement');
// Sync automatique en arrière-plan si en ligne
```

### 6. Marquer le Profil comme Complet

```dart
await userRepo.markProfileComplete();
print('✅ Profil marqué comme complet');
```

### 7. Marquer l'Onboarding comme Terminé

```dart
await userRepo.markOnboardingComplete();
print('✅ Onboarding terminé');
```

### 8. Définir le Plan Actif

```dart
await userRepo.setCurrentPlan('plan_123');
print('✅ Plan actif défini');
```

### 9. Déconnexion

```dart
// Nettoie local + Supabase
await userRepo.signOut();
print('✅ Utilisateur déconnecté');
```

---

## 🛡️ GUARDS D'AUTHENTIFICATION (Router)

Maintenant vous pouvez ajouter des guards au router :

### router.dart avec Guards

```dart
import 'package:selah_app/repositories/user_repository.dart';

class AppRouter {
  static final _userRepo = UserRepository();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    
    redirect: (context, state) async {
      final path = state.uri.path;
      
      // Toujours permettre splash
      if (path == '/splash') return null;
      
      // Vérifier authentification (local d'abord)
      final isAuth = _userRepo.isAuthenticated();
      
      if (!isAuth) {
        // Pas authentifié → welcome
        if (path == '/welcome' || path == '/auth') return null;
        return '/welcome';
      }
      
      // Authentifié - vérifier profil
      final user = await _userRepo.getCurrentUser();
      
      if (user == null) {
        return '/welcome';
      }
      
      // Vérifier profil complet
      if (!user.isComplete) {
        if (path == '/complete_profile') return null;
        return '/complete_profile';
      }
      
      // Vérifier plan actif
      if (user.currentPlanId == null) {
        if (path == '/goals') return null;
        return '/goals';
      }
      
      // Vérifier onboarding
      if (!user.hasOnboarded) {
        if (path == '/onboarding') return null;
        return '/onboarding';
      }
      
      // Tout OK
      return null;
    },
    
    routes: [
      // Vos routes...
    ],
  );
}
```

---

## 🔄 FLUX COMPLET

### Scénario 1 : Utilisateur Nouveau (Offline)

```
1. App démarre → Hive initialisé ✅
2. Aucun user local trouvé
3. User clique "Créer compte"
4. createLocalUser() appelé ✅
5. Utilisateur créé localement (id: local_123)
6. Navigation vers onboarding ✅
7. App fonctionne complètement offline
```

### Scénario 2 : Utilisateur Nouveau (Online)

```
1. App démarre → Hive + Supabase initialisés ✅
2. Aucun user local trouvé
3. User clique "Créer compte"
4. createSupabaseUser() appelé ✅
5. Compte Supabase créé (id: uuid)
6. Profil sauvegardé localement
7. Navigation vers onboarding ✅
8. App fonctionne online + offline
```

### Scénario 3 : Utilisateur Existant (Offline)

```
1. App démarre → Hive initialisé ✅
2. User local trouvé ✅
3. getCurrentUser() retourne user local
4. Navigation vers /home ✅
5. Modifications sauvegardées localement
6. Ajoutées à sync queue
```

### Scénario 4 : Utilisateur Existant (Online)

```
1. App démarre → Hive + Supabase initialisés ✅
2. User local trouvé ✅
3. getCurrentUser() retourne user local
4. Sync queue vidée en arrière-plan ✅
5. Navigation vers /home ✅
6. Modifications sync en temps réel
```

---

## ✅ AVANTAGES

### Pour l'Utilisateur

- ✅ **Fonctionne offline** - Toujours accessible
- ✅ **Rapide** - Données locales instantanées
- ✅ **Fiable** - Pas de perte de données
- ✅ **Transparent** - Sync automatique invisible

### Pour le Développeur

- ✅ **Simple** - API claire et cohérente
- ✅ **Testable** - Mode offline facile à tester
- ✅ **Robuste** - Gestion d'erreurs intégrée
- ✅ **Évolutif** - Facile d'ajouter des champs

---

## 🧪 TESTS

### Test 1 : Création Offline

```dart
// Mode avion activé
final user = await userRepo.createLocalUser(displayName: 'Test');
expect(user.id.startsWith('local_'), true);
expect(user.isLocalOnly, true);
```

### Test 2 : Mise à Jour Offline

```dart
// Mode avion activé
await userRepo.updateProfile({'display_name': 'Nouveau Nom'});
final user = await userRepo.getCurrentUser();
expect(user?.displayName, 'Nouveau Nom');
```

### Test 3 : Sync Queue

```dart
// Mode avion activé
await userRepo.updateProfile({'test': 'value'});

// Vérifier queue
final queue = LocalStorageService.getSyncQueue();
expect(queue.length, greaterThan(0));
```

### Test 4 : Authentification Sans Connexion

```dart
// Mode avion activé
await userRepo.createLocalUser(displayName: 'Test');
expect(userRepo.isAuthenticated(), true);
```

---

## 📚 FICHIERS ASSOCIÉS

| Fichier | Description |
|---------|-------------|
| `user_repository.dart` | Repository principal |
| `local_storage_service.dart` | Service de stockage |
| `router.dart` | Router avec guards |
| `main.dart` | Initialisation |

---

**🎉 UserRepository prêt à l'emploi avec offline-first complet !**

