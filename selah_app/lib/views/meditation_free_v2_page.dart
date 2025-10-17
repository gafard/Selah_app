import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/intelligent_prayer_generator.dart';
import '../services/user_prefs_hive.dart';
import '../repositories/user_repository.dart';
import '../utils/prayer_subjects_mapper.dart';

class MeditationFreeV2Page extends StatefulWidget {
  final String? passageRef;
  final String? passageText;

  const MeditationFreeV2Page({
    super.key,
    this.passageRef,
    this.passageText,
  });

  @override
  State<MeditationFreeV2Page> createState() => _MeditationFreeV2PageState();
}

class _MeditationFreeV2PageState extends State<MeditationFreeV2Page>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controllers pour les champs de texte
  final _charactersList = TextEditingController();
  final _charactersInventory = TextEditingController();
  final _actions = TextEditingController();
  final _details = TextEditingController();
  final _emotions = TextEditingController();
  final _choices = TextEditingController();
  final _reasons = TextEditingController();
  final _goodActions = TextEditingController();
  final _aboutGod = TextEditingController();
  final _aboutNeighbor = TextEditingController();
  final _convincePast = TextEditingController();
  final _correctToday = TextEditingController();
  final _setDifferent = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _charactersList.dispose();
    _charactersInventory.dispose();
    _actions.dispose();
    _details.dispose();
    _emotions.dispose();
    _choices.dispose();
    _reasons.dispose();
    _goodActions.dispose();
    _aboutGod.dispose();
    _aboutNeighbor.dispose();
    _convincePast.dispose();
    _correctToday.dispose();
    _setDifferent.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentStep = index;
    });
    _progressController.animateTo((index + 1) / _totalSteps);
  }

  // Route finale vers le carrousel (mets le bon path selon ton app)
  static const _kPrayerCarouselRoute = '/prayer';

  Map<String, Set<String>> _buildAnswersForGenerator() {
    // On encode chaque champ texte dans un Set<String>.
    // On force des guillemets pour que _extractFreeTexts() les picke.
    String q(String s) => s.trim().isEmpty ? '' : '"${s.trim()}"';

    return {
      // Étape 1
      'characters_list':      { q(_charactersList.text) }..remove(''),
      'characters_inventory': { q(_charactersInventory.text) }..remove(''),
      'actions':              { q(_actions.text) }..remove(''),
      'details':              { q(_details.text) }..remove(''),
      // Étape 2
      'emotions':             { q(_emotions.text) }..remove(''),
      'choices':              { q(_choices.text) }..remove(''),
      'reasons':              { q(_reasons.text) }..remove(''),
      // Étape 3
      'good_actions':         { q(_goodActions.text) }..remove(''),
      'aboutGod':             { q(_aboutGod.text) }..remove(''),
      'aboutNeighbor':        { q(_aboutNeighbor.text) }..remove(''),
      // Application
      'convincePast':         { q(_convincePast.text) }..remove(''),
      'correctToday':         { q(_correctToday.text) }..remove(''),
      'setDifferent':         { q(_setDifferent.text) }..remove(''),
    };
  }

  /// Détection super légère de thèmes (optionnelle)
  List<String> _detectThemes(String text) {
    final t = text.toLowerCase();
    final out = <String>[];
    if (RegExp(r'\bfamill(e|es)\b|p(è|e)re|m(è|e)re').hasMatch(t)) out.add('family');
    if (t.contains('guérison') || t.contains('maladie') || t.contains('santé')) out.add('healing');
    if (t.contains('amour') || t.contains('charité')) out.add('love');
    if (t.contains('foi') || t.contains('croire')) out.add('faith');
    return out;
  }

  /// Mappe les PrayerIdea en PrayerItem (affichables par le carrousel)
  List<PrayerItem> _ideasToItems(List<PrayerIdea> ideas) {
    // Palette douce façon "post-it"
    final paper = [
      Colors.pink[100]!, Colors.blue[100]!, Colors.green[100]!,
      Colors.yellow[100]!, Colors.orange[100]!, Colors.purple[100]!,
      Colors.cyan[100]!, Colors.lime[100]!,
    ];
    return List.generate(ideas.length, (i) {
      final idea = ideas[i];
      final theme = (idea.tags.isNotEmpty ? idea.tags.join(' · ') : idea.category).toUpperCase();
      // On met le "corps" comme texte principal de la carte (plus utile que le titre).
      return PrayerItem(
        theme: theme,
        subject: idea.body,
        color: paper[i % paper.length],
        validated: false,
        notes: '', // l'utilisateur pourra écrire son propre "Ce que Dieu me dit…"
      );
    });
  }

  void _finish() {
    // 1) Construire le "answers" pour le générateur (tags/textes libres)
    final answers = _buildAnswersForGenerator();

    // 2) Profils utilisateur (mets tes vraies données si tu les as)
    final userProfile = <String, dynamic>{
      'level': (/* ex: user.level */ 'Fidèle régulier'),
      'goal': (/* ex: user.goal */ 'Discipline quotidienne'),
      'durationMin': (/* ex: prefs.duration */ 15),
    };

    // 3) Contexte de génération (avec détection simple de thèmes)
    final ctx = PrayerContext.fromMeditation(
      userProfile: userProfile,
      passageText: widget.passageText ?? '',
      passageRef: widget.passageRef ?? '',
      answers: answers,
      detectedThemes: _detectThemes(widget.passageText ?? ''),
      currentDate: DateTime.now(),
    );

    // 4) Générer les idées de prière intelligentes
    final ideas = IntelligentPrayerGenerator.generate(ctx);

    // 5) Mapper en PrayerItem pour le carrousel
    final items = _ideasToItems(ideas);

    // 6) Naviguer directement vers le carrousel (sans passer par /prayer_subjects)
    context.go(_kPrayerCarouselRoute, extra: {
      'items': items,
      'memoryVerse': '',                 // tu peux le remplir plus tard
      'passageRef': widget.passageRef,
      'passageText': widget.passageText,
      'selectedTagsByField': answers,    // utile plus tard pour verse/poster si besoin
      'selectedAnswersByField': answers, // compat avec QCM (même shape Set<String>)
      'freeTextResponses': const <String, String>{},
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
            colors: [
              Color(0xFF1C1740),
              Color(0xFF2D1B69),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec navigation
              _buildHeader(),
              
              // Progress bar
              _buildProgressBar(),
              
              // PageView avec les étapes
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Méditation Libre',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48), // Pour centrer le titre
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Pills de progression
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCompleted 
                    ? Colors.white 
                    : isActive 
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          
          // Barre de progression linéaire
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _StepCard(
      title: 'Demander',
      subtitle: 'Qui sont les personnages ? Que font-ils ?',
      children: [
        _FreeFieldDark(
          label: 'Personnages du passage',
          controller: _charactersList,
          hint: 'Jésus, les disciples, la foule...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Inventaire des objets/éléments',
          controller: _charactersInventory,
          hint: 'Pain, poissons, paniers, bateau...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Actions principales',
          controller: _actions,
          hint: 'Multiplier, bénir, distribuer...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Détails importants',
          controller: _details,
          hint: '5 pains, 2 poissons, 5000 hommes...',
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return _StepCard(
      title: 'Chercher',
      subtitle: 'Quelles émotions ? Quels choix ?',
      children: [
        _FreeFieldDark(
          label: 'Émotions ressenties',
          controller: _emotions,
          hint: 'Émerveillement, gratitude, surprise...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Choix et alternatives',
          controller: _choices,
          hint: 'Renvoyer la foule vs nourrir, garder vs partager...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Raisons et motivations',
          controller: _reasons,
          hint: 'Compassion, obéissance, amour...',
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return _StepCard(
      title: 'Frapper',
      subtitle: 'Quelles bonnes actions ? Quels enseignements ?',
      children: [
        _FreeFieldDark(
          label: 'Bonnes actions à imiter',
          controller: _goodActions,
          hint: 'Partager, bénir, servir, avoir compassion...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Enseignement sur Dieu',
          controller: _aboutGod,
          hint: 'Dieu pourvoit, Dieu multiplie, Dieu bénit...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Enseignement sur le prochain',
          controller: _aboutNeighbor,
          hint: 'Aimer, servir, partager, être généreux...',
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return _StepCard(
      title: 'Application',
      subtitle: 'Comment appliquer ce passage ?',
      children: [
        _FreeFieldDark(
          label: 'Convaincre (passé)',
          controller: _convincePast,
          hint: 'Ce que Dieu a fait dans ma vie...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Corriger (aujourd\'hui)',
          controller: _correctToday,
          hint: 'Ce que je dois changer maintenant...',
        ),
        const SizedBox(height: 16),
        _FreeFieldDark(
          label: 'Instruire (dispositions)',
          controller: _setDifferent,
          hint: 'Comment je veux grandir...',
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                child: Text(
                  'Étape précédente',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 12),
          
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 ? _finish : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1740),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 
                  ? 'Proposer des sujets de prière'
                  : 'Étape suivante',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Champs de l'étape
          ...children,
        ],
      ),
    );
  }
}

class _FreeFieldDark extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _FreeFieldDark({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
