class ReadingConfig {
  final String planId;
  final int dayNumber;
  final String passageRef;
  final String passageText;
  final DateTime date;

  const ReadingConfig({
    required this.planId,
    required this.dayNumber,
    required this.passageRef,
    required this.passageText,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'dayNumber': dayNumber,
      'passageRef': passageRef,
      'passageText': passageText,
      'date': date.toIso8601String(),
    };
  }

  factory ReadingConfig.fromJson(Map<String, dynamic> json) {
    return ReadingConfig(
      planId: json['planId'] as String,
      dayNumber: json['dayNumber'] as int,
      passageRef: json['passageRef'] as String,
      passageText: json['passageText'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  ReadingConfig copyWith({
    String? planId,
    int? dayNumber,
    String? passageRef,
    String? passageText,
    DateTime? date,
  }) {
    return ReadingConfig(
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      passageRef: passageRef ?? this.passageRef,
      passageText: passageText ?? this.passageText,
      date: date ?? this.date,
    );
  }
}
