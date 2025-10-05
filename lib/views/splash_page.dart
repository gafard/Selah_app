import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/selah_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Attendre 3 secondes pour afficher le splash screen
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Navigation simple vers la page de bienvenue
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond avec dégradé bleu Selah
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1553FF), // Bleu Selah
              Color(0xFF49C98D), // Sauge
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Selah animé
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
                  ],
                ),
                child: const Center(
                  child: SelahSplashLogo(size: 100),
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
                duration: 2000.ms,
                delay: 1000.ms,
                color: Colors.white.withOpacity(0.3),
              ),

              const SizedBox(height: 40),

              // Titre de l'application
              Text(
                'Selah',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 500.ms)
              .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 500.ms),

              const SizedBox(height: 16),

              // Sous-titre / Tagline
              Text(
                'Un temps pour s\'arrêter et méditer',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 800.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 800.ms),

              const SizedBox(height: 60),

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
    );
  }
}
