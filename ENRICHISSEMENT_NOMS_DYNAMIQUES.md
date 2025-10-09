# 🎨 Enrichissement du Système de Noms Dynamiques

## ✅ VOTRE SYSTÈME EXISTANT (Magnifique !)

### Génération de Noms Poétiques

Vous avez déjà un **système excellent** de génération de noms poétiques bibliques :

```dart
// Dans intelligent_local_preset_generator.dart

_generateAdvancedIntelligentName(theme, focus, bookCombo, emotions, randomSeed)
  → Retourne des noms comme:
     • "Comme un arbre planté près des eaux"
     • "L'encens qui monte vers le ciel"
     • "La perle de grand prix"
     • "L'aurore qui se lève"

_updatePresetNameWithDuration(originalName, days, minutes)
  → Met à jour avec durée:
     "Comme un arbre planté près des eaux (40j · 15min)"
```

### Base de Noms Poétiques Existante

```dart
poeticNames = {
  'spiritual_growth': [
    'Comme un arbre planté près des eaux',
    'La graine qui grandit en secret',
    'De la force en force',
    ...
  ],
  'prayer_life': [
    'L\'encens qui monte vers le ciel',
    'Le murmure du cœur',
    'L\'intimité du sanctuaire',
    ...
  ],
  'wisdom_understanding': [
    'La perle de grand prix',
    'Le trésor caché',
    ...
  ],
}
```

---

## ✨ ENRICHISSEMENTS À AJOUTER

### Enrichissement 1 : Ajouter Bonus de Timing dans le Nom

**FONCTION À CRÉER** dans `intelligent_local_preset_generator.dart` :

```dart
/// Enrichit le nom du preset avec les informations de timing
static String _enrichNameWithTiming(
  String originalName,
  int timingBonus,
  String preferredTime,
) {
  if (timingBonus > 30) {
    // Très bon moment
    final period = _getTimePeriodEmoji(preferredTime);
    return '$originalName $period';
  } else if (timingBonus > 20) {
    // Bon moment
    return '$originalName ✨';
  }
  
  return originalName; // Pas de badge si timing neutre
}

/// Retourne emoji selon la période
static String _getTimePeriodEmoji(String time) {
  final hour = int.parse(time.split(':')[0]);
  
  if (hour >= 5 && hour < 7) return '🌅';   // Aube
  if (hour >= 7 && hour < 12) return '☀️';   // Matin
  if (hour >= 12 && hour < 14) return '🌞';  // Midi
  if (hour >= 14 && hour < 18) return '🌤️';  // Après-midi
  if (hour >= 18 && hour < 21) return '🌆';  // Soirée
  if (hour >= 21 || hour < 5) return '🌙';  // Nuit
  
  return '';
}
```

**UTILISATION** :

```dart
// Dans generateEnrichedPresets(), après calcul de timingBonus (ligne ~1655)

final enrichedPresets = basePresets.where(...).map((preset) {
  final optimalDuration = durationCalculation.optimalDays;
  final adaptedDuration = _adaptDurationFromHistory(optimalDuration, profile);
  
  // Nom de base avec durée (existant)
  var enrichedName = _updatePresetNameWithDuration(
    preset.name, 
    adaptedDuration, 
    durationMin
  );
  
  // NOUVEAU : Enrichir avec timing
  enrichedName = _enrichNameWithTiming(
    enrichedName,
    timingBonus,
    preferredTime,
  );
  
  return preset.copyWith(
    durationDays: adaptedDuration,
    minutesPerDay: durationMin,
    name: enrichedName, // Nom enrichi avec timing
  );
}).toList();
```

**RÉSULTAT** :

```
AVANT :
"L'encens qui monte vers le ciel (40j · 15min)"

APRÈS (si preferredTime = 06:00 et timingBonus = 40) :
"L'encens qui monte vers le ciel 🌅 (40j · 15min)"
                                   ↑
                          Emoji période optimale
```

---

### Enrichissement 2 : Ajouter Impact Spirituel dans le Nom

