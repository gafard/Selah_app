# 🚨 RAPPORT COMPLET - PROBLÈME DE NAVIGATION ET AFFICHAGE TEXTE

## 📋 RÉSUMÉ EXÉCUTIF

**Problème principal :** L'application Selah ne peut pas afficher le texte biblique dans `ReaderPageModern` à cause d'une erreur de type lors de la navigation depuis `PreMeditationPrayerPage`.

**Erreur critique :**
```
❌ Erreur navigation vers ReaderPageModern: type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>'
```

**Symptômes :**
- Navigation vers `pre_meditation_prayer_page.dart` fonctionne
- Erreur lors du passage vers `reader_page_modern.dart`
- Aucun texte biblique affiché (texte générique affiché)
- Plan existe mais pas de jours de plan trouvés

---

## 🔍 ANALYSE TECHNIQUE DÉTAILLÉE

### 1. ARCHITECTURE DE NAVIGATION

```dart
// Flux de navigation actuel
Page d'accueil → pre_meditation_prayer_page.dart → reader_page_modern.dart
```

### 2. MODÈLES DE DONNÉES

#### PlanDay Model (plan_models.dart)
```dart
class PlanDay {
  final String id;
  final String planId;
  final int dayIndex; // 1..N
  final DateTime date;
  final List<ReadingRef> readings;  // ⚠️ PROBLÈME ICI
  final bool completed;

  PlanDay({
    required this.id,
    required this.planId,
    required this.dayIndex,
    required this.date,
    required this.readings,
    required this.completed,
  });

  factory PlanDay.fromJson(Map<String, dynamic> j) => PlanDay(
        id: j['id'],
        planId: j['plan_id'],
        dayIndex: j['day_index'],
        date: DateTime.parse(j['date']),
        readings: (j['readings'] as List).map((e) => ReadingRef.fromJson(e)).toList(),
        completed: j['completed'] ?? false,
      );
}
```

#### ReadingRef Model (plan_models.dart)
```dart
class ReadingRef {
  final String book; // ex: "Jean"
  final String range; // ex: "3:16-4:10"  ⚠️ PROBLÈME ICI
  final String? url;

  ReadingRef({required this.book, required this.range, this.url});

  factory ReadingRef.fromJson(Map<String, dynamic> j) =>
      ReadingRef(book: j['book'], range: j['range'], url: j['url']);  // ⚠️ PAS DE VÉRIFICATION DE TYPE

  Map<String, dynamic> toJson() => {'book': book, 'range': range, 'url': url};
}
```

### 3. SERVICE DE GESTION DES PLANS

#### PlanServiceHttp (plan_service_http.dart)
```dart
@override
Future<List<PlanDay>> getPlanDays(String planId, {int? fromDay, int? toDay}) async {
  final key = 'days:$planId:${fromDay ?? 1}:${toDay ?? 0}';
  final cached = cachePlanDays.get(key);
  if (cached != null) {
    final list = (cached as List).map((e) => PlanDay.fromJson(Map<String, dynamic>.from(e))).toList();
    return list;
  }
  
  final r = await _authedGet('/plans/$planId/days${_range(fromDay, toDay)}');
  if (r.statusCode ~/ 100 != 2) {
    if (r.statusCode == 404) {
      print('⚠️ Fonction getPlanDays non disponible sur Supabase - utilisation du cache local');
      final localKey = 'days:$planId';
      final localCached = cachePlanDays.get(localKey);
      if (localCached != null) {
        print('✅ Jours de plan trouvés dans le cache local avec clé alternative');
        final list = (localCached as List).map((e) => PlanDay.fromJson(Map<String, dynamic>.from(e))).toList();
        return list;
      }
      print('⚠️ Aucun jour de plan trouvé pour le plan: $planId');
      return [];  // ⚠️ RETOURNE UNE LISTE VIDE
    }
    throw 'getPlanDays ${r.statusCode}: ${r.body}';
  }
  final List data = jsonDecode(r.body);
  await cachePlanDays.put(key, data);
  return data.map((e) => PlanDay.fromJson(e)).toList();
}
```

