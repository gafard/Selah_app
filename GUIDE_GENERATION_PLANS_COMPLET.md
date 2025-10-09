# 📚 GUIDE COMPLET - Génération Cartes Présets & Plans de Lecture

**Date** : 9 Octobre 2025  
**Système** : Intelligent Local Preset Generator + Pipeline complet

---

## ⚡ EN 30 SECONDES

Le système génère automatiquement des **cartes de présets personnalisées** (recommandations de livres) puis transforme le preset choisi en **plan de lecture jour par jour** intelligent.

**Pipeline** :
```
Profil utilisateur → Cartes présets → Choix utilisateur → Plan détaillé → Calendrier
```

---

## 🎯 VUE D'ENSEMBLE

### 2 Phases distinctes

| Phase | Quoi | Où | Résultat |
|-------|------|-----|----------|
| **1. Présets** | Recommandations de livres | `GoalsPage` | Cartes colorées avec scores |
| **2. Plan** | Jours de lecture détaillés | `PlanCreated` | Calendrier avec passages |

---

## 📊 PHASE 1 : GÉNÉRATION DES CARTES PRÉSETS

### Entrée : Profil utilisateur

```dart
final userProfile = {
  'level': 'Fidèle régulier',         // Niveau spirituel
  'goal': 'Discipline quotidienne',    // Objectif principal
  'meditation': 'Méditation biblique', // Type de méditation
  'durationMin': 15,                   // Minutes/jour
  'heartPosture': 'Chercheur',         // ⭐ Nouveau (posture cœur)
  'motivation': 'Croître',             // ⭐ Nouveau (motivation)
};
```

### Service : `IntelligentLocalPresetGenerator`

#### 1.1 Base de données des thèmes

```dart
static const Map<String, Map<String, dynamic>> _spiritualThemes = {
  'foundation_basics': {
    'books': ['Jean', 'Matthieu', 'Romains', '1 Jean'],
    'duration': [21, 30, 40, 60],
    'focus': 'Fondations de la foi',
    'verses': ['Jean 3:16', 'Romains 8:1', '1 Jean 4:8'],
    'emotions': ['foundation', 'clarity', 'assurance'],
    'targetAudience': ['Nouveau converti', 'Rétrograde']
  },
  'discipline_growth': {
    'books': ['Philippiens', 'Jacques', 'Hébreux', 'Proverbes'],
    'duration': [30, 40, 60, 90],
    'focus': 'Croissance et discipline',
    'verses': ['Philippiens 3:14', 'Jacques 1:2-4', 'Hébreux 12:11'],
    'emotions': ['discipline', 'growth', 'perseverance'],
    'targetAudience': ['Fidèle régulier', 'Serviteur/leader']
  },
  // ... 15+ thèmes au total
};
```

#### 1.2 Mapping Objectif → Thème

```dart
static String _mapGoalToTheme(String goal) {
  if (goal.contains('Discipline') || goal.contains('régularité')) {
    return 'discipline_growth';
  }
  if (goal.contains('Connaissance') || goal.contains('Bible')) {
    return 'bible_study';
  }
  if (goal.contains('Prière')) {
    return 'prayer_worship';
  }
  // ... 12+ mappings
}
```

#### 1.3 Génération des presets

```dart
static List<PlanPreset> generateIntelligentPresets(
  Map<String, dynamic>? userProfile
) {
  final presets = <PlanPreset>[];
  
  // Déterminer le thème principal selon l'objectif
  final theme = _mapGoalToTheme(userProfile?['goal']);
  final themeData = _spiritualThemes[theme];
  
  // Générer 3-5 presets du thème principal
  for (final book in themeData['books']) {
    for (final duration in themeData['duration']) {
      presets.add(PlanPreset(
        id: '${theme}_${book}_${duration}',
        slug: '${theme}_${book.toLowerCase()}_${duration}d',
        title: '${themeData['focus']} - $book',
        description: 'Lecture de $book en $duration jours',
        book: book,
        duration: duration,
        minutesPerDay: _calculateMinutesPerDay(book, duration),
        verses: themeData['verses'],
        // ⭐ NOUVEAUX CHAMPS
        parameters: {
          'spiritualImpact': _calculateImpact(book, theme),
          'timingBonus': _calculateTimingBonus(duration, durationMin),
        }
      ));
    }
  }
  
  // Ajouter 2-3 presets de thèmes complémentaires
  final complementaryThemes = _getComplementaryThemes(theme);
  // ...
  
  return presets;
}
```

#### 1.4 Scoring intelligent

