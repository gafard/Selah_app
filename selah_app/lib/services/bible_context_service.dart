import 'package:hive/hive.dart';
import 'semantic_passage_boundary_service.dart';
// Service supprimé (packs incomplets)
import 'biblical_timeline_service.dart';

/// 🧠 PROPHÈTE - Service de contexte biblique avec intelligence sémantique
/// 
/// Niveau : Prophète (Intelligent) - Service intelligent pour le contexte biblique
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (FALCON X)
/// 🔥 Priorité 2: thompson_plan_service.dart (thèmes)
/// 🔥 Priorité 3: cross_ref_service.dart (références)
/// 🎯 Thompson: Enrichit le contexte avec thèmes spirituels
/// 
/// Sources de données :
/// - Hive box 'bible_context'
/// - Hydratée depuis assets/jsons/ au premier lancement
/// - ENRICHI par FALCON X et Thompson
/// 
/// 100% offline, pas de dépendance réseau
class BibleContextService {
  static Box? _contextBox;
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _contextBox = await Hive.openBox('bible_context');
    print('✅ BibleContextService initialisé (${_contextBox?.length ?? 0} entrées)');
  }
  
  /// Récupère le contexte historique d'un verset
  /// 
  /// [id] : ID du verset (ex: "Matthieu.5.3")
  /// 
  /// Retourne : Contexte historique ou null
  static Future<String?> historical(String id) async {
    try {
      final data = _contextBox?.get('historical_$id');
      return data as String?;
    } catch (e) {
      print('⚠️ Erreur historical($id): $e');
      return null;
    }
  }
  
  /// Récupère le contexte culturel d'un verset
  /// 
  /// [id] : ID du verset (ex: "Matthieu.5.3")
  /// 
  /// Retourne : Contexte culturel ou null
  static Future<String?> cultural(String id) async {
    try {
      final data = _contextBox?.get('cultural_$id');
      return data as String?;
    } catch (e) {
      print('⚠️ Erreur cultural($id): $e');
      return null;
    }
  }
  
  /// Récupère les informations sur l'auteur
  /// 
  /// [id] : ID du verset ou livre (ex: "Matthieu.5.3" ou "Matthieu")
  /// 
  /// Retourne : Bio courte de l'auteur + source
  static Future<AuthorInfo?> author(String id) async {
    try {
      // Extraire le livre de l'ID
      final book = id.split('.').first;
      
      final data = _contextBox?.get('author_$book');
      if (data == null) return null;
      
      return AuthorInfo.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      print('⚠️ Erreur author($id): $e');
      return null;
    }
  }
  
  /// Récupère les informations sur les personnages d'un passage
  /// 
  /// [id] : ID du verset (ex: "Jean.3.16")
  /// 
  /// Retourne : Liste des personnages mentionnés
  static Future<List<Character>> characters(String id) async {
    try {
      final data = _contextBox?.get('characters_$id');
      if (data == null) return [];
      
      final list = data as List;
      return list.map((item) => Character.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      print('⚠️ Erreur characters($id): $e');
      return [];
    }
  }
  
  /// 🧠 Récupère un contexte complet intelligent (historique + culturel + auteur + sémantique)
  /// 
  /// [id] : ID du verset
  /// 
  /// Retourne : Objet IntelligentContextData complet avec FALCON X et Thompson
  static Future<IntelligentContextData> getFullContext(String id) async {
    // 🔥 PRIORITÉ 1: Contexte de base
    final hist = await historical(id);
    final cult = await cultural(id);
    final auth = await author(id);
    final chars = await characters(id);
    
    // 🔥 PRIORITÉ 1: Contexte sémantique FALCON X
    final semanticContext = await _getSemanticContext(id);
    
    // 🔥 PRIORITÉ 1.5: Contexte ISBE enrichi
    final isbeContext = await _getISBEContext(id);
    
    // 🔥 PRIORITÉ 2: Thèmes Thompson
    final thompsonTheme = await _getThompsonTheme(id);
    
    // 🔥 PRIORITÉ 3: Références croisées
    final crossReferences = await _getCrossReferences(id);
    
    return IntelligentContextData(
      verseId: id,
      historical: hist,
      cultural: cult,
      author: auth,
      characters: chars,
      semanticContext: semanticContext,
      isbeContext: isbeContext,
      thompsonTheme: thompsonTheme,
      crossReferences: crossReferences,
    );
  }

  /// 🔥 PRIORITÉ 1: Récupère le contexte sémantique via FALCON X
  static Future<SemanticContext?> _getSemanticContext(String id) async {
    try {
      // Extraire livre et chapitre de l'ID
      final parts = id.split('.');
      if (parts.length < 2) return null;
      
      final book = parts[0];
      final chapter = int.tryParse(parts[1]);
      if (chapter == null) return null;
      
      // Utiliser FALCON X pour trouver l'unité sémantique
      final unit = SemanticPassageBoundaryService.findUnitContaining(book, chapter);
      if (unit == null) return null;
      
      return SemanticContext(
        unitName: unit.name,
        priority: unit.priority.name,
        theme: unit.theme ?? '',
        liturgicalContext: unit.liturgicalContext,
        emotionalTones: unit.emotionalTones ?? [],
        annotation: unit.annotation,
      );
    } catch (e) {
      print('⚠️ Erreur contexte sémantique: $e');
      return null;
    }
  }

  /// Service supprimé (packs incomplets)
  static Future<Map<String, dynamic>?> _getISBEContext(String id) async {
    return null;
  }

  /// 🔥 PRIORITÉ 2: Récupère le thème Thompson enrichi avec Timeline
  static Future<String?> _getThompsonTheme(String id) async {
    try {
      // Initialiser le service Timeline
      await BiblicalTimelineService.init();
      
      // Extraire le livre de l'ID
      final book = id.split('.').first;
      
      // Récupérer la période historique pour ce livre
      final period = await BiblicalTimelineService.getPeriodForBook(book);
      
      // Thèmes de base par livre
      String baseTheme = '';
      if (book.contains('Psaumes')) {
        baseTheme = 'Vie de prière — Souffle spirituel';
      } else if (book.contains('Jean')) {
        baseTheme = 'Exigence spirituelle — Transformation profonde';
      } else if (book.contains('Matthieu')) {
        baseTheme = 'Ne vous inquiétez pas — Apprentissages de Mt 6';
      } else if (book.contains('Romains')) {
        baseTheme = 'Doctrine de la justification — Grâce et foi';
      } else if (book.contains('Éphésiens')) {
        baseTheme = 'Unité en Christ — Église et famille';
      } else if (book.contains('Philippiens')) {
        baseTheme = 'Joie en Christ — Humilité et service';
      } else if (book.contains('Colossiens')) {
        baseTheme = 'Prééminence de Christ — Sagesse et connaissance';
      } else if (book.contains('Galates')) {
        baseTheme = 'Liberté en Christ — Loi et grâce';
      } else if (book.contains('1 Corinthiens')) {
        baseTheme = 'Unité de l\'Église — Amour et charismes';
      } else if (book.contains('2 Corinthiens')) {
        baseTheme = 'Ministère de la réconciliation — Faiblesse et puissance';
      } else if (book.contains('1 Thessaloniciens')) {
        baseTheme = 'Espérance du retour — Sanctification pratique';
      } else if (book.contains('2 Thessaloniciens')) {
        baseTheme = 'Retour de Christ — Persévérance et travail';
      } else if (book.contains('1 Timothée')) {
        baseTheme = 'Ordre dans l\'Église — Doctrine et pratique';
      } else if (book.contains('2 Timothée')) {
        baseTheme = 'Fidélité au ministère — Transmission de la foi';
      } else if (book.contains('Tite')) {
        baseTheme = 'Organisation de l\'Église — Bonnes œuvres';
      } else if (book.contains('Philémon')) {
        baseTheme = 'Réconciliation personnelle — Amour fraternel';
      } else if (book.contains('Hébreux')) {
        baseTheme = 'Prééminence de Christ — Nouvelle alliance';
      } else if (book.contains('Jacques')) {
        baseTheme = 'Foi et œuvres — Sagesse pratique';
      } else if (book.contains('1 Pierre')) {
        baseTheme = 'Espérance vivante — Souffrance et gloire';
      } else if (book.contains('2 Pierre')) {
        baseTheme = 'Croissance spirituelle — Fausses doctrines';
      } else if (book.contains('1 Jean')) {
        baseTheme = 'Communion avec Dieu — Amour et vérité';
      } else if (book.contains('2 Jean')) {
        baseTheme = 'Marche dans la vérité — Amour et obéissance';
      } else if (book.contains('3 Jean')) {
        baseTheme = 'Hospitalité chrétienne — Vérité et amour';
      } else if (book.contains('Jude')) {
        baseTheme = 'Contendre pour la foi — Avertissement et exhortation';
      } else if (book.contains('Apocalypse')) {
        baseTheme = 'Révélation de Jésus-Christ — Espérance et victoire';
      }
      
      // Enrichir avec le contexte historique de la Timeline
      if (period != null) {
        final periodName = period['name'] as String? ?? '';
        final periodThemes = period['themes'] as List<dynamic>? ?? [];
        
        if (periodThemes.isNotEmpty) {
          final timelineThemes = periodThemes.take(2).join(' • ');
          baseTheme = baseTheme.isNotEmpty 
              ? '$baseTheme — Contexte: $timelineThemes'
              : 'Contexte historique: $timelineThemes';
        }
      }
      
      return baseTheme.isNotEmpty ? baseTheme : null;
    } catch (e) {
      print('⚠️ Erreur thème Thompson enrichi: $e');
      return null;
    }
  }

  /// 🔥 PRIORITÉ 3: Récupère les références croisées
  static Future<List<String>> _getCrossReferences(String id) async {
    try {
      // TODO: Intégrer avec cross_ref_service pour récupérer les références
      return []; // Placeholder
    } catch (e) {
      print('⚠️ Erreur références croisées: $e');
      return [];
    }
  }

  
  /// Hydrate la box depuis les assets JSON
  /// 
  /// À appeler une seule fois au premier lancement
  static Future<void> hydrateFromAssets({
    required Map<String, dynamic> historicalData,
    required Map<String, dynamic> culturalData,
    required Map<String, dynamic> authorsData,
    required Map<String, dynamic> charactersData,
  }) async {
    print('💧 Hydratation BibleContextService...');
    
    int count = 0;
    
    // Contexte historique
    for (final entry in historicalData.entries) {
      await _contextBox?.put('historical_${entry.key}', entry.value);
      count++;
    }
    
    // Contexte culturel
    for (final entry in culturalData.entries) {
      await _contextBox?.put('cultural_${entry.key}', entry.value);
      count++;
    }
    
    // Auteurs
    for (final entry in authorsData.entries) {
      await _contextBox?.put('author_${entry.key}', entry.value);
      count++;
    }
    
    // Personnages
    for (final entry in charactersData.entries) {
      await _contextBox?.put('characters_${entry.key}', entry.value);
      count++;
    }
    
    print('✅ $count entrées hydratées dans bible_context');
  }
}

