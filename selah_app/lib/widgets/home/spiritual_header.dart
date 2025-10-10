import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/selah_logo.dart';

/// 🌿 Header spirituel avec message d'accueil personnalisé
class SpiritualHeader extends StatelessWidget {
  final String displayName;
  final String? dailyMessage;
  
  const SpiritualHeader({
    super.key,
    required this.displayName,
    this.dailyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Message d'accueil spirituel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salutation principale
                Text(
                  'Shalom, $displayName',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1740),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Message spirituel quotidien
                Text(
                  dailyMessage ?? 'Dieu t\'attend dans la Parole 🌿',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
                
                // Micro-texte informatif
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Aujourd\'hui, 3 lectures prévues • 15 min',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Logo Selah avec effet glass
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const SelahAppIcon(size: 40),
          ),
        ],
      ),
    );
  }
}
