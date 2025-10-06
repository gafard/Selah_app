import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/bottom_primary_button.dart';
import '../components/modal_option_chooser.dart';

/// Page d'introduction du flow de méditation
class StepIntroPage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepIntroPage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepIntroPage> createState() => _StepIntroPageState();
}

class _StepIntroPageState extends ConsumerState<StepIntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
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

  void _showOptionChooser() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalOptionChooser(
        onSelected: (option) {
          final controller = ref.read(meditationControllerProvider({
            'planId': widget.planId,
            'dayNumber': widget.dayNumber,
            'passageRef': widget.passageRef,
          }).notifier);
          controller.selectOption(option);
        },
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

    return GradientScaffold(
      appBar: ProgressHeader(
        title: 'Méditation du jour',
        progress: 0.0,
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
                          const SizedBox(height: 40),
                          
                          // Illustration héroïque
                          Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.self_improvement_rounded,
                                color: Colors.white,
                                size: 100,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Titre principal
                          Text(
                            'Prenons 5-10 minutes',
                            style: DesignTokens.heading.copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'pour méditer',
                            style: DesignTokens.heading.copyWith(
                              fontSize: 32,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Référence du passage
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
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.passageRef,
                                    style: DesignTokens.subheading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Description
                          Text(
                            'Choisis ton style de méditation pour explorer ce passage biblique de manière personnelle et approfondie.',
                            style: DesignTokens.body.copyWith(
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Option sélectionnée ou bouton pour choisir
                          if (state.selectedOption != null) ...[
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
                              child: Row(
                                children: [
                                  Icon(
                                    state.selectedOption == 1 
                                        ? Icons.explore_rounded 
                                        : Icons.menu_book_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.selectedOption == 1 
                                              ? 'Processus de Découverte'
                                              : 'Lecture Quotidienne',
                                          style: DesignTokens.subheading,
                                        ),
                                        Text(
                                          state.selectedOption == 1 
                                              ? 'Demander/Chercher/Frapper'
                                              : '8 questions d\'étude',
                                          style: DesignTokens.body.copyWith(
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: _showOptionChooser,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _showOptionChooser,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Choisir un style de méditation',
                                      style: DesignTokens.body.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomPrimaryButton(
        text: state.selectedOption != null ? 'Commencer' : 'Choisir un style',
        enabled: state.selectedOption != null,
        onPressed: state.selectedOption != null 
            ? () {
                final controller = ref.read(meditationControllerProvider({
                  'planId': widget.planId,
                  'dayNumber': widget.dayNumber,
                  'passageRef': widget.passageRef,
                }).notifier);
                controller.next();
              }
            : _showOptionChooser,
      ),
    );
  }
}