/// Informations sur un auteur biblique
class AuthorInfo {
  final String name;
  final String shortBio;
  final String role;
  final List<String> otherBooks;
  final String? timeline;
  
  AuthorInfo({
    required this.name,
    required this.shortBio,
    required this.role,
    required this.otherBooks,
    this.timeline,
  });
  
  factory AuthorInfo.fromJson(Map<String, dynamic> json) {
    return AuthorInfo(
      name: json['name'] as String,
      shortBio: json['bio'] as String,
      role: json['role'] as String,
      otherBooks: List<String>.from(json['other_books'] ?? []),
      timeline: json['timeline'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bio': shortBio,
      'role': role,
      'other_books': otherBooks,
      'timeline': timeline,
    };
  }
}

/// Informations sur un personnage biblique
class Character {
  final String name;
  final String description;
  final List<String> keyPassages;
  
  Character({
    required this.name,
    required this.description,
    required this.keyPassages,
  });
  
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'] as String,
      description: json['description'] as String,
      keyPassages: List<String>.from(json['key_passages'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'key_passages': keyPassages,
    };
  }
}

/// 🧠 Contexte sémantique FALCON X
class SemanticContext {
  final String unitName;
  final String priority;
  final String theme;
  final String? liturgicalContext;
  final List<String> emotionalTones;
  final String? annotation;
  
