import 'package:hive/hive.dart';

/// Service offline pour le lexique grec/hébreu simplifié
/// 
/// Sources de données :
/// - Hive box 'bible_lexicon'
/// - Hydratée depuis assets/jsons/lexicon.json
/// 
/// Format :
/// {
///   "Matthieu.5.3": [
///     {"lemma": "makarios", "lang": "grc", "gloss": "heureux, béni"},
///     {"lemma": "ptōchos", "lang": "grc", "gloss": "pauvre, mendiant"}
///   ],
///   ...
/// }
class LexiconService {
  static Box? _lexiconBox;
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _lexiconBox = await Hive.openBox('bible_lexicon');
    print('✅ LexiconService initialisé (${_lexiconBox?.length ?? 0} entrées)');
  }
  
  /// Récupère les lexèmes (mots originaux) d'un verset
  /// 
  /// [id] : ID du verset (ex: "Matthieu.5.3")
  /// 
  /// Retourne : Liste de lexèmes avec traductions
  static Future<List<Lexeme>> lexemes(String id) async {
    try {
      final data = _lexiconBox?.get(id);
      if (data == null) return [];
      
      final list = data as List;
      return list.map((item) => Lexeme.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      print('⚠️ Erreur lexemes($id): $e');
      return [];
    }
  }
  
  /// Recherche un lemme spécifique dans tout le lexique
  /// 
  /// [lemma] : Lemme à rechercher (ex: "agapē")
  /// 
  /// Retourne : Liste de versets contenant ce lemme
  static Future<List<LexemeOccurrence>> searchLemma(String lemma) async {
    final occurrences = <LexemeOccurrence>[];
    
    try {
      final allKeys = _lexiconBox?.keys ?? [];
      
      for (final key in allKeys) {
        final lexemes = await LexiconService.lexemes(key as String);
        
        for (final lex in lexemes) {
          if (lex.lemma.toLowerCase() == lemma.toLowerCase()) {
            occurrences.add(LexemeOccurrence(
              verseId: key,
              lexeme: lex,
            ));
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur searchLemma($lemma): $e');
    }
    
    return occurrences;
  }
  
  /// Hydrate la box depuis les assets JSON
  static Future<void> hydrateFromAssets(Map<String, dynamic> lexiconData) async {
    print('💧 Hydratation LexiconService...');
    
    int count = 0;
    for (final entry in lexiconData.entries) {
      await _lexiconBox?.put(entry.key, entry.value);
      count++;
    }
    
    print('✅ $count entrées hydratées dans bible_lexicon');
  }
}

/// Lexème (mot original grec/hébreu)
class Lexeme {
  final String lemma;      // Forme de base (ex: "agapē")
  final String lang;       // 'grc' (grec) ou 'heb' (hébreu)
  final String gloss;      // Traduction courte (ex: "amour divin")
  final String? definition; // Définition longue (optionnel)
  final String? strongsNumber; // Numéro Strong (optionnel)
  
  Lexeme({
    required this.lemma,
    required this.lang,
    required this.gloss,
    this.definition,
    this.strongsNumber,
  });
  
  factory Lexeme.fromJson(Map<String, dynamic> json) {
    return Lexeme(
      lemma: json['lemma'] as String,
      lang: json['lang'] as String,
      gloss: json['gloss'] as String,
      definition: json['definition'] as String?,
      strongsNumber: json['strongs'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'lemma': lemma,
      'lang': lang,
      'gloss': gloss,
      if (definition != null) 'definition': definition,
      if (strongsNumber != null) 'strongs': strongsNumber,
    };
  }
  
  /// Langue lisible
  String get languageName => lang == 'grc' ? 'Grec' : 'Hébreu';
  
  /// Flag emoji
  String get languageFlag => lang == 'grc' ? '🇬🇷' : '🇮🇱';
}

/// Occurrence d'un lexème
class LexemeOccurrence {
  final String verseId;
  final Lexeme lexeme;
  
  LexemeOccurrence({
    required this.verseId,
    required this.lexeme,
  });
}




