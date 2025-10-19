import 'package:flutter/material.dart';

/// Modèle représentant une fondation spirituelle
class SpiritualFoundation {
  final String id;
  final String name;
  final String shortDescription;
  final String fullDescription;
  final String icon; // Nom de l'icône Material Icons
  final List<Color> gradient;
  final String verseReference;
  final String verseText;
  final String category; // 'foundation', 'practice', 'pitfall'
  final String prayerTone; // 'adoration', 'intercession', 'repentance'
  final List<String> targetProfiles; // ['beginner', 'intermediate', 'advanced']

  const SpiritualFoundation({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.fullDescription,
    required this.icon,
    required this.gradient,
    required this.verseReference,
    required this.verseText,
    required this.category,
    required this.prayerTone,
    required this.targetProfiles,
  });

  factory SpiritualFoundation.fromJson(Map<String, dynamic> json) {
    return SpiritualFoundation(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Fondation inconnue',
      shortDescription: json['shortDescription'] as String? ?? 'Description courte manquante',
      fullDescription: json['fullDescription'] as String? ?? 'Description complète manquante',
      icon: json['icon'] as String? ?? 'help_outline',
      gradient: (json['gradient'] as List<dynamic>?)
          ?.map((color) => Color(int.parse(color.toString().replaceFirst('#', '0xFF'))))
          .toList() ?? [Colors.blue, Colors.purple],
      verseReference: json['verseReference'] as String? ?? 'Jean 3:16',
      verseText: json['verseText'] as String? ?? 'Car Dieu a tant aimé le monde...',
      category: json['category'] as String? ?? 'foundation',
      prayerTone: json['prayerTone'] as String? ?? 'adoration',
      targetProfiles: (json['targetProfiles'] as List<dynamic>?)?.cast<String>() ?? ['beginner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'icon': icon,
      'gradient': gradient.map((color) => '#${color.value.toRadixString(16).substring(2).toUpperCase()}').toList(),
      'verseReference': verseReference,
      'verseText': verseText,
      'category': category,
      'prayerTone': prayerTone,
      'targetProfiles': targetProfiles,
    };
  }

  /// Retourne l'icône Material correspondante
  IconData get iconData {
    const iconMap = {
      'landscape_rounded': Icons.landscape_rounded,
      'menu_book_rounded': Icons.menu_book_rounded,
      'self_improvement': Icons.self_improvement,
      'volunteer_activism': Icons.volunteer_activism,
      'favorite_rounded': Icons.favorite_rounded,
      'flag_rounded': Icons.flag_rounded,
      'visibility_rounded': Icons.visibility_rounded,
      'check_circle_outline': Icons.check_circle_outline,
      'fitness_center': Icons.fitness_center,
      'warning_amber_rounded': Icons.warning_amber_rounded,
      'block': Icons.block,
    };
    return iconMap[icon] ?? Icons.help_outline;
  }

  @override
  String toString() {
    return 'SpiritualFoundation(id: $id, name: $name, category: $category)';
  }
}
