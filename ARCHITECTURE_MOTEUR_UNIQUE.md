# 🏗️ ARCHITECTURE - Moteur Unique de Génération

**Principe** : **1 moteur, 2 portes d'entrée**  
**Avantage** : Cohérence totale, maintenance simple, évolutivité maximale

---

## ⚡ EN 30 SECONDES

```
PRESET (carte)           CUSTOM (formulaire)
      ↓                          ↓
   Criteria.fromPreset      Criteria.fromCustom
      ↓                          ↓
      └──────────────┬───────────┘
                     ↓
         _buildPlanWithSharedEngine
                     ↓
              PLAN OPTIMAL
```

**Avantages** :
- ✅ Pas de duplication code
- ✅ Améliorations profitent aux deux
- ✅ Tests uniques
- ✅ Maintenance simple

---

## 🔄 PIPELINE COMPLET (11 ÉTAPES)

```
┌─────────────────────────────────────────────────────────────┐
│              MOTEUR UNIQUE DE GÉNÉRATION                    │
└─────────────────────────────────────────────────────────────┘

INPUT: Criteria (normalisé)
  ├─ startDate: DateTime
  ├─ daysOfWeek: [1,3,5] (Lun, Mer, Ven)
  ├─ minutesPerDay: 10
  ├─ profile: {goal, level, posture, motivation}
  ├─ books: ['Luc']
  └─ order: 'traditional'

        ↓

ÉTAPE 1: Sélection livres
  └─ BookSelector.select(criteria)
     → [BookInfo(name: 'Luc', totalChapters: 24)]

        ↓

ÉTAPE 2: Durée & intensité cibles
  ├─ IntelligentDurationCalculator.calculate(...)
  │  → 40 jours optimal (science comportementale)
  │
  └─ IntelligentMotivation.adjustDuration(...)
     → 38 jours (ajusté motivation/posture)

        ↓

ÉTAPE 3: Index chapitres (Hive)
  └─ ChapterIndexLoader (déjà hydraté au boot)
     → Luc: 24 chapitres, versets + densités

        ↓

ÉTAPE 4: Génération passages bruts
  └─ ReadingSizer.generateReadingPlan(...)
     → 24 jours bruts:
        Jour 1: Luc 1 (~14 min)
        Jour 2: Luc 2 (~11 min)
        Jour 15: Luc 15:1-10 (~6 min) ❌

        ↓

ÉTAPE 5: Ajustement sémantique
  └─ SemanticPassageBoundaryService.adjustPassageVerses(...)
     → Jour 15: Luc 15:1-32 ✅ (collection complète)
     → Annotation: "Collection de paraboles (Luc 15)"

        ↓

ÉTAPE 6: Ré-estimation temps
  └─ ChapterIndexLoader.estimateMinutesRange(...)
     → Jour 15: ~10 min (vs 6 min avant)

        ↓

ÉTAPE 7: Planification calendrier
  └─ CalendarPlanner.schedule(...)
     → 13/10 (Lun): Luc 1
     → 15/10 (Mer): Luc 2
     → 17/10 (Ven): Luc 3-4
     → ... (saute Mar, Jeu, Sam, Dim)

        ↓

ÉTAPE 8: Scoring comportemental
  └─ PresetBehavioralScorer.enrich(...)
     → Complétion prob: 78%
     → Témoignage: "Jésus au désert"
     → Reasoning scientifique

        ↓

ÉTAPE 9: Enrichissements métadonnées
  ├─ IntelligentPrayerGenerator.generate(...)
  │  → Prières personnalisées par jour
  │
  ├─ ThemesService.themes(...)
  │  → Tags spirituels
  │
  └─ _inferMeditationType(...)
     → Type méditation adapté

        ↓

ÉTAPE 10: Assemblage plan final
  └─ PlanAssembler.assemble(...)
     → Plan complet:
        - 24 jours
        - Temps total: ~240 min
        - Cohérence: 98%
        - Prières: 24 personnalisées

        ↓

ÉTAPE 11: Persistance + Sync + Notifications
  ├─ LocalPlanRepo.save(plan) → Hive
  ├─ SyncQueue.enqueue(plan) → BG sync
  └─ NotificationService.schedule(plan) → Rappels

        ↓

OUTPUT: Plan parfait ✅
```

