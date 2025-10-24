import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../utils/prayer_subjects_mapper.dart';
import '../services/prayer_subjects_builder.dart';
import '../services/semantic_passage_boundary_service_v2.dart';

class MeditationQcmPage extends StatefulWidget {
  final String? passageRef;
  final String? passageText;
  const MeditationQcmPage({super.key, this.passageRef, this.passageText});

  @override
  State<MeditationQcmPage> createState() => _MeditationQcmPageState();
}

class _MeditationQcmPageState extends State<MeditationQcmPage> {
  final Map<String, Set<String>> _answers = {}; // questionId -> selected options
  final Map<String, TextEditingController> _freeByQuestion = {};
  final Map<String, Set<String>> _selectedTagsByField = {}; // questionId -> selected tags

  // Les questions avec leurs options générées intelligemment
  late List<Map<String, dynamic>> _questions = [];
  final Map<String, Map<String, List<String>>> _tagsIndex = {};
  String? _lastKey;



  static const _fallbackDemo = '''
Jésus se rendit en Samarie... "Donne-moi à boire" ... "il t'aurait donné de l'eau vive".
  ''';

  @override
  void initState() {
    super.initState();
    print('🔍 INITSTATE - passageRef: ${widget.passageRef}');
    print('🔍 INITSTATE - passageText: ${widget.passageText?.length} caractères');
    _hydrate();
  }

