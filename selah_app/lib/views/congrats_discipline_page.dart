import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../domain/telemetry.dart';

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
      context.read<Telemetry>().track('congrats_viewed', {});
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
      backgroundColor: const Color(0xFF101423), // fond sombre
      body: Stack(
        children: [
          const _SoftBlurHalo(left: -80, top: -60, color: Color(0xFF7C3AED)),
          const _SoftBlurHalo(right: -70, bottom: -60, color: Color(0xFF22D3EE)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Column(
                children: [
                  // Close -> Home (option)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ),
                  const Spacer(),
                  // Carte blanche animée
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.22),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge + icône
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22D3EE).withOpacity(.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFF22D3EE).withOpacity(.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emoji_events, size: 16, color: Color(0xFF0891B2)),
                                SizedBox(width: 6),
                                Text('Félicitations',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0369A1),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tu es prêt à tenir ferme.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'La discipline produit la croissance. Un jour à la fois, laisse la Parole éclairer ta route.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.55,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '"Ta parole est une lampe à mes pieds, et une lumière sur mon sentier."',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 22),
                          // CTA principal
                          _PrimaryGradientButton(
                            label: 'Commencer maintenant',
                            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                          ),
                          const SizedBox(height: 10),
                          // Lien secondaire
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                            child: Text(
                              'Voir mon plan',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0EA5E9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
    );
  }
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
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
