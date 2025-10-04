import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/meditation_models.dart';
import '../data/meditation_repo.dart';
import '../data/meditation_questions.dart';

/// Provider pour le repository de méditation
final meditationRepoProvider = Provider<MeditationRepository>((ref) {
  return MeditationRepository();
});

/// Controller principal pour le flow de méditation
class MeditationController extends StateNotifier<MeditationState> {
  final MeditationRepository _repository;
  final String planId;
  final int dayNumber;
  final String passageRef;

  MeditationController(
    this._repository,
    this.planId,
    this.dayNumber,
    this.passageRef,
  ) : super(const MeditationState());

  /// Charge une méditation existante
  Future<void> loadExisting() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final existing = await _repository.fetchExisting(planId, dayNumber);
      if (existing != null) {
        state = state.copyWith(
          selectedOption: existing.option,
          mcqAnswers: existing.mcqAnswers,
          freeAnswers: existing.freeAnswers,
          checklist: existing.checklist,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sélectionne une option de méditation (1 ou 2)
  void selectOption(int option) {
    state = state.copyWith(
      selectedOption: option,
      error: null,
    );
    HapticFeedback.lightImpact();
  }

  /// Répond à une question MCQ
  void answerMcq(String questionId, dynamic answer) {
    final newAnswers = Map<String, dynamic>.from(state.mcqAnswers);
    newAnswers[questionId] = answer;
    
    state = state.copyWith(
      mcqAnswers: newAnswers,
      error: null,
    );
    HapticFeedback.lightImpact();
  }

  /// Répond à une question libre
  void answerFree(String questionId, String answer) {
    final newAnswers = Map<String, String>.from(state.freeAnswers);
    newAnswers[questionId] = answer;
    
    state = state.copyWith(
      freeAnswers: newAnswers,
      error: null,
    );
  }

  /// Passe à l'étape suivante
  Future<void> next() async {
    if (state.currentStep == MeditationStep.intro && state.selectedOption == null) {
      state = state.copyWith(error: 'Veuillez choisir un style de méditation');
      return;
    }

    if (state.currentStep == MeditationStep.mcq && !_hasAnsweredMcq()) {
      state = state.copyWith(error: 'Veuillez répondre à toutes les questions');
      return;
    }

    if (state.currentStep == MeditationStep.free && !_hasAnsweredFree()) {
      state = state.copyWith(error: 'Veuillez compléter la réponse libre');
      return;
    }

    // Sauvegarder le brouillon avant de continuer
    await _saveDraft();

    final nextStepIndex = state.currentStep.value + 1;
    if (nextStepIndex < MeditationStep.values.length) {
      final nextStep = MeditationStep.fromValue(nextStepIndex);
      
      // Générer la checklist si on arrive à l'étape checklist
      if (nextStep == MeditationStep.checklist) {
        final checklist = _generateChecklist();
        state = state.copyWith(
          currentStep: nextStep,
          checklist: checklist,
          error: null,
        );
      } else {
        state = state.copyWith(
          currentStep: nextStep,
          error: null,
        );
      }
    }
  }

  /// Retourne à l'étape précédente
  void previous() {
    if (state.currentStep.value > 0) {
      final prevStep = MeditationStep.fromValue(state.currentStep.value - 1);
      state = state.copyWith(
        currentStep: prevStep,
        error: null,
      );
    }
  }

  /// Toggle un élément de la checklist
  void toggleChecklistItem(String item) {
    final newChecklist = List<String>.from(state.checklist);
    if (newChecklist.contains(item)) {
      newChecklist.remove(item);
    } else {
      newChecklist.add(item);
    }
    
    state = state.copyWith(
      checklist: newChecklist,
      error: null,
    );
    HapticFeedback.lightImpact();
  }

  /// Termine la méditation
  Future<void> finish() async {
    if (state.checklist.isEmpty) {
      state = state.copyWith(error: 'Veuillez sélectionner au moins un sujet de prière');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = MeditationResult(
        planId: planId,
        dayNumber: dayNumber,
        passageRef: passageRef,
        option: state.selectedOption!,
        mcqAnswers: state.mcqAnswers,
        freeAnswers: state.freeAnswers,
        checklist: state.checklist,
        createdAt: DateTime.now(),
        isCompleted: true,
      );

      await _repository.markAsCompleted(result);
      
      state = state.copyWith(
        currentStep: MeditationStep.summary,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sauvegarde un brouillon
  Future<void> _saveDraft() async {
    if (state.selectedOption == null) return;

    try {
      final result = MeditationResult(
        planId: planId,
        dayNumber: dayNumber,
        passageRef: passageRef,
        option: state.selectedOption!,
        mcqAnswers: state.mcqAnswers,
        freeAnswers: state.freeAnswers,
        checklist: state.checklist,
        createdAt: DateTime.now(),
        isCompleted: false,
      );

      await _repository.saveDraft(result);
    } catch (e) {
      // print('Erreur lors de la sauvegarde du brouillon: $e');
    }
  }

  /// Vérifie si toutes les questions MCQ ont été répondues
  bool _hasAnsweredMcq() {
    if (state.selectedOption == null) return false;
    
    final pack = MeditationQuestions.getPackByOption(state.selectedOption!);
    if (pack == null) return false;

    for (final question in pack.mcq) {
      if (!state.mcqAnswers.containsKey(question.id)) {
        return false;
      }
    }
    return true;
  }

  /// Vérifie si toutes les questions libres ont été répondues
  bool _hasAnsweredFree() {
    if (state.selectedOption == null) return false;
    
    final pack = MeditationQuestions.getPackByOption(state.selectedOption!);
    if (pack == null) return false;

    for (final question in pack.free) {
      final answer = state.freeAnswers[question.id];
      if (answer == null || answer.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Récupère le pack actuel
  MeditationPack? getCurrentPack() {
    if (state.selectedOption == null) return null;
    return MeditationQuestions.getPackByOption(state.selectedOption!);
  }

  /// Vérifie si on peut continuer à l'étape actuelle
  bool canContinue() {
    switch (state.currentStep) {
      case MeditationStep.intro:
        return state.selectedOption != null;
      case MeditationStep.mcq:
        return _hasAnsweredMcq();
      case MeditationStep.free:
        return _hasAnsweredFree();
      case MeditationStep.checklist:
        return state.checklist.isNotEmpty;
      case MeditationStep.summary:
        return false; // Dernière étape
    }
  }

  /// Récupère le texte du bouton principal
  String getPrimaryButtonText() {
    switch (state.currentStep) {
      case MeditationStep.intro:
        return 'Commencer';
      case MeditationStep.checklist:
        return 'Terminer';
      case MeditationStep.summary:
        return 'Passer à la prière';
      default:
        return 'Continuer';
    }
  }

  /// Génère une checklist basée sur les réponses
  List<String> _generateChecklist() {
    final checklist = <String>[];
    
    // Logique simplifiée pour générer des tags basés sur les réponses
    if (state.mcqAnswers.isNotEmpty) {
      checklist.add('Action de grâce');
    }
    
    if (state.freeAnswers.isNotEmpty) {
      checklist.add('Intercession');
    }
    
    // Ajouter quelques tags par défaut
    if (checklist.isEmpty) {
      checklist.addAll(['Action de grâce', 'Repentance', 'Obéissance']);
    }
    
    return checklist;
  }
}

/// Provider pour le controller de méditation
final meditationControllerProvider = StateNotifierProvider.family<MeditationController, MeditationState, Map<String, dynamic>>((ref, params) {
  final repository = ref.watch(meditationRepoProvider);
  final planId = params['planId'] as String;
  final dayNumber = params['dayNumber'] as int;
  final passageRef = params['passageRef'] as String;
  
  return MeditationController(repository, planId, dayNumber, passageRef);
});
