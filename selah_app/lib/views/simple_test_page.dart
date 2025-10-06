import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SimpleTestPage extends StatelessWidget {
  const SimpleTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test de Navigation',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Authentification & Onboarding
          _buildCategory(
            context,
            '🔐 Authentification & Onboarding',
            [
              _buildPageItem(context, 'Bienvenue', '/welcome'),
              _buildPageItem(context, 'Onboarding Dynamique', '/welcome'),
              _buildPageItem(context, 'Félicitations', '/congrats'),
              _buildPageItem(context, 'Profil Complet', '/complete_profile'),
            ],
          ),

          const SizedBox(height: 20),

          // Plans de Lecture
          _buildCategory(
            context,
            '📖 Plans de Lecture',
            [
              _buildPageItem(context, 'Objectifs & Plans', '/goals'),
              _buildPageItem(context, 'Plan Personnalisé', '/custom_plan'),
              _buildPageItem(context, 'Générateur de Plan', '/custom_plan_generator'),
              _buildPageItem(context, 'Import de Plan', '/import_plan'),
            ],
          ),

          const SizedBox(height: 20),

          // Pages Principales
          _buildCategory(
            context,
            '🏠 Pages Principales',
            [
              _buildPageItem(context, 'Accueil', '/home'),
              _buildPageItem(context, 'Journal', '/journal'),
              _buildPageItem(context, 'Profil & Paramètres', '/profile_settings'),
              _buildPageItem(context, 'Splash', '/splash'),
            ],
          ),

          const SizedBox(height: 20),

          // Lecture & Bible
          _buildCategory(
            context,
            '📚 Lecture & Bible',
            [
              _buildPageItem(context, 'Lecteur Moderne', '/reader'),
              _buildPageItem(context, 'Paramètres Lecteur', '/reader_settings'),
              _buildPageItem(context, 'Scan Bible Simple', '/scan/bible'),
              _buildPageItem(context, 'Scan Bible Avancé', '/scan/bible/advanced'),
              _buildPageItem(context, 'Quiz Biblique', '/bible_quiz'),
            ],
          ),

          const SizedBox(height: 20),

          // Méditation
          _buildCategory(
            context,
            '🧘 Méditation',
            [
              _buildPageItem(context, 'Choix de Méditation', '/meditation/chooser'),
              _buildPageItem(context, 'Méditation Libre', '/meditation/free'),
              _buildPageItem(context, 'Méditation QCM', '/meditation/qcm'),
              _buildPageItem(context, 'Test Compréhension', '/meditation/auto_qcm'),
              _buildPageItem(context, 'Prière Pré-Méditation', '/pre_meditation_prayer'),
            ],
          ),

          const SizedBox(height: 20),

          // Prière
          _buildCategory(
            context,
            '🙏 Prière',
            [
              _buildPageItem(context, 'Sujets de Prière', '/prayer_subjects'),
              _buildPageItem(context, 'Carrousel de Prière', '/prayer/carousel'),
              _buildPageItem(context, 'Générateur de Prière', '/prayer/generator'),
              _buildPageItem(context, 'Workflow Prière', '/prayer_workflow'),
            ],
          ),

          const SizedBox(height: 20),

          // Créativité & Partage
          _buildCategory(
            context,
            '✨ Créativité & Partage',
            [
              _buildPageItem(context, 'Poster de Verset', '/verse_poster'),
              _buildPageItem(context, 'Gratitude', '/gratitude'),
              _buildPageItem(context, 'Mur Spirituel', '/spiritual_wall'),
            ],
          ),

          const SizedBox(height: 20),

          // Pages de Succès
          _buildCategory(
            context,
            '✅ Pages de Succès',
            [
              _buildPageItem(context, 'Succès Inscription', '/success_registration'),
              _buildPageItem(context, 'Succès Connexion', '/success_login'),
              _buildPageItem(context, 'Succès Plan Créé', '/success_plan'),
            ],
          ),

          const SizedBox(height: 20),

          // Pages Temporaires
          _buildCategory(
            context,
            '🚧 Pages Temporaires',
            [
              _buildPageItem(context, 'Bientôt Disponible', '/coming_soon'),
              _buildPageItem(context, 'Démo Analyse Passage', '/passage_analysis_demo'),
            ],
          ),

          const SizedBox(height: 30),

          // Bouton retour accueil
          Center(
            child: ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

