# 📖 CODE D'INTÉGRATION - Reader Page (Design Final)

**Fichier à modifier** : `lib/views/reader_page_modern.dart`  
**Temps** : ~30 minutes  
**Complexité** : Facile (copier-coller)

---

## 🎯 CE QUI CHANGE

### AVANT
```dart
Surlignage → Rien
Marquer lu → Direct vers méditation
```

### APRÈS
```dart
Long press verset → Menu 9 actions (gradient + glass)
Marquer lu → Dialog "Retenu" → Journal/Mur → Méditation
```

---

## 📝 INTÉGRATION EN 3 ÉTAPES

### ÉTAPE 1 : Imports (ligne 1-20)

**Ajouter en haut du fichier** :

```dart
import 'package:flutter/services.dart'; // Si pas déjà présent
import '../widgets/reading_actions_sheet.dart';
```

---

### ÉTAPE 2 : Handler de long press

**Ajouter dans la classe `_ReaderPageModernState`** :

```dart
// ═══════════════════════════════════════════════════════════════
// NOUVEAU : Handler pour menu contextuel
// ═══════════════════════════════════════════════════════════════

/// Gère le long press sur un verset
void _handleVerseLongPress(String verseId) {
  HapticFeedback.selectionClick();
  showReadingActions(context, verseId);
}

/// Construit l'ID du verset depuis le contexte actuel
/// 
/// Retourne : "Livre.Chapitre.Verset" (ex: "Jean.3.16")
String _buildVerseId(int verseNumber) {
  // Utiliser vos variables d'état actuelles
  final book = _currentBook ?? 'Jean'; // Votre variable
  final chapter = _currentChapter ?? 3; // Votre variable
  
  return '$book.$chapter.$verseNumber';
}
```

---

### ÉTAPE 3 : Modifier l'affichage des versets

**Chercher votre widget d'affichage de verset** (probablement dans `_buildVersesList` ou similaire)

#### Option A : Si vous avez déjà un GestureDetector

```dart
// AVANT
GestureDetector(
  onTap: () => _handleVerseTap(verseNumber),
  child: _buildVerseText(verse, verseNumber),
)

// APRÈS : Ajouter onLongPress
GestureDetector(
  onTap: () => _handleVerseTap(verseNumber),
  onLongPress: () => _handleVerseLongPress(_buildVerseId(verseNumber)), // ✅ NOUVEAU
  child: _buildVerseText(verse, verseNumber),
)
```

#### Option B : Si vous construisez directement le Text

```dart
// AVANT
Text('$verseNumber $verseText')

// APRÈS : Wrapper dans GestureDetector
GestureDetector(
  onLongPress: () => _handleVerseLongPress(_buildVerseId(verseNumber)),
  child: RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: '$verseNumber ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        TextSpan(
          text: verseText,
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  ),
)
```

---

### ÉTAPE 4 : Modifier "Marquer comme lu"

**Chercher votre bouton "Marquer comme lu"** (probablement en bas de page)

#### AVANT

```dart
ElevatedButton(
  onPressed: () async {
    // Sauvegarder progression
    await _saveProgress();
    
    // Aller vers méditation
    context.go('/meditation/chooser');
  },
  child: Text('Marquer comme lu'),
)
```

#### APRÈS

```dart
ElevatedButton(
  onPressed: () async {
    // ✅ NOUVEAU : Afficher dialog de rétention
    final passageId = _buildPassageId(); // Ex: "Jean.3.1" (premier verset du chapitre)
    
    await promptRetainedThenMarkRead(context, passageId);
    
    // Sauvegarder progression
    await _saveProgress();
    
    // Aller vers méditation
    context.go('/meditation/chooser');
  },
  child: Text('Marquer comme lu'),
)

// ✅ NOUVEAU : Helper pour ID du passage
String _buildPassageId() {
  final book = _currentBook ?? 'Jean';
  final chapter = _currentChapter ?? 3;
  return '$book.$chapter.1'; // Premier verset du chapitre
}
```

---

## 🧪 TESTER

### Test 1 : Menu contextuel

```
1. Lancer l'app
2. Ouvrir reader_page
3. Long press sur un verset
4. Vérifier : Menu 9 actions avec gradient violet ✅
5. Tester chaque action
```

### Test 2 : Rétention

```
1. Lire un passage
2. Appuyer "Marquer comme lu"
3. Vérifier : Dialog "Ce que j'ai retenu" ✅
4. Saisir texte
5. Cocher Journal/Mur
6. Enregistrer
7. Vérifier : Toast "Rétention enregistrée" ✅
```

### Test 3 : Désactivation comparaison versions

```
1. Avoir qu'1 seule version téléchargée
2. Long press verset
3. Vérifier : "Comparer versions" grisé ✅
```

---

## 🎨 DESIGN ATTENDU

### Menu Principal

