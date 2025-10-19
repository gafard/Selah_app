#!/usr/bin/env python3
"""
Script d'optimisation des données BSB pour réduire la taille
et ne garder que les données essentielles.
"""

import json
import os
from collections import Counter

def optimize_concordance(input_path, output_path, max_words=50000):
    """Optimise la concordance en gardant seulement les mots les plus fréquents"""
    print(f"🔧 Optimisation de la concordance...")
    
    with open(input_path, 'r', encoding='utf-8') as f:
        concordance = json.load(f)
    
    print(f"   📊 Données originales: {len(concordance)} mots")
    
    # Trier par fréquence d'occurrence
    word_frequencies = [(word, data['count']) for word, data in concordance.items()]
    word_frequencies.sort(key=lambda x: x[1], reverse=True)
    
    # Garder seulement les mots les plus fréquents
    top_words = word_frequencies[:max_words]
    optimized_concordance = {}
    
    for word, count in top_words:
        optimized_concordance[word] = concordance[word]
    
    # Sauvegarder
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(optimized_concordance, f, ensure_ascii=False, separators=(',', ':'))
    
    original_size = os.path.getsize(input_path) / 1024 / 1024
    optimized_size = os.path.getsize(output_path) / 1024 / 1024
    
    print(f"   ✅ Optimisé: {len(optimized_concordance)} mots")
    print(f"   📉 Taille: {original_size:.2f} MB → {optimized_size:.2f} MB ({optimized_size/original_size*100:.1f}%)")
    
    return optimized_concordance

def optimize_topical_index(input_path, output_path, max_themes=20000):
    """Optimise l'index thématique en gardant seulement les thèmes les plus pertinents"""
    print(f"🔧 Optimisation de l'index thématique...")
    
    with open(input_path, 'r', encoding='utf-8') as f:
        topical = json.load(f)
    
    print(f"   📊 Données originales: {len(topical)} thèmes")
    
    # Trier par fréquence d'occurrence
    theme_frequencies = [(theme, data['count']) for theme, data in topical.items()]
    theme_frequencies.sort(key=lambda x: x[1], reverse=True)
    
    # Garder seulement les thèmes les plus fréquents
    top_themes = theme_frequencies[:max_themes]
    optimized_topical = {}
    
    for theme, count in top_themes:
        optimized_topical[theme] = topical[theme]
    
    # Sauvegarder
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(optimized_topical, f, ensure_ascii=False, separators=(',', ':'))
    
    original_size = os.path.getsize(input_path) / 1024 / 1024
    optimized_size = os.path.getsize(output_path) / 1024 / 1024
    
    print(f"   ✅ Optimisé: {len(optimized_topical)} thèmes")
    print(f"   📉 Taille: {original_size:.2f} MB → {optimized_size:.2f} MB ({optimized_size/original_size*100:.1f}%)")
    
    return optimized_topical

