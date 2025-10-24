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
  // questionId -> selected options
  final Map<String, Set<String>> _answers = {};
  final Map<String, TextEditingController> _freeByQuestion = {};
  // questionId -> selected tags
  final Map<String, Set<String>> _selectedTagsByField = {};

  // Les questions avec leurs options générées intelligemment
  List<Map<String, dynamic>> _questions = [];
  // questionId -> { optionLabel -> [tags] }
  final Map<String, Map<String, List<String>>> _tagsIndex = {};
  String? _lastKey;

  static const _fallbackDemo = '''
Jésus se rendit en Samarie... "Donne-moi à boire" ... "il t'aurait donné de l'eau vive".
  ''';

  @override
  void initState() {
    super.initState();
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
      if (mounted) setState(() {});
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
    if (_lastKey == key && _questions.isNotEmpty) {
      return; // pas de regénération
    }
    _lastKey = key;

    final text = (widget.passageText ?? _fallbackDemo).trim();

    // 1) calcule tout hors setState
    final generated = await _generateIntelligentQuestions(text);

    final answers = <String, Set<String>>{};
    final freeByQuestion = <String, TextEditingController>{};
    final selectedTagsByField = <String, Set<String>>{};
    final tagsIndex = <String, Map<String, List<String>>>{};

    for (final q in generated) {
      final qid = q['id'] as String;

      // init sûrs
      answers[qid] = _answers[qid] ?? <String>{};
      freeByQuestion[qid] = _freeByQuestion[qid] ?? TextEditingController();
      selectedTagsByField[qid] = _selectedTagsByField[qid] ?? <String>{};

      final opts = (q['options'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final map = <String, List<String>>{};
      for (final opt in opts) {
        final lbl = (opt['label'] ?? '').toString();
        final tg = (opt['tags'] as List?)?.map((e) => e.toString()).toList()
            ?? const <String>[];
        if (lbl.isNotEmpty) map[lbl] = tg;
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
  }

  // Validation pour permettre de continuer
  bool get _canContinue {
    final hasSelectedOptions = _answers.values.any((s) => s.isNotEmpty);
    final hasFree = _freeByQuestion.values.any((c) => c.text.trim().isNotEmpty);
    return hasSelectedOptions || hasFree;
  }

  // Helper pour garantir des options même si la liste est vide
  List<Map<String, dynamic>> _withFallback(
    List<Map<String, dynamic>>? opts,
    List<Map<String, dynamic>> fallback,
  ) {
    if (opts == null || opts.isEmpty) return fallback;
    return opts;
  }

  Future<List<Map<String, dynamic>>> _generateIntelligentQuestions(String passage) async {
    // Générer des options spécifiques au passage
    final specificOptions = await _generateSpecificOptions(passage);
    
    print('🔍 DEBUG - _generateIntelligentQuestions');
    print('🔍 specificOptions keys: ${specificOptions.keys.toList()}');

    return [
      {
        'id': 'de_quoi_qui',
        'question': 'De quoi ou de qui parlent ces versets ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['de_quoi_qui'],
          [
            {'label': 'Jésus / le Seigneur', 'tags': ['jésus','seigneur']},
            {'label': 'Un événement du récit', 'tags': ['récit','événement']},
            {'label': 'Des personnes du passage', 'tags': ['personnages']},
            {'label': 'Autre', 'tags': []},
          ],
        ),
      },
      {
        'id': 'apprend_dieu',
        'question': 'Est-ce que ce passage m\'apprend quelque chose sur Dieu ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['apprend_dieu'],
          [
            {'label': 'Dieu agit / parle', 'tags': ['révélation','dieu']},
            {'label': 'Dieu appelle à la foi', 'tags': ['foi','révélation']},
            {'label': 'Rien de spécifique', 'tags': []},
          ],
        ),
      },
      {
        'id': 'exemple',
        'question': 'Y a-t-il un exemple à suivre ou à ne pas suivre ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['exemple'],
          [
            {'label': 'Exemple à suivre', 'tags': ['exemple','positif']},
            {'label': 'Exemple à éviter', 'tags': ['exemple','négatif']},
            {'label': 'Aucun exemple particulier', 'tags': []},
          ],
        ),
      },
      {
        'id': 'ordre',
        'question': 'Y a-t-il un ordre ou une instruction à suivre ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['ordre'],
          [
            {'label': 'Prier / Chercher Dieu', 'tags': ['prière','obéissance']},
            {'label': 'Aimer / Servir', 'tags': ['amour','service']},
            {'label': 'Aucune instruction spécifique', 'tags': []},
          ],
        ),
      },
      {
        'id': 'promesse',
        'question': 'Y a-t-il une promesse ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['promesse'],
          [
            {'label': 'Promesse de paix / présence', 'tags': ['promesse','paix']},
            {'label': 'Promesse du Saint-Esprit', 'tags': ['promesse','esprit']},
            {'label': 'Aucune promesse directe', 'tags': []},
          ],
        ),
      },
      {
        'id': 'avertissement',
        'question': 'Y a-t-il un avertissement ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['avertissement'],
          [
            {'label': 'Avertissement contre le péché / jugement', 'tags': ['warning']},
            {'label': 'Aucun avertissement', 'tags': []},
          ],
        ),
      },
      {
        'id': 'commande',
        'question': 'Y a-t-il un commandement ou une règle à respecter ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['commande'],
          [
            {'label': 'Respecter les commandements de Dieu', 'tags': ['commandement','loi']},
            {'label': 'Suivre les règles de vie chrétienne', 'tags': ['règle','vie']},
            {'label': 'Aucune règle spécifique', 'tags': []},
          ],
        ),
      },
      {
        'id': 'personnage_principal',
        'question': 'Qui est le personnage principal ?',
        'type': 'single',
        'options': _withFallback(
          specificOptions['personnage_principal'],
          [
            {'label': 'Jésus', 'tags': ['jésus']},
            {'label': 'Un personnage du récit', 'tags': ['personnages']},
            {'label': 'Autre', 'tags': []},
          ],
        ),
      },
      {
        'id': 'emotion',
        'question': 'Quelle émotion ce passage éveille-t-il en moi ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['emotion'],
          [
            {'label': 'Confiance et foi', 'tags': ['foi','confiance']},
            {'label': 'Paix et sérénité', 'tags': ['paix','sérénité']},
            {'label': 'Gratitude', 'tags': ['gratitude']},
          ],
        ),
      },
      {
        'id': 'application',
        'question': 'Comment puis-je appliquer ce passage à ma vie ?',
        'type': 'multi',
        'options': _withFallback(
          specificOptions['application'],
          [
            {'label': 'Prier régulièrement', 'tags': ['prière','habitude']},
            {'label': 'Aimer concrètement', 'tags': ['amour','service']},
            {'label': 'Obéir à un commandement précis', 'tags': ['obéissance']},
          ],
        ),
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
      final selected = _answers.putIfAbsent(questionId, () => <String>{});
      final selectedTags = _selectedTagsByField.putIfAbsent(questionId, () => <String>{});
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
          for (final t in optionTags) {
            selectedTags.remove(t);
          }
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

    _answers.forEach((questionId, selectedLabels) {
      selectedAnswersByField[questionId] = {...selectedLabels};
    });

    _freeByQuestion.forEach((field, controller) {
      freeTextResponses[field] = controller.text.trim();
    });

    // Utiliser le nouveau système intelligent de génération de sujets
    final prayerSubjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: _selectedTagsByField,
      freeTexts: freeTextResponses,
      passageText: widget.passageText,
      passageRef: widget.passageRef,
    );

    // Convertir en PrayerItem pour la compatibilité
    final items = prayerSubjects
        .map((subject) => PrayerItem(
              theme: subject.category,
              subject: subject.label,
              color: _getColorForCategory(subject.category),
            ))
        .toList();

    context.go('/payerpage', extra: {
      'items': items,
      'memoryVerse': '',
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
                      Positioned(right: -60, top: -40, child: _softBlob(180)),
                      Positioned(left: -40, bottom: -50, child: _softBlob(220)),
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: Colors.white.withOpacity(0.7),
                          radioTheme: RadioThemeData(
                            fillColor: MaterialStateProperty.all(Colors.white),
                          ),
                          checkboxTheme: CheckboxThemeData(
                            fillColor: MaterialStateProperty.all(Colors.white),
                            checkColor: MaterialStateProperty.all(
                                const Color(0xFF1A1D29)),
                          ),
                        ),
                        child: _questions.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(
                                    20, 20, 20, 100),
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
                if (widget.passageRef != null &&
                    widget.passageRef!.isNotEmpty)
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
          const SizedBox(width: 48),
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
    final questionId = (question['id'] ?? '').toString();
    final questionText = (question['question'] ?? '').toString();
    final type = (question['type'] ?? 'multi').toString();

    // 🔒 options toujours non-null, bien typées
    final options = (question['options'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];

    // 🔒 plus de "!" : on ne lit .first que si le set non-null et non-vide
    final selSet = _answers[questionId];
    final String? singleSelected =
        (type == 'single' && selSet != null && selSet.isNotEmpty)
            ? selSet.first
            : null;

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

            ...options.map((opt) {
              final label = opt['label'] as String;
              final tags = (opt['tags'] as List).cast<String>();
              final isSelected =
                  _answers[questionId]?.contains(label) ?? false;

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
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
        color: isSelected
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.white.withOpacity(0.30)
              : Colors.white.withOpacity(0.15),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          checkboxShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
        color: (selectedValue == label)
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (selectedValue == label)
              ? Colors.white.withOpacity(0.30)
              : Colors.white.withOpacity(0.15),
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
              fontWeight:
                  (selectedValue == label) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
            if (mounted) setState(() {});
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
              onChanged: (_) {
                if (mounted) setState(() {});
              },
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

  Map<String, dynamic>? _parseRef(String ref) {
    ref = ref.trim();
    final m = RegExp(r'^(.*)\s+(\d+):(\d+)(?:-(\d+)(?::(\d+))?)?$').firstMatch(ref);
    if (m != null) {
      final book = (m.group(1) ?? '').trim();
      final sc = int.parse(m.group(2)!);
      final sv = int.parse(m.group(3)!);
      late final int ec;
      late final int ev;

      if (m.group(5) != null) {
        ec = int.parse(m.group(4)!);
        ev = int.parse(m.group(5)!);
      } else if (m.group(4) != null) {
        ec = sc;
        ev = int.parse(m.group(4)!);
      } else {
        ec = sc;
        ev = sv;
      }
      return {'book': book, 'sc': sc, 'sv': sv, 'ec': ec, 'ev': ev};
    }

    final tokens = ref.split(RegExp(r'\s+'));
    if (tokens.length >= 2) {
      final last = tokens.last;
      final m2 = RegExp(r'^(\d+):(\d+)(?:-(\d+)(?::(\d+))?)?$').firstMatch(last);
      if (m2 != null) {
        final book = tokens.sublist(0, tokens.length - 1).join(' ').trim();
        final sc = int.parse(m2.group(1)!);
        final sv = int.parse(m2.group(2)!);
        late final int ec;
        late final int ev;

        if (m2.group(4) != null) {
          ec = int.parse(m2.group(3)!);
          ev = int.parse(m2.group(4)!);
        } else if (m2.group(3) != null) {
          ec = sc;
          ev = int.parse(m2.group(3)!);
        } else {
          ec = sc;
          ev = sv;
        }
        return {'book': book, 'sc': sc, 'sv': sv, 'ec': ec, 'ev': ev};
      }
    }
    return null;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _generateSpecificOptions(String passage) async {
    // 0) Normalisation basique + texte source
    final raw = (passage.isEmpty ? (widget.passageText ?? _fallbackDemo) : passage).trim();
    String _normalize(String s) => s
        .toLowerCase()
        .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e')
        .replaceAll('à', 'a').replaceAll('â', 'a')
        .replaceAll('î', 'i').replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u').replaceAll('û', 'u').replaceAll('ü', 'u');
    final text = _normalize(raw);

    // 1) Structure de sortie
    final Map<String, List<Map<String, dynamic>>> out = {
      'de_quoi_qui': [],
      'apprend_dieu': [],
      'exemple': [],
      'ordre': [],
      'promesse': [],
      'avertissement': [],
      'commande': [],
      'personnage_principal': [],
      'emotion': [],
      'application': [],
    };

    // util d'ajout (évite les doublons)
    void add(String k, String label, List<String> tags) {
      final list = out[k] ?? <Map<String, dynamic>>[];
      if (!list.any((m) => (m['label'] as String).toLowerCase() == label.toLowerCase())) {
        list.add({'label': label, 'tags': tags});
      }
      out[k] = list;
    }

    // 2) Détection "qui/quoi" + thèmes évidents à partir du texte
    if (RegExp(r'\bj[e|e]sus\b').hasMatch(text) || RegExp(r'\bchrist\b').hasMatch(text)) {
      add('de_quoi_qui', 'Jésus', ['jésus','seigneur']);
      add('personnage_principal', 'Jésus-Christ', ['jésus','seigneur']);
    }
    if (RegExp(r'\bdieu\b|\beternel\b').hasMatch(text)) {
      add('de_quoi_qui', 'Dieu', ['dieu']);
      add('apprend_dieu', 'Dieu agit / parle dans ce passage', ['révélation','dieu']);
    }
    if (RegExp(r'\b(apotres?|disciples?)\b').hasMatch(text)) {
      add('de_quoi_qui', 'Les disciples / apôtres', ['disciples','apôtres']);
      add('exemple', 'Exemple des disciples (foi / disponibilité)', ['exemple','positif']);
    }
    if (RegExp(r'\bpharisiens?\b').hasMatch(text)) {
      add('de_quoi_qui', 'Les pharisiens', ['pharisiens']);
      add('exemple', 'Exemple à éviter : hypocrisie / dureté', ['exemple','négatif']);
    }

    // 3) Impératifs / ordres / commandes (mots fréquents)
    if (RegExp(r'\b(aimer?|amour|charite)\b').hasMatch(text)) {
      add('ordre', 'Aimer Dieu et son prochain', ['amour','obéissance']);
      add('commande', 'Aime ton prochain', ['command','amour']);
      add('application', 'Aimer concrètement aujourd\'hui', ['amour','service']);
    }
    if (RegExp(r'\b(prier?|priere|prions|priant)\b').hasMatch(text)) {
      add('ordre', 'Prier', ['prière','obéissance']);
      add('application', 'Prier régulièrement', ['prière','habitude']);
      add('emotion', 'Paix et sérénité', ['paix','sérénité']);
    }
    if (RegExp(r'\b(croire|foi|croyez?)\b').hasMatch(text)) {
      add('ordre', 'Croire / faire confiance', ['foi','obéissance']);
      add('apprend_dieu', 'Dieu appelle à la foi', ['foi','révélation']);
      add('emotion', 'Confiance et foi', ['foi','assurance']);
    }
    if (RegExp(r'\brepent(ance|ir)\b').hasMatch(text)) {
      add('ordre', 'Se repentir', ['repentance','obéissance']);
      add('avertissement', 'Avertissement contre le péché', ['warning','péché']);
      add('application', 'Confesser et abandonner une habitude', ['repentance','application']);
    }

    // 4) Promesses / avertissements fréquents
    if (RegExp(r'\b(paix|consolateur|repos|reconfort)\b').hasMatch(text)) {
      add('promesse', 'Promesse de paix / consolation', ['promesse','paix']);
    }
    if (RegExp(r'\b(saint[ -]?esprit|esprit de (verite|dieu))\b').hasMatch(text)) {
      add('promesse', 'Promesse du Saint-Esprit', ['promesse','esprit']);
      add('apprend_dieu', 'Dieu envoie l\'Esprit', ['esprit','révélation']);
    }
    if (RegExp(r'\b(jugement|condamnation|chatiment|malheur)\b').hasMatch(text)) {
      add('avertissement', 'Avertissement du jugement', ['warning','jugement']);
      add('emotion', 'Crainte révérencielle', ['crainte','révérence']);
    }

    // 5) Génération d'exemples contextuels (à suivre / à éviter)
    final hasNeg = RegExp(r'\b(hypocrisie|orgueil|idolatrie|trahison|violence|mensonge|peche)\b').hasMatch(text);
    final hasPos = RegExp(r'\b(foi|obeissance|humilite|amour|service|perseverance|generosite|pardon)\b').hasMatch(text);
    if (hasPos) {
      add('exemple', 'Exemple à suivre : foi / obéissance / amour', ['exemple','positif']);
    }
    if (hasNeg) {
      add('exemple', 'Exemple à éviter : péché / orgueil / hypocrisie', ['exemple','négatif']);
    }

    // 6) Enrichissement par unité littéraire (si passageRef dispo)
    LiteraryUnit? unit;
    final passageRef = (widget.passageRef ?? '').trim();
    if (passageRef.isNotEmpty) {
      try {
        final parsed = _parseRef(passageRef);
        if (parsed != null && (parsed['book'] as String).isNotEmpty) {
          final semantic = await SemanticPassageBoundaryService.adjustPassageVerses(
            book: parsed['book'] as String,
            startChapter: parsed['sc'] as int,
            startVerse: parsed['sv'] as int,
            endChapter: parsed['ec'] as int,
            endVerse: parsed['ev'] as int,
          );
          unit = semantic.includedUnit;
          if (unit != null) {
            switch (unit.type) {
              case UnitType.parable:
                add('de_quoi_qui', 'Une parabole de Jésus', ['parable','jésus']);
                add('exemple', 'Leçon pratique de la parabole', ['exemple','parabole']);
                break;
              case UnitType.discourse:
                add('de_quoi_qui', 'Un discours / enseignement', ['discours','enseignement']);
                add('ordre', 'Mettre en pratique cet enseignement', ['obéissance','pratique']);
                break;
              case UnitType.narrative:
                add('de_quoi_qui', 'Un récit d\'événements', ['récit','histoire']);
                add('exemple', 'Exemple des personnages', ['exemple','personnages']);
                break;
              case UnitType.poetry:
                add('emotion', 'Adoration et louange', ['adoration','louange']);
                add('application', 'Louer Dieu à partir de ce texte', ['louange','application']);
                break;
              case UnitType.prophecy:
                add('avertissement', 'Appel prophétique / avertissement', ['warning','prophétie']);
                add('promesse', 'Promesse prophétique', ['promesse','prophétie']);
                break;
              case UnitType.letter:
                add('de_quoi_qui', 'Une lettre apostolique', ['lettre','apostolique']);
                add('ordre', 'Vivre ces instructions', ['obéissance','doctrine']);
                break;
              default:
                break;
            }
            if (unit.bsbThemes != null && unit.bsbThemes!.isNotEmpty) {
              for (final t in unit.bsbThemes!) {
                add('de_quoi_qui', 'Thème: $t', ['thème', t.toLowerCase()]);
              }
            }
          }
        }
      } catch (_) {/* silencieux */}
    }

    // 7) Appel des générateurs sémantiques (richesse contextuelle)
    // NB: on les fusionne avec ce qui existe déjà (et on garde tout dédoublonné)
    List<Map<String, dynamic>> _merge(List<Map<String, dynamic>> base, List<Map<String, dynamic>> extra) {
      for (final e in extra) add('__tmp__', e['label'] as String, (e['tags'] as List).cast<String>());
      final merged = List<Map<String, dynamic>>.from(base)..addAll(extra);
      // add() a déjà dédoublonné via la clé virtuelle '__tmp__', on ne garde que merged unique via Set titres
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final m in merged) {
        final k = (m['label'] as String).toLowerCase();
        if (seen.add(k)) unique.add(m);
      }
      out.remove('__tmp__');
      return unique;
    }

    out['apprend_dieu']       = _merge(out['apprend_dieu']!,       _generateSemanticCharacters(raw, unit));
    out['emotion']            = _merge(out['emotion']!,            _generateSemanticEmotions(raw, unit));
    out['application']        = _merge(out['application']!,        _generateSemanticApplications(raw, unit));
    out['ordre']              = _merge(out['ordre']!,              _generateSemanticOrders(raw, unit));
    out['promesse']           = _merge(out['promesse']!,           _generateSemanticPromises(raw, unit));
    out['avertissement']      = _merge(out['avertissement']!,      _generateSemanticWarnings(raw, unit));
    out['commande']           = _merge(out['commande']!,           _generateSemanticCommands(raw, unit));

    // 8) Garde-fous: jamais de liste vide
    out.update('de_quoi_qui', (v) => _withFallback(v, [
      {'label': 'Jésus / le Seigneur', 'tags': ['jésus','seigneur']},
      {'label': 'Un événement du récit', 'tags': ['récit']},
      {'label': 'Des personnes du passage', 'tags': ['personnages']},
    ]));
    out.update('apprend_dieu', (v) => _withFallback(v, [
      {'label': 'Dieu agit / parle', 'tags': ['révélation','dieu']},
      {'label': 'Dieu appelle à la foi', 'tags': ['foi','révélation']},
      {'label': 'Rien de spécifique', 'tags': []},
    ]));
    out.update('exemple', (v) => _withFallback(v, [
      {'label': 'Exemple à suivre : foi / obéissance', 'tags': ['exemple','positif']},
      {'label': 'Exemple à éviter : péché / orgueil', 'tags': ['exemple','négatif']},
      {'label': 'Aucun exemple particulier', 'tags': []},
    ]));
    out.update('ordre', (v) => _withFallback(v, [
      {'label': 'Prier / Chercher Dieu', 'tags': ['prière','obéissance']},
      {'label': 'Aimer / Servir', 'tags': ['amour','service']},
      {'label': 'Aucun ordre spécifique', 'tags': []},
    ]));
    out.update('promesse', (v) => _withFallback(v, [
      {'label': 'Promesse de paix / présence', 'tags': ['promesse','paix']},
      {'label': 'Promesse du Saint-Esprit', 'tags': ['promesse','esprit']},
      {'label': 'Aucune promesse directe', 'tags': []},
    ]));
    out.update('avertissement', (v) => _withFallback(v, [
      {'label': 'Avertissement contre le péché / jugement', 'tags': ['warning']},
      {'label': 'Aucun avertissement', 'tags': []},
    ]));
    out.update('commande', (v) => _withFallback(v, [
      {'label': 'Mettre en pratique aujourd\'hui', 'tags': ['command','application']},
      {'label': 'Aucune commande', 'tags': []},
    ]));
    out.update('personnage_principal', (v) => _withFallback(v, [
      {'label': 'Jésus', 'tags': ['jésus']},
      {'label': 'Un personnage du récit', 'tags': ['personnages']},
      {'label': 'Autre', 'tags': []},
    ]));
    out.update('emotion', (v) => _withFallback(v, [
      {'label': 'Confiance et foi', 'tags': ['foi','confiance']},
      {'label': 'Paix et sérénité', 'tags': ['paix','sérénité']},
      {'label': 'Gratitude', 'tags': ['gratitude']},
    ]));
    out.update('application', (v) => _withFallback(v, [
      {'label': 'Prier régulièrement', 'tags': ['prière','habitude']},
      {'label': 'Aimer concrètement', 'tags': ['amour','service']},
      {'label': 'Obéir à un commandement précis', 'tags': ['obéissance']},
    ]));

    return out;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MÉTHODES SÉMANTIQUES
  // ───────────────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _generateSemanticCharacters(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];

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

  List<Map<String, dynamic>> _generateSemanticEmotions(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];

    if (text.contains('joie') || text.contains('allégresse') || text.contains('réjouir')) {
      options.add({'label': 'Joie et allégresse', 'tags': ['joie', 'bonheur', 'célébration']});
    }
    if (text.contains('espoir') || text.contains('espérance') || text.contains('attendre')) {
      options.add({'label': 'Espoir et anticipation', 'tags': ['espoir', 'anticipation', 'attente']});
    }
    if (text.contains('crainte') || text.contains('respect')) {
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

  List<Map<String, dynamic>> _generateSemanticOrders(String passage, LiteraryUnit? unit) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];

    if (text.contains('prier') || text.contains('prière')) {
      options.add({'label': 'Prier sans cesse', 'tags': ['obedience', 'trust']});
    }
    if (text.contains('attendre')) {
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
    if (text.contains('garder')) {
      options.add({'label': 'Garder les commandements', 'tags': ['obedience', 'trust']});
    }

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
    if (text.contains('garder')) {
      options.add({'label': 'Garder les commandements', 'tags': ['command', 'obedience']});
    }
    if (text.contains('suivre')) {
      options.add({'label': 'Suivre Jésus', 'tags': ['command', 'discipleship']});
    }

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
        boxShadow: _canContinue
            ? [
                BoxShadow(
                  color: const Color(0xFF1553FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FloatingActionButton.extended(
        onPressed: _canContinue
            ? () {
                HapticFeedback.lightImpact();
                _finish();
              }
            : null,
        backgroundColor:
            _canContinue ? Colors.transparent : Colors.white.withOpacity(0.3),
        foregroundColor:
            _canContinue ? Colors.white : Colors.white.withOpacity(0.5),
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
      .replaceAll(RegExp(r'\s+'), ' ')
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