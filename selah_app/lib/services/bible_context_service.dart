import 'package:hive/hive.dart';
import '../models/verse_key.dart';

/// Service offline pour le contexte biblique (historique, culturel, auteur)
/// 
/// Sources de données :
/// - Hive box 'bible_context'
/// - Hydratée depuis assets/jsons/ au premier lancement
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
  
  /// Récupère un contexte complet (historique + culturel + auteur)
  /// 
  /// [id] : ID du verset
  /// 
  /// Retourne : Objet ContextData complet
  static Future<ContextData> getFullContext(String id) async {
    final hist = await historical(id);
    final cult = await cultural(id);
    final auth = await author(id);
    final chars = await characters(id);
    
    return ContextData(
      verseId: id,
      historical: hist,
      cultural: cult,
      author: auth,
      characters: chars,
    );
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

/// Données de contexte complètes
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

