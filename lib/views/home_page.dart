import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import '../models/home_page_model.dart';
import '../services/image_service.dart';
import '../widgets/selah_logo.dart';
import 'reader_page_modern.dart';
import 'spiritual_wall_page.dart';
import 'bible_quiz_page.dart';
import 'coming_soon_page.dart';
import 'pre_meditation_prayer_page.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> with TickerProviderStateMixin {
  late HomePageModel model;
  late PageController _pageController;
  int _currentIndex = 0;
  int _navIndex = 1; // Index pour la navigation bar (1 = Home par défaut)

  late List<Map<String, dynamic>> weekDays;

  final activities = [
    {
      'id': 1,
      'name': 'Lecture',
      'badge': 'Quotidien',
      'image': ImageService.getImage('bible_reading'),
      'gradient': [const Color(0xFFC6F830), const Color(0xFFD4FA4D), const Color(0xFFC6F830)],
      'patternColor': const Color(0xFFA8D91F),
      'route': '/pre_meditation_prayer',
    },
    {
      'id': 2,
      'name': 'Quiz Biblique',
      'badge': 'Avancé',
      'image': ImageService.getImage('bible_study'),
      'gradient': [const Color(0xFFF87171), const Color(0xFFFCA5A5), const Color(0xFFF87171)],
      'patternColor': const Color(0xFFEF4444),
      'route': '/bible_quiz',
    },
    {
      'id': 3,
      'name': 'Communauté',
      'badge': 'Partage',
      'image': ImageService.getImage('community_fellowship'),
      'gradient': [const Color(0xFF06B6D4), const Color(0xFF67E8F9), const Color(0xFF06B6D4)],
      'patternColor': const Color(0xFF0891B2),
      'route': '/community/new-post',
    },
  ];

  @override
  void initState() {
    super.initState();
    model = HomePageModel()..initState(context);
    _pageController = PageController(viewportFraction: 0.82);
    weekDays = _generateCurrentWeek(); // mêmes clés: day / date / isToday
    
    // Vérification du contexte de passage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasContext = true; // Pour la page d'accueil, on a toujours le contexte
      if (!hasContext) {
        Navigator.of(context).pushReplacementNamed('/reader');
      }
    });
  }

  List<Map<String, dynamic>> _generateCurrentWeek() {
    final now = DateTime.now();

    // Semaine commençant le dimanche (Dim, Lun, …) pour coller à ton UI
    final weekday0to6 = (now.weekday % 7); // Dim=0, Lun=1, …, Sam=6
    final startOfWeek = now.subtract(Duration(days: weekday0to6));

    const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

    return List.generate(7, (i) {
      final d = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);
      final isToday = d.day == now.day && d.month == now.month && d.year == now.year;
      return {
        'day': dayNames[i],
        'date': '${d.day}',
        'isToday': isToday,
      };
    });
  }

  @override
  void dispose() {
    model.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Gestion de la navigation
  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Paramètres
        Navigator.pushNamed(context, '/coming_soon');
        break;
      case 1: // Accueil (déjà sur cette page)
        // Ne rien faire, on est déjà sur la page d'accueil
        break;
      case 2: // Étude
        Navigator.pushNamed(context, '/bible_quiz');
        break;
    }
  }

  // Navigation vers la lecture avec prière préalable
  void _navigateToReading() {
    Navigator.pushNamed(context, '/pre_meditation_prayer');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            // Background shapes
            _buildBackgroundShapes(),
            
            // Main content
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Main content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Header
                            _buildHeader(),
                            const SizedBox(height: 24),
                            
                            // Calendar
                            _buildCalendar(),
                            const SizedBox(height: 20),
                            
                            // Activity Carousel
                            Expanded(
                              child: _buildActivityCarousel(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Progress Card
                            _buildProgressCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        // Geometric shapes
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: 30,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC6F830), Color(0xFFD4FA4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: 60,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    // Prénom utilisateur (temporairement Justin, à brancher sur Supabase plus tard)
    final userFirstName = 'Justin'; // TODO: à brancher sur Supabase (users.display_name)
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shalom, $userFirstName',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            // SUPPRIMER le Text() de la date ici
          ],
        ),
        // Logo Selah à la place de l'avatar
        const SelahAppIcon(
          size: 48,
          useBlueBackground: false,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Row(
      children: weekDays.map((day) {
        final isToday = day['isToday'] as bool;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF8B5CF6) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  day['day'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isToday ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day['date'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityCarousel() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isActive = index == _currentIndex;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                transform: Matrix4.identity()
                  ..scale(isActive ? 1.0 : 0.92),
                child: _buildActivityCard(activity, isActive),
              );
            },
          ),
        ),
        
        // Pagination dots
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(activities.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1F2937) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: activity['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (activity['gradient'][0] as Color).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(activity['patternColor'] as Color),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activity['badge'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Image
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          activity['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Go To Button
                Builder(
                  builder: (context) {
                    final route = activity['route'] as String?;
                    return _AnimatedStartButton(
                      route: route,
                      onTap: route == null ? null : () => _navigateWithAnimation(context, route),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vos objectifs quotidiens presque terminés !',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '5/6 tâches terminées',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          
          // Circular progress
          Builder(
            builder: (context) {
              final tasksDone = 5;
              final tasksTotal = 6;
              final progress = tasksDone / tasksTotal;
              
              return SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFF374151),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC6F830)),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  
  _PatternPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    // Draw curved lines
    for (int i = 0; i < 6; i++) {
      final y = 40 + (i * 40);
      path.reset();
      path.moveTo(0, y.toDouble());
      path.quadraticBezierTo(
        size.width * 0.25, y - 20,
        size.width * 0.5, y.toDouble(),
      );
      path.quadraticBezierTo(
        size.width * 0.75, y + 20,
        size.width, y.toDouble(),
      );
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Navigation avec animation simple
void _navigateWithAnimation(BuildContext context, String route) {
  Navigator.pushNamed(context, route);
}

// Widget pour le bouton animé
class _AnimatedStartButton extends StatefulWidget {
  final String? route;
  final VoidCallback? onTap;

  const _AnimatedStartButton({
    required this.route,
    required this.onTap,
  });

  @override
  State<_AnimatedStartButton> createState() => _AnimatedStartButtonState();
}

class _AnimatedStartButtonState extends State<_AnimatedStartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _isPressed 
                      ? const Color(0xFF374151) // Couleur plus claire quand pressé
                      : const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commencer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          transform: Matrix4.translationValues(
                            _isPressed ? 2.0 : 0.0,
                            0.0,
                            0.0,
                          ),
                          child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          transform: Matrix4.translationValues(
                            _isPressed ? 2.0 : 0.0,
                            0.0,
                            0.0,
                          ),
                          child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          transform: Matrix4.translationValues(
                            _isPressed ? 2.0 : 0.0,
                            0.0,
                            0.0,
                          ),
                          child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}