#### Création des jours de plan (plan_service_http.dart)
```dart
Future<void> _createLocalPlanDays(
  String planId,
  int totalDays,
  DateTime startDate,
  String books,
  List<Map<String, dynamic>>? customPassages,
  List<int>? daysOfWeek,
) async {
  final List<PlanDay> days = [];
  
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
            range: passage['reference'] as String,  // ⚠️ CORRECT ICI
            url: null,
          ),
        ],
      );
      days.add(day);
    }
  }
  
  // Sauvegarder les jours avec la même clé que getPlanDays
  await cachePlanDays.put('days:$planId:1:0', days.map((d) => d.toJson()).toList());
  print('✅ ${days.length} jours de plan sauvegardés localement');
}
```

### 4. PAGE DE NAVIGATION PROBLÉMATIQUE

#### PreMeditationPrayerPage (pre_meditation_prayer_page.dart)
```dart
/// ✅ Navigation vers ReaderPageModern avec le passage du jour actuel
Future<void> _navigateToReader() async {
  try {
    // Utiliser le PlanServiceHttp configuré globalement
    final activePlan = await planService.getActiveLocalPlan();
    
    if (activePlan != null) {
      // Récupérer les jours du plan
      final planDays = await planService.getPlanDays(activePlan.id);
      
      if (planDays.isNotEmpty) {
        // Calculer le jour actuel basé sur la date de début
        final today = DateTime.now();
        final startDate = activePlan.startDate;
        final daysSinceStart = today.difference(startDate).inDays;
        
        // Récupérer le passage du jour actuel
        if (daysSinceStart >= 0 && daysSinceStart < planDays.length) {
          final todayPassage = planDays[daysSinceStart];
          
          // ⚠️ PROBLÈME ICI - Construire la référence du passage
          String passageRef;
          if (todayPassage.readings.isNotEmpty) {
            final firstReading = todayPassage.readings.first;
            // Vérifier si range est un String ou un Map
            if (firstReading.range is String) {
              passageRef = firstReading.range as String;
            } else if (firstReading.range is Map) {
              // Si c'est un Map, essayer d'extraire la valeur
              final rangeMap = firstReading.range as Map;
              passageRef = rangeMap['range'] as String? ?? 
                         rangeMap['reference'] as String? ?? 
                         _generatePassageRef(todayPassage.dayIndex);
            } else {
              passageRef = _generatePassageRef(todayPassage.dayIndex);
            }
          } else {
            passageRef = _generatePassageRef(todayPassage.dayIndex);
          }
          
          // Navigation avec les données du passage
          if (mounted) {
            context.go('/reader', extra: {
              'passageRef': passageRef,
              'passageText': null, // Sera récupéré depuis la base de données
              'dayTitle': 'Jour ${todayPassage.dayIndex}',
              'planId': activePlan.id,
              'dayNumber': todayPassage.dayIndex,
            });
          }
          
          print('✅ Navigation vers ReaderPageModern avec passage: $passageRef (Jour ${todayPassage.dayIndex})');
        } else {
          // Plan terminé ou pas encore commencé
          if (mounted) {
            _showPlanStatusMessage(activePlan, daysSinceStart, planDays.length);
          }
        }
      } else {
        // ⚠️ PROBLÈME ICI - Pas de jours de plan trouvés
        print('⚠️ Aucun jour de plan trouvé pour le plan: ${activePlan.id}');
        print('⚠️ Utilisation du fallback avec passage intelligent');
        
        // Fallback avec passage intelligent basé sur le plan
        final fallbackPassage = _generateIntelligentFallback(activePlan);
        
        if (mounted) {
          context.go('/reader', extra: {
            'passageRef': fallbackPassage,
            'passageText': null,
            'dayTitle': 'Lecture du jour',
            'planId': activePlan.id,
            'dayNumber': 1,
          });
        }
      }
    } else {
      // Aucun plan actif - navigation par défaut avec fallback
      print('⚠️ Aucun plan actif trouvé, navigation par défaut');
      if (mounted) {
        context.go('/reader', extra: {
          'passageRef': _generatePassageRef(1), // Jour 1 par défaut
          'passageText': null,
          'dayTitle': 'Lecture du jour',
        });
      }
    }
  } catch (e) {
    print('❌ Erreur navigation vers ReaderPageModern: $e');
    // Fallback en cas d'erreur avec passage intelligent
    if (mounted) {
      context.go('/reader', extra: {
        'passageRef': _generatePassageRef(1), // Jour 1 par défaut
        'passageText': null,
        'dayTitle': 'Lecture du jour',
      });
    }
  }
}
```

