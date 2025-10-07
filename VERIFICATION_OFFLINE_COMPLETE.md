# ✅ Vérification Offline-First - Checklist 6 Points

## 📊 Status actuel de l'implémentation

### ✅ Point 1 : Aucun appel réseau pendant la création ✅

**Fichier :** `goals_page.dart` (lignes 863-919)

```dart
Future<void> _onPlanSelected(PlanPreset preset) async {
  // 1) Options utilisateur via bottom sheet ✅
  final opts = await _showPresetOptionsSheet(...);
  
  // 2) Récupération minutes/jour depuis profil ✅
  final minutesPerDay = _userProfile?['durationMin'] ?? 15;
  
  // 3) Génération passages offline ✅
  final customPassages = _generateOfflinePassagesForPreset(...);
  
  // 4) Création plan local ✅
  await planService.createLocalPlan(...);
  
  // 5) Navigation ✅
  context.go('/onboarding');
}
```

**Verdict :** ✅ **PARFAIT** - Aucun appel réseau, tout est local

---

### ✅ Point 2 : Respect des jours de semaine ✅

**Fichier :** `goals_page.dart` (lignes 1144-1150)

```dart
int produced = 0;
while (produced < targetDays) {
  // Respect réel du calendrier : sauter les jours non cochés
  final dow = cur.weekday; // 1=Mon..7=Sun
  if (!daysOfWeek.contains(dow)) {
    cur = cur.add(const Duration(days: 1));
    continue; // ✅ Passer au jour suivant
  }
  // ... génération passage ...
  produced++;
  cur = cur.add(const Duration(days: 1));
}
```

**Verdict :** ✅ **PARFAIT** - Les jours non sélectionnés sont sautés

---

### ❌ Point 3 : Propagation des minutes/jour ⚠️

**Problème détecté :** `createLocalPlan` **N'ACCEPTE PAS** `daysOfWeek` !

**Fichier :** `plan_service_http.dart` (ligne 253-260)

```dart
Future<Plan> createLocalPlan({
  required String name,
  required int totalDays,
  required DateTime startDate,
  required String books,
  String? specificBooks,
  required int minutesPerDay,
  List<Map<String, dynamic>>? customPassages,
  // ❌ MANQUE : List<int>? daysOfWeek
}) async {
```

**Fichier :** `goals_page.dart` (ligne 888-896)

```dart
await planService.createLocalPlan(
  name: preset.name,
  totalDays: preset.durationDays,
  startDate: opts.startDate,
  books: preset.books,
  specificBooks: preset.specificBooks,
  minutesPerDay: minutesPerDay, // ✅ OK
  customPassages: customPassages, // ✅ OK
  // ❌ MANQUE : daysOfWeek: opts.daysOfWeek
);
```

**Impact :** ⚠️ `daysOfWeek` n'est pas sauvegardé dans le plan

---

### ❌ Point 4 : Stockage local complet ❌

**Problèmes détectés :**

#### A) Modèle `Plan` incomplet

**Fichier :** `plan_models.dart` (lignes 2-23)

```dart
class Plan {
  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final int totalDays;
  final bool isActive;
  final String books;
  final String? specificBooks;
  final int minutesPerDay;
  // ❌ MANQUE : List<int>? daysOfWeek
  // ❌ MANQUE : List<Map<String, dynamic>>? customPassages
}
```

#### B) `_createLocalPlanDays` ignore `customPassages`

**Fichier :** `plan_service_http.dart` (lignes 295-314)

```dart
Future<void> _createLocalPlanDays(String planId, int totalDays, DateTime startDate, String books, List<Map<String, dynamic>>? customPassages) async {
  final List<PlanDay> days = [];
  
  for (int i = 0; i < totalDays; i++) {
    final dayDate = startDate.add(Duration(days: i));
    final day = PlanDay(
      id: '${planId}_day_${i + 1}',
      planId: planId,
      dayIndex: i + 1,
      date: dayDate,
      completed: false,
      // ❌ IGNORE customPassages ! Génère ses propres lectures
      readings: await _generateLocalReadings(books, i + 1),
    );
    days.add(day);
  }
  
  // Sauvegarder les jours
  await cachePlanDays.put('days:$planId', days.map((d) => d.toJson()).toList());
}
```

**Impact :** ❌ Les passages générés dans `GoalsPage` sont **IGNORÉS** !

---

### ❌ Point 5 : Lecture réelle des passages ❌

**Problème :** Les passages générés dans `_generateOfflinePassagesForPreset` ne sont **JAMAIS** utilisés car `_createLocalPlanDays` les ignore et génère ses propres lectures via `_generateLocalReadings`.

**Impact :** ❌ Le calendrier respecté (jours de semaine) est **PERDU**

---

### ✅ Point 6 : Redémarrage & offline ⚠️

**À tester :** Après correction des points 3-5

---

## 🔧 Corrections nécessaires

### 1️⃣ Modifier le modèle `Plan`

**Fichier :** `lib/models/plan_models.dart`

