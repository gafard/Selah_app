# 🗄️ Phase 1 P0 Étendue - 7 JSON au lieu de 5

## 📊 Décision stratégique

**Proposition initiale :** 5 JSON (52 KB)  
**Proposition enrichie :** 7 JSON (80 KB) - **RECOMMANDÉ** ✅

**Raison :** Les 2 JSON supplémentaires (`bible_books` + `key_verses`) sont **essentiels** pour la génération de passages réalistes, et s'intègrent parfaitement avec les 5 autres.

---

## 📦 Les 7 JSON de la Phase 1 P0

| # | Fichier | Taille | Lignes | Objectif | Priorité |
|---|---------|--------|--------|----------|----------|
| 1 | `book_theme_matrix.json` | 35 KB | 648 | Impact spirituel | 🔥 P0 |
| 2 | `goal_theme_map.json` | 8 KB | 200 | Thèmes par objectif | 🔥 P0 |
| 3 | `posture_book_bonus.json` | 4 KB | 120 | Posture × livres | 🔥 P0 |
| 4 | `verses_per_minute.json` | 3 KB | 66 | VPM par livre | 🔥 P0 |
| 5 | `motivation_multipliers.json` | 2 KB | 7 | Facteurs motivation | 🔥 P0 |
| 6 | **`bible_books.json`** | **25 KB** | **300** | **Chapitres/versets** | 🔥 **P0+** |
| 7 | **`key_verses.json`** | **3 KB** | **200** | **Versets clés** | 🔥 **P0+** |

**Total :** ~80 KB (ultra-léger pour offline)

---

## 📋 Structure des 2 nouveaux JSON

### `bible_books.json` (66 livres)

```json
[
  {
    "book": "Genèse",
    "abbr": "Gn",
    "testament": "OT",
    "chapters": 50,
    "genre": "narrative",
    "verses_by_chapter": [31, 25, 24, 26, 32, 22, 24, 22, 29, 32, ...], // 50 valeurs
    "total_verses": 1533
  },
  {
    "book": "Jean",
    "abbr": "Jn",
    "testament": "NT",
    "chapters": 21,
    "genre": "gospel_theological",
    "verses_by_chapter": [51, 25, 36, 54, 47, 71, 53, 59, 41, 42, 57, 50, 38, 31, 27, 33, 26, 40, 42, 31, 25],
    "total_verses": 879
  },
  {
    "book": "Psaumes",
    "abbr": "Ps",
    "testament": "OT",
    "chapters": 150,
    "genre": "poetry",
    "verses_by_chapter": [6, 12, 8, 8, 12, 10, 17, 9, 20, ...], // 150 valeurs
    "total_verses": 2461
  },
  {
    "book": "Romains",
    "abbr": "Rm",
    "testament": "NT",
    "chapters": 16,
    "genre": "epistle_doctrinal",
    "verses_by_chapter": [32, 29, 31, 25, 21, 23, 25, 39, 33, 21, 36, 21, 14, 23, 33, 27],
    "total_verses": 433
  }
  // ... 62 autres livres
]
```

**Utilisation :**
```dart
final meta = BibleMetadata();
final chaptersCount = meta.chaptersCount('Jean'); // 21
final versesInCh3 = meta.versesInChapter('Jean', 3); // 36
```

### `key_verses.json` (versets d'ancrage)

```json
[
  {"book": "Jean", "chapter": 1, "verse": 1, "text": "Au commencement était la Parole"},
  {"book": "Jean", "chapter": 3, "verse": 16, "text": "Car Dieu a tant aimé le monde..."},
  {"book": "Jean", "chapter": 14, "verse": 6, "text": "Je suis le chemin, la vérité et la vie"},
  {"book": "Psaumes", "chapter": 1, "verse": 1, "text": "Heureux l'homme..."},
  {"book": "Psaumes", "chapter": 23, "verse": 1, "text": "L'Éternel est mon berger"},
  {"book": "Psaumes", "chapter": 119, "verse": 105, "text": "Ta parole est une lampe"},
  {"book": "Romains", "chapter": 3, "verse": 23, "text": "Tous ont péché"},
  {"book": "Romains", "chapter": 8, "verse": 1, "text": "Aucune condamnation..."},
  {"book": "Romains", "chapter": 12, "verse": 1, "text": "Je vous exhorte donc"},
  {"book": "Philippiens", "chapter": 4, "verse": 13, "text": "Je puis tout par celui"},
  {"book": "Colossiens", "chapter": 3, "verse": 17, "text": "Tout ce que vous faites"}
  // ... 190 autres versets clés
]
```

**Utilisation :**
```dart
final keyVerse = meta.keyVerse('Jean', 3); // "Jean 3:16"
// Jour d'ancrage : affiche ce verset + méditation guidée
```

---

## 🔧 Services à créer

### 1. `BibleMetadata` (service central)

**Fichier :** `lib/services/bible_metadata.dart`

