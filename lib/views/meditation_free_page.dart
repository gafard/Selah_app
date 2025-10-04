import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/prayer_subjects_builder.dart';
import 'prayer_carousel_page.dart';

class MeditationFreePage extends StatefulWidget {
  final String passageRef;
  final String passageText;

  const MeditationFreePage({
    super.key,
    required this.passageRef,
    required this.passageText,
  });

  @override
  State<MeditationFreePage> createState() => _MeditationFreePageState();
}

class _MeditationFreePageState extends State<MeditationFreePage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Contrôleurs pour toutes les questions
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Étape 1 - Demander
    _controllers['personnages_liste'] = TextEditingController();
    _controllers['personnages_inventaire'] = TextEditingController();
    _controllers['actions'] = TextEditingController();
    _controllers['details'] = TextEditingController();

    // Étape 2 - Chercher
    _controllers['emotions'] = TextEditingController();
    _controllers['choix_alternatives'] = TextEditingController();
    _controllers['raisons_choix'] = TextEditingController();

    // Étape 3 - Frapper
    _controllers['bonnes_actions'] = TextEditingController();
    _controllers['enseignements_dieu'] = TextEditingController();
    _controllers['enseignements_prochain'] = TextEditingController();

    // Application
    _controllers['convictions_passe'] = TextEditingController();
    _controllers['corrections'] = TextEditingController();
    _controllers['dispositions'] = TextEditingController();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() async {
    // Collecter toutes les réponses
    final Map<String, String> allAnswers = {};
    for (var entry in _controllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        allAnswers[entry.key] = entry.value.text.trim();
      }
    }

    // Générer les sujets de prière à partir des réponses
    final subjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: {},
      freeTexts: allAnswers,
    );

    // Extraire les labels des sujets pour les passer à la page de workflow
    final subjectLabels = subjects.map((s) => s.label).toList();

    // Naviguer vers la page de workflow de prière avec les sujets
    final result = await Navigator.pushNamed(
      context,
      '/prayer_workflow',
      arguments: {
        'subjects': subjectLabels,
      },
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildApplication(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Méditation Libre',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.passageRef,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index <= _currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Étape 1 : L\'Étape du Demander'),
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'a - Quels sont les personnages du texte?',
            [
              _buildQuestionField('Liste des personnages', 'personnages_liste'),
              _buildQuestionField('Inventaire des personnages', 'personnages_inventaire'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'b - Quelles sont les actions effectuées dans le passage?',
            [
              _buildQuestionField('Actions', 'actions'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'c - Quels sont les détails particuliers?',
            [
              _buildQuestionField('Détails', 'details'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Étape 2 : L\'Étape du Chercher'),
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'a - Quelles seraient les émotions des personnages de l\'histoire?',
            [
              _buildQuestionField('Émotions des personnages', 'emotions'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'b - Quels sont les choix et les alternatives?',
            [
              _buildQuestionField('Choix et alternatives', 'choix_alternatives'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'c - Quelles sont les raisons de ces choix?',
            [
              _buildQuestionField('Raisons des choix', 'raisons_choix'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Étape 3 : L\'Étape du Frapper'),
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'a - Quelles sont les bonnes actions?',
            [
              _buildQuestionField('Bonnes actions', 'bonnes_actions'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'b - Qu\'est-ce que cette histoire m\'enseigne à propos de Dieu?',
            [
              _buildQuestionField('Enseignements sur Dieu', 'enseignements_dieu'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            'c - Qu\'est-ce que cette histoire m\'enseigne à faire à propos de mon prochain?',
            [
              _buildQuestionField('Enseignements sur le prochain', 'enseignements_prochain'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplication() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Comment Appliquer?'),
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            '1 - Convaincre : Le passage me dit quoi par rapport à mon passé?',
            [
              _buildQuestionField('Convictions par rapport au passé', 'convictions_passe'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            '2 - Corriger : Corriger l\'aspect de ma vie dont parle le passage. Le corriger aujourd\'hui même.',
            [
              _buildQuestionField('Corrections à apporter', 'corrections'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildQuestionSection(
            '3 - Instruire : Prendre des dispositions pour le faire autrement.',
            [
              _buildQuestionField('Dispositions à prendre', 'dispositions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuestionSection(String question, List<Widget> fields) {
    return Container(
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
          Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildQuestionField(String label, String controllerKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $label :',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _controllers[controllerKey],
              maxLines: 3,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Votre réponse...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Précédent',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _currentStep == 3 ? _finish : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1740),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 3 ? 'Continuer vers la prière' : 'Suivant',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}