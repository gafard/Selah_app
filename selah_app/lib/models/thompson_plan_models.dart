/// Modèles pour le générateur de plans basé sur la Bible d'étude Thompson 21
/// Utilise les chaînes thématiques, encarts et portraits de la Thompson 21 Sélection
library;

class CompleteProfile {
  final String language;                 // 'fr', 'en', …
  final int minutesPerDay;               // 5, 10, 20…
  final int daysPerWeek;                 // 3..7
  final List<String> goals;              // ['discipline','anxiety','marriage','community','prayer']
  final String experience;               // 'new' | 'growing' | 'mature'
  final bool prefersThemes;              // true => chaînes Thompson, false => parcours livre
  final bool hasPhysicalBible;           // enforce physical Bible
  final DateTime startDate;

  const CompleteProfile({
    required this.language,
    required this.minutesPerDay,
    required this.daysPerWeek,
    required this.goals,
    required this.experience,
    required this.prefersThemes,
    required this.hasPhysicalBible,
    required this.startDate,
  });

  /// Crée un CompleteProfile depuis les préférences utilisateur
  factory CompleteProfile.fromUserPrefs(Map<String, dynamic> prefs) {
    return CompleteProfile(
      language: prefs['language'] as String? ?? 'fr',
      minutesPerDay: prefs['minutesPerDay'] as int? ?? 15,
      daysPerWeek: prefs['daysPerWeek'] as int? ?? 6,
      goals: (prefs['goals'] as List<dynamic>?)?.cast<String>() ?? ['discipline'],
      experience: prefs['experience'] as String? ?? 'new',
      prefersThemes: prefs['prefersThemes'] as bool? ?? true,
      hasPhysicalBible: prefs['hasPhysicalBible'] as bool? ?? true,
      startDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'minutesPerDay': minutesPerDay,
      'daysPerWeek': daysPerWeek,
      'goals': goals,
      'experience': experience,
      'prefersThemes': prefersThemes,
      'hasPhysicalBible': hasPhysicalBible,
      'startDate': startDate.toIso8601String(),
    };
  }
}

class ThompsonPlanPreset {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final int durationDays;
  final List<ThompsonPlanDay> days;
  final Map<String, dynamic> meta; // e.g., theme, coverImage, source='Thompson21'

  ThompsonPlanPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.durationDays,
    required this.days,
    required this.meta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'durationDays': durationDays,
      'days': days.map((d) => d.toMap()).toList(),
      'meta': meta,
    };
  }

  factory ThompsonPlanPreset.fromMap(Map<String, dynamic> map) {
    return ThompsonPlanPreset(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      durationDays: map['durationDays'] as int,
      days: (map['days'] as List<dynamic>)
          .map((d) => ThompsonPlanDay.fromMap(d as Map<String, dynamic>))
          .toList(),
      meta: Map<String, dynamic>.from(map['meta'] as Map<String, dynamic>),
    );
  }
}

class ThompsonPlanDay {
  final DateTime date;
  final List<ThompsonPlanTask> tasks;
  
