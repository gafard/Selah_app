import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Service pour gérer les versions de Bible intégrées dans les assets
class BibleAssetsService {
  static const List<String> _integratedVersions = [
    'lsg1910',
    'francais_courant', 
    'semeur'
  ];
  
  /// Vérifie si une version est intégrée dans les assets
  static bool isIntegratedVersion(String versionId) {
    return _integratedVersions.contains(versionId);
  }
  
  /// Récupère la liste des versions intégrées
  static List<String> getIntegratedVersions() {
    return List.from(_integratedVersions);
  }
  
  /// Charge une version depuis les assets et la sauvegarde en SQLite
  static Future<bool> loadIntegratedVersion(String versionId) async {
    try {
      if (!isIntegratedVersion(versionId)) {
        print('❌ Version $versionId non intégrée');
        return false;
      }
      
      print('📖 Chargement version intégrée: $versionId');
      
      // Charger depuis les assets
      final jsonString = await rootBundle.loadString('assets/bibles/$versionId.json');
      final jsonData = json.decode(jsonString);
      
      // Sauvegarder en SQLite
      await _saveToDatabase(versionId, jsonData);
      
      print('✅ Version $versionId chargée depuis les assets');
      return true;
      
    } catch (e) {
      print('❌ Erreur chargement version intégrée $versionId: $e');
      return false;
    }
  }
  
  /// Charge toutes les versions intégrées
  static Future<Map<String, bool>> loadAllIntegratedVersions() async {
    final results = <String, bool>{};
    
    for (final versionId in _integratedVersions) {
      results[versionId] = await loadIntegratedVersion(versionId);
    }
    
    return results;
  }
  
  /// Sauvegarde les données dans la base SQLite
  static Future<void> _saveToDatabase(String versionId, Map<String, dynamic> data) async {
    final database = await _getDatabase();
    
    // Ajouter la version dans la table versions
    await database.insert('versions', {
      'version_id': versionId,
      'name': data['name'],
      'language': data['language'],
      'copyright': 'Assets intégrés',
      'source': 'assets',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Ajouter les livres et versets
    if (data['books'] != null) {
      for (final bookEntry in (data['books'] as Map<String, dynamic>).entries) {
        final bookName = bookEntry.key;
        final bookData = bookEntry.value as Map<String, dynamic>;
        
        await _insertBookAndVerses(database, versionId, bookName, bookData);
      }
    }
    
    print('💾 Version $versionId sauvegardée en SQLite');
  }
  
  /// Insère un livre et ses versets
  static Future<void> _insertBookAndVerses(
    Database database,
    String versionId,
    String bookName,
    Map<String, dynamic> bookData,
  ) async {
    // Insérer le livre
    await database.insert('books', {
      'book_id': _getBookNumber(bookName),
      'name': bookName,
      'abbreviation': _getBookAbbreviation(bookName),
      'chapters': bookData.length,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Insérer les versets
    for (final chapterEntry in bookData.entries) {
      final chapterNum = int.tryParse(chapterEntry.key) ?? 1;
      final verses = chapterEntry.value as List<dynamic>;
      
      for (int i = 0; i < verses.length; i++) {
        await database.insert('verses', {
          'book_id': _getBookNumber(bookName),
          'chapter': chapterNum,
          'verse': i + 1,
          'text': verses[i].toString(),
          'version_id': versionId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
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
    final dbPath = join(await getDatabasesPath(), 'bible_pack.sqlite');
    return await openDatabase(dbPath);
  }
}
