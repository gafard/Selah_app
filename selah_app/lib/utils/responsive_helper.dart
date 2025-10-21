import 'package:flutter/material.dart';

/// Helper pour rendre l'interface responsive selon la taille d'écran
class ResponsiveHelper {
  /// Détermine si l'écran est une tablette (>= 600dp de largeur)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }
  
  /// Calcule une largeur responsive basée sur le type d'écran
  static double getResponsiveWidth(BuildContext context, double phoneValue) {
    return isTablet(context) ? phoneValue * 1.5 : phoneValue;
  }
  
  /// Calcule une hauteur responsive basée sur le type d'écran
  static double getResponsiveHeight(BuildContext context, double phoneValue) {
    return isTablet(context) ? phoneValue * 1.5 : phoneValue;
  }
  
  /// Calcule une taille de police responsive basée sur le type d'écran
  static double getResponsiveFontSize(BuildContext context, double phoneSize) {
    return isTablet(context) ? phoneSize * 1.3 : phoneSize;
  }
  
  /// Calcule un padding responsive basé sur le type d'écran
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets phonePadding) {
    final multiplier = isTablet(context) ? 1.5 : 1.0;
    return EdgeInsets.only(
      left: phonePadding.left * multiplier,
      top: phonePadding.top * multiplier,
      right: phonePadding.right * multiplier,
      bottom: phonePadding.bottom * multiplier,
    );
  }
  
  /// Calcule un margin responsive basé sur le type d'écran
  static EdgeInsets getResponsiveMargin(BuildContext context, EdgeInsets phoneMargin) {
    final multiplier = isTablet(context) ? 1.5 : 1.0;
    return EdgeInsets.only(
      left: phoneMargin.left * multiplier,
      top: phoneMargin.top * multiplier,
      right: phoneMargin.right * multiplier,
      bottom: phoneMargin.bottom * multiplier,
    );
  }
  
  /// Calcule une taille d'icône responsive
  static double getResponsiveIconSize(BuildContext context, double phoneSize) {
    return isTablet(context) ? phoneSize * 1.4 : phoneSize;
  }
  
  /// Calcule un espacement vertical responsive
  static double getResponsiveSpacing(BuildContext context, double phoneSpacing) {
    return isTablet(context) ? phoneSpacing * 1.3 : phoneSpacing;
  }
}





