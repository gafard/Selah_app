import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'mirror_verse_service.dart';

/// Service étendu pour les connexions typologiques
/// Gère 1,800+ connexions au lieu de 36
class MirrorVerseExtendedService {
  static Box? _extendedMirrorsBox;
  static Map<String, dynamic>? _extendedMirrorsData;
  static bool _isLoading = false;

  /// Initialise le service étendu
  static Future<void> init() async {
    if (_extendedMirrorsBox != null || _isLoading) return;
    
    print('🔄 Initialisation MirrorVerseExtendedService...');
    _isLoading = true;
    try {
      // Initialiser la box Hive étendue
      _extendedMirrorsBox = await Hive.openBox('bible_mirrors_extended');
      print('📦 Box Hive étendue ouverte');
      
      // Charger les données étendues depuis assets
      await _loadExtendedData();
      
      // Hydrater la box si nécessaire
      await _hydrateExtendedBox();
      
      print('✅ MirrorVerseExtendedService initialisé (${_extendedMirrorsBox?.length ?? 0} entrées)');
    } catch (e) {
      print('⚠️ Erreur initialisation MirrorVerseExtendedService: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Charge les données étendues depuis assets
  static Future<void> _loadExtendedData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/jsons/mirrors_extended.json');
      _extendedMirrorsData = json.decode(jsonString);
      print('📚 Données étendues chargées: ${_extendedMirrorsData?.length ?? 0} connexions');
      
      // Vérifier le format des données
      if (_extendedMirrorsData != null && _extendedMirrorsData!.isNotEmpty) {
        final firstKey = _extendedMirrorsData!.keys.first;
        final firstValue = _extendedMirrorsData![firstKey];
        print('🔍 Format détecté: ${firstValue.runtimeType} (exemple: $firstKey → $firstValue)');
      }
    } catch (e) {
      print('⚠️ Erreur chargement données étendues: $e');
      _extendedMirrorsData = {};
    }
  }

  /// Hydrate la box avec les données étendues
  static Future<void> _hydrateExtendedBox() async {
    if (_extendedMirrorsData == null || _extendedMirrorsBox == null) return;
    
    try {
      // Vérifier si déjà hydraté
      if (_extendedMirrorsBox!.isNotEmpty) {
        print('📦 Box étendue déjà hydratée');
        return;
      }

      // Hydrater avec les données étendues
      for (final entry in _extendedMirrorsData!.entries) {
        await _extendedMirrorsBox!.put(entry.key, entry.value);
      }
      
      print('✅ Box étendue hydratée avec ${_extendedMirrorsData!.length} connexions');
    } catch (e) {
      print('⚠️ Erreur hydratation box étendue: $e');
    }
  }

  /// Récupère le verset miroir étendu d'un verset
  ///
  /// [id] : ID du verset (ex: "Genèse.1.1")
  ///
  /// Retourne : ID du verset miroir ou null
  static Future<String?> extendedMirrorOf(String id) async {
    try {
      // Chercher dans les données étendues
      final forward = _extendedMirrorsBox?.get(id) as String?;
      if (forward != null) return forward;

      // Chercher en sens inverse
      final allKeys = _extendedMirrorsBox?.keys ?? [];
      for (final key in allKeys) {
        final value = _extendedMirrorsBox?.get(key) as String?;
        if (value == id) return key as String;
      }

      return null;
    } catch (e) {
      print('⚠️ Erreur extendedMirrorOf($id): $e');
      return null;
    }
  }

  /// Récupère le verset miroir enrichi étendu
  ///
  /// [id] : ID du verset
  /// [getVerseText] : Fonction pour récupérer le texte
  ///
  /// Retourne : MirrorVerse enrichi ou null
  static Future<MirrorVerse?> enrichedExtendedMirror(
    String id, {
    required Future<String?> Function(String verseId) getVerseText,
  }) async {
    final mirrorId = await extendedMirrorOf(id);
    if (mirrorId == null) return null;

    final originalText = await getVerseText(id);
    final mirrorText = await getVerseText(mirrorId);
    final connection = _getExtendedConnectionType(id, mirrorId);

    return MirrorVerse(
      originalId: id,
      mirrorId: mirrorId,
      originalText: originalText,
      mirrorText: mirrorText,
      connectionType: connection,
      explanation: _getExtendedExplanation(id, mirrorId),
    );
  }

  /// Détermine le type de connexion étendue
  static ConnectionType _getExtendedConnectionType(String originalId, String mirrorId) {
    final originalBook = originalId.split('.')[0];
    final mirrorBook = mirrorId.split('.').first;
    
    // Connexions prophétiques majeures
    if (_isPropheticConnection(originalId, mirrorId)) {
      return ConnectionType.prophecyFulfillment;
    }
    
    // Connexions typologiques
    if (_isTypologicalConnection(originalId, mirrorId)) {
      return ConnectionType.typology;
    }
    
    // Connexions thématiques
    if (_isThematicConnection(originalId, mirrorId)) {
      return ConnectionType.echo;
    }
    
    // Connexions littéraires
    if (_isLiteraryConnection(originalId, mirrorId)) {
      return ConnectionType.echo;
    }
    
    // Connexions historiques
    if (_isHistoricalConnection(originalId, mirrorId)) {
      return ConnectionType.parallel;
    }
    
    return ConnectionType.parallel;
  }

  /// Vérifie si c'est une connexion prophétique
  static bool _isPropheticConnection(String originalId, String mirrorId) {
    final propheticBooks = ['Ésaïe', 'Jérémie', 'Ézéchiel', 'Daniel', 'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas', 'Michée', 'Nahum', 'Habacuc', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie'];
    final originalBook = originalId.split('.')[0];
    final mirrorBook = mirrorId.split('.').first;
    
    return propheticBooks.contains(originalBook) && 
           ['Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', 'Romains', '1Corinthiens', '2Corinthiens', 'Galates', 'Éphésiens', 'Philippiens', 'Colossiens', '1Thessaloniciens', '2Thessaloniciens', '1Timothée', '2Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques', '1Pierre', '2Pierre', '1Jean', '2Jean', '3Jean', 'Jude', 'Apocalypse'].contains(mirrorBook);
  }

  /// Vérifie si c'est une connexion typologique
  static bool _isTypologicalConnection(String originalId, String mirrorId) {
    final typologicalPairs = [
      ['Genèse', 'Matthieu'], ['Exode', 'Jean'], ['Lévitique', 'Hébreux'],
      ['Nombres', '1Corinthiens'], ['Deutéronome', 'Galates'], ['Josué', 'Actes'],
      ['Juges', '2Corinthiens'], ['Ruth', 'Éphésiens'], ['1Samuel', 'Philippiens'],
      ['2Samuel', 'Colossiens'], ['1Rois', '1Thessaloniciens'], ['2Rois', '2Thessaloniciens'],
      ['1Chroniques', '1Timothée'], ['2Chroniques', '2Timothée'], ['Esdras', 'Tite'],
      ['Néhémie', 'Philémon'], ['Esther', 'Hébreux'], ['Job', 'Jacques'],
      ['Psaumes', '1Pierre'], ['Proverbes', '2Pierre'], ['Ecclésiaste', '1Jean'],
      ['Cantique', '2Jean'], ['Ésaïe', '3Jean'], ['Jérémie', 'Jude'],
      ['Lamentations', 'Apocalypse'], ['Ézéchiel', 'Marc'], ['Daniel', 'Luc']
    ];
    
    final originalBook = originalId.split('.')[0];
    final mirrorBook = mirrorId.split('.').first;
    
    return typologicalPairs.any((pair) => 
      pair[0] == originalBook && pair[1] == mirrorBook);
  }

  /// Vérifie si c'est une connexion thématique
  static bool _isThematicConnection(String originalId, String mirrorId) {
    // Logique pour identifier les connexions thématiques
    // Basée sur des mots-clés communs, des concepts similaires, etc.
    return false; // À implémenter selon les besoins
  }

  /// Vérifie si c'est une connexion littéraire
  static bool _isLiteraryConnection(String originalId, String mirrorId) {
    // Logique pour identifier les échos littéraires
    // Basée sur des structures similaires, des motifs récurrents, etc.
    return false; // À implémenter selon les besoins
  }

  /// Vérifie si c'est une connexion historique
  static bool _isHistoricalConnection(String originalId, String mirrorId) {
    // Logique pour identifier les références historiques
    // Basée sur des événements, des personnages, des lieux communs
    return false; // À implémenter selon les besoins
  }

  /// Génère une explication étendue
  static String _getExtendedExplanation(String originalId, String mirrorId) {
    final originalBook = originalId.split('.')[0];
    final mirrorBook = mirrorId.split('.').first;
    
    if (_isPropheticConnection(originalId, mirrorId)) {
      return 'Cette prophétie de $originalBook trouve son accomplissement dans $mirrorBook, démontrant la continuité divine entre l\'Ancien et le Nouveau Testament.';
    }
    
    if (_isTypologicalConnection(originalId, mirrorId)) {
      return 'Ce passage de $originalBook préfigure le message de $mirrorBook, illustrant la typologie biblique où l\'AT annonce le NT.';
    }
    
    return 'Cette connexion entre $originalBook et $mirrorBook révèle l\'unité profonde des Écritures et la cohérence du plan divin.';
  }

  /// Recherche étendue par thème
  static Future<List<Map<String, String>>> searchByTheme(String theme) async {
    final results = <Map<String, String>>[];
    
    if (_extendedMirrorsBox == null) return results;
    
    try {
      final allKeys = _extendedMirrorsBox!.keys;
      for (final key in allKeys) {
        final value = _extendedMirrorsBox!.get(key) as String?;
        if (value != null) {
          // Logique de recherche par thème
          // À implémenter selon les besoins
        }
      }
    } catch (e) {
      print('⚠️ Erreur recherche par thème: $e');
    }
    
    return results;
  }

  /// Recherche étendue par livre
  static Future<List<Map<String, String>>> searchByBook(String book) async {
    final results = <Map<String, String>>[];
    
    if (_extendedMirrorsBox == null) return results;
    
    try {
      final allKeys = _extendedMirrorsBox!.keys;
      for (final key in allKeys) {
        final value = _extendedMirrorsBox!.get(key) as String?;
        if (value != null && (key.toString().startsWith(book) || value.startsWith(book))) {
          results.add({
            'original': key.toString(),
            'mirror': value,
            'connection': _getExtendedConnectionType(key.toString(), value).toString(),
          });
        }
      }
    } catch (e) {
      print('⚠️ Erreur recherche par livre: $e');
    }
    
    return results;
  }

  /// Statistiques étendues
  static Future<Map<String, int>> getExtendedStats() async {
    if (_extendedMirrorsBox == null) return {};
    
    final stats = <String, int>{
      'total_connections': _extendedMirrorsBox!.length,
      'prophetic': 0,
      'typological': 0,
      'thematic': 0,
      'literary': 0,
      'historical': 0,
    };
    
    try {
      final allKeys = _extendedMirrorsBox!.keys;
      for (final key in allKeys) {
        final value = _extendedMirrorsBox!.get(key) as String?;
        if (value != null) {
          final connectionType = _getExtendedConnectionType(key.toString(), value);
          switch (connectionType) {
            case ConnectionType.prophecyFulfillment:
              stats['prophetic'] = (stats['prophetic'] ?? 0) + 1;
              break;
            case ConnectionType.typology:
              stats['typological'] = (stats['typological'] ?? 0) + 1;
              break;
            case ConnectionType.echo:
              stats['thematic'] = (stats['thematic'] ?? 0) + 1;
              break;
            case ConnectionType.parallel:
              stats['literary'] = (stats['literary'] ?? 0) + 1;
              break;
            default:
              stats['historical'] = (stats['historical'] ?? 0) + 1;
              break;
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur calcul statistiques: $e');
    }
    
    return stats;
  }

  /// Réinitialise les données étendues
  static Future<void> resetExtendedData() async {
    try {
      await _extendedMirrorsBox?.clear();
      await _loadExtendedData();
      await _hydrateExtendedBox();
      print('✅ Données étendues réinitialisées');
    } catch (e) {
      print('⚠️ Erreur réinitialisation données étendues: $e');
    }
  }
}