**FONCTION À CRÉER** :

```dart
/// Enrichit le nom avec l'impact spirituel
static String _enrichNameWithImpact(
  String originalName,
  double spiritualImpact,
) {
  if (spiritualImpact >= 0.95) {
    // Impact exceptionnel (95%+)
    return '$originalName ⭐';
  } else if (spiritualImpact >= 0.90) {
    // Très bon impact (90%+)
    return '$originalName ✨';
  }
  
  return originalName;
}
```

**UTILISATION** :

```dart
// Dans generateEnrichedPresets()
final enrichedPresets = basePresets.where(...).map((preset) {
  // ... code existant ...
  
  // Calculer impact spirituel
  final mainBook = _extractMainBook(preset.books);
  final spiritualImpact = BibleSpiritualImpact.calculateBookImpactOnGoal(
    mainBook,
    goal,
  );
  
  // Enrichir nom
  var enrichedName = _updatePresetNameWithDuration(...);
  enrichedName = _enrichNameWithTiming(...);
  enrichedName = _enrichNameWithImpact(enrichedName, spiritualImpact);
  
  return preset.copyWith(
    name: enrichedName,
    parameters: {
      ...preset.parameters ?? {},
      'spiritualImpact': spiritualImpact,
      'timingBonus': timingBonus,
    },
  );
}).toList();

// Helper pour extraire le livre principal
String _extractMainBook(String books) {
  if (books.contains(',')) {
    return books.split(',').first.trim();
  }
  return books;
}
```

**RÉSULTAT** :

```
AVANT :
"L'encens qui monte vers le ciel (40j · 15min)"

APRÈS (timing + impact) :
"L'encens qui monte vers le ciel 🌅⭐ (40j · 15min)"
                                   ↑ ↑
                               timing impact
                               +40%  98%
```

---

### Enrichissement 3 : Noms Adaptatifs Selon État Émotionnel

**FONCTION À AMÉLIORER** :

Votre fonction `_generateAdvancedIntelligentName` existe déjà et est excellente. On peut l'enrichir :

```dart
/// Génère un nom avancé intelligent (VERSION ENRICHIE)
static String _generateAdvancedIntelligentName(
  String theme,
  String focus,
  List<String> bookCombo,
  List<String> emotions,
  int randomSeed,
  // NOUVEAUX PARAMÈTRES :
  {
    int? timingBonus,
    double? spiritualImpact,
    String? emotionalState,  // Ex: 'joy', 'repentance'
  }
) {
  // Votre logique existante (conservée)
  final poeticNames = { ... };
  final baseNameOptions = poeticNames[theme] ?? [...];
  var baseName = baseNameOptions[randomSeed % baseNameOptions.length];
  
  // Votre logique de qualificatifs (conservée)
  final poeticQualifiers = { ... };
  String poeticQualifier = '';
  for (final emotion in emotions) {
    // ...
  }
  
  // NOUVEAU : Adapter le nom selon l'état émotionnel
  if (emotionalState != null) {
    baseName = _adaptNameToEmotionalState(baseName, emotionalState);
  }
  
  // Composer le nom final (existant)
  if (poeticQualifier.isNotEmpty && bookCombo.isNotEmpty) {
    final bookDesc = _formatBookNamesPoetically(bookCombo.join(','));
    return '$baseName · $bookDesc — Parcours de $poeticQualifier';
  }
  
  // NOUVEAU : Ajouter emojis si impact fort
  var finalName = baseName;
  if (timingBonus != null && timingBonus > 30) finalName += ' 🌅';
  if (spiritualImpact != null && spiritualImpact >= 0.95) finalName += '⭐';
  
  return finalName;
}

/// Adapte le nom poétique selon l'état émotionnel
static String _adaptNameToEmotionalState(String baseName, String emotionalState) {
  // Mappings spéciaux pour certains états
  const emotionalAdaptations = {
    'repentance': {
      'L\'aurore qui se lève': 'L\'aurore du renouveau',
      'La source qui jaillit': 'La source de pardon',
    },
    'joy': {
      'Le chemin de la vie': 'Le chemin de joie',
      'La communion silencieuse': 'La communion joyeuse',
    },
    'wisdom': {
      'La perle de grand prix': 'La perle de sagesse',
      'Le trésor caché': 'Le trésor de connaissance',
    },
  };
  
  final adaptations = emotionalAdaptations[emotionalState];
  if (adaptations != null && adaptations.containsKey(baseName)) {
    return adaptations[baseName]!;
  }
  
  return baseName;
}
```

