import 'dart:convert';
import 'package:flutter/services.dart';

/// Service pour les personnages bibliques enrichis basé sur la Bible d'étude Thompson
class ThomsonCharactersService {
  static Map<String, dynamic>? _charactersData;
  static bool _isLoading = false;

  /// Initialise le service (chargement à la demande - optimisé)
  static Future<void> init() async {
    if (_charactersData != null || _isLoading) return;

    _isLoading = true;
    try {
      // Charger les données de personnages depuis assets/data
      final String jsonString = await rootBundle.loadString('assets/data/thomson_characters_enriched.json');
      _charactersData = json.decode(jsonString);
      final characterDescriptions = _charactersData!['character_descriptions'] as Map<String, dynamic>? ?? {};
      print('✅ ThomsonCharactersService initialisé avec ${characterDescriptions.length} personnages');
    } catch (e) {
      print('⚠️ Erreur chargement personnages Thomson: $e');
      // Utiliser des données par défaut si le fichier n'existe pas
      _charactersData = _getDefaultCharactersData();
    } finally {
      _isLoading = false;
    }
  }

  /// Données de personnages par défaut
  static Map<String, dynamic> _getDefaultCharactersData() {
    return {
      'characters': [
        {
          'name': 'Jésus-Christ',
          'description': 'Fils de Dieu, Sauveur du monde, Messie promis',
          'shortDescription': 'Fils de Dieu, Sauveur du monde',
          'keyPassages': ['Jean 3:16', 'Matthieu 28:18-20', 'Philippiens 2:5-11'],
          'themes': ['salut', 'amour', 'sacrifice', 'résurrection', 'royaume'],
          'period': 'Vie de Jésus',
          'books': ['Matthieu', 'Marc', 'Luc', 'Jean']
        },
        {
          'name': 'Pierre',
          'description': 'Apôtre de Jésus, pêcheur de Galilée, leader de l\'Église primitive',
          'shortDescription': 'Apôtre de Jésus, pêcheur de Galilée',
          'keyPassages': ['Matthieu 16:13-20', 'Actes 2:14-41', '1 Pierre 1:1-2'],
          'themes': ['foi', 'repentance', 'leadership', 'témoignage'],
          'period': 'Vie de Jésus, Église Primitive',
          'books': ['Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', '1 Pierre', '2 Pierre']
        },
        {
          'name': 'Paul',
          'description': 'Apôtre des Gentils, ancien pharisien, auteur de nombreuses épîtres',
          'shortDescription': 'Apôtre des Gentils, ancien pharisien',
          'keyPassages': ['Actes 9:1-19', 'Romains 1:1-7', 'Philippiens 3:4-11'],
          'themes': ['conversion', 'évangélisation', 'doctrine', 'souffrance'],
          'period': 'Église Primitive',
          'books': ['Actes', 'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens', 'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée', '2 Timothée', 'Tite', 'Philémon']
        },
        {
          'name': 'Moïse',
          'description': 'Libérateur d\'Israël, législateur, prophète de Dieu',
          'shortDescription': 'Libérateur d\'Israël, législateur',
          'keyPassages': ['Exode 3:1-15', 'Exode 20:1-17', 'Deutéronome 34:1-12'],
          'themes': ['libération', 'loi', 'alliance', 'intercession'],
          'period': 'Exode et Désert',
          'books': ['Exode', 'Lévitique', 'Nombres', 'Deutéronome']
        },
        {
          'name': 'David',
          'description': 'Roi d\'Israël, homme selon le cœur de Dieu, auteur de psaumes',
          'shortDescription': 'Roi d\'Israël, homme selon le cœur de Dieu',
          'keyPassages': ['1 Samuel 16:1-13', '2 Samuel 7:1-17', 'Psaume 23:1-6'],
          'themes': ['royaume', 'adoration', 'repentance', 'alliance'],
          'period': 'Royaume Unifié',
          'books': ['1 Samuel', '2 Samuel', '1 Rois', 'Psaumes']
        }
      ]
    };
  }

  /// Récupère tous les personnages
  static Future<List<Map<String, dynamic>>> getAllCharacters() async {
    await init();
    if (_charactersData != null) {
      final characterDescriptions = _charactersData!['character_descriptions'] as Map<String, dynamic>? ?? {};
      final characters = <Map<String, dynamic>>[];
      
      for (final entry in characterDescriptions.entries) {
        final name = entry.key;
        final descriptions = entry.value as List<dynamic>? ?? [];
        
        // Prendre la première description comme description principale
        final mainDescription = descriptions.isNotEmpty ? descriptions.first.toString() : 'Personnage biblique';
        
        // Créer une description courte (premiers 200 caractères pour plus de détails)
        final shortDescription = mainDescription.length > 200 
            ? '${mainDescription.substring(0, 200)}...' 
            : mainDescription;
        
        characters.add({
          'name': name,
          'description': mainDescription,
          'shortDescription': shortDescription,
          'keyPassages': [],
          'themes': [],
          'period': 'Période biblique',
          'books': [],
        });
      }
      
      print('✅ ${characters.length} personnages chargés depuis ThomsonCharactersService');
      return characters;
    }
    return [];
  }

