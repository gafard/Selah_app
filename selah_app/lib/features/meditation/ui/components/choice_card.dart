import 'package:flutter/material.dart';
import '../../../../theme/design_tokens.dart';

/// Carte de choix pour le dialog de sélection du style de méditation
class ChoiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const ChoiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? DesignTokens.white22 
              : DesignTokens.white14,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: DesignTokens.white55, width: 1)
              : null,
          boxShadow: isSelected 
              ? [DesignTokens.softShadow]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DesignTokens.subheading,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: DesignTokens.body.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
