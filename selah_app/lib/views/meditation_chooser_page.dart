import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_tokens.dart';
import '../widgets/uniform_back_button.dart';
import '../widgets/calm_ui_components.dart';
import '../widgets/option_tile.dart';
import '../models/passage_payload.dart';
import 'meditation_free_v2_page.dart';
import 'meditation_qcm_page.dart';

class MeditationChooserPage extends StatelessWidget {
  const MeditationChooserPage({super.key});

  // Fonction utilitaire pour récupérer les arguments GoRouter
  Map _readArgs(BuildContext context) {
    final goExtra = (GoRouterState.of(context).extra as Map?) ?? {};
    final modal = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    return {...modal, ...goExtra}; // go_router prioritaire
  }

  @override
  Widget build(BuildContext context) {
    final args = _readArgs(context);
    final passagePayload = PassagePayload.fromMap(Map<String, dynamic>.from(args));
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1740),
              Color(0xFF2D1B69),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec navigation
              _buildHeader(context),
              
              // Titre principal
              _buildTitleSection(),
              
              // Options de méditation
              Expanded(
                child: _buildOptionsSection(context, passagePayload),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Méditation',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48), // Pour centrer le titre
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisis ta méthode',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Trois approches pour méditer ce passage.',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context, PassagePayload passagePayload) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          _buildOptionCard(
            context: context,
            title: 'Méditation libre',
            subtitle: 'Réflexion personnelle en 3 étapes',
            icon: Icons.self_improvement_rounded,
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/meditation/free', extra: {
                'passageRef': passagePayload.ref.isNotEmpty ? passagePayload.ref : null,
                'passageText': passagePayload.text.isNotEmpty ? passagePayload.text : null,
              });
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            title: 'Méditation guidée',
            subtitle: 'Questions structurées pour approfondir',
            icon: Icons.quiz_rounded,
            gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/meditation/qcm', extra: {
                'passageRef': passagePayload.ref,
                'passageText': passagePayload.text,
              });
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            title: 'Méditation intelligente',
            subtitle: 'Questions générées automatiquement',
            icon: Icons.auto_awesome_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/meditation/auto_qcm', extra: passagePayload.toMap());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: AppTokens.backgroundGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.gap24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quelle méthode choisir ?',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTokens.gap16),
                _buildHelpItem(
                  'Méditation libre',
                  'Écris tes pensées librement. Parfait pour une réflexion personnelle.',
                ),
                const SizedBox(height: AppTokens.gap12),
                _buildHelpItem(
                  'Méditation guidée',
                  'Réponds à des questions structurées pour approfondir ta compréhension.',
                ),
                const SizedBox(height: AppTokens.gap12),
                _buildHelpItem(
                  'Méditation intelligente',
                  'Le système génère des questions adaptées au passage biblique.',
                ),
                const SizedBox(height: AppTokens.gap24),
                CalmButton(
                  text: 'Compris',
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppTokens.indigo,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.gap12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}