```
┌─────────────────────────────────────────┐
│         ──────                          │ ← Handle
│                                         │
│   📚 Outils d'étude                     │ ← Titre
│      Jean 3 16                          │ ← Sous-titre
│                                         │
│  [🔗] Références croisées          >   │
│  [🌐] Analyse lexicale             >   │
│  [↔️] Verset miroir                >   │
│  [✨] Thèmes spirituels            >   │
│  [📊] Comparer versions (grisé)    >   │
│  [📜] Contexte historique          >   │
│  [🌍] Contexte culturel            >   │
│  [👥] Auteur / personnages         >   │
│  [📚] Mémoriser ce passage         >   │
│                                         │
└─────────────────────────────────────────┘
  Gradient violet + Glass effect
```

### Feuille Secondaire (Exemple : Lexique)

```
┌─────────────────────────────────────────┐
│         ──────                          │
│                                         │
│   Analyse lexicale                      │
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ agapaō (grc)  |  aimer (amour divin)││
│ └─────────────────────────────────────┘│
│ ┌─────────────────────────────────────┐│
│ │ kosmos (grc)  |  monde, univers     ││
│ └─────────────────────────────────────┘│
│ ┌─────────────────────────────────────┐│
│ │ pisteuō (grc) |  croire, avoir foi  ││
│ └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
  Même gradient + glass
```

---

## 💡 EXEMPLES DE CODE COMPLET

### Exemple reader_page_modern.dart (structure simplifiée)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/reading_actions_sheet.dart';

class ReaderPageModern extends StatefulWidget {
  const ReaderPageModern({super.key});

  @override
  State<ReaderPageModern> createState() => _ReaderPageModernState();
}

class _ReaderPageModernState extends State<ReaderPageModern> {
  // Vos variables d'état existantes
  String? _currentBook = 'Jean';
  int? _currentChapter = 3;
  double _fontSize = 16.0;
  List<Map<String, dynamic>> _verses = [];
  
  @override
  void initState() {
    super.initState();
    _loadChapter();
  }
  
  Future<void> _loadChapter() async {
    // Votre logique existante de chargement
  }
  
  // ✅ NOUVEAU : Handler long press
  void _handleVerseLongPress(String verseId) {
    HapticFeedback.selectionClick();
    showReadingActions(context, verseId);
  }
  
  // ✅ NOUVEAU : Builder ID verset
  String _buildVerseId(int verseNumber) {
    final book = _currentBook ?? 'Jean';
    final chapter = _currentChapter ?? 3;
    return '$book.$chapter.$verseNumber';
  }
  
