import 'package:flutter/material.dart';
import 'package:essai/models/plan_preset.dart';

class PresetCard extends StatelessWidget {
  final PlanPreset preset;
  final VoidCallback? onTap;
  final bool isSelected;

  const PresetCard({
    super.key,
    required this.preset,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? Border.all(
            color: preset.color ?? Colors.blue,
            width: 2,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (preset.color ?? Colors.blue).withOpacity(.18),
              (preset.color ?? Colors.blue).withOpacity(.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Fond décoratif
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: (preset.color ?? Colors.blue).withOpacity(.25),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Contenu
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (preset.color ?? Colors.blue).withOpacity(.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      preset.badge ?? '',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: (preset.color ?? Colors.blue).withOpacity(.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Icône
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Icon(preset.icon, size: 36, color: preset.color),
                  ),
                  const SizedBox(height: 16),
                  // Titre
                  Text(
                    preset.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Sous-titre
                  Text(
                    preset.subtitle ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CTA
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Voir le plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: preset.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
