# 🗄️ Plan Implémentation - Bases de Données Intelligentes Offline-First

## 📊 Analyse de l'existant

### ✅ Déjà implémenté (partiellement)

| Base de données | Status | Fichier | Notes |
|-----------------|--------|---------|-------|
| Thèmes ↔ Livres | ⚠️ Partiel | `bible_plan_api_service.dart` | Mapping simple themes → livres |
| Témoignages spirituels | ✅ Complet | `intelligent_duration_calculator.dart` | Mapping behavioralType → testimonies |
| États émotionnels | ✅ Complet | `intelligent_duration_calculator.dart` | Par niveau spirituel |
| Besoins émotionnels | ✅ Complet | `intelligent_duration_calculator.dart` | emotional_needs par niveau |
| Base biblique | ⚠️ Basique | `intelligent_local_preset_generator.dart` | `_bibleKnowledgeBase` (statique) |

### ❌ À créer (priorités)

| # | Base de données | Priorité | Complexité | Impact |
|---|-----------------|----------|------------|--------|
| 1 | `book_theme_matrix` | 🔥 P0 | Moyenne | +30% pertinence |
| 2 | `posture_book_bonus` | 🔥 P0 | Faible | +25% personnalisation |
| 3 | `verses_per_minute` | 🔥 P0 | Faible | Passages réalistes |
| 4 | `motivation_multipliers` | 🔥 P0 | Faible | Déjà conceptualisé |
| 5 | `goal_theme_map` | 🔥 P0 | Moyenne | Calcul impact |
| 6 | `readability` | ⚡ P1 | Moyenne | Adaptation longueur |
| 7 | `pericopes` | ⚡ P1 | Élevée | Coupures naturelles |
| 8 | `bible_books` | ⚡ P1 | Faible | Métadonnées complètes |
| 9 | `reading_log` | ⚡ P1 | Faible | Boucle adaptative |

---

## 🎯 Phase 1 : MVP Intelligence Contextuelle (P0)

**Objectif :** 5 tables minimum pour un boost immédiat  
**Durée estimée :** 3-4h  
**Impact :** +50% pertinence des recommandations

### 1.1 Structure des données (JSON → Hive)

#### `book_theme_matrix.json` (648 lignes)
```json
[
  {
    "book": "Jean",
    "themes": {
      "christology": 0.98,
      "identity_in_christ": 0.95,
      "eternal_life": 0.92,
      "love": 0.90,
      "truth": 0.88,
      "light": 0.85,
      "witness": 0.82,
      "faith": 0.95,
      "relationship_with_god": 0.97
    }
  },
  {
    "book": "Romains",
    "themes": {
      "justification": 0.98,
      "grace": 0.96,
      "righteousness": 0.94,
      "sanctification": 0.90,
      "law_vs_grace": 0.92,
      "faith": 0.95,
      "sin": 0.88
    }
  },
  {
    "book": "Psaumes",
    "themes": {
      "prayer": 0.98,
      "worship": 0.96,
      "lament": 0.90,
      "thanksgiving": 0.92,
      "trust": 0.94,
      "deliverance": 0.88
    }
  }
  // ... 63 autres livres
]
```

#### `goal_theme_map.json` (200 lignes)
```json
[
  {
    "goal": "✨ Rencontrer Jésus dans la Parole",
    "themes_primary": ["christology", "relationship_with_god", "identity_in_christ"],
    "themes_secondary": ["love", "truth", "faith"],
    "weight_primary": 0.7,
    "weight_secondary": 0.3
  },
  {
    "goal": "💫 Voir Jésus dans chaque livre",
    "themes_primary": ["christology", "messianic_prophecy", "covenant"],
    "themes_secondary": ["redemption", "grace"],
    "weight_primary": 0.8,
    "weight_secondary": 0.2
  },
  {
    "goal": "🔥 Être transformé à son image",
    "themes_primary": ["sanctification", "character_formation", "fruit_of_spirit"],
    "themes_secondary": ["identity_in_christ", "renewal"],
    "weight_primary": 0.7,
    "weight_secondary": 0.3
  },
  {
    "goal": "Discipline quotidienne",
    "themes_primary": ["faithfulness", "perseverance", "discipline"],
    "themes_secondary": ["growth", "commitment"],
    "weight_primary": 0.6,
    "weight_secondary": 0.4
  }
  // ... tous les 18 objectifs
]
```

