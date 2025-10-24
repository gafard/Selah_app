import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/bible_highlight.dart';

/// Service pour gérer les surlignages bibliques
class BibleHighlightService {
  static Box<dynamic>? _box;
  static bool _initialized = false;

  /// Initialiser le service
  static Future<void> init() async {
    if (_initialized) return;
    _box ??= await Hive.openBox<dynamic>('bible_highlights');
    _initialized = true;
  }

  /// Sauvegarder un surlignage
  static Future<void> saveHighlight(BibleHighlight highlight) async {
    await init();
    await _box!.put(highlight.id, highlight.toJson());
    print('✅ Surlignage sauvegardé: ${highlight.reference}');
  }

  /// Récupérer tous les surlignages
  static Future<List<BibleHighlight>> getAllHighlights() async {
    await init();
    final highlights = <BibleHighlight>[];
    
    for (final key in _box!.keys) {
      try {
        final data = _box!.get(key) as Map<String, dynamic>?;
        if (data != null) {
          highlights.add(BibleHighlight.fromJson(data));
        }
      } catch (e) {
        print('⚠️ Erreur lors du chargement du surlignage $key: $e');
      }
    }
    
    // Trier par date de création (plus récent en premier)
    highlights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return highlights;
  }

  /// Récupérer les surlignages pour une référence spécifique
  static Future<List<BibleHighlight>> getHighlightsForReference(String reference) async {
    await init();
    final allHighlights = await getAllHighlights();
    return allHighlights.where((h) => h.reference == reference).toList();
  }

  /// Récupérer les surlignages pour un livre
  static Future<List<BibleHighlight>> getHighlightsForBook(String book) async {
    await init();
    final allHighlights = await getAllHighlights();
    return allHighlights.where((h) => h.book == book).toList();
  }

  /// Récupérer les surlignages par couleur
  static Future<List<BibleHighlight>> getHighlightsByColor(Color color) async {
    await init();
    final allHighlights = await getAllHighlights();
    return allHighlights.where((h) => h.highlightColor.value == color.value).toList();
  }

  /// Récupérer les surlignages par tags
  static Future<List<BibleHighlight>> getHighlightsByTags(List<String> tags) async {
    await init();
    final allHighlights = await getAllHighlights();
    return allHighlights.where((h) => 
      tags.any((tag) => h.tags.contains(tag))
    ).toList();
  }

  /// Rechercher dans les surlignages
  static Future<List<BibleHighlight>> searchHighlights(String query) async {
    await init();
    final allHighlights = await getAllHighlights();
    final lowercaseQuery = query.toLowerCase();
    
    return allHighlights.where((h) => 
      h.selectedText.toLowerCase().contains(lowercaseQuery) ||
      h.reference.toLowerCase().contains(lowercaseQuery) ||
      h.book.toLowerCase().contains(lowercaseQuery) ||
      (h.note?.toLowerCase().contains(lowercaseQuery) ?? false) ||
      h.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Supprimer un surlignage
  static Future<void> deleteHighlight(String highlightId) async {
    await init();
    await _box!.delete(highlightId);
    print('🗑️ Surlignage supprimé: $highlightId');
  }

  /// Supprimer tous les surlignages
  static Future<void> deleteAllHighlights() async {
    await init();
    await _box!.clear();
    print('🗑️ Tous les surlignages supprimés');
  }

  /// Mettre à jour un surlignage
  static Future<void> updateHighlight(BibleHighlight highlight) async {
    await init();
    await _box!.put(highlight.id, highlight.toJson());
    print('✅ Surlignage mis à jour: ${highlight.reference}');
  }

  /// Obtenir les statistiques des surlignages
  static Future<Map<String, dynamic>> getHighlightStats() async {
    await init();
    final allHighlights = await getAllHighlights();
    
    final stats = <String, dynamic>{
      'total': allHighlights.length,
      'byColor': <String, int>{},
      'byBook': <String, int>{},
      'recent': 0,
    };
    
    // Compter par couleur
    for (final highlight in allHighlights) {
      final colorName = HighlightColor.getColorName(highlight.highlightColor);
      stats['byColor'][colorName] = (stats['byColor'][colorName] ?? 0) + 1;
      
      // Compter par livre
      stats['byBook'][highlight.book] = (stats['byBook'][highlight.book] ?? 0) + 1;
      
      // Compter les récents (7 derniers jours)
      final daysSince = DateTime.now().difference(highlight.createdAt).inDays;
      if (daysSince <= 7) {
        stats['recent']++;
      }
    }
    
    return stats;
  }

  /// Vérifier si un passage est déjà surligné
  static Future<bool> isPassageHighlighted(String reference) async {
    await init();
    final highlights = await getHighlightsForReference(reference);
    return highlights.isNotEmpty;
  }

  /// Obtenir les surlignages récents
  static Future<List<BibleHighlight>> getRecentHighlights({int days = 7}) async {
    await init();
    final allHighlights = await getAllHighlights();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return allHighlights.where((h) => h.createdAt.isAfter(cutoffDate)).toList();
  }

  /// Exporter les surlignages (pour sauvegarde/partage)
  static Future<Map<String, dynamic>> exportHighlights() async {
    await init();
    final allHighlights = await getAllHighlights();
    final stats = await getHighlightStats();
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'stats': stats,
      'highlights': allHighlights.map((h) => h.toJson()).toList(),
    };
  }

  /// Importer des surlignages
  static Future<void> importHighlights(Map<String, dynamic> data) async {
    await init();
    
    try {
      final highlights = data['highlights'] as List<dynamic>;
      for (final highlightData in highlights) {
        final highlight = BibleHighlight.fromJson(highlightData as Map<String, dynamic>);
        await saveHighlight(highlight);
      }
      print('✅ ${highlights.length} surlignages importés');
    } catch (e) {
      print('❌ Erreur lors de l\'import: $e');
      rethrow;
    }
  }
}
