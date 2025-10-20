import 'package:flutter/material.dart';
import '../../models/spiritual_foundation.dart';
import '../../services/spiritual_foundations_service.dart';

/// Widget de rappel de fondation affiché dans les étapes de méditation
class FoundationReminder extends StatelessWidget {
  final SpiritualFoundation foundation;

  const FoundationReminder({
    super.key,
    required this.foundation,
  });

  @override
  Widget build(BuildContext context) {
    final reminderText = SpiritualFoundationsService.getReminderText(foundation);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: foundation.gradient[0].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foundation.gradient[0].withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône d'ampoule
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: foundation.gradient[0].withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 16,
              color: foundation.gradient[0],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Texte de rappel
          Expanded(
            child: Text(
              reminderText,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: foundation.gradient[0].withOpacity(0.9),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


