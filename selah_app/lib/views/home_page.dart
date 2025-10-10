import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/home_vm.dart';
import '../state/app_state.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/selah_logo.dart';
import '../services/stable_random_service.dart';

// Widgets factorisés
import '../widgets/home/header.dart';
import '../widgets/home/daily_blessing.dart';
import '../widgets/home/calendar_bar.dart';
import '../widgets/home/activity_carousel.dart';
import '../widgets/home/progress_card.dart';
import 'profile_settings_page.dart';
import 'journal_page.dart';
import 'spiritual_wall_page.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  int _navIndex = 1; // 0 = Paramètres, 1 = Home, 2 = Journal, 3 = Mur spirituel

  @override
  void initState() {
    super.initState();
    // Load user data and refresh quiz stats once on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeVM>().load();
      context.read<HomeVM>().refreshQuizProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVM>();
    final hasSync = context.watch<AppState>().value.hasPendingSync;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0B1025),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1025), Color(0xFF1C1740), Color(0xFF2D1B69)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  const ConnectivityIndicator(),
                  if (hasSync) const _SyncBadge(),
                  // Contenu principal selon l'index de navigation
                  _buildCurrentPage(vm),
                ],
              ),
            ),
          ),

      bottomNavigationBar: CircleNavBar(
        activeIcons: const [
          Icon(Icons.settings, color: Color(0xFF6D28D9)),
          Icon(Icons.home, color: Color(0xFF059669)),
          Icon(Icons.book, color: Color(0xFF2563EB)),
          Icon(Icons.people, color: Color(0xFFDC2626)),
        ],
        inactiveIcons: const [
          Icon(Icons.settings_outlined, color: Color(0xFF9CA3AF), size: 24),
          Icon(Icons.home_outlined, color: Color(0xFF9CA3AF), size: 24),
          Icon(Icons.book_outlined, color: Color(0xFF9CA3AF), size: 24),
          Icon(Icons.people_outline, color: Color(0xFF9CA3AF), size: 24),
        ],
        color: Colors.white,
        height: 62,
        circleWidth: 62,
        initIndex: _navIndex,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          setState(() => _navIndex = v);
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
          colors: [Color(0xFFE0E7FF), Color(0xFFF0FDFA)],
        ),
      ),
        ),
      ],
    );
  }

  /// Construit la page actuelle selon l'index de navigation
  Widget _buildCurrentPage(HomeVM vm) {
    switch (_navIndex) {
      case 0: // Paramètres
        return const ProfileSettingsPage();
      case 1: // Home
        return _buildHomeContent(vm);
      case 2: // Journal
        return const JournalPage();
      case 3: // Mur spirituel
        return const SpiritualWallPage();
      default:
        return _buildHomeContent(vm);
    }
  }

  /// Contenu de la page d'accueil
  Widget _buildHomeContent(HomeVM vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header (Shalom + logo)
          HomeHeader(
            displayName: vm.state.firstName,
            subtitle: 'Dieu t\'attend dans Sa Parole',
            trailing: const SelahAppIcon(size: 48),
          ),
          const SizedBox(height: 12),

          // Message d'encouragement intelligent (remplace le verset du jour)
          _buildIntelligentEncouragement(vm),

          const SizedBox(height: 18),

          // Calendar line + quick stats
          const CalendarBar(),

          const SizedBox(height: 18),

          // Activity carousel (Lecture / Quiz / Communauté)
          const Expanded(child: ActivityCarousel()),

          const SizedBox(height: 14),

          // Progress (goals of the day) - maintenant après les cartes
          HomeProgressCard(
            title: 'Vos objectifs',
            done: vm.state.tasksDone,
            total: vm.state.tasksTotal,
            currentStreak: vm.state.currentStreak ?? 0,
            weeksRemaining: vm.state.weeksRemaining ?? 0,
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  /// Message d'encouragement intelligent basé sur la progression réelle
  Widget _buildIntelligentEncouragement(HomeVM vm) {
    // Calculer le taux de complétion
    final completionRate = vm.state.tasksTotal > 0 
        ? (vm.state.tasksDone / vm.state.tasksTotal).clamp(0.0, 1.0)
        : 0.0;
    
    // Générer le message d'encouragement intelligent
    String encouragementMessage;
    try {
      // Utiliser le service de messages d'encouragement
      encouragementMessage = StableMessageService.getEncouragementMessage(
        planId: 'current_plan', // TODO: Récupérer l'ID du plan actuel
        dayNumber: DateTime.now().day,
        completionRate: completionRate,
      );
    } catch (e) {
      // Fallback en cas d'erreur
      encouragementMessage = 'Que cette journée soit bénie ! 🙏';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Icône d'encouragement
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                // Message d'encouragement
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message du jour',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        encouragementMessage,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge();
  @override
  Widget build(BuildContext context) {
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
            Text('Sync...', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}