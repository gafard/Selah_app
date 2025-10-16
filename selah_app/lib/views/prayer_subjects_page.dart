import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PrayerSubjectsPage extends StatefulWidget {
  const PrayerSubjectsPage({super.key});

  @override
  State<PrayerSubjectsPage> createState() => _PrayerSubjectsPageState();
}

class _PrayerSubjectsPageState extends State<PrayerSubjectsPage> {
  // Sujets + dégradés (ordre = de haut en bas)
  final subjects = <_Band>[
    _Band(label: 'Action de grâce', colors: [const Color(0xFFFF8AC9), const Color(0xFFFF7BAA)]),
    _Band(label: 'Foi / Confiance',  colors: [const Color(0xFFFFB36B), const Color(0xFFFFA245)]),
    _Band(label: 'Obéissance',       colors: [const Color(0xFFFFD36B), const Color(0xFFFFC23E)]),
    _Band(label: 'Intercession',     colors: [const Color(0xFFFFE39B), const Color(0xFFFFD773)]),
    _Band(label: 'Repentance',       colors: [const Color(0xFFFFF0C5), const Color(0xFFFFE9A6)]),
  ];

  final Set<String> completed = {}; // pour griser/valider

  void _toggle(String label) {
    setState(() {
      completed.contains(label) ? completed.remove(label) : completed.add(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header façon maquette
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
                    final isDone = completed.contains(s.label);
                    return _SubjectBandTile(
                      label: s.label,
                      colors: s.colors,
                      done: isDone,
                      onTap: () => _toggle(s.label),
                    );
                  },
                ),
              ),

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: completed.isEmpty ? null : () {
                    context.go('/prayer_editor', extra: {
                      'selectedSubjects': completed.toList(),
                    });
                  },
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
    // hauteur généreuse + coins très arrondis pour coller au visuel
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
            boxShadow: [
              BoxShadow(color: colors.first.withOpacity(.25), blurRadius: 16, offset: const Offset(0, 8)),
            ],
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
                    decoration: done ? TextDecoration.lineThrough : TextDecoration.none, // "trait gris"
                    decorationColor: Colors.black.withOpacity(.35),
                    decorationThickness: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // petit chevron comme sur la photo
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
  _Band({required this.label, required this.colors});
}