  /// Recherche un personnage par nom
  static Future<Map<String, dynamic>?> getCharacterByName(String name) async {
    await init();
    
    if (_charactersData != null) {
      final characterDescriptions = _charactersData!['character_descriptions'] as Map<String, dynamic>? ?? {};
      
      for (final entry in characterDescriptions.entries) {
        final characterName = entry.key;
        final descriptions = entry.value as List<dynamic>? ?? [];
        
        if (characterName.toLowerCase() == name.toLowerCase()) {
          final mainDescription = descriptions.isNotEmpty ? descriptions.first.toString() : 'Personnage biblique';
          final shortDescription = mainDescription.length > 200 
              ? '${mainDescription.substring(0, 200)}...' 
              : mainDescription;
          
          print('🔍 Personnage trouvé: $characterName - Description: $shortDescription');
          return {
            'name': characterName,
            'description': mainDescription,
            'shortDescription': shortDescription,
            'keyPassages': [],
            'themes': [],
            'period': 'Période biblique',
            'books': [],
          };
        }
      }
    }
    
    return null;
  }

  /// Recherche des personnages par nom partiel
  static Future<List<Map<String, dynamic>>> searchCharactersByName(String partialName) async {
    await init();
    final matchingCharacters = <Map<String, dynamic>>[];
    
    if (_charactersData != null) {
      final characterDescriptions = _charactersData!['character_descriptions'] as Map<String, dynamic>? ?? {};
      
      for (final entry in characterDescriptions.entries) {
        final characterName = entry.key;
        final descriptions = entry.value as List<dynamic>? ?? [];
        
        if (characterName.toLowerCase().contains(partialName.toLowerCase())) {
          final mainDescription = descriptions.isNotEmpty ? descriptions.first.toString() : 'Personnage biblique';
          final shortDescription = mainDescription.length > 200 
              ? '${mainDescription.substring(0, 200)}...' 
              : mainDescription;
          
          matchingCharacters.add({
            'name': characterName,
            'description': mainDescription,
            'shortDescription': shortDescription,
            'keyPassages': [],
            'themes': [],
            'period': 'Période biblique',
            'books': [],
          });
        }
      }
    }
    
    return matchingCharacters;
  }

  /// Recherche des personnages par thème
  static Future<List<Map<String, dynamic>>> searchCharactersByTheme(String theme) async {
    await init();
    final matchingCharacters = <Map<String, dynamic>>[];
    
    if (_charactersData != null) {
      final characters = _charactersData!['characters'] as List<dynamic>? ?? [];
      
      for (final character in characters) {
        final characterMap = character as Map<String, dynamic>;
        final themes = characterMap['themes'] as List<dynamic>? ?? [];
        
        if (themes.any((t) => t.toString().toLowerCase().contains(theme.toLowerCase()))) {
          matchingCharacters.add(characterMap);
        }
      }
    }
    
    return matchingCharacters;
  }

  /// Recherche des personnages par période
  static Future<List<Map<String, dynamic>>> searchCharactersByPeriod(String period) async {
    await init();
    final matchingCharacters = <Map<String, dynamic>>[];
    
    if (_charactersData != null) {
      final characters = _charactersData!['characters'] as List<dynamic>? ?? [];
      
      for (final character in characters) {
        final characterMap = character as Map<String, dynamic>;
        final characterPeriod = characterMap['period'] as String? ?? '';
        
        if (characterPeriod.toLowerCase().contains(period.toLowerCase())) {
          matchingCharacters.add(characterMap);
        }
      }
    }
    
    return matchingCharacters;
  }

  /// Recherche des personnages par livre biblique
  static Future<List<Map<String, dynamic>>> searchCharactersByBook(String bookName) async {
    await init();
    final matchingCharacters = <Map<String, dynamic>>[];
    
    if (_charactersData != null) {
      final characters = _charactersData!['characters'] as List<dynamic>? ?? [];
      
      for (final character in characters) {
        final characterMap = character as Map<String, dynamic>;
        final books = characterMap['books'] as List<dynamic>? ?? [];
        
        if (books.any((book) => book.toString().toLowerCase().contains(bookName.toLowerCase()))) {
          matchingCharacters.add(characterMap);
        }
      }
    }
    
    return matchingCharacters;
  }

