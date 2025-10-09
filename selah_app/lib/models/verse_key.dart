/// Clé standardisée pour identifier un verset de manière unique
/// 
/// Format : "Livre.Chapitre.Verset" (ex: "Jean.3.16")
/// 
/// Utilisé pour :
/// - Indexation dans toutes les boxes Hive
/// - Références croisées
/// - Lexique
/// - Thèmes
/// - Contexte
class VerseKey {
  final String book;
  final int chapter;
  final int verse;
  
  VerseKey({
    required this.book,
    required this.chapter,
    required this.verse,
  });
  
  /// ID standardisé : "Livre.Chapitre.Verset"
  String get id => '$book.$chapter.$verse';
  
  /// Référence lisible : "Livre chapitre:verset"
  String get reference => '$book $chapter:$verse';
  
  /// Référence courte : "Livre ch:v"
  String get shortReference => '$book $chapter:$verse';
  
  /// Parse une référence textuelle en VerseKey
  /// 
  /// Formats supportés :
  /// - "Jean 3:16"
  /// - "Jean 3.16"
  /// - "Jean.3.16"
  /// - "1 Corinthiens 13:4"
  static VerseKey? parse(String reference) {
    try {
      // Nettoyer la référence
      reference = reference.trim();
      
      // Pattern 1 : "Livre Chapitre:Verset" ou "Livre Chapitre.Verset"
      final pattern1 = RegExp(r'^(.+?)\s+(\d+)[:.​](\d+)$');
      final match1 = pattern1.firstMatch(reference);
      
      if (match1 != null) {
        return VerseKey(
          book: match1.group(1)!.trim(),
          chapter: int.parse(match1.group(2)!),
          verse: int.parse(match1.group(3)!),
        );
      }
      
      // Pattern 2 : "Livre.Chapitre.Verset"
      final pattern2 = RegExp(r'^(.+?)\.(\d+)\.(\d+)$');
      final match2 = pattern2.firstMatch(reference);
      
      if (match2 != null) {
        return VerseKey(
          book: match2.group(1)!.trim(),
          chapter: int.parse(match2.group(2)!),
          verse: int.parse(match2.group(3)!),
        );
      }
      
      return null;
    } catch (e) {
      print('⚠️ Erreur parsing référence "$reference": $e');
      return null;
    }
  }
  
  /// Convertit depuis un ID standardisé
  static VerseKey? fromId(String id) {
    return parse(id);
  }
  
  /// Crée une plage de versets
  static VerseRange range({
    required String book,
    required int chapter,
    required int startVerse,
    required int endVerse,
  }) {
    return VerseRange(
      book: book,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseKey &&
          runtimeType == other.runtimeType &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse;
  
  @override
  int get hashCode => book.hashCode ^ chapter.hashCode ^ verse.hashCode;
  
  @override
  String toString() => reference;
}

/// Plage de versets (ex: Jean 3:16-18)
class VerseRange {
  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;
  
  VerseRange({
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  });
  
  /// ID de la plage : "Livre.Chapitre.Début-Fin"
  String get id => '$book.$chapter.$startVerse-$endVerse';
  
  /// Référence lisible
  String get reference => '$book $chapter:$startVerse-$endVerse';
  
  /// Liste de tous les VerseKey dans la plage
  List<VerseKey> get verses {
    final list = <VerseKey>[];
    for (int v = startVerse; v <= endVerse; v++) {
      list.add(VerseKey(book: book, chapter: chapter, verse: v));
    }
    return list;
  }
  
  /// Liste de tous les IDs
  List<String> get verseIds => verses.map((v) => v.id).toList();
  
  @override
  String toString() => reference;
}

