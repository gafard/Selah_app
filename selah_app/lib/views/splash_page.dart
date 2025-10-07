import 'dart:io';
import 'dart:ui'; // ✅ Pour ImageFilter
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Pour GoogleFonts
import '../widgets/selah_logo.dart';
import '../services/local_storage_service.dart';
import '../services/connectivity_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;
  bool _lowPower = false;

  @override
  void initState() {
    super.initState();
    // Forcer les icônes en clair sur le dégradé foncé
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    // Détecter les appareils bas de gamme pour désactiver les animations coûteuses
    try {
      _lowPower = !kIsWeb && Platform.isAndroid && 
                  (Platform.environment['ANDROID_EMULATOR'] == 'true' || 
                   Platform.environment['FLUTTER_TEST'] == 'true');
    } catch (e) {
      // Sur le web, Platform.isAndroid n'est pas supporté
      _lowPower = false;
    }
    
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    if (_navigated) return;
    _navigated = true;
    
    // Attendre minimum 3500ms pour une expérience premium (3,5 secondes)
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if (!mounted) return;
    
    // Haptique subtile avant la navigation
    HapticFeedback.lightImpact();
    
    // Logique de navigation offline-first
    await _checkFlowAndNavigate();
  }

  /// Vérifie le flux utilisateur selon l'état local (offline-first)
  Future<void> _checkFlowAndNavigate() async {
    try {
      // Charger depuis LocalStorage (offline-first)
      final localUser = LocalStorageService.getLocalUser();
      final isOnline = ConnectivityService.instance.isOnline;
      
      // Vérifier l'état de l'utilisateur (priorité au stockage local)
      final hasAccount = localUser != null && localUser['id'] != null;
      final profileComplete = localUser?['is_complete'] == true;
      final hasOnboarded = localUser?['has_onboarded'] == true;
      final hasPlan = localUser?['current_plan_id'] != null;
      
      // Logique de navigation offline-first (GoRouter)
      if (!hasAccount) {
        // Pas de compte → Page de bienvenue
        if (mounted) context.go('/welcome');
      } else if (!profileComplete) {
        // Compte créé mais profil incomplet → Compléter le profil
        if (mounted) context.go('/complete_profile');
      } else if (!hasPlan) {
        // Profil complet mais pas de plan → Sélection de plan
        if (mounted) context.go('/goals');
      } else if (!hasOnboarded) {
        // Profil complet mais pas d'onboarding → Onboarding
        if (mounted) context.go('/onboarding');
      } else {
        // Tout est prêt → Page d'accueil
        if (mounted) context.go('/home');
      }
      
      // Log de télémetry pour debug
      if (kDebugMode) {
        print('🧭 Navigation: hasAccount=$hasAccount, profileComplete=$profileComplete, hasPlan=$hasPlan, hasOnboarded=$hasOnboarded');
        print('🌐 Connectivité: ${isOnline ? "En ligne" : "Hors ligne"}');
      }
      
    } catch (e) {
      // En cas d'erreur, fallback vers la page de bienvenue
      if (kDebugMode) {
        print('❌ Erreur navigation: $e');
      }
      if (mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Dégradé identique à auth_page.dart
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1D29), Color(0xFF112244)], // ✅ Même dégradé
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ✅ Ornements identiques à auth_page.dart
              Positioned(
                right: -60,
                top: -40,
                child: _softBlob(180),
              ),
              Positioned(
                left: -40,
                bottom: -50,
                child: _softBlob(220),
              ),

              // Contenu centré
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12), // ✅ Même transparence
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo Selah avec style auth_page
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: const Center(
                                child: SelahSplashLogo(size: 80),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 1000.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                            )
                            .shimmer(
                              duration: _lowPower ? 0.ms : 2000.ms,
                              delay: 1000.ms,
                              color: Colors.white.withOpacity(0.3),
                            ),

                            const SizedBox(height: 24),

                            // Titre SELAH (style auth_page)
                            Text(
                              'SELAH',
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 500.ms)
                            .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 500.ms),

                            const SizedBox(height: 12),

                            // Sous-titre
                            Text(
                              'Un temps pour s\'arrêter et méditer',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 800.ms)
                            .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 800.ms),

                            const SizedBox(height: 40),

                            // Indicateur de chargement
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 1200.ms),
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
    );
  }
  
  /// ✅ Ornement identique à auth_page.dart
  Widget _softBlob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.20), Colors.transparent],
        ),
      ),
    );
  }
}
