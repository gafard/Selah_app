import 'dart:ui';
import 'package:flutter/material.dart';

class DailyBlessing extends StatelessWidget {
  const DailyBlessing(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white70, height: 1.4),
          ),
        ),
      ),
    );
  }
}