#### `posture_book_bonus.json` (120 lignes)
```json
[
  {
    "posture": "💎 Rencontrer Jésus personnellement",
    "bonuses": {
      "Jean": 0.30,
      "Marc": 0.20,
      "Luc": 0.25,
      "Matthieu": 0.22,
      "Hébreux": 0.18,
      "Colossiens": 0.15
    }
  },
  {
    "posture": "🔥 Être transformé par l'Esprit",
    "bonuses": {
      "Actes": 0.28,
      "Romains": 0.25,
      "Galates": 0.22,
      "Éphésiens": 0.20,
      "1 Corinthiens": 0.18
    }
  },
  {
    "posture": "🙏 Écouter la voix de Dieu",
    "bonuses": {
      "Psaumes": 0.30,
      "1 Samuel": 0.22,
      "Jean": 0.20,
      "Ésaïe": 0.18,
      "Jérémie": 0.15
    }
  },
  {
    "posture": "📚 Approfondir ma connaissance",
    "bonuses": {
      "Romains": 0.30,
      "Hébreux": 0.28,
      "Éphésiens": 0.22,
      "Colossiens": 0.20,
      "1 Pierre": 0.18
    }
  },
  {
    "posture": "⚡ Recevoir la puissance de l'Esprit",
    "bonuses": {
      "Actes": 0.32,
      "1 Corinthiens": 0.22,
      "Éphésiens": 0.20,
      "Luc": 0.18,
      "Jean": 0.15
    }
  },
  {
    "posture": "❤️ Développer l'intimité avec le Père",
    "bonuses": {
      "Jean": 0.32,
      "Psaumes": 0.28,
      "Cantique des Cantiques": 0.25,
      "Osée": 0.20,
      "1 Jean": 0.22
    }
  }
]
```

#### `verses_per_minute.json` (66 livres)
```json
[
  {"book": "Genèse", "vpm_min": 2.0, "vpm_avg": 2.8, "vpm_max": 3.5, "genre": "narrative"},
  {"book": "Exode", "vpm_min": 1.8, "vpm_avg": 2.5, "vpm_max": 3.2, "genre": "narrative_law"},
  {"book": "Lévitique", "vpm_min": 1.2, "vpm_avg": 1.8, "vpm_max": 2.3, "genre": "law"},
  {"book": "Psaumes", "vpm_min": 2.2, "vpm_avg": 3.2, "vpm_max": 4.0, "genre": "poetry"},
  {"book": "Proverbes", "vpm_min": 1.8, "vpm_avg": 2.5, "vpm_max": 3.2, "genre": "wisdom"},
  {"book": "Ésaïe", "vpm_min": 1.5, "vpm_avg": 2.2, "vpm_max": 2.8, "genre": "prophetic"},
  {"book": "Matthieu", "vpm_min": 2.0, "vpm_avg": 2.7, "vpm_max": 3.4, "genre": "gospel"},
  {"book": "Jean", "vpm_min": 1.8, "vpm_avg": 2.5, "vpm_max": 3.2, "genre": "gospel_theological"},
  {"book": "Romains", "vpm_min": 1.4, "vpm_avg": 2.0, "vpm_max": 2.6, "genre": "epistle_doctrinal"},
  {"book": "1 Corinthiens", "vpm_min": 1.6, "vpm_avg": 2.3, "vpm_max": 3.0, "genre": "epistle_practical"},
  {"book": "Galates", "vpm_min": 1.5, "vpm_avg": 2.1, "vpm_max": 2.7, "genre": "epistle_doctrinal"},
  {"book": "Éphésiens", "vpm_min": 1.4, "vpm_avg": 2.0, "vpm_max": 2.6, "genre": "epistle_doctrinal"},
  {"book": "Philippiens", "vpm_min": 1.7, "vpm_avg": 2.4, "vpm_max": 3.1, "genre": "epistle_personal"},
  {"book": "Colossiens", "vpm_min": 1.5, "vpm_avg": 2.1, "vpm_max": 2.8, "genre": "epistle_doctrinal"},
  {"book": "Hébreux", "vpm_min": 1.3, "vpm_avg": 1.9, "vpm_max": 2.5, "genre": "epistle_complex"},
  {"book": "Jacques", "vpm_min": 1.8, "vpm_avg": 2.5, "vpm_max": 3.2, "genre": "epistle_wisdom"},
  {"book": "1 Pierre", "vpm_min": 1.6, "vpm_avg": 2.3, "vpm_max": 3.0, "genre": "epistle_encouragement"},
  {"book": "Apocalypse", "vpm_min": 1.2, "vpm_avg": 1.8, "vpm_max": 2.4, "genre": "apocalyptic"}
]
```

