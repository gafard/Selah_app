/// ═══════════════════════════════════════════════════════════════════════════
/// CHAPTER INDEX LOADER - Hydratation offline robuste
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Charge les métadonnées de chapitres depuis JSON assets → Hive
/// - 66 livres supportés (voir chapter_index_registry.dart)
/// - Fallback intelligent si fichier manquant
/// - Estimation précise du temps de lecture
/// - 100% offline
/// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'chapter_index_registry.dart';

/// Hive Box keys: "$BookName:$chapter" → {"verses": int, "density": double}
class ChapterIndexLoader {
  static const String boxName = 'chapter_index';

  /// Charge tous les JSON présents dans assets/json/chapters/
  /// - Ignore silencieusement les fichiers manquants
  /// - Journalise les erreurs non bloquantes
  /// - Évite rechargements inutiles avec seed flag
  static Future<void> loadAll({bool forceReload = false}) async {
    final box = await Hive.openBox(boxName);

    // Évite rechargements inutiles
    if (!forceReload && (box.get('_seed_v1') == true)) {
      // Déjà hydraté
      return;
    }

    int loadedBooks = 0;
    int loadedChapters = 0;

    for (final book in ChapterIndexRegistry.books) {
      final assetPath = 'assets/json/chapters/${book.slug}.json';
      
      try {
        final raw = await rootBundle.loadString(assetPath);
        final Map<String, dynamic> data = json.decode(raw);

        int chaptersForBook = 0;
        
        data.forEach((chapter, meta) {
          final m = Map<String, dynamic>.from(meta as Map);
          final verses = (m['verses'] is int) ? m['verses'] as int : 25;
          final density = (m['density'] is num) 
              ? (m['density'] as num).toDouble() 
              : 1.0;

          box.put('${book.name}:$chapter', {
            'verses': verses,
            'density': density,
          });
          
          chaptersForBook++;
        });

        loadedBooks++;
        loadedChapters += chaptersForBook;
        
        // Log optionnel (décommenter si debug)
        // print('✅ ${book.name} importé ($chaptersForBook chap.)');
        
      } catch (e) {
        // Asset manquant ou JSON invalide → on ignore pour ne pas bloquer l'app
        // Log optionnel (décommenter si debug)
        // print('ℹ️ Skipped ${book.name} ($assetPath): $e');
        continue;
      }
    }

    await box.put('_seed_v1', true);
    await box.put('_loaded_books', loadedBooks);
    await box.put('_loaded_chapters', loadedChapters);
    
    print('📦 ChapterIndexLoader → $loadedBooks livres, $loadedChapters chapitres hydratés.');
  }

  /// Nombre de versets pour (livre, chapitre)
  /// 
  /// Retourne le nombre exact de versets ou fallback à 25 si donnée manquante
  static int verseCount(String book, int chapter) {
    final box = Hive.box(boxName);
    final meta = box.get('$book:$chapter') as Map?;
    
    if (meta == null) return 25; // Fallback intelligent
    
    return (meta['verses'] as int?) ?? 25;
  }

  /// Densité textuelle pour (livre, chapitre?)
  /// 
  /// - Si chapitre null, essaie chapitre 1
  /// - Retourne: 1.0 = moyenne, >1.0 = dense (théologie), <1.0 = narratif
  static double density(String book, [int? chapter]) {
    final box = Hive.box(boxName);
    final key = chapter == null ? '$book:1' : '$book:$chapter';
    final meta = box.get(key) as Map?;
    
    if (meta == null) return 1.0; // Fallback
    
    return (meta['density'] as num?)?.toDouble() ?? 1.0;
  }

  /// Estimation du temps de lecture en minutes
  /// 
  /// Paramètres:
  /// - book: Nom du livre (ex: "Luc")
  /// - chapter: Numéro du chapitre
  /// - baseMinutes: Minutes de base pour 25 versets à densité 1.0 (défaut: 6)
  /// 
  /// Formule: baseMinutes × (versets/25) × densité
  /// 
  /// Exemples:
  /// - Luc 15 (32 versets, densité 1.3): 6 × 1.28 × 1.3 ≈ 10 min
  /// - Romains 8 (39 versets, densité 1.25): 6 × 1.56 × 1.25 ≈ 12 min
  /// - Genèse 1 (31 versets, densité 0.9): 6 × 1.24 × 0.9 ≈ 7 min
  static int estimateMinutes({
    required String book,
    required int chapter,
    int baseMinutes = 6,
  }) {
    final v = verseCount(book, chapter);
    final d = density(book, chapter);
    final factorVerses = v / 25.0;
    final est = (baseMinutes * factorVerses * d);
    
    return est.ceil();
  }

  /// Estimation pour une plage de chapitres
  /// 
  /// Utile pour calculer le temps total d'un plan de lecture
  static int estimateMinutesRange({
    required String book,
    required int startChapter,
    required int endChapter,
    int baseMinutes = 6,
  }) {
    int totalMinutes = 0;
    
    for (int ch = startChapter; ch <= endChapter; ch++) {
      totalMinutes += estimateMinutes(
        book: book,
        chapter: ch,
        baseMinutes: baseMinutes,
      );
    }
    
    return totalMinutes;
  }

  /// Stats de l'hydratation
  static Map<String, dynamic> getStats() {
    final box = Hive.box(boxName);
    
    return {
      'seeded': box.get('_seed_v1', defaultValue: false),
      'loadedBooks': box.get('_loaded_books', defaultValue: 0),
      'loadedChapters': box.get('_loaded_chapters', defaultValue: 0),
      'totalBooksAvailable': ChapterIndexRegistry.totalBooks,
    };
  }

  /// Vérifier si un livre est chargé
  static bool isBookLoaded(String book) {
    final box = Hive.box(boxName);
    // Vérifie si au moins le chapitre 1 existe
    return box.containsKey('$book:1');
  }

  /// Liste des livres effectivement chargés
  static List<String> loadedBooks() {
    final box = Hive.box(boxName);
    final loaded = <String>[];
    
    for (final book in ChapterIndexRegistry.books) {
      if (box.containsKey('${book.name}:1')) {
        loaded.add(book.name);
      }
    }
    
    return loaded;
  }

  /// Forcer le rechargement (utile pour debug ou mise à jour)
  static Future<void> reload() async {
    final box = await Hive.openBox(boxName);
    await box.clear();
    await loadAll(forceReload: true);
  }

  /// Helper: Nombre total de versets dans un livre
  /// 
  /// Nécessite de connaître le nombre de chapitres (passé en paramètre)
  static int totalVersesInBook({
    required String book,
    required int totalChapters,
  }) {
    int total = 0;
    
    for (int ch = 1; ch <= totalChapters; ch++) {
      total += verseCount(book, ch);
    }
    
    return total;
  }

  /// Helper: Densité moyenne du livre
  static double averageDensity({
    required String book,
    required int totalChapters,
  }) {
    double sum = 0;
    
    for (int ch = 1; ch <= totalChapters; ch++) {
      sum += density(book, ch);
    }
    
    return sum / totalChapters;
  }
}