### 5. PAGE DE LECTURE

#### ReaderPageModern (reader_page_modern.dart)
```dart
class ReaderPageModern extends StatefulWidget {
  final String? passageRef;
  final String? passageText;
  final String? dayTitle;
  final List<String>? passageRefs;
  final ReadingSession? readingSession;
  
  const ReaderPageModern({
    super.key,
    this.passageRef,
    this.passageText,
    this.dayTitle,
    this.passageRefs,
    this.readingSession,
  });
}

class _ReaderPageModernState extends State<ReaderPageModern> {
  // Passage data
  late final String _passageRef;
  String _passageText = '';
  late final String _dayTitle;
  bool _isLoadingText = true;
  
  // Multi-passage support
  late ReadingSession _readingSession;
  
  // Version selection
  String _selectedVersion = 'lsg1910';
  List<Map<String, String>> _availableVersions = [];

  @override
  void initState() {
    super.initState();
    
    // ✅ Charger la version de Bible de l'utilisateur
    _loadUserBibleVersion();
    
    // Initialiser la session de lecture
    _initializeReadingSession();
  }
  
  /// Initialise la session de lecture selon les paramètres fournis
  void _initializeReadingSession() {
    if (widget.readingSession != null) {
      // Session complète fournie
      _readingSession = widget.readingSession!;
    } else if (widget.passageRefs != null && widget.passageRefs!.isNotEmpty) {
      // Plusieurs références fournies
      _readingSession = ReadingSession.fromReferences(
        references: widget.passageRefs!,
        dayTitle: widget.dayTitle,
      );
    } else {
      // Une seule référence (rétrocompatibilité)
      _readingSession = ReadingSession.fromSingleReference(
        reference: widget.passageRef ?? 'Jean 14:1-19',
        text: widget.passageText,
        title: widget.dayTitle,
        dayTitle: widget.dayTitle ?? 'Jour 15',
      );
    }
    
    // Initialiser les variables de compatibilité
    _passageRef = _readingSession.currentPassage?.reference ?? 'Jean 14:1-19';
    _dayTitle = _readingSession.dayTitle ?? 'Jour 15';
    
    // Charger les versions disponibles
    _loadAvailableVersions();
    
    // Charger tous les passages
    _loadAllPassages();
  }

  /// Charge tous les passages de la session
  Future<void> _loadAllPassages() async {
    try {
      await BibleTextService.init();
      
      // Charger tous les passages en parallèle
      final futures = _readingSession.passages.asMap().entries.map((entry) {
        final index = entry.key;
        final passage = entry.value;
        return _loadSinglePassage(index, passage);
      });
      
      await Future.wait(futures);
      
      // Mettre à jour le texte du passage actuel
      _updateCurrentPassageText();
      
    } catch (e) {
      print('⚠️ Erreur chargement passages multiples: $e');
      setState(() {
        _isLoadingText = false;
      });
    }
  }
  
  /// Charge un passage spécifique
  Future<void> _loadSinglePassage(int index, ReadingPassage passage) async {
    try {
      // Marquer comme en cours de chargement
      setState(() {
        _readingSession = _readingSession.updatePassage(
          index,
          passage.copyWith(isLoading: true),
        );
      });
      
      // Récupérer le texte depuis la base de données avec la version sélectionnée
      final text = await BibleTextService.getPassageText(passage.reference, version: _selectedVersion);
      
      if (mounted) {
        setState(() {
          _readingSession = _readingSession.updatePassage(
            index,
            passage.copyWith(
              text: text ?? _getFallbackText(passage.reference),
              isLoaded: true,
              isLoading: false,
              error: text == null ? 'Texte non trouvé' : null,
            ),
          );
        });
      }
    } catch (e) {
      print('⚠️ Erreur chargement passage ${passage.reference}: $e');
      if (mounted) {
        setState(() {
          _readingSession = _readingSession.updatePassage(
            index,
            passage.copyWith(
              text: _getFallbackText(passage.reference),
              isLoaded: true,
              isLoading: false,
              error: e.toString(),
            ),
          );
        });
      }
    }
  }
}
```

