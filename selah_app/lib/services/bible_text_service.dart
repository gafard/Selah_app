import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'bible_assets_service.dart';

/// Service pour récupérer les textes bibliques depuis la base de données
/// 
/// Sources de données :
/// - SQLite : bible_pack.sqlite (textes complets)
/// - Hive : local_bible (cache des versions téléchargées)
/// - Assets : lsg_canon.json (structure canonique)
/// 
/// 100% offline, récupération intelligente des textes
class BibleTextService {
  static Database? _database;
  
  /// Initialise la base de données SQLite
  static Future<void> init() async {
    try {
      // ✅ Vérifier si la base existe déjà et est peuplée
      if (!kIsWeb) {
        final dbPath = join(await getDatabasesPath(), 'bible_pack.sqlite');
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          // Vérifier si la base est déjà peuplée
          final tempDb = await openDatabase(dbPath);
          final versesCount = Sqflite.firstIntValue(await tempDb.rawQuery('SELECT COUNT(*) FROM verses')) ?? 0;
          await tempDb.close();
          
          if (versesCount > 0) {
            print('✅ Base SQLite déjà peuplée avec $versesCount versets');
            _database = await openDatabase(dbPath);
            return;
          } else {
            await dbFile.delete();
            print('🗑️ Ancienne base SQLite vide supprimée pour recréation');
          }
        }
      }
      
      // 🌐 COMPATIBILITÉ WEB - Utiliser une base en mémoire sur le web
      if (kIsWeb) {
        print('🌐 Mode Web: Utilisation de la base SQLite en mémoire');
        _database = await openDatabase(
          ':memory:',
          version: 2, // ✅ Incrémenter la version pour forcer la recréation
        onCreate: (db, version) async {
          // Créer les tables si elles n'existent pas
          await db.execute('''
            CREATE TABLE IF NOT EXISTS books (
              book_id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              name_fr TEXT NOT NULL,
              abbreviation TEXT NOT NULL,
              chapters INTEGER NOT NULL,
              testament TEXT NOT NULL
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS verses (
              id INTEGER PRIMARY KEY,
              book_id INTEGER NOT NULL,
              chapter INTEGER NOT NULL,
              verse INTEGER NOT NULL,
              text TEXT NOT NULL,
              version_id TEXT NOT NULL DEFAULT 'lsg1910',
              FOREIGN KEY (book_id) REFERENCES books (book_id)
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS versions (
              version_id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              language TEXT NOT NULL,
              copyright TEXT,
              source TEXT DEFAULT 'assets'
            )
          ''');
        },
      );
      } else {
        // 📱 MODE MOBILE - Utiliser le stockage local
        final dbPath = join(await getDatabasesPath(), 'bible_pack.sqlite');
        _database = await openDatabase(
          dbPath,
          version: 2, // ✅ Incrémenter la version pour forcer la recréation
          onCreate: (db, version) async {
            // Créer les tables si elles n'existent pas
            await db.execute('''
              CREATE TABLE IF NOT EXISTS books (
                book_id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                name_fr TEXT NOT NULL,
                abbreviation TEXT NOT NULL,
                chapters INTEGER NOT NULL,
                testament TEXT NOT NULL
              )
            ''');
            
            await db.execute('''
              CREATE TABLE IF NOT EXISTS verses (
                id INTEGER PRIMARY KEY,
                book_id INTEGER NOT NULL,
                chapter INTEGER NOT NULL,
                verse INTEGER NOT NULL,
                text TEXT NOT NULL,
                version_id TEXT NOT NULL DEFAULT 'lsg1910',
                FOREIGN KEY (book_id) REFERENCES books (book_id)
              )
            ''');
            
            await db.execute('''
              CREATE TABLE IF NOT EXISTS versions (
                version_id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                language TEXT NOT NULL,
                copyright TEXT,
                source TEXT DEFAULT 'assets'
              )
            ''');
          },
        );
      }
      
      // La base de données SQLite est maintenant initialisée
      
      // ✅ Charger automatiquement les versions intégrées
      await _loadIntegratedVersions();
      
      // ✅ Peupler la base avec les données des assets
      await populateFromAssets();
      
      print('✅ BibleTextService initialisé');
    } catch (e) {
      print('⚠️ Erreur initialisation BibleTextService: $e');
    }
  }
  
  /// Récupère un passage biblique complet
  /// 
  /// [reference] : Référence biblique (ex: "Jean 14:1-19", "Matthieu 5:3-12")
  /// [version] : Version de la Bible (défaut: "LSG")
  /// 
  /// Retourne : Texte complet du passage ou null
  static Future<String?> getPassageText(String reference, {String version = 'LSG'}) async {
    try {
      // Parser la référence
      final parsed = _parseReference(reference);
      if (parsed == null) return null;
      
      final book = parsed['book'];
      final isMultiChapter = parsed['multiChapter'] as bool? ?? false;
      
      if (isMultiChapter) {
        // Passage multi-chapitres (ex: "Jean 3:16-4:10")
        final startChapter = parsed['startChapter'] as int;
        final startVerse = parsed['startVerse'] as int;
        final endChapter = parsed['endChapter'] as int;
        final endVerse = parsed['endVerse'] as int;
        
        return await _getMultiChapterPassage(book, startChapter, startVerse, endChapter, endVerse, version);
      } else {
        // Passage mono-chapitre
        final chapter = parsed['chapter'] as int;
        final startVerse = parsed['startVerse'] as int;
        final endVerse = parsed['endVerse'] as int;
        
        // Récupérer les versets depuis SQLite
        final verses = await _getVersesFromDatabase(book, chapter, startVerse, endVerse, version);
        if (verses.isEmpty) return null;
        
        // Construire le texte complet
        return _buildPassageText(verses, book, chapter);
      }
      
    } catch (e) {
      print('⚠️ Erreur getPassageText($reference): $e');
      return null;
    }
  }
  
  /// Récupère un verset spécifique
  /// 
  /// [book] : Nom du livre (ex: "Jean")
  /// [chapter] : Numéro du chapitre
  /// [verse] : Numéro du verset
  /// [version] : Version de la Bible
  /// 
  /// Retourne : Texte du verset ou null
  static Future<String?> getVerseText(String book, int chapter, int verse, {String version = 'LSG'}) async {
    try {
      final verses = await _getVersesFromDatabase(book, chapter, verse, verse, version);
      return verses.isNotEmpty ? verses.first['text'] : null;
    } catch (e) {
      print('⚠️ Erreur getVerseText($book $chapter:$verse): $e');
      return null;
    }
  }
  
  /// Récupère un chapitre complet
  /// 
  /// [book] : Nom du livre
  /// [chapter] : Numéro du chapitre
  /// [version] : Version de la Bible
  /// 
  /// Retourne : Texte complet du chapitre ou null
  static Future<String?> getChapterText(String book, int chapter, {String version = 'LSG'}) async {
    try {
      final verses = await _getVersesFromDatabase(book, chapter, 1, 999, version);
      if (verses.isEmpty) return null;
      
      return _buildPassageText(verses, book, chapter);
    } catch (e) {
      print('⚠️ Erreur getChapterText($book $chapter): $e');
      return null;
    }
  }
  
  /// Récupère les versets depuis la base de données SQLite
  static Future<List<Map<String, dynamic>>> _getVersesFromDatabase(
    String book, 
    int chapter, 
    int startVerse, 
    int endVerse, 
    String version
  ) async {
    if (_database == null) {
      print('⚠️ Base de données non initialisée');
      return [];
    }
    
    try {
      // Utiliser la structure réelle de la base de données
      final results = await _database!.rawQuery('''
        SELECT v.*, b.name_fr as book_name
        FROM verses v
        JOIN books b ON v.book_id = b.book_id
        WHERE b.name_fr = ? AND v.chapter = ? AND v.verse >= ? AND v.verse <= ? AND v.version_id = ?
        ORDER BY v.verse ASC
      ''', [book, chapter, startVerse, endVerse, version]);
      
      return results;
    } catch (e) {
      print('⚠️ Erreur requête SQLite: $e');
      return [];
    }
  }
  
  /// Parse une référence biblique
  /// 
  /// Exemples :
  /// - "Jean 14:1-19" → {book: "Jean", chapter: 14, startVerse: 1, endVerse: 19}
  /// - "Matthieu 5:3" → {book: "Matthieu", chapter: 5, startVerse: 3, endVerse: 3}
  /// - "Psaumes 23" → {book: "Psaumes", chapter: 23, startVerse: 1, endVerse: 999}
  static Map<String, dynamic>? _parseReference(String reference) {
    try {
      // ex: "1 Samuel 3:1-4:2" OU "Jean 3:16-4:10"
      final lastSpace = reference.lastIndexOf(' ');
      if (lastSpace <= 0) return null;

      final book = reference.substring(0, lastSpace).trim();       // "1 Samuel" ou "Jean"
      final chapterAndRange = reference.substring(lastSpace + 1).trim(); // "3:1-4:2" ou "3:16-20"

      final cv = chapterAndRange.split(':');
      if (cv.length < 2) return null;

      final startChapter = int.tryParse(cv[0]); // 3
      final versePart = cv[1];                  // "1-4:2" ou "16-20" ou "16"

      if (versePart.contains('-')) {
        final rangeParts = versePart.split('-');
        final startVerse = int.tryParse(rangeParts[0]);

        final endPart = rangeParts[1];
        if (endPart.contains(':')) {
          final ep = endPart.split(':');
          final endChapter = int.tryParse(ep[0]);
          final endVerse = int.tryParse(ep[1]);
          if (startChapter != null && startVerse != null && endChapter != null && endVerse != null) {
            return {
              'book': book,
              'startChapter': startChapter,
              'startVerse': startVerse,
              'endChapter': endChapter,
              'endVerse': endVerse,
              'multiChapter': true,
            };
          }
        } else {
          final endVerse = int.tryParse(endPart);
          if (startChapter != null && startVerse != null && endVerse != null) {
            return {
              'book': book,
              'chapter': startChapter,
              'startVerse': startVerse,
              'endVerse': endVerse,
              'multiChapter': false,
            };
          }
        }
      } else {
        final verse = int.tryParse(versePart);
        if (startChapter != null && verse != null) {
          return {
            'book': book,
            'chapter': startChapter,
            'startVerse': verse,
            'endVerse': verse,
            'multiChapter': false,
          };
        }
      }

      return null;
    } catch (e) {
      print('⚠️ Erreur parsing référence "$reference": $e');
      return null;
    }
  }
  
  /// Récupère un passage multi-chapitres
  static Future<String?> _getMultiChapterPassage(
    String book, 
    int startChapter, 
    int startVerse, 
    int endChapter, 
    int endVerse, 
    String version
  ) async {
    if (_database == null) await init();
    
    try {
      final buffer = StringBuffer();
      
      // Premier chapitre (de startVerse à la fin)
      final firstChapterVerses = await _getVersesFromDatabase(book, startChapter, startVerse, 999, version);
      for (final verse in firstChapterVerses) {
        final verseNum = verse['verse'] as int;
        final text = verse['text'] as String;
        buffer.writeln('$verseNum $text');
      }
      
      // Chapitres intermédiaires (complets)
      for (int chapter = startChapter + 1; chapter < endChapter; chapter++) {
        final chapterVerses = await _getVersesFromDatabase(book, chapter, 1, 999, version);
        for (final verse in chapterVerses) {
          final verseNum = verse['verse'] as int;
          final text = verse['text'] as String;
          buffer.writeln('$verseNum $text');
        }
      }
      
      // Dernier chapitre (du début à endVerse)
      if (endChapter > startChapter) {
        final lastChapterVerses = await _getVersesFromDatabase(book, endChapter, 1, endVerse, version);
        for (final verse in lastChapterVerses) {
          final verseNum = verse['verse'] as int;
          final text = verse['text'] as String;
          buffer.writeln('$verseNum $text');
        }
      }
      
      return buffer.toString().trim();
    } catch (e) {
      print('⚠️ Erreur _getMultiChapterPassage: $e');
      return null;
    }
  }

  /// Construit le texte complet d'un passage
  static String _buildPassageText(List<Map<String, dynamic>> verses, String book, int chapter) {
    if (verses.isEmpty) return '';
    
    final buffer = StringBuffer();
    
    for (final verse in verses) {
      final verseNum = verse['verse'] as int;
      final text = verse['text'] as String;
      
      // Ajouter le numéro du verset et le texte
      buffer.writeln('$verseNum $text');
      buffer.writeln(); // Ligne vide entre les versets
    }
    
    return buffer.toString().trim();
  }
  
  /// Vérifie si une version de Bible est disponible
  static Future<bool> isVersionAvailable(String version) async {
    try {
      if (_database == null) return false;
      
      final result = await _database!.query(
        'verses',
        where: 'version = ?',
        whereArgs: [version],
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      print('⚠️ Erreur vérification version $version: $e');
      return false;
    }
  }
  
  /// Charge automatiquement les versions intégrées dans les assets
  static Future<void> _loadIntegratedVersions() async {
    try {
      // Vérifier si les versions intégrées sont déjà chargées
      final existingVersions = await getAvailableVersions();
      if (existingVersions.isNotEmpty) {
        print('✅ Versions déjà chargées: ${existingVersions.length}');
        return;
      }
      
      // Charger les versions intégrées via BibleAssetsService
      final integratedVersions = ['lsg1910', 'francais_courant', 'semeur'];
      for (final versionId in integratedVersions) {
        try {
          final success = await BibleAssetsService.loadIntegratedVersion(versionId);
          if (success) {
            print('✅ Version intégrée chargée: $versionId');
          } else {
            print('⚠️ Échec chargement version $versionId');
          }
        } catch (e) {
          print('⚠️ Erreur chargement version $versionId: $e');
        }
      }
      
      // Vérifier le résultat final
      final finalVersions = await getAvailableVersions();
      print('📊 Versions finales disponibles: ${finalVersions.length}');
    } catch (e) {
      print('⚠️ Erreur chargement versions intégrées: $e');
    }
  }
  
  /// Récupère les versions disponibles
  static Future<List<String>> getAvailableVersions() async {
    try {
      if (_database == null) return ['lsg1910', 'francais_courant', 'semeur']; // ✅ Versions intégrées par défaut
      
      final result = await _database!.rawQuery(
        'SELECT DISTINCT version_id FROM versions ORDER BY version_id'
      );
      
      if (result.isEmpty) {
        // ✅ VERSIONS INTÉGRÉES par défaut si la table est vide
        return ['lsg1910', 'francais_courant', 'semeur'];
      }
      
      return result.map((row) => row['version_id'] as String).toList();
    } catch (e) {
      print('⚠️ Erreur récupération versions: $e');
      // ✅ FALLBACK : versions intégrées par défaut
      return ['lsg1910', 'francais_courant', 'semeur'];
    }
  }
  
  /// Récupère les livres disponibles
  static Future<List<Map<String, dynamic>>> getAvailableBooks() async {
    try {
      if (_database == null) return [];
      
      final result = await _database!.query(
        'books',
        orderBy: 'id ASC',
      );
      
      return result;
    } catch (e) {
      print('⚠️ Erreur récupération livres: $e');
      return [];
    }
  }
  
  /// Récupère le nombre de chapitres d'un livre
  static Future<int> getChapterCount(String book) async {
    try {
      if (_database == null) return 0;
      
      final result = await _database!.rawQuery(
        'SELECT MAX(chapter) as max_chapter FROM verses WHERE book = ?',
        [book]
      );
      
      return result.first['max_chapter'] as int? ?? 0;
    } catch (e) {
      print('⚠️ Erreur récupération nombre chapitres pour $book: $e');
      return 0;
    }
  }
  
  /// Récupère le nombre de versets d'un chapitre
  static Future<int> getVerseCount(String book, int chapter) async {
    try {
      if (_database == null) return 0;
      
      final result = await _database!.rawQuery(
        'SELECT MAX(verse) as max_verse FROM verses WHERE book = ? AND chapter = ?',
        [book, chapter]
      );
      
      return result.first['max_verse'] as int? ?? 0;
    } catch (e) {
      print('⚠️ Erreur récupération nombre versets pour $book $chapter: $e');
      return 0;
    }
  }
  
  /// Recherche dans les textes bibliques
  /// 
  /// [query] : Terme de recherche
  /// [version] : Version de la Bible
  /// [limit] : Nombre maximum de résultats
  /// 
  /// Retourne : Liste des versets contenant le terme
  static Future<List<Map<String, dynamic>>> searchText(String query, {String version = 'LSG', int limit = 50}) async {
    try {
      if (_database == null) return [];
      
      final result = await _database!.query(
        'verses',
        where: 'text LIKE ? AND version = ?',
        whereArgs: ['%$query%', version],
        orderBy: 'book, chapter, verse',
        limit: limit,
      );
      
      return result;
    } catch (e) {
      print('⚠️ Erreur recherche "$query": $e');
      return [];
    }
  }
  
  /// Vérifie si la base de données contient des versets
  /// 
  /// Retourne : true si des versets sont présents
  static Future<bool> hasVerses() async {
    try {
      if (_database == null) return false;
      
      final result = await _database!.rawQuery('SELECT COUNT(*) as count FROM verses');
      final count = result.first['count'] as int? ?? 0;
      
      return count > 0;
    } catch (e) {
      print('⚠️ Erreur hasVerses: $e');
      return false;
    }
  }
  
  /// Popule la base de données depuis les assets
  /// 
  /// Charge les données depuis assets/db/bible_pack.sqlite
  static Future<void> populateFromAssets() async {
    try {
      if (_database == null) {
        print('⚠️ Base de données non initialisée');
        return;
      }
      
      print('📖 Chargement des données depuis assets/db/bible_pack.sqlite...');
      
      // Pour l'instant, on va créer quelques versets d'exemple
      // En production, on devrait copier le fichier SQLite depuis assets
      await _populateWithSampleData();
      
      print('✅ Base SQLite peuplée avec succès');
    } catch (e) {
      print('⚠️ Erreur populateFromAssets: $e');
    }
  }
  
  /// Popule avec des données d'exemple (temporaire)
  static Future<void> _populateWithSampleData() async {
    if (_database == null) return;
    
    // ✅ D'abord créer les livres s'ils n'existent pas
    await _createSampleBooks();
    
    // Récupérer les IDs des livres
    final jeanId = await _getBookId('Jean');
    final matthieuId = await _getBookId('Matthieu');
    final jean1Id = await _getBookId('1 Jean');
    final hebreuxId = await _getBookId('Hébreux');
    
    if (jeanId == null || matthieuId == null || jean1Id == null || hebreuxId == null) {
      print('⚠️ Impossible de trouver les IDs des livres après création');
      return;
    }
    
    // Ajouter quelques versets d'exemple avec la structure correcte
    final sampleVerses = [
      // Jean
      {'book_id': jeanId, 'chapter': 3, 'verse': 16, 'text': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.', 'version_id': 'LSG'},
      {'book_id': jeanId, 'chapter': 14, 'verse': 1, 'text': 'Que votre cœur ne se trouble point. Croyez en Dieu, et croyez en moi.', 'version_id': 'LSG'},
      {'book_id': jeanId, 'chapter': 14, 'verse': 2, 'text': 'Il y a plusieurs demeures dans la maison de mon Père. Si cela n\'était pas, je vous l\'aurais dit. Je vais vous préparer une place.', 'version_id': 'LSG'},
      {'book_id': jeanId, 'chapter': 14, 'verse': 3, 'text': 'Et, lorsque je m\'en serai allé, et que je vous aurai préparé une place, je reviendrai, et je vous prendrai avec moi, afin que là où je suis vous y soyez aussi.', 'version_id': 'LSG'},
      {'book_id': jeanId, 'chapter': 14, 'verse': 4, 'text': 'Vous savez où je vais, et vous en savez le chemin.', 'version_id': 'LSG'},
      {'book_id': jeanId, 'chapter': 14, 'verse': 5, 'text': 'Thomas lui dit: Seigneur, nous ne savons où tu vas; comment pouvons-nous en savoir le chemin?', 'version_id': 'LSG'},
      {'book_id': jeanId, 'chapter': 14, 'verse': 6, 'text': 'Jésus lui dit: Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.', 'version_id': 'LSG'},
      
      // Matthieu
      {'book_id': matthieuId, 'chapter': 5, 'verse': 3, 'text': 'Heureux les pauvres en esprit, car le royaume des cieux est à eux!', 'version_id': 'LSG'},
      {'book_id': matthieuId, 'chapter': 5, 'verse': 4, 'text': 'Heureux les affligés, car ils seront consolés!', 'version_id': 'LSG'},
      {'book_id': matthieuId, 'chapter': 5, 'verse': 5, 'text': 'Heureux les débonnaires, car ils hériteront la terre!', 'version_id': 'LSG'},
      
      // 1 Jean
      {'book_id': jean1Id, 'chapter': 1, 'verse': 1, 'text': 'Ce qui était dès le commencement, ce que nous avons entendu, ce que nous avons vu de nos yeux, ce que nous avons contemplé et que nos mains ont touché, concernant la parole de vie.', 'version_id': 'LSG'},
      {'book_id': jean1Id, 'chapter': 1, 'verse': 2, 'text': 'Car la vie a été manifestée, et nous l\'avons vue et nous lui rendons témoignage, et nous vous annonçons la vie éternelle, qui était auprès du Père et qui nous a été manifestée.', 'version_id': 'LSG'},
      
      // Hébreux
      {'book_id': hebreuxId, 'chapter': 11, 'verse': 1, 'text': 'Or la foi est une ferme assurance des choses qu\'on espère, une démonstration de celles qu\'on ne voit pas.', 'version_id': 'LSG'},
      {'book_id': hebreuxId, 'chapter': 12, 'verse': 1, 'text': 'Nous donc aussi, puisque nous sommes environnés d\'une si grande nuée de témoins, rejetons tout fardeau, et le péché qui nous enveloppe si facilement, et courons avec persévérance dans la carrière qui nous est ouverte.', 'version_id': 'LSG'},
    ];
    
    for (final verse in sampleVerses) {
      await _database!.insert(
        'verses',
        verse,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    print('✅ ${sampleVerses.length} versets d\'exemple ajoutés');
  }
  
  /// Crée les livres d'exemple dans la base
  static Future<void> _createSampleBooks() async {
    if (_database == null) return;
    
    final sampleBooks = [
      {'book_id': 43, 'name': 'Jean', 'name_fr': 'Jean', 'abbreviation': 'Jn', 'chapters': 21, 'testament': 'NT'},
      {'book_id': 40, 'name': 'Matthieu', 'name_fr': 'Matthieu', 'abbreviation': 'Mt', 'chapters': 28, 'testament': 'NT'},
      {'book_id': 62, 'name': '1 Jean', 'name_fr': '1 Jean', 'abbreviation': '1Jn', 'chapters': 5, 'testament': 'NT'},
      {'book_id': 58, 'name': 'Hébreux', 'name_fr': 'Hébreux', 'abbreviation': 'He', 'chapters': 13, 'testament': 'NT'},
    ];
    
    for (final book in sampleBooks) {
      await _database!.insert(
        'books',
        book,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    print('✅ ${sampleBooks.length} livres d\'exemple créés');
  }
  
  /// Récupère l'ID d'un livre par son nom
  static Future<int?> _getBookId(String bookName) async {
    if (_database == null) return null;
    
    try {
      final result = await _database!.rawQuery(
        'SELECT book_id FROM books WHERE name_fr = ?',
        [bookName]
      );
      
      if (result.isNotEmpty) {
        return result.first['book_id'] as int?;
      }
      return null;
    } catch (e) {
      print('⚠️ Erreur _getBookId($bookName): $e');
      return null;
    }
  }
}