  /// Récupère les personnages mentionnés dans un passage spécifique
  static Future<List<Map<String, dynamic>>> getCharactersInPassage(String reference) async {
    await init();
    final charactersInPassage = <Map<String, dynamic>>[];
    
    // Extraire le nom du livre de la référence
    final bookName = _extractBookFromReference(reference);
    if (bookName.isEmpty) return charactersInPassage;
    
    if (_charactersData != null) {
      final characters = _charactersData!['characters'] as List<dynamic>? ?? [];
      
      for (final character in characters) {
        final characterMap = character as Map<String, dynamic>;
        final books = characterMap['books'] as List<dynamic>? ?? [];
        
        if (books.any((book) => book.toString().toLowerCase().contains(bookName.toLowerCase()))) {
          charactersInPassage.add(characterMap);
        }
      }
    }
    
    return charactersInPassage;
  }

  /// Récupère la description courte d'un personnage
  static Future<String> getCharacterShortDescription(String name) async {
    final character = await getCharacterByName(name);
    return character?['shortDescription'] as String? ?? 'Personnage biblique';
  }

  /// Récupère la description complète d'un personnage
  static Future<String> getCharacterDescription(String name) async {
    final character = await getCharacterByName(name);
    return character?['description'] as String? ?? 'Personnage biblique mentionné dans les Écritures';
  }

  /// Récupère les passages clés d'un personnage
  static Future<List<String>> getCharacterKeyPassages(String name) async {
    final character = await getCharacterByName(name);
    if (character != null) {
      final passages = character['keyPassages'] as List<dynamic>? ?? [];
      return passages.map((passage) => passage.toString()).toList();
    }
    return [];
  }

  /// Récupère les thèmes associés à un personnage
  static Future<List<String>> getCharacterThemes(String name) async {
    final character = await getCharacterByName(name);
    if (character != null) {
      final themes = character['themes'] as List<dynamic>? ?? [];
      return themes.map((theme) => theme.toString()).toList();
    }
    return [];
  }

  /// Récupère la période d'un personnage
  static Future<String> getCharacterPeriod(String name) async {
    final character = await getCharacterByName(name);
    return character?['period'] as String? ?? 'Période inconnue';
  }

  /// Récupère les livres où un personnage apparaît
  static Future<List<String>> getCharacterBooks(String name) async {
    final character = await getCharacterByName(name);
    if (character != null) {
      final books = character['books'] as List<dynamic>? ?? [];
      return books.map((book) => book.toString()).toList();
    }
    return [];
  }

  /// Recherche avancée de personnages
  static Future<List<Map<String, dynamic>>> advancedCharacterSearch({
    String? name,
    String? theme,
    String? period,
    String? book,
    String? description,
  }) async {
    await init();
    final results = <Map<String, dynamic>>[];
    
    if (_charactersData != null) {
      final characters = _charactersData!['characters'] as List<dynamic>? ?? [];
      
      for (final character in characters) {
        final characterMap = character as Map<String, dynamic>;
        bool matches = true;
        
        if (name != null) {
          final characterName = characterMap['name'] as String? ?? '';
          if (!characterName.toLowerCase().contains(name.toLowerCase())) {
            matches = false;
          }
        }
        
        if (theme != null) {
          final themes = characterMap['themes'] as List<dynamic>? ?? [];
          if (!themes.any((t) => t.toString().toLowerCase().contains(theme.toLowerCase()))) {
            matches = false;
          }
        }
        
        if (period != null) {
          final characterPeriod = characterMap['period'] as String? ?? '';
          if (!characterPeriod.toLowerCase().contains(period.toLowerCase())) {
            matches = false;
          }
        }
        
        if (book != null) {
          final books = characterMap['books'] as List<dynamic>? ?? [];
          if (!books.any((b) => b.toString().toLowerCase().contains(book.toLowerCase()))) {
            matches = false;
          }
        }
        
        if (description != null) {
          final characterDescription = characterMap['description'] as String? ?? '';
          if (!characterDescription.toLowerCase().contains(description.toLowerCase())) {
            matches = false;
          }
        }
        
        if (matches) {
          results.add(characterMap);
        }
      }
    }
    
    return results;
  }

  /// Extrait le nom du livre d'une référence biblique
  static String _extractBookFromReference(String reference) {
    // Patterns courants pour extraire le nom du livre
    final patterns = [
      RegExp(r'^([A-Za-zÀ-ÿ\s]+)\s+\d+'),
      RegExp(r'^([A-Za-zÀ-ÿ\s]+)\s*:'),
      RegExp(r'^([A-Za-zÀ-ÿ\s]+)\s*$'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(reference.trim());
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    
    return '';
  }

  /// Vérifie si le service est initialisé
  static bool get isInitialized => _charactersData != null;

  /// Obtient le nombre de personnages disponibles
  static int get characterCount => _charactersData?['characters']?.length ?? 0;

  /// Obtient les données complètes des personnages
  static Future<Map<String, dynamic>?> getFullCharactersData() async {
    await init();
    return _charactersData;
  }
}

