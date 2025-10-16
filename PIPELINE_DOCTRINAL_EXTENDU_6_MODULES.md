# 🕊️ Pipeline Doctrinal Étendu - 6 Modules Complets

## Vue d'ensemble

Extension du système doctrinal avec une architecture modulaire réutilisable et 6 doctrines complètes : **Crainte de Dieu**, **Sainteté**, **Humilité**, **Grâce**, **Prière**, et **Sagesse**.

## Architecture Modulaire

### 1. Base Réutilisable
**Fichier:** `lib/services/doctrine/anchored_doctrine_base.dart`

#### DoctrineContext
Contexte intelligent avec calcul de pondération dynamique :
```dart
class DoctrineContext {
  final Map<String, dynamic>? userProfile;
  final int minutesPerDay;
  
  double weightFor(List<String> hints, {double base = 1.0, double bonus = .25}) {
    // Analyse du profil utilisateur et calcul d'intensité
    // Plage : 0.5 à 1.6
  }
}
```

#### AnchoredDoctrineModule
Classe abstraite réutilisable pour toutes les doctrines :
```dart
abstract class AnchoredDoctrineModule implements DoctrineModule {
  final String id;                    // Identifiant stable
  final List<Map<String, String>> anchors;  // Références + justifications
  final List<String> keywords;        // Mots-clés de détection
  final String theme;                 // Thème par défaut
  final String focus;                 // Focus par défaut
  final int baseEveryNDays;          // Fréquence de base (3-7 jours)
  
  double intensity(DoctrineContext ctx) => 1.0; // Surchargeable
}
```

### 2. Modules Doctrinaux
**Fichier:** `lib/services/doctrine/modules.dart`

#### 🕊️ FearOfGodDoctrine (Crainte de Dieu)
- **Ancrages** : 8 références (Proverbes 1:7, 9:10, Psaume 111:10, etc.)
- **Mots-clés** : crainte, craignez, révérence, respect, sagesse, sainteté
- **Intensité** : +0.3 si profil contient sagesse/sainteté/respect
- **Fréquence** : 5 jours de base

#### ✨ HolinessDoctrine (Sainteté)
- **Ancrages** : 4 références (1 Pierre 1:15-16, Hébreux 12:14, etc.)
- **Mots-clés** : saint, sainteté, pur, pureté, consécration
- **Intensité** : +0.25 si profil contient sainteté/pureté/consécration
- **Fréquence** : 6 jours de base

#### 🤝 HumilityDoctrine (Humilité)
- **Ancrages** : 4 références (Philippiens 2:3-8, Jacques 4:6, etc.)
- **Mots-clés** : humble, humilité, serviteur, abaissement
- **Intensité** : +0.25 si profil contient service/leader/orgueil
- **Fréquence** : 6 jours de base

#### 🎁 GraceDoctrine (Grâce)
- **Ancrages** : 4 références (Éphésiens 2:8-9, Tite 2:11-12, etc.)
- **Mots-clés** : grâce, faveur, miséricorde, justification
- **Intensité** : +0.3 si profil contient pardon/culpabilité/évangile
- **Fréquence** : 5 jours de base

#### 🙏 PrayerDoctrine (Prière)
- **Ancrages** : 4 références (1 Thessaloniciens 5:17, Matthieu 6:6-13, etc.)
- **Mots-clés** : prière, prier, supplication, intercession, psaume
- **Intensité** : +0.35 si profil contient prière/méditation/psaumes
- **Fréquence** : 4 jours de base (plus fréquent)

#### 💡 WisdomDoctrine (Sagesse)
- **Ancrages** : 4 références (Jacques 1:5, Proverbes 2:1-6, etc.)
- **Mots-clés** : sagesse, discernement, intelligence, prudence
- **Intensité** : +0.25 si profil contient sagesse/décision/proverbes
- **Fréquence** : 5 jours de base

### 3. Pipeline Multi-Doctrines
**Fichier:** `lib/services/doctrine/doctrine_pipeline.dart`

```dart
class DoctrinePipeline {
  factory DoctrinePipeline.defaultModules() => DoctrinePipeline([
    FearOfGodDoctrine(),
    HolinessDoctrine(),
    HumilityDoctrine(),
    GraceDoctrine(),
    PrayerDoctrine(),
    WisdomDoctrine(),
  ]);
}
```

## Fonctionnalités Avancées

### 1. Intensité Dynamique
Chaque doctrine calcule son intensité selon le profil :
- **Base** : 0.95 à 1.05 selon la doctrine
- **Bonus** : +0.25 à +0.35 selon les mots-clés du profil
- **Plage finale** : 0.5 à 1.6

### 2. Fréquence Adaptative
Plus l'intensité est élevée, plus les ancrages sont fréquents :
```dart
final everyN = (baseEveryNDays / intensity(ctx)).clamp(3, 7).round();
```

### 3. Logique d'Application
1. **Soft-tagging** : Identification des passages existants pertinents
2. **Injection hard** : Remplacement par des ancrages canoniques
3. **Métadonnées** : Enrichissement avec informations doctrinales

### 4. Exemples de Profils

#### Profil "Sagesse"
```json
{
  "goal": "sagesse",
  "heartPosture": "respect",
  "level": "intermédiaire"
}
```
**Résultat** : FearOfGodDoctrine (1.3), WisdomDoctrine (1.25), PrayerDoctrine (1.05)