  // ✅ NOUVEAU : Builder ID passage
  String _buildPassageId() {
    final book = _currentBook ?? 'Jean';
    final chapter = _currentChapter ?? 3;
    return '$book.$chapter.1';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Votre header existant
          _buildHeader(),
          
          // Liste des versets
          Expanded(
            child: ListView.builder(
              itemCount: _verses.length,
              itemBuilder: (context, index) {
                final verse = _verses[index];
                final verseNumber = verse['verse'] as int;
                final verseText = verse['text'] as String;
                
                // ✅ Wrapper avec GestureDetector
                return GestureDetector(
                  onLongPress: () => _handleVerseLongPress(_buildVerseId(verseNumber)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$verseNumber ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextSpan(
                            text: verseText,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bouton "Marquer comme lu"
          _buildMarkAsReadButton(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    // Votre header existant
    return Container();
  }
  
  Widget _buildMarkAsReadButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () async {
          // ✅ NOUVEAU : Flux de rétention
          await promptRetainedThenMarkRead(context, _buildPassageId());
          
          // Sauvegarder progression
          await _saveProgress();
          
          // Aller vers méditation
          Navigator.pushNamed(context, '/meditation/chooser');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C34D1),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Marquer comme lu',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveProgress() async {
    // Votre logique existante
  }
}
```

---

## 🔗 INTÉGRATION DANS VOTRE CODE ACTUEL

### Si vous utilisez SelectableText

```dart
SelectableText(
  verseText,
  onSelectionChanged: (selection, cause) {
    if (selection.baseOffset != selection.extentOffset) {
      // Texte sélectionné
      final selectedText = verseText.substring(
        selection.baseOffset,
        selection.extentOffset,
      );
      
      // Afficher menu
      _handleVerseLongPress(_buildVerseId(verseNumber));
    }
  },
)
```

### Si vous utilisez des widgets personnalisés

```dart
// Wrapper votre widget de verset avec GestureDetector
Widget _buildVerse(int number, String text) {
  return GestureDetector(
    onLongPress: () {
      HapticFeedback.selectionClick();
      showReadingActions(context, _buildVerseId(number));
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$number ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## 🎨 DESIGN EXACT IMPLÉMENTÉ

Votre code UI est **déjà implémenté** dans `reading_actions_sheet.dart` avec :

✅ **Gradient** : `[Color(0xFF1C1740), Color(0xFF2D1B69)]`  
✅ **Glass effect** : `BackdropFilter.blur(sigmaX: 18, sigmaY: 18)`  
✅ **Handle** : Barre blanche semi-transparente  
✅ **Actions** : 9 boutons avec icônes encadrées  
✅ **Toast** : Snackbar vert arrondi  
✅ **Dialog rétention** : Même style gradient  

---

## 🧪 TESTS VISUELS

### Checklist visuelle

- [ ] Long press verset → Menu s'ouvre ✅
- [ ] Gradient violet correct ✅
- [ ] Glass effect visible ✅
- [ ] 9 actions listées ✅
- [ ] "Comparer versions" grisé si 1 seule ✅
- [ ] Chaque action ouvre feuille secondaire ✅
- [ ] Même style pour toutes les feuilles ✅
- [ ] Dialog "Retenu" avec checkboxes ✅
- [ ] Toast vert après enregistrement ✅

---

## 📱 EXEMPLE COMPLET D'UTILISATION

### Scenario utilisateur

```
1. Utilisateur lit Jean 3
2. Long press sur verset 16
   
   ┌─────────────────────────────────┐
   │  📚 Outils d'étude              │
   │     Jean 3 16                   │
   │                                 │
   │ [🔗] Références croisées    >  │ ← Tap
   └─────────────────────────────────┘
   
   ┌─────────────────────────────────┐
   │  Références croisées            │
   │                                 │
   │  • 1Jean 4 9                   │ ← Tap → Navigation
   │  • Romains 5 8                 │
   │  • Éphésiens 2 4               │
   └─────────────────────────────────┘

3. Utilisateur explore lexique
   
   ┌─────────────────────────────────┐
   │  Analyse lexicale               │
   │                                 │
   │  agapaō (grc) | aimer          │
   │  kosmos (grc) | monde          │
   │  pisteuō (grc) | croire        │
   └─────────────────────────────────┘

4. Utilisateur marque comme lu
   
   ┌─────────────────────────────────┐
   │  Ce que j'ai retenu             │
   │                                 │
   │  ┌───────────────────────────┐ │
   │  │ Dieu aime le monde entier │ │
   │  │ et offre la vie éternelle │ │
   │  └───────────────────────────┘ │
   │                                 │
   │  ☑️ Ajouter au Journal         │
   │  ☐ Ajouter au Mur spirituel    │
   │                                 │
   │            [Enregistrer]        │
   └─────────────────────────────────┘
   
   Toast : "✅ Rétention enregistrée"
   
5. Flux continue vers méditation
```

---

## 📋 VARIABLES À ADAPTER

Dans votre `_ReaderPageModernState`, vous avez probablement :

```dart
// Adaptez ces noms de variables
String? _currentBook;      // ← Votre variable
int? _currentChapter;      // ← Votre variable
int? _currentVerse;        // ← Si vous trackez le verset

// Ou peut-être :
Map<String, dynamic>? _currentPassage;
String? _currentReference;

// Adaptez la méthode _buildVerseId() selon votre structure
```

---

## 🚀 CHECKLIST RAPIDE

### Avant d'intégrer

- [ ] Lire ce guide complètement
- [ ] Identifier vos variables d'état (book, chapter)
- [ ] Localiser votre widget d'affichage versets
- [ ] Localiser votre bouton "Marquer comme lu"

### Intégration

- [ ] Ajouter import `reading_actions_sheet.dart`
- [ ] Ajouter méthode `_handleVerseLongPress`
- [ ] Ajouter méthode `_buildVerseId`
- [ ] Wrapper versets avec GestureDetector + onLongPress
- [ ] Modifier bouton "Marquer lu" avec `promptRetainedThenMarkRead`

### Tests

- [ ] Test long press → Menu
- [ ] Test chaque action (9)
- [ ] Test "Marquer lu" → Dialog
- [ ] Test enregistrement rétention
- [ ] Test toast de confirmation

---

## 💡 AIDE AU DEBUGGING

### Si le menu ne s'ouvre pas

```dart
// Vérifier l'import
import '../widgets/reading_actions_sheet.dart';

// Vérifier l'appel
showReadingActions(context, verseId);

// Log pour debug
print('Long press sur verset: $verseId');
```

### Si les services retournent vide

```dart
// Vérifier hydratation
final stats = await BibleStudyHydrator.getHydrationStats();
print(stats); // Devrait montrer des entrées > 0

// Forcer ré-hydratation si nécessaire
await BibleStudyHydrator.hydrateAll();
```

### Si le design ne match pas

```dart
// Vérifier que vous avez bien google_fonts dans pubspec.yaml
// Vérifier que les couleurs sont exactes :
Color(0xFF1C1740) // Violet foncé
Color(0xFF2D1B69) // Violet plus clair
```

---

**✅ Code prêt à intégrer ! Design exact implémenté ! 🎨**

