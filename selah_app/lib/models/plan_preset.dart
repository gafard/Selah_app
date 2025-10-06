import 'dart:convert';
import 'package:flutter/material.dart';

enum PresetLevel { beginner, regular, leader }

class PlanPreset {
  final String slug;
  final String name;
  final int durationDays;              // ex: 31, 40, 90, 180
  final String order;                  // 'traditional' | 'chronological' | ...
  final String books;                  // 'OT,NT' | 'NT' | 'Psalms,Proverbs'...
  final String? coverImage;
  final int? minutesPerDay;            // estimation affichage
  final List<PresetLevel> recommended; // pour classement
  final String? description;           // description dynamique
  final List<Color>? gradient;         // gradient personnalisé
  final String? specificBooks;         // livres/chapitres spécifiques

  PlanPreset({
    required this.slug,
    required this.name,
    required this.durationDays,
    required this.order,
    required this.books,
    this.coverImage,
    this.minutesPerDay,
    this.recommended = const [],
    this.description,
    this.gradient,
    this.specificBooks,
  });

  factory PlanPreset.fromJson(Map<String, dynamic> j) => PlanPreset(
    slug: j['slug'],
    name: j['name'],
    durationDays: j['durationDays'],
    order: j['order'],
    books: j['books'],
    coverImage: j['coverImage'],
    minutesPerDay: j['minutesPerDay'],
    recommended: (j['recommended'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .map((s) => {
          'beginner': PresetLevel.beginner,
          'regular': PresetLevel.regular,
          'leader': PresetLevel.leader,
        }[s] ?? PresetLevel.regular)
        .toList(),
  );

  static List<PlanPreset> listFromJson(String raw) =>
      (jsonDecode(raw) as List).map((e) => PlanPreset.fromJson(e)).toList();
}