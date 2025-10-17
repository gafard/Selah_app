import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/passage_qcm_builder.dart';
import '../models/passage_analysis.dart';
import '../utils/prayer_subjects_mapper.dart';
import 'prayer_carousel_page.dart';
import '../widgets/uniform_back_button.dart';

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

  // Les 8 questions fixes avec leurs options générées intelligemment
  late List<Map<String, dynamic>> _questions;

  // Fonction utilitaire pour récupérer les arguments GoRouter
  Map _readArgs(BuildContext context) {
    final goExtra = (GoRouterState.of(context).extra as Map?) ?? {};
    final modal = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    return {...modal, ...goExtra}; // go_router prioritaire
  }

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
      _selectedTagsByField[q['id']] = <String>{};
    }
  }

  // Validation pour permettre de continuer
  bool get _canContinue {
    final hasTags = _selectedTagsByField.values.any((s) => s.isNotEmpty);
    final hasFree = _freeByQuestion.values.any((c) => c.text.trim().isNotEmpty);
    return hasTags || hasFree;
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
    
    // Générer des options spécifiques au passage d'Ézéchiel 33:1-18
    final specificOptions = _generateSpecificOptions(passage);

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
        'options': [
          // Options spécifiques au passage Jean 14:1-19
          if (passage.toLowerCase().contains('croyez en dieu') || passage.toLowerCase().contains('croyez en moi'))
            {'label': 'L\'exemple de la foi et de la confiance', 'tags': ['trust', 'obedience']},
          if (passage.toLowerCase().contains('je suis le chemin'))
            {'label': 'L\'exemple de Jésus comme chemin vers le Père', 'tags': ['trust', 'obedience']},
          if (passage.toLowerCase().contains('gardez mes commandements'))
            {'label': 'L\'exemple de l\'obéissance par amour', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('faire les œuvres'))
            {'label': 'L\'exemple de faire les œuvres de Dieu', 'tags': ['obedience', 'service']},
          if (passage.toLowerCase().contains('demanderez en mon nom'))
            {'label': 'L\'exemple de la prière au nom de Jésus', 'tags': ['obedience', 'prayer']},
          if (passage.toLowerCase().contains('thomas') || passage.toLowerCase().contains('philippe'))
            {'label': 'L\'exemple des disciples qui posent des questions', 'tags': ['trust', 'seeking']},
          {'label': 'Aucun exemple particulier', 'tags': []},
        ],
      },
      {
        'id': 'ordre',
        'question': 'Y a-t-il un ordre auquel obéir ?',
        'type': 'multi',
        'options': [
          // Options spécifiques au passage Jean 14:1-19
          if (passage.toLowerCase().contains('croyez en dieu') || passage.toLowerCase().contains('croyez en moi'))
            {'label': 'Croire en Dieu et en Jésus', 'tags': ['obedience', 'trust']},
          if (passage.toLowerCase().contains('gardez mes commandements'))
            {'label': 'Garder les commandements de Jésus', 'tags': ['obedience']},
          if (passage.toLowerCase().contains('faire les œuvres'))
            {'label': 'Faire les œuvres de Dieu', 'tags': ['obedience', 'service']},
          if (passage.toLowerCase().contains('demanderez en mon nom'))
            {'label': 'Prier au nom de Jésus', 'tags': ['obedience', 'prayer']},
          if (passage.toLowerCase().contains('aimer') && passage.toLowerCase().contains('commandements'))
            {'label': 'Aimer Jésus en gardant ses commandements', 'tags': ['obedience', 'love']},
          if (passage.toLowerCase().contains('cœur ne se trouble'))
            {'label': 'Ne pas laisser son cœur se troubler', 'tags': ['obedience', 'peace']},
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
      final selectedTags = _selectedTagsByField[questionId]!;
      
      if (type == 'single') {
        selected.clear();
        selectedTags.clear();
        selected.add(optionLabel);
        
        // Ajouter les tags de l'option sélectionnée
        for (final q in _questions) {
          if (q['id'] == questionId) {
            final options = q['options'] as List<Map<String, dynamic>>;
            for (final option in options) {
              if (option['label'] == optionLabel) {
                final optionTags = (option['tags'] as List).cast<String>();
                selectedTags.addAll(optionTags);
                break;
              }
            }
            break;
          }
        }
      } else {
        if (selected.contains(optionLabel)) {
          selected.remove(optionLabel);
          // Retirer les tags de l'option désélectionnée
          for (final q in _questions) {
            if (q['id'] == questionId) {
              final options = q['options'] as List<Map<String, dynamic>>;
              for (final option in options) {
                if (option['label'] == optionLabel) {
                  final optionTags = (option['tags'] as List).cast<String>();
                  selectedTags.removeAll(optionTags);
                  break;
                }
              }
              break;
            }
          }
        } else {
          selected.add(optionLabel);
          // Ajouter les tags de l'option sélectionnée
          for (final q in _questions) {
            if (q['id'] == questionId) {
              final options = q['options'] as List<Map<String, dynamic>>;
              for (final option in options) {
                if (option['label'] == optionLabel) {
                  final optionTags = (option['tags'] as List).cast<String>();
                  selectedTags.addAll(optionTags);
                  break;
                }
              }
              break;
            }
          }
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

    // Collecter les réponses cochées pour chaque champ
    final selectedAnswersByField = <String, Set<String>>{};
    final freeTextResponses = <String, String>{};
    
    // Collecter le texte libre
    _freeByQuestion.forEach((field, controller) {
      freeTextResponses[field] = controller.text.trim();
    });
    
    // Initialiser les maps pour tous les champs
    for (final field in _selectedTagsByField.keys) {
      selectedAnswersByField[field] = <String>{};
    }
    
    // Collecter les réponses cochées depuis les QCM
    // Pour chaque champ, récupérer les labels des options sélectionnées
    _selectedTagsByField.forEach((field, tags) {
      if (tags.isNotEmpty) {
        // Trouver les questions correspondantes et leurs options
        for (final question in _questions) {
          if (question['id'] == field) {
            final options = question['options'] as List<Map<String, dynamic>>;
            final selectedLabels = <String>{};
            
            // Pour chaque option, vérifier si ses tags sont dans les tags sélectionnés
            for (final option in options) {
              final optionTags = (option['tags'] as List<dynamic>).cast<String>();
              if (optionTags.any((tag) => tags.contains(tag))) {
                selectedLabels.add(option['label'] as String);
              }
            }
            
            selectedAnswersByField[field] = selectedLabels;
            break;
          }
        }
      }
    });
    
    print('🔍 RÉPONSES DE MÉDITATION QCM:');
    _selectedTagsByField.forEach((field, tags) {
      print('🔍 $field - Tags: $tags');
      print('🔍 $field - Réponses cochées: ${selectedAnswersByField[field]}');
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

    context.go('/prayer', extra: {
      'items': items,
      'memoryVerse': '', // sera fixé plus tard si besoin
      'passageRef': widget.passageRef,
      'passageText': widget.passageText,
      'selectedTagsByField': _selectedTagsByField,
      'selectedAnswersByField': selectedAnswersByField,
      'freeTextResponses': freeTextResponses,
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withOpacity(0.3),
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
            'Lis lentement. Coche ce qui te parle, ou écris ta propre réponse.\n'
            'L\'Esprit t\'éclaire pendant que tu médites. 🙏',
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
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
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.15),
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
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
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        enableInteractiveSelection: true,
        autocorrect: false,
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

  Map<String, List<Map<String, dynamic>>> _generateSpecificOptions(String passage) {
    // Analyser le passage pour générer des options spécifiques et exactes
    final text = passage.toLowerCase();
    
    return {
      'de_quoi_qui': _generateTopicOptions(passage),
      'apprend_dieu': _generateGodRevelationOptions(passage),
      'promesse': _generatePromiseOptions(passage),
      'avertissement': _generateWarningOptions(passage),
      'commande': _generateCommandOptions(passage),
      'personnage_principal': _generateCharacterOptions(passage),
      'emotion': _generateEmotionOptions(passage),
      'application': _generateApplicationOptions(passage),
    };
  }

  List<Map<String, dynamic>> _generateTopicOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Analyser les sujets principaux du passage
    if (text.contains('sentinelle') || text.contains('garde')) {
      options.add({'label': 'La sentinelle et son rôle', 'tags': ['obedience', 'responsibility']});
    }
    if (text.contains('peuple') || text.contains('israël') || text.contains('enfants')) {
      options.add({'label': 'Le peuple de Dieu', 'tags': ['intercession']});
    }
    if (text.contains('épée') || text.contains('jugement')) {
      options.add({'label': 'Le jugement de Dieu', 'tags': ['warning', 'repentance']});
    }
    if (text.contains('trompette') || text.contains('avertir')) {
      options.add({'label': 'L\'avertissement divin', 'tags': ['guidance', 'obedience']});
    }
    if (text.contains('sang') || text.contains('responsabilité')) {
      options.add({'label': 'La responsabilité personnelle', 'tags': ['repentance', 'warning']});
    }
    if (text.contains('jésus') || text.contains('christ')) {
      options.add({'label': 'Jésus-Christ', 'tags': ['praise', 'trust']});
    }
    if (text.contains('royaume') || text.contains('roi')) {
      options.add({'label': 'Le royaume de Dieu', 'tags': ['promise', 'trust']});
    }
    if (text.contains('salut') || text.contains('sauver')) {
      options.add({'label': 'Le salut', 'tags': ['promise', 'gratitude']});
    }
    if (text.contains('amour') || text.contains('grâce')) {
      options.add({'label': 'L\'amour et la grâce de Dieu', 'tags': ['praise', 'gratitude']});
    }
    if (text.contains('foi') || text.contains('croire')) {
      options.add({'label': 'La foi', 'tags': ['trust', 'obedience']});
    }
    
    // Option par défaut si rien n'est trouvé
    if (options.isEmpty) {
      options.add({'label': 'Un enseignement spirituel', 'tags': ['guidance']});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generateGodRevelationOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    if (text.contains('établit') || text.contains('envoie')) {
      options.add({'label': 'Dieu établit et envoie des messagers', 'tags': ['praise', 'guidance']});
    }
    if (text.contains('responsable') || text.contains('redemander')) {
      options.add({'label': 'Dieu tient les hommes responsables', 'tags': ['awe', 'obedience']});
    }
    if (text.contains('avertir') || text.contains('avant')) {
      options.add({'label': 'Dieu donne des avertissements avant le jugement', 'tags': ['gratitude', 'trust']});
    }
    if (text.contains('sauve') || text.contains('écoute')) {
      options.add({'label': 'Dieu sauve ceux qui écoutent', 'tags': ['promise', 'trust']});
    }
    if (text.contains('amour') || text.contains('grâce')) {
      options.add({'label': 'Dieu est amour et grâce', 'tags': ['praise', 'gratitude']});
    }
    if (text.contains('puissance') || text.contains('majesté')) {
      options.add({'label': 'Dieu est puissant et majestueux', 'tags': ['praise', 'awe']});
    }
    if (text.contains('sagesse') || text.contains('conseil')) {
      options.add({'label': 'Dieu donne la sagesse', 'tags': ['guidance', 'trust']});
    }
    if (text.contains('fidèle') || text.contains('promesse')) {
      options.add({'label': 'Dieu est fidèle à ses promesses', 'tags': ['trust', 'promise']});
    }
    if (text.contains('saint') || text.contains('pur')) {
      options.add({'label': 'Dieu est saint et pur', 'tags': ['awe', 'repentance']});
    }
    if (text.contains('juste') || text.contains('justice')) {
      options.add({'label': 'Dieu est juste', 'tags': ['awe', 'trust']});
    }
    
    if (options.isEmpty) {
      options.add({'label': 'Dieu se révèle dans ce passage', 'tags': ['praise', 'gratitude']});
    }
    
    return options;
  }

  List<Map<String, dynamic>> _generatePromiseOptions(String passage) {
    final text = passage.toLowerCase();
    final options = <Map<String, dynamic>>[];
    
    // Promesses spécifiques au passage Jean 14:1-19
    if (text.contains('demeures') || text.contains('maison de mon père')) {
      options.add({'label': 'Promesse des demeures dans la maison du Père', 'tags': ['promise', 'trust']});
    }
    if (text.contains('préparer une place')) {
      options.add({'label': 'Promesse de préparer une place pour nous', 'tags': ['promise', 'trust']});
    }
    if (text.contains('reviendrai') || text.contains('prendrai avec moi')) {
      options.add({'label': 'Promesse de revenir et nous prendre avec lui', 'tags': ['promise', 'trust']});
    }
    if (text.contains('consolateur') || text.contains('esprit de vérité')) {
      options.add({'label': 'Promesse de l\'Esprit de vérité', 'tags': ['promise', 'trust']});
    }
    if (text.contains('demanderez en mon nom')) {
      options.add({'label': 'Promesse que tout sera fait au nom de Jésus', 'tags': ['promise', 'trust']});
    }
    if (text.contains('orphelins') || text.contains('viendrai à vous')) {
      options.add({'label': 'Promesse de ne pas nous laisser orphelins', 'tags': ['promise', 'trust']});
    }
    if (text.contains('vous vivrez aussi')) {
      options.add({'label': 'Promesse de vie éternelle', 'tags': ['promise', 'trust']});
    }
    if (text.contains('œuvres') && text.contains('plus grandes')) {
      options.add({'label': 'Promesse de faire des œuvres plus grandes', 'tags': ['promise', 'trust']});
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

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: _canContinue ? _finish : null,
      backgroundColor: _canContinue ? Colors.white : Colors.white.withOpacity(0.3),
      foregroundColor: _canContinue ? const Color(0xFF1C1740) : Colors.white.withOpacity(0.5),
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