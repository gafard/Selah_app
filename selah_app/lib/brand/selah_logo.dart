// brand/selah_logo.dart
// Logo et identité visuelle Selah
import 'dart:math' as math;
import 'package:flutter/material.dart';

// === Tokens brand ============================================================
class SelahColors {
  static const indigo = Color(0xFF2B1E75);
  static const marine = Color(0xFF0B2B7E);
  static const sage   = Color(0xFF49C98D);
  static const white  = Color(0xFFFFFFFF);
}

enum SelahBadge { none, round, squircle }

// === Painter : Logo hybride Selah (Halo + Pause || + dot) ====================
class SelahHybridPainter extends CustomPainter {
  SelahHybridPainter({
    this.sizePx = 1024,
    this.badge = SelahBadge.round,
    this.dark = false,
    this.strokeWidth,
    this.pauseWidth,
    this.pauseHeight,
    this.pauseGap,
  });

  final double sizePx;
  final SelahBadge badge;
  final bool dark;
  final double? strokeWidth;
  final double? pauseWidth;
  final double? pauseHeight;
  final double? pauseGap;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Badge
    if (badge != SelahBadge.none) {
      final bgPaint = Paint()..color = SelahColors.indigo;
      if (badge == SelahBadge.round) {
        canvas.drawCircle(Offset(cx, cy), size.width / 2, bgPaint);
      } else {
        final r = 0.175 * size.width;
        final rect = Offset.zero & size;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), bgPaint);
      }
    }

    final bool onBadge = badge != SelahBadge.none;
    final Color halo = (onBadge || dark) ? SelahColors.white : SelahColors.indigo;
    final Color bars = halo; // même couleur pour cohérence
    const Color dot = SelahColors.sage;

    final double rHalo = 0.41 * size.width;
    final double sw = strokeWidth ?? 0.088 * size.width;
    final double bw = pauseWidth ?? 0.11 * size.width;
    final double bh = pauseHeight ?? 0.40 * size.width;
    final double gap = pauseGap ?? 0.08 * size.width;

    final haloPaint = Paint()
      ..color = halo
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(cx, cy), rHalo, haloPaint);

    final pAccent = Paint()
      ..color = halo
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final top = Offset(cx, cy - rHalo);
    final accentEnd = top + Offset(0.13 * size.width, -0.11 * size.width);
    canvas.drawLine(top, accentEnd, pAccent);

    final barsPaint = Paint()..color = bars;
    final x1 = cx - gap / 2 - bw;
    final x2 = cx + gap / 2;
    final y = cy - bh / 2;
    final r = Radius.circular(bw / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x1, y, bw, bh), r), barsPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x2, y, bw, bh), r), barsPaint);

    final double dotR = 0.07 * size.width;
    const double ang = 3.1415926535 / 4; // 45°
    final Offset dotCenter = Offset(
      cx + (rHalo * math.cos(ang)),
      cy + (rHalo * math.sin(ang)),
    );
    canvas.drawCircle(dotCenter, dotR, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// === Widget : Icône hybride ==================================================
class SelahHybridIcon extends StatelessWidget {
  const SelahHybridIcon({
    super.key,
    this.size = 120,
    this.badge = SelahBadge.none,
    this.dark = false,
  });

  final double size;
  final SelahBadge badge;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: SelahHybridPainter(
        sizePx: size,
        badge: badge,
        dark: dark,
      ),
    );
  }
}

// === Widget : Wordmark (texte "Selah") =======================================
class SelahWordmark extends StatelessWidget {
  const SelahWordmark({
    super.key,
    this.fontSize = 28,
    this.color,
  });

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Selah',
      style: TextStyle(
        fontFamily: 'Gilroy',
        fontSize: fontSize,
        fontWeight: FontWeight.w800, // Heavy
        color: color ?? SelahColors.indigo,
        letterSpacing: 1.5,
      ),
    );
  }
}

// === Widget : Logo complet (icône + wordmark) ================================
class SelahLogo extends StatelessWidget {
  const SelahLogo({
    super.key,
    this.iconSize = 60,
    this.fontSize = 24,
    this.badge = SelahBadge.none,
    this.dark = false,
    this.spacing = 12,
    this.axis = Axis.horizontal,
  });

  final double iconSize;
  final double fontSize;
  final SelahBadge badge;
  final bool dark;
  final double spacing;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final icon = SelahHybridIcon(
      size: iconSize,
      badge: badge,
      dark: dark,
    );
    
    final wordmark = SelahWordmark(
      fontSize: fontSize,
      color: dark ? SelahColors.white : SelahColors.indigo,
    );

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          SizedBox(width: spacing),
          wordmark,
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          SizedBox(height: spacing),
          wordmark,
        ],
      );
    }
  }
}

