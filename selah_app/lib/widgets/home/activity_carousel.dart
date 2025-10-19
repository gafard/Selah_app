import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/airplane_guard.dart';
import '../../services/spiritual_foundations_service.dart';
import '../../models/spiritual_foundation.dart';
import '../../services/plan_service_http.dart';
import '../../services/user_prefs_hive.dart';
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
      await AirplaneGuard.ensureFocusMode(
        context,
        proceed: () async {
          HapticFeedback.mediumImpact();
          if (context.mounted) {
            context.go(activity.route!);
          }
        },
      );
    } else if (activity.route != null) {
      HapticFeedback.mediumImpact();
      context.go(activity.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
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
                  _getActivityImage(activity),
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
              
              // Effet Glassmorphism par-dessus l'image
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.04),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Gradient overlay pour le texte
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
                        _getActivityGradient(activity).first.withOpacity(0.8),
                        _getActivityGradient(activity).last.withOpacity(0.95),
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
                            child: Center(
                              child: Text(
                                'Commencer',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
      ),
    );
  }

  /// Image de fond pour chaque activité
  String _getActivityImage(_Activity activity) {
    switch (activity.name) {
      case 'Affermir ma foi':
        return 'assets/images/shepherd_lamb.png'; // Berger et agneau - parfait pour affermir la foi
      case 'Partager la lumière':
        return 'assets/images/jesus_cross.png'; // Jésus sur la croix - parfait pour partager la lumière
      default:
        return 'assets/images/miraculous_catch.png';
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
        return 'Quiz Apôtre\nIntelligence Divine';
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
        return 'APÔTRE';
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
        return '27 livres';
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
        return 'Quiz intelligent couvrant les 27 livres du Nouveau Testament avec sagesse divine.';
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

