import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/passage_qcm_builder.dart';
import '../models/passage_analysis.dart';
import '../services/prayer_subjects_builder.dart';

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

  // Les 8 questions fixes avec leurs options générées intelligemment
  late List<Map<String, dynamic>> _questions;

  static const _fallbackDemo = '''
Jésus se rendit en Samarie... "Donne-moi à boire" ... "il t'aurait donné de l'eau vive".
  ''';

  @override
  void initState() {
    super.initState();
    final text = (widget.passageText ?? _fallbackDemo).trim();
    
    // Générer les options intelligentes pour chaque question fixe
    _questions = _generateIntelligentQuestions(text);
    
    for (final q in _questions) {
      _answers[q['id']] = <String>{};
      _freeByQuestion[q['id']] = TextEditingController();
    }
  }

  List<Map<String, dynamic>> _generateIntelligentQuestions(String passage) {
    // Analyser le passage avec passage_analysis.dart
    final facts = extractFacts(passage);
    
    // Utiliser buildDynamicQcm pour générer des options variées
    final dynamicQcm = buildDynamicQcm(passage);
    
    // Analyser le passage pour générer des options intelligentes
    final actors = _extractActors(passage);
    final actions = _extractActions(passage);
    final themes = _extractThemes(passage);
    final promises = _extractPromises(passage);
    final warnings = _extractWarnings(passage);
    final commands = _extractCommands(passage);
    final godAttributes = _extractGodAttributes(passage);

    return [
      {
        'id': 'de_quoi_qui',
        'question': 'De quoi ou de qui parlent ces versets ?',
        'type': 'multi',
        'options': [
          // Utiliser les personnages extraits du passage
          ...facts.people.map((person) => {'label': person, 'tags': ['intercession']}),
          if (passage.toLowerCase().contains('dieu') || passage.toLowerCase().contains('jésus') || passage.toLowerCase().contains('seigneur'))
            {'label': 'Dieu / Jésus-Christ', 'tags': ['praise', 'trust']},
          if (passage.toLowerCase().contains('enseign') || passage.toLowerCase().contains('apprend'))
            {'label': 'Un enseignement moral', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('prophét') || passage.toLowerCase().contains('annonc'))
            {'label': 'Une prophétie', 'tags': ['promise', 'trust']},
          {'label': 'Autre', 'tags': []},
        ],
      },
      {
        'id': 'apprend_dieu',
        'question': 'Est-ce que ce passage m\'apprend quelque chose sur Dieu ?',
        'type': 'multi',
        'options': [
          // Utiliser les événements clés du passage pour comprendre ce qu'on apprend de Dieu
          ...facts.keyEvents.take(3).map((event) => {
            'label': 'Dieu révélé dans: ${event.length > 50 ? event.substring(0, 47) + '...' : event}',
            'tags': ['praise', 'gratitude']
          }),
          ...godAttributes.map((attr) => {'label': attr, 'tags': ['praise', 'gratitude']}),
          if (passage.toLowerCase().contains('amour') || passage.toLowerCase().contains('grâce'))
            {'label': 'Son amour et sa grâce', 'tags': ['praise', 'gratitude']},
          if (passage.toLowerCase().contains('justice') || passage.toLowerCase().contains('saint'))
            {'label': 'Sa justice et sa sainteté', 'tags': ['repentance', 'awe']},
          if (passage.toLowerCase().contains('sagesse') || passage.toLowerCase().contains('direction'))
            {'label': 'Sa sagesse et sa direction', 'tags': ['guidance']},
          if (passage.toLowerCase().contains('fidél') || passage.toLowerCase().contains('promesse'))
            {'label': 'Sa fidélité et ses promesses', 'tags': ['trust', 'promise']},
          if (passage.toLowerCase().contains('puissance') || passage.toLowerCase().contains('majest'))
            {'label': 'Sa puissance et sa majesté', 'tags': ['praise', 'awe']},
          {'label': 'Rien de spécifique', 'tags': []},
        ],
      },
      {
        'id': 'exemple',
        'question': 'Y a-t-il un exemple à suivre ou à ne pas suivre ?',
        'type': 'multi',
        'options': [
          // Utiliser les événements du passage pour identifier des exemples
          ...facts.keyEvents.take(2).map((event) => {
            'label': 'Exemple dans le passage: ${event.length > 40 ? event.substring(0, 37) + '...' : event}',
            'tags': ['obedience']
          }),
          if (passage.toLowerCase().contains('foi') || passage.toLowerCase().contains('croire'))
            {'label': 'Un exemple de foi à imiter', 'tags': ['trust', 'obedience']},
          if (passage.toLowerCase().contains('amour') || passage.toLowerCase().contains('aimer'))
            {'label': 'Un exemple d\'amour à suivre', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('obéir') || passage.toLowerCase().contains('écouter'))
            {'label': 'Un exemple d\'obéissance', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('péché') || passage.toLowerCase().contains('mal'))
            {'label': 'Un mauvais exemple à éviter', 'tags': ['warning', 'repentance']},
          if (passage.toLowerCase().contains('repent') || passage.toLowerCase().contains('regret'))
            {'label': 'Un exemple de repentance', 'tags': ['repentance']},
          {'label': 'Aucun exemple particulier', 'tags': []},
        ],
      },
      {
        'id': 'ordre',
        'question': 'Y a-t-il un ordre auquel obéir ?',
        'type': 'multi',
        'options': [
          // Utiliser les lieux du passage pour identifier des contextes d'obéissance
          ...facts.places.map((place) => {'label': 'Obéir dans le contexte de: $place', 'tags': ['obedience']}),
          ...commands.map((cmd) => {'label': cmd, 'tags': ['obedience']}),
          if (passage.toLowerCase().contains('aimer') && passage.toLowerCase().contains('dieu'))
            {'label': 'Aimer Dieu de tout mon cœur', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('aimer') && passage.toLowerCase().contains('prochain'))
            {'label': 'Aimer mon prochain', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('prier') || passage.toLowerCase().contains('méditer'))
            {'label': 'Prier et méditer', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('évangile') || passage.toLowerCase().contains('annoncer'))
            {'label': 'Partager l\'Évangile', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('saint') || passage.toLowerCase().contains('pur'))
            {'label': 'Vivre dans la sainteté', 'tags': ['obedience', 'repentance']},
          {'label': 'Aucun ordre spécifique', 'tags': []},
        ],
      },
      {
        'id': 'promesse',
        'question': 'Y a-t-il une promesse ?',
        'type': 'multi',
        'options': [
          // Utiliser les événements du passage pour identifier des promesses
          ...facts.keyEvents.where((event) => 
            event.toLowerCase().contains('donner') || 
            event.toLowerCase().contains('recevoir') ||
            event.toLowerCase().contains('aura') ||
            event.toLowerCase().contains('sera')
          ).take(2).map((event) => {
            'label': 'Promesse dans le passage: ${event.length > 45 ? event.substring(0, 42) + '...' : event}',
            'tags': ['promise', 'trust']
          }),
          ...promises.map((promise) => {'label': promise, 'tags': ['promise', 'trust']}),
          if (passage.toLowerCase().contains('salut') || passage.toLowerCase().contains('sauver'))
            {'label': 'Promesse de salut', 'tags': ['promise', 'trust']},
          if (passage.toLowerCase().contains('guid') || passage.toLowerCase().contains('direction'))
            {'label': 'Promesse de guidance', 'tags': ['guidance', 'trust']},
          if (passage.toLowerCase().contains('protect') || passage.toLowerCase().contains('garde'))
            {'label': 'Promesse de protection', 'tags': ['trust']},
          if (passage.toLowerCase().contains('bénédict') || passage.toLowerCase().contains('bénir'))
            {'label': 'Promesse de bénédiction', 'tags': ['gratitude', 'promise']},
          if (passage.toLowerCase().contains('présent') || passage.toLowerCase().contains('avec'))
            {'label': 'Promesse de présence', 'tags': ['trust']},
          {'label': 'Aucune promesse', 'tags': []},
        ],
      },
      {
        'id': 'avertissement',
        'question': 'Y a-t-il un avertissement ?',
        'type': 'multi',
        'options': [
          // Utiliser les événements du passage pour identifier des avertissements
          ...facts.keyEvents.where((event) => 
            event.toLowerCase().contains('ne') || 
            event.toLowerCase().contains('pas') ||
            event.toLowerCase().contains('attention') ||
            event.toLowerCase().contains('gare')
          ).take(2).map((event) => {
            'label': 'Avertissement dans le passage: ${event.length > 45 ? event.substring(0, 42) + '...' : event}',
            'tags': ['warning', 'repentance']
          }),
          ...warnings.map((warning) => {'label': warning, 'tags': ['warning', 'repentance']}),
          if (passage.toLowerCase().contains('péché') || passage.toLowerCase().contains('faute'))
            {'label': 'Avertissement contre le péché', 'tags': ['warning', 'repentance']},
          if (passage.toLowerCase().contains('apostas') || passage.toLowerCase().contains('abandon'))
            {'label': 'Avertissement contre l\'apostasie', 'tags': ['warning']},
          if (passage.toLowerCase().contains('orgueil') || passage.toLowerCase().contains('fier'))
            {'label': 'Avertissement contre l\'orgueil', 'tags': ['warning', 'repentance']},
          if (passage.toLowerCase().contains('idolâtr') || passage.toLowerCase().contains('adorer'))
            {'label': 'Avertissement contre l\'idolâtrie', 'tags': ['warning', 'repentance']},
          if (passage.toLowerCase().contains('conséquenc') || passage.toLowerCase().contains('résultat'))
            {'label': 'Avertissement sur les conséquences', 'tags': ['warning']},
          {'label': 'Aucun avertissement', 'tags': []},
        ],
      },
      {
        'id': 'verite',
        'question': 'Quelle vérité Dieu me révèle-t-il ?',
        'type': 'multi',
        'options': [
          // Utiliser les événements du passage pour identifier des vérités révélées
          ...facts.keyEvents.take(3).map((event) => {
            'label': 'Vérité révélée: ${event.length > 50 ? event.substring(0, 47) + '...' : event}',
            'tags': ['praise', 'gratitude']
          }),
          if (passage.toLowerCase().contains('homme') || passage.toLowerCase().contains('humain'))
            {'label': 'Vérité sur ma condition humaine', 'tags': ['repentance']},
          if (passage.toLowerCase().contains('amour') && passage.toLowerCase().contains('dieu'))
            {'label': 'Vérité sur l\'amour de Dieu', 'tags': ['praise', 'gratitude']},
          if (passage.toLowerCase().contains('plan') || passage.toLowerCase().contains('volonté'))
            {'label': 'Vérité sur le plan de Dieu', 'tags': ['trust', 'guidance']},
          if (passage.toLowerCase().contains('chrétien') || passage.toLowerCase().contains('vie'))
            {'label': 'Vérité sur la vie chrétienne', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('espérance') || passage.toLowerCase().contains('avenir'))
            {'label': 'Vérité sur l\'espérance', 'tags': ['trust', 'promise']},
          {'label': 'Autre vérité', 'tags': []},
        ],
      },
      {
        'id': 'autres_passages',
        'question': 'Y a-t-il d\'autres passages bibliques qui m\'aident à comprendre ?',
        'type': 'multi',
        'options': [
          // Utiliser les personnages du passage pour suggérer des passages connexes
          ...facts.people.map((person) => {
            'label': 'Passages liés à $person',
            'tags': ['trust']
          }),
          if (passage.toLowerCase().contains('jacob') || passage.toLowerCase().contains('abraham') || passage.toLowerCase().contains('moïse'))
            {'label': 'Des passages de l\'Ancien Testament', 'tags': ['trust']},
          if (passage.toLowerCase().contains('jésus') || passage.toLowerCase().contains('évangile'))
            {'label': 'Des passages des Évangiles', 'tags': ['praise', 'trust']},
          if (passage.toLowerCase().contains('paul') || passage.toLowerCase().contains('épître'))
            {'label': 'Des passages des Épîtres', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('louange') || passage.toLowerCase().contains('adoration'))
            {'label': 'Des Psaumes', 'tags': ['praise', 'gratitude']},
          if (passage.toLowerCase().contains('sagesse') || passage.toLowerCase().contains('conseil'))
            {'label': 'Des Proverbes', 'tags': ['guidance']},
          {'label': 'Aucun autre passage', 'tags': []},
        ],
      },
    ];
  }

  List<String> _extractActors(String text) {
    final rx = RegExp(r'\b([A-ZÉÈÎÂÔÛ][a-zéèêàîôûâ]+)\b');
    final set = <String>{};
    for (final m in rx.allMatches(text)) {
      set.add(m.group(1)!);
    }
    if (text.toLowerCase().contains('dieu') || text.toLowerCase().contains('seigneur')) set.add('Dieu');
    return set.take(3).toList();
  }

  List<String> _extractActions(String text) {
    final verbs = ['demander', 'croire', 'obéir', 'remercier', 'se repentir', 'aimer', 'servir'];
    return verbs.where((v) => text.toLowerCase().contains(v)).toList();
  }

  List<String> _extractThemes(String text) {
    final themes = <String>[];
    if (text.toLowerCase().contains('amour')) themes.add('Amour');
    if (text.toLowerCase().contains('foi')) themes.add('Foi');
    if (text.toLowerCase().contains('grâce')) themes.add('Grâce');
    if (text.toLowerCase().contains('salut')) themes.add('Salut');
    if (text.toLowerCase().contains('repentance')) themes.add('Repentance');
    return themes;
  }

  List<String> _extractPromises(String text) {
    final promises = <String>[];
    final lower = text.toLowerCase();
    
    if (lower.contains('eau vive') || lower.contains('don de dieu')) {
      promises.add('Promesse d\'eau vive');
    }
    if (lower.contains('vie éternelle')) {
      promises.add('Promesse de vie éternelle');
    }
    if (lower.contains('donner') && lower.contains('fils')) {
      promises.add('Promesse du don du Fils');
    }
    if (lower.contains('croire') && lower.contains('périsse')) {
      promises.add('Promesse de ne pas périr');
    }
    
    return promises;
  }

  List<String> _extractWarnings(String text) {
    final warnings = <String>[];
    final lower = text.toLowerCase();
    
    if (lower.contains('périsse')) {
      warnings.add('Avertissement sur la perdition');
    }
    if (lower.contains('croire') && lower.contains('pas')) {
      warnings.add('Avertissement sur l\'incrédulité');
    }
    
    return warnings;
  }

  List<String> _extractCommands(String text) {
    final commands = <String>[];
    final lower = text.toLowerCase();
    
    if (lower.contains('donne-moi à boire')) {
      commands.add('Demander à boire');
    }
    if (lower.contains('connaître') && lower.contains('don')) {
      commands.add('Connaître le don de Dieu');
    }
    if (lower.contains('demander') && lower.contains('boire')) {
      commands.add('Demander l\'eau vive');
    }
    
    return commands;
  }

  List<String> _extractGodAttributes(String text) {
    final attributes = <String>[];
    final lower = text.toLowerCase();
    
    if (lower.contains('don de dieu')) {
      attributes.add('Dieu qui donne');
    }
    if (lower.contains('eau vive')) {
      attributes.add('Dieu source de vie');
    }
    if (lower.contains('fils unique')) {
      attributes.add('Dieu qui aime');
    }
    if (lower.contains('tant aimé')) {
      attributes.add('Dieu d\'amour infini');
    }
    
    return attributes;
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
      if (type == 'single') {
        selected.clear();
        selected.add(optionLabel);
      } else {
        if (selected.contains(optionLabel)) {
          selected.remove(optionLabel);
        } else {
          selected.add(optionLabel);
        }
      }
    });
  }

  void _finish() async {
    // Ajouter les entrées "j'écris moi-même" si non vides
    for (final q in _questions) {
      final ctrl = _freeByQuestion[q['id']];
      if (ctrl != null) {
        final t = ctrl.text.trim();
        if (t.isNotEmpty) _answers[q['id']]!.add(t);
      }
    }

    // Collecte des tags sélectionnés
    final selectedTags = <String>[];
    for (final q in _questions) {
      final chosen = _answers[q['id']] ?? <String>{};
      final options = q['options'] as List<Map<String, dynamic>>;
      
      for (final option in options) {
        if (chosen.contains(option['label'])) {
          final tags = (option['tags'] as List).cast<String>();
          selectedTags.addAll(tags);
        }
      }
    }
    
    // Générer les sujets de prière à partir des tags sélectionnés
    final subjects = PrayerSubjectsBuilder.fromQcm(
      selectedOptionTags: selectedTags,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      ..._questions.map((q) => _buildQuestionCard(q)),
                      const SizedBox(height: 100), // Espace pour le bouton flottant
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                  'Méditation Guidée',
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
          if (widget.passageRef != null)
            Text(
              widget.passageRef!,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
            'Sélectionne les options qui correspondent le mieux à ta compréhension du passage.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
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
    final type = question['type'] as String;
    final options = question['options'] as List<Map<String, dynamic>>;
    final selected = _answers[questionId] ?? <String>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 16),
          ...options.map((option) => _buildOptionTile(
            questionId,
            option['label'] as String,
            (option['tags'] as List).cast<String>(),
            type,
            selected.contains(option['label']),
          )),
          const SizedBox(height: 16),
          _buildFreeTextField(questionId),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String questionId, String label, List<String> tags, String type, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggle(questionId, label, type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: type == 'single' ? BoxShape.circle : BoxShape.rectangle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
                child: isSelected
                  ? Icon(
                      type == 'single' ? Icons.circle : Icons.check,
                      size: 12,
                      color: const Color(0xFF1C1740),
                    )
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeTextField(String questionId) {
    final controller = _freeByQuestion[questionId]!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: 2,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: '… ou j\'écris ma propre réponse',
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: _finish,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1C1740),
      icon: const Icon(Icons.arrow_forward_rounded),
      label: Text(
        'Continuer vers la prière',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}