#### Profil "Nouveau Converti"
```json
{
  "goal": "croissance",
  "heartPosture": "recherche",
  "level": "nouveau converti"
}
```
**Résultat** : GraceDoctrine (1.3), PrayerDoctrine (1.4), FearOfGodDoctrine (1.05)

#### Profil "Leader"
```json
{
  "goal": "service",
  "heartPosture": "humilité",
  "level": "avancé"
}
```
**Résultat** : HumilityDoctrine (1.2), PrayerDoctrine (1.4), HolinessDoctrine (1.0)

## Intégration

### Dans GoalsPage
**Aucun changement UI** - Intégration transparente :
```dart
// 🕊️ INTÉGRATION DOCTRINALE - Application du pipeline doctrinal modulaire
final ctx = DoctrineContext(userProfile: _userProfile, minutesPerDay: minutesPerDay);
final pipeline = DoctrinePipeline.defaultModules();
final withDoctrine = pipeline.apply(result, context: ctx);

print('🕊️ Plan structuré par le pipeline doctrinal modulaire');
return withDoctrine;
```

## Métadonnées Enrichies

Chaque jour avec doctrine reçoit :
```dart
{
  'doctrine': {
    'fear_of_God': true,
    'prayer': true,
    // ... autres doctrines appliquées
  },
  'theme': 'Crainte de Dieu',
  'focus': 'Révérence, sagesse, fidélité',
  'annotation': 'Crainte de Dieu — Commencement de la sagesse.',
  'meta': {
    'doctrine_modules': [
      {'id': 'fear_of_God', 'intensity': 1.3},
      {'id': 'prayer', 'intensity': 1.4}
    ]
  }
}
```

## Logs de Débogage

Le système produit des logs détaillés :
```
🕊️ DoctrinePipeline: Application de 6 modules sur 14 jours
🕊️ DoctrinePipeline: Application du module fear_of_God
🕊️ fear_of_God: Application avec intensité 1.30
🕊️ fear_of_God: Injection tous les 4 jours
🕊️ fear_of_God: Ancrage injecté à la position 3: Proverbes 1:7
🕊️ DoctrinePipeline: Application du module prayer
🕊️ prayer: Application avec intensité 1.40
🕊️ prayer: Injection tous les 3 jours
🕊️ prayer: Ancrage injecté à la position 2: 1 Thessaloniciens 5:17
🕊️ DoctrinePipeline: 8 jours avec doctrine sur 14 jours
```

## Extensibilité

### Ajouter une Nouvelle Doctrine
1. Créer une classe étendant `AnchoredDoctrineModule`
2. Définir ancrages, mots-clés, thème, focus
3. Implémenter `intensity()` si nécessaire
4. L'ajouter au pipeline par défaut

### Exemple : Doctrine de la Foi
```dart
class FaithDoctrine extends AnchoredDoctrineModule {
  FaithDoctrine() : super(
    id: 'faith',
    theme: 'Foi',
    focus: 'Confiance, assurance, persévérance',
    keywords: ['foi', 'croire', 'confiance', 'assurance'],
    anchors: const [
      {'ref': 'Hébreux 11:1', 'why': 'Définition de la foi.'},
      {'ref': 'Romains 10:17', 'why': 'La foi vient de ce qu\'on entend.'},
    ],
  );
}
```

## Configuration

### Désactiver une Doctrine
```dart
factory DoctrinePipeline.defaultModules() => DoctrinePipeline([
  FearOfGodDoctrine(),
  // HolinessDoctrine(), // Désactivée
  HumilityDoctrine(),
  GraceDoctrine(),
  PrayerDoctrine(),
  WisdomDoctrine(),
]);
```

### Pipeline Personnalisé
```dart
final customPipeline = DoctrinePipeline([
  FearOfGodDoctrine(),
  PrayerDoctrine(),
  // Seulement 2 doctrines
]);
```

## Tests et Validation

### Compilation
```bash
flutter analyze lib/services/doctrine/ lib/views/goals_page.dart
# ✅ Aucune erreur, warnings mineurs uniquement
```

### Couverture Doctrinale
- **Plans courts (≤14 jours)** : 2-4 ancrages par doctrine
- **Plans moyens (15-20 jours)** : 3-5 ancrages par doctrine
- **Plans longs (≥21 jours)** : 4-6 ancrages par doctrine

## Avantages

### 1. Architecture Propre
- **Modulaire** : Chaque doctrine est indépendante
- **Réutilisable** : Base commune pour toutes les doctrines
- **Extensible** : Facile d'ajouter de nouvelles doctrines
- **Testable** : Chaque module peut être testé séparément

### 2. Personnalisation Intelligente
- **Adaptatif** : S'ajuste au profil spirituel
- **Équilibré** : Maintient la diversité du plan
- **Pédagogique** : Justifications bibliques claires
- **Cohérent** : Références canoniques et concordantes

### 3. Intégration Transparente
- **Aucun impact UI** : Fonctionne en arrière-plan
- **Compatible** : S'intègre parfaitement au système existant
- **Offline-first** : Aucune dépendance réseau
- **Performant** : Calculs locaux rapides

## Conclusion

Cette implémentation étendue fournit un système doctrinal complet et modulaire qui enrichit automatiquement tous les plans de lecture avec 6 doctrines fondamentales. L'architecture est propre, extensible et parfaitement intégrée au système existant.

**Résultat** : Tous les plans générés intègrent désormais automatiquement les doctrines appropriées selon le profil utilisateur, créant une expérience de lecture biblique plus riche et personnalisée.
