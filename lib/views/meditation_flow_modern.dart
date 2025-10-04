import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:essai/views/meditation_chooser_page.dart';
import 'package:essai/views/meditation_free_page.dart';
import 'package:essai/views/meditation_qcm_page.dart';
import 'package:essai/views/meditation_auto_qcm_page.dart';
import 'package:essai/views/prayer_subjects_page.dart';

class MeditationFlowModern extends StatefulWidget {
  final String? planId;
  final int? day;
  final String? ref;

  const MeditationFlowModern({
    super.key,
    this.planId,
    this.day,
    this.ref,
  });

  @override
  State<MeditationFlowModern> createState() => _MeditationFlowModernState();
}

class _MeditationFlowModernState extends State<MeditationFlowModern>
    with TickerProviderStateMixin {
  int currentStep = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  
  // Données de méditation
  String selectedMode = '';
  List<String> selectedAnswers = [];
  String freeText = '';
  List<String> selectedActions = [];
  String? selectedMeditationType; // 'free', 'qcm', 'auto_qcm'
  
  final List<MeditationStep> _steps = [
    MeditationStep(
      title: 'Introduction',
      subtitle: 'Préparez-vous à méditer',
      type: StepType.intro,
    ),
    MeditationStep(
      title: 'Mode de méditation',
      subtitle: 'Choisissez votre approche',
      type: StepType.mode,
    ),
    MeditationStep(
      title: 'Réflexion',
      subtitle: 'Réfléchissez sur le passage',
      type: StepType.reflection,
    ),
    MeditationStep(
      title: 'Actions',
      subtitle: 'Définissez vos intentions',
      type: StepType.actions,
    ),
    MeditationStep(
      title: 'Résumé',
      subtitle: 'Récapitulatif de votre méditation',
      type: StepType.summary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Si on est à l'étape de sélection du mode, naviguer vers la page appropriée
    if (currentStep == 1 && selectedMode.isNotEmpty) {
      _navigateToMeditationType();
      return;
    }
    
    if (currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishMeditation();
    }
  }
  
  void _navigateToMeditationType() {
    switch (selectedMode) {
      case 'free':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MeditationFreePage(),
          ),
        );
        break;
      case 'qcm':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MeditationQcmPage(),
          ),
        );
        break;
      case 'auto_qcm':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MeditationAutoQcmPage(),
          ),
        );
        break;
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishMeditation() {
    // Sauvegarder les données de méditation
    print('Sauvegarde de la méditation: $selectedMode, $selectedAnswers, $freeText, $selectedActions');
    
    // Naviguer vers la page de prière
    Navigator.pushReplacementNamed(context, '/prayer_workflow');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1740), // Violet foncé
              Color(0xFF5C34D1), // Violet plus clair
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec navigation et progression
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentStep = index;
                    });
                  },
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildStepContent(_steps[index]);
                  },
                ),
              ),
              
              // Bouton de navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Barre de progression
          Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (currentStep + 1) / _steps.length,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Bouton fermer
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(MeditationStep step) {
    switch (step.type) {
      case StepType.intro:
        return _buildIntroStep();
      case StepType.mode:
        return _buildModeStep();
      case StepType.reflection:
        return _buildReflectionStep();
      case StepType.actions:
        return _buildActionsStep();
      case StepType.summary:
        return _buildSummaryStep();
    }
  }

  Widget _buildIntroStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Titre principal
          Text(
            'Méditation',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sous-titre
          Text(
            'Préparez votre cœur à recevoir la Parole de Dieu',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Passage biblique
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passage du jour',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  widget.ref ?? 'Jean 3:16',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildModeStep() {
    final modes = [
      {'id': 'free', 'title': 'Méditation Libre', 'subtitle': 'Réflexion personnelle et spontanée'},
      {'id': 'qcm', 'title': 'Méditation QCM', 'subtitle': 'Questions à choix multiples'},
      {'id': 'auto_qcm', 'title': 'QCM Automatique', 'subtitle': 'Questions générées automatiquement'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Titre
          Text(
            'Comment souhaitez-vous méditer ?',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sous-titre
          Text(
            'Choisissez l\'approche qui vous convient le mieux',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Options de méditation
          ...modes.map((mode) => _buildModeOption(mode)).toList(),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildModeOption(Map<String, String> mode) {
    final isSelected = selectedMode == mode['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMode = mode['id']!;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected 
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icône de sélection
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFF1C1740),
                        size: 16,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode['title']!,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      mode['subtitle']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.4,
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
  }

  Widget _buildReflectionStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Titre
          Text(
            'Réflexion personnelle',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sous-titre
          Text(
            'Prenez un moment pour réfléchir sur ce passage',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Zone de texte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Écrivez vos réflexions ici...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF111827),
                height: 1.5,
              ),
              onChanged: (value) {
                freeText = value;
              },
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildActionsStep() {
    final actions = [
      'Action de grâce',
      'Repentance',
      'Obéissance',
      'Intercession',
      'Foi',
      'Amour',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Titre
          Text(
            'Actions concrètes',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sous-titre
          Text(
            'Sélectionnez les actions que vous souhaitez entreprendre',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Actions
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map((action) => _buildActionChip(action)).toList(),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildActionChip(String action) {
    final isSelected = selectedActions.contains(action);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedActions.remove(action);
          } else {
            selectedActions.add(action);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          action,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? const Color(0xFF1C1740)
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Titre
          Text(
            'Récapitulatif',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sous-titre
          Text(
            'Voici un résumé de votre méditation',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Résumé
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryItem('Mode', selectedMode),
                _buildSummaryItem('Réflexion', freeText.isNotEmpty ? 'Complétée' : 'Non complétée'),
                _buildSummaryItem('Actions', '${selectedActions.length} sélectionnées'),
              ],
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          // Bouton précédent
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Précédent',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          
          if (currentStep > 0) const SizedBox(width: 16),
          
          // Bouton suivant/terminer
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1740),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                currentStep < _steps.length - 1 ? 'Continuer' : 'Terminer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (currentStep) {
      case 0: // Intro
        return true;
      case 1: // Mode
        return selectedMode.isNotEmpty;
      case 2: // Reflection
        return true; // Optionnel
      case 3: // Actions
        return true; // Optionnel
      case 4: // Summary
        return true;
      default:
        return false;
    }
  }
}

// Modèles
class MeditationStep {
  final String title;
  final String subtitle;
  final StepType type;

  MeditationStep({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

enum StepType {
  intro,
  mode,
  reflection,
  actions,
  summary,
}
