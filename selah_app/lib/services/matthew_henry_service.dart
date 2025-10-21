import 'dart:convert';
import 'package:flutter/services.dart';

/// Service pour les commentaires bibliques de Matthew Henry
/// 
/// Fournit des commentaires historiques et théologiques riches
/// pour enrichir le contexte culturel des passages bibliques
class MatthewHenryService {
  static Map<String, dynamic>? _commentaryData;
  static bool _isLoading = false;

  /// Mapping des codes numériques vers les noms de livres
  static const Map<String, String> _bookMapping = {
    '1': 'Genèse',
    '2': 'Exode', 
    '3': 'Lévitique',
    '4': 'Nombres',
    '5': 'Deutéronome',
    '6': 'Josué',
    '7': 'Juges',
    '8': 'Ruth',
    '9': '1 Samuel',
    '10': '2 Samuel',
    '11': '1 Rois',
    '12': '2 Rois',
    '13': '1 Chroniques',
    '14': '2 Chroniques',
    '15': 'Esdras',
    '16': 'Néhémie',
    '17': 'Esther',
    '18': 'Job',
    '19': 'Psaumes',
    '20': 'Proverbes',
    '21': 'Ecclésiaste',
    '22': 'Cantique des Cantiques',
    '23': 'Ésaïe',
    '24': 'Jérémie',
    '25': 'Lamentations',
    '26': 'Ézéchiel',
    '27': 'Daniel',
    '28': 'Osée',
    '29': 'Joël',
    '30': 'Amos',
    '31': 'Abdias',
    '32': 'Jonas',
    '33': 'Michée',
    '34': 'Nahum',
    '35': 'Habacuc',
    '36': 'Sophonie',
    '37': 'Aggée',
    '38': 'Zacharie',
    '39': 'Malachie',
    '40': 'Matthieu',
    '41': 'Marc',
    '42': 'Luc',
    '43': 'Jean',
    '44': 'Actes',
    '45': 'Romains',
    '46': '1 Corinthiens',
    '47': '2 Corinthiens',
    '48': 'Galates',
    '49': 'Éphésiens',
    '50': 'Philippiens',
    '51': 'Colossiens',
    '52': '1 Thessaloniciens',
    '53': '2 Thessaloniciens',
    '54': '1 Timothée',
    '55': '2 Timothée',
    '56': 'Tite',
    '57': 'Philémon',
    '58': 'Hébreux',
    '59': 'Jacques',
    '60': '1 Pierre',
    '61': '2 Pierre',
    '62': '1 Jean',
    '63': '2 Jean',
    '64': '3 Jean',
    '65': 'Jude',
    '66': 'Apocalypse',
  };

