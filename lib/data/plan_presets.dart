import 'package:flutter/material.dart';
import 'package:essai/models/plan_preset.dart';

class PlanPresets {
  static const List<PlanPreset> presets = [
    PlanPreset(
      id: 'new_testament',
      title: 'Nouveau Testament',
      subtitle: '90 jours · ~10 min/jour',
      description: 'Découvrez le Nouveau Testament en 90 jours',
      badge: 'Populaire',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFF9A66C),
      duration: 90,
      categories: ['bible', 'new_testament'],
    ),
    PlanPreset(
      id: 'psalms',
      title: 'Psaumes',
      subtitle: '150 jours · ~5 min/jour',
      description: 'Méditez les Psaumes en 150 jours',
      badge: 'Méditation',
      icon: Icons.music_note_rounded,
      color: Color(0xFF6C5CE7),
      duration: 150,
      categories: ['bible', 'psalms'],
    ),
    PlanPreset(
      id: 'proverbs',
      title: 'Proverbes',
      subtitle: '31 jours · ~8 min/jour',
      description: 'Découvrez la sagesse des Proverbes',
      badge: 'Sagesse',
      icon: Icons.lightbulb_rounded,
      color: Color(0xFF00B894),
      duration: 31,
      categories: ['bible', 'wisdom'],
    ),
    PlanPreset(
      id: 'gospels',
      title: 'Les 4 Évangiles',
      subtitle: '60 jours · ~12 min/jour',
      description: 'Découvrez la vie de Jésus dans les 4 Évangiles',
      badge: 'Jésus',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE17055),
      duration: 60,
      categories: ['bible', 'gospels'],
    ),
    PlanPreset(
      id: 'bible_complete',
      title: 'Bible Complète',
      subtitle: '365 jours · ~15 min/jour',
      description: 'Lisez la Bible complète en un an',
      badge: 'Défi',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF2D3436),
      duration: 365,
      categories: ['bible', 'complete'],
    ),
    PlanPreset(
      id: 'genesis',
      title: 'Genèse',
      subtitle: '50 jours · ~10 min/jour',
      description: 'Découvrez les origines du monde dans la Genèse',
      badge: 'Origines',
      icon: Icons.public_rounded,
      color: Color(0xFF74B9FF),
      duration: 50,
      categories: ['bible', 'genesis'],
    ),
  ];

  static PlanPreset? getById(String id) {
    try {
      return presets.firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<PlanPreset> getPopular() {
    return presets.where((preset) => 
      ['new_testament', 'psalms', 'gospels'].contains(preset.id)
    ).toList();
  }

  static List<PlanPreset> getByCategory(String category) {
    switch (category) {
      case 'popular':
        return getPopular();
      case 'short':
        return presets.where((preset) => 
          ['proverbs', 'genesis'].contains(preset.id)
        ).toList();
      case 'long':
        return presets.where((preset) => 
          ['bible_complete', 'new_testament'].contains(preset.id)
        ).toList();
      default:
        return presets;
    }
  }
}
