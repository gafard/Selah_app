import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'bible_assets_service.dart';

/// Gestionnaire des versions de Bible - Intégration VideoPsalm et OpenBible
class BibleVersionManager {
  static const String _videopsalmBaseUrl = 'https://videopsalm.weebly.com';
  
  /// Versions disponibles depuis VideoPsalm (JSON)
  static const Map<String, Map<String, String>> _videopsalmVersions = {
    'colombe': {
      'name': 'Colombe',
      'url': '/colombe.json',
      'language': 'fr',
      'description': 'Traduction œcuménique'
    },
    'darby': {
      'name': 'Darby',
      'url': '/darby.json',
      'language': 'fr',
      'description': 'Version classique'
    },
    'francais_courant': {
      'name': 'Français courant',
      'url': '/francais-courant.json',
      'language': 'fr',
      'description': 'Langage moderne'
    },
    'martin_1744': {
      'name': 'Bible Martin 1744',
      'url': '/martin-1744.json',
      'language': 'fr',
      'description': 'Version historique'
    },
    'ostervald_1996': {
      'name': 'Bible Ostervald 1996',
      'url': '/ostervald-1996.json',
      'language': 'fr',
      'description': 'Version révisée'
    },
    'nouvelle_segond': {
      'name': 'Nouvelle Bible Segond',
      'url': '/nouvelle-segond.json',
      'language': 'fr',
      'description': 'Version moderne'
    },
    'neg_1979': {
      'name': 'Nouvelle Édition de Genève 1979',
      'url': '/neg-1979.json',
      'language': 'fr',
      'description': 'Version protestante'
    },
    'segond_21': {
      'name': 'Bible Segond 21',
      'url': '/segond-21.json',
      'language': 'fr',
      'description': 'Version contemporaine'
    },
    'parole_de_vie': {
      'name': 'Parole de Vie',
      'url': '/parole-de-vie.json',
      'language': 'fr',
      'description': 'Version simplifiée'
    },
    'semeur': {
      'name': 'Bible du Semeur',
      'url': '/semeur.json',
      'language': 'fr',
      'description': 'Version dynamique'
    },
    'tob': {
      'name': 'Traduction Œcuménique de la Bible',
      'url': '/tob.json',
      'language': 'fr',
      'description': 'Version interconfessionnelle'
    }
  };
  
  /// Versions disponibles depuis OpenBible (API)
  static const Map<String, Map<String, String>> _openbibleVersions = {
    'kjv': {
      'name': 'King James Version',
      'url': '/api/kjv',
      'language': 'en',
      'description': 'Version historique anglaise'
    },
    'asv': {
      'name': 'American Standard Version',
      'url': '/api/asv',
      'language': 'en',
      'description': 'Version classique américaine'
    },
    'darby_en': {
      'name': 'Darby Bible Translation',
      'url': '/api/darby',
      'language': 'en',
      'description': 'Version littérale anglaise'
    }
  };
  
  /// Récupère la liste des versions disponibles
  static Map<String, Map<String, String>> getAvailableVersions() {
    return {
      ..._videopsalmVersions,
      ..._openbibleVersions,
    };
  }
  
  /// Récupère les versions françaises uniquement
  static Map<String, Map<String, String>> getFrenchVersions() {
    return _videopsalmVersions;
  }
  
  /// Récupère les versions VideoPsalm
  static Map<String, Map<String, String>> getVideoPsalmVersions() {
    return _videopsalmVersions;
  }
  
  /// Récupère les versions anglaises uniquement
  static Map<String, Map<String, String>> getEnglishVersions() {
    return _openbibleVersions;
  }
  
