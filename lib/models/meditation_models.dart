enum MeditationMode { decouverte, quotidien } // Option 1 vs Option 2

class MedQuestion {
  final String id;            // stable pour sauver les réponses plus tard
  final String section;       // sous-titre/étape
  final String prompt;        // question affichée
  const MedQuestion(this.id, this.section, this.prompt);
}

// OPTION 1 : Processus de Découverte (Demander → Chercher → Frapper)
const decouverteQuestions = <MedQuestion>[
  // Étape 1 — Demander
  MedQuestion('D1a', 'Demander', "Quels sont les personnages du texte ?"),
  MedQuestion('D1b', 'Demander', "Quelles sont les actions effectuées ?"),
  MedQuestion('D1c', 'Demander', "Quels sont les détails particuliers ?"),
  // Étape 2 — Chercher
  MedQuestion('D2a', 'Chercher', "Quelles seraient les émotions des personnages ?"),
  MedQuestion('D2b', 'Chercher', "Quels sont les choix et les alternatives ?"),
  MedQuestion('D2c', 'Chercher', "Quelles sont les raisons de ces choix ?"),
  // Étape 3 — Frapper
  MedQuestion('D3a', 'Frapper', "Quelles sont les bonnes actions ?"),
  MedQuestion('D3b', 'Frapper', "Que m'enseigne ce texte sur Dieu ?"),
  MedQuestion('D3c', 'Frapper', "Que m'enseigne ce texte pour mon prochain ?"),
];

// OPTION 2 : Méthode quotidienne (questions générales)
const quotidienQuestions = <MedQuestion>[
  MedQuestion('Q1', 'Observation', "De quoi / de qui parlent ces versets ?"),
  MedQuestion('Q2', 'Dieu', "Ce passage m'apprend-il quelque chose sur Dieu ?"),
  MedQuestion('Q3', 'Exemple', "Y a-t-il un exemple à suivre / à éviter ?"),
  MedQuestion('Q4', 'Obéissance', "Y a-t-il un ordre auquel obéir ?"),
  MedQuestion('Q5', 'Promesse', "Y a-t-il une promesse ?"),
  MedQuestion('Q6', 'Avertissement', "Y a-t-il un avertissement ?"),
  MedQuestion('Q7', 'Vérité', "Quelle vérité Dieu me révèle-t-il ?"),
  MedQuestion('Q8', 'Références', "D'autres passages m'aident-ils à comprendre ?"),
  // "Chaque jour, demandez-vous"
  MedQuestion('Q9a', 'Verset-clé', "Quel verset me frappe le plus ?"),
  MedQuestion('Q9b', 'Prière', "Ai-je à me repentir ? à croire / obéir ? À remercier ? À demander ?"),
];

// Système de rotation pour les questions quotidiennes
List<List<String>> rotationSets = [
  ['Q1','Q2','Q9a','Q9b'],                 // léger
  ['Q1','Q3','Q4','Q9a','Q9b'],
  ['Q2','Q5','Q7','Q9a','Q9b'],
  ['Q1','Q6','Q7','Q8','Q9a'],
];

List<MedQuestion> quotidienDuJour(DateTime date) {
  final idx = date.difference(DateTime(2025,1,1)).inDays.abs() % rotationSets.length;
  final wanted = rotationSets[idx].toSet();
  return quotidienQuestions.where((q) => wanted.contains(q.id)).toList();
}
