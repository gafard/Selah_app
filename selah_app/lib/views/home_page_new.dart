import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_vm.dart';
import '../services/background_tasks.dart';
import '../main.dart' show telemetry;

class HomePageNew extends StatefulWidget {
  const HomePageNew({super.key});

  @override
  State<HomePageNew> createState() => _HomePageNewState();
}

class _HomePageNewState extends State<HomePageNew> {
  int _navIndex = 1; // 0 = Profil/Paramètres, 1 = Home, 2 = Étude/Quiz

  @override
  void initState() {
    super.initState();
    // Track page initialization
    telemetry.track('home_page_initialized');
  }

  void _handleNavigation(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: // Profil / Paramètres
        HapticFeedback.selectionClick();
        telemetry.track('navigation_clicked', props: {'destination': 'profile'});
        Navigator.pushNamed(context, '/profile_settings');
        break;
      case 1: // Accueil
        HapticFeedback.selectionClick();
        telemetry.track('navigation_clicked', props: {'destination': 'home'});
        // On reste ici
        break;
      case 2: // Étude / Quiz
        HapticFeedback.selectionClick();
        telemetry.track('navigation_clicked', props: {'destination': 'bible_quiz'});
        Navigator.pushNamed(context, '/bible_quiz');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackgroundShapes(),
            _buildSyncIndicator(),
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
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildProgressSection(),
                            const SizedBox(height: 20),
                            _buildBibleSection(),
                            const SizedBox(height: 20),
                            _buildQuickActions(),
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
      bottomNavigationBar: CircleNavBar(
        activeIcons: const [
          Icon(Icons.person, color: Color(0xFF6D28D9)),
          Icon(Icons.home, color: Color(0xFF059669)),
          Icon(Icons.auto_stories, color: Color(0xFF2563EB)),
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
        onChanged: _handleNavigation,
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
    );
  }

  Widget _buildHeader() {
    return Consumer<HomeVM>(
      builder: (context, homeVM, child) {
        final state = homeVM.state;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shalom, ${state.greetingName}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Que ta journée soit bénie',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return Consumer<HomeVM>(
      builder: (context, homeVM, child) {
        final state = homeVM.state;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.today, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Text(
                    'Progression du jour',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.tasksDone}/${state.tasksTotal} tâches terminées',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(state.progress * 100).toStringAsFixed(1)}% complété',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF059669),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBibleSection() {
    return Consumer<HomeVM>(
      builder: (context, homeVM, child) {
        final state = homeVM.state;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: Color(0xFF6D28D9)),
                  const SizedBox(width: 8),
                  Text(
                    'Version de la Bible',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Version actuelle: ${state.bibleVersion ?? 'Aucune'}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        telemetry.track('bible_download_started', props: {'version': 'LSG'});
                        await BackgroundTasks.queueBible('LSG');
                        await homeVM.changeBibleVersion('LSG');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Téléchargement de LSG en cours...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('LSG'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        telemetry.track('bible_download_started', props: {'version': 'S21'});
                        await BackgroundTasks.queueBible('S21');
                        await homeVM.changeBibleVersion('S21');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Téléchargement de S21 en cours...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('S21'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              if (state.hasPendingSync) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Synchronisation en cours...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                'Actions rapides',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    telemetry.track('quick_action_clicked', props: {'action': 'meditation'});
                    Navigator.pushNamed(context, '/meditation');
                  },
                  icon: const Icon(Icons.self_improvement, size: 16),
                  label: const Text('Méditation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    telemetry.track('quick_action_clicked', props: {'action': 'prayer'});
                    Navigator.pushNamed(context, '/prayer');
                  },
                  icon: const Icon(Icons.favorite, size: 16),
                  label: const Text('Prière'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return Consumer<HomeVM>(
      builder: (context, homeVM, child) {
        if (!homeVM.state.hasPendingSync) {
          return const SizedBox.shrink();
        }
        return Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sync',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundShapes() {
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
}