  // Navigation sécurisée avec conservation des paramètres
  void _safeGoBack() {
    if (!mounted) return;
    final st = GoRouterState.of(context);
    final extra = (st.extra as Map<String, dynamic>?) ?? const {};
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/meditation/chooser', extra: {
        'passageRef': extra['passageRef'],
        'passageText': extra['passageText'],
        'dayTitle': extra['dayTitle'],
        'planId': extra['planId'],
        'dayNumber': extra['dayNumber'],
      });
    }
  }

  @override
  void didUpdateWidget(covariant MeditationQcmPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passageRef != widget.passageRef ||
        oldWidget.passageText != widget.passageText) {
      _rehydrateWithCleanup();
      setState(() {}); // force rebuild
    }
  }

  void _rehydrateWithCleanup() {
    final oldIds = _questions.map((q) => q['id'] as String).toSet();
    _hydrate(); // régénère _questions + _tagsIndex

    final newIds = _questions.map((q) => q['id'] as String).toSet();
    // Supprimer et disposer ce qui n'existe plus
    for (final id in oldIds.difference(newIds)) {
      _answers.remove(id);
      _selectedTagsByField.remove(id);
      _freeByQuestion.remove(id)?.dispose();
    }
  }

  Future<void> _hydrate() async {
    final key = '${widget.passageRef}|${widget.passageText}';
    print('🔍 HYDRATE appelé avec key: $key');
    print('🔍 _lastKey: $_lastKey');
    print('🔍 _questions.length: ${_questions.length}');
    
    if (_lastKey == key && _questions.isNotEmpty) {
      print('🔍 Pas de regénération - même passage');
      return; // pas de regénération
    }
    _lastKey = key;

    final text = (widget.passageText ?? _fallbackDemo).trim();
    print('🔍 Texte à analyser: ${text.length} caractères');
    print('🔍 Début du texte: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    
    // 1) calcule tout hors setState
    final generated = await _generateIntelligentQuestions(text);
    print('🔍 Questions générées: ${generated.length}');

    final answers = <String, Set<String>>{};
    final freeByQuestion = <String, TextEditingController>{};
    final selectedTagsByField = <String, Set<String>>{};
    final tagsIndex = <String, Map<String, List<String>>>{};

    for (final q in generated) {
      final qid = q['id'] as String;
      answers[qid] = _answers[qid] ?? <String>{};
      freeByQuestion[qid] = _freeByQuestion[qid] ?? TextEditingController();
      selectedTagsByField[qid] = _selectedTagsByField[qid] ?? <String>{};

      final map = <String, List<String>>{};
      for (final opt in (q['options'] as List<Map<String, dynamic>>)) {
        map[opt['label'] as String] = (opt['tags'] as List).cast<String>();
      }
      tagsIndex[qid] = map;
    }

    // 2) commit d'un seul coup
    if (!mounted) return;
    setState(() {
      _questions = generated;
      _answers
        ..clear()
        ..addAll(answers);
      _freeByQuestion
        ..clear()
        ..addAll(freeByQuestion);
      _selectedTagsByField
        ..clear()
        ..addAll(selectedTagsByField);
      _tagsIndex
        ..clear()
        ..addAll(tagsIndex);
    });
    print('🔍 HYDRATE terminé');
  }


  // Validation pour permettre de continuer
  bool get _canContinue {
    final hasSelectedOptions = _answers.values.any((s) => s.isNotEmpty);
    final hasFree = _freeByQuestion.values.any((c) => c.text.trim().isNotEmpty);
    return hasSelectedOptions || hasFree;
  }

  Future<List<Map<String, dynamic>>> _generateIntelligentQuestions(String passage) async {
    // Générer des options spécifiques au passage
    final specificOptions = await _generateSpecificOptions(passage);

    return [
      {
        'id': 'de_quoi_qui',
        'question': 'De quoi ou de qui parlent ces versets ?',
        'type': 'multi',
        'options': specificOptions['de_quoi_qui'] ?? [
          {'label': 'Autre', 'tags': []},
        ],
      },
      {
        'id': 'apprend_dieu',
        'question': 'Est-ce que ce passage m\'apprend quelque chose sur Dieu ?',
        'type': 'multi',
        'options': specificOptions['apprend_dieu'] ?? [
          {'label': 'Rien de spécifique', 'tags': []},
        ],
      },
      {
        'id': 'exemple',
        'question': 'Y a-t-il un exemple à suivre ou à ne pas suivre ?',
        'type': 'multi',
        'options': specificOptions['exemple'] ?? [
          {'label': 'Aucun exemple particulier', 'tags': []},
        ],
      },
      {
        'id': 'ordre',
        'question': 'Y a-t-il un ordre auquel obéir ?',
        'type': 'multi',
        'options': specificOptions['ordre'] ?? [
          {'label': 'Aucun ordre spécifique', 'tags': []},
        ],
      },
      {
        'id': 'promesse',
        'question': 'Y a-t-il une promesse ?',
        'type': 'multi',
        'options': specificOptions['promesse'] ?? [
          {'label': 'Aucune promesse', 'tags': []},
        ],
      },
      {
        'id': 'avertissement',
        'question': 'Y a-t-il un avertissement ?',
        'type': 'multi',
        'options': specificOptions['avertissement'] ?? [
          {'label': 'Aucun avertissement', 'tags': []},
        ],
      },
      {
        'id': 'commande',
        'question': 'Y a-t-il un ordre ou une commande ?',
        'type': 'multi',
        'options': specificOptions['commande'] ?? [
          {'label': 'Aucune commande', 'tags': []},
        ],
      },
      {
        'id': 'personnage_principal',
        'question': 'Qui est le personnage principal ?',
        'type': 'single',
        'options': specificOptions['personnage_principal'] ?? [
          {'label': 'Autre', 'tags': []},
        ],
      },
      {
        'id': 'emotion',
        'question': 'Quelle émotion ce passage éveille-t-il en moi ?',
        'type': 'multi',
        'options': specificOptions['emotion'] ?? [
          {'label': 'Aucune émotion particulière', 'tags': []},
        ],
      },
      {
        'id': 'application',
        'question': 'Comment puis-je appliquer ce passage à ma vie ?',
        'type': 'multi',
        'options': specificOptions['application'] ?? [
          {'label': 'Aucune application spécifique', 'tags': []},
        ],
      },
    ];
  }


  @override
  void dispose() {
    for (final controller in _freeByQuestion.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggle(String questionId, String optionLabel, String type) {
    setState(() {
      final selected = _answers[questionId]!;
      final selectedTags = _selectedTagsByField[questionId]!;
      final optionTags = _tagsIndex[questionId]?[optionLabel] ?? const <String>[];
      
      if (type == 'single') {
        selected
          ..clear()
          ..add(optionLabel);
        selectedTags
          ..clear()
          ..addAll(optionTags);
      } else {
        if (selected.remove(optionLabel)) {
                  selectedTags.removeAll(optionTags);
        } else {
          selected.add(optionLabel);
                  selectedTags.addAll(optionTags);
        }
      }
    });
  }

  void _finish() {
    // Validation avant de continuer
    if (!_canContinue) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis au moins une réponse ou écris quelque chose.')),
      );
      return;
    }

    // Collecter les réponses de manière simplifiée
    final selectedAnswersByField = <String, Set<String>>{};
    final freeTextResponses = <String, String>{};
    
    // Collecter directement depuis _answers (plus simple)
    _answers.forEach((questionId, selectedLabels) {
      selectedAnswersByField[questionId] = {...selectedLabels}; // clone
    });
    
    // Collecter le texte libre
    _freeByQuestion.forEach((field, controller) {
      freeTextResponses[field] = controller.text.trim();
    });
    
    print('🔍 RÉPONSES DE MÉDITATION QCM:');
    _selectedTagsByField.forEach((field, tags) {
      print('🔍 $field - Tags: $tags');
      print('🔍 $field - Réponses cochées: ${selectedAnswersByField[field]}');
    });

    // Utiliser le nouveau système intelligent de génération de sujets
    final prayerSubjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: _selectedTagsByField,
      freeTexts: freeTextResponses,
      passageText: widget.passageText,
      passageRef: widget.passageRef,
    );
    
    // Convertir en PrayerItem pour la compatibilité
    final items = prayerSubjects.map((subject) => PrayerItem(
      theme: subject.category,
      subject: subject.label,
      color: _getColorForCategory(subject.category),
    )).toList();
    
    print('🔍 SUJETS DE PRIÈRE GÉNÉRÉS: ${items.length}');
    for (int i = 0; i < items.length; i++) {
      print('🔍 Item $i: ${items[i].theme} - ${items[i].subject}');
    }

    context.go('/payerpage', extra: {
      'items': items,
      'memoryVerse': '', // sera fixé plus tard si besoin
      'passageRef': _normalizeRef(widget.passageRef),
      'passageText': widget.passageText,
      'selectedTagsByField': _selectedTagsByField,
      'selectedAnswersByField': selectedAnswersByField,
      'freeTextResponses': freeTextResponses,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final hasInput = _answers.values.any((s) => s.isNotEmpty) ||
            _freeByQuestion.values.any((c) => c.text.trim().isNotEmpty);

        if (!hasInput) return true;
        
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Quitter la méditation ?'),
            content: const Text('Tes réponses non envoyées seront perdues.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Quitter'),
              ),
            ],
          ),
        );
        return ok ?? false;
      },
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1D29), Color(0xFF112244)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                  child: Stack(
                    children: [
                      // Ornements légers en arrière-plan
                      Positioned(
                        right: -60,
                        top: -40,
                        child: _softBlob(180),
                      ),
                      Positioned(
                        left: -40,
                        bottom: -50,
                        child: _softBlob(220),
                      ),

                    // Contenu principal optimisé avec thème a11y
                    Theme(
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor: Colors.white.withOpacity(0.7),
                        radioTheme: RadioThemeData(
                          fillColor: MaterialStateProperty.all(Colors.white),
                        ),
                        checkboxTheme: CheckboxThemeData(
                          fillColor: MaterialStateProperty.all(Colors.white),
                          checkColor: MaterialStateProperty.all(const Color(0xFF1A1D29)),
                        ),
                      ),
                      child: _questions.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding en bas pour le FAB
                            itemCount: _questions.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i == 0) return _glass(_buildInfoCard());
                              final q = _questions[i - 1];
                              return Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: _buildQuestionCard(q),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
              // Message d'aide si pas de réponses
              if (!_canContinue)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Réponds à au moins une question pour continuer.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: _safeGoBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Méditation Guidée',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (widget.passageRef != null && widget.passageRef!.isNotEmpty)
                  Text(
                    widget.passageRef!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Pour centrer le titre
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Réflexion Guidée',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lis lentement. Coche ce qui te parle, ou écris ta propre réponse.\n'
            'L\'Esprit t\'éclaire pendant que tu médites. 🙏',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final questionText = question['question'] as String;
    final type = question['type'] as String; // "single" | "multi"
    final options = question['options'] as List<Map<String, dynamic>>;

    // Pour RadioListTile, on a besoin d'une valeur unique
    final String? singleSelected =
        (_answers[questionId]?.isNotEmpty ?? false) ? _answers[questionId]!.first : null;

    return _glass(
      Container(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
            const SizedBox(height: 12),

            // Options a11y
            ...options.map((opt) {
              final label = opt['label'] as String;
              final tags  = (opt['tags'] as List).cast<String>();
              final isSelected = _answers[questionId]?.contains(label) ?? false;

              if (type == 'single') {
                return _radioOptionTile(
                  questionId: questionId,
                  label: label,
                  selectedValue: singleSelected,
                  tags: tags,
                );
              } else {
                return _checkboxOptionTile(
                  questionId: questionId,
                  label: label,
                  isSelected: isSelected,
                  tags: tags,
                );
              }
            }),

            const SizedBox(height: 12),
            
            // Bouton "Effacer" pour cette question
            if (_answers[questionId]?.isNotEmpty == true || 
                _freeByQuestion[questionId]?.text.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _answers[questionId]?.clear();
                      _selectedTagsByField[questionId]?.clear();
                      _freeByQuestion[questionId]?.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Effacer mes réponses',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
          _buildFreeTextField(questionId),
        ],
        ),
      ),
    );
  }

  Widget _checkboxOptionTile({
    required String questionId,
    required String label,
    required bool isSelected,
    required List<String> tags,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
          color: isSelected ? Colors.white.withOpacity(0.30) : Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
      child: Semantics(
        label: '$label (case à cocher)',
        child: CheckboxListTile(
          value: isSelected,
          onChanged: (v) => _toggle(questionId, label, 'multi'),
          title: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _radioOptionTile({
    required String questionId,
    required String label,
    required String? selectedValue,
    required List<String> tags,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
        color: (selectedValue == label) ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
                  border: Border.all(
          color: (selectedValue == label) ? Colors.white.withOpacity(0.30) : Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Semantics(
        label: '$label (bouton radio)',
        child: RadioListTile<String>(
          groupValue: selectedValue,
          value: label,
          onChanged: (_) => _toggle(questionId, label, 'single'),
          title: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              fontWeight: (selectedValue == label) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        ),
      ),
    );
  }

  Widget _glass(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: child,
        ),
      ),
    );

  Widget _buildFreeTextField(String questionId) {
    final controller = _freeByQuestion.putIfAbsent(
      questionId,
      () => TextEditingController(),
    );
    
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Focus(
          onFocusChange: (hasFocus) {
            setState(() {}); // Rebuild pour mettre à jour le style de focus
          },
          child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: 2,
              textInputAction: TextInputAction.next,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
                letterSpacing: 0.1,
        ),
        keyboardType: TextInputType.multiline,
              onChanged: (_) => setState(() {}), // Pour recalculer la validité
        enableInteractiveSelection: true,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: '… ou j\'écris ma propre réponse',
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
              letterSpacing: 0.1,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.35),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _generateSpecificOptions(String passage) async {
    final text = passage.toLowerCase();
    
    print('🔍 GÉNÉRATION OPTIONS pour passage: ${passage.length} caractères');
    print('🔍 Début du passage: ${passage.substring(0, passage.length > 50 ? 50 : passage.length)}...');
    print('🔍 Texte analysé: ${text.length} caractères');
    
    // 🧠 ANALYSE SÉMANTIQUE DU PASSAGE
    Map<String, List<Map<String, dynamic>>> semanticOptions = {};
    try {
      // Extraire les informations du passage depuis la référence
      final passageRef = widget.passageRef ?? '';
      if (passageRef.isNotEmpty) {
        // Parser la référence pour extraire book, chapters, verses
        final parts = passageRef.split(' ');
        if (parts.length >= 2) {
          final book = parts[0];
          final chapterVerse = parts[1];
          
          if (chapterVerse.contains(':')) {
            final chapterParts = chapterVerse.split(':');
            final startChapter = int.tryParse(chapterParts[0]) ?? 1;
            final verseParts = chapterParts[1].split('-');
            final startVerse = int.tryParse(verseParts[0]) ?? 1;
            final endVerse = int.tryParse(verseParts[1]) ?? startVerse;
            
            // Appeler le service sémantique
            final semanticAnalysis = await SemanticPassageBoundaryService.adjustPassageVerses(
              book: book,
              startChapter: startChapter,
              startVerse: startVerse,
              endChapter: startChapter,
              endVerse: endVerse,
            );

            // Générer des options basées sur l'unité littéraire détectée
            if (semanticAnalysis.includedUnit != null) {
              final unit = semanticAnalysis.includedUnit!;
              
              print('🧠 Unité littéraire détectée: ${unit.name} (${unit.type.name})');
              
              // Options basées sur le type d'unité
              switch (unit.type) {
                case UnitType.parable:
                  semanticOptions['de_quoi_qui'] = [
                    {'label': 'Une parabole de Jésus', 'tags': ['parable', 'enseignement', 'jésus']},
                  ];
                  semanticOptions['apprend_dieu'] = [
                    {'label': 'Dieu enseigne par des paraboles', 'tags': ['enseignement', 'sagesse']},
                  ];
                  semanticOptions['exemple'] = [
                    {'label': 'L\'exemple de Jésus dans cette parabole', 'tags': ['exemple', 'jésus']},
                  ];
                  break;
                case UnitType.discourse:
                  semanticOptions['de_quoi_qui'] = [
                    {'label': 'Un discours de Jésus', 'tags': ['discours', 'enseignement', 'jésus']},
                  ];
                  semanticOptions['apprend_dieu'] = [
                    {'label': 'Dieu révèle sa doctrine', 'tags': ['doctrine', 'révélation']},
                  ];
                  semanticOptions['exemple'] = [
                    {'label': 'L\'exemple de Jésus dans ce discours', 'tags': ['exemple', 'jésus']},
                  ];
                  break;
                case UnitType.narrative:
                  semanticOptions['de_quoi_qui'] = [
                    {'label': 'Un récit biblique', 'tags': ['récit', 'histoire', 'événement']},
                  ];
                  semanticOptions['apprend_dieu'] = [
                    {'label': 'Dieu agit dans l\'histoire', 'tags': ['action', 'providence']},
                  ];
                  semanticOptions['exemple'] = [
                    {'label': 'L\'exemple des personnages bibliques', 'tags': ['exemple', 'personnages']},
                  ];
                  break;
                case UnitType.poetry:
                  semanticOptions['de_quoi_qui'] = [
                    {'label': 'Une poésie biblique', 'tags': ['poésie', 'louange', 'adoration']},
                  ];
                  semanticOptions['apprend_dieu'] = [
                    {'label': 'Dieu est digne de louange', 'tags': ['louange', 'adoration']},
                  ];
                  semanticOptions['exemple'] = [
                    {'label': 'L\'exemple de la louange', 'tags': ['louange', 'adoration']},
                  ];
                  break;
                case UnitType.prophecy:
                  semanticOptions['de_quoi_qui'] = [
                    {'label': 'Une prophétie', 'tags': ['prophétie', 'avenir', 'révélation']},
                  ];
                  semanticOptions['apprend_dieu'] = [
                    {'label': 'Dieu révèle l\'avenir', 'tags': ['révélation', 'prophétie']},
                  ];
                  semanticOptions['exemple'] = [
                    {'label': 'L\'exemple de la fidélité prophétique', 'tags': ['fidélité', 'prophétie']},
                  ];
                  break;
                case UnitType.letter:
                  semanticOptions['de_quoi_qui'] = [
                    {'label': 'Une lettre apostolique', 'tags': ['lettre', 'enseignement', 'doctrine']},
                  ];
                  semanticOptions['apprend_dieu'] = [
                    {'label': 'Dieu enseigne par ses apôtres', 'tags': ['enseignement', 'apostolique']},
                  ];
                  semanticOptions['exemple'] = [
                    {'label': 'L\'exemple des apôtres', 'tags': ['exemple', 'apôtres']},
                  ];
                  break;
                default:
                  semanticOptions['de_quoi_qui'] = [
                    {'label': 'Un passage biblique', 'tags': ['biblique', 'méditation']},
                  ];
                  semanticOptions['apprend_dieu'] = [
                    {'label': 'Dieu se révèle dans ce passage', 'tags': ['révélation', 'dieu']},
                  ];
                  semanticOptions['exemple'] = [
                    {'label': 'L\'exemple biblique', 'tags': ['exemple', 'biblique']},
                  ];
              }

              // Ajouter des options basées sur les thèmes BSB
              if (unit.bsbThemes != null && unit.bsbThemes!.isNotEmpty) {
                for (final theme in unit.bsbThemes!) {
                  semanticOptions['de_quoi_qui']?.add({
                    'label': 'Thème: $theme',
                    'tags': ['thème', theme.toLowerCase()],
                  });
                }
              }

              // Ajouter des options basées sur la priorité
              switch (unit.priority) {
                case UnitPriority.critical:
                  semanticOptions['apprend_dieu']?.add({
                    'label': 'Passage fondamental pour la foi',
                    'tags': ['fondamental', 'critique', 'important'],
                  });
                  break;
                case UnitPriority.high:
                  semanticOptions['apprend_dieu']?.add({
                    'label': 'Passage important pour la compréhension',
                    'tags': ['important', 'significatif'],
                  });
                  break;
                case UnitPriority.medium:
                  semanticOptions['apprend_dieu']?.add({
                    'label': 'Passage instructif',
                    'tags': ['instructif', 'enseignement'],
                  });
                  break;
                case UnitPriority.low:
                  semanticOptions['apprend_dieu']?.add({
                    'label': 'Passage contemplatif',
                    'tags': ['contemplatif', 'méditation'],
                  });
                  break;
              }

              // Générer des options pour personnages, émotions et applications
              semanticOptions['personnage_principal'] = _generateSemanticCharacters(passage, unit);
              semanticOptions['emotion'] = _generateSemanticEmotions(passage, unit);
              semanticOptions['application'] = _generateSemanticApplications(passage, unit);
              
              // Générer des options sémantiques pour ordre, promesse, avertissement, commande
              semanticOptions['ordre'] = _generateSemanticOrders(passage, unit);
              semanticOptions['promesse'] = _generateSemanticPromises(passage, unit);
              semanticOptions['avertissement'] = _generateSemanticWarnings(passage, unit);
              semanticOptions['commande'] = _generateSemanticCommands(passage, unit);
              
              print('🧠 Options sémantiques générées:');
              print('🧠 personnage_principal: ${semanticOptions['personnage_principal']?.length ?? 0} options');
              print('🧠 emotion: ${semanticOptions['emotion']?.length ?? 0} options');
              print('🧠 application: ${semanticOptions['application']?.length ?? 0} options');
              print('🧠 ordre: ${semanticOptions['ordre']?.length ?? 0} options');
              print('🧠 promesse: ${semanticOptions['promesse']?.length ?? 0} options');
              print('🧠 avertissement: ${semanticOptions['avertissement']?.length ?? 0} options');
              print('🧠 commande: ${semanticOptions['commande']?.length ?? 0} options');
            } else {
              // Même si aucune unité littéraire n'est détectée, générer des options basées sur le contenu
              print('🧠 Aucune unité littéraire détectée, génération basée sur le contenu');
              semanticOptions['personnage_principal'] = _generateSemanticCharacters(passage, null);
              semanticOptions['emotion'] = _generateSemanticEmotions(passage, null);
              semanticOptions['application'] = _generateSemanticApplications(passage, null);
              semanticOptions['ordre'] = _generateSemanticOrders(passage, null);
              semanticOptions['promesse'] = _generateSemanticPromises(passage, null);
              semanticOptions['avertissement'] = _generateSemanticWarnings(passage, null);
              semanticOptions['commande'] = _generateSemanticCommands(passage, null);
              
              print('🧠 Options sémantiques générées (sans unité):');
              print('🧠 personnage_principal: ${semanticOptions['personnage_principal']?.length ?? 0} options');
              print('🧠 emotion: ${semanticOptions['emotion']?.length ?? 0} options');
              print('🧠 application: ${semanticOptions['application']?.length ?? 0} options');
              print('🧠 ordre: ${semanticOptions['ordre']?.length ?? 0} options');
              print('🧠 promesse: ${semanticOptions['promesse']?.length ?? 0} options');
              print('🧠 avertissement: ${semanticOptions['avertissement']?.length ?? 0} options');
              print('🧠 commande: ${semanticOptions['commande']?.length ?? 0} options');
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur analyse sémantique: $e');
    }
    
    // Debug: Vérifier les options sémantiques avant utilisation
    print('🔍 DEBUG - Options sémantiques avant utilisation:');
    print('🔍 personnage_principal: ${semanticOptions['personnage_principal']?.length ?? 0} options');
    print('🔍 emotion: ${semanticOptions['emotion']?.length ?? 0} options');
    print('🔍 application: ${semanticOptions['application']?.length ?? 0} options');
    print('🔍 ordre: ${semanticOptions['ordre']?.length ?? 0} options');
    print('🔍 promesse: ${semanticOptions['promesse']?.length ?? 0} options');
    print('🔍 avertissement: ${semanticOptions['avertissement']?.length ?? 0} options');
    print('🔍 commande: ${semanticOptions['commande']?.length ?? 0} options');
    
    final options = {
      'de_quoi_qui': semanticOptions['de_quoi_qui'] ?? [],
      'apprend_dieu': semanticOptions['apprend_dieu'] ?? [],
      'exemple': semanticOptions['exemple'] ?? [],
      'ordre': semanticOptions['ordre'] ?? [],
      'promesse': semanticOptions['promesse'] ?? [],
      'avertissement': semanticOptions['avertissement'] ?? [],
      'commande': semanticOptions['commande'] ?? [],
      'personnage_principal': semanticOptions['personnage_principal'] ?? [],
      'emotion': semanticOptions['emotion'] ?? [],
      'application': semanticOptions['application'] ?? [],
    };
    
    // Debug: Afficher les options générées
    print('🔍 OPTIONS GÉNÉRÉES:');
    options.forEach((key, value) {
      print('🔍 $key: ${value.length} options');
      for (final option in value) {
        print('  - ${option['label']}');
      }
    });
    
    return options;
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES SÉMANTIQUES POUR PERSONNAGES, ÉMOTIONS ET APPLICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _generateSemanticCharacters(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Personnages basés sur le contenu réel du passage
    if (text.contains('jésus') || text.contains('christ')) {
      options.add({'label': 'Jésus-Christ', 'tags': ['jésus', 'sauveur', 'seigneur']});
    }
    if (text.contains('puissance') || text.contains('majesté') || text.contains('tout-puissant')) {
      options.add({'label': 'Dieu est puissant et majestueux', 'tags': ['praise', 'awe']});
    }
    if (text.contains('sagesse') || text.contains('conseil') || text.contains('intelligence')) {
      options.add({'label': 'Dieu donne la sagesse', 'tags': ['guidance', 'trust']});
    }
    if (text.contains('fidèle') || text.contains('promesse') || text.contains('promis')) {
      options.add({'label': 'Dieu est fidèle à ses promesses', 'tags': ['trust', 'promise']});
    }
    if (text.contains('saint') || text.contains('pur') || text.contains('sainteté')) {
      options.add({'label': 'Dieu est saint et pur', 'tags': ['awe', 'repentance']});
    }
    if (text.contains('juste') || text.contains('justice') || text.contains('équité')) {
      options.add({'label': 'Dieu est juste', 'tags': ['awe', 'trust']});
    }
    if (text.contains('sauve') || text.contains('salut') || text.contains('délivre')) {
      options.add({'label': 'Dieu sauve et délivre', 'tags': ['promise', 'trust']});
    }
    if (text.contains('créateur') || text.contains('créé') || text.contains('création')) {
      options.add({'label': 'Dieu est le Créateur', 'tags': ['praise', 'awe']});
    }
    if (text.contains('père') || text.contains('paternité')) {
      options.add({'label': 'Dieu est notre Père', 'tags': ['praise', 'trust']});
    }
    if (text.contains('roi') || text.contains('royaume') || text.contains('souverain')) {
      options.add({'label': 'Dieu est le Roi souverain', 'tags': ['praise', 'awe']});
    }
    if (text.contains('miséricorde') || text.contains('compassion')) {
      options.add({'label': 'Dieu est miséricordieux', 'tags': ['praise', 'gratitude']});
    }
    if (text.contains('vérité') || text.contains('vrai')) {
      options.add({'label': 'Dieu est vérité', 'tags': ['trust', 'guidance']});
    }
    if (text.contains('éternel') || text.contains('éternité')) {
      options.add({'label': 'Dieu est éternel', 'tags': ['awe', 'trust']});
    }
    if (text.contains('présent') || text.contains('avec nous') || text.contains('accompagne')) {
      options.add({'label': 'Dieu est présent avec nous', 'tags': ['trust', 'promise']});
    }
    if (text.contains('écoute') || text.contains('entend') || text.contains('répond')) {
      options.add({'label': 'Dieu écoute et répond', 'tags': ['trust', 'promise']});
    }
    if (text.contains('guide') || text.contains('direction') || text.contains('chemin')) {
      options.add({'label': 'Dieu guide et dirige', 'tags': ['guidance', 'trust']});
    }
    if (text.contains('protège') || text.contains('garde') || text.contains('défend')) {
      options.add({'label': 'Dieu protège et garde', 'tags': ['trust', 'promise']});
    }
    if (text.contains('juge') || text.contains('jugement') || text.contains('avertit')) {
      options.add({'label': 'Dieu juge et avertit', 'tags': ['awe', 'warning']});
    }
    if (text.contains('pardonne') || text.contains('pardon') || text.contains('miséricorde')) {
      options.add({'label': 'Dieu pardonne', 'tags': ['gratitude', 'trust']});
    }
    if (text.contains('rédempteur') || text.contains('rédemption') || text.contains('racheter')) {
      options.add({'label': 'Dieu est le Rédempteur', 'tags': ['praise', 'gratitude']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Dieu se révèle dans ce passage', 'tags': ['praise', 'gratitude']});
    }
    
    return options;
  }

  // Méthode supprimée - utilise maintenant uniquement les options sémantiques
  List<Map<String, dynamic>> _generateExampleOptions_DELETED(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Analyse dynamique des exemples à suivre ou à ne pas suivre
    if (text.contains('jésus') || text.contains('christ')) {
      options.add({'label': 'L\'exemple de Jésus-Christ', 'tags': ['trust', 'obedience']});
    }
    if (text.contains('apôtres') || text.contains('disciples')) {
      options.add({'label': 'L\'exemple des apôtres', 'tags': ['obedience', 'service']});
    }
    if (text.contains('foi') || text.contains('croire')) {
      options.add({'label': 'L\'exemple de la foi', 'tags': ['trust', 'obedience']});
    }
    if (text.contains('amour') || text.contains('aimer')) {
      options.add({'label': 'L\'exemple de l\'amour', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('obéissance') || text.contains('obéir')) {
      options.add({'label': 'L\'exemple de l\'obéissance', 'tags': ['obedience']});
    }
    if (text.contains('prière') || text.contains('prier')) {
      options.add({'label': 'L\'exemple de la prière', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('service') || text.contains('servir')) {
      options.add({'label': 'L\'exemple du service', 'tags': ['obedience', 'service']});
    }
    if (text.contains('humilité') || text.contains('humble')) {
      options.add({'label': 'L\'exemple de l\'humilité', 'tags': ['repentance', 'obedience']});
    }
    if (text.contains('patience') || text.contains('patient')) {
      options.add({'label': 'L\'exemple de la patience', 'tags': ['trust', 'obedience']});
    }
    if (text.contains('persévérance') || text.contains('persévérer')) {
      options.add({'label': 'L\'exemple de la persévérance', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('sagesse') || text.contains('sage')) {
      options.add({'label': 'L\'exemple de la sagesse', 'tags': ['guidance', 'trust']});
    }
    if (text.contains('courage') || text.contains('brave')) {
      options.add({'label': 'L\'exemple du courage', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('pardon') || text.contains('pardonner')) {
      options.add({'label': 'L\'exemple du pardon', 'tags': ['gratitude', 'intercession']});
    }
    if (text.contains('générosité') || text.contains('donner')) {
      options.add({'label': 'L\'exemple de la générosité', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('justice') || text.contains('juste')) {
      options.add({'label': 'L\'exemple de la justice', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('miséricorde') || text.contains('miséricordieux')) {
      options.add({'label': 'L\'exemple de la miséricorde', 'tags': ['gratitude', 'intercession']});
    }
    if (text.contains('trahison') || text.contains('trahir')) {
      options.add({'label': 'L\'exemple de la trahison (à éviter)', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('orgueil') || text.contains('fier')) {
      options.add({'label': 'L\'exemple de l\'orgueil (à éviter)', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('incrédulité') || text.contains('incrédule')) {
      options.add({'label': 'L\'exemple de l\'incrédulité (à éviter)', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('désobéissance') || text.contains('désobéir')) {
      options.add({'label': 'L\'exemple de la désobéissance (à éviter)', 'tags': ['warning', 'repentance']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucun exemple particulier', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateOrderOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Analyse dynamique des ordres et commandements
    if (text.contains('croire') || text.contains('foi')) {
      options.add({'label': 'Croire en Dieu', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('aimer') || text.contains('amour')) {
      options.add({'label': 'Aimer Dieu et son prochain', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('obéir') || text.contains('obéissance')) {
      options.add({'label': 'Obéir aux commandements', 'tags': ['obedience']});
    }
    if (text.contains('prier') || text.contains('prière')) {
      options.add({'label': 'Prier sans cesse', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('servir') || text.contains('service')) {
      options.add({'label': 'Servir Dieu', 'tags': ['obedience', 'service']});
    }
    if (text.contains('évangéliser') || text.contains('proclamer')) {
      options.add({'label': 'Proclamer l\'Évangile', 'tags': ['obedience', 'service']});
    }
    if (text.contains('repentir') || text.contains('repentance')) {
      options.add({'label': 'Se repentir', 'tags': ['repentance', 'obedience']});
    }
    if (text.contains('pardonner') || text.contains('pardon')) {
      options.add({'label': 'Pardonner', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('donner') || text.contains('générosité')) {
      options.add({'label': 'Donner généreusement', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('écouter') || text.contains('entendre')) {
      options.add({'label': 'Écouter la Parole de Dieu', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('garder') || text.contains('conserver')) {
      options.add({'label': 'Garder les commandements', 'tags': ['obedience']});
    }
    if (text.contains('suivre') || text.contains('suivre')) {
      options.add({'label': 'Suivre Jésus', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('chercher') || text.contains('rechercher')) {
      options.add({'label': 'Chercher le royaume de Dieu', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('demander') || text.contains('demander')) {
      options.add({'label': 'Demander à Dieu', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('remercier') || text.contains('gratitude')) {
      options.add({'label': 'Remercier Dieu', 'tags': ['gratitude', 'praise']});
    }
    if (text.contains('louer') || text.contains('louange')) {
      options.add({'label': 'Louer Dieu', 'tags': ['praise', 'gratitude']});
    }
    if (text.contains('adorer') || text.contains('adoration')) {
      options.add({'label': 'Adorer Dieu', 'tags': ['praise', 'gratitude']});
    }
    if (text.contains('témoigner') || text.contains('témoignage')) {
      options.add({'label': 'Témoigner de sa foi', 'tags': ['obedience', 'service']});
    }
    if (text.contains('veiller') || text.contains('vigilance')) {
      options.add({'label': 'Veiller et prier', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('persévérer') || text.contains('persévérance')) {
      options.add({'label': 'Persévérer dans la foi', 'tags': ['obedience', 'trust']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucun ordre spécifique', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generatePromiseOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Analyse dynamique des promesses - s'adapte à n'importe quel passage
    if (text.contains('promesse') || text.contains('promis')) {
      options.add({'label': 'Les promesses de Dieu', 'tags': ['promise', 'trust']});
    }
    if (text.contains('vie éternelle') || text.contains('vie éternelle')) {
      options.add({'label': 'Promesse de vie éternelle', 'tags': ['promise', 'trust']});
    }
    if (text.contains('salut') || text.contains('sauver')) {
      options.add({'label': 'Promesse de salut', 'tags': ['promise', 'trust']});
    }
    if (text.contains('royaume') || text.contains('roi')) {
      options.add({'label': 'Promesse du royaume de Dieu', 'tags': ['promise', 'trust']});
    }
    if (text.contains('saint-esprit') || text.contains('esprit')) {
      options.add({'label': 'Promesse du Saint-Esprit', 'tags': ['promise', 'trust']});
    }
    if (text.contains('demeures') || text.contains('maison')) {
      options.add({'label': 'Promesse des demeures célestes', 'tags': ['promise', 'trust']});
    }
    if (text.contains('revenir') || text.contains('retour')) {
      options.add({'label': 'Promesse du retour de Jésus', 'tags': ['promise', 'trust']});
    }
    if (text.contains('résurrection') || text.contains('ressusciter')) {
      options.add({'label': 'Promesse de résurrection', 'tags': ['promise', 'trust']});
    }
    if (text.contains('bénédiction') || text.contains('bénir')) {
      options.add({'label': 'Promesse de bénédiction', 'tags': ['promise', 'gratitude']});
    }
    if (text.contains('protection') || text.contains('protéger')) {
      options.add({'label': 'Promesse de protection', 'tags': ['promise', 'trust']});
    }
    if (text.contains('guidance') || text.contains('guider')) {
      options.add({'label': 'Promesse de guidance', 'tags': ['promise', 'trust']});
    }
    if (text.contains('paix') || text.contains('paix')) {
      options.add({'label': 'Promesse de paix', 'tags': ['promise', 'trust']});
    }
    if (text.contains('joie') || text.contains('allégresse')) {
      options.add({'label': 'Promesse de joie', 'tags': ['promise', 'gratitude']});
    }
    if (text.contains('force') || text.contains('puissance')) {
      options.add({'label': 'Promesse de force', 'tags': ['promise', 'trust']});
    }
    if (text.contains('sagesse') || text.contains('intelligence')) {
      options.add({'label': 'Promesse de sagesse', 'tags': ['promise', 'trust']});
    }
    if (text.contains('pardon') || text.contains('pardonner')) {
      options.add({'label': 'Promesse de pardon', 'tags': ['promise', 'gratitude']});
    }
    if (text.contains('amour') || text.contains('aimer')) {
      options.add({'label': 'Promesse d\'amour', 'tags': ['promise', 'gratitude']});
    }
    if (text.contains('fidélité') || text.contains('fidèle')) {
      options.add({'label': 'Promesse de fidélité', 'tags': ['promise', 'trust']});
    }
    if (text.contains('présence') || text.contains('avec nous')) {
      options.add({'label': 'Promesse de présence', 'tags': ['promise', 'trust']});
    }
    if (text.contains('victoire') || text.contains('vaincre')) {
      options.add({'label': 'Promesse de victoire', 'tags': ['promise', 'trust']});
    }
    if (text.contains('héritage') || text.contains('hériter')) {
      options.add({'label': 'Promesse d\'héritage', 'tags': ['promise', 'trust']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune promesse directe dans ce passage', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateWarningOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    if (text.contains('épée') && text.contains('viendra')) {
      options.add({'label': 'L\'épée viendra sur le pays', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('sang') && text.contains('tête')) {
      options.add({'label': 'Le sang sera sur la tête de celui qui n\'écoute pas', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('responsable') || text.contains('redemander')) {
      options.add({'label': 'La responsabilité sera redemandée', 'tags': ['warning', 'obedience']});
    }
    if (text.contains('sonner') || text.contains('trompette')) {
      options.add({'label': 'Il faut sonner l\'alarme', 'tags': ['warning', 'obedience']});
    }
    if (text.contains('péché') || text.contains('faute')) {
      options.add({'label': 'Avertissement contre le péché', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('orgueil') || text.contains('fier')) {
      options.add({'label': 'Avertissement contre l\'orgueil', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('idolâtrie') || text.contains('idole')) {
      options.add({'label': 'Avertissement contre l\'idolâtrie', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('conséquence') || text.contains('résultat')) {
      options.add({'label': 'Avertissement sur les conséquences', 'tags': ['warning']});
    }
    if (text.contains('jugement') || text.contains('condamnation')) {
      options.add({'label': 'Avertissement du jugement à venir', 'tags': ['warning', 'repentance']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucun avertissement dans ce passage', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateCommandOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    if (text.contains('parler') || text.contains('dire')) {
      options.add({'label': 'Parler et proclamer la Parole', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('sonner') || text.contains('trompette')) {
      options.add({'label': 'Sonner l\'alarme quand on voit le danger', 'tags': ['obedience', 'responsibility']});
    }
    if (text.contains('avertir') || text.contains('prévenir')) {
      options.add({'label': 'Avertir les autres', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('écouter') || text.contains('entendre')) {
      options.add({'label': 'Écouter l\'avertissement', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('croire') || text.contains('foi')) {
      options.add({'label': 'Croire en Dieu', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('aimer') || text.contains('amour')) {
      options.add({'label': 'Aimer Dieu et son prochain', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('servir') || text.contains('service')) {
      options.add({'label': 'Servir Dieu', 'tags': ['obedience', 'responsibility']});
    }
    if (text.contains('prier') || text.contains('prière')) {
      options.add({'label': 'Prier sans cesse', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('obéir') || text.contains('obéissance')) {
      options.add({'label': 'Obéir aux commandements', 'tags': ['obedience']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune commande dans ce passage', 'tags': []});
    }
    
    return options;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES SÉMANTIQUES POUR PERSONNAGES, ÉMOTIONS ET APPLICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

    
    // Émotions basées sur le contenu réel du passage
    if (text.contains('joie') || text.contains('allégresse') || text.contains('réjouir')) {
      options.add({'label': 'Joie et allégresse', 'tags': ['joie', 'bonheur', 'célébration']});
    }
    if (text.contains('espoir') || text.contains('espérance') || text.contains('attendre')) {
      options.add({'label': 'Espoir et anticipation', 'tags': ['espoir', 'anticipation', 'attente']});
    }
    if (text.contains('crainte') || text.contains('crainte') || text.contains('respect')) {
      options.add({'label': 'Crainte révérencielle', 'tags': ['crainte', 'respect', 'révérence']});
    }
    if (text.contains('confiance') || text.contains('foi') || text.contains('croire')) {
      options.add({'label': 'Confiance et foi', 'tags': ['confiance', 'foi', 'assurance']});
    }
    if (text.contains('gratitude') || text.contains('remercier') || text.contains('merci')) {
      options.add({'label': 'Gratitude', 'tags': ['gratitude', 'reconnaissance', 'merci']});
    }
    if (text.contains('paix') || text.contains('sérénité') || text.contains('tranquillité')) {
      options.add({'label': 'Paix et sérénité', 'tags': ['paix', 'sérénité', 'tranquillité']});
    }
    if (text.contains('amour') || text.contains('aimer') || text.contains('charité')) {
      options.add({'label': 'Amour et charité', 'tags': ['amour', 'charité', 'bienveillance']});
    }
    if (text.contains('humilité') || text.contains('humble') || text.contains('soumission')) {
      options.add({'label': 'Humilité et soumission', 'tags': ['humilité', 'soumission', 'modestie']});
    }
    
    // Émotions basées sur le type d'unité littéraire
    if (unit != null) {
      switch (unit.type) {
      case UnitType.poetry:
        options.add({'label': 'Adoration et louange', 'tags': ['adoration', 'louange', 'worship']});
        break;
      case UnitType.prophecy:
        options.add({'label': 'Urgence et responsabilité', 'tags': ['urgence', 'responsabilité', 'mission']});
        break;
      case UnitType.letter:
        options.add({'label': 'Affection fraternelle', 'tags': ['affection', 'fraternelle', 'communauté']});
        break;
      default:
        break;
      }
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune émotion particulière', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateSemanticApplications(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Applications basées sur le contenu réel du passage
    if (text.contains('attendre') || text.contains('promesse')) {
      options.add({'label': 'Attendre les promesses de Dieu', 'tags': ['attente', 'promesse', 'patience']});
    }
    if (text.contains('témoin') || text.contains('témoigner') || text.contains('proclamer')) {
      options.add({'label': 'Être témoin de Jésus', 'tags': ['témoin', 'proclamation', 'évangélisation']});
    }
    if (text.contains('prier') || text.contains('prière')) {
      options.add({'label': 'Prier sans cesse', 'tags': ['prière', 'communion', 'adoration']});
    }
    if (text.contains('obéir') || text.contains('obéissance') || text.contains('commandement')) {
      options.add({'label': 'Obéir aux commandements de Dieu', 'tags': ['obéissance', 'commandements', 'fidélité']});
    }
    if (text.contains('aimer') || text.contains('amour')) {
      options.add({'label': 'Aimer Dieu et mon prochain', 'tags': ['amour', 'charité', 'service']});
    }
    if (text.contains('servir') || text.contains('service')) {
      options.add({'label': 'Servir Dieu dans ma vie', 'tags': ['service', 'ministère', 'don']});
    }
    if (text.contains('croire') || text.contains('foi')) {
      options.add({'label': 'Renforcer ma foi en Dieu', 'tags': ['foi', 'confiance', 'croyance']});
    }
    if (text.contains('esprit') || text.contains('saint-esprit')) {
      options.add({'label': 'M\'ouvrir au Saint-Esprit', 'tags': ['esprit', 'saint', 'guidance']});
    }
    
    // Applications basées sur le type d'unité littéraire
    if (unit != null) {
      switch (unit.type) {
      case UnitType.parable:
        options.add({'label': 'Appliquer les leçons de cette parabole', 'tags': ['parabole', 'leçon', 'application']});
        break;
      case UnitType.discourse:
        options.add({'label': 'Mettre en pratique cet enseignement', 'tags': ['enseignement', 'pratique', 'obéissance']});
        break;
      case UnitType.narrative:
        options.add({'label': 'Suivre l\'exemple de ce récit', 'tags': ['exemple', 'récit', 'imitation']});
        break;
      case UnitType.poetry:
        options.add({'label': 'Louer Dieu avec ce psaume', 'tags': ['louange', 'psaume', 'adoration']});
        break;
      case UnitType.prophecy:
        options.add({'label': 'Répondre à cet appel prophétique', 'tags': ['prophétie', 'appel', 'mission']});
        break;
      case UnitType.letter:
        options.add({'label': 'Vivre selon ces instructions apostoliques', 'tags': ['instruction', 'apostolique', 'doctrine']});
        break;
      default:
        break;
      }
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune application spécifique', 'tags': []});
    }
    
    return options;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES GÉNÉRIQUES (DÉSACTIVÉES - GARDÉES POUR RÉFÉRENCE)
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _generateCharacterOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    if (text.contains('ézéchiel') || text.contains('prophète')) {
      options.add({'label': 'Ézéchiel (le prophète)', 'tags': ['intercession', 'obedience']});
    }
    if (text.contains('sentinelle') || text.contains('garde')) {
      options.add({'label': 'La sentinelle', 'tags': ['responsibility', 'obedience']});
    }
    if (text.contains('peuple') || text.contains('israël')) {
      options.add({'label': 'Le peuple d\'Israël', 'tags': ['intercession']});
    }
    if (text.contains('éternel') || text.contains('seigneur') || text.contains('dieu')) {
      options.add({'label': 'L\'Éternel (Dieu)', 'tags': ['praise', 'awe']});
    }
    if (text.contains('jésus') || text.contains('christ')) {
      options.add({'label': 'Jésus-Christ', 'tags': ['praise', 'trust']});
    }
    if (text.contains('homme') && text.contains('n\'écoute')) {
      options.add({'label': 'L\'homme qui n\'écoute pas', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('apôtre') || text.contains('paul')) {
      options.add({'label': 'Un apôtre', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('roi') || text.contains('david')) {
      options.add({'label': 'Un roi', 'tags': ['responsibility', 'obedience']});
    }
    if (text.contains('berger') || text.contains('pasteur')) {
      options.add({'label': 'Un berger', 'tags': ['responsibility', 'intercession']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Un personnage biblique', 'tags': ['intercession']});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateEmotionOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    if (text.contains('urgence') || text.contains('responsabilité')) {
      options.add({'label': 'Urgence et responsabilité', 'tags': ['obedience', 'responsibility']});
    }
    if (text.contains('crainte') || text.contains('jugement')) {
      options.add({'label': 'Crainte du jugement', 'tags': ['awe', 'repentance']});
    }
    if (text.contains('espoir') || text.contains('salut')) {
      options.add({'label': 'Espoir de salut', 'tags': ['trust', 'promise']});
    }
    if (text.contains('gratitude') || text.contains('remercier')) {
      options.add({'label': 'Gratitude pour l\'avertissement', 'tags': ['gratitude', 'trust']});
    }
    if (text.contains('joie') || text.contains('allégresse')) {
      options.add({'label': 'Joie et allégresse', 'tags': ['praise', 'gratitude']});
    }
    if (text.contains('paix') || text.contains('sérénité')) {
      options.add({'label': 'Paix et sérénité', 'tags': ['trust', 'gratitude']});
    }
    if (text.contains('amour') || text.contains('tendresse')) {
      options.add({'label': 'Amour et tendresse', 'tags': ['praise', 'gratitude']});
    }
    if (text.contains('confiance') || text.contains('foi')) {
      options.add({'label': 'Confiance et foi', 'tags': ['trust', 'obedience']});
    }
    if (text.contains('humilité') || text.contains('soumission')) {
      options.add({'label': 'Humilité et soumission', 'tags': ['repentance', 'obedience']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune émotion particulière', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateApplicationOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    if (text.contains('sentinelle') || text.contains('garde')) {
      options.add({'label': 'Être une sentinelle fidèle dans ma vie', 'tags': ['obedience', 'responsibility']});
    }
    if (text.contains('écouter') || text.contains('avertissement')) {
      options.add({'label': 'Écouter les avertissements de Dieu', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('avertir') || text.contains('prévenir')) {
      options.add({'label': 'Avertir les autres avec amour', 'tags': ['intercession', 'obedience']});
    }
    if (text.contains('responsabilité') || text.contains('responsable')) {
      options.add({'label': 'Prendre mes responsabilités au sérieux', 'tags': ['obedience', 'responsibility']});
    }
    if (text.contains('repentir') || text.contains('se repentir')) {
      options.add({'label': 'Me repentir avant qu\'il ne soit trop tard', 'tags': ['repentance', 'trust']});
    }
    if (text.contains('aimer') || text.contains('amour')) {
      options.add({'label': 'Aimer Dieu et mon prochain', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('servir') || text.contains('service')) {
      options.add({'label': 'Servir Dieu dans ma vie quotidienne', 'tags': ['obedience', 'responsibility']});
    }
    if (text.contains('prier') || text.contains('prière')) {
      options.add({'label': 'Prier plus régulièrement', 'tags': ['obedience', 'intercession']});
    }
    if (text.contains('croire') || text.contains('foi')) {
      options.add({'label': 'Renforcer ma foi en Dieu', 'tags': ['trust', 'obedience']});
    }
    if (text.contains('obéir') || text.contains('obéissance')) {
      options.add({'label': 'Obéir aux commandements de Dieu', 'tags': ['obedience']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune application spécifique', 'tags': []});
    }
    
    return options;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES SÉMANTIQUES POUR ORDRE, PROMESSE, AVERTISSEMENT, COMMANDE
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _generateSemanticOrders(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Ordres basés sur le contenu réel du passage
    if (text.contains('prier') || text.contains('prière')) {
      options.add({'label': 'Prier sans cesse', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('attendre') || text.contains('attendre')) {
      options.add({'label': 'Attendre les promesses de Dieu', 'tags': ['trust', 'patience']});
    }
    if (text.contains('témoin') || text.contains('témoigner')) {
      options.add({'label': 'Être témoin de Jésus', 'tags': ['obedience', 'service']});
    }
    if (text.contains('obéir') || text.contains('obéissance')) {
      options.add({'label': 'Obéir aux commandements', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('aimer') || text.contains('amour')) {
      options.add({'label': 'Aimer Dieu et son prochain', 'tags': ['obedience', 'love']});
    }
    if (text.contains('servir') || text.contains('service')) {
      options.add({'label': 'Servir Dieu', 'tags': ['obedience', 'service']});
    }
    if (text.contains('garder') || text.contains('garder')) {
      options.add({'label': 'Garder les commandements', 'tags': ['obedience', 'trust']});
    }
    
    // Ordres basés sur le type d'unité littéraire
    if (unit != null) {
      switch (unit.type) {
        case UnitType.parable:
          options.add({'label': 'Appliquer les leçons de cette parabole', 'tags': ['obedience', 'wisdom']});
          break;
        case UnitType.discourse:
          options.add({'label': 'Mettre en pratique cet enseignement', 'tags': ['obedience', 'wisdom']});
          break;
        case UnitType.narrative:
          options.add({'label': 'Suivre l\'exemple de ce récit', 'tags': ['obedience', 'example']});
          break;
        case UnitType.poetry:
          options.add({'label': 'Louer Dieu avec ce psaume', 'tags': ['praise', 'worship']});
          break;
        case UnitType.prophecy:
          options.add({'label': 'Répondre à cet appel prophétique', 'tags': ['obedience', 'mission']});
          break;
        case UnitType.letter:
          options.add({'label': 'Vivre selon ces instructions apostoliques', 'tags': ['obedience', 'doctrine']});
          break;
        default:
          break;
      }
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucun ordre spécifique', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateSemanticPromises(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Promesses basées sur le contenu réel du passage
    if (text.contains('royaume') || text.contains('roi')) {
      options.add({'label': 'Promesse du royaume de Dieu', 'tags': ['promise', 'hope']});
    }
    if (text.contains('saint-esprit') || text.contains('esprit')) {
      options.add({'label': 'Promesse du Saint-Esprit', 'tags': ['promise', 'power']});
    }
    if (text.contains('retour') || text.contains('revenir')) {
      options.add({'label': 'Promesse du retour de Jésus', 'tags': ['promise', 'hope']});
    }
    if (text.contains('salut') || text.contains('sauver')) {
      options.add({'label': 'Promesse du salut', 'tags': ['promise', 'hope']});
    }
    if (text.contains('vie éternelle') || text.contains('éternel')) {
      options.add({'label': 'Promesse de la vie éternelle', 'tags': ['promise', 'hope']});
    }
    if (text.contains('force') || text.contains('puissance')) {
      options.add({'label': 'Promesse de force', 'tags': ['promise', 'power']});
    }
    if (text.contains('paix') || text.contains('tranquillité')) {
      options.add({'label': 'Promesse de paix', 'tags': ['promise', 'comfort']});
    }
    if (text.contains('guérison') || text.contains('guérir')) {
      options.add({'label': 'Promesse de guérison', 'tags': ['promise', 'healing']});
    }
    
    // Promesses basées sur le type d'unité littéraire
    if (unit != null) {
      switch (unit.type) {
        case UnitType.prophecy:
          options.add({'label': 'Promesses prophétiques', 'tags': ['promise', 'prophecy']});
          break;
        case UnitType.poetry:
          options.add({'label': 'Promesses de louange et d\'adoration', 'tags': ['promise', 'worship']});
          break;
        case UnitType.letter:
          options.add({'label': 'Promesses apostoliques', 'tags': ['promise', 'doctrine']});
          break;
        default:
          break;
      }
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune promesse directe dans ce passage', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateSemanticWarnings(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Avertissements basés sur le contenu réel du passage
    if (text.contains('jugement') || text.contains('condamnation')) {
      options.add({'label': 'Avertissement du jugement', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('péché') || text.contains('faute')) {
      options.add({'label': 'Avertissement contre le péché', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('déception') || text.contains('faux')) {
      options.add({'label': 'Avertissement contre la déception', 'tags': ['warning', 'discernment']});
    }
    if (text.contains('orgueil') || text.contains('fierté')) {
      options.add({'label': 'Avertissement contre l\'orgueil', 'tags': ['warning', 'humility']});
    }
    if (text.contains('idolâtrie') || text.contains('idole')) {
      options.add({'label': 'Avertissement contre l\'idolâtrie', 'tags': ['warning', 'worship']});
    }
    if (text.contains('découragement') || text.contains('désespoir')) {
      options.add({'label': 'Avertissement contre le découragement', 'tags': ['warning', 'hope']});
    }
    if (text.contains('tentation') || text.contains('tenter')) {
      options.add({'label': 'Avertissement contre la tentation', 'tags': ['warning', 'resistance']});
    }
    
    // Avertissements basés sur le type d'unité littéraire
    if (unit != null) {
      switch (unit.type) {
        case UnitType.prophecy:
          options.add({'label': 'Avertissements prophétiques', 'tags': ['warning', 'prophecy']});
          break;
        case UnitType.parable:
          options.add({'label': 'Avertissements dans cette parabole', 'tags': ['warning', 'wisdom']});
          break;
        case UnitType.letter:
          options.add({'label': 'Avertissements apostoliques', 'tags': ['warning', 'doctrine']});
          break;
        default:
          break;
      }
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucun avertissement dans ce passage', 'tags': []});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateSemanticCommands(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Commandes basées sur le contenu réel du passage
    if (text.contains('aimer') || text.contains('amour')) {
      options.add({'label': 'Aimer Dieu et son prochain', 'tags': ['command', 'love']});
    }
    if (text.contains('prier') || text.contains('prière')) {
      options.add({'label': 'Prier sans cesse', 'tags': ['command', 'prayer']});
    }
    if (text.contains('témoin') || text.contains('témoigner')) {
      options.add({'label': 'Être témoin de Jésus', 'tags': ['command', 'witness']});
    }
    if (text.contains('obéir') || text.contains('obéissance')) {
      options.add({'label': 'Obéir aux commandements', 'tags': ['command', 'obedience']});
    }
    if (text.contains('servir') || text.contains('service')) {
      options.add({'label': 'Servir Dieu', 'tags': ['command', 'service']});
    }
    if (text.contains('proclamer') || text.contains('annoncer')) {
      options.add({'label': 'Proclamer la Parole', 'tags': ['command', 'witness']});
    }
    if (text.contains('garder') || text.contains('garder')) {
      options.add({'label': 'Garder les commandements', 'tags': ['command', 'obedience']});
    }
    if (text.contains('suivre') || text.contains('suivre')) {
      options.add({'label': 'Suivre Jésus', 'tags': ['command', 'discipleship']});
    }
    
    // Commandes basées sur le type d'unité littéraire
    if (unit != null) {
      switch (unit.type) {
        case UnitType.parable:
          options.add({'label': 'Commandes de cette parabole', 'tags': ['command', 'wisdom']});
          break;
        case UnitType.discourse:
          options.add({'label': 'Commandes de cet enseignement', 'tags': ['command', 'wisdom']});
          break;
        case UnitType.letter:
          options.add({'label': 'Commandes apostoliques', 'tags': ['command', 'doctrine']});
          break;
        case UnitType.prophecy:
          options.add({'label': 'Commandes prophétiques', 'tags': ['command', 'prophecy']});
          break;
        default:
          break;
      }
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Aucune commande dans ce passage', 'tags': []});
    }
    
    return options;
  }

  Widget _buildFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _canContinue 
          ? const LinearGradient(
              colors: [
                Color(0xFF1553FF),
                Color(0xFF0D47A1),
              ],
            )
          : null,
        boxShadow: _canContinue ? [
          BoxShadow(
            color: const Color(0xFF1553FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: FloatingActionButton.extended(
        onPressed: _canContinue ? () {
          HapticFeedback.lightImpact();
          _finish();
        } : null,
        backgroundColor: _canContinue ? Colors.transparent : Colors.white.withOpacity(0.3),
        foregroundColor: _canContinue ? Colors.white : Colors.white.withOpacity(0.5),
        elevation: 0,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          'Continuer vers la prière',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        tooltip: 'Continuer vers la prière',
      ),
    );
  }

  String _normalizeRef(String? ref) => (ref ?? '')
      .replaceAll('.', ':')
      .replaceAll('_', '-')
      .replaceAll('\u2013', '-')
      .replaceAll('\u2014', '-')
      .replaceAll(RegExp(r'\s+'), ' ') // Éviter les espaces bizarres
      .trim();

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'gratitude':
        return const Color(0xFF2ECC71);
      case 'repentance':
        return const Color(0xFF8E44AD);
      case 'obedience':
        return const Color(0xFFF39C12);
      case 'promise':
        return const Color(0xFF9B59B6);
      case 'intercession':
        return const Color(0xFF96CEB4);
      case 'praise':
        return const Color(0xFFFF6B6B);
      case 'trust':
        return const Color(0xFF54A0FF);
      case 'guidance':
        return const Color(0xFF5F27CD);
      case 'warning':
        return const Color(0xFFFF6348);
      case 'responsibility':
        return const Color(0xFF6C5CE7);
      case 'awe':
        return const Color(0xFF2D3436);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _softBlob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.20), Colors.transparent],
        ),
      ),
    );
  }
}