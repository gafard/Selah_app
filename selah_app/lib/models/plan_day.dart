class PlanDay {
  final int? id;
  final int planId;
  final int dayNumber;
  final DateTime date;
  final List<String> bibleReferences;
  final String status; // 'pending', 'completed', 'skipped'
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ NOUVEAU : Métadonnées sémantiques
  final String? annotation;           // "Parabole du semeur", "Sermon sur la montagne"
  final bool? hasLiteraryUnit;        // Ce passage contient une unité littéraire
  final String? unitType;             // 'parable', 'discourse', 'narrative', etc.
  final String? unitPriority;         // 'critical', 'high', 'medium'
  final List<String>? tags;           // ['parabole', 'royaume', 'semeur']
  final int? estimatedMinutes;        // Temps estimé adapté à la densité
  final String? meditationType;       // Type de méditation recommandé

  PlanDay({
    this.id,
    required this.planId,
    required this.dayNumber,
    required this.date,
    required this.bibleReferences,
    required this.status,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.annotation,
    this.hasLiteraryUnit,
    this.unitType,
    this.unitPriority,
    this.tags,
    this.estimatedMinutes,
    this.meditationType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_number': dayNumber,
      'date': date.toIso8601String(),
      'bible_references': bibleReferences,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'annotation': annotation,
      'has_literary_unit': hasLiteraryUnit,
      'unit_type': unitType,
      'unit_priority': unitPriority,
      'tags': tags,
      'estimated_minutes': estimatedMinutes,
      'meditation_type': meditationType,
    };
  }

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      id: json['id'],
      planId: json['plan_id'],
      dayNumber: json['day_number'],
      date: DateTime.parse(json['date']),
      bibleReferences: List<String>.from(json['bible_references']),
      status: json['status'],
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      annotation: json['annotation'],
      hasLiteraryUnit: json['has_literary_unit'],
      unitType: json['unit_type'],
      unitPriority: json['unit_priority'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      estimatedMinutes: json['estimated_minutes'],
      meditationType: json['meditation_type'],
    );
  }
}