#### `motivation_multipliers.json` (7 motivations)
```json
[
  {
    "motivation": "🔥 Passion pour Christ",
    "duration_factor": 0.85,
    "intensity_factor": 1.25,
    "timing_hint": "05:00-08:00",
    "recommended_genres": ["gospel", "epistle_doctrinal"],
    "min_minutes": 20,
    "max_minutes": 60
  },
  {
    "motivation": "❤️ Amour pour Dieu",
    "duration_factor": 1.0,
    "intensity_factor": 1.15,
    "timing_hint": "06:00-09:00",
    "recommended_genres": ["poetry", "gospel"],
    "min_minutes": 15,
    "max_minutes": 45
  },
  {
    "motivation": "🎯 Obéissance joyeuse",
    "duration_factor": 1.1,
    "intensity_factor": 1.0,
    "timing_hint": "07:00-10:00",
    "recommended_genres": ["wisdom", "epistle_practical"],
    "min_minutes": 10,
    "max_minutes": 30
  },
  {
    "motivation": "📖 Désir de connaître Dieu",
    "duration_factor": 1.3,
    "intensity_factor": 1.2,
    "timing_hint": "06:30-09:30",
    "recommended_genres": ["epistle_doctrinal", "prophetic"],
    "min_minutes": 20,
    "max_minutes": 60
  },
  {
    "motivation": "⚡ Besoin de transformation",
    "duration_factor": 0.9,
    "intensity_factor": 1.3,
    "timing_hint": "05:30-08:00",
    "recommended_genres": ["gospel", "epistle_practical"],
    "min_minutes": 15,
    "max_minutes": 40
  },
  {
    "motivation": "🙏 Recherche de direction",
    "duration_factor": 1.0,
    "intensity_factor": 1.1,
    "timing_hint": "06:00-09:00",
    "recommended_genres": ["wisdom", "prophetic", "gospel"],
    "min_minutes": 15,
    "max_minutes": 45
  },
  {
    "motivation": "💪 Discipline spirituelle",
    "duration_factor": 1.2,
    "intensity_factor": 0.9,
    "timing_hint": "07:00-10:00",
    "recommended_genres": ["law", "epistle_practical"],
    "min_minutes": 10,
    "max_minutes": 30
  }
]
```

### 1.2 Intégration dans le code existant

