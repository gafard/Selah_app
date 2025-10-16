import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class MeditationFreePage extends StatefulWidget {
  final String? passageRef;
  final String? passageText;
  
  const MeditationFreePage({
    super.key,
    this.passageRef,
    this.passageText,
  });
  
  @override
  State<MeditationFreePage> createState() => _MeditationFreePageState();
}

class _MeditationFreePageState extends State<MeditationFreePage> {
  final _controllers = <String, TextEditingController>{
    'aboutGod': TextEditingController(),        // "Qu'est-ce que ce texte m'enseigne sur Dieu ?"
    'neighbor': TextEditingController(),        // "... à propos de mon prochain ?"
    'applyToday': TextEditingController(),      // "Application concrète aujourd'hui"
    'verseHit': TextEditingController(),        // "Quel verset me frappe le plus ?"
  };

  final _tagPool = const ['gratitude','repentance','obedience','promise','intercession','praise','trust','guidance','warning'];
  final Map<String, Set<String>> _selectedTagsByField = { // champ -> tags choisis
    'aboutGod': <String>{},
    'neighbor': <String>{},
    'applyToday': <String>{},
    'verseHit': <String>{},
  };

  final Map<String, List<String>> _subjectsByTag = {
    'gratitude': ['Remercier pour la grâce reçue','Remercier pour les personnes autour de moi'],
    'repentance': ['Reconnaître une faute et demander un cœur pur'],
    'obedience': ['Mettre en pratique une action concrète aujourd\'hui'],
    'promise': ['S\'approprier une promesse lue et s\'y appuyer'],
    'intercession': ['Prier pour un proche','Prier pour l\'Église / la ville'],
    'praise': ['Adorer Dieu pour son caractère révélé'],
    'trust': ['Demander paix et confiance'],
    'guidance': ['Demander sagesse pour une décision'],
    'warning': ['Prendre au sérieux un avertissement / établir un garde-fou'],
  };

  void _finish() {
    final tags = <String>{};
    _selectedTagsByField.values.forEach(tags.addAll);
    // Pas de guidance : on propose seulement.
    final subjects = <String>{};
    for (final t in tags) {
      final list = _subjectsByTag[t];
      if (list != null) subjects.addAll(list);
    }
    context.go('/prayer_subjects', extra: {
      'suggestedSubjects': subjects.toList(),
      'memoryVerse': _controllers['verseHit']!.text.trim(),
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Méditation — Libre', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF7F7F9), elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _FreeField(
            title: 'Ce texte m\'enseigne à propos de Dieu',
            controller: _controllers['aboutGod']!,
            chips: _tagPool,
            selected: _selectedTagsByField['aboutGod']!,
            onToggleTag: (t){ setState(() {
              final set = _selectedTagsByField['aboutGod']!;
              set.contains(t) ? set.remove(t) : set.add(t);
            });},
          ),
          const SizedBox(height: 12),
          _FreeField(
            title: '… et à propos de mon prochain',
            controller: _controllers['neighbor']!,
            chips: _tagPool,
            selected: _selectedTagsByField['neighbor']!,
            onToggleTag: (t){ setState(() {
              final set = _selectedTagsByField['neighbor']!;
              set.contains(t) ? set.remove(t) : set.add(t);
            });},
          ),
          const SizedBox(height: 12),
          _FreeField(
            title: 'Application concrète aujourd\'hui',
            controller: _controllers['applyToday']!,
            chips: _tagPool,
            selected: _selectedTagsByField['applyToday']!,
            onToggleTag: (t){ setState(() {
              final set = _selectedTagsByField['applyToday']!;
              set.contains(t) ? set.remove(t) : set.add(t);
            });},
          ),
          const SizedBox(height: 12),
          _FreeField(
            title: 'Verset à mémoriser (écran de veille)',
            controller: _controllers['verseHit']!,
            chips: const ['gratitude','praise','promise','trust'], // soft
            selected: _selectedTagsByField['verseHit']!,
            onToggleTag: (t){ setState(() {
              final set = _selectedTagsByField['verseHit']!;
              set.contains(t) ? set.remove(t) : set.add(t);
            });},
            maxLines: 2,
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Proposer des sujets de prière', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _FreeField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final List<String> chips;
  final Set<String> selected;
  final ValueChanged<String> onToggleTag;
  final int maxLines;
  const _FreeField({
    required this.title,
    required this.controller,
    required this.chips,
    required this.selected,
    required this.onToggleTag,
    this.maxLines = 5
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06), 
            blurRadius: 12, 
            offset: const Offset(0,6)
          )
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(
            title, 
            style: GoogleFonts.inter(
              fontSize: 15, 
              fontWeight: FontWeight.w700
            )
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: const InputDecoration(
              filled: true, 
              fillColor: Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderSide: BorderSide.none, 
                borderRadius: BorderRadius.all(Radius.circular(12))
              ),
              hintText: 'Écrire librement…',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, 
            runSpacing: 8,
            children: chips.map((t){
              final on = selected.contains(t);
              return GestureDetector(
                onTap: ()=>onToggleTag(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
                    border: Border.all(
                      color: on ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB)
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t, 
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)
                  ),
                ),
              );
            }).toList(),
          ),
        ]
      ),
    );
  }
}