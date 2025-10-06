class LegacyUserProfile {
  final String id;
  final String? displayName;
  final String email;
  final bool hasOnboarded;
  final String bibleVersion;            // ex: "LSG"
  final String preferredTime;           // ex: "07:00"
  final int dailyMinutes;               // ex: 15
  final List<String> goals;             // ex: ["memorisation","discipline","connaissance"]
  final bool audioMode;
  final String? currentPlanId;

  const LegacyUserProfile({
    required this.id,
    this.displayName,
    required this.email,
    required this.hasOnboarded,
    required this.bibleVersion,
    required this.preferredTime,
    required this.dailyMinutes,
    required this.goals,
    required this.audioMode,
    this.currentPlanId,
  });

  LegacyUserProfile copyWith({
    String? displayName,
    bool? hasOnboarded,
    String? bibleVersion,
    String? preferredTime,
    int? dailyMinutes,
    List<String>? goals,
    bool? audioMode,
    String? currentPlanId,
  }) => LegacyUserProfile(
    id: id,
    displayName: displayName ?? this.displayName,
    email: email,
    hasOnboarded: hasOnboarded ?? this.hasOnboarded,
    bibleVersion: bibleVersion ?? this.bibleVersion,
    preferredTime: preferredTime ?? this.preferredTime,
    dailyMinutes: dailyMinutes ?? this.dailyMinutes,
    goals: goals ?? this.goals,
    audioMode: audioMode ?? this.audioMode,
    currentPlanId: currentPlanId ?? this.currentPlanId,
  );

  factory LegacyUserProfile.fromJson(Map<String, dynamic> json) {
    return LegacyUserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String,
      hasOnboarded: json['has_onboarded'] as bool? ?? false,
      bibleVersion: json['bible_version'] as String? ?? 'LSG',
      preferredTime: json['preferred_time'] as String? ?? '07:00',
      dailyMinutes: json['daily_minutes'] as int? ?? 15,
      goals: (json['goals'] as List?)?.cast<String>() ?? const ['discipline'],
      audioMode: json['audio_mode'] as bool? ?? true,
      currentPlanId: json['current_plan_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'has_onboarded': hasOnboarded,
      'bible_version': bibleVersion,
      'preferred_time': preferredTime,
      'daily_minutes': dailyMinutes,
      'goals': goals,
      'audio_mode': audioMode,
      'current_plan_id': currentPlanId,
    };
  }
}