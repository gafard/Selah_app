class Plan {
  final String id;
  final String name;
  final DateTime startDate;
  final int totalDays;
  final String? coverUrl;

  const Plan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.totalDays,
    this.coverUrl,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      totalDays: json['total_days'] as int,
      coverUrl: json['cover_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'total_days': totalDays,
      'cover_url': coverUrl,
    };
  }
}