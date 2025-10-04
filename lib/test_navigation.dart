import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/prayer_subjects_builder.dart';
import 'views/prayer_carousel_page.dart';

/// Page de test pour vérifier la navigation et les fonctionnalités
class TestNavigationPage extends StatelessWidget {
  const TestNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tests de Navigation',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Pages de Méditation
                _TestCard(
                  title: 'Méditation - Choix',
                  subtitle: 'Page de choix de méditation',
                  onTap: () => Navigator.pushNamed(context, '/meditation/chooser'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Méditation Libre',
                  subtitle: 'Méditation avec 3 étapes (Demander, Chercher, Frapper)',
                  onTap: () => Navigator.pushNamed(context, '/meditation/free'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Méditation QCM',
                  subtitle: 'Méditation guidée avec QCM',
                  onTap: () => Navigator.pushNamed(context, '/meditation/qcm'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Test Compréhension',
                  subtitle: 'QCM automatique',
                  onTap: () => Navigator.pushNamed(context, '/meditation/auto_qcm'),
                ),
                const SizedBox(height: 12),

                // Pages de Prière
                _TestCard(
                  title: 'Carrousel de Prière',
                  subtitle: 'Sélection des sujets de prière',
                  onTap: () => _testPrayerCarousel(context),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Générateur de Prière',
                  subtitle: 'Génération automatique de prières',
                  onTap: () => Navigator.pushNamed(context, '/prayer/generator'),
                ),
                const SizedBox(height: 12),

                // Pages de Scan Bible
                _TestCard(
                  title: 'Scan Bible Simple',
                  subtitle: 'Scanner une page de Bible',
                  onTap: () => Navigator.pushNamed(context, '/scan/bible'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Scan Bible Avancé',
                  subtitle: 'Scanner avec animations',
                  onTap: () => Navigator.pushNamed(context, '/scan/bible/advanced'),
                ),
                const SizedBox(height: 12),

                // Pages de Plans
                _TestCard(
                  title: 'Plans Prédéfinis',
                  subtitle: 'Sélection de plans avec swipe',
                  onTap: () => Navigator.pushNamed(context, '/goals'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Plan Personnalisé',
                  subtitle: 'Créer un plan sur mesure',
                  onTap: () => Navigator.pushNamed(context, '/custom_plan'),
                ),
                const SizedBox(height: 12),

                // Pages Principales
                _TestCard(
                  title: 'Accueil',
                  subtitle: 'Page d\'accueil de l\'application',
                  onTap: () => Navigator.pushNamed(context, '/home'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Lecteur',
                  subtitle: 'Lecteur de Bible moderne',
                  onTap: () => Navigator.pushNamed(context, '/reader'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Journal',
                  subtitle: 'Journal personnel',
                  onTap: () => Navigator.pushNamed(context, '/journal'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Profil',
                  subtitle: 'Profil utilisateur',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Paramètres',
                  subtitle: 'Paramètres de l\'application',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Workflow Prière',
                  subtitle: 'Démonstration du workflow',
                  onTap: () => Navigator.pushNamed(context, '/prayer_workflow'),
                ),
                const SizedBox(height: 8),
                
                // _TestCard(
                //   title: 'Payerpage - Carousel Flip Cards',
                //   subtitle: 'Carousel de cartes de prière avec flip animation',
                //   onTap: () => Navigator.pushNamed(context, '/payerpage'),
                // ),
                const SizedBox(height: 12),

                // Pages d'Authentification
                _TestCard(
                  title: 'Connexion',
                  subtitle: 'Page de connexion',
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Bienvenue',
                  subtitle: 'Page d\'accueil initiale',
                  onTap: () => Navigator.pushNamed(context, '/welcome'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Onboarding',
                  subtitle: 'Introduction à l\'application',
                  onTap: () => Navigator.pushNamed(context, '/onboarding'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Compléter Profil',
                  subtitle: 'Finalisation du profil',
                  onTap: () => Navigator.pushNamed(context, '/complete_profile'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Succès',
                  subtitle: 'Page de confirmation',
                  onTap: () => Navigator.pushNamed(context, '/success'),
                ),
                const SizedBox(height: 12),

                // Pages Spécialisées
                _TestCard(
                  title: 'Vidéos Bible',
                  subtitle: 'Contenu vidéo biblique',
                  onTap: () => Navigator.pushNamed(context, '/bible_videos'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Analyse Passage',
                  subtitle: 'Démonstration d\'analyse',
                  onTap: () => Navigator.pushNamed(context, '/passage_analysis_demo'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Sujets Prière',
                  subtitle: 'Sélection de sujets de prière',
                  onTap: () => Navigator.pushNamed(context, '/prayer_subjects'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Sujets Prière (Bandes)',
                  subtitle: 'Interface avec bandes colorées',
                  onTap: () => Navigator.pushNamed(context, '/prayer_subjects_bands'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Paramètres Lecteur',
                  subtitle: 'Configuration du lecteur',
                  onTap: () => Navigator.pushNamed(context, '/reader_settings'),
                ),
                const SizedBox(height: 8),
                
                _TestCard(
                  title: 'Splash',
                  subtitle: 'Écran de démarrage',
                  onTap: () => Navigator.pushNamed(context, '/splash'),
                ),
                
                const SizedBox(height: 20),
                
                // Bouton de retour
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C1740),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Retour',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _testPrayerCarousel(BuildContext context) async {
    // Générer des sujets de test
    final subjects = PrayerSubjectsBuilder.fromFree(
      selectedTagsByField: {
        'aboutGod': {'praise', 'gratitude'},
        'applyToday': {'obedience'},
      },
      freeTexts: {
        'aboutGod': 'Dieu est fidèle et bon',
        'neighbor': 'Ma famille',
        'applyToday': 'Prier plus régulièrement',
        'verseHit': 'Psaume 23 - L\'Éternel est mon berger',
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrayerCarouselPage(
          subjects: subjects,
          passageRef: 'Psaume 23',
          memoryVerse: 'L\'Éternel est mon berger',
        ),
      ),
    );

    if (result != null && result is Map) {
      final completed = result['completed'] as List<String>? ?? [];
      final all = result['all'] as List<String>? ?? [];
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Carrousel de Prière'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sujets sélectionnés: ${completed.length}'),
              Text('Total sujets: ${all.length}'),
              const SizedBox(height: 8),
              Text('Sélectionnés: ${completed.join(', ')}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _TestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TestCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1740),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}