### 6. SERVICE DE TEXTE BIBLIQUE

#### BibleTextService (bible_text_service.dart)
```dart
class BibleTextService {
  static Database? _database;
  
  static Future<void> init() async {
    if (_database != null) return;
    
    final dbPath = await _getDatabasePath();
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Créer les tables si nécessaire
      },
    );
  }
  
  static Future<String?> getPassageText(String reference, {String version = 'lsg1910'}) async {
    if (_database == null) {
      await init();
    }
    
    try {
      // Parser la référence (ex: "Jean 3:16-4:10")
      final parts = reference.split(' ');
      if (parts.length < 2) return null;
      
      final book = parts[0];
      final chapterVerse = parts[1];
      
      // Extraire chapitre et versets
      final chapterVerseParts = chapterVerse.split(':');
      if (chapterVerseParts.length < 2) return null;
      
      final chapter = int.tryParse(chapterVerseParts[0]);
      final verseRange = chapterVerseParts[1];
      
      // Gérer les plages de versets (ex: "16-4:10")
      if (verseRange.contains('-')) {
        final rangeParts = verseRange.split('-');
        final startVerse = int.tryParse(rangeParts[0]);
        final endPart = rangeParts[1];
        
        if (endPart.contains(':')) {
          // Plage multi-chapitres (ex: "16-4:10")
          final endParts = endPart.split(':');
          final endChapter = int.tryParse(endParts[0]);
          final endVerse = int.tryParse(endParts[1]);
          
          if (chapter != null && startVerse != null && endChapter != null && endVerse != null) {
            return await _getMultiChapterPassage(book, chapter, startVerse, endChapter, endVerse, version);
          }
        } else {
          // Plage simple (ex: "16-20")
          final endVerse = int.tryParse(endPart);
          if (chapter != null && startVerse != null && endVerse != null) {
            return await _getSingleChapterPassage(book, chapter, startVerse, endVerse, version);
          }
        }
      } else {
        // Verset unique
        final verse = int.tryParse(verseRange);
        if (chapter != null && verse != null) {
          return await _getSingleVerse(book, chapter, verse, version);
        }
      }
      
      return null;
    } catch (e) {
      print('⚠️ Erreur getPassageText: $e');
      return null;
    }
  }
  
  static Future<String?> _getSingleChapterPassage(String book, int chapter, int startVerse, int endVerse, String version) async {
    final result = await _database!.rawQuery('''
      SELECT text FROM verses 
      WHERE book = ? AND chapter = ? AND verse >= ? AND verse <= ? AND version = ?
      ORDER BY verse
    ''', [book, chapter, startVerse, endVerse, version]);
    
    if (result.isEmpty) return null;
    
    return result.map((row) => row['text'] as String).join('\n\n');
  }
  
  static Future<String?> _getMultiChapterPassage(String book, int startChapter, int startVerse, int endChapter, int endVerse, String version) async {
    final result = await _database!.rawQuery('''
      SELECT text FROM verses 
      WHERE book = ? AND (
        (chapter = ? AND verse >= ?) OR 
        (chapter > ? AND chapter < ?) OR 
        (chapter = ? AND verse <= ?)
      ) AND version = ?
      ORDER BY chapter, verse
    ''', [book, startChapter, startVerse, startChapter, endChapter, endChapter, endVerse, version]);
    
    if (result.isEmpty) return null;
    
    return result.map((row) => row['text'] as String).join('\n\n');
  }
  
  static Future<String?> _getSingleVerse(String book, int chapter, int verse, String version) async {
    final result = await _database!.rawQuery('''
      SELECT text FROM verses 
      WHERE book = ? AND chapter = ? AND verse = ? AND version = ?
    ''', [book, chapter, verse, version]);
    
    if (result.isEmpty) return null;
    
    return result.first['text'] as String;
  }
}
```