---

## 🎯 2 POINTS D'ENTRÉE

### Point d'entrée 1 : PRESET (carte)

```dart
// goals_page.dart - Utilisateur tape sur une carte

onTapPresetCard(PlanPreset preset) async {
  final profile = await UserPrefs.getProfile();
  
  // Options UI (optionnel)
  final options = await showPresetOptions(preset);
  // → startDate, daysOfWeek personnalisés
  
  final plan = await PlanService.createFromPreset(
    preset,
    profile,
    options,
  );
  
  // Naviguer vers plan créé
  context.go('/plan/${plan.id}');
}
```

**Transformation** :
```dart
PlanPreset {
  book: 'Luc',
  duration: 40,
  minutesPerDay: 10,
  ...
}
        ↓
Criteria {
  books: ['Luc'],
  minutesPerDay: 10,
  startDate: DateTime.now(),
  daysOfWeek: [1,2,3,4,5],
  profile: {...},
  presetId: preset.id,
  presetName: preset.title,
}
        ↓
_buildPlanWithSharedEngine(criteria)
```

### Point d'entrée 2 : CUSTOM (formulaire)

```dart
// custom_plan_generator_page.dart - Utilisateur remplit formulaire

onSubmitCustomForm() async {
  final profile = await UserPrefs.getProfile();
  
  final form = {
    'books': ['Jean', 'Romains'],  // Multi-livres
    'startDate': selectedDate,
    'daysOfWeek': [1, 3, 5],       // Lun, Mer, Ven
    'minutesPerDay': 15,
    'order': 'chronological',
  };
  
  final plan = await PlanService.createCustom(
    form,
    profile,
  );
  
  context.go('/plan/${plan.id}');
}
```

**Transformation** :
```dart
CustomForm {
  books: ['Jean', 'Romains'],
  minutesPerDay: 15,
  daysOfWeek: [1, 3, 5],
  ...
}
        ↓
Criteria {
  books: ['Jean', 'Romains'],
  minutesPerDay: 15,
  startDate: DateTime(...),
  daysOfWeek: [1, 3, 5],
  profile: {...},
  presetId: null,
  presetName: null,
}
        ↓
_buildPlanWithSharedEngine(criteria)
```

---

## 🧩 MODULES & RESPONSABILITÉS

| Module | Responsabilité | Input | Output |
|--------|---------------|-------|--------|
| **Criteria** | Normaliser entrées | Preset OU Custom | Critères unifiés |
| **BookSelector** | Sélectionner livres | Criteria | List<BookInfo> |
| **DurationCalculator** | Durée optimale | Criteria + Books | DurationCalculation |
| **Motivation** | Ajuster intensité | Durée + Profil | Durée ajustée |
| **ChapterIndexLoader** | Métadonnées | Books | Versets + Densités |
| **ReadingSizer** ⭐ | Passages bruts | Books + Minutes | RawPassages |
| **SemanticBoundary** ⭐ | Cohérence | RawPassages | BoundedPassages |
| **CalendarPlanner** | Dates réelles | Bounded + Calendar | ScheduledDays |
| **BehavioralScorer** ⭐ | Scoring enrichi | Scheduled + Profil | Enriched |
| **PrayerGenerator** | Prières perso | Days + Profil | Prayers |
| **PlanAssembler** | Assemblage final | Enriched + Meta | Plan |
| **LocalPlanRepo** | Persistance | Plan | void (saved) |
| **SyncQueue** | Sync BG | Plan | void (queued) |
| **NotificationService** | Rappels | Plan | void (scheduled) |

---

## 🔗 FLUX DE DONNÉES

### Flux 1 : Preset → Plan

