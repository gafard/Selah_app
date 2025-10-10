import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ActivityCarousel extends StatefulWidget {
  const ActivityCarousel({super.key});

  @override
  State<ActivityCarousel> createState() => _ActivityCarouselState();
}

class _ActivityCarouselState extends State<ActivityCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .82);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activities = [
      const _Activity(
        name: 'Rencontrer Dieu',
        subtitle: 'Dans Sa Parole',
        icon: '📖',
        gradient: [Color(0xFF4A90E2), Color(0xFF7BB3F0), Color(0xFF4A90E2)],
        route: '/pre_meditation_prayer',
      ),
      const _Activity(
        name: 'Affermir ma foi',
        subtitle: 'Quiz biblique',
        icon: '🧠',
        gradient: [Color(0xFFE74C3C), Color(0xFFF39C12), Color(0xFFE74C3C)],
        route: '/bible_quiz',
      ),
      const _Activity(
        name: 'Partager la lumière',
        subtitle: 'Communauté',
        icon: '🤝',
        gradient: [Color(0xFF27AE60), Color(0xFF2ECC71), Color(0xFF27AE60)],
        route: '/community/new-post',
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: activities.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final isActive = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                transform: Matrix4.identity()
                  ..translate(0.0, isActive ? 0.0 : 12.0)
                  ..scale(isActive ? 1.0 : 0.92),
                child: _ActivityCard(activity: activities[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(activities.length, (i) {
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
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Container(
        height: 400,
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
              // Image de fond avec blur
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Image.asset(
                    _getActivityImage(activity),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
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
                            onTap: () => context.go(activity.route),
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
      case 'Rencontrer Dieu':
        return 'assets/images/onboarding_bible.png'; // Berger avec agneau - parfait pour rencontrer Dieu
      case 'Affermir ma foi':
        return 'assets/images/onboarding_tree.png'; // Lanterne dorée avec rayons - parfait pour le Quiz Apôtre
      case 'Partager la lumière':
        return 'assets/images/onboarding_path.png'; // Bible ouverte avec soleil - parfait pour partager la lumière
      default:
        return 'assets/images/onboarding_bible.png';
    }
  }

  /// Gradient de couleur pour chaque activité
  List<Color> _getActivityGradient(_Activity activity) {
    switch (activity.name) {
      case 'Rencontrer Dieu':
        return [const Color(0xFF4A90E2), const Color(0xFF2E5BBA)]; // Bleu spirituel
      case 'Affermir ma foi':
        return [const Color(0xFFE74C3C), const Color(0xFFC0392B)]; // Rouge passion
      case 'Partager la lumière':
        return [const Color(0xFF27AE60), const Color(0xFF1E8449)]; // Vert communion
      default:
        return [const Color(0xFF4A90E2), const Color(0xFF2E5BBA)];
    }
  }

  /// Titre principal de l'activité
  String _getActivityTitle(_Activity activity) {
    switch (activity.name) {
      case 'Rencontrer Dieu':
        return 'Rencontrer Dieu\ndans Sa Parole';
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
      case 'Rencontrer Dieu':
        return 'QUOTIDIEN';
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
      case 'Rencontrer Dieu':
        return '15 min';
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
      case 'Rencontrer Dieu':
        return 'Méditation biblique quotidienne pour nourrir votre âme et grandir dans la foi.';
      case 'Affermir ma foi':
        return 'Quiz intelligent couvrant les 27 livres du Nouveau Testament avec IA divine.';
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
    required this.route
  });
  final String name;
  final String subtitle;
  final String icon;
  final List<Color> gradient;
  final String route;
}