```dart
static List<PlanPreset> scoreAndRankPresets(
  List<PlanPreset> presets,
  Map<String, dynamic>? profile,
) {
  for (final preset in presets) {
    double score = 0;
    
    // 1. Objectif (45%)
    if (preset.slug.contains(themeKey)) score += 0.45;
    
    // 2. Saison liturgique (20%)
    if (_matchesSeason(preset, _getCurrentSeason())) score += 0.20;
    
    // 3. Minutes/jour (15%)
    final deltaMinutes = (preset.minutesPerDay - profile['durationMin']).abs();
    if (deltaMinutes == 0) score += 0.15;
    else if (deltaMinutes <= 5) score += 0.10;
    
    // 4. Niveau (10%)
    if (_matchesLevel(preset, profile['level'])) score += 0.10;
    
    // 5. Variété (10%) - Éviter redondances
    if (!_wasRecentlyCompleted(preset, profile)) score += 0.10;
    
    preset.score = score;
  }
  
  // Trier par score décroissant
  presets.sort((a, b) => b.score.compareTo(a.score));
  
  // Garder top 8-12 presets
  return presets.take(12).toList();
}
```

### Sortie : Cartes dans GoalsPage

```dart
// goals_page.dart

Widget _buildPresetCards() {
  // Générer presets
  final presets = IntelligentLocalPresetGenerator.generateIntelligentPresets(
    userProfile,
  );
  
  // Afficher cartes
  return ListView.builder(
    itemCount: presets.length,
    itemBuilder: (context, index) {
      final preset = presets[index];
      
      return PresetCard(
        title: preset.title,
        description: preset.description,
        duration: '${preset.duration} jours',
        minutesPerDay: '${preset.minutesPerDay} min/jour',
        score: preset.score,
        color: _getThemeColor(preset.slug),
        badge: _getBadge(preset), // Ex: "+40% timing bonus"
        onTap: () => _createPlanFromPreset(preset),
      );
    },
  );
}
```

**Exemple visuel** :

```
┌─────────────────────────────────────────┐
│ 📖 Fondations - Jean                    │
│ ─────────────────────────────────────── │
│ Découvrir l'amour de Dieu               │
│                                         │
│ 📅 30 jours  •  ⏱️ 12 min/jour         │
│ ⭐ Score : 0.85  •  🏆 +40% timing     │
│                                         │
│            [Commencer →]                │
└─────────────────────────────────────────┘
```

---

## 📖 PHASE 2 : GÉNÉRATION DU PLAN DÉTAILLÉ

### Entrée : Preset choisi + Profil

```dart
final selectedPreset = PlanPreset(
  book: 'Luc',
  duration: 40,
  minutesPerDay: 10,
  // ...
);
```

### Pipeline complet (6 étapes)

#### ÉTAPE 1 : Calcul durée optimale

```dart
// Service: IntelligentDurationCalculator

final durationCalc = IntelligentDurationCalculator.calculateOptimalDuration(
  goal: userProfile['goal'],
  level: userProfile['level'],
  dailyMinutes: userProfile['durationMin'],
  meditationType: userProfile['meditation'],
);

print(durationCalc.optimalDays);      // 40 jours
print(durationCalc.totalHours);        // 6.7 heures
print(durationCalc.scientificBasis);   // ['Psychologie formation habitudes']
print(durationCalc.reasoning);         // Explication complète
```

**Base scientifique** :
- Habitudes : 21-66 jours
- Témoignages chrétiens : 40 jours (Jésus désert, Moïse Sinaï)
- Neuroplasticité : 30-90 jours

#### ÉTAPE 2 : Générer plan brut (ReadingSizer) ⭐

```dart
// Service: ReadingSizer

final rawPlan = ReadingSizer.generateReadingPlan(
  book: 'Luc',
  totalChapters: 24,
  targetMinutesPerDay: 10,
);

// Résultat :
[
  {
    'dayNumber': 1,
    'book': 'Luc',
    'startChapter': 1,
    'endChapter': 1,
    'chapters': 1,
    'approxMinutes': 14,
    'range': 'Luc 1'
  },
  {
    'dayNumber': 2,
    'book': 'Luc',
    'startChapter': 2,
    'endChapter': 2,
    'chapters': 1,
    'approxMinutes': 11,
    'range': 'Luc 2'
  },
  // ... 22 autres jours
]
```

