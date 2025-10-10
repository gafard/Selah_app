import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarBar extends StatelessWidget {
  const CalendarBar({super.key});
  @override
  Widget build(BuildContext context) {
    const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final now = DateTime.now();
    return Row(
      children: List.generate(7, (i) {
        final date = now.subtract(Duration(days: now.weekday - 1 - i));
        final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: isToday ? 1 : 2),
            padding: EdgeInsets.symmetric(
              vertical: isToday ? 12 : 10, 
              horizontal: isToday ? 8 : 6
            ),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF1553FF) : Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isToday ? Colors.transparent : Colors.white.withOpacity(.14)),
            ),
            child: Column(children: [
              Text(dayNames[i], style: TextStyle(fontFamily: 'Gilroy', fontSize: 10, color: isToday ? Colors.white : Colors.white70)),
              const SizedBox(height: 4),
              Text('${date.day}', style: TextStyle(fontFamily: 'Gilroy', fontSize: isToday ? 16 : 14, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600, color: isToday ? Colors.white : Colors.white)),
              const SizedBox(height: 2),
              Icon(Icons.radio_button_unchecked, size: 10, color: isToday ? Colors.white70 : Colors.white30),
            ]),
          ),
        );
      }),
    );
  }
}
