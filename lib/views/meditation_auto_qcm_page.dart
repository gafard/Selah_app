import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/passage_qcm_builder.dart';
import '../models/passage_analysis.dart';
import '../services/prayer_subjects_builder.dart';

class MeditationAutoQcmPage extends StatefulWidget {
  const MeditationAutoQcmPage({super.key});

  @override
  State<MeditationAutoQcmPage> createState() => _MeditationAutoQcmPageState();
}

class _MeditationAutoQcmPageState extends State<MeditationAutoQcmPage> {
  late List<QcmQuestion> _questions;
  final Map<String, Set<String>> _answers = {}; // questionId -> selected options
  final Map<String, TextEditingController> _freeByQuestion = {};
  bool _isLoading = true;

  // Texte de démonstration (en production, ceci viendrait du passage biblique)
  final String _demoPassage = """
    Jésus se rendit dans la ville de Samarie, appelée Sychar, près du champ que Jacob avait donné à son fils Joseph. 
    Là se trouvait le puits de Jacob. Jésus, fatigué du voyage, était assis au bord du puits. 
    C'était environ la sixième heure. Une femme de Samarie vint puiser de l'eau. 
    Jésus lui dit : Donne-moi à boire. Car ses disciples étaient allés à la ville pour acheter des vivres. 
    La femme samaritaine lui dit : Comment toi, qui es Juif, me demandes-tu à boire, à moi qui suis une femme samaritaine ? 
    Jésus lui répondit : Si tu connaissais le don de Dieu et qui est celui qui te dit : Donne-moi à boire, tu lui aurais toi-même demandé à boire, et il t'aurait donné de l'eau vive.
  """;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  void _generateQuestions() {
    setState(() {
      _isLoading = true;
    });

    // Simuler un délai de traitement
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // Utiliser l'analyse du passage pour générer des questions intelligentes
        final facts = extractFacts(_demoPassage);
        final mcqs = buildMcqs(_demoPassage);
        
        // Convertir les McqItem en QcmQuestion avec des options basées sur le passage
        _questions = mcqs.map((mcq) {
          return QcmQuestion(
            id: 'auto_${_questions.length}',
            title: mcq.question,
            type: QcmType.single,
            options: mcq.choices.map((choice) => QcmOption(choice, tags: [])).toList(),
            allowFreeWrite: true,
          );
        }).toList();
        
        // Ajouter des questions basées sur les faits extraits
        if (facts.people.isNotEmpty) {
          _questions.add(QcmQuestion(
            id: 'people',
            title: 'Quels personnages apparaissent dans ce passage ?',
            type: QcmType.multi,
            options: facts.people.map((person) => QcmOption(person, tags: ['intercession'])).toList(),
            allowFreeWrite: true,
          ));
        }
        
        if (facts.keyEvents.isNotEmpty) {
          _questions.add(QcmQuestion(
            id: 'events',
            title: 'Quels événements se déroulent dans ce passage ?',
            type: QcmType.multi,
            options: facts.keyEvents.take(4).map((event) => 
              QcmOption(event.length > 60 ? event.substring(0, 57) + '...' : event, tags: ['obedience'])).toList(),
            allowFreeWrite: true,
          ));
        }
        
        for (final q in _questions) {
          _answers[q.id] = <String>{};
          if (q.allowFreeWrite) {
            _freeByQuestion[q.id] = TextEditingController();
          }
        }
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    for (final controller in _freeByQuestion.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggle(String questionId, String optionLabel, QcmType type) {
    setState(() {
      final selected = _answers[questionId]!;
      if (type == QcmType.single) {
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
      final ctrl = _freeByQuestion[q.id];
      if (ctrl != null) {
        final t = ctrl.text.trim();
        if (t.isNotEmpty) _answers[q.id]!.add(t);
      }
    }

    // Collecte des tags sélectionnés
    final selectedTags = <String>[];
    for (final q in _questions) {
      final chosen = _answers[q.id] ?? <String>{};
      for (final opt in q.options) {
        if (chosen.contains(opt.label)) {
          selectedTags.addAll(opt.tags);
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
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
                  'Test de Compréhension',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _generateQuestions,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Générer de nouvelles questions',
              ),
            ],
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
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'QCM Automatique',
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
            'Ces questions ont été générées automatiquement à partir du passage biblique pour tester votre compréhension.',
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

  Widget _buildQuestionCard(QcmQuestion question) {
    final selected = _answers[question.id] ?? <String>{};

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
            question.title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ...question.options.map((option) => _buildOptionTile(
            question.id,
            option.label,
            option.tags,
            question.type,
            selected.contains(option.label),
          )),
          if (question.allowFreeWrite) ...[
            const SizedBox(height: 16),
            _buildFreeTextField(question.id),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile(String questionId, String label, List<String> tags, QcmType type, bool isSelected) {
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
                  shape: type == QcmType.single ? BoxShape.circle : BoxShape.rectangle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
                child: isSelected
                  ? Icon(
                      type == QcmType.single ? Icons.circle : Icons.check,
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