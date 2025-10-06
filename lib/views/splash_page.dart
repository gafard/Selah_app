import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:essai/services/app_state.dart';

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
    // Attendre au minimum 400ms pour éviter l'effet "flash de pages"
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;
    
    try {
      final appState = context.read<AppState>();
      
      // Attendre que le chargement soit terminé
      while (appState.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      
      // === SYSTÈME D'EXEMPTION COMPLET ===
      // 1. Non connecté → Welcome
      if (!appState.isLoggedIn) {
        context.pushReplacement('/welcome');
        return;
      }
      
      // 2. Connecté + !has_onboarded → Onboarding
      if (!appState.hasOnboarded) {
        context.pushReplacement('/onboarding');
        return;
      }
      
      // 3. Connecté + has_onboarded + !current_plan_id → PlanWizard
      if (appState.currentPlanId == null || appState.currentPlanId!.isEmpty) {
        context.pushReplacement('/goals');
        return;
      }
      
      // 4. Connecté + has_onboarded + current_plan_id → Home
      context.pushReplacement('/home');
    } catch (e) {
      // Mode test - redirection par défaut
      print('Erreur SplashPage: $e');
      context.pushReplacement('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nous utilisons un Consumer pour réagir aux changements de l'état de chargement
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          // Fond sombre et apaisant, similaire à l'exemple
          backgroundColor: const Color(0xFF1C1C1E),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Espace flexible pour centrer le contenu verticalement
                const Spacer(flex: 2),

                // Icône de l'application
                // TODO: Remplacez cette icône par votre logo officiel (ex: avec Image.asset)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355), // Couleur or/brun apaisante
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.self_improvement, // Icône de méditation temporaire
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // Titre de l'application
                Text(
                  'Selah',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Sous-titre / Tagline
                Text(
                  'Un temps pour s\'arrêter et méditer',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade400,
                  ),
                ),

                // Espace flexible pour pousser l'indicateur de chargement vers le bas
                const Spacer(flex: 3),

                // Indicateur de chargement visible uniquement pendant la vérification
                if (appState.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7355)),
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