```
PlanPreset
  ├─ id: 'luc_40'
  ├─ book: 'Luc'
  ├─ duration: 40
  └─ minutesPerDay: 10
        ↓
Criteria.fromPreset(preset, profile, options)
  ├─ books: ['Luc']
  ├─ startDate: 13/10/2025
  ├─ daysOfWeek: [1,3,5]
  ├─ minutesPerDay: 10
  └─ profile: {level, goal, ...}
        ↓
_buildPlanWithSharedEngine(criteria)
  ├─ BookInfo(Luc, 24 chap)
  ├─ Duration: 40j → 38j (ajusté)
  ├─ RawPassages: 24 jours
  ├─ BoundedPassages: 24 jours (ajustés)
  ├─ ScheduledDays: 24 dates (Lun/Mer/Ven)
  └─ EnrichedDays: 24 avec prières
        ↓
Plan
  ├─ id: 'plan_123'
  ├─ title: 'Évangile de Luc'
  ├─ duration: 24
  ├─ days: 24 PlanDay
  └─ parameters: {scoring, duration calc, ...}
```

### Flux 2 : Custom → Plan

```
CustomForm
  ├─ books: ['Jean', 'Romains']
  ├─ startDate: 20/10/2025
  ├─ daysOfWeek: [1,2,3,4,5]
  └─ minutesPerDay: 15
        ↓
Criteria.fromCustom(form, profile)
  ├─ books: ['Jean', 'Romains']
  ├─ startDate: 20/10/2025
  ├─ daysOfWeek: [1,2,3,4,5]
  ├─ minutesPerDay: 15
  └─ profile: {level, goal, ...}
        ↓
_buildPlanWithSharedEngine(criteria)
  ├─ BookInfo(Jean, 21 chap) + BookInfo(Romains, 16 chap)
  ├─ Duration: 60j → 58j
  ├─ RawPassages: 37 jours (Jean 21j + Romains 16j)
  ├─ BoundedPassages: 37 ajustés
  ├─ ScheduledDays: 37 dates (Lun-Ven)
  └─ EnrichedDays: 37 avec prières
        ↓
Plan
  ├─ id: 'plan_456'
  ├─ title: 'Plan personnalisé (2 livres)'
  ├─ duration: 37
  ├─ days: 37 PlanDay
  └─ parameters: {...}
```

---

## 🧪 SCÉNARIOS DE VALIDATION

### Scénario 1 : Preset "Luc 40j"

```dart
final preset = PlanPreset(
  id: 'luc_40',
  book: 'Luc',
  duration: 40,
  minutesPerDay: 10,
);

final profile = {
  'level': 'Fidèle régulier',
  'goal': 'Discipline quotidienne',
  'durationMin': 15,
};

final plan = await PlanService.createFromPreset(preset, profile, null);

// Vérifications
assert(plan.book == 'Luc');
assert(plan.days.length > 0);
assert(plan.days.every((d) => d.estimatedMinutes <= 15));
assert(plan.days.where((d) => d.reference.contains('15:1-32')).length == 1); // Luc 15 complet
```

### Scénario 2 : Custom multi-livres

```dart
final form = {
  'books': ['Psaumes', '60, 90, 120'],
  'startDate': DateTime(2025, 10, 20),
  'daysOfWeek': [1, 2, 3, 4, 5], // Lun-Ven
  'minutesPerDay': 12,
  'order': 'traditional',
};

final plan = await PlanService.createCustom(form, profile);

// Vérifications
assert(plan.books.length == 1);
assert(plan.books.first == 'Psaumes');
assert(plan.days.length > 0);
assert(plan.days.first.date.weekday >= 1 && plan.days.first.date.weekday <= 5);
```

### Scénario 3 : Coupe sensible (Matthieu 5-7)

```dart
final form = {
  'books': ['Matthieu'],
  'minutesPerDay': 8, // Peu de temps
};

final plan = await PlanService.createCustom(form, profile);

// Vérifier: Sermon sur la montagne jamais coupé
final sermonDays = plan.days.where((d) => 
  d.reference.contains('5') || 
  d.reference.contains('6') || 
  d.reference.contains('7')
).toList();

// Si Sermon détecté, devrait être complet
final hasSermon = sermonDays.any((d) => d.annotation?.contains('Sermon'));
if (hasSermon) {
  final sermonDay = sermonDays.firstWhere((d) => d.annotation?.contains('Sermon'));
  assert(sermonDay.reference.contains('5:1') && sermonDay.reference.contains('7:29'));
}
```

