import 'quiz_question.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MODELS POUR L'ANALYSE DE CONTENU ET L'HISTORIQUE DU PLAN
/// ═══════════════════════════════════════════════════════════════════════════

/// Analyse du contenu d'un passage biblique
class ContentAnalysis {
  final String passageRef;
  final String passageText;
  final List<String> characters;
  final List<String> themes;
  final List<String> events;
  final List<String> keywords;
  final Map<String, dynamic> semanticContext;
  final DateTime analyzedAt;

  ContentAnalysis({
    required this.passageRef,
    required this.passageText,
    required this.characters,
    required this.themes,
    required this.events,
    required this.keywords,
    required this.semanticContext,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'passageRef': passageRef,
      'passageText': passageText,
      'characters': characters,
      'themes': themes,
      'events': events,
      'keywords': keywords,
      'semanticContext': semanticContext,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory ContentAnalysis.fromJson(Map<String, dynamic> json) {
    return ContentAnalysis(
      passageRef: json['passageRef'] as String,
      passageText: json['passageText'] as String,
      characters: List<String>.from(json['characters'] ?? []),
      themes: List<String>.from(json['themes'] ?? []),
      events: List<String>.from(json['events'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      semanticContext: Map<String, dynamic>.from(json['semanticContext'] ?? {}),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }
}

/// Analyse de l'historique du plan de lecture
class PlanHistoryAnalysis {
  final List<CompletedPassage> completedPassages;
  final List<String> recurringThemes;
  final List<String> recurringCharacters;
  final Map<String, int> themeFrequency;
  final Map<String, int> characterFrequency;
  final Map<String, int> keywordFrequency;
  final DateTime analyzedAt;

  PlanHistoryAnalysis({
    required this.completedPassages,
    required this.recurringThemes,
    required this.recurringCharacters,
    required this.themeFrequency,
    required this.characterFrequency,
    required this.keywordFrequency,
    required this.analyzedAt,
  });

  /// Retourne les thèmes les plus fréquents
  List<String> get topThemes {
    final sorted = themeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Retourne les personnages les plus fréquents
  List<String> get topCharacters {
    final sorted = characterFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Retourne les mots-clés les plus fréquents
  List<String> get topKeywords {
    final sorted = keywordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'completedPassages': completedPassages.map((p) => p.toJson()).toList(),
      'recurringThemes': recurringThemes,
      'recurringCharacters': recurringCharacters,
      'themeFrequency': themeFrequency,
      'characterFrequency': characterFrequency,
      'keywordFrequency': keywordFrequency,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory PlanHistoryAnalysis.fromJson(Map<String, dynamic> json) {
    return PlanHistoryAnalysis(
      completedPassages: (json['completedPassages'] as List)
          .map((p) => CompletedPassage.fromJson(p as Map<String, dynamic>))
          .toList(),
      recurringThemes: List<String>.from(json['recurringThemes'] ?? []),
      recurringCharacters: List<String>.from(json['recurringCharacters'] ?? []),
      themeFrequency: Map<String, int>.from(json['themeFrequency'] ?? {}),
      characterFrequency: Map<String, int>.from(json['characterFrequency'] ?? {}),
      keywordFrequency: Map<String, int>.from(json['keywordFrequency'] ?? {}),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }
}

/// Passage complété avec son contenu et métadonnées
class CompletedPassage {
  final String passageRef;
  final String passageText;
  final DateTime completedAt;
  final int dayIndex;
  final String? annotation;
  final List<String>? tags;
  final int? estimatedMinutes;

  CompletedPassage({
    required this.passageRef,
    required this.passageText,
    required this.completedAt,
    required this.dayIndex,
    this.annotation,
    this.tags,
    this.estimatedMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'passageRef': passageRef,
      'passageText': passageText,
      'completedAt': completedAt.toIso8601String(),
      'dayIndex': dayIndex,
      'annotation': annotation,
      'tags': tags,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  factory CompletedPassage.fromJson(Map<String, dynamic> json) {
    return CompletedPassage(
      passageRef: json['passageRef'] as String,
      passageText: json['passageText'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      dayIndex: json['dayIndex'] as int,
      annotation: json['annotation'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      estimatedMinutes: json['estimatedMinutes'] as int?,
    );
  }
}

/// Référence croisée pour enrichir les questions
class CrossReference {
  final String reference;
  final String theme;
  final String description;
  final double relevanceScore;

  CrossReference({
    required this.reference,
    required this.theme,
    required this.description,
    required this.relevanceScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'theme': theme,
      'description': description,
      'relevanceScore': relevanceScore,
    };
  }

  factory CrossReference.fromJson(Map<String, dynamic> json) {
    return CrossReference(
      reference: json['reference'] as String,
      theme: json['theme'] as String,
      description: json['description'] as String,
      relevanceScore: (json['relevanceScore'] as num).toDouble(),
    );
  }
}

/// Résultat de génération de questions
class QuestionGenerationResult {
  final List<QuizQuestion> contentQuestions;
  final List<QuizQuestion> historyQuestions;
  final List<QuizQuestion> crossRefQuestions;
  final Map<String, dynamic> metadata;

  QuestionGenerationResult({
    required this.contentQuestions,
    required this.historyQuestions,
    required this.crossRefQuestions,
    required this.metadata,
  });

  List<QuizQuestion> get allQuestions {
    return [...contentQuestions, ...historyQuestions, ...crossRefQuestions];
  }

  int get totalQuestions => allQuestions.length;

  Map<String, dynamic> toJson() {
    return {
      'contentQuestions': contentQuestions.map((q) => q.toMap()).toList(),
      'historyQuestions': historyQuestions.map((q) => q.toMap()).toList(),
      'crossRefQuestions': crossRefQuestions.map((q) => q.toMap()).toList(),
      'metadata': metadata,
    };
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// MODÈLES POUR LA PROGRESSION THÉOLOGIQUE
/// ═══════════════════════════════════════════════════════════════════════════

/// Occurrence d'un thème dans un passage
class ThemeOccurrence {
  final String passageRef;
  final String context;
  final int dayIndex;
  final String aspect; // Quel aspect du thème est développé
  final DateTime readAt;
  
  ThemeOccurrence({
    required this.passageRef,
    required this.context,
    required this.dayIndex,
    required this.aspect,
    required this.readAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'passageRef': passageRef,
      'context': context,
      'dayIndex': dayIndex,
      'aspect': aspect,
      'readAt': readAt.toIso8601String(),
    };
  }

  factory ThemeOccurrence.fromMap(Map<String, dynamic> map) {
    return ThemeOccurrence(
      passageRef: map['passageRef'] as String,
      context: map['context'] as String,
      dayIndex: map['dayIndex'] as int,
      aspect: map['aspect'] as String,
      readAt: DateTime.parse(map['readAt'] as String),
    );
  }
}

/// Progression d'un thème à travers le plan de lecture
class ThemeProgression {
  final String theme;
  final List<ThemeOccurrence> occurrences;
  final String evolutionPattern;
  final Map<String, int> aspectFrequency; // Fréquence des aspects du thème
  
  ThemeProgression({
    required this.theme,
    required this.occurrences,
    required this.evolutionPattern,
    this.aspectFrequency = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'occurrences': occurrences.map((o) => o.toMap()).toList(),
      'evolutionPattern': evolutionPattern,
      'aspectFrequency': aspectFrequency,
    };
  }

  factory ThemeProgression.fromMap(Map<String, dynamic> map) {
    return ThemeProgression(
      theme: map['theme'] as String,
      occurrences: (map['occurrences'] as List).map((e) => ThemeOccurrence.fromMap(e as Map<String, dynamic>)).toList(),
      evolutionPattern: map['evolutionPattern'] as String,
      aspectFrequency: Map<String, int>.from(map['aspectFrequency'] as Map),
    );
  }
}

/// Arc narratif du plan de lecture
class NarrativeArc {
  final String book;
  final List<String> mainCharacters;
  final List<String> keyEvents;
  final List<String> theologicalThemes;
  final String overallMessage;
  final Map<String, String> characterDevelopment; // Évolution des personnages
  
  NarrativeArc({
    required this.book,
    required this.mainCharacters,
    required this.keyEvents,
    required this.theologicalThemes,
    required this.overallMessage,
    this.characterDevelopment = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'book': book,
      'mainCharacters': mainCharacters,
      'keyEvents': keyEvents,
      'theologicalThemes': theologicalThemes,
      'overallMessage': overallMessage,
      'characterDevelopment': characterDevelopment,
    };
  }

  factory NarrativeArc.fromMap(Map<String, dynamic> map) {
    return NarrativeArc(
      book: map['book'] as String,
      mainCharacters: List<String>.from(map['mainCharacters'] as List),
      keyEvents: List<String>.from(map['keyEvents'] as List),
      theologicalThemes: List<String>.from(map['theologicalThemes'] as List),
      overallMessage: map['overallMessage'] as String,
      characterDevelopment: Map<String, String>.from(map['characterDevelopment'] as Map),
    );
  }
}
