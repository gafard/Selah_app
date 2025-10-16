import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:json5/json5.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Schéma attendu (tolérant):
/// {
///   Abbreviation:"LSG", Language:"fr", VersionDate:"20121010000000", ...,
///   Testaments: [ { Books:[ { Chapters:[ { Verses:[ {Text:"..." , ID?:int} ... ] } ... ] } ... ] }, ... ]
/// }
///
/// Pas de nom de livre => on affecte selon l'ordre canonique (FR).

class BibleAssetImporter {
  BibleAssetImporter(this.db);

  final Database db;

  /// Ordre canonique (FR – protestant) : 39 OT + 27 NT
  static const List<String> _ot = [
    'Genèse','Exode','Lévitique','Nombres','Deutéronome','Josué','Juges','Ruth',
    '1 Samuel','2 Samuel','1 Rois','2 Rois','1 Chroniques','2 Chroniques',
    'Esdras','Néhémie','Esther','Job','Psaumes','Proverbes','Ecclésiaste','Cantique des Cantiques',
    'Ésaïe','Jérémie','Lamentations','Ézéchiel','Daniel','Osée','Joël','Amos','Abdias',
    'Jonas','Michée','Nahum','Habacuc','Sophonie','Aggée','Zacharie','Malachie'
  ];

  static const List<String> _nt = [
    'Matthieu','Marc','Luc','Jean','Actes','Romains','1 Corinthiens','2 Corinthiens','Galates',
    'Éphésiens','Philippiens','Colossiens','1 Thessaloniciens','2 Thessaloniciens','1 Timothée','2 Timothée',
    'Tite','Philémon','Hébreux','Jacques','1 Pierre','2 Pierre','1 Jean','2 Jean','3 Jean','Jude','Apocalypse'
  ];

  static const List<String> _allBooks = [..._ot, ..._nt];

  /// Vérifie/Crée la table
  static Future<void> ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS verses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version TEXT NOT NULL,
        book TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL,
        UNIQUE(version, book, chapter, verse)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_v ON verses(version,book,chapter,verse)');
  }

  /// Renvoie true si cette version est déjà importée (≥ 30k versets ≈ Bible entière)
  static Future<bool> isVersionImported(Database db, String versionId) async {
    final x = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM verses WHERE version = ?', [versionId]));
    return (x ?? 0) > 30000;
  }

  /// Import d'un asset JSON/JSON5 « loose »
  static Future<void> importFromAsset({
    required Database db,
    required String assetPath,
    String? forceVersionId, // ex: lsg1910 / semeur / fc
  }) async {
    await ensureSchema(db);

    final raw = await rootBundle.loadString(assetPath);
    // tolère clés non-quotées/virgules finales
    final Map<String, dynamic> data = Map<String, dynamic>.from(JSON5.parse(raw));

    final metaAbbr = (data['Abbreviation'] ?? data['abbr'] ?? forceVersionId ?? 'unknown').toString().trim();
    final versionId = _normalizeVersionId(metaAbbr);

    // si déjà importée, on n'insère pas deux fois
    if (await isVersionImported(db, versionId)) {
      print('📚 Version "$versionId" déjà importée — skip');
      return;
    }

    final testaments = (data['Testaments'] ?? data['testaments']) as List?;
    if (testaments == null || testaments.isEmpty) {
      throw Exception('Format invalide: champ Testaments manquant');
    }

    // On a pas de noms de livres => on mappe par position.
    // Sécurité: on tolère moins/plus de 39/27 si nécessaire, mais on tronque à l'ordre canonique.
    final books = <Map<String, dynamic>>[];
    for (final t in testaments) {
      final tb = (t['Books'] ?? t['books']) as List? ?? const [];
      for (final b in tb) {
        books.add(Map<String, dynamic>.from(b));
      }
    }

    if (books.isEmpty) {
      throw Exception('Aucun livre trouvé dans Testaments[].Books[]');
    }

    final batch = db.batch();
    int bookIndex = 0;

    for (final bookObj in books) {
      if (bookIndex >= _allBooks.length) break; // sécurité
      final bookName = _allBooks[bookIndex];

      final chapters = (bookObj['Chapters'] ?? bookObj['chapters']) as List? ?? const [];
      if (chapters.isEmpty) {
        bookIndex++;
        continue;
      }

      int chapterIndex = 1;
      for (final chObj in chapters) {
        final verses = (chObj['Verses'] ?? chObj['verses']) as List? ?? const [];
        if (verses.isEmpty) {
          chapterIndex++;
          continue;
        }

        int verseIdx = 1;
        for (final vObj in verses) {
          // formats possibles: {Text:"..." [,ID:n]}
          final map = Map<String, dynamic>.from(vObj as Map);
          final txt = (map['Text'] ?? map['text'] ?? '').toString();
          final id = map['ID'] ?? map['id'];
          final verseNo = id is int ? id : verseIdx;

          if (txt.trim().isEmpty) {
            verseIdx++;
            continue;
          }

          batch.insert(
            'verses',
            {
              'version': versionId,
              'book': bookName,
              'chapter': chapterIndex,
              'verse': verseNo,
              'text': txt,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          verseIdx++;
        }

        chapterIndex++;
      }

      bookIndex++;
    }

    await batch.commit(noResult: true);
    
    // Optimiser la base après import
    await db.execute('PRAGMA optimize');
    
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM verses WHERE version = ?', [versionId]));
    print('✅ Import "$versionId" terminé — ${count ?? 0} versets');
  }

  /// Force la réimportation d'une version (pour dev/QA)
  static Future<void> forceReimport({
    required Database db,
    required String assetPath,
    String? forceVersionId,
  }) async {
    final versionId = _normalizeVersionId(
      forceVersionId ?? _guessVersionFromPath(assetPath)
    );
    
    print('🔄 Réimport forcé de "$versionId"...');
    
    // Supprimer les versets existants pour cette version
    await db.delete('verses', where: 'version = ?', whereArgs: [versionId]);
    
    // VACUUM pour récupérer l'espace
    await db.execute('VACUUM');
    
    // Réimporter
    await importFromAsset(
      db: db,
      assetPath: assetPath,
      forceVersionId: forceVersionId,
    );
    
    print('✅ Réimport forcé de "$versionId" terminé');
  }

  static String _guessVersionFromPath(String path) {
    if (path.contains('lsg1910')) return 'lsg1910';
    if (path.contains('semeur')) return 'semeur';
    if (path.contains('francais_courant')) return 'francais_courant';
    return 'unknown';
  }

  static String _normalizeVersionId(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('semeur')) return 'semeur';
    if (lower.contains('lsg')) return 'lsg1910';
    if (lower.contains('fc')) return 'francais_courant';
    return lower.replaceAll(RegExp(r'\s+'), '_');
  }
}