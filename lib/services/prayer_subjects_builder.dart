
class PrayerSubject {
  final String label;
  final String category; // gratitude, repentance, ...
  PrayerSubject(this.label, this.category);
}

class PrayerSubjectsBuilder {
  static final Map<String, List<String>> _catalog = {
    'gratitude': ['Remercier pour la grâce reçue', 'Remercier pour les personnes autour de moi'],
    'repentance': ['Reconnaître une faute et demander un cœur pur'],
    'obedience': ['Mettre en pratique une action concrète aujourd\'hui'],
    'promise': ['S\'approprier une promesse lue et s\'y appuyer'],
    'intercession': ['Prier pour un proche', 'Prier pour l\'Église / la ville'],
    'praise': ['Adorer Dieu pour son caractère révélé'],
    'trust': ['Demander paix et confiance'],
    'guidance': ['Demander sagesse pour une décision'],
    'warning': ['Prendre au sérieux un avertissement / établir un garde-fou'],
  };

  static List<PrayerSubject> fromQcm({required List<String> selectedOptionTags}) {
    final out = <PrayerSubject>[];
    for (final tag in selectedOptionTags.toSet()) {
      final bucket = _catalog[tag];
      if (bucket != null) {
        out.addAll(bucket.map((s) => PrayerSubject(s, tag)));
      }
    }
    return out;
  }

  static List<PrayerSubject> fromFree({
    required Map<String, Set<String>> selectedTagsByField,
    Map<String, String>? freeTexts,
  }) {
    final subjects = <PrayerSubject>[];
    
    // Traiter les tags sélectionnés par champ
    for (final entry in selectedTagsByField.entries) {
      final tags = entry.value;
      
      for (final tag in tags) {
        final bucket = _catalog[tag];
        if (bucket != null) {
          subjects.addAll(bucket.map((s) => PrayerSubject(s, tag)));
        }
      }
    }
    
    // Traiter les textes libres si fournis
    if (freeTexts != null) {
      for (final entry in freeTexts.entries) {
        final field = entry.key;
        final text = entry.value.trim();
        
        if (text.isNotEmpty) {
          switch (field) {
            case 'aboutGod':
              subjects.add(PrayerSubject('Méditer sur ce que Dieu m\'enseigne : "$text"', 'praise'));
              subjects.add(PrayerSubject('Remercier Dieu pour cette révélation', 'gratitude'));
              break;
            case 'neighbor':
              subjects.add(PrayerSubject('Prier pour mes prochains concernant : "$text"', 'intercession'));
              subjects.add(PrayerSubject('Demander l\'amour pour servir : "$text"', 'obedience'));
              break;
            case 'applyToday':
              subjects.add(PrayerSubject('Demander la grâce d\'appliquer : "$text"', 'obedience'));
              subjects.add(PrayerSubject('Prier pour la persévérance dans : "$text"', 'trust'));
              break;
            case 'verseHit':
              subjects.add(PrayerSubject('Méditer sur le verset : "$text"', 'praise'));
              subjects.add(PrayerSubject('S\'approprier cette parole de Dieu', 'promise'));
              break;
            default:
              subjects.add(PrayerSubject('Méditer sur : "$text"', 'other'));
              break;
          }
        }
      }
    }
    
    // Si aucun sujet n'a été généré, ajouter des sujets par défaut
    if (subjects.isEmpty) {
      subjects.addAll([
        PrayerSubject('Remercier Dieu pour sa fidélité', 'gratitude'),
        PrayerSubject('Demander la sagesse pour la journée', 'guidance'),
        PrayerSubject('Prier pour mes prochains', 'intercession'),
        PrayerSubject('Confier mes préoccupations à Dieu', 'trust'),
      ]);
    }
    
    return subjects;
  }
}
