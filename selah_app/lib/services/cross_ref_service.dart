import 'package:hive/hive.dart';

/// Service offline pour les références croisées bibliques
/// 
/// Sources de données :
/// - Hive box 'bible_crossrefs'
/// - Hydratée depuis assets/jsons/crossrefs.json
/// 
/// Format :
/// {
///   "Matthieu.5.3": ["Luc.6.20", "Psaumes.34.18"],
///   "Jean.3.16": ["1Jean.4.9", "Romains.5.8"],
///   ...
/// }
class CrossRefService {
  static Box? _crossRefsBox;
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _crossRefsBox = await Hive.openBox('bible_crossrefs');
    print('✅ CrossRefService initialisé (${_crossRefsBox?.length ?? 0} entrées)');
  }
  
  /// Récupère les références croisées d'un verset
  /// 
  /// [id] : ID du verset (ex: "Jean.3.16")
  /// 
  /// Retourne : Liste d'IDs de versets liés
  static Future<List<String>> crossRefs(String id) async {
    try {
      final data = _crossRefsBox?.get(id);
      if (data == null) return [];
      
      return List<String>.from(data as List);
    } catch (e) {
      print('⚠️ Erreur crossRefs($id): $e');
      return [];
    }
  }
  
  /// Récupère les références croisées enrichies avec les textes
  /// 
  /// [id] : ID du verset
  /// [getVerseText] : Fonction pour récupérer le texte d'un verset
  /// 
  /// Retourne : Liste de CrossReference avec textes
  static Future<List<CrossReference>> enrichedCrossRefs(
    String id, {
    required Future<String?> Function(String verseId) getVerseText,
  }) async {
    final refs = await crossRefs(id);
    final enriched = <CrossReference>[];
    
    for (final refId in refs) {
      final text = await getVerseText(refId);
      enriched.add(CrossReference(
        verseId: refId,
        reference: refId.replaceAll('.', ' ').replaceAll(' ', ' ', ), // "Jean.3.16" → "Jean 3:16"
        text: text,
      ));
    }
    
    return enriched;
  }
  
  /// Hydrate la box depuis les assets JSON
  static Future<void> hydrateFromAssets(Map<String, dynamic> crossRefsData) async {
    print('💧 Hydratation CrossRefService...');
    
    int count = 0;
    for (final entry in crossRefsData.entries) {
      await _crossRefsBox?.put(entry.key, entry.value);
      count++;
    }
    
    print('✅ $count entrées hydratées dans bible_crossrefs');
  }
  
  /// Recherche bidirectionnelle : trouve les versets qui référencent ce verset
  /// 
  /// [id] : ID du verset
  /// 
  /// Retourne : Liste d'IDs qui pointent vers ce verset
  static Future<List<String>> reverseRefs(String id) async {
    final reverse = <String>[];
    
    try {
      // Parcourir toutes les entrées pour trouver celles qui contiennent cet ID
      final allKeys = _crossRefsBox?.keys ?? [];
      
      for (final key in allKeys) {
        final refs = await crossRefs(key as String);
        if (refs.contains(id)) {
          reverse.add(key);
        }
      }
    } catch (e) {
      print('⚠️ Erreur reverseRefs($id): $e');
    }
    
    return reverse;
  }
}

/// Référence croisée enrichie
class CrossReference {
  final String verseId;
  final String reference;
  final String? text;
  
  CrossReference({
    required this.verseId,
    required this.reference,
    this.text,
  });
}




