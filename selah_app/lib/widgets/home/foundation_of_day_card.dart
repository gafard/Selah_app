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

  /// Retourne l'image de fond pour la fondation
  String _getFoundationImage(SpiritualFoundation foundation) {
    switch (foundation.id) {
      case 'christ_foundation':
        return 'assets/images/jesus_cross.png'; // Jésus sur la croix - parfait pour le Christ comme fondement
      case 'word_keystone':
        return 'assets/images/shepherd_lamb.png'; // Berger et agneau - parfait pour la Parole
      case 'humility_prayer':
        return 'assets/images/miraculous_catch.png'; // Pêche miraculeuse - humilité et prière
      case 'forgiveness':
        return 'assets/images/jesus_cross.png'; // Jésus sur la croix - pardon
      case 'trust_god':
        return 'assets/images/shepherd_lamb.png'; // Berger et agneau - confiance en Dieu
      case 'priorities':
        return 'assets/images/miraculous_catch.png'; // Pêche miraculeuse - priorités
      case 'discernment':
        return 'assets/images/jesus_cross.png'; // Jésus sur la croix - discernement
      case 'obedience':
        return 'assets/images/shepherd_lamb.png'; // Berger et agneau - obéissance
      case 'practice':
        return 'assets/images/miraculous_catch.png'; // Pêche miraculeuse - pratique
      case 'sand_foundation':
        return 'assets/images/jesus_cross.png'; // Jésus sur la croix - fondation de sable
      case 'vain_work':
        return 'assets/images/shepherd_lamb.png'; // Berger et agneau - travail vain
      default:
        return 'assets/images/jesus_cross.png'; // Image par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleFoundationTap(context),
            child: Container(
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
              
              // Effet de flou dégradé du bas vers le haut
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Couche de flou uniquement sur la partie basse
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120, // Hauteur de la zone floue
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Overlay avec gradient (comme les autres cartes)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      foundation.gradient.first.withOpacity(0.8),
                      foundation.gradient.last.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              
              // Effet glassmorphism
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.landscape_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'FONDATION DU JOUR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Icône de la fondation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        foundation.iconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Titre de la fondation
                    Text(
                      foundation.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Description courte
                    Text(
                      foundation.shortDescription,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Référence biblique
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
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Bouton d'action
                    Container(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Je m\'y engage',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
