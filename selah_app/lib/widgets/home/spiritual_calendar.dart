import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../bootstrap.dart' as bootstrap;

/// 📅 Calendrier spirituel avec progression et encouragements
class SpiritualCalendar extends StatelessWidget {
  const SpiritualCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final now = DateTime.now();
    final startOfWeekSunday = now.subtract(Duration(days: (now.weekday % 7))); // dimanche
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Titre avec encouragement
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ta semaine avec Dieu',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1740),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '3/7 jours',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grille des jours
          Row(
            children: List.generate(7, (index) {
              final date = startOfWeekSunday.add(Duration(days: index));
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final isPast = date.isBefore(now) && !isToday;
              final isFuture = date.isAfter(now);
              
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.calendarRadius),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    bootstrap.telemetry.event('calendar_tap', {'date': date.toIso8601String()});
                    context.push('/pre_meditation_prayer');
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: isToday 
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : isPast
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.8),
                                const Color(0xFF34D399).withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isFuture ? Colors.white : null,
                      borderRadius: BorderRadius.circular(AppTheme.calendarRadius),
                      border: Border.all(
                        color: isToday 
                          ? Colors.transparent 
                          : isPast
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : AppTheme.neutral200,
                        width: 1.5,
                      ),
                      boxShadow: isToday ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayNames[index],
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSizeXS,
                            color: isToday 
                              ? Colors.white 
                              : isPast
                                ? Colors.white
                                : AppTheme.neutral400,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSizeM,
                            color: isToday 
                              ? Colors.white 
                              : isPast
                                ? Colors.white
                                : AppTheme.neutral900,
                            fontWeight: AppTheme.fontWeightSemiBold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isToday 
                            ? Icons.radio_button_checked
                            : isPast
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 12,
                          color: isToday 
                            ? Colors.white 
                            : isPast
                              ? Colors.white
                              : AppTheme.neutral400,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 12),
          
          // Message d'encouragement
          Text(
            _getEncouragementMessage(now),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF6B7280),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  String _getEncouragementMessage(DateTime now) {
    final hour = now.hour;
    if (hour < 6) {
      return 'L\'aurore de ta journée avec Dieu commence...';
    } else if (hour < 12) {
      return 'Bonne matinée ! Que Dieu bénisse tes pas.';
    } else if (hour < 18) {
      return 'L\'après-midi est un moment parfait pour méditer.';
    } else {
      return 'Finis ta journée en paix avec le Seigneur.';
    }
  }
}
