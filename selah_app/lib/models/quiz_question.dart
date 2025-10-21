import 'package:flutter/material.dart';

/// 🧠 Modèle de question de quiz intelligent
/// 
/// Utilisé par le service IntelligentQuizService pour générer
/// des questions personnalisées basées sur l'analyse sémantique

enum QuizType { single, multi }

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final List<int> correctAnswerIndices;
  final String explanation;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String category; // 'comprehension', 'application', 'analysis', 'synthesis'
  final QuizType type; // 'single', 'multi'
  final String? passageReference;
  final String? verseText;
  final Map<String, dynamic>? metadata; // Données supplémentaires pour l'analyse

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndices,
    required this.explanation,
    required this.difficulty,
    required this.category,
    this.type = QuizType.single,
    this.passageReference,
    this.verseText,
    this.metadata,
  });

  /// Crée une question depuis un Map (pour Hive)
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    // Support rétrocompatibilité pour l'ancien format
    List<int> correctIndices;
    if (map['correctAnswerIndices'] != null) {
      correctIndices = List<int>.from(map['correctAnswerIndices']);
    } else if (map['correctAnswerIndex'] != null) {
      correctIndices = [map['correctAnswerIndex']];
    } else {
      correctIndices = [0];
    }
    
    return QuizQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndices: correctIndices,
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 'medium',
      category: map['category'] ?? 'comprehension',
      type: map['type'] == 'multi' ? QuizType.multi : QuizType.single,
      passageReference: map['passageReference'],
      verseText: map['verseText'],
      metadata: map['metadata'],
    );
  }

  /// Convertit en Map (pour Hive)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndices': correctAnswerIndices,
      'explanation': explanation,
      'difficulty': difficulty,
      'category': category,
      'type': type.name,
      'passageReference': passageReference,
      'verseText': verseText,
      'metadata': metadata,
    };
  }

  /// Vérifie si une réponse est correcte (pour questions à choix simple)
  bool isCorrectAnswer(int selectedIndex) {
    return correctAnswerIndices.contains(selectedIndex);
  }

  /// Vérifie si plusieurs réponses sont correctes (pour questions à choix multiples)
  bool isCorrectAnswers(List<int> selectedIndices) {
    if (selectedIndices.length != correctAnswerIndices.length) return false;
    return selectedIndices.every((index) => correctAnswerIndices.contains(index));
  }

  /// Retourne la première réponse correcte (rétrocompatibilité)
  String get correctAnswer => options[correctAnswerIndex];

  /// Retourne l'index de la première réponse correcte (rétrocompatibilité)
  int get correctAnswerIndex => correctAnswerIndices.isNotEmpty ? correctAnswerIndices.first : 0;

  /// Retourne toutes les réponses correctes
  List<String> get correctAnswers => correctAnswerIndices.map((index) => options[index]).toList();

  /// Retourne la couleur associée à la difficulté
  Color get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Retourne l'icône associée à la catégorie
  IconData get categoryIcon {
    switch (category) {
      case 'comprehension':
        return Icons.lightbulb_outline;
      case 'application':
        return Icons.psychology;
      case 'analysis':
        return Icons.analytics;
      case 'synthesis':
        return Icons.auto_awesome;
      default:
        return Icons.quiz;
    }
  }

  /// Retourne le nom de la catégorie en français
  String get categoryName {
    switch (category) {
      case 'comprehension':
        return 'Compréhension';
      case 'application':
        return 'Application';
      case 'analysis':
        return 'Analyse';
      case 'synthesis':
        return 'Synthèse';
      default:
        return 'Général';
    }
  }

  /// Retourne le nom de la difficulté en français
  String get difficultyName {
    switch (difficulty) {
      case 'easy':
        return 'Facile';
      case 'medium':
        return 'Moyen';
      case 'hard':
        return 'Difficile';
      default:
        return 'Inconnu';
    }
  }
}

/// 📊 Résultat d'un quiz
class QuizResult {
  final String quizId;
  final List<QuizQuestion> questions;
  final List<List<int>> userAnswers; // Changé pour supporter les réponses multiples
  final int score;
  final double percentage;
  final Duration timeSpent;
  final DateTime completedAt;
  final Map<String, dynamic>? analytics; // Données d'analyse cognitive

  const QuizResult({
    required this.quizId,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.percentage,
    required this.timeSpent,
    required this.completedAt,
    this.analytics,
  });

  /// Crée un résultat depuis un Map
  factory QuizResult.fromMap(Map<String, dynamic> map) {
    // Support rétrocompatibilité pour l'ancien format
    List<List<int>> answers;
    if (map['userAnswers'] is List<List<dynamic>>) {
      answers = (map['userAnswers'] as List<dynamic>)
          .map((answer) => List<int>.from(answer))
          .toList();
    } else if (map['userAnswers'] is List<int>) {
      // Convertir l'ancien format en nouveau format
      answers = (map['userAnswers'] as List<int>)
          .map((answer) => [answer])
          .toList();
    } else {
      answers = [];
    }
    
    return QuizResult(
      quizId: map['quizId'] ?? '',
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromMap(q))
          .toList() ?? [],
      userAnswers: answers,
      score: map['score'] ?? 0,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      timeSpent: Duration(milliseconds: map['timeSpentMs'] ?? 0),
      completedAt: DateTime.parse(map['completedAt'] ?? DateTime.now().toIso8601String()),
      analytics: map['analytics'],
    );
  }

  /// Convertit en Map
  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'questions': questions.map((q) => q.toMap()).toList(),
      'userAnswers': userAnswers,
      'score': score,
      'percentage': percentage,
      'timeSpentMs': timeSpent.inMilliseconds,
      'completedAt': completedAt.toIso8601String(),
      'analytics': analytics,
    };
  }

  /// Retourne le nombre de bonnes réponses
  int get correctAnswers {
    int correct = 0;
    for (int i = 0; i < questions.length && i < userAnswers.length; i++) {
      final question = questions[i];
      final userAnswer = userAnswers[i];
      
      if (question.type == QuizType.single) {
        // Pour les questions à choix simple, vérifier le premier élément
        if (userAnswer.isNotEmpty && question.isCorrectAnswer(userAnswer.first)) {
          correct++;
        }
      } else {
        // Pour les questions à choix multiples, vérifier toutes les réponses
        if (question.isCorrectAnswers(userAnswer)) {
          correct++;
        }
      }
    }
    return correct;
  }

  /// Retourne la couleur du score
  Color get scoreColor {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Retourne le message de félicitation
  String get congratulationMessage {
    if (percentage >= 90) return 'Excellent ! 🎉';
    if (percentage >= 80) return 'Très bien ! 👏';
    if (percentage >= 60) return 'Bien joué ! 👍';
    return 'Continue tes efforts ! 💪';
  }
}
