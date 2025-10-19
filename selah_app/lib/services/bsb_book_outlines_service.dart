import 'dart:convert';
import 'package:flutter/services.dart';

/// Service pour les plans de livres BSB
/// Utilise le PDF bsb_book_outlines.pdf pour enrichir l'étude thématique
class BSBBookOutlinesService {
  static Map<String, dynamic>? _bookOutlines;
  static bool _isInitialized = false;

  /// Initialise le service
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Pour l'instant, on utilise des données simulées
      // TODO: Intégrer le PDF bsb_book_outlines.pdf
      _bookOutlines = _getSimulatedBookOutlines();
      _isInitialized = true;
      print('✅ BSBBookOutlinesService initialisé avec ${_bookOutlines?.length ?? 0} livres');
    } catch (e) {
      print('⚠️ Erreur chargement plans de livres: $e');
      _bookOutlines = {};
      _isInitialized = true;
    }
  }

  /// Obtient le plan d'un livre spécifique
  static Future<Map<String, dynamic>?> getBookOutline(String bookName) async {
    await init();
    return _bookOutlines?[bookName];
  }

  /// Obtient les sections d'un livre pour un thème donné
  static Future<List<Map<String, dynamic>>> getSectionsForTheme(String bookName, String theme) async {
    await init();
    
    final outline = _bookOutlines?[bookName];
    if (outline == null) return [];
    
    final sections = outline['sections'] as List<dynamic>? ?? [];
    final matchingSections = <Map<String, dynamic>>[];
    
    for (final section in sections) {
      final sectionData = section as Map<String, dynamic>;
      final sectionThemes = (sectionData['themes'] as List<dynamic>? ?? [])
          .map((t) => t.toString().toLowerCase())
          .toList();
      
      if (sectionThemes.any((t) => t.contains(theme.toLowerCase()))) {
        matchingSections.add(sectionData);
      }
    }
    
    return matchingSections;
  }

  /// Obtient la progression chronologique d'un thème à travers un livre
  static Future<List<Map<String, dynamic>>> getThemeProgressionInBook(String bookName, String theme) async {
    await init();
    
    final outline = _bookOutlines?[bookName];
    if (outline == null) return [];
    
    final sections = outline['sections'] as List<dynamic>? ?? [];
    final progression = <Map<String, dynamic>>[];
    
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i] as Map<String, dynamic>;
      final sectionThemes = (section['themes'] as List<dynamic>? ?? [])
          .map((t) => t.toString().toLowerCase())
          .toList();
      
      if (sectionThemes.any((t) => t.contains(theme.toLowerCase()))) {
        progression.add({
          'section': section['title'] ?? '',
          'chapters': section['chapters'] ?? '',
          'description': section['description'] ?? '',
          'themes': sectionThemes,
          'order': i + 1,
          'book': bookName,
        });
      }
    }
    
    return progression;
  }

  /// Obtient les données simulées des plans de livres
  static Map<String, dynamic> _getSimulatedBookOutlines() {
    return {
      'Genèse': {
        'title': 'Genèse',
        'period': 'Patriarches',
        'description': 'Le livre des commencements',
        'sections': [
          {
            'title': 'Création et chute',
            'chapters': '1-3',
            'description': 'La création du monde et la chute de l\'homme',
            'themes': ['création', 'chute', 'péché', 'tentation', 'obéissance'],
          },
          {
            'title': 'Les patriarches',
            'chapters': '12-50',
            'description': 'L\'histoire des patriarches Abraham, Isaac et Jacob',
            'themes': ['foi', 'alliance', 'promesse', 'bénédiction', 'patriarches'],
          },
        ],
      },
      'Exode': {
        'title': 'Exode',
        'period': 'Patriarches',
        'description': 'La sortie d\'Égypte et la loi',
        'sections': [
          {
            'title': 'La délivrance',
            'chapters': '1-15',
            'description': 'La sortie d\'Égypte et le passage de la mer Rouge',
            'themes': ['délivrance', 'libération', 'miracles', 'foi', 'obéissance'],
          },
          {
            'title': 'La loi et l\'alliance',
            'chapters': '16-40',
            'description': 'Le don de la loi et l\'établissement de l\'alliance',
            'themes': ['loi', 'alliance', 'obéissance', 'sainteté', 'adoration'],
          },
        ],
      },
      'Psaumes': {
        'title': 'Psaumes',
        'period': 'Sagesse',
        'description': 'Le livre des louanges et des prières',
        'sections': [
          {
            'title': 'Psaumes de louange',
            'chapters': '1-50',
            'description': 'Psaumes de louange et d\'adoration',
            'themes': ['louange', 'adoration', 'gratitude', 'joie', 'bénédiction'],
          },
          {
            'title': 'Psaumes de lamentation',
            'chapters': '51-100',
            'description': 'Psaumes de lamentation et de supplication',
            'themes': ['lamentation', 'supplication', 'pardon', 'repentance', 'grâce'],
          },
        ],
      },
      'Jean': {
        'title': 'Évangile selon Jean',
        'period': 'Nouveau Testament',
        'description': 'L\'évangile de la vie éternelle',
        'sections': [
          {
            'title': 'Le Verbe fait chair',
            'chapters': '1-4',
            'description': 'L\'incarnation et les premiers miracles',
            'themes': ['incarnation', 'divinité', 'miracles', 'foi', 'vérité'],
          },
          {
            'title': 'Les signes et les discours',
            'chapters': '5-12',
            'description': 'Les signes de Jésus et ses enseignements',
            'themes': ['signes', 'enseignements', 'vérité', 'vie', 'résurrection'],
          },
          {
            'title': 'La passion et la résurrection',
            'chapters': '13-21',
            'description': 'La passion, la mort et la résurrection de Jésus',
            'themes': ['passion', 'mort', 'résurrection', 'amour', 'salut'],
          },
        ],
      },
      'Romains': {
        'title': 'Épître aux Romains',
        'period': 'Nouveau Testament',
        'description': 'L\'évangile de la justification par la foi',
        'sections': [
          {
            'title': 'La justification par la foi',
            'chapters': '1-5',
            'description': 'La doctrine de la justification par la foi seule',
            'themes': ['justification', 'foi', 'grâce', 'pardon', 'salut'],
          },
          {
            'title': 'La sanctification',
            'chapters': '6-8',
            'description': 'La vie chrétienne et la sanctification',
            'themes': ['sanctification', 'vie chrétienne', 'Esprit', 'liberté', 'amour'],
          },
        ],
      },
    };
  }

  /// Obtient tous les livres disponibles
  static Future<List<String>> getAvailableBooks() async {
    await init();
    return _bookOutlines?.keys.toList() ?? [];
  }

  /// Recherche des livres par thème
  static Future<List<String>> searchBooksByTheme(String theme) async {
    await init();
    
    final matchingBooks = <String>[];
    final themeLower = theme.toLowerCase();
    
    for (final entry in _bookOutlines!.entries) {
      final bookName = entry.key;
      final outline = entry.value as Map<String, dynamic>;
      final sections = outline['sections'] as List<dynamic>? ?? [];
      
      for (final section in sections) {
        final sectionData = section as Map<String, dynamic>;
        final sectionThemes = (sectionData['themes'] as List<dynamic>? ?? [])
            .map((t) => t.toString().toLowerCase())
            .toList();
        
        if (sectionThemes.any((t) => t.contains(themeLower))) {
          if (!matchingBooks.contains(bookName)) {
            matchingBooks.add(bookName);
          }
        }
      }
    }
    
    return matchingBooks;
  }
}