  /// Initialise le service (chargement à la demande)
  static Future<void> init() async {
    if (_commentaryData != null || _isLoading) return;

    _isLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/matthew_henry.json');
      _commentaryData = json.decode(jsonString);
      print('✅ MatthewHenryService initialisé avec ${_commentaryData?.length ?? 0} commentaires');
    } catch (e) {
      print('⚠️ Erreur chargement MatthewHenryService: $e');
      _commentaryData = {};
    } finally {
      _isLoading = false;
    }
  }

  /// Récupère le commentaire pour un livre et chapitre
  /// 
  /// [book] : Nom du livre (ex: "1 Pierre")
  /// [chapter] : Numéro du chapitre (ex: 3)
  /// 
  /// Retourne : Commentaire Matthew Henry ou null
  static Future<String?> getCommentary(String book, int chapter) async {
    await init();
    
    if (_commentaryData == null) return null;

    // Trouver le code numérique du livre
    String? bookCode;
    for (final entry in _bookMapping.entries) {
      if (entry.value == book) {
        bookCode = entry.key;
        break;
      }
    }

    if (bookCode == null) {
      print('⚠️ Livre non trouvé dans le mapping: $book');
      return null;
    }

    // Construire la clé (ex: "60-3" pour 1 Pierre chapitre 3)
    final key = '$bookCode-$chapter';
    final chapterData = _commentaryData![key];
    
    if (chapterData == null) {
      print('⚠️ Commentaire non trouvé pour $book chapitre $chapter');
      return null;
    }

    // Extraire et nettoyer le texte HTML
    return _extractTextFromChapter(chapterData);
  }

  /// Extrait le texte brut depuis les données de chapitre
  static String _extractTextFromChapter(Map<String, dynamic> chapterData) {
    final sections = <String>[];
    
    for (final entry in chapterData.entries) {
      final content = entry.value as String;
      final cleanText = _cleanHtmlText(content);
      if (cleanText.isNotEmpty) {
        sections.add(cleanText);
      }
    }
    
    return sections.join('\n\n');
  }

  /// Nettoie le texte HTML en gardant la structure
  static String _cleanHtmlText(String html) {
    // Remplacer les balises de titre par des titres markdown
    String text = html.replaceAll(RegExp(r'<h3[^>]*>'), '### ');
    text = text.replaceAll(RegExp(r'</h3>'), '');
    
    // Remplacer les paragraphes par des retours à la ligne
    text = text.replaceAll(RegExp(r'<p[^>]*>'), '');
    text = text.replaceAll(RegExp(r'</p>'), '\n\n');
    
    // Supprimer les autres balises HTML
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Décoder les entités HTML communes
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    
    // Décoder les entités numériques hexadécimales
    text = _decodeHexEntities(text);
    
    // Décoder les entités numériques décimales
    text = _decodeDecimalEntities(text);
    
    // Nettoyer les espaces multiples
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    
    return text.trim();
  }
  
  /// Décode les entités hexadécimales (&#xE9; → é)
  static String _decodeHexEntities(String text) {
    return text.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
      final hexCode = match.group(1)!;
      try {
        final codePoint = int.parse(hexCode, radix: 16);
        return String.fromCharCode(codePoint);
      } catch (e) {
        return match.group(0)!; // Retourner l'entité originale si erreur
      }
    });
  }
  
  /// Décode les entités décimales (&#233; → é)
  static String _decodeDecimalEntities(String text) {
    return text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final decimalCode = match.group(1)!;
      try {
        final codePoint = int.parse(decimalCode);
        return String.fromCharCode(codePoint);
      } catch (e) {
        return match.group(0)!; // Retourner l'entité originale si erreur
      }
    });
  }

  /// Récupère un extrait de commentaire pour un verset spécifique
  /// 
  /// [book] : Nom du livre
  /// [chapter] : Numéro du chapitre  
  /// [verse] : Numéro du verset (optionnel)
  /// 
  /// Retourne : Extrait pertinent du commentaire
  static Future<String?> getCommentaryForVerse(String book, int chapter, [int? verse]) async {
    final fullCommentary = await getCommentary(book, chapter);
    if (fullCommentary == null) return null;
    
    // Si un verset spécifique est demandé, essayer d'extraire la section pertinente
    if (verse != null) {
      final sections = fullCommentary.split('\n\n');
      // Chercher une section qui mentionne le verset ou qui semble pertinente
      for (final section in sections) {
        if (section.contains('$verse') || 
            section.contains('verset $verse') ||
            section.contains('v. $verse')) {
          return section;
        }
      }
    }
    
    return fullCommentary;
  }

  /// Vérifie si un commentaire existe pour un livre/chapitre
  static Future<bool> hasCommentary(String book, int chapter) async {
    await init();
    
    if (_commentaryData == null) return false;
    
    // Trouver le code numérique du livre
    String? bookCode;
    for (final entry in _bookMapping.entries) {
      if (entry.value == book) {
        bookCode = entry.key;
        break;
      }
    }
    
    if (bookCode == null) return false;
    
    final key = '$bookCode-$chapter';
    return _commentaryData!.containsKey(key);
  }
}
