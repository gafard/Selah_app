# 📊 DIAGRAMME DE SÉQUENCE - Génération Plan Complète

**Architecture** : Moteur unique, 15 intelligences coordonnées

---

## 🎯 SÉQUENCE COMPLÈTE (Preset → Plan)

```
┌──────┐  ┌────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
│ User │  │ UI     │  │ PlanService│  │ Intelligences│  │ Storage   │
└──────┘  └────────┘  └────────────┘  └────────────┘  └────────────┘
   │          │              │                │               │
   │ Tap carte preset        │                │               │
   ├─────────>│              │                │               │
   │          │              │                │               │
   │          │ createFromPreset(preset)      │               │
   │          ├─────────────>│                │               │
   │          │              │                │               │
   │          │              │ Criteria.fromPreset()          │
   │          │              ├───────┐        │               │
   │          │              │       │        │               │
   │          │              │<──────┘        │               │
   │          │              │                │               │
   │          │              │ _buildPlanWithSharedEngine()   │
   │          │              ├───────┐        │               │
   │          │              │       │        │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 1: BookSelector   │   │
   │          │              │   │ → ['Luc', 24 chap]     │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 2: DurationCalc   │   │
   │          │              │   │ → 40j optimal          │   │
   │          │              ├──>│   (science + témoin.)  │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 3: Motivation     │   │
   │          │              │   │ → 38j ajusté           │   │
   │          │              ├──>│   (posture/motiv)      │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 4: ChapterIndex   │   │
   │          │              │   │ → Versets + densités   │   │
   │          │              ├──>│   (Hive lookup)        │<──┤
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 5: ReadingSizer   │   │
   │          │              │   │ → 24 jours bruts       │   │
   │          │              ├──>│   (~10 min/jour)       │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 6: Semantic v2    │   │
   │          │              │   │ → Luc 15 complet       │   │
   │          │              ├──>│   (convergence 5×)     │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 7: ChapterIndex   │   │
   │          │              │   │ → Ré-estimation        │   │
   │          │              ├──>│   (temps final ±10%)   │<──┤
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 8: Calendar       │   │
   │          │              │   │ → 24 dates Lun/Mer/Ven │   │
   │          │              ├──>│   (saute Mar/Jeu/etc)  │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 9: Behavioral     │   │
   │          │              │   │ → Score 0.85           │   │
   │          │              ├──>│   + Complétion 78%     │   │
   │          │              │   │   + Témoignages        │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 10: PrayerGen     │   │
   │          │              │   │ → 24 prières perso     │   │
   │          │              ├──>│   (QCM + templates)    │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │   ┌───▼────────────────────┐   │
   │          │              │   │ ÉTAPE 11: Assemble      │   │
   │          │              │   │ → Plan complet         │   │
   │          │              │<──┤   {24 days, meta}      │   │
   │          │              │   └────────────────────────┘   │
   │          │              │                │               │
   │          │              │ save(plan)     │               │
   │          │              ├────────────────────────────────>│
   │          │              │                │               │
   │          │              │ enqueueSync(plan)             │
   │          │              ├────────────────────────────────>│
   │          │              │                │               │
   │          │              │ scheduleNotifications()        │
   │          │              ├───────┐        │               │
   │          │              │       │        │               │
   │          │              │<──────┘        │               │
   │          │              │                │               │
   │          │<─────────────┤ Plan created   │               │
   │          │              │                │               │
   │ Navigate to plan        │                │               │
   │<─────────┤              │                │               │
   │          │              │                │               │
```

**Temps total** : < 1 seconde ⚡

---

## 🔄 SÉQUENCE CUSTOM (Multi-livres)

```
User fills form
  │
  ├─ Books: ['Jean', 'Romains']
  ├─ Days: [1, 3, 5]  (Lun, Mer, Ven)
  ├─ Minutes: 15
  └─ Order: 'chronological'
  │
  ↓
PlanService.createCustom(form, profile)
  │
  ├─ Criteria.fromCustom(form)
  │  ├─ books: ['Jean', 'Romains']
  │  └─ ... (normalize)
  │
  ↓
_buildPlanWithSharedEngine(criteria)
  │
  ├─ BookSelector
  │  ├─ Jean: 21 chapitres
  │  └─ Romains: 16 chapitres
  │
  ├─ DurationCalculator
  │  └─ 60 jours optimal (multi-livres)
  │
  ├─ ReadingSizer
  │  ├─ Jean: 21 jours
  │  └─ Romains: 16 jours
  │  └─ Total: 37 jours
  │
  ├─ Semantic v2
  │  ├─ Jean 6:22-71 complet (discours pain)
  │  └─ Romains 8:1-39 complet
  │
  ├─ Calendar
  │  └─ 37 dates sur Lun/Mer/Ven
  │     (13/10, 15/10, 17/10, ...)
  │
  ├─ BehavioralScorer
  │  └─ Score + complétion prob
  │
  └─ Assemble
     └─ Plan 37 jours, 2 livres
```

