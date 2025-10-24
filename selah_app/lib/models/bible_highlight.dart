import 'package:flutter/material.dart';

/// Modèle pour représenter un surlignage biblique
class BibleHighlight {
  final String id;
  final String reference; // ex: "Jean 3:16"
  final String book;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final String selectedText; // Le texte sélectionné
  final Color highlightColor;
  final DateTime createdAt;
  final String? note; // Note optionnelle
  final List<String> tags; // Tags pour organisation
  final String version; // Version de la Bible utilisée

  const BibleHighlight({
    required this.id,
    required this.reference,
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.selectedText,
    required this.highlightColor,
    required this.createdAt,
    this.note,
    this.tags = const [],
    required this.version,
  });

  /// Créer un surlignage depuis une sélection de texte
  factory BibleHighlight.fromSelection({
    required String id,
    required String reference,
    required String book,
    required int startChapter,
    required int startVerse,
    required int endChapter,
    required int endVerse,
    required String selectedText,
    required Color highlightColor,
    required String version,
    String? note,
    List<String> tags = const [],
  }) {
    return BibleHighlight(
      id: id,
      reference: reference,
      book: book,
      startChapter: startChapter,
      startVerse: startVerse,
      endChapter: endChapter,
      endVerse: endVerse,
      selectedText: selectedText,
      highlightColor: highlightColor,
      createdAt: DateTime.now(),
      note: note,
      tags: tags,
      version: version,
    );
  }

  /// Convertir en Map pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'book': book,
      'startChapter': startChapter,
      'startVerse': startVerse,
      'endChapter': endChapter,
      'endVerse': endVerse,
      'selectedText': selectedText,
      'highlightColor': highlightColor.value,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'tags': tags,
      'version': version,
    };
  }

  /// Créer depuis un Map
  factory BibleHighlight.fromJson(Map<String, dynamic> json) {
    return BibleHighlight(
      id: json['id'] as String,
      reference: json['reference'] as String,
      book: json['book'] as String,
      startChapter: json['startChapter'] as int,
      startVerse: json['startVerse'] as int,
      endChapter: json['endChapter'] as int,
      endVerse: json['endVerse'] as int,
      selectedText: json['selectedText'] as String,
      highlightColor: Color(json['highlightColor'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      version: json['version'] as String,
    );
  }

  /// Copier avec modifications
  BibleHighlight copyWith({
    String? id,
    String? reference,
    String? book,
    int? startChapter,
    int? startVerse,
    int? endChapter,
    int? endVerse,
    String? selectedText,
    Color? highlightColor,
    DateTime? createdAt,
    String? note,
    List<String>? tags,
    String? version,
  }) {
    return BibleHighlight(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      book: book ?? this.book,
      startChapter: startChapter ?? this.startChapter,
      startVerse: startVerse ?? this.startVerse,
      endChapter: endChapter ?? this.endChapter,
      endVerse: endVerse ?? this.endVerse,
      selectedText: selectedText ?? this.selectedText,
      highlightColor: highlightColor ?? this.highlightColor,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      version: version ?? this.version,
    );
  }

  @override
  String toString() {
    return 'BibleHighlight(id: $id, reference: $reference, selectedText: ${selectedText.length > 50 ? '${selectedText.substring(0, 50)}...' : selectedText})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BibleHighlight && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Couleurs disponibles pour les surlignages
class HighlightColor {
  static const List<Color> availableColors = [
    Color(0xFFFFEB3B), // Jaune - Important
    Color(0xFF4CAF50), // Vert - Promesses
    Color(0xFF2196F3), // Bleu - Prières
    Color(0xFFE91E63), // Rose - Amour
    Color(0xFFFF9800), // Orange - Avertissements
    Color(0xFF9C27B0), // Violet - Prophéties
    Color(0xFFF44336), // Rouge - Sang/Redemption
    Color(0xFF00BCD4), // Cyan - Esprit Saint
  ];

  static const List<String> colorNames = [
    'Important',
    'Promesses',
    'Prières',
    'Amour',
    'Avertissements',
    'Prophéties',
    'Sang/Redemption',
    'Esprit Saint',
  ];

  /// Obtenir le nom d'une couleur
  static String getColorName(Color color) {
    final index = availableColors.indexOf(color);
    return index >= 0 ? colorNames[index] : 'Inconnu';
  }

  /// Obtenir la couleur par nom
  static Color? getColorByName(String name) {
    final index = colorNames.indexOf(name);
    return index >= 0 ? availableColors[index] : null;
  }
}

