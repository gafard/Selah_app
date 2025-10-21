import 'dart:convert';
import 'package:flutter/services.dart';

class TreasuryCrossRefService {
  static Map<String, dynamic>? _crossRefData;
  static bool _isInitialized = false;

  /// Mapping des numéros de livres vers les noms français
  static const Map<int, String> bookNames = {
    1: 'Genèse', 2: 'Exode', 3: 'Lévitique', 4: 'Nombres', 5: 'Deutéronome',
    6: 'Josué', 7: 'Juges', 8: 'Ruth', 9: '1 Samuel', 10: '2 Samuel',
    11: '1 Rois', 12: '2 Rois', 13: '1 Chroniques', 14: '2 Chroniques',
    15: 'Esdras', 16: 'Néhémie', 17: 'Esther', 18: 'Job', 19: 'Psaumes',
    20: 'Proverbes', 21: 'Ecclésiaste', 22: 'Cantique', 23: 'Ésaïe',
    24: 'Jérémie', 25: 'Lamentations', 26: 'Ézéchiel', 27: 'Daniel',
    28: 'Osée', 29: 'Joël', 30: 'Amos', 31: 'Abdias', 32: 'Jonas',
    33: 'Michée', 34: 'Nahum', 35: 'Habacuc', 36: 'Sophonie',
    37: 'Aggée', 38: 'Zacharie', 39: 'Malachie', 40: 'Matthieu',
    41: 'Marc', 42: 'Luc', 43: 'Jean', 44: 'Actes', 45: 'Romains',
    46: '1 Corinthiens', 47: '2 Corinthiens', 48: 'Galates', 49: 'Éphésiens',
    50: 'Philippiens', 51: 'Colossiens', 52: '1 Thessaloniciens',
    53: '2 Thessaloniciens', 54: '1 Timothée', 55: '2 Timothée',
    56: 'Tite', 57: 'Philémon', 58: 'Hébreux', 59: 'Jacques',
    60: '1 Pierre', 61: '2 Pierre', 62: '1 Jean', 63: '2 Jean',
    64: '3 Jean', 65: 'Jude', 66: 'Apocalypse',
  };

  /// Mapping des noms de livres français vers les numéros
  static const Map<String, int> bookNumbers = {
    'Genèse': 1, 'Exode': 2, 'Lévitique': 3, 'Nombres': 4, 'Deutéronome': 5,
    'Josué': 6, 'Juges': 7, 'Ruth': 8, '1 Samuel': 9, '2 Samuel': 10,
    '1 Rois': 11, '2 Rois': 12, '1 Chroniques': 13, '2 Chroniques': 14,
    'Esdras': 15, 'Néhémie': 16, 'Esther': 17, 'Job': 18, 'Psaumes': 19,
    'Proverbes': 20, 'Ecclésiaste': 21, 'Cantique': 22, 'Ésaïe': 23,
    'Jérémie': 24, 'Lamentations': 25, 'Ézéchiel': 26, 'Daniel': 27,
    'Osée': 28, 'Joël': 29, 'Amos': 30, 'Abdias': 31, 'Jonas': 32,
    'Michée': 33, 'Nahum': 34, 'Habacuc': 35, 'Sophonie': 36,
    'Aggée': 37, 'Zacharie': 38, 'Malachie': 39, 'Matthieu': 40,
    'Marc': 41, 'Luc': 42, 'Jean': 43, 'Actes': 44, 'Romains': 45,
    '1 Corinthiens': 46, '2 Corinthiens': 47, 'Galates': 48, 'Éphésiens': 49,
    'Philippiens': 50, 'Colossiens': 51, '1 Thessaloniciens': 52,
    '2 Thessaloniciens': 53, '1 Timothée': 54, '2 Timothée': 55,
    'Tite': 56, 'Philémon': 57, 'Hébreux': 58, 'Jacques': 59,
    '1 Pierre': 60, '2 Pierre': 61, '1 Jean': 62, '2 Jean': 63,
    '3 Jean': 64, 'Jude': 65, 'Apocalypse': 66,
  };

