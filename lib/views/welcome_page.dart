import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/selah_logo.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29), // Fond sombre bleu-gris exactement comme Superlist
      body: SafeArea(
        child: Stack(
          children: [
            // Formes décoratives en arrière-plan - exactement comme Superlist
            _buildBackgroundShapes(),
            
            // Contenu principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Icône de l'app - exactement comme Superlist
                  _buildAppIcon(),
                  
                  const SizedBox(height: 40),
                  
                  // Titre de bienvenue - exactement comme Superlist
                  _buildWelcomeTitle(),
                  
                  const SizedBox(height: 16),
                  
                  // Sous-titre - exactement comme Superlist
                  _buildSubtitle(),
                  
                  const Spacer(),
                  
                  // Boutons d'authentification - exactement comme Superlist
                  _buildAuthButtons(context),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundShapesPainter(),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF1553FF), // Bleu Selah
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1553FF).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Center(
        child: SelahAppIcon(
          size: 80,
          useBlueBackground: false, // Pas de fond car on a déjà le container
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 800.ms, delay: 200.ms)
    .scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.0, 1.0),
      duration: 600.ms,
      delay: 400.ms,
      curve: Curves.elasticOut,
    )
    .shimmer(
      duration: 2000.ms,
      delay: 1000.ms,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildWelcomeTitle() {
    return Column(
      children: [
        Text(
          'Bienvenue dans',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 800.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 800.ms),
        
        Text(
          'Selah',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 1000.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 1000.ms)
        .shimmer(
          duration: 1500.ms,
          delay: 1500.ms,
          color: const Color(0xFF49C98D).withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Ta parole est une lampe à mes pieds.\nChaque jour, laisse la Parole éclairer ta route.',
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white.withOpacity(0.8),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    )
    .animate()
    .fadeIn(duration: 800.ms, delay: 1200.ms)
    .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 1200.ms);
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton Google - design exactement comme Superlist
        _buildAuthButton(
          context: context,
          icon: Icons.g_mobiledata,
          label: 'Continuer avec Google',
          backgroundColor: Colors.white,
          textColor: Colors.black,
          onTap: () {
            // TODO: Implémenter l'authentification Google
            _showComingSoon(context, 'Google');
          },
        ),
        
        const SizedBox(height: 16),
        
        // Bouton Apple - design exactement comme Superlist
        _buildAuthButton(
          context: context,
          icon: Icons.apple,
          label: 'Se connecter avec Apple',
          backgroundColor: Colors.white,
          textColor: Colors.black,
          onTap: () {
            // TODO: Implémenter l'authentification Apple
            _showComingSoon(context, 'Apple');
          },
        ),
        
        const SizedBox(height: 16),
        
        // Bouton Email - design exactement comme Superlist
        _buildAuthButton(
          context: context,
          icon: Icons.email_outlined,
          label: 'Continuer avec l\'email',
          backgroundColor: const Color(0xFF2A2D3A),
          textColor: Colors.white,
          onTap: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
        
      ],
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: backgroundColor == Colors.white 
                ? Colors.grey.withOpacity(0.2)
                : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: textColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Authentification $service bientôt disponible',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6B46C1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class BackgroundShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08) // Plus visible
      ..style = PaintingStyle.fill;

    // Formes géométriques dispersées
    final shapes = [
      // Cercle en bas à gauche
      Offset(size.width * 0.1, size.height * 0.8),
      // Cercle en haut à droite
      Offset(size.width * 0.85, size.height * 0.15),
      // Cercle au centre
      Offset(size.width * 0.7, size.height * 0.6),
      // Cercle en bas à droite
      Offset(size.width * 0.9, size.height * 0.9),
      // Cercle supplémentaire en haut à gauche
      Offset(size.width * 0.15, size.height * 0.25),
      // Cercle supplémentaire au centre gauche
      Offset(size.width * 0.2, size.height * 0.6),
    ];

    for (final shape in shapes) {
      canvas.drawCircle(shape, 30, paint);
    }

    // Lignes décoratives
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.06) // Plus visible
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Ligne diagonale
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      linePaint,
    );

    // Ligne horizontale
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.4),
      linePaint,
    );

    // Ligne verticale supplémentaire
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.8),
      linePaint,
    );

    // Formes supplémentaires
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Croix en haut à droite
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.3),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.2),
      Offset(size.width * 0.75, size.height * 0.3),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}