// tool/export_selah_icons.dart
// -----------------------------------------------------------------------------
// Génère les PNG d'icône (toutes tailles) **à partir du CustomPainter** du logo
// hybride Selah (Halo + Pause || + dot). Aucune dépendance externe.
//
// ⚙️ Usage (depuis la racine du projet Flutter) :
//   1) Place ce fichier sous `tool/export_selah_icons.dart`.
//   2) Exécute sur DESKTOP (macOS/Windows/Linux) :
//        flutter run -d macos -t tool/export_selah_icons.dart
//      ou  flutter run -d windows -t tool/export_selah_icons.dart
//      ou  flutter run -d linux  -t tool/export_selah_icons.dart
//   3) Les PNG seront écrits dans `build/selah_icons/`.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:ui' as ui;
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

// === Painter =================================================================
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
    final Color bars = halo;
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
    const double ang = 3.1415926535 / 4;
    final Offset dotCenter = Offset(
      cx + (rHalo * math.cos(ang)),
      cy + (rHalo * math.sin(ang)),
    );
    canvas.drawCircle(dotCenter, dotR, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// === Export helpers ==========================================================
Future<void> _savePng({
  required String path,
  required double size,
  required SelahBadge badge,
  required bool dark,
  double? strokeWidth,
  double? pauseWidth,
  double? pauseHeight,
  double? pauseGap,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final painter = SelahHybridPainter(
    sizePx: size,
    badge: badge,
    dark: dark,
    strokeWidth: strokeWidth,
    pauseWidth: pauseWidth,
    pauseHeight: pauseHeight,
    pauseGap: pauseGap,
  );
  painter.paint(canvas, Size(size, size));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..createSync(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

Future<void> exportAll() async {
  final outDir = Directory('build/selah_icons');
  outDir.createSync(recursive: true);

  // Tailles courantes (inclut 1024 pour stores)
  final sizes = <int>[16, 32, 48, 64, 128, 180, 192, 256, 384, 512, 1024];

  // Variantes principales
  final variants = <({String name, SelahBadge badge, bool dark})>[
    (name: 'no_badge_light', badge: SelahBadge.none, dark: false),
    (name: 'no_badge_dark',  badge: SelahBadge.none, dark: true),
    (name: 'badge_round',    badge: SelahBadge.round, dark: false),
    (name: 'badge_squircle', badge: SelahBadge.squircle, dark: false),
  ];

  for (final v in variants) {
    for (final s in sizes) {
      final p = '${outDir.path}/app_icon_${s}_${v.name}.png';
      await _savePng(path: p, size: s.toDouble(), badge: v.badge, dark: v.dark);
      // ignore: avoid_print
      print('✔︎ $p');
    }
  }

  // Fichiers nommés pour flutter_launcher_icons (1024 recommandé)
  await _savePng(
    path: '${outDir.path}/app_icon_1024_badge_round.png',
    size: 1024,
    badge: SelahBadge.round,
    dark: false,
  );
  await _savePng(
    path: '${outDir.path}/app_icon_1024_no_badge_light.png',
    size: 1024,
    badge: SelahBadge.none,
    dark: false,
  );
}

// === Entrée appli "headless UI" ============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await exportAll();
  // ignore: avoid_print
  print('\nDone. Les fichiers sont dans build/selah_icons/.');
  Future.delayed(const Duration(milliseconds: 300), () => exit(0));
}
