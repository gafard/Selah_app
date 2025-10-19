import 'package:flutter/material.dart';
import '../../models/spiritual_foundation.dart';

/// Bandeau affichant la fondation du jour dans la page de lecture
class FoundationBanner extends StatelessWidget {
  final SpiritualFoundation foundation;
  final bool isInteractive; // 👈 nouveau
  final VoidCallback? onTap; // garde pour compat mais ignoré si non interactif

  const FoundationBanner({
    super.key,
    required this.foundation,
    this.isInteractive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = _BannerContent(foundation: foundation);

    if (!isInteractive) {
      // rendu purement informatif
      return Semantics(
        label: 'Fondation du jour: ${foundation.name}',
        button: false,
        child: content,
      );
    }

    // rendu cliquable (comportement existant)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}

/// Contenu visuel isolé (pas d'interaction ici)
class _BannerContent extends StatelessWidget {
  final SpiritualFoundation foundation;
  const _BannerContent({required this.foundation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            foundation.gradient[0].withOpacity(0.08),
            foundation.gradient[1].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: foundation.gradient[0].withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Icône de la fondation (plus petite)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: foundation.gradient[0].withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              foundation.iconData,
              color: foundation.gradient[0],
              size: 14,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Contenu textuel compact
          Expanded(
            child: Text(
              '${foundation.name} • ${foundation.verseReference}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: foundation.gradient[0].withOpacity(0.9),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

