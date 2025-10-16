import 'package:flutter/foundation.dart';

/// Service de fallback pour maintenir l'offline-first sur le web
/// 
/// Fournit des données par défaut quand les packs ZIP ne sont pas disponibles
class WebFallbackService {
  
  /// Données ISBE par défaut (extrait de l'encyclopédie)
  static const Map<String, Map<String, dynamic>> _defaultISBEData = {
    'jesus': {
      'title': 'Jésus-Christ',
      'content': 'Jésus-Christ est le Fils de Dieu, venu en chair pour sauver l\'humanité. Il est le Messie promis, mort sur la croix et ressuscité le troisième jour.',
      'category': 'Personnages bibliques',
    },
    'christ': {
      'title': 'Christ',
      'content': 'Le terme "Christ" signifie "Oint" en grec, équivalent de "Messie" en hébreu. Il désigne Jésus comme le Sauveur promis.',
      'category': 'Termes théologiques',
    },
    'bible': {
      'title': 'Bible',
      'content': 'La Bible est la Parole de Dieu, composée de l\'Ancien et du Nouveau Testament. Elle est inspirée par Dieu et utile pour l\'enseignement.',
      'category': 'Concepts fondamentaux',
    },
  };

  /// Thèmes OpenBible par défaut
  static const Map<String, Map<String, dynamic>> _defaultOpenBibleThemes = {
    'amour': {
      'name': 'Amour de Dieu',
      'description': 'L\'amour inconditionnel de Dieu pour l\'humanité, manifesté en Jésus-Christ.',
      'category': 'Relations',
    },
    'salut': {
      'name': 'Salut',
      'description': 'Le salut par la grâce, par le moyen de la foi en Jésus-Christ.',
      'category': 'Doctrine',
    },
    'foi': {
      'name': 'Foi',
      'description': 'La confiance en Dieu et en ses promesses, fondement de la vie chrétienne.',
      'category': 'Vie chrétienne',
    },
    'espérance': {
      'name': 'Espérance',
      'description': 'L\'espérance chrétienne basée sur les promesses de Dieu et la résurrection.',
      'category': 'Vie chrétienne',
    },
    'grâce': {
      'name': 'Grâce',
      'description': 'La faveur imméritée de Dieu, manifestée dans le salut par Jésus-Christ.',
      'category': 'Doctrine',
    },
  };

  /// Vérifie si on est en mode web
  static bool get isWebMode => kIsWeb;

  /// Récupère une entrée ISBE par défaut
  static Map<String, dynamic>? getDefaultISBEEntry(String keyword) {
    if (!isWebMode) return null;
    
    final lowerKeyword = keyword.toLowerCase();
    
    // Recherche exacte
    if (_defaultISBEData.containsKey(lowerKeyword)) {
      return _defaultISBEData[lowerKeyword];
    }
    
    // Recherche partielle
    for (final entry in _defaultISBEData.entries) {
      if (entry.key.contains(lowerKeyword) || lowerKeyword.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Récupère toutes les entrées ISBE par défaut
  static List<Map<String, dynamic>> getAllDefaultISBEEntries() {
    if (!isWebMode) return [];
    
    return _defaultISBEData.values.toList();
  }

  /// Récupère un thème OpenBible par défaut
  static Map<String, dynamic>? getDefaultOpenBibleTheme(String themeName) {
    if (!isWebMode) return null;
    
    final lowerTheme = themeName.toLowerCase();
    
    // Recherche exacte
    if (_defaultOpenBibleThemes.containsKey(lowerTheme)) {
      return _defaultOpenBibleThemes[lowerTheme];
    }
    
    // Recherche partielle
    for (final entry in _defaultOpenBibleThemes.entries) {
      if (entry.key.contains(lowerTheme) || lowerTheme.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Récupère tous les thèmes OpenBible par défaut
  static List<Map<String, dynamic>> getAllDefaultOpenBibleThemes() {
    if (!isWebMode) return [];
    
    return _defaultOpenBibleThemes.values.toList();
  }

  /// Recherche dans les données par défaut
  static List<Map<String, dynamic>> searchDefaultISBE(String query) {
    if (!isWebMode) return [];
    
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();
    
    for (final entry in _defaultISBEData.entries) {
      final data = entry.value;
      if (data['title']?.toLowerCase().contains(lowerQuery) == true ||
          data['content']?.toLowerCase().contains(lowerQuery) == true) {
        results.add(data);
      }
    }
    
    return results;
  }

  /// Recherche dans les thèmes par défaut
  static List<Map<String, dynamic>> searchDefaultOpenBibleThemes(String query) {
    if (!isWebMode) return [];
    
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();
    
    for (final entry in _defaultOpenBibleThemes.entries) {
      final data = entry.value;
      if (data['name']?.toLowerCase().contains(lowerQuery) == true ||
          data['description']?.toLowerCase().contains(lowerQuery) == true) {
        results.add(data);
      }
    }
    
    return results;
  }

  /// Récupère les catégories disponibles
  static List<String> getDefaultISBECategories() {
    if (!isWebMode) return [];
    
    final categories = <String>{};
    for (final data in _defaultISBEData.values) {
      if (data['category'] != null) {
        categories.add(data['category']);
      }
    }
    
    return categories.toList();
  }

  /// Récupère les catégories de thèmes disponibles
  static List<String> getDefaultOpenBibleCategories() {
    if (!isWebMode) return [];
    
    final categories = <String>{};
    for (final data in _defaultOpenBibleThemes.values) {
      if (data['category'] != null) {
        categories.add(data['category']);
      }
    }
    
    return categories.toList();
  }

  /// Indique si le service de fallback est actif
  static bool get isActive => isWebMode;

  /// Message d'information sur le mode fallback
  static String get fallbackMessage => 
      'Mode web: Utilisation des données par défaut (packs ZIP non disponibles)';
}
