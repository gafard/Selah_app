# 🕊️ Doctrine Pipeline Modulaire - Implémentation Complète

## Vue d'ensemble

Implémentation d'un système doctrinal modulaire et extensible qui infuse la doctrine "Crainte de Dieu" dans tous les plans de lecture générés, avec une architecture propre et 100% offline-first.

## Architecture

### 1. DoctrineContext
**Fichier:** `lib/services/doctrine/fear_of_god_doctrine.dart`

Classe qui encapsule le contexte d'application des doctrines :
- **userProfile**: Profil utilisateur complet
- **minutesPerDay**: Durée de lecture quotidienne
- **intensity**: Intensité calculée dynamiquement (0.5-1.5) basée sur le profil

```dart
class DoctrineContext {
  final Map<String, dynamic>? userProfile;
  final int minutesPerDay;
  
  double get intensity {
    // Calcul intelligent basé sur goal, heartPosture, level
    // Plus de sagesse/sainteté → plus d'intensité
  }
}
```

### 2. DoctrineModule (Interface)
**Fichier:** `lib/services/doctrine/fear_of_god_doctrine.dart`

Interface abstraite pour tous les modules doctrinaux :
```dart
abstract class DoctrineModule {
  String get id;
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> plan, DoctrineContext ctx);
}
```

### 3. FearOfGodDoctrine (Implémentation)
**Fichier:** `lib/services/doctrine/fear_of_god_doctrine.dart`

Module concret pour la doctrine "Crainte de Dieu" :

#### Ancrages canoniques
10 références bibliques clés avec justifications pédagogiques :
- **Proverbes 1:7** - "La crainte de l'Éternel fonde toute sagesse"
- **Proverbes 9:10** - "Sagesse et connaissance viennent de la crainte de Dieu"
- **Psaume 111:10** - "La crainte de l'Éternel rend la pensée saine"
- **Psaume 34:9-10** - "Protection et provision pour ceux qui le craignent"
- **Proverbes 19:23** - "La crainte de l'Éternel mène à la vie"
- **Exode 20:20** - "La crainte détourne du péché"
- **Ecclésiaste 12:13** - "Craindre Dieu et garder ses commandements"
- **Deutéronome 10:12** - "Aimer/servir Dieu avec tout son cœur"
- **Hébreux 12:28** - "Rendre un culte avec piété et crainte"
- **1 Pierre 1:17** - "Se conduire avec crainte durant le séjour terrestre"

#### Mots-clés de détection
Détection automatique des passages existants pertinents :
```dart
static const _keywords = [
  'crainte', 'craignez', 'révérence', 'respect', 'sagesse', 'sainteté',
];
```

#### Logique d'application
1. **Tagging soft** : Identification des passages existants pertinents
2. **Injection hard** : Remplacement de passages par des ancrages canoniques
3. **Fréquence adaptative** : `everyN = (5 / intensity).clamp(3, 7)`
4. **Garantie minimale** : Au moins 2-4 ancrages selon la durée du plan

### 4. DoctrinePipeline
**Fichier:** `lib/services/doctrine/doctrine_pipeline.dart`

Pipeline modulaire qui applique tous les modules doctrinaux :
```dart
class DoctrinePipeline {
  final List<DoctrineModule> modules;
  
  factory DoctrinePipeline.defaultModules() =>
      DoctrinePipeline([FearOfGodDoctrine()]);
      
  List<Map<String, dynamic>> apply(
    List<Map<String, dynamic>> plan, {
    required DoctrineContext context,
  });
}
```

## Intégration

### Dans GoalsPage
**Fichier:** `lib/views/goals_page.dart`

Intégration transparente dans `_generateOfflinePassagesForPreset` :

```dart
// 🕊️ INTÉGRATION DOCTRINALE - Application du pipeline doctrinal modulaire
final ctx = DoctrineContext(userProfile: _userProfile, minutesPerDay: minutesPerDay);
final pipeline = DoctrinePipeline.defaultModules();
final withDoctrine = pipeline.apply(result, context: ctx);

print('🕊️ Plan structuré par le pipeline doctrinal modulaire');
return withDoctrine;
```

