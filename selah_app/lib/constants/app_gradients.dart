import 'package:flutter/material.dart';

class AppGradients {
  // Gradient principal de l'application (Indigo → Violet)
  static const appBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
  );
  
  // Gradient d'accent pour les éléments interactifs
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );
  
  // Gradient pour les cartes et contenus
  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1B5D), Color(0xFF3B2A7A)],
  );
  
  // Gradient pour les boutons primaires
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
  
  // Gradient pour les éléments secondaires
  static const secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
  );
}

class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const secondary = Color(0xFF7C3AED);
  static const accent = Color(0xFF8B5CF6);
  static const background = Color(0xFF1C1740);
  static const surface = Color(0xFF2A1B5D);
  static const onSurface = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFFE5E7EB);
}

class AppTextStyles {
  static const titleLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const titleMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );
}