import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/bottom_primary_button.dart';

/// Page de révision de la checklist
class StepChecklistReviewPage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepChecklistReviewPage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepChecklistReviewPage> createState() => _StepChecklistReviewPageState();
}

class _StepChecklistReviewPageState extends ConsumerState<StepChecklistReviewPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChecklist(String item) {
    final controller = ref.read(meditationControllerProvider({
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    }).notifier);
    
    controller.toggleChecklistItem(item);
  }

  Color _getChecklistColor(int index) {
    final colors = [
      DesignTokens.gold,
      DesignTokens.rose,
      DesignTokens.green,
      DesignTokens.lavender,
      DesignTokens.gold,
      DesignTokens.rose,
    ];
    return colors[index % colors.length];
  }

  IconData _getChecklistIcon(String item) {
    switch (item) {
      case 'Action de grâce':
        return Icons.celebration_rounded;
      case 'Repentance':
        return Icons.favorite_rounded;
      case 'Obéissance':
        return Icons.directions_run_rounded;
      case 'Intercession':
        return Icons.people_rounded;
      case 'Foi/Confiance':
        return Icons.psychology_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationControllerProvider({
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    }));

    const progress = 0.8; // 4ème étape sur 5

    return GradientScaffold(
      appBar: ProgressHeader(
        title: 'Sujets de prière',
        progress: progress,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.margin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Titre et description
                          Text(
                            'Sujets de prière proposés',
                            style: DesignTokens.heading.copyWith(
                              fontSize: 24,
                              height: 1.3,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            'Sélectionne les sujets que tu souhaites inclure dans ta prière. Ces suggestions sont basées sur tes réponses précédentes.',
                            style: DesignTokens.body.copyWith(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Liste des éléments de checklist
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.checklist.length,
                              itemBuilder: (context, index) {
                                final item = state.checklist[index];
                                final isSelected = state.checklist.contains(item);
                                final color = _getChecklistColor(index);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: DesignTokens.spacing),
                                  child: GestureDetector(
                                    onTap: () {
                                      _toggleChecklist(item);
                                      HapticFeedback.lightImpact();
                                    },
                                    child: AnimatedContainer(
                                      duration: DesignTokens.animationDuration,
                                      curve: DesignTokens.animationCurve,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color.withOpacity(0.3),
                                            color.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: color.withOpacity(0.5),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected 
                                            ? [
                                                BoxShadow(
                                                  color: color.withOpacity(0.3),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getChecklistIcon(item),
                                              color: color,
                                              size: 24,
                                            ),
                                          ),
                                          
                                          const SizedBox(width: 16),
                                          
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: DesignTokens.subheading.copyWith(
                                                decoration: isSelected 
                                                    ? TextDecoration.lineThrough 
                                                    : null,
                                                decorationColor: Colors.white.withOpacity(0.7),
                                                decorationThickness: 2,
                                              ),
                                            ),
                                          ),
                                          
                                          AnimatedScale(
                                            scale: isSelected ? 1.0 : 0.0,
                                            duration: DesignTokens.animationDuration,
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: color.withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Message d'erreur
                    if (state.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: DesignTokens.body.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Conseils
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tu peux sélectionner plusieurs sujets ou aucun. Ces suggestions t\'aideront à structurer ta prière.',
                              style: DesignTokens.body.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomPrimaryButton(
        text: 'Terminer la méditation',
        enabled: state.checklist.isNotEmpty,
        onPressed: state.checklist.isNotEmpty
            ? () {
                final controller = ref.read(meditationControllerProvider({
                  'planId': widget.planId,
                  'dayNumber': widget.dayNumber,
                  'passageRef': widget.passageRef,
                }).notifier);
                controller.finish();
              }
            : null,
      ),
    );
  }
}
