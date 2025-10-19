import 'dart:convert';
import 'package:flutter/services.dart';

/// Service d'index thématique BSB optimisé et léger
class BSBTopicalService {
  static Map<String, dynamic>? _topicalData;
  static bool _isLoading = false;
  
  /// Initialise le service (chargement à la demande - optimisé)
  static Future<void> init() async {
    if (_topicalData != null || _isLoading) return;
    
    _isLoading = true;
    try {
      // Charger les vraies données BSB
      final String jsonString = await rootBundle.loadString('assets/data/bsb_topical_index_optimized.json');
      _topicalData = json.decode(jsonString);
      print('✅ BSBTopicalService initialisé avec ${_topicalData?.length ?? 0} thèmes BSB');
    } catch (e) {
      print('⚠️ Erreur chargement index thématique BSB: $e');
      _topicalData = {};
    } finally {
      _isLoading = false;
    }
  }
  
  /// Recherche un thème dans les vraies données BSB
  static Future<List<String>> searchTheme(String theme) async {
    await init();
    
    if (_topicalData == null) return [];
    
    final normalizedTheme = theme.toLowerCase().trim();
    
    // Recherche exacte d'abord
    for (final key in _topicalData!.keys) {
      if (key.toLowerCase() == normalizedTheme) {
        return List<String>.from(_topicalData![key]['references'] ?? []);
      }
    }
    
    // Recherche partielle (limité à 30 résultats)
    final matches = <String>[];
    for (final key in _topicalData!.keys) {
      if (key.toLowerCase().contains(normalizedTheme)) {
        matches.addAll(_topicalData![key]['references'] ?? []);
        if (matches.length >= 30) break; // Limiter les résultats
      }
    }
    
    return matches;
  }
  
  /// Recherche partielle de thèmes (limité à 20 résultats)
  static Future<List<String>> searchPartialTheme(String partial) async {
    await init();
    
    if (_topicalData == null) return [];
    
    final normalizedPartial = partial.toLowerCase().trim();
    final matches = <String>[];
    
    for (final theme in _topicalData!.keys) {
      if (theme.toLowerCase().contains(normalizedPartial)) {
        matches.add(theme);
        if (matches.length >= 20) break; // Limiter les résultats
      }
    }
    
    return matches;
  }
  
  /// Obtient les thèmes populaires pour la page d'accueil
  static Future<List<String>> getPopularThemes() async {
    await init();
    
    try {
      // Thèmes populaires prédéfinis
      final popularThemes = [
        'amour', 'foi', 'grâce', 'espérance', 'paix', 'joie', 'sagesse',
        'vérité', 'vie', 'mort', 'résurrection', 'salut', 'pardon',
        'justice', 'miséricorde', 'compassion', 'humilité', 'servir',
        'prière', 'adoration', 'sainteté', 'pureté', 'obéissance'
      ];
      
      return popularThemes;
    } catch (e) {
      print('❌ Erreur récupération thèmes populaires: $e');
      return ['amour', 'foi', 'grâce', 'espérance', 'paix'];
    }
  }
  
  /// Recherche les références d'un thème spécifique
  static Future<List<Map<String, dynamic>>> searchThemeReferences(String theme) async {
    await init();
    
    try {
      // Rechercher le thème dans les données
      final normalizedTheme = theme.toLowerCase().trim();
      
      for (final key in _topicalData!.keys) {
        if (key.toLowerCase() == normalizedTheme) {
          final data = _topicalData![key];
          final refs = List<String>.from(data['references'] ?? []);
          return refs.map((ref) => {
            'reference': ref,
            'book': ref.split(':')[0],
            'chapter': ref.split(':')[1].split('.')[0],
            'verse': ref.split(':')[1].split('.')[1],
            'weight': 1.0,
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Erreur recherche références thème: $e');
      return [];
    }
  }
  
  /// Vérifie si le service est initialisé
  static bool get isInitialized => _topicalData != null;
  
  /// Obtient le nombre de thèmes disponibles
  static int get themeCount => _topicalData?.length ?? 0;
}