  /// Initialise le service en chargeant les données depuis les assets
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('🔄 Chargement TreasuryCrossRefService...');
      final String jsonString = await rootBundle.loadString('assets/data/treasury_crossref.json');
      _crossRefData = json.decode(jsonString) as Map<String, dynamic>;
      _isInitialized = true;
      print('✅ TreasuryCrossRefService initialisé (${_crossRefData?.length ?? 0} entrées)');
    } catch (e) {
      print('⚠️ Erreur chargement TreasuryCrossRefService: $e');
      _crossRefData = {};
      _isInitialized = true;
    }
  }

  /// Convertit une référence biblique en format numérique
  /// Ex: "1 Pierre 3:1" → "60-3-1" ou "1 Pierre 3:1-18" → "60-3-1"
  static String _convertToNumericFormat(String verseRef) {
    try {
      // Parser la référence (ex: "1 Pierre 3:1" ou "1 Pierre 3:1-18")
      final regex = RegExp(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$');
      final match = regex.firstMatch(verseRef.trim());
      
      if (match == null) {
        print('⚠️ Format de référence non reconnu: $verseRef');
        return '';
      }

      final bookName = match.group(1)!.trim();
      final chapter = match.group(2)!;
      final startVerse = match.group(3)!;
      // Pour les passages, on prend le premier verset
      final verse = startVerse;

      // Convertir le nom du livre en numéro
      final bookNumber = bookNumbers[bookName];
      if (bookNumber == null) {
        print('⚠️ Livre non trouvé: $bookName');
        return '';
      }

      return '$bookNumber-$chapter-$verse';
    } catch (e) {
      print('⚠️ Erreur conversion référence: $e');
      return '';
    }
  }

  /// Convertit un format numérique en référence biblique
  /// Ex: "45-7-2" → "Romains 7:2"
  static String _convertFromNumericFormat(String numericRef) {
    try {
      final parts = numericRef.split('-');
      if (parts.length != 3) return numericRef;

      final bookNumber = int.tryParse(parts[0]);
      final chapter = parts[1];
      final verse = parts[2];

      if (bookNumber == null) return numericRef;

      final bookName = bookNames[bookNumber];
      if (bookName == null) return numericRef;

      return '$bookName $chapter:$verse';
    } catch (e) {
      print('⚠️ Erreur conversion numérique: $e');
      return numericRef;
    }
  }

  /// Vérifie si une chaîne correspond au pattern de référence numérique
  static bool _isNumericReference(String item) {
    final regex = RegExp(r'^\d+-\d+-\d+$');
    return regex.hasMatch(item);
  }

  /// Récupère les références croisées pour un verset donné
  static Future<List<Map<String, dynamic>>> getCrossReferences(String verseRef) async {
    await init();

    if (_crossRefData == null) {
      print('⚠️ TreasuryCrossRefService non initialisé');
      return [];
    }

    try {
      // Convertir la référence en format numérique
      final numericRef = _convertToNumericFormat(verseRef);
      if (numericRef.isEmpty) return [];

      print('🔍 Recherche références croisées pour: $verseRef ($numericRef)');

      // Récupérer les références depuis le JSON
      final references = _crossRefData![numericRef] as List<dynamic>?;
      if (references == null || references.isEmpty) {
        print('📝 Aucune référence croisée trouvée pour $verseRef');
        return [];
      }

      // Filtrer et convertir les références
      final crossRefs = <Map<String, dynamic>>[];
      
      for (final item in references) {
        final itemStr = item.toString();
        
        // Ignorer les textes explicatifs, ne garder que les références numériques
        if (_isNumericReference(itemStr)) {
          final readableRef = _convertFromNumericFormat(itemStr);
          final parts = itemStr.split('-');
          
          if (parts.length == 3) {
            final bookNumber = int.tryParse(parts[0]);
            final chapter = int.tryParse(parts[1]);
            final verse = int.tryParse(parts[2]);
            
            if (bookNumber != null && chapter != null && verse != null) {
              crossRefs.add({
                'reference': readableRef,
                'bookNumber': bookNumber,
                'chapter': chapter,
                'verse': verse,
                'numericRef': itemStr,
              });
            }
          }
        }
      }

      // Trier par pertinence et limiter à 5 références
      final sortedRefs = _sortByRelevance(crossRefs, verseRef);
      final limitedRefs = sortedRefs.take(5).toList();
      
      print('✅ ${limitedRefs.length} références croisées les plus pertinentes trouvées pour $verseRef');
      return limitedRefs;

    } catch (e) {
      print('⚠️ Erreur getCrossReferences: $e');
      return [];
    }
  }

  /// Trie les références par pertinence
  static List<Map<String, dynamic>> _sortByRelevance(
    List<Map<String, dynamic>> references,
    String originalVerse,
  ) {
    // Extraire le numéro du livre original pour le scoring
    final originalBookName = _extractBookFromReference(originalVerse);
    final originalBook = bookNumbers[originalBookName] ?? 0;
    
    return references.map((ref) {
      final book = ref['bookNumber'] as int? ?? 0;
      final chapter = ref['chapter'] as int? ?? 0;
      final verse = ref['verse'] as int? ?? 0;
      final reference = ref['reference'] as String? ?? '';
      
      // Calculer un score de pertinence
      int score = 0;
      
      // 1. Priorité aux livres du même Testament
      if (_isSameTestament(originalBook, book)) {
        score += 100;
      }
      
      // 2. Priorité aux livres proches (même auteur ou époque)
      if (_isRelatedBook(originalBook, book)) {
        score += 50;
      }
      
      // 3. Priorité aux références dans les premiers chapitres (plus fondamentales)
      if (chapter <= 5) {
        score += 20;
      }
      
      // 4. Priorité aux versets avec des numéros similaires (connexions thématiques)
      final originalVerseNum = _extractVerseNumber(originalVerse);
      if (originalVerseNum != null) {
        final verseDiff = (verse - originalVerseNum).abs();
        if (verseDiff <= 5) {
          score += 30;
        }
      }
      
      // 5. Priorité aux livres majeurs (Évangiles, Épîtres de Paul, etc.)
      if (_isMajorBook(book)) {
        score += 15;
      }
      
      // 6. Priorité aux références dans les premiers versets du chapitre
      if (verse <= 10) {
        score += 10;
      }
      
      return {
        ...ref,
        'relevanceScore': score,
      };
    }).toList()
      ..sort((a, b) => (b['relevanceScore'] as int).compareTo(a['relevanceScore'] as int));
  }
  
  /// Extrait le livre d'une référence
  static String _extractBookFromReference(String reference) {
    final regex = RegExp(r'^(.+?)\s+\d+:\d+');
    final match = regex.firstMatch(reference);
    return match?.group(1)?.trim().toLowerCase() ?? '';
  }
  
  /// Extrait le numéro de verset d'une référence
  static int? _extractVerseNumber(String reference) {
    final regex = RegExp(r':(\d+)(?:-\d+)?');
    final match = regex.firstMatch(reference);
    return int.tryParse(match?.group(1) ?? '');
  }
  
  /// Vérifie si deux livres sont du même Testament
  static bool _isSameTestament(int book1, int book2) {
    final book1OldTestament = book1 <= 39;
    final book2OldTestament = book2 <= 39;
    return book1OldTestament == book2OldTestament;
  }
  
  /// Vérifie si deux livres sont liés (même auteur, époque, etc.)
  static bool _isRelatedBook(int book1, int book2) {
    // Paul's epistles
    final paulBooks = [45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58];
    if (paulBooks.contains(book1) && paulBooks.contains(book2)) return true;
    
    // Gospels
    final gospels = [40, 41, 42, 43];
    if (gospels.contains(book1) && gospels.contains(book2)) return true;
    
    // Peter's epistles
    if ((book1 == 60 || book1 == 61) && (book2 == 60 || book2 == 61)) return true;
    
    // John's writings
    final johnBooks = [43, 62, 63, 64, 66];
    if (johnBooks.contains(book1) && johnBooks.contains(book2)) return true;
    
    return false;
  }
  
  /// Vérifie si un livre est majeur (plus important théologiquement)
  static bool _isMajorBook(int book) {
    // Gospels, Paul's epistles, Hebrews, Revelation
    return book >= 40 && book <= 66;
  }

  /// Récupère les statistiques du service
  static Future<Map<String, int>> getStats() async {
    await init();
    
    if (_crossRefData == null) return {};
    
    return {
      'totalEntries': _crossRefData!.length,
      'isInitialized': _isInitialized ? 1 : 0,
    };
  }
}
