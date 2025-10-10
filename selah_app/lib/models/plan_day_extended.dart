import 'plan_day.dart';

/// Extension du modèle PlanDay pour supporter les fonctionnalités avancées
/// 
/// Fonctionnalités ajoutées :
/// - Rattrapage (isCatchup, originalDayNumber)
/// - Métadonnées de méditation (estimatedMinutes, meditationType)
/// - Statut enum typé
class PlanDayExtended {
  final String id;
  final String planId;
  final int dayNumber;
  final DateTime date;
  final List<String> bibleReferences;
  final PlanDayStatus status;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ NOUVEAU : Rattrapage
  final bool isCatchup;           // Ce jour est un rattrapage
  final int? originalDayNumber;   // Numéro du jour original manqué
  final String? catchupReason;    // Raison du rattrapage
  
  // ✅ NOUVEAU : Métadonnées méditation
  final int? estimatedMinutes;    // Temps estimé de lecture
  final String? meditationType;   // Type de méditation recommandé
  final String? meditationDepth;  // Profondeur (light/medium/deep/veryDeep)
  
  // ✅ NOUVEAU : Tracking
  final int? actualMinutesRead;   // Temps réel de lecture
  final double? userSatisfaction; // Satisfaction utilisateur (0.0-1.0)

  PlanDayExtended({
    required this.id,
    required this.planId,
    required this.dayNumber,
    required this.date,
    required this.bibleReferences,
    required this.status,
    this.completedAt,
    this.skippedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isCatchup = false,
    this.originalDayNumber,
    this.catchupReason,
    this.estimatedMinutes,
    this.meditationType,
    this.meditationDepth,
    this.actualMinutesRead,
    this.userSatisfaction,
  });

  /// Convertit en PlanDay standard (rétrocompatible)
  PlanDay toPlanDay() {
    return PlanDay(
      id: int.tryParse(id),
      planId: int.tryParse(planId) ?? 0,
      dayNumber: dayNumber,
      date: date,
      bibleReferences: bibleReferences,
      status: status.name,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Crée depuis PlanDay standard
  factory PlanDayExtended.fromPlanDay(PlanDay day, {
    bool isCatchup = false,
    int? originalDayNumber,
    String? catchupReason,
    int? estimatedMinutes,
    String? meditationType,
  }) {
    return PlanDayExtended(
      id: day.id?.toString() ?? 'temp_${day.dayNumber}',
      planId: day.planId.toString(),
      dayNumber: day.dayNumber,
      date: day.date,
      bibleReferences: day.bibleReferences,
      status: PlanDayStatus.fromString(day.status),
      completedAt: day.completedAt,
      createdAt: day.createdAt,
      updatedAt: day.updatedAt,
      isCatchup: isCatchup,
      originalDayNumber: originalDayNumber,
      catchupReason: catchupReason,
      estimatedMinutes: estimatedMinutes,
      meditationType: meditationType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_number': dayNumber,
      'date': date.toIso8601String(),
      'bible_references': bibleReferences,
      'status': status.name,
      'completed_at': completedAt?.toIso8601String(),
      'skipped_at': skippedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_catchup': isCatchup,
      'original_day_number': originalDayNumber,
      'catchup_reason': catchupReason,
      'estimated_minutes': estimatedMinutes,
      'meditation_type': meditationType,
      'meditation_depth': meditationDepth,
      'actual_minutes_read': actualMinutesRead,
      'user_satisfaction': userSatisfaction,
    };
  }

  factory PlanDayExtended.fromJson(Map<String, dynamic> json) {
    return PlanDayExtended(
      id: json['id'] ?? '',
      planId: json['plan_id'] ?? '',
      dayNumber: json['day_number'],
      date: DateTime.parse(json['date']),
      bibleReferences: List<String>.from(json['bible_references']),
      status: PlanDayStatus.fromString(json['status']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      skippedAt: json['skipped_at'] != null ? DateTime.parse(json['skipped_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isCatchup: json['is_catchup'] ?? false,
      originalDayNumber: json['original_day_number'],
      catchupReason: json['catchup_reason'],
      estimatedMinutes: json['estimated_minutes'],
      meditationType: json['meditation_type'],
      meditationDepth: json['meditation_depth'],
      actualMinutesRead: json['actual_minutes_read'],
      userSatisfaction: json['user_satisfaction']?.toDouble(),
    );
  }

  /// Crée une copie avec modifications
  PlanDayExtended copyWith({
    String? id,
    String? planId,
    int? dayNumber,
    DateTime? date,
    List<String>? bibleReferences,
    PlanDayStatus? status,
    DateTime? completedAt,
    DateTime? skippedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCatchup,
    int? originalDayNumber,
    String? catchupReason,
    int? estimatedMinutes,
    String? meditationType,
    String? meditationDepth,
    int? actualMinutesRead,
    double? userSatisfaction,
  }) {
    return PlanDayExtended(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      bibleReferences: bibleReferences ?? this.bibleReferences,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCatchup: isCatchup ?? this.isCatchup,
      originalDayNumber: originalDayNumber ?? this.originalDayNumber,
      catchupReason: catchupReason ?? this.catchupReason,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      meditationType: meditationType ?? this.meditationType,
      meditationDepth: meditationDepth ?? this.meditationDepth,
      actualMinutesRead: actualMinutesRead ?? this.actualMinutesRead,
      userSatisfaction: userSatisfaction ?? this.userSatisfaction,
    );
  }
  
  /// Indique si ce jour est en retard
  bool get isOverdue {
    return date.isBefore(DateTime.now()) && status == PlanDayStatus.pending;
  }
  
  /// Indique si ce jour est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  /// Indique si ce jour est dans le futur
  bool get isFuture {
    return date.isAfter(DateTime.now());
  }
}

/// Enum typé pour le statut
enum PlanDayStatus {
  pending,
  completed,
  skipped,
  missed;
  
  static PlanDayStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return PlanDayStatus.completed;
      case 'skipped':
        return PlanDayStatus.skipped;
      case 'missed':
        return PlanDayStatus.missed;
      default:
        return PlanDayStatus.pending;
    }
  }
}




