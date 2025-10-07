# 🧠 Guide d'intégration - Générateur de Prières Intelligentes

## 📋 Vue d'ensemble

Le générateur de prières intelligentes enrichit ton système existant `PrayerSubjectsBuilder` en ajoutant :
- **Adaptation émotionnelle** selon le niveau spirituel
- **Cohérence thématique** avec les objectifs utilisateur
- **Ancrage biblique** avec versets appropriés
- **Sens saisonnier** (Avent, Carême, etc.)
- **Équilibre ACTS** (Adoration, Confession, Thanks, Supplication)

## 🔗 Intégration avec ton code existant

### 1. Remplacement simple dans une page existante

```dart
// AVANT (ton code actuel)
final prayerSubjects = PrayerSubjectsBuilder.fromFree(
  selectedTagsByField: selectedAnswersByField,
  freeTexts: freeTexts,
);

// APRÈS (avec enrichissement intelligent)
final ctx = PrayerContext.fromMeditation(
  userProfile: userProfile, // depuis UserPrefs.getProfile()
  passageText: currentPassageText,
  passageRef: currentPassageRef,
  answers: selectedAnswersByField,
  detectedThemes: MeditationAnalyzer.extractThemes(passageText, answers),
);

final ideas = IntelligentPrayerGenerator.generate(ctx);
final prayerItems = ideas.map((idea) => idea.toPrayerItem()).toList();
```

### 2. Intégration dans PrayerCarouselPage

```dart
// Dans ta PrayerCarouselPage
class _PrayerCarouselPageState extends State<PrayerCarouselPage> {
  
  Future<void> _generatePrayerIdeas() async {
    // Récupérer le profil utilisateur
    final userProfile = await UserPrefs.getProfile();
    
    // Créer le contexte intelligent
    final ctx = PrayerContext.fromMeditation(
      userProfile: userProfile,
      passageText: widget.passageText,
      passageRef: widget.passageRef,
      answers: _selectedAnswersByField,
      detectedThemes: _extractThemes(widget.passageText),
    );
    
    // Générer les prières enrichies
    final ideas = IntelligentPrayerGenerator.generate(ctx);
    
    // Convertir vers ton format UI existant
    setState(() {
      _prayerItems = ideas.map((idea) => PrayerItem(
        theme: idea.tags.join(' · ').toUpperCase(),
        subject: idea.title,
        description: idea.body,
        verseRef: idea.verseRef,
        emotion: idea.emotion,
        validated: false,
        notes: '',
      )).toList();
    });
  }
}
```

### 3. Persistance enrichie dans Supabase

```dart
// Quand tu sauvegardes les tâches de prière
Future<void> _savePrayerTasks(List<PrayerIdea> ideas, String dayId) async {
  for (int i = 0; i < ideas.length; i++) {
    final idea = ideas[i];
    
    await supabase.from('plan_tasks').insert({
      'plan_day_id': dayId,
      'task_type': 'prayer',
      'title': idea.title,
      'description': idea.body,
      'metadata': idea.metadata, // Traçabilité complète
      'order_index': i,
    });
  }
}
```

## 🎯 Profils émotionnels par niveau

| Niveau | Émotions prioritaires | Équilibre ACTS |
|--------|----------------------|----------------|
| **Nouveau converti** | Joie, gratitude, partage | +30% reconnaissance, -20% confession |
| **Rétrograde** | Repentance, retour, restauration | +40% confession, +20% reconnaissance |
| **Fidèle pas si régulier** | Motivation, discipline, résolution | +30% intercession, équilibre modéré |
| **Serviteur/leader** | Responsabilité, fardeau, vision | +40% intercession, +20% confession |
| **Fidèle régulier** | Persévérance, fidélité, contentement | Équilibre parfait ACTS |

## 🌱 Adaptation saisonnière

```dart
// Le générateur détecte automatiquement la saison
final season = SeasonDetector.detect(); // 'advent', 'lent', 'easter', 'ordinary'

// Et adapte les prières en conséquence
if (season == 'lent') {
  // +40% bonus pour les prières de confession
  // Versets sur le pardon et la repentance
}
```

## 📊 Métadonnées de traçabilité

Chaque prière générée contient :

```dart
{
  'source': 'intelligent_prayer_v2',
  'theme': 'prayer_life',
  'season': 'ordinary',
  'emotion': 'joy',
  'userLevel': 'Fidèle régulier',
  'userGoal': 'Discipline de prière',
  'passageRef': 'Matthieu 6:9-13',
  'timestamp': '2024-01-15T10:30:00Z',
  'originalCategory': 'gratitude',
}
```

## 🧪 Tests et validation

```dart
// Lancer les tests d'intégration
await PrayerIntegrationTest.runTests();

// Voir la démonstration
await IntelligentPrayerIntegrationExample.demonstrateIntegration();
```

## 🚀 Avantages immédiats

1. **Cohérence** : Les prières correspondent au profil spirituel
2. **Personnalisation** : Adaptation émotionnelle et thématique
3. **Équilibre** : Structure ACTS respectée automatiquement
4. **Traçabilité** : Métadonnées complètes pour l'amélioration
5. **Évolutivité** : Facile d'ajouter de nouveaux enrichissements

## 🔧 Personnalisation avancée

### Ajouter de nouveaux thèmes

```dart
// Dans IntelligentLocalPresetGenerator
static const Map<String, Map<String, dynamic>> _spiritualThemes = {
  'nouveau_theme': {
    'focus': 'Nouvelle orientation spirituelle',
    'verses': ['Nouveau 1:1', 'Testament 2:2'],
    'emotions': ['nouvelle_emotion'],
    'targetAudience': ['Nouveau converti', 'Fidèle régulier'],
  },
};
```

### Modifier les profils émotionnels

```dart
// Dans EmotionProfiles.forLevel()
case 'nouveau_niveau':
  return EmotionProfile('Nouveau niveau', {
    'adoration': 'nouvelle_emotion',
    'confession': 'autre_emotion',
    // ...
  }, {
    'adoration': 1.2, // Poids personnalisé
    'confession': 0.8,
    // ...
  });
```

## 📈 Métriques et amélioration continue

Le système collecte automatiquement :
- **Scores de pertinence** par profil utilisateur
- **Équilibre ACTS** effectif vs. théorique
- **Utilisation des versets** d'ancrage
- **Satisfaction émotionnelle** par saison

Ces données permettent d'ajuster les algorithmes et d'améliorer les recommandations.

## 🎯 Prochaines étapes recommandées

1. **Intégrer dans PrayerCarouselPage** (priorité haute)
2. **Tester avec différents profils** utilisateur
3. **Ajuster les poids** selon les retours
4. **Enrichir la base** de versets d'ancrage
5. **Ajouter des thèmes** saisonniers spécifiques

---

*Ce générateur respecte ton architecture existante tout en apportant une intelligence contextuelle et émotionnelle à la génération de prières.*