def create_lightweight_services():
    """Crée des services Flutter légers avec chargement à la demande"""
    
    concordance_service = """
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service de concordance BSB optimisé et léger
class BSBConcordanceService {
  static Map<String, dynamic>? _concordanceData;
  static bool _isLoading = false;
  
  /// Initialise le service (chargement à la demande)
  static Future<void> init() async {
    if (_concordanceData != null || _isLoading) return;
    
    _isLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/bsb_concordance_optimized.json');
      _concordanceData = json.decode(jsonString);
      print('✅ BSBConcordanceService initialisé avec ${_concordanceData?.length ?? 0} mots');
    } catch (e) {
      print('⚠️ Erreur chargement concordance BSB: $e');
      _concordanceData = {};
    } finally {
      _isLoading = false;
    }
  }
  
  /// Recherche un mot dans la concordance
  static Future<List<String>> searchWord(String word) async {
    await init();
    
    if (_concordanceData == null) return [];
    
    final normalizedWord = word.toLowerCase().trim();
    final data = _concordanceData![normalizedWord];
    
    if (data == null) return [];
    
    return List<String>.from(data['references'] ?? []);
  }
  
  /// Obtient les statistiques d'un mot
  static Future<Map<String, dynamic>?> getWordStats(String word) async {
    await init();
    
    if (_concordanceData == null) return null;
    
    final normalizedWord = word.toLowerCase().trim();
    return _concordanceData![normalizedWord];
  }
  
  /// Recherche partielle (limité à 20 résultats)
  static Future<List<String>> searchPartial(String partial) async {
    await init();
    
    if (_concordanceData == null) return [];
    
    final normalizedPartial = partial.toLowerCase().trim();
    final matches = <String>[];
    
    for (final word in _concordanceData!.keys) {
      if (word.contains(normalizedPartial)) {
        matches.add(word);
        if (matches.length >= 20) break; // Limiter les résultats
      }
    }
    
    return matches;
  }
  
  /// Vérifie si le service est initialisé
  static bool get isInitialized => _concordanceData != null;
  
  /// Obtient le nombre de mots disponibles
  static int get wordCount => _concordanceData?.length ?? 0;
}
"""
    
    topical_service = """
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service d'index thématique BSB optimisé et léger
class BSBTopicalService {
  static Map<String, dynamic>? _topicalData;
  static bool _isLoading = false;
  
  /// Initialise le service (chargement à la demande)
  static Future<void> init() async {
    if (_topicalData != null || _isLoading) return;
    
    _isLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/bsb_topical_index_optimized.json');
      _topicalData = json.decode(jsonString);
      print('✅ BSBTopicalService initialisé avec ${_topicalData?.length ?? 0} thèmes');
    } catch (e) {
      print('⚠️ Erreur chargement index thématique BSB: $e');
      _topicalData = {};
    } finally {
      _isLoading = false;
    }
  }
  
  /// Recherche un thème
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
  
  /// Obtient tous les thèmes disponibles (limité)
  static Future<List<String>> getAllThemes() async {
    await init();
    
    if (_topicalData == null) return [];
    
    return _topicalData!.keys.take(1000).toList()..sort(); // Limiter à 1000 thèmes
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
  
  /// Vérifie si le service est initialisé
  static bool get isInitialized => _topicalData != null;
  
  /// Obtient le nombre de thèmes disponibles
  static int get themeCount => _topicalData?.length ?? 0;
}
"""
    
    # Sauvegarder les services optimisés
    with open('lib/services/bsb_concordance_service.dart', 'w', encoding='utf-8') as f:
        f.write(concordance_service)
    
    with open('lib/services/bsb_topical_service.dart', 'w', encoding='utf-8') as f:
        f.write(topical_service)
    
    print("   ✅ Services Flutter optimisés créés")

def main():
    """Fonction principale d'optimisation"""
    print("🚀 Optimisation des données BSB pour réduire la taille")
    
    # Chemins des fichiers
    concordance_input = "assets/data/bsb_concordance.json"
    topical_input = "assets/data/bsb_topical_index.json"
    
    concordance_output = "assets/data/bsb_concordance_optimized.json"
    topical_output = "assets/data/bsb_topical_index_optimized.json"
    
    # Optimiser les données
    optimize_concordance(concordance_input, concordance_output, max_words=50000)
    optimize_topical_index(topical_input, topical_output, max_themes=20000)
    
    # Créer les services optimisés
    create_lightweight_services()
    
    # Afficher les statistiques finales
    concordance_size = os.path.getsize(concordance_output) / 1024 / 1024
    topical_size = os.path.getsize(topical_output) / 1024 / 1024
    
    print(f"\n📊 Statistiques d'optimisation:")
    print(f"   📚 Concordance optimisée: {concordance_size:.2f} MB")
    print(f"   🏷️  Index thématique optimisé: {topical_size:.2f} MB")
    print(f"   💾 Taille totale optimisée: {concordance_size + topical_size:.2f} MB")
    
    # Supprimer les fichiers originaux volumineux
    if os.path.exists(concordance_input):
        os.remove(concordance_input)
        print(f"   🗑️  Fichier original supprimé: {concordance_input}")
    
    if os.path.exists(topical_input):
        os.remove(topical_input)
        print(f"   🗑️  Fichier original supprimé: {topical_input}")
    
    print(f"\n✅ Optimisation terminée!")
    print(f"   📁 Fichiers optimisés: {concordance_output}, {topical_output}")
    print(f"   🔧 Services optimisés: lib/services/")

if __name__ == "__main__":
    main()