---

## ⚡ SÉQUENCE DAILY (Quotidien)

```
App Launch (Daily)
  │
  ├─ Load active plan
  │  └─ Hive.box('local_plans')
  │
  ├─ Detect today's passage
  │  └─ plan.days.where(d => d.date == today)
  │
  ├─ Check missed days
  │  ├─ if (missedDays.isNotEmpty)
  │  └─> PlanCatchupService.suggestOptions()
  │      ├─ 1 jour → "Reporter"
  │      ├─ 2 jours → "Combiner"
  │      └─ 3+ → "Skip ou Prolonger"
  │
  ├─ Generate motivation
  │  └─> IntelligentMotivation.generate(context)
  │      ├─ Streak 3j → "Bravo 🔥"
  │      ├─ Comeback → "Content de te revoir 💪"
  │      └─ Normal → Message encouragement
  │
  └─ Display Home
     └─ Motivation message + Today's passage
```

---

## 📊 FLUX DE DONNÉES (Exemple Luc 40j)

```
INPUT
─────
PlanPreset {
  book: 'Luc',
  duration: 40,
  minutesPerDay: 10
}

Profile {
  level: 'Fidèle régulier',
  goal: 'Discipline',
  durationMin: 15
}

↓

ÉTAPE 1: BookSelector
─────────────────────
books = ['Luc']
totalChapters = 24

↓

ÉTAPE 2-3: Duration + Motivation
──────────────────────────────
baseDuration = 40j (science)
adjustedDuration = 38j (motivation ×0.95)
  
↓

ÉTAPE 4-5: ReadingSizer + Semantic
────────────────────────────────
RawPassages (24 jours):
  1. Luc 1 (14 min)
  2. Luc 2 (11 min)
  ...
  15. Luc 15:1-10 (6 min) ❌

BoundedPassages (24 jours):
  1. Luc 1:1-80 (14 min)
  2. Luc 2:1-52 (11 min)
  ...
  15. Luc 15:1-32 (10 min) ✅
      📖 Collection de paraboles
      🔴 Priorité: critique

↓

ÉTAPE 6-7: Calendar + ReEstimate
──────────────────────────────
ScheduledDays (24 dates):
  13/10 (Lun): Luc 1 (14 min)
  15/10 (Mer): Luc 2 (11 min)
  17/10 (Ven): Luc 3-4 (12 min)
  ...

↓

ÉTAPE 8-9: Behavioral + Enrich
────────────────────────────
EnrichedDays:
  + completionProb: 78%
  + testimonies: ['Jésus au désert']
  + scientificReasoning: "Optimal habit formation"
  + prayers: 24 personnalisées

↓

ÉTAPE 10-11: Assemble + Save
──────────────────────────
Plan {
  id: 'plan_luc_20251013',
  title: 'Évangile de Luc',
  duration: 24,
  days: 24 PlanDay,
  totalMinutes: ~240 min,
  progress: 0,
  isActive: true
}

↓ Save Hive

↓ Enqueue Sync

↓ Schedule Notifications

OUTPUT
──────
✅ Plan créé
✅ 24 jours planifiés
✅ Notifications programmées
✅ Sync queued (BG)
```

---

## 🔀 COMPARAISON PRESET VS CUSTOM

### Preset Flow

```
PlanPreset
  ↓
Criteria.fromPreset()
  ├─ books: [preset.book]           ← 1 livre
  ├─ duration: preset.duration       ← Pré-défini
  ├─ minutesPerDay: preset.minutes   ← Pré-défini
  └─ presetId: preset.id             ← Référence
  ↓
_buildPlanWithSharedEngine()
  ↓
Plan (avec metadata preset)
```

### Custom Flow

```
CustomForm
  ↓
Criteria.fromCustom()
  ├─ books: form.books               ← Multi-livres possible
  ├─ duration: null                  ← Calculé par DurationCalc
  ├─ minutesPerDay: form.minutes     ← User choice
  └─ presetId: null                  ← Pas de preset
  ↓
_buildPlanWithSharedEngine()
  ↓
Plan (custom, même qualité)
```

**Résultat** : Même pipeline, même qualité, zéro duplication ✅

---

## 📊 INTERACTIONS INTELLIGENCES

```
                    MOTEUR UNIQUE
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    PRESET FLOW      CUSTOM FLOW      DAILY FLOW
         │                │                │
         ↓                ↓                ↓
    
1️⃣ PresetGenerator  BookSelector    Motivation
    ↓ enrichi par        │                ↓
2️⃣ BehavioralScorer ────┘          PlanCatchup
    ↓                                     │
3️⃣ DurationCalculator ←──────────────────┘
    ↓                    (même pour tous)
4️⃣ Motivation
    ↓
5️⃣ ReadingSizer ←─────── ChapterIndex (Hive)
    ↓
6️⃣ Semantic v2  ←─────── ChapterIndex (versets)
    ↓
7️⃣ ChapterIndex (ré-estimation)
    ↓
8️⃣ CalendarPlanner
    ↓
9️⃣ BehavioralScorer (enrichissement)
    ↓
🔟 PrayerGenerator ←───── StableRandom (seed)
    ↓
1️⃣1️⃣ PlanAssembler
    ↓
1️⃣2️⃣ LocalRepo (Hive)
    ↓
1️⃣3️⃣ SyncQueue (BG)
    ↓
1️⃣4️⃣ Notifications

DAILY RUNTIME:
  ├─ VersionCompare (reader)
  ├─ ReadingMemory (reader)
  └─ HeartPosture (analysis)
```

