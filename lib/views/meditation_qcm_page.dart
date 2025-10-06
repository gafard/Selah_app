import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeditationQcmPage extends StatefulWidget {
  const MeditationQcmPage({super.key});

  @override
  State<MeditationQcmPage> createState() => _MeditationQcmPageState();
}

class _MeditationQcmPageState extends State<MeditationQcmPage> {
  // Banque QCM basée sur tes questions d'origine (neutres)
  final List<QcmQuestion> _questions = [
    QcmQuestion(
      id: 'topic',
      title: 'De quoi / de qui parlent ces versets ?',
      type: QcmType.multi, // on autorise plusieurs éléments
      options: [
        QcmOption('Dieu / Son caractère', tags: ['truth','praise']),
        QcmOption('Un commandement / appel à obéir', tags: ['obedience']),
        QcmOption('Une promesse', tags: ['promise']),
        QcmOption('Un avertissement', tags: ['warning']),
        QcmOption('Un exemple à suivre', tags: ['obedience','formation']),
        QcmOption('Un exemple à éviter', tags: ['repentance']),
      ],
    ),
    QcmQuestion(
      id: 'aboutGod',
      title: 'Ce passage m\'apprend-il quelque chose sur Dieu ?',
      type: QcmType.single,
      options: [
        QcmOption('Oui, sur Son amour / fidélité', tags: ['praise','trust']),
        QcmOption('Oui, sur Sa justice / sainteté', tags: ['repentance','awe']),
        QcmOption('Oui, sur Sa sagesse / direction', tags: ['guidance']),
        QcmOption('Non explicite', tags: []),
      ],
    ),
    QcmQuestion(
      id: 'commands',
      title: 'Y a-t-il un ordre auquel obéir ?',
      type: QcmType.single,
      options: [
        QcmOption('Oui — à mettre en pratique', tags: ['obedience']),
        QcmOption('Non', tags: []),
      ],
    ),
    QcmQuestion(
      id: 'promise',
      title: 'Y a-t-il une promesse ?',
      type: QcmType.single,
      options: [
        QcmOption('Oui — à croire et proclamer', tags: ['promise','trust']),
        QcmOption('Non', tags: []),
      ],
    ),
    QcmQuestion(
      id: 'warning',
      title: 'Y a-t-il un avertissement ?',
      type: QcmType.single,
      options: [
        QcmOption('Oui — à prendre au sérieux', tags: ['warning','repentance']),
        QcmOption('Non', tags: []),
      ],
    ),
    QcmQuestion(
      id: 'apply',
      title: 'Application aujourd\'hui (choisis au moins une)',
      type: QcmType.multi,
      options: [
        QcmOption('Rendre grâce', tags: ['gratitude']),
        QcmOption('Se repentir / corriger', tags: ['repentance']),
        QcmOption('Obéir concrètement', tags: ['obedience']),
        QcmOption('Croire / s\'approprier une promesse', tags: ['promise','trust']),
        QcmOption('Intercéder pour quelqu\'un', tags: ['intercession']),
      ],
    ),
  ];

  // Sélections utilisateur (par question)
  final Map<String, Set<String>> _answers = {}; // questionId -> set of option labels

  // Catalogue de sujets final (mapping tags -> sujets neutres)
  final Map<String, List<String>> _subjectsByTag = {
    'gratitude': [
      'Remercier pour la vie et la grâce reçue',
      'Remercier pour les personnes autour de moi',
    ],
    'repentance': [
      'Reconnaître et abandonner une habitude nocive',
      'Demander un cœur humble et pur',
    ],
    'obedience': [
      'Mettre en pratique une action concrète aujourd\'hui',
      'Être fidèle dans une petite chose précise',
    ],
    'promise': [
      'S\'approprier une promesse lue et s\'y appuyer',
      'Demander la foi pour croire au bon moment de Dieu',
    ],
    'warning': [
      'Demander la crainte de Dieu face à un avertissement',
      'Prendre une mesure de garde-fou',
    ],
    'intercession': [
      'Prier pour un proche en difficulté',
      'Prier pour l\'Église / la ville',
    ],
    'trust': [
      'Demander la paix et la confiance au milieu de l\'incertitude',
    ],
    'guidance': [
      'Demander la sagesse pour une décision',
    ],
    'praise': [
      'Adorer Dieu pour son caractère révélé',
    ],
    'truth': [
      'Remercier pour une vérité comprise aujourd\'hui',
    ],
    'formation': [
      'Imiter un bon exemple vu dans le texte',
    ],
  };

  void _toggleAnswer(String qid, String label, bool multi) {
    setState(() {
      _answers.putIfAbsent(qid, () => <String>{});
      if (multi) {
        if (_answers[qid]!.contains(label)) {
          _answers[qid]!.remove(label);
        } else {
          _answers[qid]!.add(label);
        }
      } else {
        _answers[qid]!
          ..clear()
          ..add(label);
      }
    });
  }

  void _finish() {
    // 1) Collecte des tags depuis les réponses choisies
    final selectedTags = <String>{};
    for (final q in _questions) {
      final chosen = _answers[q.id] ?? {};
      for (final opt in q.options) {
        if (chosen.contains(opt.label)) {
          selectedTags.addAll(opt.tags);
        }
      }
    }

    // 2) Générer la liste de sujets à proposer (sans guider)
    final subjects = <String>{};
    for (final tag in selectedTags) {
      final bundle = _subjectsByTag[tag];
      if (bundle != null) subjects.addAll(bundle);
    }

    // 3) Aller à la page de prière (ou renvoyer la liste)
    Navigator.pushNamed(
      context,
      '/prayer_subjects',
      arguments: {
        'suggestedSubjects': subjects.toList(), // tu peux fusionner avec ta page existante
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F9),
        elevation: 0,
        title: Text('Méditation — QCM', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemBuilder: (_, i) {
          final q = _questions[i];
          final selected = _answers[q.id] ?? {};
          return _QuestionCard(
            question: q,
            selected: selected,
            onToggle: (label) => _toggleAnswer(q.id, label, q.type == QcmType.multi),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _questions.length,
      ),
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: const Color(0xFFF7F7F9),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Proposer des sujets de prière', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Modèles simples ---
enum QcmType { single, multi }

class QcmQuestion {
  final String id;
  final String title;
  final QcmType type;
  final List<QcmOption> options;
  QcmQuestion({required this.id, required this.title, required this.type, required this.options});
}

class QcmOption {
  final String label;
  final List<String> tags;
  QcmOption(this.label, {this.tags = const []});
}

// --- UI ---
class _QuestionCard extends StatelessWidget {
  final QcmQuestion question;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _QuestionCard({
    required this.question,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isMulti = question.type == QcmType.multi;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + badge single/multi
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.title,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isMulti ? 'Multiple' : 'Unique',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.options.map((opt) {
                final on = selected.contains(opt.label);
                return GestureDetector(
                  onTap: () => onToggle(opt.label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: on ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(on ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18, color: on ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Text(opt.label,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}