  ThompsonPlanDay({required this.date, required this.tasks});

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
    };
  }

  factory ThompsonPlanDay.fromMap(Map<String, dynamic> map) {
    return ThompsonPlanDay(
      date: DateTime.parse(map['date'] as String),
      tasks: (map['tasks'] as List<dynamic>)
          .map((t) => ThompsonPlanTask.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum ThompsonTaskKind { 
  prepare, 
  reading, 
  meditation, 
  prayer, 
  application, 
  memorize,
  selah,
  reflection
}

class ThompsonPlanTask {
  final ThompsonTaskKind kind;
  final String title;
  final String? passageRef; // e.g. 'Mt 6:25-34' (Segond 21 refs)
  final Map<String, dynamic>? payload;   // UI hints (timer, prompt, imageKey…)
  
  ThompsonPlanTask({
    required this.kind, 
    required this.title, 
    this.passageRef, 
    this.payload
  });

  Map<String, dynamic> toMap() {
    return {
      'kind': kind.name,
      'title': title,
      'passageRef': passageRef,
      'payload': payload,
    };
  }

  factory ThompsonPlanTask.fromMap(Map<String, dynamic> map) {
    return ThompsonPlanTask(
      kind: ThompsonTaskKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => ThompsonTaskKind.meditation,
      ),
      title: map['title'] as String,
      passageRef: map['passageRef'] as String?,
      payload: map['payload'] != null 
          ? Map<String, dynamic>.from(map['payload'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Thompson anchors (seeds) — extraites des pages citées du PDF Thompson 21 Sélection.
/// Chaque seed inclut une ancre et quelques refs de la mini-chaîne/encart pour construire un bloc.
class ChainSeed {
  final String key;               // logical key
  final String display;           // human name
  final List<String> refs;        // ordered refs (Segond 21 notation)
  final String description;       // description du thème
  final List<String> relatedGoals; // objectifs associés
  
  const ChainSeed(
    this.key, 
    this.display, 
    this.refs, 
    this.description,
    this.relatedGoals,
  );
}

// NB: ces listes proviennent des encarts/chaînes illustrés dans le doc
// (Compagnie p.15 ; Exigence spirituelle p.28 ; Erreurs courantes p.30 ; Inquiétude interdite Mt 6:25-34 p.31 ; Mariage/Epoux p.15).
const THOMPSON_SEEDS = <ChainSeed>[
  ChainSeed(
    'companionship', 
    'Compagnie', 
    ['Gn 2:18', 'Nb 10:31', 'Ec 4:9', 'Mt 26:37', 'Lc 10:1'],
    'Dieu nous a créés pour la communion et le compagnonnage. Ces passages montrent l\'importance de marcher ensemble dans la foi.',
    ['community', 'fellowship', 'relationships'],
  ),
  ChainSeed(
    'spiritual_demand', 
    'Exigence spirituelle', 
    ['Mt 5:20', 'Mt 18:3', 'Lc 13:2-3', 'Jn 3:5', 'Jn 4:24', 'Jn 8:24', 'Hé 12:14'],
    'Jésus exige une transformation profonde du cœur, pas seulement des apparences. Ces passages révèlent les exigences spirituelles du Royaume.',
    ['discipline', 'holiness', 'transformation'],
  ),
  ChainSeed(
    'common_errors', 
    'Erreurs courantes', 
    ['Gn 3:5-6', 'Mt 6:7', 'Mt 26:33', 'Lc 6:49', 'Lc 12:19', 'Ac 17:29', 'Jc 4:13-14'],
    'La Bible nous met en garde contre les pièges spirituels courants. Ces passages nous aident à identifier et éviter les erreurs typiques.',
    ['wisdom', 'discernment', 'avoiding_sin'],
  ),
  ChainSeed(
    'no_worry', 
    'Inquiétude interdite', 
    ['Mt 6:25-34'],
    'Jésus nous enseigne à ne pas nous inquiéter mais à faire confiance à la providence du Père. Un antidote puissant à l\'anxiété.',
    ['anxiety', 'peace', 'trust'],
  ),
  ChainSeed(
    'marriage_duties', 
    'Mariage & Epoux', 
    ['Gn 2:24', 'Dt 24:5', 'Pr 5:18-19', 'Ep 5:22-33', '1P 3:1-7'],
    'Le mariage est une alliance sacrée instituée par Dieu. Ces passages guident les couples dans leur marche commune.',
    ['marriage', 'relationships', 'covenant'],
  ),
  ChainSeed(
    'prayer_life',
    'Vie de prière',
    ['Mt 6:5-15', 'Lc 11:1-13', 'Ep 6:18', '1Th 5:17', 'Jc 5:13-16'],
    'La prière est le souffle de la vie spirituelle. Ces passages nous enseignent à prier selon le cœur de Dieu.',
    ['prayer', 'spiritual_life', 'communion'],
  ),
  ChainSeed(
    'forgiveness',
    'Pardon & Réconciliation',
    ['Mt 18:21-35', 'Lc 15:11-32', 'Ep 4:32', 'Col 3:13', '1Jn 1:9'],
    'Le pardon est au cœur de l\'Évangile. Ces passages nous montrent comment recevoir et donner le pardon.',
    ['forgiveness', 'healing', 'reconciliation'],
  ),
  ChainSeed(
    'faith_trials',
    'Épreuves & Foi',
    ['Jb 1:1-22', 'Ps 23', 'Rm 8:28', '2Co 4:7-18', 'Hé 11:1-40'],
    'Les épreuves font partie du chemin de foi. Ces passages nous encouragent à tenir ferme dans les difficultés.',
    ['trials', 'faith', 'perseverance'],
  ),
];

/// Profil utilisateur étendu pour la génération Thompson
class UserProfile {
  final String id;
  final String name;
  final String email;
  final CompleteProfile preferences;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic> stats; // statistiques d'usage

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.preferences,
    required this.createdAt,
    required this.lastActive,
    this.stats = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'preferences': preferences.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'stats': stats,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      preferences: CompleteProfile.fromUserPrefs(map['preferences'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastActive: DateTime.parse(map['lastActive'] as String),
      stats: Map<String, dynamic>.from(map['stats'] as Map<String, dynamic>? ?? {}),
    );
  }
}