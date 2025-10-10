import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../bootstrap.dart' as bootstrap;

/// 📊 Carte de progression spirituelle avec empty state
class SpiritualProgress extends StatelessWidget {
  final int tasksDone;
  final int tasksTotal;
  
  const SpiritualProgress({
    super.key,
    required this.tasksDone,
    required this.tasksTotal,
  });

  @override
  Widget build(BuildContext context) {
    final safeRatio = (tasksTotal <= 0) ? 0.0 : (tasksDone / tasksTotal).clamp(0.0, 1.0);
    
    // Empty state si pas d'objectifs
    if (tasksTotal == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.track_changes,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Configure ton plan pour lancer la journée',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choisis un plan de lecture qui te correspond',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                bootstrap.telemetry.event('empty_state_cta_clicked');
                context.push('/goals');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF10B981),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
              ),
              child: Text(
                'Choisir un plan',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1C1740),
            const Color(0xFF2D1B69),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1740).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ta progression spirituelle',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$tasksDone/$tasksTotal objectifs accomplis',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMotivationalMessage(safeRatio),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Cercle de progression
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: safeRatio,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                Center(
                  child: Text(
                    '${(safeRatio * 100).round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMotivationalMessage(double ratio) {
    if (ratio == 0.0) {
      return 'Commence ton voyage avec Dieu';
    } else if (ratio < 0.3) {
      return 'Chaque pas compte dans ta foi';
    } else if (ratio < 0.6) {
      return 'Tu avances bien, continue !';
    } else if (ratio < 0.9) {
      return 'Presque au bout, tiens bon !';
    } else if (ratio < 1.0) {
      return 'Dernière ligne droite !';
    } else {
      return 'Excellent ! Dieu est fier de toi';
    }
  }
}