```dart
class Plan {
  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final int totalDays;
  final bool isActive;
  final String books;
  final String? specificBooks;
  final int minutesPerDay;
  final List<int>? daysOfWeek; // ✅ NOUVEAU
  
  Plan({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.totalDays,
    required this.isActive,
    required this.books,
    this.specificBooks,
    required this.minutesPerDay,
    this.daysOfWeek, // ✅ NOUVEAU
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id: j['id'],
    userId: j['user_id'],
    name: j['name'],
    startDate: DateTime.parse(j['start_date']),
    totalDays: j['total_days'],
    isActive: j['is_active'] ?? false,
    books: j['books'] ?? '',
    specificBooks: j['specific_books'],
    minutesPerDay: j['minutes_per_day'] ?? 15,
    daysOfWeek: (j['days_of_week'] as List?)?.cast<int>(), // ✅ NOUVEAU
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'start_date': startDate.toIso8601String(),
    'total_days': totalDays,
    'is_active': isActive,
    'books': books,
    'specific_books': specificBooks,
    'minutes_per_day': minutesPerDay,
    'days_of_week': daysOfWeek, // ✅ NOUVEAU
  };
}
```

### 2️⃣ Modifier `createLocalPlan`

**Fichier :** `lib/services/plan_service_http.dart`

```dart
Future<Plan> createLocalPlan({
  required String name,
  required int totalDays,
  required DateTime startDate,
  required String books,
  String? specificBooks,
  required int minutesPerDay,
  List<Map<String, dynamic>>? customPassages,
  List<int>? daysOfWeek, // ✅ NOUVEAU
}) async {
  final planId = const Uuid().v4();
  
  final plan = Plan(
    id: planId,
    userId: 'local_user',
    name: name,
    totalDays: totalDays,
    startDate: startDate,
    isActive: true,
    books: books,
    specificBooks: specificBooks,
    minutesPerDay: minutesPerDay,
    daysOfWeek: daysOfWeek, // ✅ NOUVEAU
  );
  
  await cachePlans.put('active_plan', plan.toJson());
  
  // ✅ Passer customPassages ET daysOfWeek
  await _createLocalPlanDays(planId, totalDays, startDate, books, customPassages, daysOfWeek);
  
  telemetry.event('plan_created_locally', {
    'plan_id': planId,
    'name': name,
    'total_days': totalDays,
    'books': books,
    'days_of_week': daysOfWeek?.join(','), // ✅ NOUVEAU
  });
  
  return plan;
}
```

### 3️⃣ Modifier `_createLocalPlanDays` pour UTILISER customPassages

**Fichier :** `lib/services/plan_service_http.dart`

```dart
Future<void> _createLocalPlanDays(
  String planId,
  int totalDays,
  DateTime startDate,
  String books,
  List<Map<String, dynamic>>? customPassages,
  List<int>? daysOfWeek, // ✅ NOUVEAU
) async {
  final List<PlanDay> days = [];
  
  // ✅ PRIORITÉ : Utiliser customPassages si disponibles
  if (customPassages != null && customPassages.isNotEmpty) {
    print('✅ Utilisation des passages personnalisés (${customPassages.length})');
    
    for (int i = 0; i < customPassages.length; i++) {
      final passage = customPassages[i];
      final dayDate = DateTime.parse(passage['date'] as String);
      
      final day = PlanDay(
        id: '${planId}_day_${i + 1}',
        planId: planId,
        dayIndex: i + 1,
        date: dayDate,
        completed: false,
        readings: [
          ReadingRef(
            book: passage['book'] as String,
            range: passage['reference'] as String,
            url: null,
          ),
        ],
      );
      days.add(day);
    }
  } else {
    // ✅ FALLBACK : Générer passages génériques
    print('⚠️ Pas de passages personnalisés, génération générique');
    
    var currentDate = startDate;
    int dayIndex = 1;
    
    while (days.length < totalDays) {
      // Respecter daysOfWeek si disponible
      if (daysOfWeek != null && !daysOfWeek.contains(currentDate.weekday)) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }
      
      final day = PlanDay(
        id: '${planId}_day_$dayIndex',
        planId: planId,
        dayIndex: dayIndex,
        date: currentDate,
        completed: false,
        readings: await _generateLocalReadings(books, dayIndex),
      );
      days.add(day);
      
      dayIndex++;
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
  
  // Sauvegarder les jours
  await cachePlanDays.put('days:$planId', days.map((d) => d.toJson()).toList());
  print('✅ ${days.length} jours de plan sauvegardés localement');
}
```

### 4️⃣ Mise à jour de l'appel dans `GoalsPage`

**Fichier :** `lib/views/goals_page.dart`

```dart
await planService.createLocalPlan(
  name: preset.name,
  totalDays: preset.durationDays,
  startDate: opts.startDate,
  books: preset.books,
  specificBooks: preset.specificBooks,
  minutesPerDay: minutesPerDay,
  customPassages: customPassages, // ✅ OK
  daysOfWeek: opts.daysOfWeek, // ✅ NOUVEAU - À ajouter
);
```

---

## 📊 Résumé des modifications nécessaires

