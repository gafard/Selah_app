import '../utils/prayer_subjects_mapper.dart';

/// Contrat de navigation pour passer les données de passage
class PassagePayload {
  final String ref;
  final String text;
  final String? altVersionText;
  final String? dayTitle;
  final String? planId;
  final int? dayNumber;
  
  const PassagePayload({
    required this.ref,
    required this.text,
    this.altVersionText,
    this.dayTitle,
    this.planId,
    this.dayNumber,
  });

  factory PassagePayload.fromMap(Map<String, dynamic> map) {
    return PassagePayload(
      ref: map['passageRef'] as String? ?? '',
      text: map['passageText'] as String? ?? '',
      altVersionText: map['altVersionText'] as String?,
      dayTitle: map['dayTitle'] as String?,
      planId: map['planId'] as String?,
      dayNumber: map['dayNumber'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passageRef': ref,
      'passageText': text,
      'altVersionText': altVersionText,
      'dayTitle': dayTitle,
      'planId': planId,
      'dayNumber': dayNumber,
    };
  }
}

/// Résultat d'une session de méditation
class MeditationResult {
  final List<PrayerItem> items;
  final Map<String, Set<String>> selectedTagsByField;
  final Map<String, Set<String>> selectedAnswersByField;
  final Map<String, String> freeTextResponses;
  final String memoryVerse;
  
  const MeditationResult({
    required this.items,
    required this.selectedTagsByField,
    required this.selectedAnswersByField,
    required this.freeTextResponses,
    this.memoryVerse = '',
  });

  factory MeditationResult.fromMap(Map<String, dynamic> map) {
    return MeditationResult(
      items: (map['items'] as List<dynamic>?)
          ?.map((e) => PrayerItem.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      selectedTagsByField: Map<String, Set<String>>.from(
        (map['selectedTagsByField'] as Map<String, dynamic>?) ?? {}
      ),
      selectedAnswersByField: Map<String, Set<String>>.from(
        (map['selectedAnswersByField'] as Map<String, dynamic>?) ?? {}
      ),
      freeTextResponses: Map<String, String>.from(
        (map['freeTextResponses'] as Map<String, dynamic>?) ?? {}
      ),
      memoryVerse: map['memoryVerse'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((e) => {
        'theme': e.theme,
        'subject': e.subject,
        'color': e.color.value,
        'validated': e.validated,
        'notes': e.notes,
      }).toList(),
      'selectedTagsByField': selectedTagsByField,
      'selectedAnswersByField': selectedAnswersByField,
      'freeTextResponses': freeTextResponses,
      'memoryVerse': memoryVerse,
    };
  }
}

