import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../widgets/selah_logo.dart';
import '../services/local_storage_service.dart';
import '../services/connectivity_service.dart';
import '../services/app_reset_service.dart'; // ✅ Service de réinitialisation

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Forcer les icônes en clair sur le dégradé foncé
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
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
      // ✅ Dégradé Selah
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
              // ✅ Ornements subtils
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

              // ✅ Logo Selah directement sur le fond
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo icône Selah
                    SelahLogo.round(size: 120)
                    .animate()
                    .fadeIn(duration: 1000.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOut,
                    ),

                    const SizedBox(height: 24),
                    
                    // Texte Selah en Gilroy Black (comme logo original)
                    Text(
                      'Selah',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 42,
                        fontWeight: FontWeight.w900, // ✅ Black (900 au lieu de 800)
                        color: Colors.white,
                        letterSpacing: 2, // ✅ Légèrement réduit pour Gilroy Black
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 400.ms),

                    const SizedBox(height: 16),

                    // Sous-titre
                    Text(
                      'Un temps pour s\'arrêter et méditer',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 700.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 700.ms),

                    const SizedBox(height: 40),

                    // Indicateur de chargement
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 1000.ms),
                  ],
                ),
              ),
              
              // 🔥 BOUTON DE RÉINITIALISATION (MODE DEBUG SEULEMENT)
              if (kDebugMode)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        // Confirmation avant réinitialisation
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('⚠️ Réinitialisation'),
                            content: const Text(
                              'Voulez-vous vraiment SUPPRIMER TOUTES les données locales ?\n\n'
                              'Cela va supprimer :\n'
                              '• Tous les comptes\n'
                              '• Tous les plans\n'
                              '• Toutes les préférences\n'
                              '• Toute la progression\n\n'
                              'Cette action est IRRÉVERSIBLE.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => context.pop(false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => context.pop(true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('TOUT SUPPRIMER'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          // Réinitialiser l'application
                          try {
                            await AppResetService.resetEverything();
                            
                            if (mounted) {
                              // Afficher un message de succès
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Application réinitialisée ! Redémarrage...'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              
                              // Attendre 2 secondes puis redémarrer
                              await Future.delayed(const Duration(seconds: 2));
                              
                              // Forcer la navigation vers /welcome
                              if (mounted) {
                                context.go('/welcome');
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                      label: const Text(
                        'Réinitialiser l\'app (DEBUG)',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
