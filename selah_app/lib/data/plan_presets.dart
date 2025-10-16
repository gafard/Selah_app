import 'package:flutter/material.dart';
import '../models/plan_preset.dart';

class PlanPresets {
  static final List<PlanPreset> presets = [
    PlanPreset(
      slug: 'new_testament',
      name: 'Nouveau Testament',
      durationDays: 90,
      order: 'traditional',
      books: 'NT',
      description: 'Découvrez le Nouveau Testament en 90 jours',
      minutesPerDay: 10,
      recommended: [PresetLevel.beginner, PresetLevel.regular],
    ),
    PlanPreset(
      slug: 'psalms',
      name: 'Psaumes',
      durationDays: 150,
      order: 'traditional',
      books: 'Psalms',
      description: 'Méditez les Psaumes en 150 jours',
      minutesPerDay: 5,
      recommended: [PresetLevel.beginner, PresetLevel.regular],
    ),
    PlanPreset(
      slug: 'proverbs',
      name: 'Proverbes',
      durationDays: 31,
      order: 'traditional',
      books: 'Proverbs',
      description: 'Découvrez la sagesse des Proverbes',
      minutesPerDay: 8,
      recommended: [PresetLevel.beginner, PresetLevel.regular],
    ),
    PlanPreset(
      slug: 'gospels',
      name: 'Les 4 Évangiles',
      durationDays: 60,
      order: 'chronological',
      books: 'Matthew,Mark,Luke,John',
      description: 'Découvrez la vie de Jésus dans les 4 Évangiles',
      minutesPerDay: 12,
      recommended: [PresetLevel.beginner, PresetLevel.regular, PresetLevel.leader],
    ),
    PlanPreset(
      slug: 'bible_complete',
      name: 'Bible Complète',
      durationDays: 365,
      order: 'traditional',
      books: 'OT,NT',
      description: 'Lisez toute la Bible en un an',
      minutesPerDay: 15,
      recommended: [PresetLevel.regular, PresetLevel.leader],
    ),
  ];

  /// Trouve un preset par son slug
  static PlanPreset? findBySlug(String slug) {
    try {
      return presets.firstWhere((preset) => preset.slug == slug);
    } catch (e) {
      return null;
    }
  }

  /// Retourne les presets recommandés pour un niveau donné
  static List<PlanPreset> getRecommendedFor(PresetLevel level) {
    return presets.where((preset) => preset.recommended.contains(level)).toList();
  }

  /// Retourne tous les presets triés par durée
  static List<PlanPreset> getAllSortedByDuration() {
    final sorted = List<PlanPreset>.from(presets);
    sorted.sort((a, b) => a.durationDays.compareTo(b.durationDays));
    return sorted;
  }
}