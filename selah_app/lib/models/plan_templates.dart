/// Modèles de plans standards pour CustomPlanGeneratorPage
class PlanTemplate {
  final String id;
  final String title;
  final int days;
  final List<String> books;
  final String description;

  const PlanTemplate({
    required this.id,
    required this.title,
    required this.days,
    required this.books,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'days': days,
      'books': books,
      'description': description,
    };
  }

  factory PlanTemplate.fromMap(Map<String, dynamic> map) {
    return PlanTemplate(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      days: map['days'] ?? 0,
      books: List<String>.from(map['books'] ?? []),
      description: map['description'] ?? '',
    );
  }
}

/// Liste des plans standards disponibles
const kPlanTemplates = <PlanTemplate>[
  PlanTemplate(
    id: 'NT60',
    title: 'Nouveau Testament en 60 jours',
    days: 60,
    description: 'Découvre le Nouveau Testament en 60 jours avec une lecture quotidienne équilibrée.',
    books: [
      'Matthieu', 'Marc', 'Luc', 'Jean',
      'Actes',
      'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens', 'Philippiens', 'Colossiens',
      '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée', '2 Timothée', 'Tite', 'Philémon',
      'Hébreux',
      'Jacques',
      '1 Pierre', '2 Pierre',
      '1 Jean', '2 Jean', '3 Jean',
      'Jude',
      'Apocalypse',
    ],
  ),
  PlanTemplate(
    id: 'BIBLE300',
    title: 'Toute la Bible en 300 jours',
    days: 300,
    description: 'Un parcours complet de toute la Bible en 300 jours, de la Genèse à l\'Apocalypse.',
    books: [
      // Ancien Testament
      'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
      'Josué', 'Juges', 'Ruth',
      '1 Samuel', '2 Samuel', '1 Rois', '2 Rois',
      '1 Chroniques', '2 Chroniques',
      'Esdras', 'Néhémie', 'Esther',
      'Job', 'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique des Cantiques',
      'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel',
      'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas', 'Michée', 'Nahum', 'Habacuc', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie',
      // Nouveau Testament
      'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
      'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens', 'Philippiens', 'Colossiens',
      '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée', '2 Timothée', 'Tite', 'Philémon',
      'Hébreux', 'Jacques', '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean', 'Jude', 'Apocalypse',
    ],
  ),
  PlanTemplate(
    id: 'PS-PR60',
    title: 'Psaumes & Proverbes en 60 jours',
    days: 60,
    description: 'Médite les Psaumes et les Proverbes pour nourrir ta sagesse et ta louange.',
    books: ['Psaumes', 'Proverbes'],
  ),
  PlanTemplate(
    id: 'EVANG30',
    title: 'Évangiles en 30 jours',
    days: 30,
    description: 'Découvre la vie et l\'enseignement de Jésus à travers les quatre Évangiles.',
    books: ['Matthieu', 'Marc', 'Luc', 'Jean'],
  ),
  PlanTemplate(
    id: 'EPISTRES60',
    title: 'Épîtres en 60 jours',
    days: 60,
    description: 'Explore les lettres des apôtres et approfondis ta compréhension de la foi chrétienne.',
    books: [
      'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens', 'Philippiens', 'Colossiens',
      '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée', '2 Timothée', 'Tite', 'Philémon',
      'Hébreux', 'Jacques', '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean', 'Jude'
    ],
  ),
];


