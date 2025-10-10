import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../bootstrap.dart' as bootstrap;

class CongratsDisciplinePage extends StatefulWidget {
  const CongratsDisciplinePage({super.key});
  @override
  State<CongratsDisciplinePage> createState() => _CongratsDisciplinePageState();
}

class _CongratsDisciplinePageState extends State<CongratsDisciplinePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Ping analytique non bloquant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bootstrap.telemetry.event('congrats_viewed', {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1025), Color(0xFF1C1740), Color(0xFF2D1B69)],
            stops: [0, .55, 1],
          ),
        ),
        child: Stack(
        children: [
            // Éléments abstraits animés en arrière-plan
            _FloatingElements(controller: _c),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Column(
                children: [
                  const Spacer(),
                // Carte avec effet Glassmorphism (cohérent avec l'onboarding)
                  Center(
                    child: ScaleTransition(
                      scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      // Effet Glassmorphism cohérent avec l'onboarding
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.08),
                          const Color(0xFF8B5CF6).withOpacity(0.05),
                          Colors.white.withOpacity(0.03),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.0,
                      ),
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 25,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.04),
                                Colors.white.withOpacity(0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                              // Badge + icône (style cohérent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                  color: const Color(0xFF49C98D).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFF49C98D).withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                    Icon(Icons.emoji_events, size: 16, color: Color(0xFF49C98D)),
                                SizedBox(width: 6),
                                Text('Félicitations',
                                    style: TextStyle(
                                          fontFamily: 'Gilroy',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                          color: Color(0xFF49C98D),
                                    )),
                              ],
                            ),
                          ),
                              const SizedBox(height: 18),
                          Text(
                            'Tu es prêt à tenir ferme.',
                            textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                              fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                            'La discipline produit la croissance. Un jour à la fois, laisse la Parole éclairer ta route.',
                            textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 15,
                                    height: 1.3,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                            '"Ta parole est une lampe à mes pieds, et une lumière sur mon sentier."',
                            textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                                    height: 1.2,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                            ),
                          ),
                              const SizedBox(height: 20),
                              // CTA principal (style cohérent)
                          _PrimaryGradientButton(
                            label: 'Commencer maintenant',
                            onPressed: () => context.go('/home'),
                          ),
                        ],
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
                  ),
                  const Spacer(),
                  // Barre style iOS
                  Container(
                    height: 5,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.14),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ——— Éléments abstraits animés
class _FloatingElements extends StatefulWidget {
  const _FloatingElements({required this.controller});
  final AnimationController controller;

  @override
  State<_FloatingElements> createState() => _FloatingElementsState();
}

