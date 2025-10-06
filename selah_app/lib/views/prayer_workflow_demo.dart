import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrayerWorkflowDemo extends StatefulWidget {
  const PrayerWorkflowDemo({super.key});
  @override
  State<PrayerWorkflowDemo> createState() => _PrayerWorkflowDemoState();
}

class _PrayerWorkflowDemoState extends State<PrayerWorkflowDemo> {
  // sujets par défaut (remplace par ceux générés depuis la méditation si besoin)
  final List<_Band> _defaultSubjects = [
    _Band('Action de grâce', [const Color(0xFFFF8AC9), const Color(0xFFFF7BAA)]),
    _Band('Foi / Confiance', [const Color(0xFFFFB36B), const Color(0xFFFFA245)]),
    _Band('Obéissance', [const Color(0xFFFFD36B), const Color(0xFFFFC23E)]),
    _Band('Intercession', [const Color(0xFFFFE39B), const Color(0xFFFFD773)]),
    _Band('Repentance', [const Color(0xFFFFF0C5), const Color(0xFFFFE9A6)]),
  ];

  final Set<String> _validated = {}; // bandes validées (gris + barré)

  // Dégradés prédéfinis pour les sujets dynamiques
  final List<List<Color>> _gradients = [
    [const Color(0xFFFF8AC9), const Color(0xFFFF7BAA)],
    [const Color(0xFFFFB36B), const Color(0xFFFFA245)],
    [const Color(0xFFFFD36B), const Color(0xFFFFC23E)],
    [const Color(0xFFFFE39B), const Color(0xFFFFD773)],
    [const Color(0xFFFFF0C5), const Color(0xFFFFE9A6)],
    [const Color(0xFFE8F5E8), const Color(0xFFD4F1D4)],
    [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
    [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
    [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
    [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
  ];

  void _toggle(String label) {
    setState(() {
      _validated.contains(label) ? _validated.remove(label) : _validated.add(label);
    });
  }

  void _continue() {
    // Enchaîne vers ton éditeur / page de prière
    Navigator.pushNamed(context, '/prayer_editor', arguments: {
      'selectedSubjects': _validated.toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les arguments de navigation
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final incoming = (args['subjects'] as List?)?.cast<String>();
    
    // Utiliser les sujets entrants ou les sujets par défaut
    final List<_Band> subjects;
    if (incoming != null && incoming.isNotEmpty) {
      // Créer des bandes avec les sujets entrants et des dégradés dynamiques
      subjects = incoming.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final gradientIndex = index % _gradients.length;
        return _Band(label, _gradients[gradientIndex]);
      }).toList();
    } else {
      // Utiliser les sujets par défaut
      subjects = _defaultSubjects;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre façon maquette (noir, bold)
              Text('Choisis tes sujets de prière',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 16),

              // Bandes empilées
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = subjects[i];
                    final done = _validated.contains(s.label);
                    return _SubjectBandTile(
                      label: s.label,
                      colors: s.colors,
                      done: done,
                      onTap: () => _toggle(s.label),
                    );
                  },
                ),
              ),

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _validated.isEmpty ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Continuer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectBandTile extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final bool done;
  final VoidCallback onTap;

  const _SubjectBandTile({
    required this.label,
    required this.colors,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: done ? 0.45 : 1,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: colors.first.withOpacity(.25), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(.9),
                    decoration: done ? TextDecoration.lineThrough : TextDecoration.none, // trait gris
                    decorationColor: Colors.black.withOpacity(.35),
                    decorationThickness: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.keyboard_arrow_right_rounded, color: Colors.black.withOpacity(.75), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _Band {
  final String label;
  final List<Color> colors;
  _Band(this.label, this.colors);
}