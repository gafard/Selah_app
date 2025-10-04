import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/design_tokens.dart';
import '../../logic/meditation_controller.dart';
import '../../data/meditation_questions.dart';
import '../components/gradient_scaffold.dart';
import '../components/progress_header.dart';
import '../components/pill_option_button.dart';
import '../components/bottom_primary_button.dart';

/// Page de questions à choix multiples
class StepQuestionMcqPage extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;
  final String passageRef;

  const StepQuestionMcqPage({
    super.key,
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
  });

  @override
  ConsumerState<StepQuestionMcqPage> createState() => _StepQuestionMcqPageState();
}

class _StepQuestionMcqPageState extends ConsumerState<StepQuestionMcqPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentQuestionIndex = 0;
  String? _otherText;

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

  void _answerQuestion(String questionId, String answer) {
    final controller = ref.read(meditationControllerProvider({
      'planId': widget.planId,
      'dayNumber': widget.dayNumber,
      'passageRef': widget.passageRef,
    }).notifier);
    
    controller.answerMcq(questionId, answer);
  }

  void _showOtherInput(String questionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Autre réponse',
            style: DesignTokens.subheading,
          ),
          content: TextField(
            style: DesignTokens.body,
            decoration: InputDecoration(
              hintText: 'Tapez votre réponse...',
              hintStyle: DesignTokens.placeholder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
            maxLines: 3,
            onChanged: (value) => _otherText = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: DesignTokens.body.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_otherText != null && _otherText!.trim().isNotEmpty) {
                  _answerQuestion(questionId, _otherText!);
                }
                Navigator.of(context).pop();
                _otherText = null;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Valider'),
            ),
          ],
        );
      },
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
    if (pack == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur: Pack de méditation non trouvé'),
        ),
      );
    }

    final currentQuestion = pack.mcq[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / pack.mcq.length;

    return GradientScaffold(
      appBar: ProgressHeader(
        title: 'Question ${_currentQuestionIndex + 1} sur ${pack.mcq.length}',
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            
                            // Question
                            Text(
                              currentQuestion.title,
                              style: DesignTokens.heading.copyWith(
                                fontSize: 24,
                                height: 1.3,
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Options de réponse
                            ...currentQuestion.choices.map((choice) {
                              final isSelected = state.mcqAnswers[currentQuestion.id] == choice;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: DesignTokens.spacing),
                                child: PillOptionButton(
                                  text: choice,
                                  isSelected: isSelected,
                                  onTap: () => _answerQuestion(currentQuestion.id, choice),
                                ),
                              );
                            }),
                            
                            // Option "Autre" si disponible
                            if (currentQuestion.allowOther) ...[
                              const SizedBox(height: 8),
                              PillOptionButton(
                                text: 'Autre...',
                                isSelected: state.mcqAnswers[currentQuestion.id] != null &&
                                    !currentQuestion.choices.contains(state.mcqAnswers[currentQuestion.id]),
                                onTap: () => _showOtherInput(currentQuestion.id),
                              ),
                            ],
                            
                            const SizedBox(height: 40),
                            
                            // Indicateur de progression
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                      'Prends le temps de réfléchir à ta réponse. Il n\'y a pas de bonne ou mauvaise réponse.',
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
        text: _currentQuestionIndex < pack.mcq.length - 1 ? 'Suivant' : 'Continuer',
        enabled: state.mcqAnswers.containsKey(currentQuestion.id),
        onPressed: state.mcqAnswers.containsKey(currentQuestion.id)
            ? () {
                if (_currentQuestionIndex < pack.mcq.length - 1) {
                  setState(() {
                    _currentQuestionIndex++;
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
