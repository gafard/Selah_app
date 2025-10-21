import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème Selah avec police Gilroy
ThemeData selahTheme(BuildContext context) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD54F)),
    useMaterial3: true,
  );

  // Utiliser Gilroy si disponible, sinon fallback sur Poppins (similaire)
  final poppins = GoogleFonts.poppinsTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: poppins.copyWith(
      // CHIFFRES (ex: "91") - Gilroy Heavy
      displayLarge: const TextStyle(
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w800,  // Heavy
        fontSize: 80,                 // Taille imposante
        height: 0.85,
        letterSpacing: -3,
        color: Color(0xFF111111),
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      
      // TITRE (ex: "Croissance Spirituelle") - Gilroy SemiBold
      titleLarge: const TextStyle(
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w600,  // SemiBold
        fontSize: 24,                 // 22-26 selon densité
        height: 1.15,
        letterSpacing: -0.3,
        color: Color(0xFF111111),
      ),
      
      // PETITS TEXTES (ex: "jours", "livres") - Gilroy Medium
      bodySmall: const TextStyle(
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,  // Medium
        fontSize: 14,                 // 12-14
        height: 1.2,
        color: Color(0xFF111111),
      ),
    ),
  );
}

