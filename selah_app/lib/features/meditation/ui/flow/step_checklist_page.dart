import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/bottom_primary_button.dart';

/// Page de checklist finale
class StepChecklistPage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepChecklistPage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepChecklistPage> createState() => _StepChecklistPageState();
}

class _StepChecklistPageState extends ConsumerState<StepChecklistPage> {
  final List<String> _availableTags = [
    'Action de grâce',
    'Repentance',
    'Obéissance',
    'Intercession',
    'Foi/Confiance',
    'Louange',
  ];

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
        title: 'Checklist',
        progress: 0.8,
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
                    'Sélectionnez les éléments de prière',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choisissez ce pour quoi vous voulez prier après cette méditation.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableTags.map((tag) {
                      final isSelected = meditationState.checklist.contains(tag);
                      return GestureDetector(
                        onTap: () => controller.toggleChecklistItem(tag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? DesignTokens.white22 : DesignTokens.white14,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? DesignTokens.white55 : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                              ),
                            ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomPrimaryButton(
              text: 'Terminer',
              onPressed: meditationState.checklist.isNotEmpty ? () => controller.next() : null,
              enabled: meditationState.checklist.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }
}