  /// Télécharge une version de Bible (assets intégrés ou VideoPsalm)
  static Future<bool> downloadVideoPsalmVersion(String versionId) async {
    // ✅ Vérifier si c'est une version intégrée
    if (BibleAssetsService.isIntegratedVersion(versionId)) {
      print('📦 Version intégrée détectée: $versionId');
      return await BibleAssetsService.loadIntegratedVersion(versionId);
    }
    
    // ✅ Sinon, télécharger depuis VideoPsalm
    final version = _videopsalmVersions[versionId];
    if (version == null) {
      throw Exception('Version $versionId non trouvée');
    }
    
    try {
      print('📥 Téléchargement de ${version['name']} depuis VideoPsalm...');
      
      // ✅ Téléchargement réel depuis VideoPsalm
      final url = '$_videopsalmBaseUrl${version['url']}';
      print('🌐 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Selah App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        print('✅ Données reçues (${response.body.length} caractères)');
        
        // Parser les données JSON
        final jsonData = json.decode(response.body);
        
        // Convertir au format attendu
        final bibleData = {
          'version': versionId,
          'name': version['name'],
          'language': version['language'],
          'books': _convertVideoPsalmData(jsonData),
          'downloaded_at': DateTime.now().toIso8601String(),
          'source': 'VideoPsalm',
        };
        
        // Sauvegarder dans la base SQLite
        await _saveBibleVersionToDatabase(versionId, version, bibleData);
        
        print('✅ ${version['name']} téléchargée et sauvegardée');
        return true;
        
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}');
        return false;
      }
      
    } catch (e) {
      print('❌ Erreur téléchargement ${version['name']}: $e');
      return false;
    }
  }
  
  /// Télécharge une version de Bible depuis OpenBible
  static Future<bool> downloadOpenBibleVersion(String versionId) async {
    final version = _openbibleVersions[versionId];
    if (version == null) {
      throw Exception('Version $versionId non trouvée');
    }
    
    try {
      print('📥 Téléchargement de ${version['name']} depuis OpenBible...');
      
      // Utiliser l'API OpenBible pour récupérer les données
      final bibleData = await _fetchOpenBibleData(versionId);
      
      // Sauvegarder dans la base SQLite
      await _saveBibleVersionToDatabase(versionId, version, bibleData);
      
      print('✅ ${version['name']} téléchargée et sauvegardée');
      return true;
      
    } catch (e) {
      print('❌ Erreur téléchargement ${version['name']}: $e');
      return false;
    }
  }
  
  /// Récupère les données depuis l'API OpenBible
  static Future<Map<String, dynamic>> _fetchOpenBibleData(String versionId) async {
    // Simulation - remplacer par vraie API OpenBible
    await Future.delayed(const Duration(seconds: 2));
    
    return {
      'version': versionId,
      'name': _openbibleVersions[versionId]!['name'],
      'language': 'en',
      'books': _getSampleBooks(),
      'downloaded_at': DateTime.now().toIso8601String(),
    };
  }
  
  /// Sauvegarde une version de Bible dans la base SQLite
  static Future<void> _saveBibleVersionToDatabase(
    String versionId,
    Map<String, String> versionInfo,
    Map<String, dynamic> bibleData,
  ) async {
    final database = await _getDatabase();
    
    // Ajouter la version dans la table versions
    await database.insert('versions', {
      'version_id': versionId,
      'name': versionInfo['name'],
      'language': versionInfo['language'],
      'copyright': 'TBD',
    });
    
    // Ajouter les livres et versets
    if (bibleData['books'] != null) {
      for (final book in bibleData['books']) {
        await _insertBookAndVerses(database, versionId, book);
      }
    }
    
    print('💾 Version $versionId sauvegardée dans la base SQLite');
  }
  
  /// Insère un livre et ses versets dans la base
  static Future<void> _insertBookAndVerses(
    Database database,
    String versionId,
    Map<String, dynamic> book,
  ) async {
    // Insérer le livre
    await database.insert('books', {
      'book_id': book['num'] ?? book['id'],
      'name': book['name'],
      'abbreviation': book['abbr'] ?? book['abbreviation'],
      'chapters': book['chapters']?.length ?? 0,
    });
    
    // Insérer les versets
    if (book['chapters'] != null) {
      for (final chapter in book['chapters']) {
        await _insertChapterVerses(database, versionId, book, chapter);
      }
    }
  }
  
  /// Insère les versets d'un chapitre
  static Future<void> _insertChapterVerses(
    Database database,
    String versionId,
    Map<String, dynamic> book,
    Map<String, dynamic> chapter,
  ) async {
    if (chapter['verses'] != null) {
      for (final verse in chapter['verses']) {
        await database.insert('verses', {
          'book_id': book['num'] ?? book['id'],
          'chapter': chapter['chapter'],
          'verse': verse['verse'],
          'text': verse['text'],
          'version_id': versionId,
        });
      }
    }
  }
  
  /// Récupère les livres d'exemple
  static List<Map<String, dynamic>> _getSampleBooks() {
    return [
      {
        'num': 1, 
        'name': 'Genèse', 
        'abbr': 'Ge', 
        'chapters': [
          {
            'chapter': '1',
            'verses': [
              {'verse': '1', 'text': 'Au commencement, Dieu créa les cieux et la terre.'},
              {'verse': '2', 'text': 'La terre était informe et vide: il y avait des ténèbres à la surface de l\'abîme, et l\'esprit de Dieu se mouvait au-dessus des eaux.'},
            ]
          }
        ]
      },
      {
        'num': 2, 
        'name': 'Exode', 
        'abbr': 'Ex', 
        'chapters': [
          {
            'chapter': '1',
            'verses': [
              {'verse': '1', 'text': 'Voici les noms des fils d\'Israël, venus en Égypte avec Jacob et la famille de chacun d\'eux:'},
            ]
          }
        ]
      },
    ];
  }
  
  /// Vérifie si une version est disponible localement
  static Future<bool> isVersionAvailable(String versionId) async {
    final database = await _getDatabase();
    final result = await database.query(
      'versions',
      where: 'version_id = ?',
      whereArgs: [versionId],
    );
    return result.isNotEmpty;
  }
  
  /// Récupère les statistiques des versions téléchargées
  static Future<Map<String, dynamic>> getDownloadStats() async {
    try {
      final database = await _getDatabase();
      
      final versions = await database.query('versions');
      final verses = await database.rawQuery('SELECT COUNT(*) as count FROM verses');
      final books = await database.rawQuery('SELECT COUNT(*) as count FROM books');
      
      return {
        'downloaded_versions': versions.length,
        'total_verses': verses.isNotEmpty ? verses.first['count'] : 0,
        'total_books': books.isNotEmpty ? books.first['count'] : 0,
        'versions': versions.map((v) => {
          'id': v['version_id'],
          'name': v['name'],
          'language': v['language'],
        }).toList(),
      };
    } catch (e) {
      print('⚠️ Erreur getDownloadStats: $e');
      return {
        'downloaded_versions': 0,
        'total_verses': 0,
        'total_books': 0,
        'versions': [],
      };
    }
  }
  
  /// Télécharge toutes les versions françaises
  static Future<Map<String, bool>> downloadAllFrenchVersions() async {
    final results = <String, bool>{};
    
    for (final versionId in _videopsalmVersions.keys) {
      if (!await isVersionAvailable(versionId)) {
        results[versionId] = await downloadVideoPsalmVersion(versionId);
      } else {
        results[versionId] = true; // Déjà disponible
      }
    }
    
    return results;
  }
  
  /// Supprime une version de la base
  static Future<void> removeVersion(String versionId) async {
    final database = await _getDatabase();
    
    // Supprimer les versets
    await database.delete('verses', where: 'version_id = ?', whereArgs: [versionId]);
    
    // Supprimer la version
    await database.delete('versions', where: 'version_id = ?', whereArgs: [versionId]);
    
    print('🗑️ Version $versionId supprimée');
  }
  
  /// Convertit les données VideoPsalm au format attendu
  static List<Map<String, dynamic>> _convertVideoPsalmData(dynamic jsonData) {
    try {
      // VideoPsalm utilise un format spécifique, on l'adapte
      if (jsonData is Map<String, dynamic>) {
        final books = <Map<String, dynamic>>[];
        
        // Parcourir les livres
        jsonData.forEach((bookName, bookData) {
          if (bookData is Map<String, dynamic>) {
            final chapters = <List<String>>[];
            
            // Parcourir les chapitres
            bookData.forEach((chapterNum, chapterData) {
              if (chapterData is List) {
                chapters.add(chapterData.cast<String>());
              }
            });
            
            books.add({
              'name': bookName,
              'abbreviation': _getBookAbbreviation(bookName),
              'chapters': chapters,
              'num': _getBookNumber(bookName),
            });
          }
        });
        
        return books;
      }
      
      return [];
    } catch (e) {
      print('⚠️ Erreur conversion données VideoPsalm: $e');
      return [];
    }
  }
  
  /// Récupère l'abréviation d'un livre
  static String _getBookAbbreviation(String bookName) {
    final abbreviations = {
      'Genèse': 'Gn', 'Exode': 'Ex', 'Lévitique': 'Lv', 'Nombres': 'Nb', 'Deutéronome': 'Dt',
      'Josué': 'Jos', 'Juges': 'Jg', 'Ruth': 'Rt', '1 Samuel': '1S', '2 Samuel': '2S',
      '1 Rois': '1R', '2 Rois': '2R', '1 Chroniques': '1Ch', '2 Chroniques': '2Ch',
      'Esdras': 'Esd', 'Néhémie': 'Ne', 'Esther': 'Est', 'Job': 'Jb', 'Psaumes': 'Ps',
      'Proverbes': 'Pr', 'Ecclésiaste': 'Qo', 'Cantique': 'Ct', 'Ésaïe': 'És', 'Jérémie': 'Jr',
      'Lamentations': 'Lm', 'Ézéchiel': 'Éz', 'Daniel': 'Dn', 'Osée': 'Os', 'Joël': 'Jl',
      'Amos': 'Am', 'Abdias': 'Ab', 'Jonas': 'Jon', 'Michée': 'Mi', 'Nahum': 'Na',
      'Habacuc': 'Ha', 'Sophonie': 'So', 'Aggée': 'Ag', 'Zacharie': 'Za', 'Malachie': 'Ml',
      'Matthieu': 'Mt', 'Marc': 'Mc', 'Luc': 'Lc', 'Jean': 'Jn', 'Actes': 'Ac',
      'Romains': 'Rm', '1 Corinthiens': '1Co', '2 Corinthiens': '2Co', 'Galates': 'Ga',
      'Éphésiens': 'Ép', 'Philippiens': 'Ph', 'Colossiens': 'Col', '1 Thessaloniciens': '1Th',
      '2 Thessaloniciens': '2Th', '1 Timothée': '1Tm', '2 Timothée': '2Tm', 'Tite': 'Tt',
      'Philémon': 'Phm', 'Hébreux': 'He', 'Jacques': 'Jc', '1 Pierre': '1P', '2 Pierre': '2P',
      '1 Jean': '1Jn', '2 Jean': '2Jn', '3 Jean': '3Jn', 'Jude': 'Jd', 'Apocalypse': 'Ap',
    };
    
    return abbreviations[bookName] ?? bookName.substring(0, 2).toUpperCase();
  }
  
  /// Récupère le numéro d'un livre
  static int _getBookNumber(String bookName) {
    final bookNumbers = {
      'Genèse': 1, 'Exode': 2, 'Lévitique': 3, 'Nombres': 4, 'Deutéronome': 5,
      'Josué': 6, 'Juges': 7, 'Ruth': 8, '1 Samuel': 9, '2 Samuel': 10,
      '1 Rois': 11, '2 Rois': 12, '1 Chroniques': 13, '2 Chroniques': 14,
      'Esdras': 15, 'Néhémie': 16, 'Esther': 17, 'Job': 18, 'Psaumes': 19,
      'Proverbes': 20, 'Ecclésiaste': 21, 'Cantique': 22, 'Ésaïe': 23, 'Jérémie': 24,
      'Lamentations': 25, 'Ézéchiel': 26, 'Daniel': 27, 'Osée': 28, 'Joël': 29,
      'Amos': 30, 'Abdias': 31, 'Jonas': 32, 'Michée': 33, 'Nahum': 34,
      'Habacuc': 35, 'Sophonie': 36, 'Aggée': 37, 'Zacharie': 38, 'Malachie': 39,
      'Matthieu': 40, 'Marc': 41, 'Luc': 42, 'Jean': 43, 'Actes': 44,
      'Romains': 45, '1 Corinthiens': 46, '2 Corinthiens': 47, 'Galates': 48,
      'Éphésiens': 49, 'Philippiens': 50, 'Colossiens': 51, '1 Thessaloniciens': 52,
      '2 Thessaloniciens': 53, '1 Timothée': 54, '2 Timothée': 55, 'Tite': 56,
      'Philémon': 57, 'Hébreux': 58, 'Jacques': 59, '1 Pierre': 60, '2 Pierre': 61,
      '1 Jean': 62, '2 Jean': 63, '3 Jean': 64, 'Jude': 65, 'Apocalypse': 66,
    };
    
    return bookNumbers[bookName] ?? 0;
  }

  /// Récupère la base de données SQLite
  static Future<Database> _getDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'bible_versions.db');
    
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Créer la table versions
        await db.execute('''
          CREATE TABLE versions (
            version_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            language TEXT NOT NULL,
            copyright TEXT,
            source TEXT
          )
        ''');
        
        // Créer la table books
        await db.execute('''
          CREATE TABLE books (
            book_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            abbreviation TEXT,
            chapters INTEGER
          )
        ''');
        
        // Créer la table verses
        await db.execute('''
          CREATE TABLE verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            text TEXT NOT NULL,
            version_id TEXT NOT NULL,
            FOREIGN KEY (version_id) REFERENCES versions(version_id),
            FOREIGN KEY (book_id) REFERENCES books(book_id)
          )
        ''');
        
        // Index pour les requêtes fréquentes
        await db.execute('''
          CREATE INDEX idx_verses_lookup 
          ON verses(version_id, book_id, chapter, verse)
        ''');
      },
    );
  }
}
