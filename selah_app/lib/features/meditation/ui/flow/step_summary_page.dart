import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/bottom_primary_button.dart';

/// Page de résumé final
class StepSummaryPage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepSummaryPage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepSummaryPage> createState() => _StepSummaryPageState();
}

class _StepSummaryPageState extends ConsumerState<StepSummaryPage> {
  @override
  Widget build(BuildContext context) {
    final params = {
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    };
    
    final meditationState = ref.watch(meditationControllerProvider(params));
    final controller = ref.read(meditationControllerProvider(params).notifier);

    return GradientScaffold(
      appBar: const ProgressHeader(
        title: 'Résumé',
        progress: 1.0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Méditation terminée !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Félicitations pour avoir terminé votre session de méditation.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Résumé des réponses
                  if (meditationState.mcqAnswers.isNotEmpty) ...[
                    const Text(
                      'Vos réponses MCQ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...meditationState.mcqAnswers.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DesignTokens.white14,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Checklist sélectionnée
                  if (meditationState.checklist.isNotEmpty) ...[
                    const Text(
                      'Éléments de prière sélectionnés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: meditationState.checklist.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: DesignTokens.white22,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomPrimaryButton(
              text: 'Aller à la prière',
              onPressed: () => controller.finish(),
              isLoading: meditationState.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
