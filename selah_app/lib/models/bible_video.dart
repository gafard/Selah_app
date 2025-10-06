// lib/models/bible_video.dart

class BibleVideo {
  final String id;
  final String title;
  final String description;
  final String youtubeId;
  final String thumbnailUrl;
  final int durationSeconds;
  final List<String> relatedBooks;
  final String category; // 'book_overview', 'theme', 'character', etc.
  final DateTime createdAt;

  BibleVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeId,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.relatedBooks,
    required this.category,
    required this.createdAt,
  });

  factory BibleVideo.fromJson(Map<String, dynamic> json) {
    return BibleVideo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      youtubeId: json['youtube_id'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      durationSeconds: json['duration_seconds'] ?? 0,
      relatedBooks: List<String>.from(json['related_books'] ?? []),
      category: json['category'] ?? 'book_overview',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'youtube_id': youtubeId,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'related_books': relatedBooks,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Getters utiles
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get categoryDisplayName {
    switch (category) {
      case 'book_overview':
        return 'Aperçu du livre';
      case 'theme':
        return 'Thème biblique';
      case 'character':
        return 'Personnage biblique';
      case 'series':
        return 'Série';
      default:
        return 'Vidéo';
    }
  }

  // Vérifie si cette vidéo est pertinente pour une lecture donnée
  bool isRelevantFor(List<String> bibleReferences) {
    for (final reference in bibleReferences) {
      for (final book in relatedBooks) {
        if (reference.toLowerCase().contains(book.toLowerCase())) {
          return true;
        }
      }
    }
    return false;
  }
}

// Données de démonstration pour les vidéos BibleProject populaires
class BibleProjectVideos {
  static List<BibleVideo> getDemoVideos() {
    return [
      BibleVideo(
        id: 'demo_genesis',
        title: 'Genèse 1-11',
        description: 'Découvrez les premiers chapitres de la Genèse et leurs messages profonds sur la création, la chute et l\'espoir.',
        youtubeId: 'GQI72THyO5I',
        thumbnailUrl: 'https://img.youtube.com/vi/GQI72THyO5I/maxresdefault.jpg',
        durationSeconds: 510, // 8:30
        relatedBooks: ['Genèse'],
        category: 'book_overview',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      BibleVideo(
        id: 'demo_psalms',
        title: 'Les Psaumes',
        description: 'Une introduction aux Psaumes, le livre de prières et de louanges d\'Israël.',
        youtubeId: 'j9phNEaPrv8',
        thumbnailUrl: 'https://img.youtube.com/vi/j9phNEaPrv8/maxresdefault.jpg',
        durationSeconds: 420, // 7:00
        relatedBooks: ['Psaumes'],
        category: 'book_overview',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      BibleVideo(
        id: 'demo_gospel_matthew',
        title: 'L\'Évangile selon Matthieu',
        description: 'Découvrez comment Matthieu présente Jésus comme le Messie promis d\'Israël.',
        youtubeId: 'GGCF3OPWN14',
        thumbnailUrl: 'https://img.youtube.com/vi/GGCF3OPWN14/maxresdefault.jpg',
        durationSeconds: 480, // 8:00
        relatedBooks: ['Matthieu'],
        category: 'book_overview',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      BibleVideo(
        id: 'demo_love_theme',
        title: 'L\'Amour dans la Bible',
        description: 'Explorez le thème de l\'amour divin à travers toute l\'Écriture.',
        youtubeId: 'iyn2gOozM_c',
        thumbnailUrl: 'https://img.youtube.com/vi/iyn2gOozM_c/maxresdefault.jpg',
        durationSeconds: 360, // 6:00
        relatedBooks: ['1 Corinthiens', '1 Jean', 'Romains'],
        category: 'theme',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      BibleVideo(
        id: 'demo_heaven_earth',
        title: 'Ciel et Terre',
        description: 'Comprenez la vision biblique de l\'union entre le ciel et la terre.',
        youtubeId: '8BxM2I95OGo',
        thumbnailUrl: 'https://img.youtube.com/vi/8BxM2I95OGo/maxresdefault.jpg',
        durationSeconds: 390, // 6:30
        relatedBooks: ['Genèse', 'Apocalypse', 'Ésaïe'],
        category: 'theme',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  // Trouve les vidéos pertinentes pour une lecture donnée
  static List<BibleVideo> getVideosForReading(List<String> bibleReferences) {
    final allVideos = getDemoVideos();
    return allVideos.where((video) => video.isRelevantFor(bibleReferences)).toList();
  }

  // Obtient les vidéos par catégorie
  static List<BibleVideo> getVideosByCategory(String category) {
    final allVideos = getDemoVideos();
    return allVideos.where((video) => video.category == category).toList();
  }
}