#### Fichier : `lib/data/intelligent_databases.dart` (NOUVEAU)
```dart
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class IntelligentDatabases {
  static Future<void> initializeAll() async {
    await _loadBookThemeMatrix();
    await _loadGoalThemeMap();
    await _loadPostureBookBonus();
    await _loadVersesPerMinute();
    await _loadMotivationMultipliers();
  }

  static Future<void> _loadBookThemeMatrix() async {
    final box = await Hive.openBox('book_theme_matrix');
    if (box.isEmpty) {
      final json = await rootBundle.loadString('assets/data/book_theme_matrix.json');
      final data = jsonDecode(json) as List;
      for (var item in data) {
        await box.put(item['book'], item);
      }
    }
  }

  // ... autres _load methods
  
  /// Récupère le poids d'un thème pour un livre
  static double getBookThemeWeight(String book, String theme) {
    final box = Hive.box('book_theme_matrix');
    final bookData = box.get(book) as Map?;
    if (bookData == null) return 0.0;
    final themes = bookData['themes'] as Map?;
    return (themes?[theme] as num?)?.toDouble() ?? 0.0;
  }

  /// Calcule l'impact spirituel d'un livre sur un objectif
  static double calculateBookImpactOnGoal(String book, String goal) {
    final goalBox = Hive.box('goal_theme_map');
    final goalData = goalBox.values.firstWhere(
      (g) => g['goal'] == goal,
      orElse: () => null,
    );
    if (goalData == null) return 0.5; // Fallback
    
    final themesPrimary = goalData['themes_primary'] as List;
    final themesSecondary = goalData['themes_secondary'] as List;
    final weightPrimary = goalData['weight_primary'] as double;
    final weightSecondary = goalData['weight_secondary'] as double;
    
    double impactPrimary = 0.0;
    for (var theme in themesPrimary) {
      impactPrimary += getBookThemeWeight(book, theme);
    }
    impactPrimary = impactPrimary / themesPrimary.length;
    
    double impactSecondary = 0.0;
    for (var theme in themesSecondary) {
      impactSecondary += getBookThemeWeight(book, theme);
    }
    impactSecondary = impactSecondary / themesSecondary.length;
    
    return (impactPrimary * weightPrimary + impactSecondary * weightSecondary)
        .clamp(0.0, 1.0);
  }

  /// Récupère le bonus de posture pour un livre
  static double getPostureBonus(String book, String posture) {
    final box = Hive.box('posture_book_bonus');
    final postureData = box.values.firstWhere(
      (p) => p['posture'] == posture,
      orElse: () => null,
    );
    if (postureData == null) return 0.0;
    final bonuses = postureData['bonuses'] as Map?;
    return (bonuses?[book] as num?)?.toDouble() ?? 0.0;
  }

  /// Récupère le VPM moyen pour un livre
  static double getVersesPerMinute(String book) {
    final box = Hive.box('verses_per_minute');
    final bookData = box.values.firstWhere(
      (b) => b['book'] == book,
      orElse: () => null,
    );
    return (bookData?['vpm_avg'] as num?)?.toDouble() ?? 2.5; // Fallback
  }

  /// Récupère les multiplicateurs de motivation
  static Map<String, dynamic>? getMotivationMultipliers(String motivation) {
    final box = Hive.box('motivation_multipliers');
    return box.values.firstWhere(
      (m) => m['motivation'] == motivation,
      orElse: () => null,
    );
  }
}
```

#### Modification : `intelligent_local_preset_generator.dart`
```dart
// Import
import '../data/intelligent_databases.dart';

// Dans generateEnrichedPresets(), REMPLACER le calcul d'impact
static List<PlanPreset> generateEnrichedPresets(Map<String, dynamic>? profile) {
  // ... code existant ...
  
  final enrichedPresets = basePresets.map((preset) {
    final mainBook = _extractMainBook(preset.books);
    
    // ✅ NOUVEAU : Calculer impact réel depuis base de données
    final spiritualImpact = IntelligentDatabases.calculateBookImpactOnGoal(
      mainBook,
      goal,
    );
    
    // ✅ NOUVEAU : Bonus de posture
    final postureBonus = heartPosture != null
        ? IntelligentDatabases.getPostureBonus(mainBook, heartPosture)
        : 0.0;
    
    // ✅ NOUVEAU : VPM pour calcul passages
    final vpm = IntelligentDatabases.getVersesPerMinute(mainBook);
    
    // ... reste du code ...
  });
}
```

