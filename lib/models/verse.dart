// lib/models/verse.dart

class Verse {
  final int verse;
  final String text;

  Verse({required this.verse, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      verse: json['verse'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verse': verse,
      'text': text,
    };
  }

  @override
  String toString() {
    return '$verse. $text';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Verse &&
          runtimeType == other.runtimeType &&
          verse == other.verse &&
          text == other.text;

  @override
  int get hashCode => verse.hashCode ^ text.hashCode;
}

// Classe pour gérer un chapitre complet avec ses versets
class Chapter {
  final String book;
  final int chapter;
  final List<Verse> verses;

  Chapter({
    required this.book,
    required this.chapter,
    required this.verses,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      book: json['book'] ?? '',
      chapter: json['chapter'] ?? 0,
      verses: (json['verses'] as List<dynamic>?)
          ?.map((verse) => Verse.fromJson(verse as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }

  // Getter pour obtenir la référence complète
  String get reference => '$book $chapter';

  // Getter pour obtenir le texte complet du chapitre
  String get fullText => verses.map((verse) => verse.toString()).join(' ');

  // Méthode pour obtenir un verset spécifique
  Verse? getVerse(int verseNumber) {
    try {
      return verses.firstWhere((verse) => verse.verse == verseNumber);
    } catch (e) {
      return null;
    }
  }

  // Méthode pour obtenir une plage de versets
  List<Verse> getVerseRange(int startVerse, int endVerse) {
    return verses
        .where((verse) => verse.verse >= startVerse && verse.verse <= endVerse)
        .toList();
  }

  // Méthode pour rechercher du texte dans le chapitre
  List<Verse> searchText(String query) {
    final lowerQuery = query.toLowerCase();
    return verses
        .where((verse) => verse.text.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  String toString() {
    return '$reference (${verses.length} versets)';
  }
}

// Classe pour gérer une référence biblique complète
class BibleReference {
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  BibleReference({
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });

  // Factory pour créer une référence depuis une chaîne comme "Jean 3:16"
  factory BibleReference.fromString(String reference) {
    // Exemple: "Jean 3:16" ou "Jean 3:16-17" ou "Jean 3"
    final parts = reference.trim().split(' ');
    if (parts.length < 2) {
      throw ArgumentError('Format de référence invalide: $reference');
    }

    final book = parts.sublist(0, parts.length - 1).join(' ');
    final chapterVerse = parts.last;

    if (chapterVerse.contains(':')) {
      final chapterParts = chapterVerse.split(':');
      final chapter = int.parse(chapterParts[0]);
      
      if (chapterParts[1].contains('-')) {
        final verseParts = chapterParts[1].split('-');
        return BibleReference(
          book: book,
          chapter: chapter,
          startVerse: int.parse(verseParts[0]),
          endVerse: int.parse(verseParts[1]),
        );
      } else {
        final verse = int.parse(chapterParts[1]);
        return BibleReference(
          book: book,
          chapter: chapter,
          startVerse: verse,
          endVerse: verse,
        );
      }
    } else {
      return BibleReference(
        book: book,
        chapter: int.parse(chapterVerse),
      );
    }
  }

  // Getter pour obtenir la référence formatée
  String get formatted {
    if (startVerse == null) {
      return '$book $chapter';
    } else if (startVerse == endVerse) {
      return '$book $chapter:$startVerse';
    } else {
      return '$book $chapter:$startVerse-$endVerse';
    }
  }

  // Vérifie si c'est un chapitre complet
  bool get isFullChapter => startVerse == null && endVerse == null;

  // Vérifie si c'est un seul verset
  bool get isSingleVerse => startVerse != null && startVerse == endVerse;

  // Vérifie si c'est une plage de versets
  bool get isVerseRange => startVerse != null && endVerse != null && startVerse != endVerse;

  @override
  String toString() => formatted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleReference &&
          runtimeType == other.runtimeType &&
          book == other.book &&
          chapter == other.chapter &&
          startVerse == other.startVerse &&
          endVerse == other.endVerse;

  @override
  int get hashCode =>
      book.hashCode ^ chapter.hashCode ^ startVerse.hashCode ^ endVerse.hashCode;
}

// Données de démonstration pour quelques versets populaires
class SampleVerses {
  static List<Chapter> getDemoChapters() {
    return [
      Chapter(
        book: 'Jean',
        chapter: 3,
        verses: [
          Verse(
            verse: 16,
            text: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
          ),
          Verse(
            verse: 17,
            text: 'Dieu, en effet, n\'a pas envoyé son Fils dans le monde pour qu\'il juge le monde, mais pour que le monde soit sauvé par lui.',
          ),
        ],
      ),
      Chapter(
        book: 'Psaumes',
        chapter: 23,
        verses: [
          Verse(
            verse: 1,
            text: 'L\'Éternel est mon berger: je ne manquerai de rien.',
          ),
          Verse(
            verse: 2,
            text: 'Il me fait reposer dans de verts pâturages, il me dirige près des eaux paisibles.',
          ),
          Verse(
            verse: 3,
            text: 'Il restaure mon âme, il me conduit dans les sentiers de la justice, à cause de son nom.',
          ),
        ],
      ),
      Chapter(
        book: '1 Corinthiens',
        chapter: 13,
        verses: [
          Verse(
            verse: 4,
            text: 'L\'amour est patient, il est plein de bonté; l\'amour n\'est point envieux; l\'amour ne se vante point, il ne s\'enfle point d\'orgueil,',
          ),
          Verse(
            verse: 5,
            text: 'il ne fait rien de malhonnête, il ne cherche point son intérêt, il ne s\'irrite point, il ne soupçonne point le mal,',
          ),
          Verse(
            verse: 13,
            text: 'Maintenant donc ces trois choses demeurent: la foi, l\'espérance, l\'amour; mais la plus grande de ces choses, c\'est l\'amour.',
          ),
        ],
      ),
    ];
  }

  // Méthode pour obtenir un verset aléatoire
  static Verse getRandomVerse() {
    final chapters = getDemoChapters();
    final randomChapter = chapters[DateTime.now().millisecond % chapters.length];
    final randomVerse = randomChapter.verses[DateTime.now().second % randomChapter.verses.length];
    return randomVerse;
  }

  // Méthode pour rechercher des versets par mot-clé
  static List<Verse> searchVerses(String query) {
    final chapters = getDemoChapters();
    final results = <Verse>[];
    
    for (final chapter in chapters) {
      results.addAll(chapter.searchText(query));
    }
    
    return results;
  }
}