  SemanticContext({
    required this.unitName,
    required this.priority,
    required this.theme,
    this.liturgicalContext,
    this.emotionalTones = const [],
    this.annotation,
  });
}

/// 🧠 Données de contexte complètes intelligentes
class IntelligentContextData {
  final String verseId;
  final String? historical;
  final String? cultural;
  final AuthorInfo? author;
  final List<Character> characters;
  final SemanticContext? semanticContext;
  final Map<String, dynamic>? isbeContext;
  final String? thompsonTheme;
  final List<String> crossReferences;
  
  IntelligentContextData({
    required this.verseId,
    this.historical,
    this.cultural,
    this.author,
    this.characters = const [],
    this.semanticContext,
    this.isbeContext,
    this.thompsonTheme,
    this.crossReferences = const [],
  });
  
  /// Indique si des données sont disponibles
  bool get hasData => historical != null || 
                     cultural != null || 
                     author != null || 
                     characters.isNotEmpty ||
                     semanticContext != null ||
                     isbeContext != null ||
                     thompsonTheme != null ||
                     crossReferences.isNotEmpty;
  
  /// Indique si le contexte est enrichi par FALCON X
  bool get hasSemanticContext => semanticContext != null;
  
  /// Indique si le contexte est enrichi par ISBE
  bool get hasISBEContext => isbeContext != null;
  
  /// Indique si le contexte est enrichi par Thompson
  bool get hasThompsonTheme => thompsonTheme != null;
}

/// Données de contexte complètes (legacy)
class ContextData {
  final String verseId;
  final String? historical;
  final String? cultural;
  final AuthorInfo? author;
  final List<Character> characters;
  
  ContextData({
    required this.verseId,
    this.historical,
    this.cultural,
    this.author,
    this.characters = const [],
  });
  
  /// Indique si des données sont disponibles
  bool get hasData => historical != null || cultural != null || author != null || characters.isNotEmpty;
}


