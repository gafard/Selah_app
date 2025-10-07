# 🗺️ PLAN COMPLET - Main & Router (Tous les fichiers)

## 📊 VUE D'ENSEMBLE

### Fichiers Trouvés

**2 main.dart** :
1. `/lib/main.dart` (racine)
2. `/selah_app/lib/main.dart` (selah_app)

**8 routers** :
1. `/lib/router.dart` (racine)
2. `/lib/router_new.dart` (racine, GoRouter)
3. `/lib/router_supabase.dart` (racine, Map<String, WidgetBuilder>)
4. `/selah_app/lib/router.dart` (selah_app, Map<String, WidgetBuilder>)
5. `/selah_app/lib/router_new.dart` (selah_app, GoRouter)
6. `/selah_app/lib/router_simple.dart` (selah_app, GoRouter)
7. `/lib/features/meditation/ui/flow/meditation_flow_router.dart`
8. `/selah_app/lib/features/meditation/ui/flow/meditation_flow_router.dart`

---

## 🔍 ANALYSE DÉTAILLÉE

### 1️⃣ MAIN.DART - RACINE (`/lib/main.dart`)

**Package** : `essai`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  
  runApp(const ProviderScope(child: SelahApp()));
}

class SelahApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider(
      create: (context) => ReaderSettingsService(),
      child: MaterialApp.router(
        routerConfig: AppRouterNew.router, // ← GoRouter
      ),
    );
  }
}
```

**Analyse** :
- ✅ **Utilise** : `router_new.dart` (GoRouter)
- ✅ Riverpod configuré
- ✅ GoogleFonts configuré
- ❌ **Manque** : Timezone init
- ❌ **Manque** : Notifications init
- ❌ **Manque** : Supabase init
- ❌ **Manque** : Error handling

**Statut** : 🟡 Fonctionnel mais incomplet

---

### 2️⃣ MAIN.DART - SELAH_APP (`/selah_app/lib/main.dart`)

**Package** : `selah_app`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  
  await initializeSupabase(); // ✅
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => ReaderSettingsService()),
      ],
      child: const ProviderScope(child: SelahApp()),
    ),
  );
}

class SelahApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/splash',
      routes: AppRouter.routes, // ← Map-based routing
    );
  }
}
```

**Analyse** :
- ✅ **Utilise** : `router.dart` (Map-based)
- ✅ Riverpod + MultiProvider
- ✅ GoogleFonts configuré
- ✅ **Supabase initialisé** 🌟
- ✅ AppState provider
- ✅ Route initiale : `/splash`
- ❌ **Manque** : Timezone init
- ❌ **Manque** : Notifications init
- ❌ **Manque** : Error handling

**Statut** : 🟢 Plus complet que racine

---

## 📍 COMPARAISON DES 2 MAIN.DART

| Critère | `/lib/main.dart` (racine) | `/selah_app/main.dart` | Recommandation |
|---------|---------------------------|------------------------|----------------|
| **Package** | `essai` | `selah_app` | **Utiliser selah_app** |
| **Routing** | GoRouter (router_new) | Map (router.dart) | **GoRouter meilleur** |
| **Supabase** | ❌ Non | ✅ Oui | **selah_app gagne** |
| **State** | Provider (1) | MultiProvider (2) | **selah_app gagne** |
| **Route initiale** | /test | /splash | **selah_app gagne** |
| **Timezone** | ❌ | ❌ | Ajouter partout |
| **Notifications** | ❌ | ❌ | Ajouter partout |

**🎯 RECOMMANDATION MAIN.DART** :

**FUSIONNER le meilleur des deux** :
- Base : `/selah_app/lib/main.dart`
- Ajouter : GoRouter (de racine)
- Ajouter : Timezone init
- Ajouter : Notifications init
- Garder : Supabase init, MultiProvider

---

## 🗺️ ANALYSE DES ROUTERS

### Router 1 : `/lib/router.dart` (Map-based, racine)

**Type** : `Map<String, Widget Function(BuildContext)>`  
**Routes** : 41  
**Utilise** : Packages `essai`

**Problèmes** :
- ❌ Doublon `/reader` et `/reader_modern`
- ❌ Doublon `/home` et `/selah_home`
- ❌ Pas de guards d'auth
- ❌ Utilise package `essai` (à unifier ?)

