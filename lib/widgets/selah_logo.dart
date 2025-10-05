import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget réutilisable pour afficher le logo Selah
/// 
/// Variantes disponibles :
/// - blueBg : Fond bleu (pour app stores)
/// - whiteBg : Fond blanc
/// - monochrome : Version monochrome marine
/// - transparent : Transparent avec couleurs
/// - monoTransparent : Transparent monochrome
/// - horizontal : Lockup horizontal avec fond
/// - stacked : Lockup empilé avec fond
/// - horizontalTransparent : Lockup horizontal transparent
class SelahLogo extends StatelessWidget {
  final SelahLogoVariant variant;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const SelahLogo({
    super.key,
    required this.variant,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final String assetPath = _getAssetPath();
    
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      fit: fit,
    );
  }

  String _getAssetPath() {
    switch (variant) {
      case SelahLogoVariant.blueBg:
        return 'assets/logos/icon-blue-bg.svg';
      case SelahLogoVariant.whiteBg:
        return 'assets/logos/icon-white-bg.svg';
      case SelahLogoVariant.monochrome:
        return 'assets/logos/icon-monochrome.svg';
      case SelahLogoVariant.transparent:
        return 'assets/logos/icon-transparent.svg';
      case SelahLogoVariant.monoTransparent:
        return 'assets/logos/icon-mono-transparent.svg';
      case SelahLogoVariant.horizontal:
        return 'assets/logos/lockup-horizontal.svg';
      case SelahLogoVariant.stacked:
        return 'assets/logos/lockup-stacked.svg';
      case SelahLogoVariant.horizontalTransparent:
        return 'assets/logos/lockup-horizontal-transparent.svg';
    }
  }
}

/// Variantes du logo Selah
enum SelahLogoVariant {
  /// Icône avec fond bleu (pour app stores)
  blueBg,
  
  /// Icône avec fond blanc
  whiteBg,
  
  /// Version monochrome marine
  monochrome,
  
  /// Transparent avec couleurs
  transparent,
  
  /// Transparent monochrome
  monoTransparent,
  
  /// Lockup horizontal avec fond
  horizontal,
  
  /// Lockup empilé avec fond
  stacked,
  
  /// Lockup horizontal transparent
  horizontalTransparent,
}

/// Widget spécialisé pour l'icône de l'application
class SelahAppIcon extends StatelessWidget {
  final double size;
  final bool useBlueBackground;

  const SelahAppIcon({
    super.key,
    this.size = 48.0,
    this.useBlueBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return SelahLogo(
      variant: useBlueBackground 
          ? SelahLogoVariant.blueBg 
          : SelahLogoVariant.whiteBg,
      width: size,
      height: size,
    );
  }
}

/// Widget spécialisé pour le header de l'application
class SelahHeaderLogo extends StatelessWidget {
  final double height;
  final bool useTransparent;

  const SelahHeaderLogo({
    super.key,
    this.height = 40.0,
    this.useTransparent = true,
  });

  @override
  Widget build(BuildContext context) {
    return SelahLogo(
      variant: useTransparent 
          ? SelahLogoVariant.horizontalTransparent 
          : SelahLogoVariant.horizontal,
      height: height,
    );
  }
}

/// Widget spécialisé pour le splash screen
class SelahSplashLogo extends StatelessWidget {
  final double size;

  const SelahSplashLogo({
    super.key,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return SelahLogo(
      variant: SelahLogoVariant.stacked,
      width: size,
      height: size,
    );
  }
}

/// Widget spécialisé pour les favicons et petites icônes
class SelahFavicon extends StatelessWidget {
  final double size;
  final bool useTransparent;

  const SelahFavicon({
    super.key,
    this.size = 32.0,
    this.useTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return SelahLogo(
      variant: useTransparent 
          ? SelahLogoVariant.monoTransparent 
          : SelahLogoVariant.blueBg,
      width: size,
      height: size,
    );
  }
}
