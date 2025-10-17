import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barre de prompts de réflexion pour le Reader
class ReaderPromptsBar extends StatelessWidget {
  final void Function(String prompt)? onTapPrompt;
  
  const ReaderPromptsBar({
    super.key,
    this.onTapPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final prompts = const [
      'Que dit ce passage sur le caractère de Dieu ?',
      'Quel verset dois-je garder aujourd\'hui ?',
      'Quelle étape concrète je prends d\'ici ce soir ?',
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return GestureDetector(
            onTap: () => onTapPrompt?.call(prompt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  prompt,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
