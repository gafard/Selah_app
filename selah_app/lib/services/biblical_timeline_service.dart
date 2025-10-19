import 'dart:convert';
import 'package:flutter/services.dart';

/// Service pour les chronologies bibliques
/// Utilise les données d'OpenBible pour enrichir l'étude thématique
class BiblicalTimelineService {
  static Map<String, dynamic>? _timelineData;
  static bool _isInitialized = false;

  /// Initialise le service
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Pour l'instant, on utilise des données simulées
      // TODO: Intégrer les données d'OpenBible
      _timelineData = _getSimulatedTimelineData();
      _isInitialized = true;
      print('✅ BiblicalTimelineService initialisé avec ${_timelineData?.length ?? 0} périodes');
    } catch (e) {
      print('⚠️ Erreur chargement chronologies: $e');
      _timelineData = {};
      _isInitialized = true;
    }
  }

  /// Obtient les périodes bibliques
  static Future<List<Map<String, dynamic>>> getBiblicalPeriods() async {
    await init();
    return _timelineData?['periods'] as List<dynamic>? ?? [];
  }

  /// Obtient les événements d'une période
  static Future<List<Map<String, dynamic>>> getEventsForPeriod(String periodName) async {
    await init();
    
    final periods = _timelineData?['periods'] as List<dynamic>? ?? [];
    for (final period in periods) {
      final periodData = period as Map<String, dynamic>;
      if (periodData['name'] == periodName) {
        return (periodData['events'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    }
    
    return [];
  }

  /// Obtient les événements liés à un thème
  static Future<List<Map<String, dynamic>>> getEventsForTheme(String theme) async {
    await init();
    
    final allEvents = <Map<String, dynamic>>[];
    final periods = _timelineData?['periods'] as List<dynamic>? ?? [];
    
    for (final period in periods) {
      final periodData = period as Map<String, dynamic>;
      final events = (periodData['events'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      for (final event in events) {
        final eventThemes = (event['themes'] as List<dynamic>? ?? [])
            .map((t) => t.toString().toLowerCase())
            .toList();
        
        if (eventThemes.any((t) => t.contains(theme.toLowerCase()))) {
          allEvents.add({
            ...event,
            'period': periodData['name'],
            'periodYears': periodData['years'],
          });
        }
      }
    }
    
    return allEvents;
  }

  /// Obtient la chronologie d'un thème à travers l'histoire biblique
  static Future<List<Map<String, dynamic>>> getThemeTimeline(String theme) async {
    await init();
    
    final events = await getEventsForTheme(theme);
    
    // Trier par ordre chronologique
    events.sort((a, b) {
      final yearA = int.tryParse(a['year']?.toString() ?? '0') ?? 0;
      final yearB = int.tryParse(b['year']?.toString() ?? '0') ?? 0;
      return yearA.compareTo(yearB);
    });
    
    return events;
  }

  /// Obtient les données simulées des chronologies
  static Map<String, dynamic> _getSimulatedTimelineData() {
    return {
      'periods': [
        {
          'name': 'Patriarches',
          'years': '2000-1500 av. J.-C.',
          'description': 'Période des patriarches Abraham, Isaac et Jacob',
          'events': [
            {
              'title': 'Appel d\'Abraham',
              'year': '2000',
              'reference': 'Genèse 12:1-3',
              'description': 'Dieu appelle Abraham à quitter son pays',
              'themes': ['foi', 'obéissance', 'promesse', 'bénédiction'],
            },
            {
              'title': 'Alliance avec Abraham',
              'year': '1980',
              'reference': 'Genèse 15:1-21',
              'description': 'Dieu établit une alliance avec Abraham',
              'themes': ['alliance', 'promesse', 'foi', 'bénédiction'],
            },
            {
              'title': 'Sacrifice d\'Isaac',
              'year': '1850',
              'reference': 'Genèse 22:1-19',
              'description': 'Abraham est prêt à sacrifier Isaac',
              'themes': ['foi', 'obéissance', 'sacrifice', 'bénédiction'],
            },
          ],
        },
        {
          'name': 'Exode et Conquête',
          'years': '1500-1200 av. J.-C.',
          'description': 'Sortie d\'Égypte et conquête de Canaan',
          'events': [
            {
              'title': 'Sortie d\'Égypte',
              'year': '1446',
              'reference': 'Exode 14:1-31',
              'description': 'Israël sort d\'Égypte par la mer Rouge',
              'themes': ['délivrance', 'miracles', 'foi', 'obéissance'],
            },
            {
              'title': 'Don de la loi',
              'year': '1445',
              'reference': 'Exode 20:1-17',
              'description': 'Dieu donne les dix commandements',
              'themes': ['loi', 'alliance', 'obéissance', 'sainteté'],
            },
            {
              'title': 'Conquête de Jéricho',
              'year': '1406',
              'reference': 'Josué 6:1-27',
              'description': 'Jéricho tombe par la foi d\'Israël',
              'themes': ['foi', 'obéissance', 'victoire', 'miracles'],
            },
          ],
        },
        {
          'name': 'Royaume uni',
          'years': '1050-930 av. J.-C.',
          'description': 'Règnes de Saül, David et Salomon',
          'events': [
            {
              'title': 'Oint de David',
              'year': '1025',
              'reference': '1 Samuel 16:1-13',
              'description': 'David est oint roi d\'Israël',
              'themes': ['onction', 'royaume', 'bénédiction', 'promesse'],
            },
            {
              'title': 'Alliance avec David',
              'year': '1000',
              'reference': '2 Samuel 7:1-17',
              'description': 'Dieu établit une alliance éternelle avec David',
              'themes': ['alliance', 'promesse', 'royaume', 'bénédiction'],
            },
            {
              'title': 'Construction du temple',
              'year': '966',
              'reference': '1 Rois 6:1-38',
              'description': 'Salomon construit le temple de Jérusalem',
              'themes': ['temple', 'adoration', 'bénédiction', 'sainteté'],
            },
          ],
        },
        {
          'name': 'Nouveau Testament',
          'years': '4 av. J.-C. - 100 ap. J.-C.',
          'description': 'Vie de Jésus et début de l\'Église',
          'events': [
            {
              'title': 'Naissance de Jésus',
              'year': '4',
              'reference': 'Luc 2:1-20',
              'description': 'Jésus naît à Bethléem',
              'themes': ['incarnation', 'salut', 'promesse', 'bénédiction'],
            },
            {
              'title': 'Baptême de Jésus',
              'year': '26',
              'reference': 'Matthieu 3:13-17',
              'description': 'Jésus est baptisé par Jean',
              'themes': ['baptême', 'onction', 'ministère', 'bénédiction'],
            },
            {
              'title': 'Crucifixion',
              'year': '30',
              'reference': 'Jean 19:16-30',
              'description': 'Jésus meurt sur la croix',
              'themes': ['sacrifice', 'salut', 'amour', 'pardon'],
            },
            {
              'title': 'Résurrection',
              'year': '30',
              'reference': 'Jean 20:1-18',
              'description': 'Jésus ressuscite d\'entre les morts',
              'themes': ['résurrection', 'victoire', 'vie', 'bénédiction'],
            },
            {
              'title': 'Pentecôte',
              'year': '30',
              'reference': 'Actes 2:1-41',
              'description': 'L\'Esprit Saint descend sur les disciples',
              'themes': ['Esprit', 'Église', 'bénédiction', 'puissance'],
            },
          ],
        },
      ],
    };
  }

  /// Obtient les périodes disponibles
  static Future<List<String>> getAvailablePeriods() async {
    await init();
    final periods = _timelineData?['periods'] as List<dynamic>? ?? [];
    return periods.map((p) => (p as Map<String, dynamic>)['name'] as String).toList();
  }

  /// Recherche des événements par mot-clé
  static Future<List<Map<String, dynamic>>> searchEvents(String keyword) async {
    await init();
    
    final allEvents = <Map<String, dynamic>>[];
    final periods = _timelineData?['periods'] as List<dynamic>? ?? [];
    final keywordLower = keyword.toLowerCase();
    
    for (final period in periods) {
      final periodData = period as Map<String, dynamic>;
      final events = (periodData['events'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      for (final event in events) {
        final title = (event['title'] ?? '').toString().toLowerCase();
        final description = (event['description'] ?? '').toString().toLowerCase();
        final themes = (event['themes'] as List<dynamic>? ?? [])
            .map((t) => t.toString().toLowerCase())
            .toList();
        
        if (title.contains(keywordLower) || 
            description.contains(keywordLower) ||
            themes.any((t) => t.contains(keywordLower))) {
          allEvents.add({
            ...event,
            'period': periodData['name'],
            'periodYears': periodData['years'],
          });
        }
      }
    }
    
    return allEvents;
  }
}
