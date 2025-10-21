import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/spiritual_foundation.dart';
import '../../services/airplane_guard.dart';

/// Carte affichant la fondation spirituelle du jour
class FoundationOfDayCard extends StatelessWidget {
  final SpiritualFoundation foundation;
  final VoidCallback? onTap;

  const FoundationOfDayCard({
    super.key,
    required this.foundation,
    this.onTap,
  });

  /// Gère le tap sur la carte avec notification de mode avion
  Future<void> _handleFoundationTap(BuildContext context) async {
    if (onTap != null) {
      onTap!();
    } else {
      // Utiliser AirplaneGuard pour la notification de mode avion
      await AirplaneGuard.ensureFocusMode(
        context,
        proceed: () async {
          HapticFeedback.mediumImpact();
          if (context.mounted) {
            context.go('/pre_meditation_prayer');
          }
        },
      );
    }
  }

  /// Retourne l'image de fond pour la fondation - évite les doublons avec les cartes d'activité
  String _getFoundationImage(SpiritualFoundation foundation) {
    // Images disponibles pour les fondations (différentes des cartes d'activité)
    final foundationImages = [
      'assets/images/21b1298f86e169728b67a700d9f4268e.jpg', // Image unique pour fondation
      'assets/images/caf319f92d5998a6cab7b4d462655071.jpg', // Image unique pour fondation
    ];
    
    // Pour éviter les doublons, utiliser une logique de rotation basée sur l'ID
    final foundationId = foundation.id;
    final hash = foundationId.hashCode;
    final imageIndex = hash.abs() % foundationImages.length;
    
    return foundationImages[imageIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: const BoxConstraints(
          minHeight: 200,
          maxHeight: 300,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Image de fond
              Positioned.fill(
                child: Image.asset(
                  _getFoundationImage(foundation),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              
              // Gradient léger pour la lisibilité du texte (même style que les cartes d'activité)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.15),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Gradient overlay pour le texte - renforcé pour la lisibilité (même style que les cartes d'activité)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        foundation.gradient.first.withOpacity(0.9),
                        foundation.gradient.last.withOpacity(0.98),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Contenu principal - positionné comme les autres cartes
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge "FONDATION DU JOUR"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.landscape_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'FONDATION DU JOUR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Titre de la fondation
                      Text(
                        foundation.name,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 6,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Référence biblique - déplacée plus haut
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              foundation.verseReference,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description courte
                      Text(
                        foundation.shortDescription,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bouton d'action
                      GestureDetector(
                        onTap: () => _handleFoundationTap(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Commencer',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