class _FloatingElementsState extends State<_FloatingElements>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    )..repeat();
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: const Duration(seconds: 35),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Stack(
      children: [
        // Cercle principal avec mouvement orbital complexe
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = _floatController.value;
            final x = screenWidth * 0.2 + screenWidth * 0.3 * (0.5 + 0.5 * math.sin(t * 0.8 * math.pi));
            final y = screenHeight * 0.2 + screenHeight * 0.2 * (0.5 + 0.5 * math.cos(t * 0.8 * math.pi + 1.5));
            return Positioned(
              left: x,
              top: y,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * 3.14159,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.08),
                            const Color(0xFF8B5CF6).withOpacity(0.04),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        // Triangle avec mouvement en spirale
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = _floatController.value;
            final spiralRadius = screenWidth * 0.1 + screenWidth * 0.08 * t;
            final spiralAngle = t * 1.5 * math.pi;
            final x = screenWidth * 0.6 + spiralRadius * math.cos(spiralAngle);
            final y = screenHeight * 0.3 + spiralRadius * math.sin(spiralAngle);
            return Positioned(
              left: x,
              top: y,
              child: AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.6 + (0.6 * _scaleController.value),
                    child: Transform.rotate(
                      angle: spiralAngle,
                      child: CustomPaint(
                        size: const Size(50, 50),
                        painter: _TrianglePainter(
                          color: const Color(0xFF49C98D).withOpacity(0.1),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        // Hexagone avec mouvement en vague
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = _floatController.value;
            final waveX = screenWidth * 0.1 + screenWidth * 0.4 * t;
            final waveY = screenHeight * 0.15 + screenHeight * 0.1 * math.sin(t * 1.2 * math.pi);
            return Positioned(
              left: waveX,
              top: waveY,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 3.14159 / 3,
                    child: CustomPaint(
                      size: const Size(45, 45),
                      painter: _HexagonPainter(
                        color: const Color(0xFF22D3EE).withOpacity(0.08),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        // Ligne ondulée avec mouvement complexe
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = _floatController.value;
            final x = screenWidth * 0.05 + screenWidth * 0.3 * t;
            final y = screenHeight * 0.6 + screenHeight * 0.08 * math.sin(t * 0.8 * math.pi);
            return Positioned(
              left: x,
              top: y,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 3.14159 / 6 + t * 3.14159,
                    child: Container(
                      width: 100,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF22D3EE).withOpacity(0.15),
                            const Color(0xFF6366F1).withOpacity(0.08),
                            const Color(0xFF8B5CF6).withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        // Cercle secondaire avec mouvement en 8
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final t = _floatController.value;
            final x = screenWidth * 0.4 + screenWidth * 0.1 * math.sin(t * 1.5 * math.pi);
            final y = screenHeight * 0.7 + screenHeight * 0.06 * math.cos(t * 1.5 * math.pi);
            return Positioned(
              left: x,
              top: y,
              child: AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.4 + (0.3 * _scaleController.value),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFFFFF).withOpacity(0.08),
                            const Color(0xFF6366F1).withOpacity(0.04),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFFFFF).withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        // Particules avec mouvement brownien
        ...List.generate(12, (index) {
          return AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final t = _floatController.value;
              final offset = (index * 0.083) % 1.0;
              final phase = (t + offset) % 1.0;
              
              // Mouvement brownien simulé réparti sur tout l'écran
              final brownianX = screenWidth * 0.05 + screenWidth * 0.9 * phase + screenWidth * 0.08 * math.sin(phase * 2 * math.pi);
              final brownianY = screenHeight * 0.1 + screenHeight * 0.8 * (0.5 + 0.5 * math.cos(phase * 1.5 * math.pi)) + screenHeight * 0.05 * math.sin(phase * 2.5 * math.pi);
              
              return Positioned(
                left: brownianX,
                top: brownianY,
                child: Transform.rotate(
                  angle: phase * 4 * 3.14159,
                  child: Container(
                    width: 6 + (4 * phase),
                    height: 6 + (4 * phase),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    color: const Color(0xFFFFFFFF).withOpacity(0.06 * (1 - phase * 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.12 * (1 - phase * 0.5)),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Formes géométriques flottantes
        ...List.generate(6, (index) {
          return AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final t = _floatController.value;
              final offset = (index * 0.167) % 1.0;
              final phase = (t + offset) % 1.0;
              
              final x = screenWidth * 0.1 + screenWidth * 0.8 * phase;
              final y = screenHeight * 0.2 + screenHeight * 0.6 * (0.5 + 0.5 * math.sin(phase * 0.8 * math.pi));
              
              return Positioned(
                left: x,
                top: y,
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateController.value * 3.14159 + phase * 2 * 3.14159,
                      child: CustomPaint(
                        size: const Size(25, 25),
                        painter: _StarPainter(
                          color: const Color(0xFF49C98D).withOpacity(0.06),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// Peintre pour le triangle
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Peintre pour l'hexagone
class _HexagonPainter extends CustomPainter {
  const _HexagonPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Peintre pour l'étoile
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - (math.pi / 2);
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ——— UI helpers

class _SoftBlurHalo extends StatelessWidget {
  const _SoftBlurHalo({
    this.left, this.top, this.right, this.bottom,
    required this.color,
  });
  final double? left, top, right, bottom;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left, top: top, right: right, bottom: bottom,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              color: color.withOpacity(.28),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1553FF), Color(0xFF49C98D)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1553FF).withOpacity(.25),
            blurRadius: 18, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: Colors.white,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16, 
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
