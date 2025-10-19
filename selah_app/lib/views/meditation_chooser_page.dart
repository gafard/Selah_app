import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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
            colors: [Color(0xFF1A1D29), Color(0xFF112244)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Stack(
                    children: [
                      // Ornements légers en arrière-plan
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

                      // Contenu principal
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  // Header
                                  _buildHeader(context),
                                  const SizedBox(height: 20),
                                  
                                  // Titre principal
                                  _buildTitleSection(),
                                  const SizedBox(height: 24),
                                  
                                  // Options de méditation
                                  _buildOptionsSection(context, passagePayload),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHOISIS TA MÉTHODE',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Trois approches pour méditer ce passage',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context, PassagePayload passagePayload) {
    return Column(
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
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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