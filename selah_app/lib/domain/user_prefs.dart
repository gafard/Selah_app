abstract class UserPrefs {
  Future<UserProfile> get();
  Future<void> set(UserProfile profile);
  Stream<UserProfile> get profileStream;
  Future<void> update(UserProfile profile);
  Future<void> setHasOnboarded(bool value);
}

class UserProfile {
  final String? displayName;
  final String? bibleVersion;
  final int? dailyMinutes;
  final String? preferredTime;
  final Map<String, dynamic>? preferences;
  final String? themeImageReading;
  final String? themeImageQuiz;
  final String? themeImageAudio;
  final String? themeImageCommunity;
  final bool hasOnboarded;

  UserProfile({
    this.displayName,
    this.bibleVersion,
    this.dailyMinutes,
    this.preferredTime,
    this.preferences,
    this.themeImageReading,
    this.themeImageQuiz,
    this.themeImageAudio,
    this.themeImageCommunity,
    this.hasOnboarded = false,
  });

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'bibleVersion': bibleVersion,
    'dailyMinutes': dailyMinutes,
    'preferredTime': preferredTime,
    'preferences': preferences,
    'themeImageReading': themeImageReading,
    'themeImageQuiz': themeImageQuiz,
    'themeImageAudio': themeImageAudio,
    'themeImageCommunity': themeImageCommunity,
    'hasOnboarded': hasOnboarded,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    displayName: json['displayName'] ?? json['display_name'],
    bibleVersion: json['bibleVersion'],
    dailyMinutes: json['dailyMinutes'],
    preferredTime: json['preferredTime'],
    preferences: json['preferences'] != null 
        ? Map<String, dynamic>.from(json['preferences'] as Map)
        : null,
    themeImageReading: json['themeImageReading'],
    themeImageQuiz: json['themeImageQuiz'],
    themeImageAudio: json['themeImageAudio'],
    themeImageCommunity: json['themeImageCommunity'],
    hasOnboarded: json['hasOnboarded'] ?? false,
  );

  UserProfile copyWith({
    String? displayName,
    String? bibleVersion,
    int? dailyMinutes,
    String? preferredTime,
    Map<String, dynamic>? preferences,
    String? themeImageReading,
    String? themeImageQuiz,
    String? themeImageAudio,
    String? themeImageCommunity,
    bool? hasOnboarded,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      bibleVersion: bibleVersion ?? this.bibleVersion,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      preferredTime: preferredTime ?? this.preferredTime,
      preferences: preferences ?? this.preferences,
      themeImageReading: themeImageReading ?? this.themeImageReading,
      themeImageQuiz: themeImageQuiz ?? this.themeImageQuiz,
      themeImageAudio: themeImageAudio ?? this.themeImageAudio,
      themeImageCommunity: themeImageCommunity ?? this.themeImageCommunity,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
    );
  }
}