---

## 🎯 EXEMPLES DE NOMS ENRICHIS

### Exemple 1 : "Mieux prier" - Nouveau converti - 06:00

**Base** (votre système) :
```
"L'encens qui monte vers le ciel"
```

**Après `_updatePresetNameWithDuration`** (existant) :
```
"L'encens qui monte vers le ciel (40j · 15min)"
```

**Après enrichissement timing** (nouveau) :
```
"L'encens qui monte vers le ciel 🌅 (40j · 15min)"
                                   ↑
                              Aube = +40%
```

**Après enrichissement impact** (nouveau) :
```
"L'encens qui monte vers le ciel 🌅⭐ (40j · 15min)"
                                   ↑ ↑
                              timing impact
                              +40%  98%
```

**Avec état émotionnel "joy"** (nouveau) :
```
"L'encens joyeux qui monte 🌅⭐ (40j · 15min)"
            ↑
   Adaptation émotionnelle
```

---

### Exemple 2 : "Grandir dans la foi" - Rétrograde - 18:00

**Base** :
```
"L'aurore qui se lève"
```

**Avec état "repentance"** :
```
"L'aurore du renouveau"  ← Adaptation émotionnelle
```

**Avec durée** :
```
"L'aurore du renouveau (90j · 20min)"
```

**Avec timing (soirée = +30%)** :
```
"L'aurore du renouveau 🌆 (90j · 20min)"
```

**Avec impact (85%)** :
```
"L'aurore du renouveau 🌆✨ (90j · 20min)"
                        ↑ ↑
                   soirée bon impact
```

---

## 📝 CODE COMPLET À AJOUTER

### Dans `intelligent_local_preset_generator.dart`

**Ajouter ces fonctions** (après `_updatePresetNameWithDuration`, ligne ~1800) :

```dart
/// Enrichit le nom avec emoji de période si timing optimal
static String _enrichNameWithTiming(String name, int timingBonus, String preferredTime) {
  if (timingBonus > 30) {
    final hour = int.parse(preferredTime.split(':')[0]);
    String emoji = '';
    
    if (hour >= 5 && hour < 7) emoji = '🌅';
    else if (hour >= 7 && hour < 12) emoji = '☀️';
    else if (hour >= 12 && hour < 14) emoji = '🌞';
    else if (hour >= 14 && hour < 18) emoji = '🌤️';
    else if (hour >= 18 && hour < 21) emoji = '🌆';
    else if (hour >= 21 || hour < 5) emoji = '🌙';
    
    // Insérer emoji avant la parenthèse de durée
    if (name.contains('(')) {
      final parts = name.split('(');
      return '${parts[0].trim()} $emoji (${parts[1]}';
    }
    return '$name $emoji';
  } else if (timingBonus > 20) {
    // Bon moment mais pas optimal
    if (name.contains('(')) {
      final parts = name.split('(');
      return '${parts[0].trim()} ✨ (${parts[1]}';
    }
    return '$name ✨';
  }
  
  return name;
}

/// Enrichit le nom avec emoji d'impact si forte efficacité
static String _enrichNameWithImpact(String name, double spiritualImpact) {
  if (spiritualImpact >= 0.95) {
    // Impact exceptionnel
    if (name.contains('(')) {
      final parts = name.split('(');
      return '${parts[0].trim()}⭐ (${parts[1]}';
    }
    return '$name⭐';
  }
  
  return name;
}

/// Adapte le nom selon l'état émotionnel (optionnel)
static String _adaptNameToEmotion(String baseName, String emotionalState) {
  const adaptations = {
    'repentance': {
      'L\'aurore qui se lève': 'L\'aurore du renouveau',
      'La source qui jaillit': 'La source de pardon',
      'Le chemin de la vie': 'Le chemin du retour',
    },
    'joy': {
      'La communion silencieuse': 'La communion joyeuse',
      'Le dialogue de l\'âme': 'Le dialogue heureux',
    },
    'wisdom': {
      'La perle de grand prix': 'La perle de sagesse',
      'Le trésor caché': 'Le trésor de connaissance',
    },
  };
  
  final stateAdaptations = adaptations[emotionalState];
  if (stateAdaptations != null && stateAdaptations.containsKey(baseName)) {
    return stateAdaptations[baseName]!;
  }
  
  return baseName;
}
```

