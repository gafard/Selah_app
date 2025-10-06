import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../../data/meditation_questions.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/bottom_primary_button.dart';

/// Page de réponse libre
class StepFreeInputPage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepFreeInputPage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepFreeInputPage> createState() => _StepFreeInputPageState();
}

class _StepFreeInputPageState extends ConsumerState<StepFreeInputPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  int _currentQuestionIndex = 0;

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
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateAnswer(String questionId, String answer) {
    final controller = ref.read(meditationControllerProvider({
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    }).notifier);
    
    controller.answerFree(questionId, answer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meditationControllerProvider({
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    }));

    final pack = MeditationQuestions.getPackByOption(state.selectedOption!);
    if (pack == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur: Pack de méditation non trouvé'),
        ),
      );
    }

    final currentQuestion = pack.free[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / pack.free.length;
    final currentAnswer = state.freeAnswers[currentQuestion.id] ?? '';
    final maxLength = currentQuestion.maxLength ?? 1000;

    // Initialiser le controller avec la réponse existante
    if (_textController.text != currentAnswer) {
      _textController.text = currentAnswer;
    }

    return GradientScaffold(
      appBar: ProgressHeader(
        title: 'Réflexion personnelle',
        progress: progress,
        onBack: () {
          if (_currentQuestionIndex > 0) {
            setState(() {
              _currentQuestionIndex--;
            });
          } else {
            Navigator.of(context).pop();
          }
        },
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
                          
                          // Question
                          Text(
                            currentQuestion.prompt,
                            style: DesignTokens.heading.copyWith(
                              fontSize: 24,
                              height: 1.3,
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Zone de texte
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: DesignTokens.body.copyWith(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                maxLines: currentQuestion.minLines,
                                maxLength: maxLength,
                                decoration: InputDecoration(
                                  hintText: 'Écris tes réflexions ici...',
                                  hintStyle: DesignTokens.placeholder,
                                  border: InputBorder.none,
                                  counterStyle: DesignTokens.body.copyWith(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  _updateAnswer(currentQuestion.id, value);
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Conseils
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Prends le temps d\'écrire tes pensées. Il n\'y a pas de longueur minimale requise.',
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
        text: _currentQuestionIndex < pack.free.length - 1 ? 'Suivant' : 'Continuer',
        enabled: currentAnswer.trim().isNotEmpty,
        onPressed: currentAnswer.trim().isNotEmpty
            ? () {
                // Masquer le clavier
                _focusNode.unfocus();
                
                if (_currentQuestionIndex < pack.free.length - 1) {
                  setState(() {
                    _currentQuestionIndex++;
                    _textController.clear();
                  });
                  _animationController.reset();
                  _animationController.forward();
                } else {
                  final controller = ref.read(meditationControllerProvider({
                    'planId': widget.planId,
                    'dayNumber': widget.dayNumber,
                    'passageRef': widget.passageRef,
                  }).notifier);
                  controller.next();
                }
              }
            : null,
      ),
    );
  }
}