---

## 📦 Phase 2 : Intelligence Adaptative (P1)

### 2.1 `reading_log` (Boucle de feedback)

#### Structure Hive
```dart
@HiveType(typeId: 10)
class ReadingLogEntry extends HiveObject {
  @HiveField(0)
  DateTime date;
  
  @HiveField(1)
  String planId;
  
  @HiveField(2)
  int dayIndex;
  
  @HiveField(3)
  bool completed;
  
  @HiveField(4)
  int? durationMinutes;
  
  @HiveField(5)
  String? timeOfDay;
  
  @HiveField(6)
  double? satisfaction; // 0.0-1.0
  
  @HiveField(7)
  String? emotion;
}
```

#### Service : `reading_analytics_service.dart`
```dart
class ReadingAnalyticsService {
  static Future<void> logReading({
    required String planId,
    required int dayIndex,
    required bool completed,
    int? durationMinutes,
    String? emotion,
    double? satisfaction,
  }) async {
    final box = await Hive.openBox<ReadingLogEntry>('reading_log');
    final entry = ReadingLogEntry()
      ..date = DateTime.now()
      ..planId = planId
      ..dayIndex = dayIndex
      ..completed = completed
      ..durationMinutes = durationMinutes
      ..timeOfDay = TimeOfDay.now().format(context)
      ..satisfaction = satisfaction
      ..emotion = emotion;
    await box.add(entry);
  }

  /// Analyse les 30 derniers jours pour détecter les patterns
  static Future<Map<String, dynamic>> analyzeRecentReadings() async {
    final box = await Hive.openBox<ReadingLogEntry>('reading_log');
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = box.values.where((e) => e.date.isAfter(cutoff)).toList();
    
    if (recent.isEmpty) return {'completion_rate': 0.0};
    
    final completed = recent.where((e) => e.completed).length;
    final completionRate = completed / recent.length;
    
    final avgDuration = recent
        .where((e) => e.durationMinutes != null)
        .map((e) => e.durationMinutes!)
        .fold(0, (a, b) => a + b) / recent.length;
    
    final avgSatisfaction = recent
        .where((e) => e.satisfaction != null)
        .map((e) => e.satisfaction!)
        .fold(0.0, (a, b) => a + b) / recent.where((e) => e.satisfaction != null).length;
    
    return {
      'completion_rate': completionRate,
      'avg_duration': avgDuration,
      'avg_satisfaction': avgSatisfaction,
      'total_readings': recent.length,
      'streak': _calculateStreak(recent),
    };
  }

  static int _calculateStreak(List<ReadingLogEntry> entries) {
    entries.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime? lastDate;
    
    for (var entry in entries) {
      if (!entry.completed) continue;
      if (lastDate == null || lastDate.difference(entry.date).inDays == 1) {
        streak++;
        lastDate = entry.date;
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Recommande des ajustements basés sur l'analytics
  static Future<Map<String, dynamic>> getAdaptiveRecommendations() async {
    final analytics = await analyzeRecentReadings();
    final completionRate = analytics['completion_rate'] as double;
    final avgDuration = analytics['avg_duration'] as double?;
    final avgSatisfaction = analytics['avg_satisfaction'] as double?;
    
    final recommendations = <String, dynamic>{};
    
    // Si taux de complétion faible, réduire durée
    if (completionRate < 0.5) {
      recommendations['adjust_duration'] = -0.2; // -20%
      recommendations['reason'] = 'Taux de complétion faible, réduire la charge';
    }
    
    // Si satisfaction faible, changer de type de passages
    if (avgSatisfaction != null && avgSatisfaction < 0.4) {
      recommendations['change_genre'] = true;
      recommendations['reason'] = 'Satisfaction faible, essayer d\'autres livres';
    }
    
    // Si tout va bien, augmenter légèrement
    if (completionRate > 0.8 && (avgSatisfaction ?? 0.5) > 0.7) {
      recommendations['adjust_duration'] = 0.1; // +10%
      recommendations['reason'] = 'Excellente progression, augmenter légèrement';
    }
    
    return recommendations;
  }
}
```