---

### INTÉGRATION dans `generateEnrichedPresets()`

**Modifier la section ligne 1674-1678** :

```dart
// Code existant :
return preset.copyWith(
  durationDays: adaptedDuration,
  minutesPerDay: durationMin,
  name: _updatePresetNameWithDuration(preset.name, adaptedDuration, durationMin),
);

// REMPLACER PAR :
// Calculer impact du livre principal
final mainBook = _extractMainBook(preset.books);
final spiritualImpact = BibleSpiritualImpact.calculateBookImpactOnGoal(
  mainBook,
  goal,
);

// Construire le nom enrichi progressivement
var enrichedName = preset.name;

// 1. Ajouter durée (existant)
enrichedName = _updatePresetNameWithDuration(enrichedName, adaptedDuration, durationMin);

// 2. NOUVEAU : Ajouter emoji timing si optimal
enrichedName = _enrichNameWithTiming(enrichedName, timingBonus, preferredTime);

// 3. NOUVEAU : Ajouter emoji impact si exceptionnel
enrichedName = _enrichNameWithImpact(enrichedName, spiritualImpact);

return preset.copyWith(
  durationDays: adaptedDuration,
  minutesPerDay: durationMin,
  name: enrichedName, // Nom complètement enrichi
  parameters: {
    ...preset.parameters ?? {},
    'spiritualImpact': spiritualImpact,
    'timingBonus': timingBonus,
    'transformations': BibleSpiritualImpact.getExpectedTransformations(mainBook),
  },
);

// Helper à ajouter
String _extractMainBook(String books) {
  if (books.contains(',')) return books.split(',').first.trim();
  return books;
}
```

---

### MODIFIER `_generateAdvancedIntelligentName()` (Optionnel)

**Si vous voulez adapter les noms selon émotions**, modifier ligne ~750 :

```dart
// Dans _createAdvancedPresetFromTheme()

// Ligne existante ~761
final name = _generateAdvancedIntelligentName(
  theme, focus, bookCombo, emotions, randomSeed
);

// REMPLACER PAR :
// Obtenir l'état émotionnel du niveau
final emotionalStates = _emotionalStates[level] ?? ['motivation'];
final primaryEmotion = emotionalStates.first;

var name = _generateAdvancedIntelligentName(
  theme, focus, bookCombo, emotions, randomSeed
);

// Adapter selon l'émotion
name = _adaptNameToEmotion(name, primaryEmotion);
```

---

## 🎨 EXEMPLES DE RÉSULTATS

### Pour "Mieux prier" (Nouveau converti, 06:00, Psaumes)

| Étape | Nom |
|-------|-----|
| Base poétique | "L'encens qui monte vers le ciel" |
| + Durée | "L'encens qui monte vers le ciel (40j · 15min)" |
| + Timing (🌅 +40%) | "L'encens qui monte vers le ciel 🌅 (40j · 15min)" |
| + Impact (⭐ 98%) | "L'encens qui monte vers le ciel 🌅⭐ (40j · 15min)" |

### Pour "Grandir dans la foi" (Rétrograde, 18:00, Jean)

