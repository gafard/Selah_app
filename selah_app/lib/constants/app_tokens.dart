import 'package:flutter/material.dart';

class AppTokens {
  // Colors - Palette Calm plus douce
  static const bgTop = Color(0xFF0D1020);
  static const bgBottom = Color(0xFF1A1C3A);
  static const glassStroke = Color(0x1FFFFFFF);
  static const onGlass = Colors.white;
  static const indigo = Color(0xFF7C8CFF);
  static const teal = Color(0xFF4FD1C5);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  
  // Glass surfaces
  static const glassBg = Color(0x08FFFFFF);
  static const glassBgHover = Color(0x12FFFFFF);
  static const glassBorder = Color(0x18FFFFFF);

  // Radius - Tout en r-16 et r-20, boutons r-12
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;

  // Spacing - Baseline 8 → 12 → 16 → 24 → 32
  static const gap8 = 8.0;
  static const gap12 = 12.0;
  static const gap16 = 16.0;
  static const gap20 = 20.0;
  static const gap24 = 24.0;
  static const gap32 = 32.0;

  // Motion - Animations Calm
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 400);
  static const curve = Curves.easeInOutCubic;
  static const spring = Curves.elasticOut;

  // Typography
  static const titleLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  
  static const titleMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
  
  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // Shadows - 2 couches max, très diffuses
  static const shadowLight = BoxShadow(
    color: Color(0x0C000000),
    blurRadius: 20,
    offset: Offset(0, 8),
  );
  
  static const shadowMedium = BoxShadow(
    color: Color(0x12000000),
    blurRadius: 40,
    offset: Offset(0, 16),
  );

  // Gradients
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
    stops: [0.0, 1.0],
  );
  
  static const indigoGradient = LinearGradient(
    colors: [indigo, Color(0xFF8B5CF6)],
  );
  
  static const tealGradient = LinearGradient(
    colors: [teal, Color(0xFF3B82F6)],
  );
  
  static const successGradient = LinearGradient(
    colors: [success, Color(0xFF10B981)],
  );
}

