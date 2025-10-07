import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../../data/meditation_questions.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/bottom_primary_button.dart';

/// Page de résumé et finalisation
class StepSummaryDonePage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepSummaryDonePage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepSummaryDonePage> createState() => _StepSummaryDonePageState();
}

class _StepSummaryDonePageState extends ConsumerState<StepSummaryDonePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToPrayer() {
    // Navigation vers la page de prière avec la checklist
    final state = ref.read(meditationControllerProvider({
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    }));
    
    // TODO: Implémenter la navigation vers /prayer/start avec la checklist
    // Pour l'instant, on retourne à la page précédente
    Navigator.of(context).pop();
    
    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Méditation terminée ! ${state.checklist.length} sujets de prière sélectionnés.',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationControllerProvider({
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    }));

    final pack = MeditationQuestions.getPackByOption(state.selectedOption!);
    const progress = 1.0; // Dernière étape

    return GradientScaffold(
      appBar: ProgressHeader(
        title: 'Méditation terminée',
        progress: progress,
        showProgress: false,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.margin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Animation de succès
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0.3),
                                  Colors.green.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 60,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bravo !',
                                style: DesignTokens.heading.copyWith(
                                  fontSize: 32,
                                  color: Colors.green,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Text(
                                'Tu as terminé ta méditation sur ${widget.passageRef}',
                                style: DesignTokens.subheading.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Résumé
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Résumé de ta méditation',
                                          style: DesignTokens.subheading,
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Style choisi',
                                                style: DesignTokens.body.copyWith(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                pack?.title ?? 'Non défini',
                                                style: DesignTokens.body,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Sujets de prière',
                                                style: DesignTokens.body.copyWith(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '${state.checklist.length} sélectionnés',
                                                style: DesignTokens.body,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Liste des sujets sélectionnés
                              if (state.checklist.isNotEmpty) ...[
                                Text(
                                  'Sujets de prière sélectionnés :',
                                  style: DesignTokens.subheading,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                ...state.checklist.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final color = _getChecklistColor(index);
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          item,
                                          style: DesignTokens.body,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomPrimaryButton(
        text: 'Passer à la prière',
        enabled: !state.isLoading,
        isLoading: state.isLoading,
        onPressed: state.isLoading ? null : _goToPrayer,
      ),
    );
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
}
