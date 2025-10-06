import 'package:flutter/material.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _page = PageController();

  void _next() {
    if (_page.page == null) return;
    if (_page.page! >= 2) return; // dernier
    _page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D29), // Fond sombre comme Superlist
        ),
        child: Stack(
          children: [
            // Formes décoratives en arrière-plan
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundShapesPainter(),
              ),
            ),
            // PageView principal
            PageView(
              controller: _page,
              physics: const BouncingScrollPhysics(),
                    children: [
        // Slide 1 (wedge en haut à droite)
        OnboardingSlide(
          topDecoration: const TopRightWedge(),
          heroImage: const AssetImage('assets/images/onboarding_bible.png'),
          title: "Choisis ton plan et engage-toi.",
          subtitle: "Commence aujourd'hui et avance pas à pas.",
          onNext: _next,
        ),
        // Slide 2 (arche en bas)
        OnboardingSlide(
          bottomDecoration: const BottomArch(),
          heroImage: const AssetImage('assets/images/onboarding_tree.png'),
          title: "Marchons ensemble dans la Parole.",
          subtitle: "Partage, médite et prie avec la communauté.",
          onNext: _next,
        ),
        // Slide 3 (autre wedge)
        OnboardingSlide(
          topDecoration: const TopRightWedge(),
          heroImage: const AssetImage('assets/images/onboarding_path.png'),
          title: "Ta parole est une lampe à mes pieds.",
          subtitle: "Chaque jour, laisse la Parole éclairer ta route.",
          onNext: () {
            // Naviguer vers la home page
            Navigator.pushNamed(context, '/selah_home');
          },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// —— Données des 3 slides ————————————————————————————————————————————————
class SlideData {
  final String imageAsset;
  final String title;
  final String subtitle;
  final AccentStyle accent;

  const SlideData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

enum AccentStyle { topLeftDiagonal, bottomOvoid, topRightDiagonal }

const kPeach = Color(0xFFFFA870); // orange pêche
const kInk = Color(0xFF14181B);   // noir encre
const kAqua = Color(0xFF43D3C0);  // aqua halo

/// —— Un slide individuel fidèle au style demandé ————————————————
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.heroImage,
    required this.title,
    required this.subtitle,
    this.topDecoration,
    this.bottomDecoration,
    this.onNext,
  });

  final Widget? topDecoration;
  final Widget? bottomDecoration;
  final ImageProvider heroImage;
  final String title;
  final String subtitle;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      color: Colors.transparent, // Transparent pour laisser voir le fond parent
      child: SafeArea(
        child: Stack(
          children: [
            // Décors
            if (topDecoration != null) Positioned.fill(child: topDecoration!),
            if (bottomDecoration != null) Positioned.fill(child: bottomDecoration!),

            // Contenu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: size.height * .07),
                  // Illustration
                  SizedBox(
                    height: size.height * .32,
                    child: Center(
                      child: Image(
                        image: heroImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * .04),
                  // Titre
                      Text(
                    title,
                        textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // Blanc pour le fond sombre
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sous-titre
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white70, // Blanc avec transparence pour le fond sombre
                    ),
                  ),
                  const Spacer(),
                  // Bouton
                  GradientRingButton(
                    onPressed: onNext,
                    diameter: 88,
                    ringWidth: 10,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// —— Bouton rond avec halo dégradé (aqua → pêche) ————————————————
class GradientRingButton extends StatelessWidget {
  const GradientRingButton({
    super.key,
    this.onPressed,
    this.diameter = 88,
    this.ringWidth = 10,
  });

  final VoidCallback? onPressed;
  final double diameter;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final outer = diameter;
    final inner = outer - (ringWidth * 2);

    return SizedBox(
      width: outer,
      height: outer,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anneau dégradé
            Container(
              width: outer,
              height: outer,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFFFFA36C), // orange clair
                    Color(0xFF2FC7AF), // vert d'eau
                    Color(0xFFFFA36C),
                  ],
                ),
              ),
            ),
            // Cercle vide (pour créer l'anneau)
            Container(
              width: inner,
              height: inner,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onPressed,
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// —— Composant TopRightWedge avec courbes arrondies ————————————————
class TopRightWedge extends StatelessWidget {
  const TopRightWedge({super.key, this.color = const Color(0xFFFFA36C)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TopRightWedgePainter(color),
      size: Size.infinite,
    );
  }
}

class _TopRightWedgePainter extends CustomPainter {
  _TopRightWedgePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // On reproduit la grande forme triangulaire avec angles très arrondis
    final path = Path()
      ..moveTo(w * .55, 0)
      ..quadraticBezierTo(w * .88, 0, w, h * .10)
      ..lineTo(w, h * .65)
      ..quadraticBezierTo(w * .92, h * .48, w * .70, h * .26)
      ..quadraticBezierTo(w * .62, h * .18, w * .55, 0)
      ..close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// —— Composant BottomArch avec ovale centré ————————————————
class BottomArch extends StatelessWidget {
  const BottomArch({super.key, this.color = const Color(0xFFFFA36C)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BottomArchPainter(color),
      size: Size.infinite,
    );
  }
}

class _BottomArchPainter extends CustomPainter {
  _BottomArchPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromCenter(
      center: Offset(w / 2, h * .92),
      width: w * .72,
      height: h * .55,
    );
    final paint = Paint()..color = color;
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// —— Peintre des formes d'aplat (fidèle aux exemples) ————————————————
class _AccentPainter extends CustomPainter {
  final AccentStyle style;
  _AccentPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kPeach;

    switch (style) {
      case AccentStyle.topLeftDiagonal:
        // triangle/diagonale en haut-gauche (~40% de la partie supérieure)
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.width * 0.55, 0)
          ..lineTo(0, size.height * 0.45)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AccentStyle.bottomOvoid:
        // Utilise le nouveau BottomArch avec ovale centré
        final archPainter = _BottomArchPainter(kPeach);
        archPainter.paint(canvas, size);
        break;

      case AccentStyle.topRightDiagonal:
        // Utilise le nouveau TopRightWedge avec courbes arrondies
        final wedgePainter = _TopRightWedgePainter(kPeach);
        wedgePainter.paint(canvas, size);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AccentPainter oldDelegate) =>
      oldDelegate.style != style;
}

class BackgroundShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
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
      ..color = Colors.white.withOpacity(0.06)
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