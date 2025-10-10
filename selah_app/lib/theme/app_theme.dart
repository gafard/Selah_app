import 'package:flutter/material.dart';

/// 🎨 Tokens de thème centralisés pour éviter les "magic numbers"
class AppTheme {
  // Couleurs
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF9FAFB);
  
  static const Color surface = Colors.white;
  static const Color brandIndigo = Color(0xFF6D28D9);
  static const Color brandEmerald = Color(0xFF059669);
  static const Color brandPurple = Color(0xFF8B5CF6);
  static const Color brandRed = Color(0xFFDC2626);
  static const Color brandCyan = Color(0xFF06B6D4);
  static const Color brandLime = Color(0xFFC6F830);
  
  // Rayons
  static const Radius radiusXS = Radius.circular(4);
  static const Radius radiusS = Radius.circular(8);
  static const Radius radiusM = Radius.circular(12);
  static const Radius radiusL = Radius.circular(16);
  static const Radius radiusXL = Radius.circular(20);
  static const Radius radius2XL = Radius.circular(24);
  static const Radius radius3XL = Radius.circular(32);
  static const Radius radius4XL = Radius.circular(40);
  
  // BorderRadius
  static const BorderRadius cardR = BorderRadius.all(radius2XL);
  static const BorderRadius buttonR = BorderRadius.all(radiusM);
  static const BorderRadius calendarR = BorderRadius.all(radiusM);
  static const BorderRadius activityR = BorderRadius.all(radius3XL);
  
  // Valeurs numériques pour BorderRadius.circular()
  static const double cardRadius = 24.0;
  static const double buttonRadius = 12.0;
  static const double calendarRadius = 12.0;
  static const double activityRadius = 32.0;
  
  // Ombres
  static const List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: Color(0x14000000), // 8%
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000), // 10%
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> shadowHard = [
    BoxShadow(
      color: Color(0x28000000), // 16%
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
  
  // Espacements
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 20;
  static const double spacing2XL = 24;
  static const double spacing3XL = 32;
  static const double spacing4XL = 40;
  
  // Tailles de police
  static const double fontSizeXS = 10;
  static const double fontSizeS = 12;
  static const double fontSizeM = 14;
  static const double fontSizeL = 16;
  static const double fontSizeXL = 18;
  static const double fontSize2XL = 20;
  static const double fontSize3XL = 24;
  static const double fontSize4XL = 32;
  
  // Poids de police
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;
  static const FontWeight fontWeightBlack = FontWeight.w900;
  
  // Hauteurs de ligne
  static const double lineHeightTight = 1.1;
  static const double lineHeightNormal = 1.3;
  static const double lineHeightRelaxed = 1.5;
  static const double lineHeightLoose = 1.7;
  
  // Opacités
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;
  
  // Dégradés prédéfinis
  static const LinearGradient gradientPurple = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientLime = LinearGradient(
    colors: [Color(0xFFC6F830), Color(0xFFD4FA4D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientCyan = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientRed = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientEmerald = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dégradés de fond
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFE0E7FF), Color(0xFFF0FDFA)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  
  // Styles de texte prédéfinis
  static TextStyle get heading1 => const TextStyle(
    fontSize: fontSize3XL,
    fontWeight: fontWeightBold,
    color: neutral900,
    height: lineHeightTight,
  );
  
  static TextStyle get heading2 => const TextStyle(
    fontSize: fontSize2XL,
    fontWeight: fontWeightBold,
    color: neutral900,
    height: lineHeightTight,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: fontSizeL,
    fontWeight: fontWeightNormal,
    color: neutral800,
    height: lineHeightNormal,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontSize: fontSizeM,
    fontWeight: fontWeightNormal,
    color: neutral700,
    height: lineHeightNormal,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontSize: fontSizeS,
    fontWeight: fontWeightNormal,
    color: neutral500,
    height: lineHeightNormal,
  );
  
  static TextStyle get caption => const TextStyle(
    fontSize: fontSizeXS,
    fontWeight: fontWeightMedium,
    color: neutral400,
    height: lineHeightNormal,
  );
  
  static TextStyle get button => const TextStyle(
    fontSize: fontSizeM,
    fontWeight: fontWeightSemiBold,
    color: surface,
    height: lineHeightTight,
  );
  
  // Couleurs de contraste pour accessibilité
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? neutral900 : surface;
  }
  
  // Couleur de texte avec opacité pour contraste
  static Color getTextColorWithOpacity(Color backgroundColor, double opacity) {
    final baseColor = getContrastColor(backgroundColor);
    return baseColor.withOpacity(opacity);
  }
}
