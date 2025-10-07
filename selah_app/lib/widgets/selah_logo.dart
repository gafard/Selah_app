import 'package:flutter/material.dart';
import '../brand/selah_logo.dart' as brand;

enum SelahLogoType {
  round,
  squircle,
  transparent,
  wordmark,
  lockupHorizontal,
  lockupStacked,
}

class SelahLogo extends StatelessWidget {
  final SelahLogoType type;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const SelahLogo({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser le nouveau logo de la charte graphique (CustomPainter)
    final size = width ?? height ?? 100.0;
    
    switch (type) {
      case SelahLogoType.round:
        return brand.SelahHybridIcon(
          size: size,
          badge: brand.SelahBadge.round,
        );
      case SelahLogoType.squircle:
        return brand.SelahHybridIcon(
          size: size,
          badge: brand.SelahBadge.squircle,
        );
      case SelahLogoType.transparent:
        return brand.SelahHybridIcon(
          size: size,
          badge: brand.SelahBadge.none,
        );
      case SelahLogoType.wordmark:
        return SizedBox(
          width: width ?? 120,
          height: height ?? 40,
          child: const brand.SelahWordmark(),
        );
      case SelahLogoType.lockupHorizontal:
        return SizedBox(
          width: width ?? 200,
          height: height ?? 60,
          child: const brand.SelahLogo(),
        );
      case SelahLogoType.lockupStacked:
        return SizedBox(
          width: width ?? 150,
          height: height ?? 180,
          child: const brand.SelahLogo(),
        );
    }
  }

  // Méthodes de convenance pour créer des logos spécifiques
  static Widget round({double? size, Color? color}) {
    return SelahLogo(
      type: SelahLogoType.round,
      width: size,
      height: size,
      color: color,
    );
  }

  static Widget squircle({double? size, Color? color}) {
    return SelahLogo(
      type: SelahLogoType.squircle,
      width: size,
      height: size,
      color: color,
    );
  }

  static Widget transparent({double? size, Color? color}) {
    return SelahLogo(
      type: SelahLogoType.transparent,
      width: size,
      height: size,
      color: color,
    );
  }

  static Widget wordmark({double? width, double? height, Color? color}) {
    return SelahLogo(
      type: SelahLogoType.wordmark,
      width: width,
      height: height,
      color: color,
    );
  }

  static Widget lockupHorizontal({double? width, double? height, Color? color}) {
    return SelahLogo(
      type: SelahLogoType.lockupHorizontal,
      width: width,
      height: height,
      color: color,
    );
  }

  static Widget lockupStacked({double? width, double? height, Color? color}) {
    return SelahLogo(
      type: SelahLogoType.lockupStacked,
      width: width,
      height: height,
      color: color,
    );
  }

  // Widgets de convenance pour les pages spécifiques
  static Widget splashLogo({double? size}) {
    return SelahLogo.round(size: size ?? 100);
  }

  static Widget appIcon({double? size}) {
    return SelahLogo.round(size: size ?? 40);
  }
}

// Alias pour compatibilité avec les pages existantes
class SelahSplashLogo extends StatelessWidget {
  final double? size;
  const SelahSplashLogo({super.key, this.size});
  
  @override
  Widget build(BuildContext context) {
    return SelahLogo.splashLogo(size: size);
  }
}

class SelahAppIcon extends StatelessWidget {
  final double? size;
  const SelahAppIcon({super.key, this.size});
  
  @override
  Widget build(BuildContext context) {
    return SelahLogo.appIcon(size: size);
  }
}

// Classe pour les couleurs Selah
class SelahColors {
  static const Color primary = Color(0xFF2B1E75);   // Indigo approuvé
  static const Color marine = Color(0xFF0B2B7E);    // Marine
  static const Color sage = Color(0xFF49C98D);      // Sauge
  static const Color white = Color(0xFFFFFFFF);     // Blanc

  // Variantes avec opacité
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color marineWithOpacity(double opacity) => marine.withOpacity(opacity);
  static Color sageWithOpacity(double opacity) => sage.withOpacity(opacity);
}

// Classe pour les dégradés Selah
class SelahGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
  );

  static const LinearGradient sage = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF49C98D), Color(0xFF2B1E75)],
  );
}