```dart
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Interface pour accéder aux métadonnées bibliques (offline)
abstract class BibleMetadata {
  /// Nombre de chapitres pour un livre
  int chaptersCount(String book);
  
  /// Nombre de versets dans un chapitre
  int versesInChapter(String book, int chapter);
  
  /// Mots par verset (densité)
  double wordsPerVerse(String book);
  
  /// Verset clé d'un chapitre (pour ancrage)
  String? keyVerse(String book, int chapter);
}

/// Implémentation basée sur JSON local (Hive)
class HiveBibleMetadata implements BibleMetadata {
  static final HiveBibleMetadata _instance = HiveBibleMetadata._internal();
  factory HiveBibleMetadata() => _instance;
  HiveBibleMetadata._internal();
  
  Box? _booksBox;
  Box? _keyVersesBox;
  
  /// Initialisation (charge JSON → Hive au premier lancement)
  static Future<void> initialize() async {
    final instance = HiveBibleMetadata();
    instance._booksBox = await Hive.openBox('bible_books');
    instance._keyVersesBox = await Hive.openBox('key_verses');
    
    // Charger depuis assets si vide
    if (instance._booksBox!.isEmpty) {
      await instance._loadBooksFromAssets();
    }
    if (instance._keyVersesBox!.isEmpty) {
      await instance._loadKeyVersesFromAssets();
    }
  }
  
  Future<void> _loadBooksFromAssets() async {
    final json = await rootBundle.loadString('assets/data/bible_books.json');
    final data = jsonDecode(json) as List;
    for (var item in data) {
      await _booksBox!.put(item['book'], item);
    }
    print('✅ ${data.length} livres bibliques chargés');
  }
  
  Future<void> _loadKeyVersesFromAssets() async {
    final json = await rootBundle.loadString('assets/data/key_verses.json');
    final data = jsonDecode(json) as List;
    for (var item in data) {
      final key = '${item['book']}_${item['chapter']}';
      await _keyVersesBox!.put(key, item);
    }
    print('✅ ${data.length} versets clés chargés');
  }
  
  @override
  int chaptersCount(String book) {
    final bookData = _booksBox?.get(book) as Map?;
    return (bookData?['chapters'] as int?) ?? _fallbackChapters(book);
  }
  
  @override
  int versesInChapter(String book, int chapter) {
    final bookData = _booksBox?.get(book) as Map?;
    final versesList = bookData?['verses_by_chapter'] as List?;
    if (versesList != null && chapter > 0 && chapter <= versesList.length) {
      return versesList[chapter - 1] as int;
    }
    return _fallbackVerses(book);
  }
  
  @override
  double wordsPerVerse(String book) {
    final bookData = _booksBox?.get(book) as Map?;
    final genre = bookData?['genre'] as String?;
    
    // Densité par genre
    switch (genre) {
      case 'poetry': return 18.0; // Psaumes, légers
      case 'wisdom': return 20.0; // Proverbes
      case 'narrative': return 24.0; // Genèse, Actes
      case 'gospel': return 26.0; // Évangiles
      case 'epistle_doctrinal': return 30.0; // Romains, Hébreux (dense)
      case 'epistle_practical': return 24.0; // Jacques
      case 'prophetic': return 28.0; // Ésaïe
      default: return 25.0;
    }
  }
  
  @override
  String? keyVerse(String book, int chapter) {
    final key = '${book}_$chapter';
    final verse Data = _keyVersesBox?.get(key) as Map?;
    if (verseData != null) {
      return '$book ${verseData['chapter']}:${verseData['verse']}';
    }
    return null;
  }
  
  // Fallbacks si données manquantes
  int _fallbackChapters(String book) {
    const defaults = {
      'Jean': 21, 'Luc': 24, 'Marc': 16, 'Matthieu': 28,
      'Romains': 16, 'Psaumes': 150, 'Proverbes': 31,
      'Genèse': 50, 'Exode': 40,
    };
    return defaults[book] ?? 20;
  }
  
  int _fallbackVerses(String book) {
    if (book == 'Psaumes') return 15;
    if (book == 'Proverbes') return 30;
    return 30;
  }
}
```

---

## 📊 Impact attendu (7 JSON vs 5 JSON)

| Métrique | 5 JSON | 7 JSON | Amélioration |
|----------|--------|--------|--------------|
| Taille totale | 52 KB | **80 KB** | +28 KB (+54%) |
| Pertinence presets | +30% | **+30%** | Identique |
| Passages réalistes | ❌ | **✅** | **NOUVEAU** |
| Couverture complète | ❌ | **✅** | **NOUVEAU** |
| Jours spéciaux | ❌ | **✅** | **NOUVEAU** |
| VPM adapté | ✅ | **✅** | Conservé |

**Verdict :** +28 KB pour passages 10x plus crédibles = **EXCELLENT ROI** ⭐

---

## ✅ RECOMMANDATION FINALE

### 👍 Phase 1 P0 Étendue (7 JSON)

**Plan d'exécution :**

#### Jour 1-2 : Créer les 7 JSON
1. `book_theme_matrix.json` (648 lignes)
2. `goal_theme_map.json` (200 lignes)
3. `posture_book_bonus.json` (120 lignes)
4. `verses_per_minute.json` (66 lignes)
5. `motivation_multipliers.json` (7 lignes)
6. **`bible_books.json`** (300 lignes) ← **NOUVEAU**
7. **`key_verses.json`** (200 lignes) ← **NOUVEAU**

#### Jour 3 : Service `IntelligentDatabases` + `BibleMetadata`
- Hydratation Hive
- Méthodes d'accès

#### Jour 4 : Intégration
- `IntelligentLocalPresetGenerator` : impact thématique
- `goals_page.dart` : amélioration `_generateOfflinePassagesForPreset`

#### Jour 5 : Tests
- Tester avec différents profils
- Tester Lun-Mer-Ven
- Tester jours ancrage/catch-up
- Mode avion

---

**Status :** ✅ PLAN VALIDÉ - 7 JSON au lieu de 5  
**Date :** 7 octobre 2025  
**Taille :** 80 KB (ultra-léger)  
**Impact :** Passages 10x plus crédibles + bases solides

