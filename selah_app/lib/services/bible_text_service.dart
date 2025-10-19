import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'bible_asset_importer.dart';

class BibleTextService {
  static Database? _database;
  static String? _preloadedVersion;
  
  static Future<void> init() async {
    if (_database != null) return;
    final dbPath = await getDatabasesPath();
    final file = p.join(dbPath, 'bible_verses.db');
    _database = await openDatabase(file, version: 1, onCreate: (db, v) async {
      await BibleAssetImporter.ensureSchema(db);
    });
  }

  /// Pré-charge la version active au boot pour éviter le "blanc" la première fois
  static Future<void> preloadActiveVersion(String versionId) async {
    if (_preloadedVersion == versionId) return;
    
    await ensureVersionAvailable(versionId);
    _preloadedVersion = versionId;
    print('📖 Version "$versionId" pré-chargée');
  }

  /// À appeler au démarrage (ou lazy) pour s'assurer que la version existe.
  static Future<void> ensureVersionAvailable(String versionId) async {
    await init();
    
    // Vérifier si la version est déjà disponible
    final isAvailable = await BibleAssetImporter.isVersionAvailable(_database!, versionId);
    print('🔍 ensureVersionAvailable($versionId): isAvailable=$isAvailable');
    
    if (isAvailable) {
      print('✅ Version "$versionId" déjà disponible en base SQLite');
      return;
    }

    // map versionId -> asset
    final assetPath = _assetFor(versionId);
    if (assetPath == null) {
      print('⚠️ Pas d\'asset configuré pour "$versionId"');
      return;
    }
    
    print('📥 Import de la version "$versionId" depuis $assetPath');
    try {
      await BibleAssetImporter.importFromAsset(
        db: _database!,
        assetPath: assetPath,
        forceVersionId: versionId,
      );
      print('✅ Import de "$versionId" terminé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'import de "$versionId": $e');
      // Ne pas relancer l'erreur pour éviter de casser l'app
    }
  }

  static String? _assetFor(String versionId) {
    switch (versionId) {
      case 'lsg1910': return 'assets/bibles/lsg1910.json';
      case 'semeur': return 'assets/bibles/semeur.json';
      case 'francais_courant': return 'assets/bibles/francais_courant.json';
      default: return null;
    }
  }

  static Future<String?> getPassageText(String reference, {String version = 'lsg1910'}) async {
    await ensureVersionAvailable(version);
    if (_database == null) await init();

    try {
      // Parse ex: "Jean 3:16-4:10" | "Jean 3" | "Jean 3:16-20" | "Jean 3:16" | "2 Corinthiens 2:1-35"
      final ref = reference.trim();
      
      // Trouver le dernier espace pour séparer livre et chapitre/verset
      final lastSpace = ref.lastIndexOf(' ');
      if (lastSpace <= 0) return null;

      final book = ref.substring(0, lastSpace).trim(); // "2 Corinthiens" ou "Jean"
      final rest = ref.substring(lastSpace + 1).trim(); // "2:1-35" ou "3:16"

      int sc, sv = 1, ec, ev;
      if (rest.contains('-')) {
        // "3:16-4:10" ou "3:16-20"
        final parts = rest.split('-');
        final start = parts[0];
        final end = parts[1];

        final sCV = start.split(':');
        sc = int.parse(sCV[0]);
        sv = sCV.length > 1 ? int.parse(sCV[1]) : 1;

        if (end.contains(':')) {
          final eCV = end.split(':');
          ec = int.parse(eCV[0]);
          ev = int.parse(eCV[1]);
        } else {
          ec = sc;
          ev = int.parse(end);
        }
      } else if (rest.contains(':')) {
        // "3:16"
        final sCV = rest.split(':');
        sc = int.parse(sCV[0]);
        sv = int.parse(sCV[1]);
        ec = sc; ev = sv;
      } else {
        // "3" → chapitre entier
        sc = int.parse(rest);
        ec = sc;
        // récupérer max(verse) du chapitre
        final maxV = await _maxVerse(version, book, sc);
        sv = 1; ev = maxV ?? 999; // safe
      }

      final rows = await _database!.rawQuery('''
        SELECT text FROM verses
        WHERE version = ? AND book = ? AND (
          (chapter = ? AND verse >= ?) OR
          (chapter > ? AND chapter < ?) OR
          (chapter = ? AND verse <= ?)
        )
        ORDER BY chapter, verse
      ''', [version, book, sc, sv, sc, ec, ec, ev]);

      if (rows.isEmpty) {
        // essai fallback pour les livres numérotés ("1 Jean", etc.)
        final alt = _normalizeBook(book);
        if (alt != book) {
          final rows2 = await _database!.rawQuery('''
            SELECT text FROM verses
            WHERE version = ? AND book = ? AND (
              (chapter = ? AND verse >= ?) OR
              (chapter > ? AND chapter < ?) OR
              (chapter = ? AND verse <= ?)
            )
            ORDER BY chapter, verse
          ''', [version, alt, sc, sv, sc, ec, ec, ev]);
          if (rows2.isNotEmpty) {
            return rows2.map((r) => r['text'] as String).join('\n\n');
          }
        }
        return null;
      }

      return rows.map((r) => r['text'] as String).join('\n\n');
    } catch (e) {
      print('⚠️ getPassageText("$reference",$version) → $e');
      return null;
    }
  }

  static Future<int?> _maxVerse(String version, String book, int chapter) async {
    final r = await _database!.rawQuery(
      'SELECT MAX(verse) m FROM verses WHERE version=? AND book=? AND chapter=?',
      [version, book, chapter],
    );
    final v = r.isNotEmpty ? r.first['m'] as int? : null;
    return v;
  }

  /// Ex: "1Jean" / "1 Jean" / "I Jean" → "1 Jean"
  static String _normalizeBook(String b) {
    final s = b.replaceAll(RegExp(r'\s+'), ' ').trim();
    // peu de normalisation — ajuste si tu en vois d'autres
    if (RegExp(r'^(1|I)\s*Jean$', caseSensitive: false).hasMatch(s)) return '1 Jean';
    if (RegExp(r'^(2|II)\s*Jean$', caseSensitive: false).hasMatch(s)) return '2 Jean';
    if (RegExp(r'^(3|III)\s*Jean$', caseSensitive: false).hasMatch(s)) return '3 Jean';
    if (RegExp(r'^(1|I)\s*Cor', caseSensitive: false).hasMatch(s)) return '1 Corinthiens';
    if (RegExp(r'^(2|II)\s*Cor', caseSensitive: false).hasMatch(s)) return '2 Corinthiens';
    if (RegExp(r'^(1|I)\s*Thes', caseSensitive: false).hasMatch(s)) return '1 Thessaloniciens';
    if (RegExp(r'^(2|II)\s*Thes', caseSensitive: false).hasMatch(s)) return '2 Thessaloniciens';
    if (RegExp(r'^(1|I)\s*Tim', caseSensitive: false).hasMatch(s)) return '1 Timothée';
    if (RegExp(r'^(2|II)\s*Tim', caseSensitive: false).hasMatch(s)) return '2 Timothée';
    return s;
  }

  /// Vérifie si la base contient des versets pour une version spécifique
  static Future<bool> hasVerses([String? versionId]) async {
    try {
      await init();
      if (_database == null) return false;
      
      final version = versionId ?? 'lsg1910';
      return await BibleAssetImporter.isVersionAvailable(_database!, version);
    } catch (e) {
      print('⚠️ Erreur hasVerses: $e');
      return false;
    }
  }
  
  /// Méthode de compatibilité
  static Future<void> populateFromAssets() async {
    print('✅ BibleTextService: Import des fichiers JSON bibliques avec json5 vers SQLite');
    await init();
  }

  /// Force la réimportation d'une version (pour dev/QA)
  static Future<void> forceReimportVersion(String versionId) async {
    await init();
    if (_database == null) return;
    
    // Supprimer les anciennes entrées
    await _database!.delete('verses', where: 'version = ?', whereArgs: [versionId]);
    await _database!.execute('VACUUM');
    
    // Réimporter
    final assetPath = _assetFor(versionId);
    if (assetPath != null) {
      await BibleAssetImporter.importFromAsset(
        db: _database!,
        assetPath: assetPath,
        forceVersionId: versionId,
      );
    }
  }
}