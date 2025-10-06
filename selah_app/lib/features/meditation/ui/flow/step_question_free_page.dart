import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/bottom_primary_button.dart';

/// Page de questions libres
class StepQuestionFreePage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepQuestionFreePage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepQuestionFreePage> createState() => _StepQuestionFreePageState();
}

class _StepQuestionFreePageState extends ConsumerState<StepQuestionFreePage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = {
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    };
    
    final meditationState = ref.watch(meditationControllerProvider(params));
    final controller = ref.read(meditationControllerProvider(params).notifier);

    // Simuler une question libre
    const question = "Partagez vos réflexions personnelles sur ce passage...";
    
    return GradientScaffold(
      appBar: ProgressHeader(
        title: 'Réflexion',
        progress: 0.6,
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
                    "Partagez vos réflexions personnelles sur ce passage...",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DesignTokens.white14,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DesignTokens.white22),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Écrivez vos réflexions ici...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        // Sauvegarder automatiquement la réponse
                        controller.answerFree('free_1', value);
                      },
                    ),
                  ),
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomPrimaryButton(
              text: 'Continuer',
              onPressed: _textController.text.trim().isNotEmpty ? () => controller.next() : null,
              enabled: _textController.text.trim().isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }
}
