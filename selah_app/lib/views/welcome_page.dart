import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../widgets/selah_logo.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      // Fond avec dégradé subtil bleu-vert
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1D29),
              Color(0xFF112244),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Formes décoratives en arrière-plan avec RepaintBoundary
              const RepaintBoundary(
                child: CustomPaint(
                  painter: BackgroundShapesPainter(),
                ),
              ),
              
              // Contenu principal avec support du TextScaleFactor
              MediaQuery.withNoTextScaling(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      
                      // Icône de l'app avec accessibilité
                      _buildAppIcon(),
                      
                      const SizedBox(height: 40),
                      
                      // Titre de bienvenue avec accessibilité
                      _buildWelcomeTitle(),
                      
                      const SizedBox(height: 16),
                      
                      // Sous-titre avec accessibilité
                      _buildSubtitle(),
                      
                      const Spacer(),
                      
                      // Boutons d'authentification
                      _buildAuthButtons(context),
                      
                      const SizedBox(height: 16),
                      
                      // Mentions légales
                      _buildLegalText(context),
                      
                      const SizedBox(height: 40),
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


  Widget _buildAppIcon() {
    return Semantics(
      label: 'Logo Selah - Application de méditation chrétienne',
      child: Container(
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
          child: SelahAppIcon(size: 80),
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
    return Semantics(
      label: 'Bienvenue dans Selah - Application de méditation',
      child: Column(
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
              letterSpacing: 0.5, // Tracking premium
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
      ),
    );
  }

  Widget _buildSubtitle() {
    return Semantics(
      label: 'Ta parole est une lampe à mes pieds. Chaque jour, laisse la Parole éclairer ta route.',
      child: Text(
        'Ta parole est une lampe à mes pieds.\nChaque jour, laisse la Parole éclairer ta route.',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.8),
          height: 1.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    )
    .animate()
    .fadeIn(duration: 800.ms, delay: 1200.ms)
    .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 1200.ms);
  }

  Widget _buildAuthButtons(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    return Column(
      children: [
        // Boutons selon la plateforme
        if (isIOS) ...[
          // Bouton Apple sur iOS
          _buildAuthButton(
            context: context,
            icon: Icons.apple,
            label: 'Se connecter avec Apple',
            backgroundColor: Colors.white,
            textColor: Colors.black,
            onTap: () => _handleAuthTap(() => _showComingSoon(context, 'Apple')),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Bouton Google sur Android/Web
          _buildAuthButton(
            context: context,
            icon: Icons.g_mobiledata,
            label: 'Continuer avec Google',
            backgroundColor: Colors.white,
            textColor: Colors.black,
            onTap: () => _handleAuthTap(() => _showComingSoon(context, 'Google')),
          ),
          const SizedBox(height: 16),
        ],
        
        // Bouton Email avec outline gradient
        _buildEmailButton(context),
        
        const SizedBox(height: 16),
        
        // Lien "Créer un compte par email"
        _buildSignUpLink(context),
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
    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
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
      ),
    );
  }

  Widget _buildEmailButton(BuildContext context) {
    return Semantics(
      label: 'Continuer avec l\'email',
      button: true,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1553FF).withOpacity(0.3),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2A2D3A),
              const Color(0xFF2A2D3A).withOpacity(0.8),
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: () => _handleAuthTap(() => Navigator.pushNamed(context, '/auth', arguments: {'mode': 'login'})),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'Continuer avec l\'email',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Semantics(
      label: 'Créer un compte par email',
      button: true,
      child: InkWell(
        onTap: () => _handleAuthTap(() => Navigator.pushNamed(context, '/auth', arguments: {'mode': 'signup'})),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            'Créer un compte par email',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text.rich(
        TextSpan(
          text: 'En continuant, vous acceptez nos ',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 12,
          ),
          children: [
            WidgetSpan(
              child: InkWell(
                onTap: () => _showComingSoon(context, 'CGU'),
                child: Text(
                  'Conditions',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' et notre '),
            WidgetSpan(
              child: InkWell(
                onTap: () => _showComingSoon(context, 'Confidentialité'),
                child: Text(
                  'Politique de confidentialité',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _handleAuthTap(VoidCallback action) async {
    if (_busy) return;
    setState(() => _busy = true);
    
    try {
      HapticFeedback.lightImpact();
      action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showComingSoon(BuildContext context, String service) {
    String message;
    switch (service) {
      case 'Google':
        message = 'Google bientôt dispo — essayez l\'email en attendant';
        break;
      case 'Apple':
        message = 'Apple bientôt dispo — essayez l\'email en attendant';
        break;
      case 'CGU':
        message = 'Conditions d\'utilisation bientôt disponibles';
        break;
      case 'Confidentialité':
        message = 'Politique de confidentialité bientôt disponible';
        break;
      default:
        message = '$service bientôt disponible';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
  const BackgroundShapesPainter();
  
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