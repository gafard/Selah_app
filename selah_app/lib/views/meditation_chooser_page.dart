import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_tokens.dart';
import '../widgets/uniform_back_button.dart';
import '../widgets/calm_ui_components.dart';
import '../widgets/option_tile.dart';
import '../models/passage_payload.dart';
import 'meditation_free_page.dart';
import 'meditation_qcm_page.dart';

class MeditationChooserPage extends StatelessWidget {
  const MeditationChooserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final passagePayload = PassagePayload.fromMap(Map<String, dynamic>.from(args));
    
    return Scaffold(
      body: Column(
        children: [
          // Header avec navigation
          UniformHeader(
            title: 'Méditation',
            onBackPressed: () => context.pop(),
            textColor: Colors.white,
            iconColor: Colors.black,
            titleAlignment: CrossAxisAlignment.center,
          ),
          
          // Titre principal
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTokens.gap20, AppTokens.gap24, AppTokens.gap20, AppTokens.gap8),
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
                const SizedBox(height: AppTokens.gap12),
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
          ),
          
          // Options de méditation
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.gap20, AppTokens.gap32, AppTokens.gap20, AppTokens.gap20),
              child: Column(
                children: [
                  OptionTile(
                    title: 'Méditation libre',
                    subtitle: 'Réflexion personnelle et spontanée',
                    icon: Icons.self_improvement_rounded,
                    gradient: const [AppTokens.indigo, Color(0xFF8B5CF6)],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go('/meditation/free', extra: {
                        'passageRef': passagePayload.ref.isNotEmpty ? passagePayload.ref : null,
                        'passageText': passagePayload.text.isNotEmpty ? passagePayload.text : null,
                      });
                    },
                  ),
                  const SizedBox(height: AppTokens.gap16),
                  OptionTile(
                    title: 'Méditation guidée',
                    subtitle: 'Questions structurées pour approfondir',
                    icon: Icons.quiz_rounded,
                    gradient: const [AppTokens.teal, Color(0xFF3B82F6)],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go('/meditation/qcm', extra: {
                        'passageRef': passagePayload.ref,
                        'passageText': passagePayload.text,
                      });
                    },
                  ),
                  const SizedBox(height: AppTokens.gap16),
                  OptionTile(
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
            ),
          ),
        ],
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