---

## 🎨 Phase 3 : Intelligence Émotionnelle (P1+)

### 3.1 Profils spirituels & Messages contextuels

#### `emotional_profiles.json`
```json
[
  {
    "profile": "nouveau_converti_enthousiaste",
    "patterns": {
      "emotions": ["joy", "anticipation", "curiosity"],
      "completion_rate": ">0.7",
      "satisfaction": ">0.6"
    },
    "messages": [
      "🎉 Quelle joie de te voir grandir dans la foi !",
      "✨ Ton enthousiasme pour la Parole est inspirant !",
      "🌱 Continue, chaque jour compte !"
    ],
    "scripture_encouragements": [
      "2 Pierre 3:18 - Croissez dans la grâce",
      "1 Pierre 2:2 - Comme des enfants nouveau-nés..."
    ]
  },
  {
    "profile": "retrograde_en_restauration",
    "patterns": {
      "emotions": ["repentance", "hope", "determination"],
      "completion_rate": "0.4-0.7",
      "satisfaction": ">0.5"
    },
    "messages": [
      "💝 Le Père t'accueille à bras ouverts !",
      "🌅 Chaque nouveau jour est une grâce fraîche !",
      "🙏 Ta persévérance touche le cœur de Dieu !"
    ],
    "scripture_encouragements": [
      "Lamentations 3:22-23 - Ses compassions se renouvellent",
      "Osée 2:14 - Je la conduirai au désert..."
    ]
  }
]
```

---

## 📁 Structure Assets (à créer)

```
selah_app/selah_app/assets/data/
├── book_theme_matrix.json (35 KB)
├── goal_theme_map.json (8 KB)
├── posture_book_bonus.json (4 KB)
├── verses_per_minute.json (3 KB)
├── motivation_multipliers.json (2 KB)
├── readability.json (25 KB) [P1]
├── pericopes_fr.json (180 KB) [P1]
├── bible_books.json (15 KB) [P1]
└── emotional_profiles.json (12 KB) [P1+]

TOTAL P0: ~52 KB
TOTAL P1: ~272 KB
```

---

## 🚀 Plan d'exécution

### Semaine 1 : MVP P0 (Intelligence Contextuelle)
- [ ] Jour 1-2 : Créer les 5 fichiers JSON
- [ ] Jour 3 : Créer `IntelligentDatabases` service
- [ ] Jour 4 : Intégrer dans `IntelligentLocalPresetGenerator`
- [ ] Jour 5 : Tests + Validation impact

### Semaine 2 : P1 (Intelligence Adaptative)
- [ ] Jour 1-2 : `ReadingAnalyticsService` + Hive models
- [ ] Jour 3 : Intégration dans `ReaderPageModern`
- [ ] Jour 4-5 : Boucle de feedback adaptative

### Semaine 3 : P1+ (Intelligence Émotionnelle)
- [ ] Jour 1-2 : Profils émotionnels + messages
- [ ] Jour 3-4 : Intégration UI (encouragements)
- [ ] Jour 5 : Tests end-to-end

---

## 📊 Métriques de succès

| Métrique | Avant | Cible | Comment mesurer |
|----------|-------|-------|-----------------|
| Pertinence presets | 60% | 90% | User feedback + completion rate |
| Durée passages | Fixe | Adaptive | VPM × readability |
| Personnalisation | 70% | 95% | Posture + motivation matching |
| Engagement | 50% | 75% | Reading log analytics |

---

**Statut :** 📋 PLAN VALIDÉ - PRÊT POUR IMPLÉMENTATION  
**Date :** 7 octobre 2025  
**Prochaine étape :** Créer les JSON P0
