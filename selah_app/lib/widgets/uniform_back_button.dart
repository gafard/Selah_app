import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget réutilisable pour un bouton retour uniforme
/// Basé sur le modèle de goals_page.dart
class UniformBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;

  const UniformBackButton({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: size ?? 40,
        height: size ?? 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (iconColor ?? Colors.white).withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor ?? Colors.white,
          size: iconSize ?? 20,
        ),
      ),
    );
  }
}

/// Widget pour les AppBar qui utilise un IconButton standard mais avec le style uniforme
class UniformBackButtonAppBar extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? iconColor;

  const UniformBackButtonAppBar({
    super.key,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: iconColor ?? Colors.black,
        size: 20,
      ),
    );
  }
}

/// Widget pour un header avec bouton retour uniforme
class UniformHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBackPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;

  const UniformHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.subtitle,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          UniformBackButton(
            onPressed: onBackPressed,
            iconColor: iconColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor ?? Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: (textColor ?? Colors.white).withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}
