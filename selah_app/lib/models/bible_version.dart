class BibleVersion {
  final String id;
  final String name;
  final String language;
  final String abbreviation;
  final bool isDefault;
  final String? description;

  const BibleVersion({
    required this.id,
    required this.name,
    required this.language,
    required this.abbreviation,
    this.isDefault = false,
    this.description,
  });

  factory BibleVersion.fromJson(Map<String, dynamic> json) {
    return BibleVersion(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      abbreviation: json['abbreviation'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'abbreviation': abbreviation,
      'isDefault': isDefault,
      'description': description,
    };
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleVersion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

