# 💻 CODE D'INTÉGRATION - Badges Timing & Impact

**Objectif** : Afficher les badges "timing bonus" et "impact spirituel" sur les cartes de plans

---

## 📝 MODIFICATION 1 : Lire les parameters dans _buildPlanCard

**Fichier** : `lib/views/goals_page.dart`  
**Ligne** : 409 (début de _buildPlanCard)

### AVANT

```dart
Widget _buildPlanCard(PlanPreset preset) {
  final weeks = (preset.durationDays / 7).ceil();
  
  // ✅ Couleur intelligente du texte selon la luminosité du fond
  final cardColor = _getCardColorForPreset(preset);
  final textColor = _getIntelligentTextColor(cardColor);
```

### APRÈS

```dart
Widget _buildPlanCard(PlanPreset preset) {
  final weeks = (preset.durationDays / 7).ceil();
  
  // ✅ NOUVEAU : Lire les parameters intelligents
  final parameters = preset.parameters ?? {};
  final timingBonus = parameters['timingBonus'] as int? ?? 0;
  final spiritualImpact = parameters['spiritualImpact'] as double? ?? 0.0;
  final expectedTransformations = parameters['expectedTransformations'] as List? ?? [];
  
  // ✅ Couleur intelligente du texte selon la luminosité du fond
  final cardColor = _getCardColorForPreset(preset);
  final textColor = _getIntelligentTextColor(cardColor);
```

---

## 📝 MODIFICATION 2 : Ajouter le badge timing bonus

**Fichier** : `lib/views/goals_page.dart`  
**Ligne** : Après ligne 513 (après l'icône en haut à droite)

### Chercher ce bloc

```dart
// ✅ PETITE ICÔNE encadrée en HAUT À DROITE
Positioned(
  top: 15,
  right: 15,
  child: Column(
    children: [
      Container(
        // ... icône ...
      ),
      // ✅ "Recommandé" sous l'icône
      if (_isRecommendedPreset(preset)) ...[
        // ... badge recommandé ...
      ],
    ],
  ),
),
```

### AJOUTER APRÈS (nouvelle Positioned)

```dart
// ✅ BADGE TIMING BONUS (haut gauche)
if (timingBonus > 20)
  Positioned(
    top: 15,
    left: 15,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA726).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wb_sunny_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '+$timingBonus%',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  ),
```

---

## 📝 MODIFICATION 3 : Ajouter la barre d'impact spirituel

**Fichier** : `lib/views/goals_page.dart`  
**Ligne** : Chercher le nom du plan (vers ligne 560-580)

### Chercher ce bloc

```dart
// Titre GILROY HEAVY ITALIC + Livres en bas
Positioned(
  top: 120,
  left: 0,
  right: 0,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // ✅ NOM DU PLAN
      Text(
        preset.name,
        // ... style ...
      ),
      // ... le reste ...
    ],
  ),
),
```

### AJOUTER APRÈS le Text(preset.name)

```dart
// ✅ NOM DU PLAN
Text(
  preset.name,
  style: TextStyle(
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w900,
    fontSize: 24,
    fontStyle: FontStyle.italic,
    color: textColor,
    letterSpacing: -0.5,
  ),
  textAlign: TextAlign.center,
),

// ✅ NOUVEAU : BARRE D'IMPACT SPIRITUEL
if (spiritualImpact > 0.85) ...[
  const SizedBox(height: 12),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 12,
              color: textColor.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Impact spirituel',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: spiritualImpact,
            minHeight: 6,
            backgroundColor: textColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(spiritualImpact * 100).round()}%',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  ),
],
```

---

## 📝 MODIFICATION 4 : Afficher les transformations

**Optionnel** : Afficher les transformations attendues sous le nombre de livres

### Chercher (vers ligne 600-650)

```dart
// Livres en bas
Text(
  _getBooksSummary(preset),
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textColor.withOpacity(0.7),
  ),
),
```

### AJOUTER APRÈS

```dart
// Livres en bas
Text(
  _getBooksSummary(preset),
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textColor.withOpacity(0.7),
  ),
),

// ✅ NOUVEAU : TRANSFORMATION PRINCIPALE
if (expectedTransformations.isNotEmpty) ...[
  const SizedBox(height: 8),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: textColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.trending_up_rounded,
          size: 12,
          color: textColor.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          expectedTransformations.first as String,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  ),
],
```

---

## 🎨 RÉSULTAT VISUEL ATTENDU

```
┌─────────────────────────────────────────────────┐
│  ☀️ +40%                        ⭐ [Top]      │  ← Badges
│                                                  │
│        13                                        │  ← Semaines
│     semaines                                     │
│                                                  │
│   L'encens qui monte 🌅                         │  ← Nom
│                                                  │
│   Impact spirituel  ⭐                          │  ← Label
│   ████████████████░░  98%                       │  ← Barre
│                                                  │
│   📖 Psaumes                                    │  ← Livres
│   ↗️ Vie de louange                             │  ← Transformation
│                                                  │
│   15 min/jour · 7 jours/semaine                 │  ← Détails
│                                                  │
│   [Créer ce plan]                                │  ← Bouton
└─────────────────────────────────────────────────┘
```

---

## 🧪 CODE DE TEST

### Tester la génération avec parameters

```dart
void testParametersGeneration() async {
  final profile = {
    'level': 'Fidèle régulier',
    'goal': 'Mieux prier',
    'preferredTime': '06:00', // ← Matin tôt
    'dailyMinutes': 15,
  };
  
  final presets = IntelligentLocalPresetGenerator.generateEnrichedPresets(profile);
  
  for (final preset in presets) {
    print('Preset: ${preset.name}');
    
    final params = preset.parameters ?? {};
    print('  Timing bonus: ${params['timingBonus']}%'); // Devrait être > 30
    print('  Spiritual impact: ${params['spiritualImpact']}'); // Devrait être > 0.9
    print('  Transformations: ${params['expectedTransformations']}');
  }
}
```

### Tester l'affichage des badges

```dart
void testBadgeDisplay() {
  // Créer un preset de test
  final testPreset = PlanPreset(
    slug: 'test',
    name: 'Plan test',
    durationDays: 30,
    order: 'traditional',
    books: 'Psaumes',
    parameters: {
      'timingBonus': 45,      // ← Badge devrait s'afficher
      'spiritualImpact': 0.98, // ← Barre devrait s'afficher
      'expectedTransformations': ['Vie de louange'],
    },
  );
  
  // Ouvrir goals_page et vérifier visuellement :
  // 1. Badge "+45%" en haut à gauche ✅
  // 2. Barre "Impact spirituel 98%" visible ✅
  // 3. Transformation "Vie de louange" visible ✅
}
```

---

## 📋 CHECKLIST VISUELLE

Après intégration, vérifier sur la carte :

- [ ] Badge "+XX%" visible en haut gauche (si > 20%)
- [ ] Couleur badge : Gradient orange (#FFA726 → #FF6F00)
- [ ] Icône soleil (wb_sunny_rounded) dans le badge
- [ ] Badge "Top" en haut à droite (si recommandé)
- [ ] Barre d'impact spirituel visible (si > 85%)
- [ ] Pourcentage d'impact affiché
- [ ] Transformation attendue affichée
- [ ] Pas de chevauchement entre éléments
- [ ] Responsive sur différentes tailles d'écran

---

**✅ Code prêt à intégrer ! Copiez-collez les modifications ci-dessus.**