---

## 📊 DONNÉES & SOURCES

### Sources offline

```
UserProfile (Hive 'local_user')
  ├─ level: String
  ├─ goal: String
  ├─ durationMin: int
  ├─ heartPosture: String?
  ├─ motivation: String?
  ├─ daysOfWeek: List<int>
  └─ bibleVersion: String

ChapterIndex (Hive 'chapter_index')
  ├─ "Luc:1" → {verses: 80, density: 1.1}
  ├─ "Luc:2" → {verses: 52, density: 1.0}
  └─ ... (1,189 chapitres)

LiteraryUnits (Code + JSON optionnel)
  ├─ Matthieu 5-7: Sermon montagne
  ├─ Luc 15: Collection paraboles
  └─ ... (50+ unités)

Presets (Code constants)
  ├─ 17 thèmes spirituels
  ├─ 100+ presets pré-configurés
  └─ Metadata (description, versets, durées)
```

---

## 🧭 RÈGLES CLÉS DU MOTEUR

### Règle 1 : Offline-first

```dart
// ✅ Lecture & écriture via Hive d'abord
await LocalPlanRepo.save(plan);  // Hive

// Sync BG seulement si réseau
if (await hasNetwork()) {
  SyncQueue.enqueue(plan);  // Non-bloquant
}
```

### Règle 2 : Même pipeline (preset = custom)

```dart
// Preset
createFromPreset(preset, ...) 
  → Criteria.fromPreset(...) 
  → _buildPlanWithSharedEngine(criteria)

// Custom
createCustom(form, ...) 
  → Criteria.fromCustom(...) 
  → _buildPlanWithSharedEngine(criteria)

// ✅ Même code métier
```

### Règle 3 : Calendrier réel

```dart
// Saute jours exclus
currentDate = startDate

while (passagesRemaining) {
  while (!daysOfWeek.contains(currentDate.weekday)) {
    currentDate = currentDate.add(Duration(days: 1))
    // Skip Sam/Dim si non sélectionnés
  }
  
  assignPassage(currentDate, passage)
  currentDate = currentDate.add(Duration(days: 1))
}
```

### Règle 4 : Frontières sémantiques

```dart
// Jamais couper un discours critique
if (cutsUnit(passage, unit) && unit.priority == 'critical') {
  passage = includeUnitCompletely(passage, unit)
}

// Exemples protégés:
// - Matthieu 5-7 (Sermon montagne)
// - Luc 15 (Collection paraboles)
// - Jean 15-17 (Discours adieu)
```

### Règle 5 : Scoring final

```dart
// Scoring appliqué à la fin (pas pendant génération)
// → Permet de garder pipeline simple

enrichedDays = days.map((d) => {
  ...d,
  behavioralScore: BehavioralScorer.score(...),
  completionProb: calculateProb(...),
})
```

### Règle 6 : Notifications contextuelles

```dart
// Uniquement sur jours sélectionnés
for (day in plan.days) {
  if (daysOfWeek.contains(day.date.weekday)) {
    NotificationService.schedule(
      date: day.date,
      time: preferredTime,
      message: 'Lecture du jour: ${day.reference}',
    )
  }
}
```

---

## 🧩 INTERFACES COMPLÈTES

### Criteria (Input normalisé)

```dart
class Criteria {
  final DateTime startDate;
  final List<int> daysOfWeek;        // 1..7 (Lun..Dim)
  final int minutesPerDay;
  final Map<String, dynamic> profile; // {level, goal, posture, motivation}
  final List<String> books;          // ['Luc'] ou ['Jean', 'Romains']
  final String order;                // 'traditional', 'chronological', 'thematic'
  final String? presetId;
  final String? presetName;
  final Map<String, dynamic>? options;

  // Factories
  factory Criteria.fromPreset(PlanPreset preset, Map profile, Map? options);
  factory Criteria.fromCustom(Map form, Map profile);
}
```

