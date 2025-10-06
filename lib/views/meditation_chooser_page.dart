import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeditationChooserPage extends StatelessWidget {
  const MeditationChooserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Choisir la méthode', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF7F7F9), 
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _OptionTile(
              title: 'Option 1 — Méditation Libre',
              subtitle: 'Réponses en texte libre (pas de QCM)',
              icon: Icons.edit_note_rounded,
              onTap: () => Navigator.pushNamed(context, '/meditation/free'),
            ),
            const SizedBox(height: 12),
            _OptionTile(
              title: 'Option 2 — Méditation QCM',
              subtitle: 'Choix multiples, mêmes questions d\'origine',
              icon: Icons.list_alt_rounded,
              onTap: () => Navigator.pushNamed(context, '/meditation/qcm'),
            ),
            const SizedBox(height: 12),
            _OptionTile(
              title: 'Option 3 — QCM Automatique',
              subtitle: 'Questions générées automatiquement du texte',
              icon: Icons.auto_awesome_rounded,
              onTap: () => Navigator.pushNamed(context, '/meditation/auto_qcm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _OptionTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 24, 
              backgroundColor: const Color(0xFFEFF2FF), 
              child: Icon(icon, color: const Color(0xFF6366F1))
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(
                    title, 
                    style: GoogleFonts.inter(
                      fontSize: 16, 
                      fontWeight: FontWeight.w700
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: GoogleFonts.inter(
                      fontSize: 13, 
                      color: const Color(0xFF6B7280)
                    )
                  ),
                ]
              )
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF))
          ],
        ),
      ),
    );
  }
}