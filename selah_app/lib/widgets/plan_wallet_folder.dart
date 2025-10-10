import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanWalletFolder extends StatelessWidget {
  final Widget card;
  final String planTitle;
  final String planSubtitle;
  final int progress;
  final int totalDays;

  const PlanWalletFolder({
    super.key,
    required this.card,
    required this.planTitle,
    required this.planSubtitle,
    required this.progress,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const MainContainer(),
        Positioned(
          top: 90,
          left: 40,
          right: 40,
          child: Hero(
            tag: 'plan_wallet_card',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: card,
            ),
          ),
        ),
        // Informations du plan sur le dossier
        Positioned(
          bottom: 60,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Text(
                planTitle,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                planSubtitle,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Barre de progression
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress / totalDays,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1553FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MainContainer extends StatelessWidget {
  const MainContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: FolderShapePainter(),
        child: Stack(
          children: [
            // Avatar en haut à droite
            const Positioned(
              top: 20,
              right: 20,
              child: AvatarGhost(),
            ),
            // Titre du dossier
            const Positioned(
              top: 20,
              left: 20,
              child: Text(
                'Mon Plan',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            // Icône de crâne en bas à gauche
            const Positioned(
              bottom: 20,
              left: 20,
              child: SkullIcon(),
            ),
            // Groupe de documents en bas à droite
            const Positioned(
              bottom: 20,
              right: 20,
              child: DocumentGroup(),
            ),
          ],
        ),
      ),
    );
  }
}

class CardContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const CardContainer({
    super.key,
    required this.child,
    this.width = 240,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class DocumentGroup extends StatelessWidget {
  const DocumentGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDocument(const Color(0xFF4A90E2), 0),
        const SizedBox(width: 4),
        _buildDocument(const Color(0xFF7ED321), 1),
        const SizedBox(width: 4),
        _buildDocument(const Color(0xFFF5A623), 2),
      ],
    );
  }

  Widget _buildDocument(Color color, int index) {
    return Container(
      width: 12,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class AvatarGhost extends StatelessWidget {
  const AvatarGhost({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF7ED321)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class SkullIcon extends StatelessWidget {
  const SkullIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: SkullIconPainter(),
    );
  }
}

class FolderShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(20, 0)
      ..lineTo(size.width - 20, 0)
      ..lineTo(size.width - 10, 20)
      ..lineTo(size.width, 20)
      ..lineTo(size.width, size.height - 20)
      ..lineTo(size.width - 20, size.height)
      ..lineTo(20, size.height)
      ..lineTo(0, size.height - 20)
      ..lineTo(0, 20)
      ..close();

    canvas.drawPath(path, paint);

    // Bordure brillante
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, borderPaint);

    // Effet de brillance
    final shinePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Colors.white, Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        stops: [0.0, 0.3],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final shinePath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6, 0)
      ..lineTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(0, size.height * 0.2)
      ..close();

    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SkullIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Tête du crâne
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.8,
        height: size.height * 0.8,
      ),
      paint,
    );

    // Orbites
    final eyePaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.4),
        width: size.width * 0.15,
        height: size.height * 0.15,
      ),
      eyePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.4),
        width: size.width * 0.15,
        height: size.height * 0.15,
      ),
      eyePaint,
    );

    // Nez
    final nosePaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    final nosePath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.6)
      ..lineTo(size.width * 0.55, size.height * 0.6)
      ..close();

    canvas.drawPath(nosePath, nosePaint);

    // Bouche
    final mouthPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final mouthPath = Path()
      ..moveTo(size.width * 0.4, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        size.width * 0.6,
        size.height * 0.7,
      );

    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
