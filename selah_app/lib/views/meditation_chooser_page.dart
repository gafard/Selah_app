import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/passage_payload.dart';

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
                                  _buildHeader(context, passagePayload),
                                  const SizedBox(height: 20),
                                  
                                  // Titre principal
                                  _buildTitleSection(),
                                  const SizedBox(height: 32),
                                  
                                  // Informations sur le passage
                                  _buildPassageInfo(passagePayload),
                                  const SizedBox(height: 20),
                                  
                                  // Conseils de méditation
                                  _buildMeditationTips(),
                                  const SizedBox(height: 32),
                                  
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

  Widget _buildHeader(BuildContext context, PassagePayload passagePayload) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Si pas de page précédente, naviguer vers reader avec les paramètres du passage
              // Récupérer les paramètres depuis GoRouterState
              final goRouterState = GoRouterState.of(context);
              final extra = goRouterState.extra as Map<String, dynamic>?;
              
              if (extra != null && extra['passageRef'] != null) {
                context.go('/reader', extra: {
                  'passageRef': extra['passageRef'],
                  'passageText': extra['passageText'],
                  'dayTitle': extra['dayTitle'],
                  'planId': extra['planId'],
                  'dayNumber': extra['dayNumber'],
                });
              } else {
                context.go('/reader');
              }
            }
          },
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
          'Deux approches pour méditer ce passage',
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
          icon: Icons.book_rounded,
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

  Widget _buildPassageInfo(PassagePayload passagePayload) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Passage du jour',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            passagePayload.ref.isNotEmpty ? passagePayload.ref : 'Aucun passage sélectionné',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            passagePayload.dayTitle ?? 'Jour de lecture',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationTips() {
    final tips = [
      {'icon': Icons.menu_book_rounded, 'text': 'Aie ta Bible à portée de main pour relire le passage'},
      {'icon': Icons.lightbulb_outline_rounded, 'text': 'Laisse le Saint-Esprit éclairer ta compréhension'},
      {'icon': Icons.favorite_outline_rounded, 'text': 'Applique le passage à ta vie quotidienne'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                color: Colors.amber.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Conseils pour méditer',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  tip['icon'] as IconData,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip['text'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
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