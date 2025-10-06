/// Modèles de données pour la feature Meditation Flow
class McqQuestion {
  final String id;
  final String title;
  final List<String> choices;
  final bool allowOther;

  const McqQuestion({
    required this.id,
    required this.title,
    required this.choices,
    this.allowOther = false,
  });

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    return McqQuestion(
      id: json['id'] as String,
      title: json['title'] as String,
      choices: List<String>.from(json['choices'] as List),
      allowOther: json['allowOther'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'choices': choices,
      'allowOther': allowOther,
    };
  }
}

class FreeQuestion {
  final String id;
  final String prompt;
  final int minLines;
  final int? maxLength;

  const FreeQuestion({
    required this.id,
    required this.prompt,
    this.minLines = 3,
    this.maxLength,
  });

  factory FreeQuestion.fromJson(Map<String, dynamic> json) {
    return FreeQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      minLines: json['minLines'] as int? ?? 3,
      maxLength: json['maxLength'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'minLines': minLines,
      'maxLength': maxLength,
    };
  }
}

class MeditationPack {
  final String packId;
  final String title;
  final String description;
  final List<McqQuestion> mcq;
  final List<FreeQuestion> free;

  const MeditationPack({
    required this.packId,
    required this.title,
    required this.description,
    required this.mcq,
    required this.free,
  });

  factory MeditationPack.fromJson(Map<String, dynamic> json) {
    return MeditationPack(
      packId: json['packId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      mcq: (json['mcq'] as List)
          .map((q) => McqQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      free: (json['free'] as List)
          .map((q) => FreeQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packId': packId,
      'title': title,
      'description': description,
      'mcq': mcq.map((q) => q.toJson()).toList(),
      'free': free.map((q) => q.toJson()).toList(),
    };
  }
}

class MeditationResult {
  final String planId;
  final int dayNumber;
  final String passageRef;
  final int option; // 1 ou 2
  final Map<String, dynamic> mcqAnswers; // {questionId: choice}
  final Map<String, String> freeAnswers; // {questionId: text}
  final List<String> checklist; // tags générés
  final DateTime createdAt;
  final bool isCompleted;

  const MeditationResult({
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
    required this.option,
    required this.mcqAnswers,
    required this.freeAnswers,
    required this.checklist,
    required this.createdAt,
    this.isCompleted = false,
  });

  factory MeditationResult.fromJson(Map<String, dynamic> json) {
    return MeditationResult(
      planId: json['planId'] as String,
      dayNumber: json['dayNumber'] as int,
      passageRef: json['passageRef'] as String,
      option: json['option'] as int,
      mcqAnswers: Map<String, dynamic>.from(json['mcqAnswers'] as Map),
      freeAnswers: Map<String, String>.from(json['freeAnswers'] as Map),
      checklist: List<String>.from(json['checklist'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'dayNumber': dayNumber,
      'passageRef': passageRef,
      'option': option,
      'mcqAnswers': mcqAnswers,
      'freeAnswers': freeAnswers,
      'checklist': checklist,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  MeditationResult copyWith({
    String? planId,
    int? dayNumber,
    String? passageRef,
    int? option,
    Map<String, dynamic>? mcqAnswers,
    Map<String, String>? freeAnswers,
    List<String>? checklist,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return MeditationResult(
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      passageRef: passageRef ?? this.passageRef,
      option: option ?? this.option,
      mcqAnswers: mcqAnswers ?? this.mcqAnswers,
      freeAnswers: freeAnswers ?? this.freeAnswers,
      checklist: checklist ?? this.checklist,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// État du flow de méditation
enum MeditationStep {
  intro(0),
  mcq(1),
  free(2),
  checklist(3),
  summary(4);

  const MeditationStep(this.value);
  final int value;

  static MeditationStep fromValue(int value) {
    return MeditationStep.values.firstWhere((step) => step.value == value);
  }
}

/// État du controller de méditation
class MeditationState {
  final MeditationStep currentStep;
  final int? selectedOption; // 1 ou 2
  final Map<String, dynamic> mcqAnswers;
  final Map<String, String> freeAnswers;
  final List<String> checklist;
  final bool isLoading;
  final String? error;

  const MeditationState({
    this.currentStep = MeditationStep.intro,
    this.selectedOption,
    this.mcqAnswers = const {},
    this.freeAnswers = const {},
    this.checklist = const [],
    this.isLoading = false,
    this.error,
  });

  MeditationState copyWith({
    MeditationStep? currentStep,
    int? selectedOption,
    Map<String, dynamic>? mcqAnswers,
    Map<String, String>? freeAnswers,
    List<String>? checklist,
    bool? isLoading,
    String? error,
  }) {
    return MeditationState(
      currentStep: currentStep ?? this.currentStep,
      selectedOption: selectedOption ?? this.selectedOption,
      mcqAnswers: mcqAnswers ?? this.mcqAnswers,
      freeAnswers: freeAnswers ?? this.freeAnswers,
      checklist: checklist ?? this.checklist,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Génère la checklist à partir des réponses
  List<String> generateChecklist() {
    final tags = <String>{};
    
    // Analyser les réponses MCQ
    for (final answer in mcqAnswers.values) {
      final text = answer.toString().toLowerCase();
      
      if (text.contains('promesse') || text.contains('vérité') || text.contains('louange')) {
        tags.add('Action de grâce');
      }
      if (text.contains('péché') || text.contains('avertissement') || text.contains('mauvais exemple')) {
        tags.add('Repentance');
      }
      if (text.contains('ordre') || text.contains('à faire aujourd\'hui')) {
        tags.add('Obéissance');
      }
      if (text.contains('pour les autres') || text.contains('intercession')) {
        tags.add('Intercession');
      }
      if (text.contains('promesse à croire') || text.contains('foi')) {
        tags.add('Foi/Confiance');
      }
    }
    
    // Analyser les réponses libres
    for (final answer in freeAnswers.values) {
      final text = answer.toLowerCase();
      
      if (text.contains('merci') || text.contains('gratitude') || text.contains('bénédiction')) {
        tags.add('Action de grâce');
      }
      if (text.contains('pardon') || text.contains('repentance') || text.contains('regret')) {
        tags.add('Repentance');
      }
      if (text.contains('obéir') || text.contains('suivre') || text.contains('appliquer')) {
        tags.add('Obéissance');
      }
      if (text.contains('prier') || text.contains('intercéder') || text.contains('famille') || text.contains('amis')) {
        tags.add('Intercession');
      }
      if (text.contains('croire') || text.contains('confiance') || text.contains('foi')) {
        tags.add('Foi/Confiance');
      }
    }
    
    return tags.take(6).toList(); // Max 6 éléments
  }
}
