import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:provider/provider.dart';

import '../models/home_page_model.dart';
import '../widgets/selah_logo.dart';
import '../services/home_vm.dart';
import '../services/telemetry_console.dart';
import '../widgets/connectivity_indicator.dart';
import '../state/app_state.dart';
import '../widgets/pattern_painter.dart';
import '../widgets/animated_start_button.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  late HomePageModel model;
  late PageController _pageController;
  int _currentIndex = 0;
  int _navIndex = 1; // 0 = Profil/Paramètres, 1 = Home, 2 = Étude/Quiz

  @override
  void initState() {
    super.initState();
    model = HomePageModel()..initState(context);
    _pageController = PageController(viewportFraction: 0.82);
    
    // Si nécessaire : rediriger si pas de contexte de lecture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // hasContext is always true for home page
      // if (!hasContext && mounted) {
      //   Navigator.of(context).pushReplacementNamed('/reader');
      // }
    });
  }


  @override
  void dispose() {
    model.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation (CircleNavBar)
  // ---------------------------------------------------------------------------
  void _handleNavigation(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: // Profil / Paramètres
        HapticFeedback.selectionClick();
        context.read<TelemetryConsole>().event('navigation_clicked', {'destination': 'profile'});
        Navigator.pushNamed(context, '/profile_settings');
        break;
      case 1: // Accueil
        HapticFeedback.selectionClick();
        context.read<TelemetryConsole>().event('navigation_clicked', {'destination': 'home'});
        // On reste ici. Option : remonter en haut si besoin.
        break;
      case 2: // Étude / Quiz
        HapticFeedback.selectionClick();
        context.read<TelemetryConsole>().event('navigation_clicked', {'destination': 'bible_quiz'});
        Navigator.pushNamed(context, '/bible_quiz');
        break;
    }
  }


  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------
  Widget _buildError(HomeVM vm) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Impossible de charger la page.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => vm.load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );

  Widget _buildSyncIndicator() {
    return Consumer<HomeVM>(
      builder: (context, homeVM, child) {
        if (!context.watch<AppState>().value.hasPendingSync) {
          return const SizedBox.shrink();
        }
        return Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Sync...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVM>();
    final userFirstName = vm.state.firstName;
    final tasksDone = vm.state.tasksDone;
    final tasksTotal = vm.state.tasksTotal;
    final hasSync = context.watch<AppState>().value.hasPendingSync;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackgroundShapes(),
            // Indicateur de connectivité
            const ConnectivityIndicator(),
            // Indicateur de sync en overlay si besoin
            if (hasSync) _buildSyncIndicator(),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                                      _buildHeader(displayName: userFirstName),
                            const SizedBox(height: 24),
                            _buildCalendar(),
                            const SizedBox(height: 20),
                            Expanded(
                                        child:
                                            _buildActivityCarousel(),
                            ),
                                      const SizedBox(height: 16),
                                      _buildProgressCard(tasksDone: tasksDone, tasksTotal: tasksTotal),
                            const SizedBox(height: 16),
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

      // ---------------- CircleNavBar (style Calm / Superlist) ----------------
      bottomNavigationBar: CircleNavBar(
        activeIcons: const [
          Icon(Icons.person, color: Color(0xFF6D28D9)), // deep purple
          Icon(Icons.home, color: Color(0xFF059669)), // emerald
          Icon(Icons.auto_stories, color: Color(0xFF2563EB)), // blue
        ],
        inactiveIcons: const [
          Padding(padding: EdgeInsets.only(bottom: 4), child: Text("Profil")),
          Padding(padding: EdgeInsets.only(bottom: 4), child: Text("Accueil")),
          Padding(padding: EdgeInsets.only(bottom: 4), child: Text("Étude")),
        ],
        color: Colors.white,
        height: 62,
        circleWidth: 62,
        initIndex: _navIndex,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          _handleNavigation(v);
        },
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
        shadowColor: const Color(0xFF6D28D9),
        elevation: 10,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFE0E7FF), Color(0xFFF0FDFA)], // indigo-50 -> teal-50
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    // Décor subtil façon "Calm/Superlist"
    return Stack(
      children: [
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

  Widget _buildHeader({required String displayName}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Greeting
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shalom, $displayName',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            // (On supprime la date ici pour rester épuré)
          ],
        ),
        // Logo Selah
        const SelahAppIcon(size: 48),
      ],
    );
  }

  Widget _buildCalendar() {
    const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final now = DateTime.now();
    
    return Row(
      children: List.generate(7, (index) {
        final date = now.subtract(Duration(days: now.weekday - 1 - index));
        final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF8B5CF6) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday ? Colors.transparent : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              children: [
                Text(
                  dayNames[index],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isToday
                        ? Colors.white
                        : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isToday
                        ? Colors.white
                        : const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Placeholder for reading status - can be enhanced later
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 10,
                      color: isToday
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActivityCarousel() {
    final activities = [
      {
        'name': 'Lecture',
        'badge': 'Quotidien',
        'imageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=300&fit=crop',
        'gradient': [0xFFC6F830, 0xFFD4FA4D, 0xFFC6F830],
        'patternColor': 0xFFA8D91F,
        'route': '/pre_meditation_prayer',
      },
      {
        'name': 'Quiz Biblique',
        'badge': 'Avancé',
        'imageUrl': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=300&fit=crop',
        'gradient': [0xFFF87171, 0xFFFCA5A5, 0xFFF87171],
        'patternColor': 0xFFEF4444,
        'route': '/bible_quiz',
      },
      {
        'name': 'Communauté',
        'badge': 'Partage',
        'imageUrl': 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400&h=300&fit=crop',
        'gradient': [0xFF06B6D4, 0xFF67E8F9, 0xFF06B6D4],
        'patternColor': 0xFF0891B2,
        'route': '/community/new-post',
      },
    ];

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isActive = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                transform: Matrix4.identity()..scale(isActive ? 1.0 : 0.92),
                child: _buildActivityCard(activity, isActive),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(activities.length, (index) {
            final isActive = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isActive) {
    final gradient = (activity['gradient'] as List<int>).map((c) => Color(c)).toList();
    final patternColor = Color(activity['patternColor'] as int);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Color((activity['gradient'] as List<int>).first).withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern décoratif (courbes fines)
          Positioned.fill(
            child: CustomPaint(
              painter: PatternPainter(patternColor),
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity['name'],
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activity['badge'],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Illustration
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.image,
                                size: 40,
                            color: Colors.white.withOpacity(0.75),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // CTA
                AnimatedStartButton(
                  route: activity['route'],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (activity['route'] != null) {
                      Navigator.pushNamed(context, activity['route']);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProgressCard({required int tasksDone, required int tasksTotal}) {
    final ratio = tasksTotal == 0 ? 0.0 : tasksDone / tasksTotal;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vos objectifs quotidiens',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$tasksDone/$tasksTotal tâches terminées',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          
          // Cercle de progression
          SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFF374151),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFC6F830),
                    ),
                      ),
                    ),
                    Center(
                      child: Text(
                    '${(ratio * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white,
                      fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

}