### Plan (Output)

```dart
class Plan {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String book;              // Premier livre
  final List<String> books;       // Tous les livres
  final int duration;             // Nombre de jours
  final int minutesPerDay;
  final int totalMinutes;
  final DateTime startDate;
  final List<int> daysOfWeek;
  final List<PlanDay> days;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int progress;             // 0-100
  final bool isActive;
  final String? presetId;
  final Map<String, dynamic> parameters;

  // Methods
  Map<String, dynamic> toJson();
  factory Plan.fromJson(Map json);
}
```

### PlanDay (Jour de lecture)

```dart
class PlanDay {
  final int dayNumber;
  final DateTime date;
  final String reference;         // "Luc 15:1-32"
  final String book;
  final int startChapter;
  final int endChapter;
  final int? startVerse;          // Optionnel (verse-level)
  final int? endVerse;
  final int estimatedMinutes;
  final String? annotation;       // "Collection paraboles"
  final bool hasLiteraryUnit;
  final String? unitType;         // "collection", "discourse", ...
  final String? unitPriority;     // "critical", "high", ...
  final List<String>? tags;
  final String? meditationType;   // "contemplation", "enseignement", ...
  final bool isCompleted;
  final DateTime? completedAt;

  // Methods
  Map<String, dynamic> toJson();
}
```

---

## 🎯 AVANTAGES ARCHITECTURE

### 1. Cohérence totale

```dart
// Amélioration dans Sémantique v2
SemanticService.adjustPassageVerses(...) // Upgrade

// Profite automatiquement aux deux :
createFromPreset(...)  ✅
createCustom(...)      ✅
```

### 2. Maintenance simple

```
1 fichier à modifier (plan_service.dart)
1 pipeline à tester
1 documentation à maintenir
```

### 3. Évolutivité

```dart
// Ajouter un nouveau module
ÉTAPE 11.5: AI Enhancement
  └─ GPTService.enhance(plan)
     → Suggestions ultra-personnalisées

// Intégrer simplement dans pipeline
final aiEnhanced = await GPTService.enhance(enrichedDays);
```

### 4. Testabilité

```dart
// Tester le moteur unique
test('Moteur partagé - preset vs custom', () async {
  // Preset
  final preset = PlanPreset(...);
  final planFromPreset = await PlanService.createFromPreset(...);
  
  // Custom (mêmes paramètres)
  final form = {'book': preset.book, ...};
  final planFromCustom = await PlanService.createCustom(...);
  
  // Devraient être similaires
  expect(planFromPreset.duration, closeTo(planFromCustom.duration, 5));
});
```

---

## 🚀 UTILISATION

### Dans l'UI

```dart
// goals_page.dart
ElevatedButton(
  onPressed: () async {
    final plan = await PlanService.createFromPreset(
      selectedPreset,
      userProfile,
      null,
    );
    
    context.go('/plan/${plan.id}');
  },
  child: Text('Commencer'),
)

// custom_plan_generator_page.dart
ElevatedButton(
  onPressed: () async {
    final plan = await PlanService.createCustom(
      formData,
      userProfile,
    );
    
    context.go('/plan/${plan.id}');
  },
  child: Text('Créer plan'),
)
```

---

## ✅ CHECKLIST IMPLÉMENTATION

### Code
- [x] Créer `plan_service.dart` avec moteur partagé
- [x] Créer modèle `Criteria`
- [x] Implémenter `createFromPreset()`
- [x] Implémenter `createCustom()`
- [x] Implémenter `_buildPlanWithSharedEngine()`

### Intégration
- [ ] Remplacer appels existants par `PlanService.createFromPreset()`
- [ ] Remplacer génération custom par `PlanService.createCustom()`
- [ ] Tester les deux flows

### Documentation
- [x] Guide architecture moteur unique
- [ ] Exemples d'utilisation
- [ ] Tests end-to-end

---

**🏗️ MOTEUR UNIQUE COMPLET ! 1 ENGINE, 2 ENTRÉES, PIPELINE UNIFIÉ ! 🎯✨**

