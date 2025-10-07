# ✅ CHECKLIST OFFLINE-FIRST - À Vérifier à CHAQUE Modification

## 🎯 PRINCIPE FONDAMENTAL

**RÈGLE D'OR** : Toute modification doit fonctionner **SANS Internet** !

---

## 📋 CHECKLIST AVANT CHAQUE MODIFICATION

### 1️⃣ Assets & Ressources

**Questions à se poser** :
- [ ] Les images sont-elles dans `/assets/images/` (local) ?
- [ ] Les audios sont-ils dans `/assets/audios/` (local) ?
- [ ] Les vidéos sont-elles dans `/assets/videos/` (local) ?
- [ ] Les fonts sont-elles dans `/assets/fonts/` (local) ?
- [ ] Les animations sont-elles dans `/assets/rive_animations/` (local) ?

**❌ À ÉVITER** :
```dart
// ❌ URL externe (nécessite Internet)
Image.network('https://example.com/image.png')
AudioPlayer('https://cdn.com/audio.mp3')
```

**✅ À FAIRE** :
```dart
// ✅ Asset local (offline-first)
Image.asset('assets/images/image.png')
AudioPlayer('assets/audios/audio.mp3')
```

---

### 2️⃣ Données & API

**Questions à se poser** :
- [ ] Les données sont-elles chargées depuis Hive/LocalStorage d'abord ?
- [ ] Y a-t-il un fallback local si l'API échoue ?
- [ ] Les modifications sont-elles sauvegardées localement en premier ?
- [ ] La sync Supabase est-elle optionnelle et en arrière-plan ?

**❌ À ÉVITER** :
```dart
// ❌ Lecture directe depuis Supabase (bloque si offline)
final data = await supabase.from('table').select();
```

**✅ À FAIRE** :
```dart
// ✅ Local d'abord, Supabase en fallback
final localData = LocalStorageService.getData();
if (localData != null) return localData;

// Seulement si en ligne
if (await ConnectivityService.instance.isOnline) {
  try {
    final data = await supabase.from('table').select();
    await LocalStorageService.saveData(data); // Sauvegarder localement
    return data;
  } catch (e) {
    return localData; // Fallback sur local
  }
}
```

---

### 3️⃣ Navigation & Routes

**Questions à se poser** :
- [ ] La page fonctionne-t-elle sans authentification Supabase ?
- [ ] Les guards vérifient-ils le stockage local d'abord ?
- [ ] Les arguments de route sont-ils optionnels ou ont des valeurs par défaut ?

**❌ À ÉVITER** :
```dart
// ❌ Paramètres requis (peut crasher)
final String passageRef; // required
```

**✅ À FAIRE** :
```dart
// ✅ Paramètres optionnels avec défauts
final String? passageRef;
final ref = passageRef ?? 'Jean 3:16';
```

---

### 4️⃣ Initialisation Services

**Questions à se poser** :
- [ ] Le service fonctionne-t-il sans Internet ?
- [ ] L'initialisation est-elle non bloquante ?
- [ ] Y a-t-il un try-catch avec continuation si échec ?

**❌ À ÉVITER** :
```dart
// ❌ Init bloquante
await initializeService(); // Crash si échec
runApp(...);
```

**✅ À FAIRE** :
```dart
// ✅ Init non bloquante avec fallback
try {
  await initializeService();
} catch (e) {
  print('⚠️ Service failed, continuing offline: $e');
}
runApp(...); // Continue quand même
```

---

### 5️⃣ État & State Management

**Questions à se poser** :
- [ ] L'état est-il sauvegardé dans Hive ?
- [ ] La restauration d'état fonctionne-t-elle offline ?
- [ ] Les updates sont-ils optimistes (local immédiat) ?

**❌ À ÉVITER** :
```dart
// ❌ État seulement en mémoire
setState(() => _data = newData);
```

**✅ À FAIRE** :
```dart
// ✅ État persisté localement
setState(() => _data = newData);
await LocalStorageService.saveData(newData);
await LocalStorageService.markForSync('data', id);
```

---

### 6️⃣ Widgets & UI

**Questions à se poser** :
- [ ] Le widget affiche-t-il des placeholders pendant le chargement ?
- [ ] Y a-t-il un message clair si fonctionnalité offline indisponible ?
- [ ] Les erreurs réseau sont-elles gérées gracieusement ?

