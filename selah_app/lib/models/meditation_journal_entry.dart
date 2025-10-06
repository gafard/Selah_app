import 'dart:typed_data';

class MeditationJournalEntry {
  final String id;
  final DateTime date;
  final String passageRef;
  final String passageText;
  final String memoryVerse;
  final String memoryVerseRef;
  final List<String> prayerSubjects;
  final List<String> prayerNotes;
  final int gradientIndex; // Index du dégradé choisi pour le poster
  final Uint8List? posterImageBytes; // Image du poster sauvegardée
  final String meditationType; // 'free' ou 'qcm'
  final Map<String, dynamic> meditationData; // Données de méditation (tags, réponses, etc.)

  MeditationJournalEntry({
    required this.id,
    required this.date,
    required this.passageRef,
    required this.passageText,
    required this.memoryVerse,
    required this.memoryVerseRef,
    required this.prayerSubjects,
    required this.prayerNotes,
    required this.gradientIndex,
    this.posterImageBytes,
    required this.meditationType,
    required this.meditationData,
  });

  // Convertir en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'passageRef': passageRef,
      'passageText': passageText,
      'memoryVerse': memoryVerse,
      'memoryVerseRef': memoryVerseRef,
      'prayerSubjects': prayerSubjects,
      'prayerNotes': prayerNotes,
      'gradientIndex': gradientIndex,
      'posterImageBytes': posterImageBytes?.toList(),
      'meditationType': meditationType,
      'meditationData': meditationData,
    };
  }

  // Créer depuis un Map
  factory MeditationJournalEntry.fromMap(Map<String, dynamic> map) {
    return MeditationJournalEntry(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      passageRef: map['passageRef'] ?? '',
      passageText: map['passageText'] ?? '',
      memoryVerse: map['memoryVerse'] ?? '',
      memoryVerseRef: map['memoryVerseRef'] ?? '',
      prayerSubjects: List<String>.from(map['prayerSubjects'] ?? []),
      prayerNotes: List<String>.from(map['prayerNotes'] ?? []),
      gradientIndex: map['gradientIndex'] ?? 0,
      posterImageBytes: map['posterImageBytes'] != null 
          ? Uint8List.fromList(List<int>.from(map['posterImageBytes']))
          : null,
      meditationType: map['meditationType'] ?? 'free',
      meditationData: Map<String, dynamic>.from(map['meditationData'] ?? {}),
    );
  }

  // Copier avec modifications
  MeditationJournalEntry copyWith({
    String? id,
    DateTime? date,
    String? passageRef,
    String? passageText,
    String? memoryVerse,
    String? memoryVerseRef,
    List<String>? prayerSubjects,
    List<String>? prayerNotes,
    int? gradientIndex,
    Uint8List? posterImageBytes,
    String? meditationType,
    Map<String, dynamic>? meditationData,
  }) {
    return MeditationJournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      passageRef: passageRef ?? this.passageRef,
      passageText: passageText ?? this.passageText,
      memoryVerse: memoryVerse ?? this.memoryVerse,
      memoryVerseRef: memoryVerseRef ?? this.memoryVerseRef,
      prayerSubjects: prayerSubjects ?? this.prayerSubjects,
      prayerNotes: prayerNotes ?? this.prayerNotes,
      gradientIndex: gradientIndex ?? this.gradientIndex,
      posterImageBytes: posterImageBytes ?? this.posterImageBytes,
      meditationType: meditationType ?? this.meditationType,
      meditationData: meditationData ?? this.meditationData,
    );
  }

  @override
  String toString() {
    return 'MeditationJournalEntry(id: $id, date: $date, passageRef: $passageRef, memoryVerse: $memoryVerse)';
  }
}