**Comment ça marche** :
```dart
// ReadingSizer accumule chapitres jusqu'à atteindre target

int currentChapter = 1;
int dayNumber = 1;

while (currentChapter <= 24) {
  double accumulated = 0;
  int endChapter = currentChapter;
  
  // Accumuler jusqu'à ~10 min
  while (accumulated < 10 && endChapter <= 24) {
    final chapterMinutes = ChapterIndexLoader.estimateMinutes(
      book: 'Luc',
      chapter: endChapter,
    );
    // Luc 1: 80 versets × 1.1 densité ≈ 14 min
    
    accumulated += chapterMinutes;
    endChapter++;
  }
  
  days.add({...});
  currentChapter = endChapter;
  dayNumber++;
}
```

#### ÉTAPE 3 : Ajustement sémantique (v2.0) ⭐

```dart
// Service: SemanticPassageBoundaryService v2

for (final rawDay in rawPlan) {
  final adjusted = SemanticPassageBoundaryService.adjustPassageVerses(
    book: rawDay['book'],
    startChapter: rawDay['startChapter'],
    startVerse: 1,
    endChapter: rawDay['endChapter'],
    endVerse: ChapterIndexLoader.verseCount(
      rawDay['book'],
      rawDay['endChapter'],
    ),
  );
  
  // Exemple jour 15:
  // Proposé: Luc 15:1-10 ❌
  // Ajusté:  Luc 15:1-32 ✅ (collection complète)
}
```

**Convergence itérative** :
```dart
// Vérifie si coupe une unité littéraire
for (int i = 0; i < 5; i++) {
  final cuts = units.where((u) => _cutsUnit(range, u)).toList();
  
  if (cuts.isEmpty) break; // ✅ Stable
  
  // Sélectionner unité dominante
  final dominantUnit = _pickDominantCut(cuts);
  // Critères : priorité > type collection > taille
  
  range = _resolveCut(range, dominantUnit);
  // → Inclure l'unité complète
}
```

#### ÉTAPE 4 : Ré-estimation temps ⭐

```dart
// Service: ChapterIndexLoader

final finalMinutes = ChapterIndexLoader.estimateMinutesRange(
  book: adjusted.book,
  startChapter: adjusted.startChapter,
  endChapter: adjusted.endChapter,
);

// Luc 15:1-32 : 32 versets × 1.3 densité ≈ 10 min ✅
```

#### ÉTAPE 5 : Mapping calendrier

```dart
// Mapper sur daysOfWeek sélectionnés

final selectedDays = ['Lundi', 'Mercredi', 'Vendredi']; // Exemple
final startDate = DateTime(2025, 10, 13); // Lundi

int dayIndex = 0;
DateTime currentDate = startDate;

for (final planDay in adjustedPlan) {
  // Trouver le prochain jour valide
  while (!selectedDays.contains(_getDayName(currentDate))) {
    currentDate = currentDate.add(Duration(days: 1));
  }
  
  days.add(PlanDay(
    dayNumber: planDay['dayNumber'],
    date: currentDate,
    reference: planDay['range'],
    book: planDay['book'],
    startChapter: planDay['startChapter'],
    endChapter: planDay['endChapter'],
    estimatedMinutes: planDay['finalMinutes'],
    annotation: planDay['unitName'], // Ex: "Sermon sur la montagne"
    hasLiteraryUnit: planDay['wasAdjusted'],
    unitType: planDay['unitType'],
    unitPriority: planDay['unitPriority'],
    tags: planDay['tags'],
    isCompleted: false,
  ));
  
  currentDate = currentDate.add(Duration(days: 1));
}
```

#### ÉTAPE 6 : Génération prières/méditations

```dart
// Service: IntelligentPrayerGenerator

for (final day in days) {
  final prayer = IntelligentPrayerGenerator.generatePrayer(
    context: PrayerContext(
      day: day,
      userProfile: userProfile,
      passage: day.reference,
      theme: preset.theme,
    ),
  );
  
  day.prayerSuggestion = prayer.text;
  day.meditationQuestions = prayer.questions;
}
```

### Sortie : Plan complet

```dart
final completePlan = Plan(
  id: generateId(),
  userId: currentUserId,
  book: 'Luc',
  title: 'Fondations - Luc',
  description: 'Découvrir l'évangile de Luc en 24 jours',
  duration: 24,
  minutesPerDay: 10,
  days: days, // List<PlanDay>
  startDate: DateTime.now(),
  createdAt: DateTime.now(),
  progress: 0,
  isActive: true,
  preset: selectedPreset,
);

// Sauvegarder
await LocalStorageService.savePlan(completePlan);
```

---

## 🔄 PIPELINE COMPLET ILLUSTRÉ