## Fonctionnalités

### 1. Intensité dynamique
L'intensité de la doctrine s'adapte au profil utilisateur :
- **Goal "sagesse"** → +0.25
- **Heart "respect/révérence"** → +0.2  
- **Level "nouveau converti"** → +0.05
- **Plage finale** : 0.5 à 1.5

### 2. Fréquence adaptative
Plus l'intensité est élevée, plus les ancrages sont fréquents :
- **Intensité 1.0** → 1 ancrage tous les 5 jours
- **Intensité 1.5** → 1 ancrage tous les 3 jours
- **Intensité 0.5** → 1 ancrage tous les 7 jours

### 3. Métadonnées enrichies
Chaque jour avec doctrine reçoit :
```dart
{
  'doctrine': {'fear_of_God': true},
  'theme': 'Crainte de Dieu',
  'focus': 'Sagesse, révérence, fidélité',
  'annotation': 'Doctrine – Crainte de Dieu : [raison pédagogique]',
  'meta': {
    'doctrine_modules': [
      {'id': 'fear_of_God', 'intensity': 1.25}
    ]
  }
}
```

### 4. Garantie de couverture
- **Plans courts (≤14 jours)** : Minimum 2 ancrages
- **Plans moyens (15-20 jours)** : Minimum 3 ancrages  
- **Plans longs (≥21 jours)** : Minimum 4 ancrages

## Avantages

### 1. Architecture modulaire
- **Extensible** : Facile d'ajouter de nouvelles doctrines
- **Maintenable** : Code séparé et bien structuré
- **Testable** : Chaque module peut être testé indépendamment

### 2. Intégration transparente
- **Aucun impact UI** : Fonctionne en arrière-plan
- **Compatible** : S'intègre parfaitement au système existant
- **Offline-first** : Aucune dépendance réseau

### 3. Personnalisation intelligente
- **Adaptatif** : S'ajuste au profil spirituel
- **Pédagogique** : Justifications bibliques claires
- **Équilibré** : Maintient la diversité du plan

## Extensibilité

### Ajouter une nouvelle doctrine
1. Créer une nouvelle classe implémentant `DoctrineModule`
2. Ajouter des ancrages canoniques spécifiques
3. Implémenter la logique d'application
4. L'ajouter au pipeline par défaut

### Exemple : Doctrine de la Grâce
```dart
class GraceDoctrine implements DoctrineModule {
  @override
  String get id => 'grace';
  
  static const List<Map<String, String>> _anchors = [
    {'ref': 'Éphésiens 2:8-9', 'why': 'Salut par grâce, non par les œuvres'},
    {'ref': 'Romains 3:23-24', 'why': 'Tous ont péché, tous sont justifiés gratuitement'},
    // ...
  ];
  
  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> plan, DoctrineContext ctx) {
    // Logique spécifique à la grâce
  }
}
```

## Tests et validation

### Compilation
```bash
flutter analyze lib/services/doctrine/ lib/views/goals_page.dart
# ✅ Aucune erreur, quelques warnings mineurs (print statements)
```

### Logs de débogage
Le système produit des logs détaillés :
```
🕊️ FearOfGodDoctrine: Application avec intensité 1.25
🕊️ FearOfGodDoctrine: Injection tous les 4 jours
🕊️ Ancrage injecté à la position 3: Proverbes 1:7
🕊️ Ancrage injecté à la position 7: Proverbes 9:10
🕊️ FearOfGodDoctrine: 3 ancrages injectés sur 14 jours
🕊️ DoctrinePipeline: 3 jours avec doctrine sur 14 jours
```

## Conclusion

Cette implémentation fournit une base solide et extensible pour l'infusion doctrinale dans les plans de lecture. Elle respecte les principes d'architecture propre, d'offline-first, et de personnalisation intelligente, tout en restant parfaitement intégrée au système existant.

**Prochaines étapes possibles :**
- Ajout d'autres doctrines (Grâce, Foi, Sainteté)
- Interface utilisateur pour configurer les doctrines
- Analytics sur l'impact des doctrines
- Tests unitaires complets
