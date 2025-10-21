import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🔔 Écran d'alarme plein écran
/// 
/// S'affiche quand l'alarme se déclenche avec options interactives
class AlarmScreenPage extends StatefulWidget {
  const AlarmScreenPage({super.key});

  @override
  State<AlarmScreenPage> createState() => _AlarmScreenPageState();
}

class _AlarmScreenPageState extends State<AlarmScreenPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Icône animée
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4CAF50),
                              Color(0xFF8BC34A),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.self_improvement,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Titre
                Text(
                  'Selah',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Sous-titre
                Text(
                  'Moment de méditation',
                  style: GoogleFonts.openSans(
                    fontSize: 18,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Message
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'C\'est l\'heure de ta méditation quotidienne 🙏\n\n'
                    'Prends un moment pour te connecter avec Dieu et méditer sa Parole.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Boutons d'action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Bouton principal
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleStartNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 8,
                            shadowColor: Colors.green.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Commencer maintenant',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Boutons secondaires
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _handleSnooze,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white54,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.snooze, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rappel 10min',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _handleDismiss,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.close, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ignorer',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleStartNow() {
    print('📱 Commencer maintenant - Navigation vers l\'app');
    // Fermer l'écran d'alarme et naviguer vers l'app
    Navigator.of(context).pop();
    // Optionnel: naviguer vers une page spécifique
    // context.go('/meditation');
  }

  void _handleSnooze() {
    print('⏰ Rappel dans 10 minutes');
    // Le rappel est géré par IntelligentAlarmService
    Navigator.of(context).pop();
  }

  void _handleDismiss() {
    print('🚫 Alarme ignorée');
    Navigator.of(context).pop();
  }
}
