import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../../data/meditation_models.dart';
import 'step_intro_page.dart';
import 'step_question_mcq_page.dart';
import 'step_question_free_page.dart';
import 'step_checklist_page.dart';
import 'step_summary_page.dart';

/// Page principale du flow de méditation
class MeditationFlowPage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const MeditationFlowPage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<MeditationFlowPage> createState() => _MeditationFlowPageState();
}

class _MeditationFlowPageState extends ConsumerState<MeditationFlowPage> {
  @override
  Widget build(BuildContext context) {
    final params = {
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    };
    
    final meditationState = ref.watch(meditationControllerProvider(params));
    final controller = ref.read(meditationControllerProvider(params).notifier);

    if (meditationState.isLoading) {
      return Scaffold(
        backgroundColor: DesignTokens.primaryGradient.colors.first,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Naviguer vers la page appropriée selon l'étape
    switch (meditationState.currentStep) {
      case MeditationStep.intro:
        return StepIntroPage(
          planId: widget.planId,
          dayNumber: widget.dayNumber,
          passageRef: widget.passageRef,
        );
      case MeditationStep.mcq:
        return StepQuestionMcqPage(
          planId: widget.planId,
          dayNumber: widget.dayNumber,
          passageRef: widget.passageRef,
        );
      case MeditationStep.free:
        return StepQuestionFreePage(
          planId: widget.planId,
          dayNumber: widget.dayNumber,
          passageRef: widget.passageRef,
        );
      case MeditationStep.checklist:
        return StepChecklistPage(
          planId: widget.planId,
          dayNumber: widget.dayNumber,
          passageRef: widget.passageRef,
        );
      case MeditationStep.summary:
        return StepSummaryPage(
          planId: widget.planId,
          dayNumber: widget.dayNumber,
          passageRef: widget.passageRef,
        );
      default:
        return StepIntroPage(
          planId: widget.planId,
          dayNumber: widget.dayNumber,
          passageRef: widget.passageRef,
        );
    }
  }
}
