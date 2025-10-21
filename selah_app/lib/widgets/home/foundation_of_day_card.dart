import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/spiritual_foundation.dart';
import '../../services/airplane_guard.dart';
import '../../services/daily_display_service.dart';
import '../../bootstrap.dart';

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
      // Vérifier si la page pre_meditation_prayer doit être affichée aujourd'hui
      if (DailyDisplayService.shouldShowPreMeditationPrayer()) {
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
      } else {
        // Déjà affichée aujourd'hui, naviguer directement vers le lecteur avec le passage du jour
        HapticFeedback.mediumImpact();
        if (context.mounted) {
          // Navigation directe vers le lecteur avec le passage du jour
          // Utiliser la même logique que pre_meditation_prayer_page.dart
          _navigateToReaderDirectly(context);
        }
      }
    }
  }

  /// Navigation directe vers le lecteur avec le passage du jour (même logique que pre_meditation_prayer_page.dart)
  Future<void> _navigateToReaderDirectly(BuildContext context) async {
    try {
      // Utiliser le PlanServiceHttp configuré globalement
      final activePlan = await planService.getActiveLocalPlan();
      
      if (activePlan != null) {
        // S'assurer que les jours du plan existent (auto-régénération si nécessaire)
        await planService.regenerateCurrentPlanDays();
        
        // Récupérer les jours du plan
        final planDays = await planService.getPlanDays(activePlan.id);
        
        if (planDays.isNotEmpty) {
          // Calculer la différence en jours calendaires (change à minuit)
          final today = DateTime.now();
          final startDate = activePlan.startDate;
          
          // Normaliser les dates à minuit pour comparer les jours calendaires
          final todayNormalized = DateTime(today.year, today.month, today.day);
          final startNormalized = DateTime(startDate.year, startDate.month, startDate.day);
          
          final dayIndex = todayNormalized.difference(startNormalized).inDays + 1;
          
          if (dayIndex >= 1 && dayIndex <= planDays.length) {
            final todayPassage = planDays.firstWhere((day) => day.dayIndex == dayIndex);
            
            // Construire la référence du passage
            String passageRef;
            if (todayPassage.readings.isNotEmpty) {
              final r = todayPassage.readings.first;
              passageRef = '${r.book} ${r.range}'.trim();
            } else {
              passageRef = _generatePassageRef(todayPassage.dayIndex);
            }
            
            // Navigation avec les données du passage
            if (context.mounted) {
              final extraData = <String, dynamic>{
                'passageRef': passageRef,
                'passageText': null, // Sera récupéré depuis la base de données
                'dayTitle': 'Jour ${todayPassage.dayIndex}',
                'planId': activePlan.id,
                'dayNumber': todayPassage.dayIndex,
              };
              context.go('/reader', extra: extraData);
            }
          } else {
            // Plan terminé ou pas encore commencé - utiliser fallback
            if (context.mounted) {
              final fallbackData = <String, dynamic>{
                'passageRef': _generatePassageRef(1),
                'passageText': null,
                'dayTitle': 'Lecture du jour',
                'planId': activePlan.id,
                'dayNumber': 1,
              };
              context.go('/reader', extra: fallbackData);
            }
          }
        } else {
          // Pas de jours de plan trouvés - utiliser le fallback
          if (context.mounted) {
            final fallbackData = <String, dynamic>{
              'passageRef': _generatePassageRef(1),
              'passageText': null,
              'dayTitle': 'Lecture du jour',
              'planId': activePlan.id,
              'dayNumber': 1,
            };
            context.go('/reader', extra: fallbackData);
          }
        }
      } else {
        // Aucun plan actif - navigation par défaut avec fallback
        if (context.mounted) {
          final defaultData = <String, dynamic>{
            'passageRef': _generatePassageRef(1),
            'passageText': null,
            'dayTitle': 'Lecture du jour',
          };
          context.go('/reader', extra: defaultData);
        }
      }
    } catch (e) {
      // Fallback en cas d'erreur
      if (context.mounted) {
        final errorData = <String, dynamic>{
          'passageRef': _generatePassageRef(1),
          'passageText': null,
          'dayTitle': 'Lecture du jour',
        };
        context.go('/reader', extra: errorData);
      }
    }
  }

  /// Génère une référence de passage basée sur le jour du plan (FALLBACK INTELLIGENT)
  String _generatePassageRef(int dayNumber) {
    // Liste de passages bibliques populaires pour la méditation
    final passages = [
      'Jean 14:1-19',    // Jour 1 - "Je suis le chemin, la vérité et la vie"
      'Psaume 23:1-6',   // Jour 2 - "L'Éternel est mon berger"
      'Matthieu 6:9-13', // Jour 3 - Notre Père
      'Romains 8:28-39', // Jour 4 - "Toutes choses concourent au bien"
      'Éphésiens 2:8-10', // Jour 5 - "C'est par la grâce que vous êtes sauvés"
      'Philippiens 4:4-9', // Jour 6 - "Réjouissez-vous toujours"
      '1 Corinthiens 13:4-8', // Jour 7 - L'amour
      'Galates 5:22-23', // Jour 8 - Le fruit de l'Esprit
      'Colossiens 3:12-17', // Jour 9 - "Revêtez-vous de compassion"
      'Hébreux 11:1-6', // Jour 10 - La foi
      'Jacques 1:2-8', // Jour 11 - "Considérez comme un sujet de joie"
      '1 Pierre 5:6-11', // Jour 12 - "Humiliez-vous sous la main puissante"
      '2 Pierre 1:3-8', // Jour 13 - "Sa divine puissance nous a donné tout"
      '1 Jean 4:7-12', // Jour 14 - "Dieu est amour"
      'Apocalypse 21:1-7', // Jour 15 - "Voici, je fais toutes choses nouvelles"
    ];
    
    // Utiliser le passage correspondant au jour, ou revenir au début si on dépasse
    final index = (dayNumber - 1) % passages.length;
    return passages[index];
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