**❌ À ÉVITER** :
```dart
// ❌ Pas de gestion d'erreur
FutureBuilder(
  future: fetchOnlineData(),
  builder: (context, snapshot) => Text(snapshot.data),
)
```

**✅ À FAIRE** :
```dart
// ✅ Gestion complète offline/online
FutureBuilder(
  future: fetchData(), // Essaie local d'abord
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text('Mode offline - Données locales');
    }
    return Text(snapshot.data ?? 'Chargement...');
  },
)
```

---

## 🚨 ERREURS COURANTES À ÉVITER

### Erreur 1 : Assets Externes

```dart
❌ Image.network('https://...')
✅ Image.asset('assets/images/...')
```

### Erreur 2 : API Sans Fallback

```dart
❌ await supabase.from('table').select()
✅ LocalStorage.get() ?? await supabase...
```

### Erreur 3 : Init Bloquante

```dart
❌ await initSupabase(); runApp();
✅ runApp(); unawaited(initSupabase());
```

### Erreur 4 : Paramètres Requis

```dart
❌ required String passageRef
✅ String? passageRef; final ref = passageRef ?? 'default';
```

### Erreur 5 : État Non Persisté

```dart
❌ setState(() => data = newData);
✅ setState(() => data = newData); LocalStorage.save(data);
```

---

## ✅ MODÈLE DE CODE OFFLINE-FIRST

### Template pour Nouvelle Fonctionnalité

```dart
class MyNewFeature {
  // 1. Charger depuis local d'abord
  Future<Data> loadData() async {
    final localData = await LocalStorageService.getMyData();
    if (localData != null) {
      return localData; // ✅ Retour immédiat
    }
    
    // 2. Tenter chargement online seulement si nécessaire
    if (await ConnectivityService.instance.isOnline) {
      try {
        final onlineData = await _fetchFromSupabase();
        await LocalStorageService.saveMyData(onlineData);
        return onlineData;
      } catch (e) {
        print('⚠️ Online fetch failed: $e');
      }
    }
    
    // 3. Fallback sur données par défaut
    return _getDefaultData();
  }
  
  // 4. Sauvegarder avec optimistic update
  Future<void> saveData(Data data) async {
    // Local immédiat
    await LocalStorageService.saveMyData(data);
    
    // Marquer pour sync
    await LocalStorageService.markForSync('my_data', data.id);
    
    // Sync en arrière-plan (non bloquant)
    unawaited(_syncToSupabase(data));
  }
  
  Future<void> _syncToSupabase(Data data) async {
    if (!await ConnectivityService.instance.isOnline) return;
    
    try {
      await supabase.from('table').upsert(data.toJson());
    } catch (e) {
      print('⚠️ Sync failed, will retry: $e');
    }
  }
}
```

---

## 🧪 TESTS OFFLINE-FIRST OBLIGATOIRES

Avant chaque commit, tester :

1. **Mode avion au démarrage**
   ```
   Activer mode avion → Fermer app → Relancer
   ✅ ATTENDU : App démarre normalement
   ```

2. **Créer des données offline**
   ```
   Mode avion → Créer plan/note/etc
   ✅ ATTENDU : Sauvegarde locale, ajout à sync queue
   ```

3. **Retour en ligne**
   ```
   Désactiver mode avion
   ✅ ATTENDU : Sync automatique, logs "Réseau rétabli"
   ```

4. **Supabase down**
   ```
   Simuler erreur Supabase
   ✅ ATTENDU : App continue offline proprement
   ```

---

## 📚 RESSOURCES

### Guides Existants

1. **`OFFLINE_FIRST_FINAL.md`** - Implémentation complète
2. **`ARCHITECTURE_OFFLINE_FIRST_CONFIRMEE.md`** - Architecture validée
3. **`USER_REPOSITORY_GUIDE.md`** - Exemple concret

### Services Disponibles

- `LocalStorageService` - Stockage Hive
- `ConnectivityService` - Détection réseau
- `UserRepository` - Exemple offline-first

---

## ⚠️ RAPPEL IMPORTANT

**À CHAQUE modification** :
1. ✅ Penser LOCAL D'ABORD
2. ✅ Supabase = OPTIONNEL
3. ✅ Sync = ARRIÈRE-PLAN
4. ✅ Tester en MODE AVION

**Sinon** :
- ❌ App crash sans Internet
- ❌ Utilisateurs frustrés
- ❌ Violation du principe offline-first

---

**🎯 Utilisez cette checklist AVANT chaque modification !**
