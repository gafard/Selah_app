import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'prayer_carousel_page.dart';
import '../utils/prayer_subjects_mapper.dart';
import '../widgets/uniform_back_button.dart';

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
  final Map<String, Set<String>> _selectedTagsByField = {}; // fieldId -> selected tags

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

    // Initialiser les sets de tags pour chaque champ
    for (final key in _controllers.keys) {
      _selectedTagsByField[key] = <String>{};
    }
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

  void _finish() {
    // Extraire des tags à partir des réponses textuelles
    _extractTagsFromText();
    
    // Collecter les réponses écrites pour chaque champ
    final selectedAnswersByField = <String, Set<String>>{};
    final freeTextResponses = <String, String>{};
    
    // Initialiser les maps pour tous les champs
    for (final field in _selectedTagsByField.keys) {
      selectedAnswersByField[field] = <String>{};
      freeTextResponses[field] = '';
    }
    
    // Collecter les réponses écrites depuis les TextField
    _controllers.forEach((fieldId, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        freeTextResponses[fieldId] = text;
      }
    });
    
    print('🔍 RÉPONSES DE MÉDITATION LIBRE:');
    _selectedTagsByField.forEach((field, tags) {
      print('🔍 $field - Tags: $tags');
      print('🔍 $field - Réponse écrite: "${freeTextResponses[field]}"');
    });

    // Utiliser la nouvelle fonction de synthèse intelligente
    final items = buildPrayerItemsFromMeditation(
      selectedTagsByField: _selectedTagsByField,
      selectedAnswersByField: selectedAnswersByField,
      freeTextResponses: freeTextResponses,
      passageText: widget.passageText,
      passageRef: widget.passageRef,
    );
    
    print('🔍 SUJETS DE PRIÈRE GÉNÉRÉS: ${items.length}');
    for (int i = 0; i < items.length; i++) {
      print('🔍 Item $i: ${items[i].theme} - ${items[i].subject}');
    }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrayerCarouselPage(),
                settings: RouteSettings(arguments: {
                  'items': items,
                  'memoryVerse': '', // Sera rempli par le bottom sheet
                  'passageRef': widget.passageRef,
                  'passageText': widget.passageText,
                  'selectedTagsByField': _selectedTagsByField,
                  'selectedAnswersByField': selectedAnswersByField,
                  'freeTextResponses': freeTextResponses,
                }),
              ),
            );
  }

  void _extractTagsFromText() {
    // Analyser le texte saisi pour extraire des tags pertinents
    _controllers.forEach((fieldId, controller) {
      final text = controller.text.toLowerCase().trim();
      if (text.isNotEmpty) {
        final tags = <String>{};
        
        // Analyser le contenu du texte pour extraire des tags
        if (text.contains('dieu') || text.contains('seigneur') || text.contains('jésus')) {
          tags.add('praise');
        }
        if (text.contains('merci') || text.contains('gratitude') || text.contains('reconnaissant')) {
          tags.add('gratitude');
        }
        if (text.contains('pardon') || text.contains('repentir') || text.contains('péché')) {
          tags.add('repentance');
        }
        if (text.contains('aide') || text.contains('force') || text.contains('soutien')) {
          tags.add('trust');
        }
        if (text.contains('sagesse') || text.contains('comprendre') || text.contains('connaissance')) {
          tags.add('guidance');
        }
        if (text.contains('famille') || text.contains('amis') || text.contains('prochain')) {
          tags.add('intercession');
        }
        if (text.contains('obéir') || text.contains('suivre') || text.contains('commande')) {
          tags.add('obedience');
        }
        if (text.contains('promesse') || text.contains('bénédiction') || text.contains('espoir')) {
          tags.add('promise');
        }
        if (text.contains('avertissement') || text.contains('attention') || text.contains('danger')) {
          tags.add('warning');
        }
        if (text.contains('responsabilité') || text.contains('devoir') || text.contains('mission')) {
          tags.add('responsibility');
        }
        if (text.contains('crainte') || text.contains('respect') || text.contains('majesté')) {
          tags.add('awe');
        }
        
        // Ajouter les tags extraits
        _selectedTagsByField[fieldId]!.addAll(tags);
      }
    });
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
    return Column(
      children: [
        UniformHeader(
          title: 'Méditation Libre',
          subtitle: widget.passageRef,
          onBackPressed: () => Navigator.pop(context),
          textColor: Colors.white,
          iconColor: Colors.white,
          titleAlignment: CrossAxisAlignment.center,
        ),
        const SizedBox(height: 20),
        _buildProgressIndicator(),
      ],
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
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableInteractiveSelection: true,
              autocorrect: false,
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