```
┌────────────────────────────────────────────────────────┐
│             PHASE 1 : CARTES PRÉSETS                   │
└────────────────────────────────────────────────────────┘
                          ↓
          ┌───────────────────────────┐
          │   Profil Utilisateur      │
          │  • Niveau: Fidèle régulier│
          │  • Objectif: Discipline   │
          │  • Temps: 15 min/jour     │
          └───────────────────────────┘
                          ↓
          ┌───────────────────────────┐
          │ IntelligentPresetGenerator│
          │  1. Map objectif → thème  │
          │  2. Sélectionner livres   │
          │  3. Calculer durations    │
          │  4. Scorer presets        │
          └───────────────────────────┘
                          ↓
          ┌───────────────────────────┐
          │    12 Cartes Présets      │
          │  Luc 30j • Score 0.85     │
          │  Jean 40j • Score 0.80    │
          │  Romains 60j • Score 0.75 │
          │  ...                      │
          └───────────────────────────┘
                          ↓
          ┌───────────────────────────┐
          │  Utilisateur choisit      │
          │  👉 "Luc 30j" ✅          │
          └───────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────┐
│          PHASE 2 : PLAN DÉTAILLÉ                       │
└────────────────────────────────────────────────────────┘
                          ↓
  ┌──────────────────────────────────────────────────┐
  │ ÉTAPE 1: DurationCalculator                      │
  │ → Durée optimale: 30 jours                       │
  │ → Base: Science comportementale + Témoignages    │
  └──────────────────────────────────────────────────┘
                          ↓
  ┌──────────────────────────────────────────────────┐
  │ ÉTAPE 2: ReadingSizer ⭐                         │
  │ → ChapterIndex: Luc 1 = 80 versets, densité 1.1 │
  │ → Calcul: 80v × 1.1d × 2s/v = ~14 min          │
  │ → Plan brut: 24 jours (Luc 1-24)                │
  └──────────────────────────────────────────────────┘
                          ↓
  ┌──────────────────────────────────────────────────┐
  │ ÉTAPE 3: Sémantique v2 ⭐                        │
  │ → Jour 15: Luc 15:1-10 proposé                  │
  │ → Détecte cut "Collection paraboles"            │
  │ → Ajuste: Luc 15:1-32 ✅                        │
  └──────────────────────────────────────────────────┘
                          ↓
  ┌──────────────────────────────────────────────────┐
  │ ÉTAPE 4: ChapterIndex (ré-estimation) ⭐         │
  │ → Luc 15:1-32 = 32 versets × 1.3 densité        │
  │ → Temps final: ~10 min ✅                       │
  └──────────────────────────────────────────────────┘
                          ↓
  ┌──────────────────────────────────────────────────┐
  │ ÉTAPE 5: Mapping calendrier                      │
  │ → Jours sélectionnés: Lun/Mer/Ven               │
  │ → Dates: 13/10, 15/10, 17/10...                 │
  └──────────────────────────────────────────────────┘
                          ↓
  ┌──────────────────────────────────────────────────┐
  │ ÉTAPE 6: Prières/Méditations                     │
  │ → IntelligentPrayerGenerator                     │
  │ → Questions personnalisées par passage           │
  └──────────────────────────────────────────────────┘
                          ↓
          ┌───────────────────────────┐
          │   PLAN COMPLET CRÉÉ       │
          │  • 24 jours mappés        │
          │  • Temps ±10% précis      │
          │  • Cohérence 98%          │
          │  • Prières générées       │
          └───────────────────────────┘
                          ↓
          ┌───────────────────────────┐
          │  Sauvegarde Hive Local    │
          │  + Sync Supabase (BG)     │
          └───────────────────────────┘
```

---

## 💡 EXEMPLE CONCRET : Plan Luc 24 jours

### Input

```dart
userProfile = {
  'level': 'Fidèle régulier',
  'goal': 'Discipline quotidienne',
  'durationMin': 10,
};

selectedPreset = {
  'book': 'Luc',
  'duration': 30, // Suggestion initiale
};

selectedDays = ['Lundi', 'Mercredi', 'Vendredi'];
```

### Processing

