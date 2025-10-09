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
  bool _isNavigating = false;

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
              
              // Contenu principal avec support du TextScaleFactor et scroll
              MediaQuery.withNoTextScaling(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          
                          // Icône de l'app avec accessibilité
                          _buildAppIcon(),
                          
                          const SizedBox(height: 40),
                          
                          // Titre de bienvenue avec accessibilité
                          _buildWelcomeTitle(),
                          
                          const SizedBox(height: 32),
                          
                          // Sous-titre avec accessibilité
                          _buildSubtitle(),
                          
                          const SizedBox(height: 60),
                          
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
      child: SelahLogo.round(size: 120) // ✅ Logo direct sans box
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
          
          // ✅ Texte Selah en Gilroy Black (comme logo original)
          Text(
            'Selah',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 32,
              fontWeight: FontWeight.w900, // ✅ Black
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
      label: 'À l\'Éternel la terre et ce qu\'elle renferme, le monde et ceux qui l\'habitent.',
      child: Column(
        children: [
          Text(
            '"À l\'Éternel la terre et ce qu\'elle renferme,\nle monde et ceux qui l\'habitent."',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.9),
              height: 1.3,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Psaume 24:10',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 800.ms, delay: 1200.ms)
    .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 1200.ms);
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton principal "Se connecter"
        _buildLoginButton(context),
        
        const SizedBox(height: 16),
        
        // Lien "Créer un compte"
        _buildSignUpLink(context),
      ],
    );
  }


  Widget _buildLoginButton(BuildContext context) {
    return Semantics(
      label: 'Se connecter',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF1553FF), Color(0xFF0D47A1)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1553FF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isNavigating ? null : () => _handleAuthTap(() => context.go('/auth', extra: {'mode': 'login'})),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Se connecter',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      )
      .animate()
      .fadeIn(duration: 600.ms, delay: 1400.ms)
      .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 1400.ms),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Semantics(
      label: 'Créer un compte',
      button: true,
      child: TextButton(
        onPressed: _isNavigating ? null : () => _handleAuthTap(() => context.go('/auth', extra: {'mode': 'signup'})),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pas encore de compte ? ',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            Text(
              'Créer un compte',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF49C98D),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      )
      .animate()
      .fadeIn(duration: 600.ms, delay: 1600.ms)
      .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 1600.ms),
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
    if (_busy || _isNavigating) return;
    setState(() {
      _busy = true;
      _isNavigating = true;
    });
    
    try {
      HapticFeedback.lightImpact();
      // Délai pour permettre à l'animation de se terminer avant la navigation
      await Future.delayed(const Duration(milliseconds: 150));
      action();
    } finally {
      // Ne pas remettre _busy à false car on navigue
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showComingSoon(BuildContext context, String service) {
    String message;
    switch (service) {
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