---

## 🚨 PROBLÈMES IDENTIFIÉS

### 1. PROBLÈME PRINCIPAL : Erreur de type Map
**Localisation :** `pre_meditation_prayer_page.dart` ligne 281
**Cause :** `todayPassage.readings.first.range` retourne un `Map<dynamic, dynamic>` au lieu d'un `String`
**Impact :** Navigation échoue, aucun texte affiché

### 2. PROBLÈME SECONDAIRE : Pas de jours de plan
**Localisation :** `plan_service_http.dart` ligne 230
**Cause :** `getPlanDays` retourne une liste vide
**Impact :** Fallback vers passages génériques

### 3. PROBLÈME DE DÉSÉRIALISATION
**Localisation :** `ReadingRef.fromJson()` dans `plan_models.dart`
**Cause :** Pas de vérification de type pour la propriété `range`
**Impact :** Données corrompues lors de la désérialisation

---

## 🔧 SOLUTIONS PROPOSÉES

### Solution 1 : Corriger la désérialisation ReadingRef
```dart
factory ReadingRef.fromJson(Map<String, dynamic> j) {
  // Vérifier et corriger le type de range
  dynamic rangeValue = j['range'];
  String rangeString;
  
  if (rangeValue is String) {
    rangeString = rangeValue;
  } else if (rangeValue is Map) {
    // Si c'est un Map, essayer d'extraire la valeur
    rangeString = rangeValue['range'] as String? ?? 
                  rangeValue['reference'] as String? ?? 
                  '1:1';
  } else {
    rangeString = '1:1'; // Fallback
  }
  
  return ReadingRef(
    book: j['book'] as String? ?? 'Jean',
    range: rangeString,
    url: j['url'] as String?,
  );
}
```

### Solution 2 : Améliorer la gestion des erreurs dans getPlanDays
```dart
@override
Future<List<PlanDay>> getPlanDays(String planId, {int? fromDay, int? toDay}) async {
  try {
    final key = 'days:$planId:${fromDay ?? 1}:${toDay ?? 0}';
    final cached = cachePlanDays.get(key);
    if (cached != null) {
      final list = (cached as List).map((e) {
        try {
          return PlanDay.fromJson(Map<String, dynamic>.from(e));
        } catch (e) {
          print('⚠️ Erreur désérialisation PlanDay: $e');
          return null;
        }
      }).where((e) => e != null).cast<PlanDay>().toList();
      return list;
    }
    
    // ... reste du code
  } catch (e) {
    print('❌ Erreur critique getPlanDays: $e');
    return [];
  }
}
```

