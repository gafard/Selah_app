import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:essai/views/meditation_chooser_page.dart';
import 'package:essai/views/meditation_free_page.dart';
import 'package:essai/views/meditation_qcm_page.dart';
import 'package:essai/views/meditation_auto_qcm_page.dart';
import 'package:essai/views/prayer_subjects_page.dart';

class MeditationFlowPage extends StatefulWidget {
  final String? planId;
  final int? day;
  final String? ref;

  const MeditationFlowPage({
    super.key,
    this.planId,
    this.day,
    this.ref,
  });

  @override
  State<MeditationFlowPage> createState() => _MeditationFlowPageState();
}

class _MeditationFlowPageState extends State<MeditationFlowPage>
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
    // Sauvegarder la méditation
    _saveMeditation();
    
    // Naviguer vers la prière
    Navigator.pushNamed(
      context,
      '/prayer_workflow',
      arguments: {
        'meditationData': {
          'mode': selectedMode,
          'answers': selectedAnswers,
          'freeText': freeText,
          'actions': selectedActions,
        },
      },
    );
  }

  void _saveMeditation() {
    // Ici vous pouvez sauvegarder dans Supabase
    print('Sauvegarde de la méditation: $selectedMode, $selectedAnswers, $freeText, $selectedActions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1740),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec progression
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
            
            // Navigation
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Bouton retour et progression
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${currentStep + 1}/${_steps.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Barre de progression
          Container(
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
          Text(
            'Méditation',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
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
                Text(
                  'Bienvenue dans votre temps de méditation',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Prenez un moment pour vous détendre et vous préparer à méditer sur la Parole de Dieu.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (widget.ref != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
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
                          widget.ref!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
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
          Text(
            'Mode de méditation',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
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
                Text(
                  'Choisissez votre approche de méditation',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                ...modes.map((mode) => _buildModeOption(mode)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(Map<String, String> mode) {
    final isSelected = selectedMode == mode['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedMode = mode['id']!;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode['title']!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['subtitle']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
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
          Text(
            'Réflexion',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
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
                Text(
                  'Partagez vos pensées sur ce passage',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  maxLines: 8,
                  onChanged: (value) {
                    setState(() {
                      freeText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Écrivez vos réflexions ici...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ],
            ),
          ),
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
      'Louange',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
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
                Text(
                  'Quelles actions souhaitez-vous entreprendre ?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: actions.map((action) => _buildActionChip(action)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String action) {
    final isSelected = selectedActions.contains(action);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedActions.remove(action);
          } else {
            selectedActions.add(action);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          action,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
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
          Text(
            'Résumé',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
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
                Text(
                  'Récapitulatif de votre méditation',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildSummaryItem('Mode', _getModeTitle(selectedMode)),
                _buildSummaryItem('Réflexion', freeText.isNotEmpty ? 'Rédigée' : 'Non rédigée'),
                _buildSummaryItem('Actions', '${selectedActions.length} sélectionnées'),
                
                if (selectedActions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Actions choisies:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedActions.map((action) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        action,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  String _getModeTitle(String modeId) {
    switch (modeId) {
      case 'guided':
        return 'Méditation Guidée';
      case 'free':
        return 'Méditation Libre';
      case 'qcm':
        return 'Méditation QCM';
      default:
        return 'Non sélectionné';
    }
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Précédent',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          
          if (currentStep > 0) const SizedBox(width: 16),
          
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
