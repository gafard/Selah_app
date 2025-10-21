import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/airplane_guard.dart';
import '../../services/spiritual_foundations_service.dart';
import '../../models/spiritual_foundation.dart';
import '../../services/plan_service_http.dart';
import '../../services/user_prefs_hive.dart';
import '../../services/daily_display_service.dart';
import '../../bootstrap.dart';
import 'package:provider/provider.dart';
import 'foundation_of_day_card.dart';
import '../../views/theme_study_page.dart';

class ActivityCarousel extends StatefulWidget {
  const ActivityCarousel({super.key});

  @override
  State<ActivityCarousel> createState() => _ActivityCarouselState();
}

class _ActivityCarouselState extends State<ActivityCarousel> {
  late final PageController _controller;
  int _index = 0;
  SpiritualFoundation? _foundationOfDay;
  bool _isLoadingFoundation = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .82);
    _loadFoundationOfDay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Charge la fondation du jour
  Future<void> _loadFoundationOfDay() async {
    try {
      final planService = context.read<PlanServiceHttp>();
      final userPrefs = context.read<UserPrefsHive>();
      
      final plan = await planService.getActivePlan();
      final profile = userPrefs.profile;
      
      // Calculer le jour actuel du plan
      int dayNumber = 1;
      if (plan != null) {
        final now = DateTime.now();
        final startDate = plan.startDate;
        dayNumber = now.difference(startDate).inDays + 1;
        if (dayNumber < 1) dayNumber = 1;
      }
      
      final foundation = await SpiritualFoundationsService.getFoundationOfDay(
        plan,
        dayNumber,
        profile,
      );
      
      if (mounted) {
        setState(() {
          _foundationOfDay = foundation;
          _isLoadingFoundation = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement fondation du jour: $e');
      if (mounted) {
        setState(() {
          _isLoadingFoundation = false;
        });
      }
    }
  }

  /// Navigue vers la page d'étude thématique
  void _navigateToThemeStudy(BuildContext context) {
    // Récupérer la référence du passage actuel depuis le contexte
    // Pour l'instant, on utilise une référence par défaut
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThemeStudyPage(
          passageRef: 'Jean 14:1-19', // TODO: Récupérer depuis le contexte
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activities = [
      const _Activity(
        name: 'Affermir ma foi',
        subtitle: 'Quiz biblique',
        icon: '🧠',
        gradient: [Color(0xFFE74C3C), Color(0xFFF39C12), Color(0xFFE74C3C)],
        route: '/bible_quiz',
      ),
      _Activity(
        name: 'Étude thématique',
        subtitle: 'Parcours aventure d\'un thème',
        icon: '📚',
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)],
        onTap: (context) => _navigateToThemeStudy(context),
      ),
      const _Activity(
        name: 'Partager la lumière',
        subtitle: 'Communauté',
        icon: '🤝',
        gradient: [Color(0xFF27AE60), Color(0xFF2ECC71), Color(0xFF27AE60)],
        route: '/community/new-post',
      ),
    ];

    // Calculer le nombre total d'éléments (fondation + activités)
    final totalItems = 1 + activities.length; // 1 pour la fondation + 3 activités

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: totalItems,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final isActive = i == _index;
              
              // Première carte : Fondation du jour
              if (i == 0) {
                if (_isLoadingFoundation) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    transform: Matrix4.identity()
                      ..translate(0.0, isActive ? 0.0 : 12.0)
                      ..scale(isActive ? 1.0 : 0.92),
                    child: _buildLoadingCard(),
                  );
                } else if (_foundationOfDay != null) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    transform: Matrix4.identity()
                      ..translate(0.0, isActive ? 0.0 : 12.0)
                      ..scale(isActive ? 1.0 : 0.92),
                    child: FoundationOfDayCard(foundation: _foundationOfDay!),
                  );
                } else {
                  // Fallback si pas de fondation
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    transform: Matrix4.identity()
                      ..translate(0.0, isActive ? 0.0 : 12.0)
                      ..scale(isActive ? 1.0 : 0.92),
                    child: _buildErrorCard(),
                  );
                }
              }
              
              // Autres cartes : Activités (index décalé de 1)
              final activityIndex = i - 1;
              final activity = activities[activityIndex];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                transform: Matrix4.identity()
                  ..translate(0.0, isActive ? 0.0 : 12.0)
                  ..scale(isActive ? 1.0 : 0.92),
                child: _ActivityCard(activity: activity),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalItems, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: active ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1F2937) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Carte de chargement pour la fondation
  Widget _buildLoadingCard() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 300,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B7355), Color(0xFFD2B48C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de la fondation...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'erreur si la fondation ne peut pas être chargée
  Widget _buildErrorCard() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 300,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Fondation non disponible',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Réessayez plus tard',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final _Activity activity;

  Future<void> _handleActivityTap(BuildContext context) async {
    if (activity.onTap != null) {
      HapticFeedback.mediumImpact();
      activity.onTap!(context);
    } else if (activity.route == '/pre_meditation_prayer') {
      // Vérifier si la page pre_meditation_prayer doit être affichée aujourd'hui
      if (DailyDisplayService.shouldShowPreMeditationPrayer()) {
        await AirplaneGuard.ensureFocusMode(
          context,
          proceed: () async {
            HapticFeedback.mediumImpact();
            if (context.mounted) {
              context.go(activity.route!);
            }
          },
        );
      } else {
        // Déjà affichée aujourd'hui, naviguer directement vers le lecteur
        HapticFeedback.mediumImpact();
        if (context.mounted) {
          // Navigation directe vers le lecteur avec le passage du jour
          _navigateToReaderDirectly(context);
        }
      }
    } else if (activity.route != null) {
      HapticFeedback.mediumImpact();
      context.go(activity.route!);
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
                  _getActivityImage(activity),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              
              // Gradient léger pour la lisibilité du texte
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
              
              // Gradient overlay pour le texte - renforcé pour la lisibilité
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
                        _getActivityGradient(activity).first.withOpacity(0.9),
                        _getActivityGradient(activity).last.withOpacity(0.98),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Contenu de la carte
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre principal
                      Text(
                        _getActivityTitle(activity),
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
                      
                      const SizedBox(height: 12),
                      
                      // Informations de l'activité
                      Row(
                        children: [
                          // Badge de niveau/durée
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getActivityBadge(activity),
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
                          ),
                          
                          const Spacer(),
                          
                          // Durée/niveau
                          Text(
                            _getActivityDuration(activity),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        _getActivityDescription(activity),
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
                      Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleActivityTap(context),
                            borderRadius: BorderRadius.circular(22),
                            child: const Center(
                              child: Text(
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
                            ),
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

  /// Image de fond pour chaque activité - évite les doublons
  String _getActivityImage(_Activity activity) {
    // Attribution directe d'images uniques pour chaque activité
    switch (activity.name) {
      case 'Affermir ma foi':
        return 'assets/images/shepherd_lamb.jpg';
      case 'Partager la lumière':
        return 'assets/images/355c44bd5772246e2ee5167158dfbb2a.jpg';
      case 'Étude thématique':
        return 'assets/images/7f327ee3b2d9139dba52d8aeeac615b5.jpg';
      default:
        return 'assets/images/21b1298f86e169728b67a700d9f4268e.jpg';
    }
  }
  

  /// Gradient de couleur pour chaque activité
  List<Color> _getActivityGradient(_Activity activity) {
    switch (activity.name) {
      case 'Affermir ma foi':
        return [const Color(0xFFE74C3C), const Color(0xFFC0392B)]; // Rouge passion
      case 'Partager la lumière':
        return [const Color(0xFF27AE60), const Color(0xFF1E8449)]; // Vert communion
      default:
        return [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)];
    }
  }

  /// Titre principal de l'activité
  String _getActivityTitle(_Activity activity) {
    switch (activity.name) {
      case 'Affermir ma foi':
        return 'Quiz Biblique';
      case 'Partager la lumière':
        return 'Partager la lumière\navec la communauté';
      default:
        return 'Activité spirituelle';
    }
  }

  /// Badge de niveau/durée
  String _getActivityBadge(_Activity activity) {
    switch (activity.name) {
      case 'Affermir ma foi':
        return 'QUIZ';
      case 'Partager la lumière':
        return 'PARTAGE';
      default:
        return 'ACTIVITÉ';
    }
  }

  /// Durée/niveau de l'activité
  String _getActivityDuration(_Activity activity) {
    switch (activity.name) {
      case 'Affermir ma foi':
        return '5-10 min';
      case 'Partager la lumière':
        return '∞ temps';
      default:
        return '10 min';
    }
  }

  /// Description de l'activité
  String _getActivityDescription(_Activity activity) {
    switch (activity.name) {
      case 'Affermir ma foi':
        return 'Quiz biblique pour tester et approfondir vos connaissances.';
      case 'Partager la lumière':
        return 'Communauté de croyants pour partager, encourager et grandir ensemble.';
      default:
        return 'Activité spirituelle pour votre croissance personnelle.';
    }
  }

}

class _Activity {
  const _Activity({
    required this.name, 
    required this.subtitle, 
    required this.icon, 
    required this.gradient, 
    this.route,
    this.onTap,
  });
  final String name;
  final String subtitle;
  final String icon;
  final List<Color> gradient;
  final String? route;
  final Function(BuildContext)? onTap;
}

