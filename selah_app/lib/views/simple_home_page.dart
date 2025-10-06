import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/selah_logo.dart';

class SimpleHomePage extends StatelessWidget {
  const SimpleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: SelahGradients.primary,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec nouveau logo Selah
                _buildHeader(),
                const SizedBox(height: 32),
                
                // Section de navigation
                _buildNavigationSection(context),
                const SizedBox(height: 32),
                
                // Section des fonctionnalités
                _buildFeaturesSection(context),
                const SizedBox(height: 32),
                
                // Section des plans
                _buildPlansSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo Selah avec nouvelle identité
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SelahColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SelahLogo.round(size: 80),
        ),
        const SizedBox(height: 16),
        Text(
          'Selah',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Un temps pour s\'arrêter et méditer',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildNavButton(
          context,
          title: 'Test de Navigation',
          subtitle: 'Page de test centralisée',
          route: '/test',
          icon: Icons.navigation,
          color: SelahColors.sage, // Couleur sauge
        ),
        _buildNavButton(
          context,
          title: 'Configuration du Profil',
          subtitle: 'Personnaliser votre expérience',
          route: '/complete-profile',
          icon: Icons.person_add,
          color: SelahColors.primary,
        ),
        _buildNavButton(
          context,
          title: 'Choisir un Plan',
          subtitle: 'Sélectionner votre plan de lecture',
          route: '/choose-plan',
          icon: Icons.library_books,
          color: SelahColors.marine, // Couleur marine
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildNavButton(
          context,
          title: 'Générateur de Plan',
          subtitle: 'Créer un plan personnalisé',
          route: '/custom_plan_generator',
          icon: Icons.auto_awesome,
          color: const Color(0xFF49C98D),
        ),
        _buildNavButton(
          context,
          title: 'Importation de Plan',
          subtitle: 'Importer depuis un fichier ICS',
          route: '/import_plan',
          icon: Icons.upload_file,
          color: SelahColors.primary,
        ),
      ],
    );
  }

  Widget _buildPlansSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plans de Lecture',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildNavButton(
          context,
          title: 'Objectifs',
          subtitle: 'Gérer vos plans de lecture',
          route: '/goals',
          icon: Icons.flag,
          color: SelahColors.marine,
        ),
      ],
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String route,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
