import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../widgets/selah_logo.dart';
import '../services/user_prefs_hive.dart';
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
      final prefs = Provider.of<UserPrefsHive>(context, listen: false);
      final connectivity = Provider.of<ConnectivityService>(context, listen: false);
      
      // Vérifier l'état de l'utilisateur (priorité au stockage local)
      final hasAccount = prefs.profile['hasAccount'] == true;
      final profileComplete = prefs.profile['profileComplete'] == true;
      final hasOnboarded = prefs.profile['hasOnboarded'] == true;
      
      // Logique de navigation offline-first
      if (!hasAccount) {
        // Pas de compte → Page de bienvenue
        Navigator.pushReplacementNamed(context, '/welcome');
      } else if (!profileComplete) {
        // Compte créé mais profil incomplet → Compléter le profil
        Navigator.pushReplacementNamed(context, '/complete_profile');
      } else if (!hasOnboarded) {
        // Profil complet mais pas d'onboarding → Onboarding
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // Tout est prêt → Page d'accueil
        Navigator.pushReplacementNamed(context, '/home');
      }
      
      // Log de télémetry pour debug
      if (kDebugMode) {
        print('🧭 Navigation: hasAccount=$hasAccount, profileComplete=$profileComplete, hasOnboarded=$hasOnboarded');
        print('🌐 Connectivité: ${connectivity.isOnline ? "En ligne" : "Hors ligne"}');
      }
      
    } catch (e) {
      // En cas d'erreur, fallback vers la page de bienvenue
      if (kDebugMode) {
        print('❌ Erreur navigation: $e');
      }
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      // Fond avec dégradé bleu Selah (utilise les couleurs du thème)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary, // Bleu Selah
              colorScheme.secondary, // Sauge
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Selah animé avec blur frosté
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    // Blur frosté subtil
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Semantics(
                  label: 'Logo Selah - Application de méditation chrétienne',
                  child: const Center(
                    child: SelahSplashLogo(size: 100),
                  ),
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
                duration: _lowPower ? 0.ms : 2000.ms, // Désactivé sur bas de gamme
                delay: 1000.ms,
                color: Colors.white.withOpacity(0.3),
              ),

              const SizedBox(height: 40),

              // Titre de l'application avec letter-spacing premium
              Semantics(
                label: 'Selah - Application de méditation',
                child: Text(
                  'Selah',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5, // Tracking premium
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 500.ms)
              .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 500.ms),

              const SizedBox(height: 16),

              // Sous-titre / Tagline
              Semantics(
                label: 'Un temps pour s\'arrêter et méditer',
                child: Text(
                  'Un temps pour s\'arrêter et méditer',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 800.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 800.ms),

              const SizedBox(height: 60),

              // Indicateur de chargement
              Semantics(
                label: 'Chargement de l\'application',
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 1200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
