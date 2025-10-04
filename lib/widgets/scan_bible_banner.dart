import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanBibleBanner extends StatelessWidget {
  final VoidCallback onTap;
  const ScanBibleBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Color(0xFFEFF2FF), child: Icon(Icons.document_scanner_rounded, color: Color(0xFF6366F1))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Scanner la page de Bible (optionnel)', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Prends une photo pour garder la référence et relire hors-ligne.', style: GoogleFonts.inter(color: Color(0xFF6B7280), fontSize: 13)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
