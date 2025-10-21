import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/meditation_journal_service.dart';
import '../services/intelligent_content_quiz_generator.dart';
import '../services/bible_text_service.dart';
import '../services/adaptive_difficulty_service.dart';
import '../models/meditation_journal_entry.dart';
import '../models/quiz_question.dart';
import '../bootstrap.dart' as bootstrap;

class BibleQuizPage extends StatefulWidget {
  const BibleQuizPage({super.key});

  @override
  State<BibleQuizPage> createState() => _BibleQuizPageState();
}

class _BibleQuizPageState extends State<BibleQuizPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<MeditationJournalEntry> _journalEntries = [];
  List<QuizQuestion> _questions = [];
  List<int> _userAnswers = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizStarted = false;
  bool _quizCompleted = false;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isLoading = false;
  DateTime _quizStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadJournalEntries();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadJournalEntries() async {
    final entries = await MeditationJournalService.getEntries();
    setState(() {
      _journalEntries = entries;
    });
    await _generateIntelligentQuestions();
  }

  /// 🧠 Génère des questions intelligentes basées sur le contenu et l'historique
  Future<void> _generateIntelligentQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer le plan actuel et le passage du jour
      final planService = bootstrap.planService;
      final activePlan = await planService.getActiveLocalPlan();
      
      if (activePlan == null) {
        print('⚠️ Aucun plan actif trouvé, utilisation du fallback');
        _generateFallbackQuestions();
        return;
      }
      
      // Obtenir le passage actuel
      final planDays = await planService.getPlanDays(activePlan.id);
      final today = planDays.firstWhere(
        (day) => day.dayIndex == _calculateCurrentDayIndex(activePlan),
        orElse: () => planDays.first,
      );
      
      // Construire la référence du passage
      final passageRef = today.readings.isNotEmpty 
          ? '${today.readings.first.book} ${today.readings.first.range}'
          : 'Jean 3:16';
      
      // Récupérer le texte du passage
      final passageText = await _getPassageText(passageRef);
      
      if (passageText == null) {
        print('⚠️ Impossible de récupérer le texte du passage, utilisation du fallback');
        _generateFallbackQuestions();
        return;
      }
      
            // Calculer la difficulté adaptative
            final difficulty = await AdaptiveDifficultyService.calculateAdaptiveDifficulty('user_${DateTime.now().millisecondsSinceEpoch}');

            // Générer les questions intelligentes
            final questions = await IntelligentContentQuizGenerator.generatePersonalizedQuestions(
              currentPassageText: passageText,
              currentPassageRef: passageRef,
              currentPlanId: activePlan.id,
              questionCount: 10,
              targetDifficulty: difficulty.name,
            );
      
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      
      print('🧠 ${questions.length} questions générées (contenu + historique + cross-refs)');
    } catch (e) {
      print('❌ Erreur génération questions: $e');
      _generateFallbackQuestions();
    }
  }

  /// Questions de fallback si le service intelligent échoue
  void _generateFallbackQuestions() {
    if (_journalEntries.isEmpty) {
      _questions = _getDefaultQuestions().map((q) => QuizQuestion(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        question: q['question'],
        options: q['options'],
        correctAnswerIndex: q['correct'],
        explanation: q['explanation'],
        difficulty: 'medium',
        category: 'comprehension',
        passageReference: q['passage'],
      )).toList();
      setState(() {
        _isLoading = false;
      });
      return;
    }

    List<Map<String, dynamic>> questions = [];
    Set<String> usedQuestions = {}; // Pour éviter les doublons
    
    // Analyser l'historique pour créer des questions personnalisées
    for (var entry in _journalEntries) {
      if (entry.passageRef.isNotEmpty && entry.passageText.isNotEmpty) {
        // Créer des questions basées sur les passages lus
        final passageQuestions = _createQuestionsFromPassage(entry.passageRef, entry.passageText);
        
        // Ajouter seulement les questions uniques
        for (var question in passageQuestions) {
          if (!usedQuestions.contains(question['question'])) {
            questions.add(question);
            usedQuestions.add(question['question']);
          }
        }
      }
    }
    
    // Si pas assez de questions uniques, ajouter des questions par défaut
    if (questions.length < 5) {
      final defaultQuestions = _getDefaultQuestions();
      for (var question in defaultQuestions) {
        if (!usedQuestions.contains(question['question']) && questions.length < 10) {
          questions.add(question);
          usedQuestions.add(question['question']);
        }
      }
    }
    
    // Mélanger et limiter à 10 questions
    questions.shuffle();
    final finalQuestions = questions.take(10).toList();
    
    // Convertir en QuizQuestion
    _questions = finalQuestions.map((q) => QuizQuestion(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}_${q.hashCode}',
      question: q['question'],
      options: q['options'],
      correctAnswerIndex: q['correct'],
      explanation: q['explanation'],
      difficulty: 'medium',
      category: 'comprehension',
      passageReference: q['passage'],
    )).toList();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _createQuestionsFromPassage(String passageRef, String passageText) {
    List<Map<String, dynamic>> questions = [];
    
    // Questions sur les personnages et contextes - une seule question par passage
    if (passageRef.contains('Jean') && passageText.contains('Consolateur')) {
      questions.add({
        'question': 'Dans Jean 14, qui est le "Consolateur" promis par Jésus ?',
        'options': ['Le Saint-Esprit', 'Un ange', 'Un prophète', 'Un disciple'],
        'correct': 0,
        'explanation': 'Jésus promet l\'envoi du Saint-Esprit comme Consolateur (Jean 14:16)',
        'passage': passageRef,
      });
    } else if (passageRef.contains('Jean') && passageText.contains('chemin')) {
      questions.add({
        'question': 'Quel verset parallèle à Jean 14:6 ("Je suis le chemin, la vérité, la vie") se trouve dans l\'Ancien Testament ?',
        'options': ['Psaume 23:1', 'Proverbes 3:5-6', 'Ésaïe 26:3', 'Jérémie 29:11'],
        'correct': 1,
        'explanation': 'Proverbes 3:5-6 parle de confier son chemin à l\'Éternel, parallèle au concept de Jésus comme chemin',
        'passage': passageRef,
      });
    }
    
    if (passageRef.contains('Matthieu') && passageText.contains('bienheureux')) {
      questions.add({
        'question': 'Dans les Béatitudes, qui sont appelés "bienheureux" ?',
        'options': ['Les riches', 'Les pauvres en esprit', 'Les puissants', 'Les savants'],
        'correct': 1,
        'explanation': 'Jésus dit "Heureux les pauvres en esprit, car le royaume des cieux est à eux" (Matthieu 5:3)',
        'passage': passageRef,
      });
    } else if (passageRef.contains('Matthieu') && passageText.contains('royaume')) {
      questions.add({
        'question': 'Quel passage de l\'Ancien Testament fait écho aux Béatitudes de Matthieu 5 ?',
        'options': ['Psaume 1:1-3', 'Ésaïe 61:1-3', 'Jérémie 17:7-8', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Tous ces passages de l\'AT préfigurent les Béatitudes : Psaume 1 (bienheureux), Ésaïe 61 (consolation), Jérémie 17 (confiance)',
        'passage': passageRef,
      });
    }
    
    // Questions sur les thèmes et sujets de prière - une seule par thème
    if (passageText.contains('amour') && !passageText.contains('charité')) {
      questions.add({
        'question': 'Quel est le plus grand commandement selon Jésus ?',
        'options': ['Aimer Dieu', 'Aimer son prochain', 'Aimer Dieu et son prochain', 'Obéir aux lois'],
        'correct': 2,
        'explanation': 'Jésus dit que le plus grand commandement est d\'aimer Dieu et son prochain (Matthieu 22:37-39)',
        'passage': passageRef,
      });
    } else if (passageText.contains('charité')) {
      questions.add({
        'question': 'Si vous priez pour "l\'amour fraternel", quel verset biblique vous inspire le plus ?',
        'options': ['1 Corinthiens 13:4-7', 'Jean 13:34-35', '1 Jean 4:7-8', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Tous ces versets parlent de l\'amour : 1 Cor 13 (définition), Jean 13 (nouveau commandement), 1 Jean 4 (amour de Dieu)',
        'passage': passageRef,
      });
    }
    
    if (passageText.contains('paix') && !passageText.contains('shalom')) {
      questions.add({
        'question': 'Quel verset biblique est le plus approprié pour prier pour la paix ?',
        'options': ['Jean 14:27', 'Philippiens 4:7', 'Ésaïe 26:3', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Tous ces versets parlent de paix : Jean 14:27 (paix de Jésus), Phil 4:7 (paix de Dieu), Ésaïe 26:3 (paix parfaite)',
        'passage': passageRef,
      });
    }
    
    if (passageText.contains('foi') && !passageText.contains('croire')) {
      questions.add({
        'question': 'Quel passage biblique illustre le mieux la prière pour la foi ?',
        'options': ['Hébreux 11:1', 'Marc 9:24', 'Luc 17:5-6', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Hébreux 11:1 (définition de la foi), Marc 9:24 (aide mon incrédulité), Luc 17:5-6 (augmente notre foi)',
        'passage': passageRef,
      });
    }
    
    if (passageText.contains('sagesse') && !passageText.contains('intelligence')) {
      questions.add({
        'question': 'Pour prier pour la sagesse, quel livre biblique est le plus approprié ?',
        'options': ['Proverbes', 'Jacques 1:5', '1 Rois 3:9-12', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Proverbes (sagesse pratique), Jacques 1:5 (demander la sagesse), 1 Rois 3 (prière de Salomon)',
        'passage': passageRef,
      });
    }
    
    // Questions sur les promesses et sujets de prière
    if (passageText.contains('promesse') && !passageText.contains('alliance')) {
      questions.add({
        'question': 'Quelle promesse biblique est la plus appropriée pour prier dans l\'épreuve ?',
        'options': ['Jérémie 29:11', 'Romains 8:28', '2 Corinthiens 12:9', 'Toutes les précédentes'],
        'correct': 3,
        'explanation': 'Jérémie 29:11 (plans de paix), Romains 8:28 (tout concourt au bien), 2 Cor 12:9 (grâce suffisante)',
        'passage': passageRef,
      });
    }
    
    return questions;
  }

  List<Map<String, dynamic>> _getDefaultQuestions() {
    return [
      {
        'question': 'Qui a écrit la plupart des épîtres du Nouveau Testament ?',
        'options': ['Pierre', 'Paul', 'Jean', 'Jacques'],
        'correct': 1,
        'explanation': 'L\'apôtre Paul a écrit la majorité des épîtres du Nouveau Testament',
        'passage': 'Général',
      },
      {
        'question': 'Dans quel livre de la Bible trouve-t-on l\'histoire de David et Goliath ?',
        'options': ['Exode', '1 Samuel', 'Psaumes', 'Proverbes'],
        'correct': 1,
        'explanation': 'L\'histoire de David et Goliath se trouve dans 1 Samuel 17',
        'passage': '1 Samuel',
      },
      {
        'question': 'Quel verset parallèle à "Dieu est amour" (1 Jean 4:8) se trouve dans l\'Ancien Testament ?',
        'options': ['Psaume 23:1', 'Exode 34:6', 'Proverbes 3:5', 'Ésaïe 40:31'],
        'correct': 1,
        'explanation': 'Exode 34:6 décrit l\'Éternel comme "miséricordieux et compatissant, lent à la colère, riche en bonté"',
        'passage': '1 Jean / Exode',
      },
      {
        'question': 'Pour prier pour la guérison, quel verset biblique est le plus approprié ?',
        'options': ['Jérémie 30:17', 'Jacques 5:16', 'Psaume 103:3', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Jérémie 30:17 (guérison promise), Jacques 5:16 (prière efficace), Psaume 103:3 (guérison divine)',
        'passage': 'Sujets de prière',
      },
      {
        'question': 'Quel passage biblique fait écho à "Cherchez d\'abord le royaume de Dieu" (Matthieu 6:33) ?',
        'options': ['Proverbes 3:5-6', 'Psaume 37:4', 'Ésaïe 26:3', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Tous ces versets parlent de prioriser Dieu : Proverbes 3 (confiance), Psaume 37 (délice en l\'Éternel), Ésaïe 26 (pensée fixée)',
        'passage': 'Matthieu / Parallèles',
      },
      {
        'question': 'Si vous priez pour la protection, quel verset vous inspire le plus ?',
        'options': ['Psaume 91:1-2', 'Proverbes 18:10', 'Ésaïe 41:10', 'Tous les précédents'],
        'correct': 3,
        'explanation': 'Psaume 91 (refuge), Proverbes 18:10 (nom de l\'Éternel), Ésaïe 41:10 (ne crains pas)',
        'passage': 'Sujets de prière',
      },
    ];
  }

  /// 🚀 Démarre le quiz intelligent
  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _currentQuestionIndex = 0;
      _score = 0;
      _userAnswers = [];
      _quizStartTime = DateTime.now();
    });
  }

  /// 🎯 Sélectionne une réponse et l'analyse
  void _selectAnswer(int index) async {
    if (_currentQuestionIndex >= _questions.length) return;
    
    final question = _questions[_currentQuestionIndex];
    final isCorrect = question.isCorrectAnswer(index);
    
    setState(() {
      _selectedAnswer = question.options[index];
      _showResult = true;
      _userAnswers.add(index);
      
      if (isCorrect) {
        _score++;
      }
    });

    // Enregistrer la réponse pour l'analyse cognitive
    // Note: La méthode recordResponse sera implémentée dans une version future
    print('🧠 Apôtre: Réponse enregistrée - Question: ${question.id}, Correct: $isCorrect');
  }

  /// 🧠 Estime l'effort cognitif basé sur la difficulté et le temps
  double _estimateCognitiveEffort(QuizQuestion question, int selectedIndex) {
    double baseEffort = 0.5;
    
    // Ajuster selon la difficulté
    switch (question.difficulty) {
      case 'easy':
        baseEffort = 0.3;
        break;
      case 'medium':
        baseEffort = 0.6;
        break;
      case 'hard':
        baseEffort = 0.8;
        break;
    }
    
    // Ajuster selon la catégorie
    switch (question.category) {
      case 'comprehension':
        baseEffort *= 0.8;
        break;
      case 'application':
        baseEffort *= 1.2;
        break;
      case 'analysis':
        baseEffort *= 1.4;
        break;
      case 'synthesis':
        baseEffort *= 1.6;
        break;
    }
    
    return baseEffort.clamp(0.0, 1.0);
  }

  /// ➡️ Passe à la question suivante
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    } else {
      _completeQuiz();
    }
  }

  /// 🏁 Finalise le quiz et enregistre les résultats
  Future<void> _completeQuiz() async {
    final timeSpent = DateTime.now().difference(_quizStartTime);
    final percentage = (_score / _questions.length) * 100;
    
    // Enregistrer le score pour la difficulté adaptative
    await _recordQuizScore(percentage / 100);
    
    // Créer le résultat du quiz
    final result = QuizResult(
      quizId: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      questions: _questions,
      userAnswers: _userAnswers,
      score: _score,
      percentage: percentage,
      timeSpent: timeSpent,
      completedAt: DateTime.now(),
      analytics: {
        'cognitive_load': _calculateAverageCognitiveLoad(),
        'difficulty_progression': _analyzeDifficultyProgression(),
        'learning_style': _detectLearningStyle(),
      },
    );

    // Enregistrer le résultat dans le service intelligent
    // Note: La méthode saveQuizResult sera implémentée dans une version future
    print('🧠 Apôtre: Résultat du quiz enregistré - Score: ${percentage.toInt()}%');
    print('📊 Analytics: Charge cognitive: ${result.analytics?['cognitive_load']?.toStringAsFixed(2) ?? 'N/A'}');
    print('🎯 Style d\'apprentissage détecté: ${result.analytics?['learning_style'] ?? 'N/A'}');

    setState(() {
      _quizCompleted = true;
    });
  }

  /// 🧮 Calcule la charge cognitive moyenne
  double _calculateAverageCognitiveLoad() {
    if (_questions.isEmpty) return 0.0;
    
    double totalLoad = 0.0;
    for (int i = 0; i < _questions.length && i < _userAnswers.length; i++) {
      totalLoad += _estimateCognitiveEffort(_questions[i], _userAnswers[i]);
    }
    return totalLoad / _questions.length;
  }

  /// 📈 Analyse la progression de difficulté
  List<String> _analyzeDifficultyProgression() {
    return _questions.map((q) => q.difficulty).toList();
  }

  /// 🎯 Détecte le style d'apprentissage
  String _detectLearningStyle() {
    // Analyse basée sur les types de questions et les performances
    int comprehension = 0, application = 0, analysis = 0, synthesis = 0;
    
    for (int i = 0; i < _questions.length && i < _userAnswers.length; i++) {
      final question = _questions[i];
      final isCorrect = question.isCorrectAnswer(_userAnswers[i]);
      
      if (isCorrect) {
        switch (question.category) {
          case 'comprehension':
            comprehension++;
            break;
          case 'application':
            application++;
            break;
          case 'analysis':
            analysis++;
            break;
          case 'synthesis':
            synthesis++;
            break;
        }
      }
    }
    
    // Déterminer le style dominant
    final max = [comprehension, application, analysis, synthesis].reduce((a, b) => a > b ? a : b);
    if (max == comprehension) return 'comprehension';
    if (max == application) return 'application';
    if (max == analysis) return 'analysis';
    return 'synthesis';
  }

  /// 🔄 Redémarre le quiz
  void _restartQuiz() {
    setState(() {
      _quizStarted = false;
      _quizCompleted = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _showResult = false;
    });
    _generateIntelligentQuestions();
  }


  /// 📖 Récupère le texte d'un passage biblique
  Future<String?> _getPassageText(String passageRef) async {
    try {
      // Utiliser le service de texte biblique existant
      final text = await BibleTextService.getPassageText(passageRef);
      return text;
    } catch (e) {
      print('⚠️ Erreur récupération texte: $e');
      return null;
    }
  }

  /// 📅 Calcule l'index du jour actuel dans le plan
  int _calculateCurrentDayIndex(activePlan) {
    final today = DateTime.now();
    final startDate = activePlan.startDate;
    
    // Normaliser les dates à minuit pour comparer les jours calendaires
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final startNormalized = DateTime(startDate.year, startDate.month, startDate.day);
    
    final dayIndex = todayNormalized.difference(startNormalized).inDays + 1;
    return dayIndex;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Dessins abstraits en arrière-plan
            _buildAbstractBackground(),
            
            // Contenu principal
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Header avec style Selah
                        _buildSelahHeader(),
                        
                        const SizedBox(height: 24),
                        
                        // Content
                        Expanded(
                          child: _buildContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingScreen();
    } else if (!_quizStarted) {
      return _buildStartScreen();
    } else if (_quizCompleted) {
      return _buildResultsScreen();
    } else {
      return _buildQuestionScreen();
    }
  }

  /// 🔄 Écran de chargement pendant la génération des questions
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation de chargement
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.3),
                  const Color(0xFFF59E0B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Titre
          Text(
            '🧠 Apôtre en action',
            style: GoogleFonts.inter(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            'Génération de questions intelligentes\nbasées sur votre historique de méditation...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Analyse cognitive en cours...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icône
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.quiz,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'Quiz Biblique Avancé',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Testez vos connaissances bibliques avec des questions intelligentes basées sur vos lectures précédentes.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Vos lectures',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_journalEntries.length} passages lus',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_questions.length} questions générées',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Start button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _questions.isNotEmpty ? _startQuiz : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
            child: Text(
              _questions.isNotEmpty ? 'Commencer le Quiz' : 'Pas assez de données',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionScreen() {
    final question = _questions[_currentQuestionIndex];
    
    return Column(
      children: [
        // Progress avec informations intelligentes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                // Badge de difficulté et catégorie
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: question.difficultyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: question.difficultyColor, width: 1),
                      ),
                      child: Text(
                        question.difficultyName,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: question.difficultyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(question.categoryIcon, size: 12, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            question.categoryName,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'Score: $_score',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Progress bar
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
        ),
        
        const SizedBox(height: 32),
        
        // Question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.question,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (question.passageReference != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        question.passageReference!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (question.verseText != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    '"${question.verseText}"',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Référence: ${question.passageReference ?? 'Général'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Options
        Expanded(
          child: ListView.builder(
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = _selectedAnswer == option;
              final isCorrect = question.isCorrectAnswer(index);
              
              Color backgroundColor = Colors.white.withOpacity(0.1);
              Color borderColor = Colors.white.withOpacity(0.2);
              
              if (_showResult) {
                if (isCorrect) {
                  backgroundColor = const Color(0xFF10B981).withOpacity(0.2);
                  borderColor = const Color(0xFF10B981);
                } else if (isSelected && !isCorrect) {
                  backgroundColor = const Color(0xFFEF4444).withOpacity(0.2);
                  borderColor = const Color(0xFFEF4444);
                }
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: _showResult ? null : () => _selectAnswer(index),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _showResult && isCorrect 
                                ? const Color(0xFF10B981)
                                : _showResult && isSelected && !isCorrect
                                    ? const Color(0xFFEF4444)
                                    : Colors.white.withOpacity(0.2),
                          ),
                          child: _showResult && isCorrect
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : _showResult && isSelected && !isCorrect
                                  ? const Icon(Icons.close, size: 16, color: Colors.white)
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
        
        // Next button
        if (_showResult) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                    Icon(
                      question.isCorrectAnswer(_userAnswers.isNotEmpty ? _userAnswers.last : -1) 
                          ? Icons.check_circle 
                          : Icons.cancel,
                      color: question.isCorrectAnswer(_userAnswers.isNotEmpty ? _userAnswers.last : -1) 
                          ? Colors.green 
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Explication:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.explanation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentQuestionIndex < _questions.length - 1 ? 'Question suivante' : 'Voir les résultats',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsScreen() {
    final percentage = (_score / _questions.length * 100).round();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Score circle
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: percentage >= 70 
                  ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                  : percentage >= 50
                      ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                      : [const Color(0xFFEF4444), const Color(0xFFF87171)],
            ),
            boxShadow: [
              BoxShadow(
                color: (percentage >= 70 
                    ? const Color(0xFF10B981)
                    : percentage >= 50
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444)).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$_score/${_questions.length}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        Text(
          _getScoreMessage(percentage),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          _getScoreDescription(percentage),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _restartQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
                child: Text(
                  'Recommencer',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Terminer',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getScoreMessage(int percentage) {
    if (percentage >= 90) return 'Excellent !';
    if (percentage >= 80) return 'Très bien !';
    if (percentage >= 70) return 'Bien !';
    if (percentage >= 50) return 'Pas mal !';
    return 'Continuez à lire !';
  }

  String _getScoreDescription(int percentage) {
    if (percentage >= 90) return 'Vos connaissances bibliques sont remarquables !';
    if (percentage >= 80) return 'Vous avez une très bonne compréhension des Écritures.';
    if (percentage >= 70) return 'Bonne maîtrise des passages que vous avez lus.';
    if (percentage >= 50) return 'Continuez à méditer sur les passages pour approfondir.';
    return 'Lisez plus régulièrement pour améliorer vos connaissances.';
  }

  /// Enregistre le score du quiz pour la difficulté adaptative
  Future<void> _recordQuizScore(double score) async {
    try {
      await AdaptiveDifficultyService.recordScore('user_${DateTime.now().millisecondsSinceEpoch}', score);
      print('📊 Score enregistré: ${(score * 100).toStringAsFixed(1)}%');
    } catch (e) {
      print('⚠️ Erreur enregistrement score: $e');
    }
  }

  /// 🎨 Dessins abstraits en arrière-plan (style Selah/Calm)
  Widget _buildAbstractBackground() {
    return Stack(
      children: [
        // Formes géométriques flottantes
        Positioned(
          top: 100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        Positioned(
          bottom: 200,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.08),
                  const Color(0xFF059669).withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        Positioned(
          top: 300,
          left: 50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.06),
                  const Color(0xFFFBBF24).withOpacity(0.03),
                ],
              ),
            ),
          ),
        ),
        
        // Lignes organiques
        Positioned(
          top: 150,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 200),
            painter: OrganicLinesPainter(),
          ),
        ),
        
        // Particules flottantes
        ...List.generate(8, (index) => _buildFloatingParticle(index)),
      ],
    );
  }

  /// ✨ Particule flottante individuelle
  Widget _buildFloatingParticle(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    
    final positions = [
      const Offset(50, 200),
      const Offset(300, 150),
      const Offset(100, 400),
      const Offset(250, 350),
      const Offset(80, 500),
      const Offset(320, 450),
      const Offset(150, 300),
      const Offset(280, 250),
    ];
    
    return Positioned(
      left: positions[index].dx,
      top: positions[index].dy,
      child: Container(
        width: 4 + (index % 3) * 2,
        height: 4 + (index % 3) * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[index % colors.length].withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: colors[index % colors.length].withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Header avec style Selah
  Widget _buildSelahHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour avec style Selah
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Titre avec style moderne
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Biblique',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Testez vos connaissances',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Icône de statut
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Peintre pour les lignes organiques
class OrganicLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Ligne organique 1
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.1,
      size.width * 0.6, size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.7,
      size.width, size.height * 0.5,
    );
    
    canvas.drawPath(path, paint);
    
    // Ligne organique 2
    final path2 = Path();
    paint.color = const Color(0xFF10B981).withOpacity(0.08);
    
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.4, size.height * 0.5,
      size.width * 0.7, size.height * 0.8,
    );
    path2.quadraticBezierTo(
      size.width * 0.9, size.height * 0.9,
      size.width, size.height * 0.6,
    );
    
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
