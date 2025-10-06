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
    );
  }
}