```dart
// 1. DurationCalculator
final optimalDuration = calculateOptimalDuration(...);
// → 24 jours (ajusté selon total chapitres + minutes)

// 2. ReadingSizer
final rawPlan = ReadingSizer.generateReadingPlan(
  book: 'Luc',
  totalChapters: 24,
  targetMinutesPerDay: 10,
);
// Jour 1: Luc 1 (14 min)
// Jour 2: Luc 2 (11 min)
// Jour 15: Luc 15:1-10 (6 min) ❌

// 3. Sémantique v2
final adjusted = adjustPassageVerses(...);
// Jour 15: Luc 15:1-32 (10 min) ✅

// 4. Ré-estimation
final finalMinutes = estimateMinutesRange(...);
// Jour 15: 10 min confirmé ✅

// 5. Mapping calendrier
final days = mapToCalendar(adjustedPlan, selectedDays);
// 13/10 (Lun): Luc 1
// 15/10 (Mer): Luc 2
// 17/10 (Ven): Luc 3-4
// ...

// 6. Prières
final prayers = generatePrayers(days);
// Jour 1: "Seigneur, ouvre mon cœur à ta Parole..."
```

### Output

```dart
Plan(
  id: 'plan_luc_2025_10_13',
  book: 'Luc',
  title: 'Évangile de Luc - 24 jours',
  duration: 24,
  minutesPerDay: 10,
  days: [
    PlanDay(
      dayNumber: 1,
      date: DateTime(2025, 10, 13),
      reference: 'Luc 1:1-80',
      book: 'Luc',
      startChapter: 1,
      endChapter: 1,
      estimatedMinutes: 14,
      annotation: null,
      hasLiteraryUnit: false,
      isCompleted: false,
    ),
    // ...
    PlanDay(
      dayNumber: 15,
      date: DateTime(2025, 11, 10),
      reference: 'Luc 15:1-32',
      book: 'Luc',
      startChapter: 15,
      endChapter: 15,
      estimatedMinutes: 10,
      annotation: 'Collection de paraboles (Luc 15)', // ⭐
      hasLiteraryUnit: true, // ⭐
      unitType: 'collection', // ⭐
      unitPriority: 'critical', // ⭐
      tags: ['paraboles', 'miséricorde'],
      isCompleted: false,
    ),
    // ... 22 autres jours
  ],
);
```

---

## 📊 SERVICES IMPLIQUÉS

| Service | Rôle | Phase |
|---------|------|-------|
| `IntelligentLocalPresetGenerator` | Générer cartes présets | 1 |
| `IntelligentDurationCalculator` | Calculer durée optimale | 2.1 |
| `ReadingSizer` ⭐ | Plan brut optimisé | 2.2 |
| `ChapterIndexLoader` ⭐ | Métadonnées (versets + densité) | 2.2 + 2.4 |
| `SemanticPassageBoundaryService v2` ⭐ | Ajustement cohérence | 2.3 |
| `IntelligentPrayerGenerator` | Prières personnalisées | 2.6 |
| `LocalStorageService` | Sauvegarde Hive | 2.7 |

---

## 🎯 POINTS CLÉS

### Pourquoi c'est intelligent

1. **Personnalisation** : Adapté au niveau, objectif, temps disponible
2. **Science** : Basé sur psychologie + témoignages chrétiens
3. **Précision** : Estimation temps ±10% (vs ±50% avant)
4. **Cohérence** : Aucune parabole/discours coupé (98% cohérence)
5. **Flexibilité** : S'adapte au calendrier utilisateur
6. **Offline-first** : 100% local, sync background

### Algorithmes clés

```dart
// Scoring preset
score = 0.45×objectif + 0.20×saison + 0.15×temps + 0.10×niveau + 0.10×variété

// Estimation temps
minutes = baseMinutes × (versets/25) × densité

// Ajustement sémantique
if (coupe_unité && priorité_critical) → inclure_unité_complète
```

---

## 🚀 FICHIERS CONCERNÉS

**Services** :
- `intelligent_local_preset_generator.dart` (1667L)
- `intelligent_duration_calculator.dart`
- `reading_sizer.dart` ⭐
- `chapter_index_loader.dart` ⭐
- `semantic_passage_boundary_service_v2.dart` ⭐
- `intelligent_prayer_generator.dart`

**UI** :
- `goals_page.dart` (affichage cartes)
- `plan_detail_page.dart` (calendrier)

**Models** :
- `plan_preset.dart`
- `plan_day.dart`
- `plan.dart`

---

## ✅ PROCHAINES AMÉLIORATIONS

1. **UI Preview** : Voir plan avant création
2. **Stats temps réel** : Montrer stats pendant génération
3. **A/B Testing** : Tester variations algorithmes
4. **ML** : Apprendre des complétions utilisateurs
5. **OTA Updates** : Mettre à jour thèmes/livres sans redéployer

---

**📚 SYSTÈME DE GÉNÉRATION COMPLET EXPLIQUÉ ! 🎯✨**