| Point | Status | Action requise |
|-------|--------|----------------|
| 1. Pas d'appel réseau | ✅ OK | Aucune |
| 2. Respect jours semaine | ✅ OK | Aucune |
| 3. Propagation minutes/jour | ⚠️ Partiel | Ajouter `daysOfWeek` param |
| 4. Stockage local complet | ❌ NON | 3 modifications (Plan model + service + appel) |
| 5. Lecture passages | ❌ NON | Utiliser `customPassages` |
| 6. Offline redémarrage | ⏳ À tester | Après corrections |

---

## 🔧 Plan de correction (30 minutes)

### Étape 1 : Modèle `Plan` (5 min)
- Ajouter champ `daysOfWeek` (`List<int>?`)
- Ajouter dans constructeur, `fromJson`, `toJson`

### Étape 2 : Service `PlanService` (15 min)
- Ajouter param `daysOfWeek` dans `createLocalPlan`
- Modifier `_createLocalPlanDays` pour :
  - Accepter `daysOfWeek`
  - **UTILISER** `customPassages` en priorité
  - Fallback générique respecte `daysOfWeek`

### Étape 3 : Appel depuis `GoalsPage` (2 min)
- Ajouter `daysOfWeek: opts.daysOfWeek` dans l'appel

### Étape 4 : Tests (8 min)
- ✅ Créer plan Lun-Mer-Ven (3/7)
- ✅ Vérifier 40 passages = ~13-14 semaines
- ✅ Vérifier dates respectent calendrier
- ✅ Redémarrer en mode avion → plan accessible

---

## ⚠️ Pièges évités

✅ **Première date non valide :** La génération commence bien à `startDate` et avance jusqu'au premier jour valide  
✅ **DST (changement d'heure) :** Utilisation de `DateTime(year, month, day)` sans heures  
⚠️ **`customPassages` ignorés :** **DOIT ÊTRE CORRIGÉ** (Point 4)  
⚠️ **`daysOfWeek` non stocké :** **DOIT ÊTRE CORRIGÉ** (Point 3)  

---

## 🎯 Impact des corrections

### Avant corrections
```
Utilisateur sélectionne Lun-Mer-Ven
   ↓
_generateOfflinePassagesForPreset génère 40 passages respectant calendrier
   ↓
createLocalPlan IGNORE customPassages ❌
   ↓
_createLocalPlanDays génère 40 jours CONSÉCUTIFS ❌
   ↓
Plan créé avec TOUS les jours (pas seulement Lun-Mer-Ven) ❌
```

### Après corrections
```
Utilisateur sélectionne Lun-Mer-Ven
   ↓
_generateOfflinePassagesForPreset génère 40 passages respectant calendrier
   ↓
createLocalPlan reçoit customPassages + daysOfWeek ✅
   ↓
_createLocalPlanDays UTILISE customPassages ✅
   ↓
Plan créé avec 40 jours SEULEMENT Lun-Mer-Ven ✅
   ↓
Redémarrage offline → passages toujours accessibles ✅
```

---

## 📋 Tests express à faire (après corrections)

### Test 1 : Tous les jours (7/7)
- Sélectionner preset 40 jours
- Cocher tous les jours
- Vérifier : 40 passages sur 40 jours consécutifs
- ✅ Durée calendrier = 40 jours

### Test 2 : Lun-Mer-Ven (3/7)
- Sélectionner preset 40 jours
- Cocher uniquement Lun, Mer, Ven
- Vérifier : 40 passages sur ~13-14 semaines
- ✅ Durée calendrier ≈ 94 jours (13.4 semaines)

### Test 3 : Week-end (2/7)
- Sélectionner preset 40 jours
- Cocher uniquement Sam, Dim
- Vérifier : 40 passages sur 20 semaines
- ✅ Durée calendrier = 140 jours

### Test 4 : StartDate non valide
- Sélectionner preset 30 jours
- StartDate = Mardi
- Cocher uniquement Lun, Mer, Ven
- Vérifier : Jour 1 = Mercredi (prochain jour valide)

### Test 5 : Mode avion
- Créer plan en mode avion
- Redémarrer app en mode avion
- ✅ Plan listé
- ✅ Passages accessibles
- ✅ Aucune erreur réseau

---

## ✅ Checklist finale (après corrections)

- [ ] Modèle `Plan` a `daysOfWeek` + `customPassages` (optionnels)
- [ ] `createLocalPlan` accepte `daysOfWeek` en paramètre
- [ ] `_createLocalPlanDays` utilise `customPassages` en priorité
- [ ] `_createLocalPlanDays` respecte `daysOfWeek` en fallback
- [ ] Appel depuis `GoalsPage` passe `daysOfWeek`
- [ ] Tests 1-5 passent tous
- [ ] Mode avion fonctionne parfaitement

---

**Date :** 7 octobre 2025  
**Status :** ⚠️ **CORRECTIONS NÉCESSAIRES**  
**Priorité :** 🔥 **P0** - Bloquant pour l'offline-first complet  
**Durée estimée :** 30 minutes
