import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens pour l'application Selah
/// Respecte strictement les spécifications UI/UX
class DesignTokens {
  // Couleurs principales
  static const Color primaryStart = Color(0xFF1C1740);
  static const Color primaryEnd = Color(0xFF5C34D1);
  
  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryStart, primaryEnd],
  );
  
  // Couleurs neutres avec overlay
  static const Color white14 = Color(0x24FFFFFF); // #FFFFFF14
  static const Color white22 = Color(0x38FFFFFF); // #FFFFFF22
  static const Color white55 = Color(0x8CFFFFFF); // #FFFFFF55
  static const Color whiteAA = Color(0xAAFFFFFF); // #FFFFFFAA
  
  // Couleurs pour checklist
  static const Color gold = Color(0xFFFFD36A);
  static const Color rose = Color(0xFFFF7CCB);
  static const Color green = Color(0xFF56E6C2);
  static const Color lavender = Color(0xFFB39DFF);
  
  // Ombres
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x55000000),
    blurRadius: 20,
    offset: Offset(0, 4),
  );
  
  // Styles de texte
  static TextStyle get heading => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );
  
  static TextStyle get subheading => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
  );
  
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.4,
  );
  
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle get placeholder => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: whiteAA,
    height: 1.4,
  );
  
  // Dimensions
  static const double pillRadius = 28.0;
  static const double pillHeight = 64.0;
  static const double pillPadding = 24.0;
  static const double progressRingSize = 24.0;
  static const double progressStrokeWidth = 4.0;
  
  // Espacements
  static const double margin = 24.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 12.0;
  
  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;
}