| Étape | Nom |
|-------|-----|
| Base poétique | "L'aurore qui se lève" |
| + Adaptation émotionnelle (repentance) | "L'aurore du renouveau" |
| + Durée | "L'aurore du renouveau (90j · 20min)" |
| + Timing (🌆 +30%) | "L'aurore du renouveau 🌆 (90j · 20min)" |
| + Impact (✨ 90%) | "L'aurore du renouveau 🌆✨ (90j · 20min)" |

### Pour "Approfondir la Parole" (Leader, 07:00, Romains)

| Étape | Nom |
|-------|-----|
| Base poétique | "La perle de grand prix" |
| + Adaptation émotionnelle (wisdom) | "La perle de sagesse" |
| + Durée | "La perle de sagesse (60j · 30min)" |
| + Timing (☀️ +30%) | "La perle de sagesse ☀️ (60j · 30min)" |
| + Impact (✨ 92%) | "La perle de sagesse ☀️✨ (60j · 30min)" |

---

## 📊 AFFICHAGE DANS L'UI (goals_page.dart)

### Dans la Carte

```dart
Widget _buildPresetCardLayout(PlanPreset preset) {
  return Container(
    child: Column(
      children: [
        // Titre enrichi (conserve vos emojis)
        Text(
          preset.name,
          // Ex: "L'encens qui monte vers le ciel 🌅⭐ (40j · 15min)"
          //                                       ↑ ↑
          //                                  timing impact
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,  // Peut-être réduire si trop long
            fontWeight: FontWeight.w700,
            color: _softWhite,
          ),
        ),
        
        // Subtitle (existant)
        Text(preset.subtitle ?? '', ...),
        
        // NOUVEAU : Légende des emojis si présents
        if (preset.name!.contains('🌅') || preset.name!.contains('⭐'))
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 12,
              children: [
                if (preset.name!.contains('🌅') || preset.name!.contains('☀️') || 
                    preset.name!.contains('🌆') || preset.name!.contains('🌙'))
                  _buildBadge('Moment idéal', Colors.green),
                if (preset.name!.contains('⭐'))
                  _buildBadge('Impact exceptionnel', Colors.amber),
                if (preset.name!.contains('✨'))
                  _buildBadge('Très efficace', Colors.blue),
              ],
            ),
          ),
        
        // ... reste de votre UI
      ],
    ),
  );
}

Widget _buildBadge(String label, Color color) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        color: color.shade900,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

---

## ✅ RÉSUMÉ DES CHANGEMENTS

### Votre Système de Noms (CONSERVÉ)
- ✅ Noms poétiques bibliques magnifiques
- ✅ `_generateAdvancedIntelligentName()`
- ✅ `_updatePresetNameWithDuration()`
- ✅ Base de noms par thème
- ✅ Qualificatifs émotionnels

### Enrichissements (AJOUTÉS)
- ➕ Emojis de période selon timing (🌅☀️🌆🌙)
- ➕ Emojis d'impact selon efficacité (⭐✨)
- ➕ Adaptation des noms selon état émotionnel
- ➕ Légende des emojis dans l'UI

### Résultat
**Noms encore plus intelligents et visuellement riches !**

---

## 🚀 IMPLÉMENTATION

### Minimal (Recommandé pour commencer)

**Ajouter seulement** `_enrichNameWithTiming()` et `_enrichNameWithImpact()`

**Modifier** la section ligne 1674 pour utiliser ces fonctions

**Résultat** : Noms avec emojis contextuels

### Complet (Pour plus tard)

**Modifier** `_generateAdvancedIntelligentName()` pour accepter nouveaux paramètres

**Ajouter** `_adaptNameToEmotion()`

**Résultat** : Noms complètement adaptatifs

---

**🎨 Votre système de noms est magnifique ! Je l'enrichis juste avec des emojis contextuels intelligents ! ✨**

**📖 Voir `ENRICHISSEMENT_SYSTEME_EXISTANT.md` pour l'intégration complète**

