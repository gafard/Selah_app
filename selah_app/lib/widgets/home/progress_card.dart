import 'dart:ui';
import 'package:flutter/material.dart';

class HomeProgressCard extends StatelessWidget {
  const HomeProgressCard({
    super.key, 
    required this.title, 
    required this.done, 
    required this.total,
    this.currentStreak = 0,
    this.weeksRemaining = 0,
  });
  final String title;
  final int done;
  final int total;
  final int currentStreak;
  final int weeksRemaining;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1553FF).withOpacity(0.8),
                const Color(0xFF49C98D).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et progression
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title, 
                          style: const TextStyle(
                            fontFamily: 'Gilroy', 
                            fontSize: 14, 
                            color: Colors.white, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(ratio * 100).round()}% du plan terminé', 
                          style: const TextStyle(
                            fontFamily: 'Gilroy', 
                            fontSize: 12, 
                            color: Colors.white70
                          )
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: ratio,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withOpacity(.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(ratio * 100).round()}%', 
                          style: const TextStyle(
                            fontFamily: 'Gilroy', 
                            fontSize: 10, 
                            color: Colors.white, 
                            fontWeight: FontWeight.w700
                          )
                        ),
                      )
                    ]),
                  )
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Petits textes pour série et semaines
              Row(
                children: [
                  Text(
                    'Série: $currentStreak jours',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Restant: $weeksRemaining sem.',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