### Solution 3 : Créer un service de régénération des jours
```dart
class PlanDaysRegenerator {
  static Future<List<PlanDay>> regeneratePlanDays(String planId, Plan plan) async {
    try {
      // Récupérer les passages personnalisés du plan
      final customPassages = await _getCustomPassages(planId);
      
      if (customPassages != null && customPassages.isNotEmpty) {
        return _createDaysFromCustomPassages(planId, customPassages);
      } else {
        return _createGenericDays(planId, plan);
      }
    } catch (e) {
      print('❌ Erreur régénération jours: $e');
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>?> _getCustomPassages(String planId) async {
    // Récupérer depuis le cache ou la base de données
    final cacheKey = 'custom_passages:$planId';
    final cached = cachePlanDays.get(cacheKey);
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }
    return null;
  }
  
  static List<PlanDay> _createDaysFromCustomPassages(String planId, List<Map<String, dynamic>> passages) {
    final List<PlanDay> days = [];
    
    for (int i = 0; i < passages.length; i++) {
      final passage = passages[i];
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
    
    return days;
  }
  
  static List<PlanDay> _createGenericDays(String planId, Plan plan) {
    final List<PlanDay> days = [];
    var currentDate = plan.startDate;
    
    for (int i = 0; i < plan.totalDays; i++) {
      final day = PlanDay(
        id: '${planId}_day_${i + 1}',
        planId: planId,
        dayIndex: i + 1,
        date: currentDate,
        completed: false,
        readings: [
          ReadingRef(
            book: 'Jean',
            range: '${i + 1}:1-10',
            url: null,
          ),
        ],
      );
      days.add(day);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return days;
  }
}
```

---

## 📊 LOGS D'ERREUR COMPLETS

```
I/flutter (15824): 🧭 Router Guard: hasOnboarded=true, currentPlanId=88b09cc8-8a59-4c88-9e95-7541ac3c997f, path=/pre_meditation_prayer
I/flutter (15824): [telemetry] active_local_plan_verified {plan_id: 88b09cc8-8a59-4c88-9e95-7541ac3c997f}
I/flutter (15824): ❌ Erreur navigation vers ReaderPageModern: type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>'
I/flutter (15824): 🧭 Router Guard: hasOnboarded=true, currentPlanId=88b09cc8-8a59-4c88-9e95-7541ac3c997f, path=/reader
I/flutter (15824): ⚠️ Erreur getDownloadStats: DatabaseException(error database_closed)
I/flutter (15824): ✅ Base SQLite déjà peuplée avec 14 versets
I/flutter (15824): 📖 Version utilisateur chargée: semeur
```

---

## 🎯 ACTIONS RECOMMANDÉES

### Priorité 1 (Critique)
1. **Corriger la désérialisation ReadingRef** - Ajouter vérification de type
2. **Améliorer la gestion d'erreur dans _navigateToReader** - Gestion gracieuse des Map vs String
3. **Tester la navigation complète** - Vérifier que le texte s'affiche

### Priorité 2 (Important)
1. **Implémenter PlanDaysRegenerator** - Service de régénération des jours
2. **Améliorer les logs** - Plus de détails sur les erreurs
3. **Ajouter des tests unitaires** - Pour éviter les régressions

### Priorité 3 (Amélioration)
1. **Optimiser la performance** - Cache plus intelligent
2. **Améliorer l'UX** - Messages d'erreur plus clairs
3. **Documentation** - Guide de débogage

---

## 📁 FICHIERS À MODIFIER

1. **`lib/models/plan_models.dart`** - Corriger ReadingRef.fromJson()
2. **`lib/services/plan_service_http.dart`** - Améliorer getPlanDays()
3. **`lib/views/pre_meditation_prayer_page.dart`** - Gestion d'erreur navigation
4. **`lib/services/plan_days_regenerator.dart`** - Nouveau service (à créer)

---

## 🔗 RESSOURCES UTILES

- **Base de données SQLite** : `/assets/db/bible_verses.db`
- **Cache Hive** : `cachePlanDays` et `cachePlans`
- **Service de texte** : `BibleTextService`
- **Router** : `GoRouter` avec guards d'authentification

---

## 📞 CONTACT

**Développeur principal :** Claude (Assistant IA)
**Projet :** Selah App - Application de lecture biblique
**Date :** 16 octobre 2025
**Statut :** En cours de résolution

---

*Ce rapport contient tous les éléments nécessaires pour comprendre et résoudre le problème de navigation et d'affichage du texte biblique dans l'application Selah.*


