import 'package:flutter/material.dart';

/// Widget moderne pour afficher un mini graphique de progression de lecture
class ProgressChart extends StatelessWidget {
  final int currentStreak;
  final int weeklyGoal;
  final int weeklyProgress;
  final List<int> last7Days;

  const ProgressChart({
    super.key,
    required this.currentStreak,
    required this.weeklyGoal,
    required this.weeklyProgress,
    required this.last7Days,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = weeklyGoal > 0 ? (weeklyProgress / weeklyGoal).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header compact
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Progression',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${(progressPercentage * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini graphique en ligne
          _buildCompactChart(),
          const SizedBox(height: 8),

          // Statistiques compactes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactStat('Série', '$currentStreak jours'),
              _buildCompactStat('Semaine', '$weeklyProgress/$weeklyGoal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChart() {
    final maxValue = last7Days.isNotEmpty ? last7Days.reduce((a, b) => a > b ? a : b) : 1;
    
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _LineChartPainter(
          data: last7Days,
          maxValue: maxValue,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF60A5FA),
            const Color(0xFF10B981),
            const Color(0xFF34D399),
          ],
        ),
        size: const Size(double.infinity, 40),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getDayLabel(int index) {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[index];
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> data;
  final int maxValue;
  final List<Color> colors;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // Calculer les points de la courbe
    final points = <Offset>[];
    final spacing = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * spacing;
      final y = size.height - (data[i] / maxValue) * (size.height - 8) - 4;
      points.add(Offset(x, y));
    }

    // Dessiner la zone remplie sous la courbe
    final path = Path();
    path.moveTo(points.first.dx, size.height - 4);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, size.height - 4);
    path.close();

    // Gradient pour la zone remplie
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors[2].withOpacity(0.3),
        colors[2].withOpacity(0.1),
      ],
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    fillPaint.shader = gradient.createShader(rect);
    canvas.drawPath(path, fillPaint);

    // Dessiner la ligne de progression
    paint.shader = LinearGradient(
      colors: [colors[2], colors[3]],
    ).createShader(rect);
    
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Dessiner les points
    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors[2];

    for (int i = 0; i < points.length; i++) {
      final isToday = i == points.length - 1;
      final pointColor = isToday ? colors[2] : colors[0];
      final pointSize = isToday ? 4.0 : 3.0;
      
      pointPaint.color = pointColor;
      canvas.drawCircle(points[i], pointSize, pointPaint);
      
      // Effet de glow pour le point d'aujourd'hui
      if (isToday) {
        final glowPaint = Paint()
          ..color = pointColor.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(points[i], pointSize + 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
