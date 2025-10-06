import 'package:flutter/material.dart';

class SelahTheme {
  // Couleurs principales
  static const Color primary = Color(0xFF1553FF);
  static const Color sauge = Color(0xFF49C98D);
  static const Color ink = Color(0xFF1A1D29);
  static const Color card = Color(0x14FFFFFF); // blanc 8% pour overlays
  
  // Couleurs secondaires
  static const Color marine = Color(0xFF0B1025);
  static const Color purple = Color(0xFF1C1740);
  static const Color deepPurple = Color(0xFF2D1B69);
  
  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, sauge],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [marine, purple, deepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Rayons de bordure
  static const double radiusSmall = 14.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 26.0;
  
  // Ombres
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  // Espacement
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Typographie
  static const double letterSpacingCTA = 0.5;
}

