import 'package:flutter/material.dart';

class PlanPreset {
  final String id;
  final String title;
  final String? subtitle;
  final String? badge;
  final IconData? icon;
  final Color? color;
  final String? description;
  final int? duration;
  final List<String>? categories;
  final bool? isRecommended;
  final bool? isPopular;
  final String? name;
  final String? shortDesc;
  final int? durationDays;
  final String? difficulty;
  final Map<String, dynamic>? parameters;
  final bool? hasBpVideos;

  const PlanPreset({
    required this.id,
    required this.title,
    this.subtitle,
    this.badge,
    this.icon,
    this.color,
    this.description,
    this.duration,
    this.categories,
    this.isRecommended,
    this.isPopular,
    this.name,
    this.shortDesc,
    this.durationDays,
    this.difficulty,
    this.parameters,
    this.hasBpVideos,
  });

  factory PlanPreset.fromJson(Map<String, dynamic> json) {
    return PlanPreset(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#8B5CF6',
      duration: json['duration'] ?? 30,
      categories: List<String>.from(json['categories'] ?? []),
      isRecommended: json['isRecommended'] ?? false,
      isPopular: json['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'icon': icon,
      'color': color,
      'duration': duration,
      'categories': categories,
      'isRecommended': isRecommended,
      'isPopular': isPopular,
    };
  }
}