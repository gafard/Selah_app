import '../services/prayer_subjects_builder.dart';

/// Exemple d'utilisation de PrayerSubjectsBuilder avec la nouvelle structure
class PrayerSubjectsUsageExample {
  
  /// Exemple d'utilisation avec des tags sélectionnés par champ
  static void exampleWithSelectedTags() {
    final subjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: {
        'aboutGod': {'praise', 'trust'}, // Tags sélectionnés pour le champ "aboutGod"
        'neighbor': {'intercession'},    // Tags sélectionnés pour le champ "neighbor"
        'applyToday': {'obedience'},     // Tags sélectionnés pour le champ "applyToday"
        'verseHit': {'promise'},         // Tags sélectionnés pour le verset
      },
    );
    
    print('Sujets générés à partir des tags:');
    for (final subject in subjects) {
      print('- ${subject.label} (${subject.category})');
    }
  }
  
  /// Exemple d'utilisation avec des textes libres
  static void exampleWithFreeTexts() {
    final subjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: {}, // Pas de tags
      freeTexts: {
        'aboutGod': 'Dieu est amour et fidèle',
        'neighbor': 'Mes collègues de travail',
        'applyToday': 'Être plus patient avec mes enfants',
        'verseHit': 'Jean 3:16 - Car Dieu a tant aimé le monde...',
      },
    );
    
    print('\nSujets générés à partir des textes libres:');
    for (final subject in subjects) {
      print('- ${subject.label} (${subject.category})');
    }
  }
  
  /// Exemple d'utilisation mixte (tags + textes libres)
  static void exampleMixed() {
    final subjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: {
        'aboutGod': {'praise', 'gratitude'},
        'applyToday': {'obedience'},
      },
      freeTexts: {
        'neighbor': 'Ma famille et mes amis',
        'verseHit': 'Psaume 23 - L\'Éternel est mon berger...',
      },
    );
    
    print('\nSujets générés (mixte):');
    for (final subject in subjects) {
      print('- ${subject.label} (${subject.category})');
    }
  }
  
  /// Exemple d'utilisation avec QCM
  static void exampleWithQcm() {
    // Simuler des tags sélectionnés depuis un QCM
    final selectedTags = ['gratitude', 'repentance', 'intercession', 'praise'];
    
    final subjects = PrayerSubjectsBuilder.fromQcm(
      selectedOptionTags: selectedTags,
    );
    
    print('\nSujets générés à partir du QCM:');
    for (final subject in subjects) {
      print('- ${subject.label} (${subject.category})');
    }
  }
  
  /// Exécuter tous les exemples
  static void runAllExamples() {
    print('=== EXEMPLES D\'UTILISATION PrayerSubjectsBuilder ===\n');
    
    exampleWithSelectedTags();
    exampleWithFreeTexts();
    exampleMixed();
    exampleWithQcm();
    
    print('\n=== FIN DES EXEMPLES ===');
  }
}

/// Fonction main pour tester les exemples
void main() {
  PrayerSubjectsUsageExample.runAllExamples();
}
