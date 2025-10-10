import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/home_vm.dart';

class HomeQuizCard extends StatelessWidget {
  const HomeQuizCard({super.key, required this.progress});
  final QuizProgress progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.speed, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('Quiz Apôtre', style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(12)),
            child: Text('${progress.totalQuizzes} quiz', style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Stat(label: 'Score moyen', value: '${progress.averageScore}%', icon: Icons.trending_up)),
          const SizedBox(width: 16),
          Expanded(child: _Stat(label: 'Style d\'apprentissage', value: progress.learningStyle, icon: Icons.psychology)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Stat(label: 'Niveau spirituel', value: progress.spiritualLevel, icon: Icons.auto_awesome)),
          const SizedBox(width: 16),
          Expanded(child: _Stat(label: 'Dernier quiz', value: progress.lastQuizDate, icon: Icons.schedule)),
        ]),
      ]),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: Colors.white70, size: 14), const SizedBox(width: 4), Text(label, style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white70, fontSize: 12))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}