import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/spiritual_foundation.dart';
import '../../services/spiritual_foundations_service.dart';
import '../../services/foundations_progress_service.dart';

/// Widget affichant le bilan des fondations de la semaine
class FoundationsSummaryCard extends StatelessWidget {
  final List<FoundationPractice> weekPractices;
  final VoidCallback? onTap;

  const FoundationsSummaryCard({
    super.key,
    required this.weekPractices,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final practiced = weekPractices.where((p) => p.practiced).length;
    final total = weekPractices.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B7355), Color(0xFFD2B48C)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tes fondations de la semaine',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$practiced/$total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Barre de progression
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total > 0 ? practiced / total : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Liste des fondations avec checkmarks
            ...weekPractices.map((practice) => _buildFoundationRow(context, practice)),
            
            const SizedBox(height: 20),
            
            // Message d'encouragement
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getEncouragementMessage(practiced, total),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundationRow(BuildContext context, FoundationPractice practice) {
    return FutureBuilder<SpiritualFoundation?>(
      future: SpiritualFoundationsService.getFoundationById(practice.foundationId),
      builder: (context, snapshot) {
        final foundation = snapshot.data;
        if (foundation == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                practice.practiced ? Icons.check_circle : Icons.cancel,
                color: practice.practiced ? Colors.green[300] : Colors.red[300],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  foundation.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    decoration: practice.practiced ? null : TextDecoration.lineThrough,
                    fontWeight: practice.practiced ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (practice.note != null && practice.note!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.note_alt_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getEncouragementMessage(int practiced, int total) {
    if (total == 0) {
      return 'Commence ton parcours spirituel cette semaine !';
    }
    
    final percentage = (practiced / total * 100).round();
    
    if (percentage == 100) {
      return 'Incroyable ! Tu as pratiqué toutes les fondations cette semaine ! 🎉';
    } else if (percentage >= 70) {
      return 'Tu avances bien ! Continue à bâtir sur le roc 💪 ($practiced/$total pratiquées).';
    } else if (percentage >= 40) {
      return 'Continue l\'effort ! Chaque jour est une nouvelle opportunité ($practiced/$total).';
    } else {
      return 'Ne te décourage pas ! Dieu est avec toi dans ton parcours ($practiced/$total).';
    }
  }
}

/// Widget compact pour afficher un résumé rapide des fondations
class FoundationsSummaryCompact extends StatelessWidget {
  final int practicedCount;
  final int totalCount;
  final VoidCallback? onTap;

  const FoundationsSummaryCompact({
    super.key,
    required this.practicedCount,
    required this.totalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B7355).withOpacity(0.8),
              const Color(0xFFD2B48C).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Fondations: $practicedCount/$totalCount',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: totalCount > 0 ? practicedCount / totalCount : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