**Statut** : 🟡 Doublon de router_new.dart

---

### Router 2 : `/lib/router_new.dart` (GoRouter, racine)

**Type** : `GoRouter`  
**Routes** : 31  
**Initial** : `/test`  
**Utilise** : Packages `essai`

**Avantages** :
- ✅ GoRouter (moderne)
- ✅ Query parameters gérés
- ✅ Typed navigation

**Problèmes** :
- ❌ Doublon `/reader` et `/reader_modern` (ligne 77-82)
- ❌ Doublon `/home` et `/selah_home`
- ❌ Pas de guards d'auth
- ❌ Initial route = `/test` (pour dev)

**Statut** : 🟢 Meilleur que router.dart (racine)

---

### Router 3 : `/lib/router_supabase.dart` (Map-based, racine)

**Type** : `Map<String, Widget Function(BuildContext)>`  
**Routes** : 31  
**Initial** : Non défini (dans class)  
**Classe** : `AppRouterSupabase`

**Observations** :
- Identique à `/lib/router.dart`
- Probablement version test Supabase
- Contient `/splash`

**Statut** : 🟡 Probablement obsolète/test

---

### Router 4 : `/selah_app/lib/router.dart` (Map-based, selah_app)

**Type** : `Map<String, Widget Function(BuildContext)>`  
**Routes** : 51 🌟  
**Package** : `selah_app`  
**Utilise actuellement** : Par main.dart selah_app

**Routes uniques** :
- `/auth` (vs `/login` et `/register`)
- `/custom_plan`
- `/scan/bible`
- `/scan/bible/advanced`
- `/profile`
- `/profile_settings`
- `/splash`
- `/verse_poster`
- `/spiritual_wall`
- `/gratitude`
- `/payerpage`
- `/bible_quiz`
- `/pre_meditation_prayer`
- `/onboarding` (OnboardingDynamicPage)
- `/congrats` (CongratsDisciplinePage)

**Problèmes** :
- ❌ Doublon `/reader` et `/reader_modern` (ligne 54-55)

**Statut** : 🟢 Le plus complet ! **ROUTER DE PRODUCTION**

---

### Router 5 : `/selah_app/lib/router_new.dart` (GoRouter, selah_app)

**Type** : `GoRouter`  
**Routes** : 8  
**Initial** : `/splash`  
**Classe** : `AppRouter`

**Caractéristiques UNIQUES** :
- ✅ **Redirect logic avec auth** 🌟🌟🌟
- ✅ Vérification profil complet
- ✅ Vérification plan actif
- ✅ Vérification onboarding
- ✅ Routes protégées

**Code clé** :
```dart
redirect: (context, state) async {
  final user = _supabase.auth.currentUser;
  
  if (user == null) return '/welcome';
  
  final profile = await _userRepo.getCurrentUser();
  if (!profile.isComplete) return '/complete-profile';
  if (profile.currentPlanId == null) return '/choose-plan';
  if (!profile.hasOnboarded) return '/onboarding';
  
  return null;
}
```

**Problèmes** :
- ⚠️ Seulement 8 routes (incomplet)
- ⚠️ Utilisé par qui ? (pas dans main.dart actuel)

**Statut** : 🟡 **EXCELLENT redirect logic, mais incomplet**

---

### Router 6 : `/selah_app/lib/router_simple.dart` (GoRouter, selah_app)

**Type** : `GoRouter`  
**Routes** : 28  
**Initial** : `/home`

**Observations** :
- Routes complètes
- Gestion des `extra` arguments
- Doublon `/home` (ligne 33 et 73)

**Statut** : 🟡 Version simplifiée sans guards

---

### Router 7 & 8 : `meditation_flow_router.dart`

**Localisations** :
- `/lib/features/meditation/ui/flow/`
- `/selah_app/lib/features/meditation/ui/flow/`

**À analyser** : Probablement routers locaux pour méditation

---

## 🎯 RECOMMANDATIONS FINALES

### PLAN DE CONSOLIDATION

#### Phase 1 : Choisir le Package Principal

**🏆 RECOMMANDATION** : **`selah_app`** comme package principal

**Raisons** :
- Supabase déjà initialisé
- Routes les plus complètes (51)
- AppState provider
- Route splash configurée