---

## 🎯 POINTS D'INJECTION

### Où chaque intelligence intervient

| Intelligence | Étape | Input | Output |
|-------------|-------|-------|--------|
| PresetGenerator | 0 (pré-moteur) | Profile | Cartes présets |
| BehavioralScorer ⭐ | 0 (pré-moteur) | Presets | Scores enrichis |
| DurationCalculator | 2 | Criteria + Books | Durée optimale |
| Motivation | 3 | Duration + Profile | Durée ajustée |
| ChapterIndex ⭐ | 4, 7 | Books, Passages | Métadonnées |
| ReadingSizer ⭐ | 5 | Books + Minutes | Passages bruts |
| Semantic v2 ⭐ | 6 | Raw passages | Passages ajustés |
| CalendarPlanner | 8 | Passages + Dates | Jours schedulés |
| BehavioralScorer | 9 | Scheduled + Profile | Enriched |
| PrayerGenerator | 10 | Days + Profile | Prières |
| StableRandom | 10 | PlanId | Seed |
| PlanCatchup | Daily | Plan + Today | Options |
| IntelligentMotivation | Daily | Streak + Context | Message |
| HeartPosture | Analysis | Journal + Answers | Posture |
| VersionCompare | Reader | VerseId | Versions |
| ReadingMemory | Reader | VerseId | Queue |

---

## ⏱️ TIMELINE

```
t=0ms     : User tap
t=10ms    : Criteria création
t=50ms    : BookSelector
t=100ms   : DurationCalculator
t=120ms   : Motivation
t=150ms   : ChapterIndex lookup (Hive, fast)
t=250ms   : ReadingSizer (24 passages)
t=500ms   : Semantic v2 (convergence 24×)
t=550ms   : ChapterIndex ré-estimation
t=600ms   : Calendar mapping
t=650ms   : BehavioralScorer
t=800ms   : PrayerGenerator (24 prières)
t=850ms   : Assemble
t=900ms   : Save Hive
t=920ms   : Enqueue sync
t=950ms   : Schedule notifications
t=1000ms  : Plan ready ✅

TOTAL: ~1 seconde
```

**Performance** : ✅ Excellent (< 1s pour plan complet)

---

## 🧪 VALIDATIONS

### Test 1 : Preset = Custom (mêmes params)

```dart
final preset = PlanPreset(book: 'Luc', duration: 40, minutes: 10);
final planPreset = await PlanService.createFromPreset(preset, profile, null);

final form = {'books': ['Luc'], 'minutesPerDay': 10};
final planCustom = await PlanService.createCustom(form, profile);

// Devraient être similaires
expect(planPreset.duration, closeTo(planCustom.duration, 3));
expect(planPreset.days.length, closeTo(planCustom.days.length, 3));
```

### Test 2 : Cohérence sémantique

```dart
final plan = await PlanService.createFromPreset(...);

// Vérifier Luc 15 jamais coupé
final luc15 = plan.days.firstWhere((d) => d.reference.contains('15'));
expect(luc15.reference, contains('15:1-32'));
expect(luc15.annotation, contains('Collection'));
```

### Test 3 : Calendrier correct

```dart
final plan = await PlanService.createCustom(
  {'books': ['Psaumes'], 'daysOfWeek': [1, 3, 5]},
  profile,
);

// Tous les jours devraient être Lun/Mer/Ven
for (final day in plan.days) {
  expect([1, 3, 5], contains(day.date.weekday));
}
```

---

## 🏆 AVANTAGES ARCHITECTURE

### 1. Cohérence

```
✅ Même logique preset/custom
✅ Même qualité output
✅ Même tests
```

### 2. Maintenance

```
✅ 1 fichier à modifier (plan_service.dart)
✅ 1 pipeline à optimiser
✅ Amélioration profite aux 2
```

### 3. Évolutivité

```
✅ Ajouter module : 1 ligne dans pipeline
✅ Changer ordre : réorganiser étapes
✅ A/B testing : facile (même code)
```

### 4. Offline-first

```
✅ Toutes données en Hive
✅ Sync BG non-bloquante
✅ Notifications locales
```

---

**📊 SÉQUENCE COMPLÈTE DOCUMENTÉE ! MOTEUR UNIQUE ORCHESTRÉ ! 🎯✨**

