import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestNavigationPage extends StatelessWidget {
  const TestNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D29), // Fond sombre comme Superlist
        ),
        child: Stack(
          children: [
            // Formes décoratives en arrière-plan
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundShapesPainter(),
              ),
            ),
            // AppBar personnalisé
            SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'Test Navigation',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Pour centrer le titre
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pages disponibles :',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Section Authentification
                          Text(
                            'Authentification :',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bouton Login
                          _buildNavigationButton(
                            context,
                            'Connexion',
                            'Page de connexion avec design moderne',
                            Icons.login,
                            const Color(0xFF8B5CF6), // Violet pour les accents
                            '/login',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Register
                          _buildNavigationButton(
                            context,
                            'Inscription',
                            'Création de compte utilisateur',
                            Icons.person_add,
                            const Color(0xFF8B5CF6),
                            '/register',
                          ),

                          const SizedBox(height: 20),

                          // Bouton Welcome Page
                          _buildNavigationButton(
                            context,
                            'Page de bienvenue',
                            'Page d\'accueil moderne avec authentification',
                            Icons.waving_hand,
                            const Color(0xFF8B5CF6),
                            '/welcome',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Onboarding
                          _buildNavigationButton(
                            context,
                            'Onboarding',
                            'Page d\'introduction avec 3 slides',
                            Icons.slideshow,
                            Colors.blue,
                            '/onboarding',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Profil Complet
                          _buildNavigationButton(
                            context,
                            'Profil Complet',
                            'Compléter les informations utilisateur',
                            Icons.person_add_alt_1_rounded,
                            const Color(0xFF4CAF50),
                            '/complete_profile',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Goals (Plans prédéfinis)
                          _buildNavigationButton(
                            context,
                            'Goals - Plans prédéfinis',
                            'Sélection des plans avec swipe',
                            Icons.swipe,
                            Colors.orange,
                            '/goals',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Plans Presets
                          _buildNavigationButton(
                            context,
                            'Plans Presets',
                            'Liste des plans prédéfinis',
                            Icons.list,
                            Colors.orange,
                            '/preset_plans',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Plan Personnalisé
                          _buildNavigationButton(
                            context,
                            'Plan Personnalisé',
                            'Créer votre propre plan de lecture',
                            Icons.tune_rounded,
                            const Color(0xFF8B7355),
                            '/custom_plan',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Home
                          _buildNavigationButton(
                            context,
                            'Home page',
                            'Page d\'accueil classique',
                            Icons.home,
                            Colors.green,
                            '/home',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Selah Home
                          _buildNavigationButton(
                            context,
                            'Selah Home',
                            'Page d\'accueil moderne avec cartes',
                            Icons.dashboard,
                            Colors.purple,
                            '/selah_home',
                          ),

                          const SizedBox(height: 20),

                          // Section Pages fonctionnelles
                          Text(
                            'Pages fonctionnelles :',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bouton Profil complet
                          _buildNavigationButton(
                            context,
                            'Profil complet',
                            'Configuration du profil utilisateur',
                            Icons.person,
                            Colors.teal,
                            '/complete_profile',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Vidéos bibliques
                          _buildNavigationButton(
                            context,
                            'Vidéos bibliques',
                            'Contenu vidéo et méditation',
                            Icons.play_circle,
                            Colors.red,
                            '/bible_videos',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Reader
                          _buildNavigationButton(
                            context,
                            'Lecteur biblique',
                            'Lecture quotidienne avec versets',
                            Icons.menu_book,
                            Colors.blue,
                            '/reader',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Reader Moderne
                          _buildNavigationButton(
                            context,
                            'Lecteur Moderne',
                            'Lecteur avec design moderne',
                            Icons.menu_book,
                            Colors.blue,
                            '/reader_modern',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Reader Settings
                          _buildNavigationButton(
                            context,
                            'Paramètres Lecteur',
                            'Configuration du lecteur',
                            Icons.settings,
                            Colors.grey,
                            '/reader_settings',
                          ),

                          const SizedBox(height: 16),

                          _buildNavigationButton(
                            context,
                            'Système de surlignage',
                            'Surlignage exactement comme l\'image',
                            Icons.highlight,
                            Colors.orange,
                            '/reader_highlight',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Meditation
                          _buildNavigationButton(
                            context,
                            'Méditation',
                            'Page de méditation simple',
                            Icons.psychology_alt_rounded,
                            Colors.purple,
                            '/meditation',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Meditation Flow
                          _buildNavigationButton(
                            context,
                            'Méditation Flow',
                            'Processus complet de méditation',
                            Icons.psychology_alt_rounded,
                            Colors.purple,
                            '/meditation/flow',
                          ),

                          const SizedBox(height: 12),

                          _buildNavigationButton(
                            context,
                            'Nouveau Chooser',
                            'Méditation Libre vs QCM',
                            Icons.psychology_alt_rounded,
                            Colors.purple,
                            '/meditation/chooser',
                          ),

                          const SizedBox(height: 12),

                          _buildNavigationButton(
                            context,
                            'Méditation Flow',
                            'Processus complet de méditation en 5 étapes',
                            Icons.psychology_alt_rounded,
                            Colors.purple,
                            '/meditation/flow',
                            arguments: {
                              'planId': 'demo-plan',
                              'day': 3,
                              'ref': 'Jean 3:16',
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildNavigationButton(
                            context,
                            'Analyse de Passage',
                            'Extraction automatique de faits et génération de QCM',
                            Icons.auto_awesome_rounded,
                            Colors.blue,
                            '/passage_analysis_demo',
                          ),

                          const SizedBox(height: 12),


                          const SizedBox(height: 16),

                          // Bouton Journal
                          _buildNavigationButton(
                            context,
                            'Journal',
                            'Journal personnel et réflexions',
                            Icons.book,
                            Colors.brown,
                            '/journal',
                          ),

                          const SizedBox(height: 16),

                          // Bouton Paramètres
                          _buildNavigationButton(
                            context,
                            'Paramètres',
                            'Configuration de l\'application',
                            Icons.settings,
                            Colors.grey,
                            '/settings',
                          ),

                          const SizedBox(height: 16),

                          _buildNavigationButton(
                            context,
                            'Analyse de Prière',
                            'Détection automatique des catégories de prière',
                            Icons.auto_awesome,
                            Colors.purple,
                            '/prayer_analysis',
                          ),

                          const SizedBox(height: 12),

                          _buildNavigationButton(
                            context,
                            'Test Classification',
                            'Exemples de classification automatique',
                            Icons.science,
                            Colors.purple,
                            '/prayer_test',
                          ),

                          const SizedBox(height: 12),

                          _buildNavigationButton(
                            context,
                            'Générateur de Prière',
                            'Transforme vos réponses en prières structurées',
                            Icons.auto_fix_high,
                            Colors.purple,
                            '/prayer_generator',
                          ),

                          const SizedBox(height: 12),

                          _buildNavigationButton(
                            context,
                            'Workflow Complet',
                            'Démonstration du processus complet',
                            Icons.account_tree,
                            Colors.purple,
                            '/prayer_workflow_demo',
                          ),

                          const SizedBox(height: 20),

                          // Section Pages de succès
                          Text(
                            'Pages de succès :',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bouton Inscription réussie
                          _buildNavigationButton(
                            context,
                            'Inscription réussie',
                            'Page de succès pour l\'inscription',
                            Icons.person_add_alt_1,
                            Colors.green,
                            '/success/registration',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Connexion réussie
                          _buildNavigationButton(
                            context,
                            'Connexion réussie',
                            'Page de succès pour la connexion',
                            Icons.login,
                            Colors.blue,
                            '/success/login',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Plan créé
                          _buildNavigationButton(
                            context,
                            'Plan créé',
                            'Page de succès pour la création de plan',
                            Icons.check_circle,
                            Colors.orange,
                            '/success/plan_created',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Analyse terminée
                          _buildNavigationButton(
                            context,
                            'Analyse terminée',
                            'Page de succès pour l\'analyse (comme l\'image)',
                            Icons.analytics,
                            Colors.purple,
                            '/success/analysis',
                          ),

                          const SizedBox(height: 12),

                          // Bouton Sauvegarde réussie
                          _buildNavigationButton(
                            context,
                            'Sauvegarde réussie',
                            'Page de succès pour la sauvegarde',
                            Icons.save,
                            Colors.teal,
                            '/success/save',
                          ),

                          const SizedBox(height: 20),

                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1), // Fond semi-transparent
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Instructions :',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cliquez sur les boutons ci-dessus pour naviguer vers les différentes pages de l\'application. Utilisez le bouton retour de votre appareil pour revenir à cette page de navigation.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildNavigationButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route, {
    Map<String, dynamic>? arguments,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // Fond semi-transparent
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (route.startsWith('/meditation/start')) {
            Navigator.pushNamed(
              context,
              '/meditation/start',
              arguments: {
                'planId': 'demo-plan',
                'day': 3,
                'ref': 'Jean 3:16',
              },
            );
          } else {
            Navigator.pushNamed(
              context, 
              route,
              arguments: arguments,
            );
          }
        },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Formes géométriques dispersées
    final shapes = [
      // Cercle en bas à gauche
      Offset(size.width * 0.1, size.height * 0.8),
      // Cercle en haut à droite
      Offset(size.width * 0.85, size.height * 0.15),
      // Cercle au centre
      Offset(size.width * 0.7, size.height * 0.6),
      // Cercle en bas à droite
      Offset(size.width * 0.9, size.height * 0.9),
      // Cercle supplémentaire en haut à gauche
      Offset(size.width * 0.15, size.height * 0.25),
      // Cercle supplémentaire au centre gauche
      Offset(size.width * 0.2, size.height * 0.6),
    ];

    for (final shape in shapes) {
      canvas.drawCircle(shape, 30, paint);
    }

    // Lignes décoratives
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Ligne diagonale
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      linePaint,
    );

    // Ligne horizontale
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.4),
      linePaint,
    );

    // Ligne verticale supplémentaire
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.8),
      linePaint,
    );

    // Formes supplémentaires
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Croix en haut à droite
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.3),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.2),
      Offset(size.width * 0.75, size.height * 0.3),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}