---

#### Phase 2 : Choisir le Router Définitif

**🏆 RECOMMANDATION** : **GoRouter avec guards**

**Créer** : `/selah_app/lib/router_final.dart`

**Combiner** :
1. **Base** : `/selah_app/lib/router.dart` (51 routes)
2. **Ajouter** : Redirect logic de `/selah_app/lib/router_new.dart` (guards auth)
3. **Convertir** : De Map-based à GoRouter
4. **Nettoyer** : Supprimer doublons

---

#### Phase 3 : Améliorer main.dart

**Fichier** : `/selah_app/lib/main.dart`

**Modifications** :

```dart
import 'package:timezone/data/latest.dart' as tz;
import 'package:selah_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all services
  await _initializeServices();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => ReaderSettingsService()),
      ],
      child: const ProviderScope(child: SelahApp()),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    // 1. Timezone (pour notifications)
    tz.initializeTimeZones();
    print('✅ Timezone initialized');
    
    // 2. Google Fonts
    GoogleFonts.config.allowRuntimeFetching = true;
    print('✅ Google Fonts initialized');
    
    // 3. Supabase
    await initializeSupabase();
    print('✅ Supabase initialized');
    
    // 4. Notifications
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
    print('✅ Notifications initialized');
    
  } catch (e) {
    print('❌ Error initializing services: $e');
  }
}

class SelahApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Selah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      routerConfig: AppRouterFinal.router, // ← Nouveau router unifié
    );
  }
}
```

---

## 📋 TABLEAU RÉCAPITULATIF

### Main.dart

| Fichier | Package | Routing | Supabase | State | Recommandation |
|---------|---------|---------|----------|-------|----------------|
| `/lib/main.dart` | essai | GoRouter | ❌ | Provider | ❌ Abandonner |
| `/selah_app/lib/main.dart` | selah_app | Map | ✅ | MultiProvider | ✅ **UTILISER + AMÉLIORER** |

### Routers

| Fichier | Type | Routes | Guards | Complet | Recommandation |
|---------|------|--------|--------|---------|----------------|
| `/lib/router.dart` | Map | 41 | ❌ | 🟡 | ❌ Obsolète |
| `/lib/router_new.dart` | GoRouter | 31 | ❌ | 🟡 | ❌ Obsolète |
| `/lib/router_supabase.dart` | Map | 31 | ❌ | 🟡 | ❌ Obsolète |
| `/selah_app/lib/router.dart` | Map | **51** | ❌ | ✅ | 🟡 Base routes |
| `/selah_app/lib/router_new.dart` | GoRouter | 8 | ✅ | ❌ | 🟡 Prendre guards |
| `/selah_app/lib/router_simple.dart` | GoRouter | 28 | ❌ | 🟡 | ❌ Obsolète |

---

## ✅ ACTIONS CONCRÈTES

### Action 1 : Supprimer Fichiers Obsolètes

```bash
# Supprimer routers racine (package essai)
rm lib/router.dart
rm lib/router_new.dart
rm lib/router_supabase.dart
rm lib/main.dart

# Supprimer router simple (selah_app)
rm selah_app/lib/router_simple.dart
```

### Action 2 : Créer Router Unifié

**Créer** : `/selah_app/lib/router_final.dart`

**Combiner** :
- 51 routes de `router.dart`
- Guards de `router_new.dart`
- GoRouter moderne

### Action 3 : Améliorer main.dart

**Modifier** : `/selah_app/lib/main.dart`

**Ajouter** :
- Timezone init
- Notifications init
- Error handling
- Utiliser router_final

### Action 4 : Nettoyer Doublons Routes

Dans le router final, supprimer :
- `/reader_modern` (garder `/reader`)
- Choisir entre `/home` et `/selah_home`

---

## 🎁 PROPOSITION FINALE

### Structure Cible

```
selah_app/
├── lib/
│   ├── main.dart ← Main unifié avec tous les inits
│   ├── router.dart ← Router GoRouter avec guards (51 routes)
│   └── ...
```

**Tous les fichiers dans racine `/lib/` (package essai)** : **À SUPPRIMER**

---

Voulez-vous que je procède à la création du **router unifié** et à l'amélioration du **main.dart** ?
