import 'dart:convert';
import 'package:flutter/services.dart';

/// Service de chronologie biblique basé sur OpenBible Timeline Charts
/// https://openbible.com/timelinecharts/
class BiblicalTimelineService {
  static Map<String, dynamic>? _timelineData;
  static bool _isLoading = false;

  /// Initialise le service (chargement à la demande - optimisé)
  static Future<void> init() async {
    if (_timelineData != null || _isLoading) return;

    _isLoading = true;
    try {
      // Charger les données de chronologie depuis assets/data
      final String jsonString = await rootBundle.loadString('assets/data/biblical_timeline.json');
      _timelineData = json.decode(jsonString);
      print('✅ BiblicalTimelineService initialisé avec ${_timelineData?.length ?? 0} périodes');
    } catch (e) {
      print('⚠️ Erreur chargement chronologie biblique: $e');
      // Utiliser des données par défaut si le fichier n'existe pas
      _timelineData = _getDefaultTimelineData();
    } finally {
      _isLoading = false;
    }
  }

  /// Données de chronologie par défaut basées sur OpenBible Timeline Charts
  static Map<String, dynamic> _getDefaultTimelineData() {
    return {
      'periods': [
        {
          'name': 'Création et Patriarches',
          'startYear': -4000,
          'endYear': -1800,
          'description': 'De la création à Abraham',
          'books': ['Genèse'],
          'keyEvents': [
            'Création du monde',
            'Chute de l\'humanité',
            'Déluge de Noé',
            'Tour de Babel',
            'Appel d\'Abraham'
          ],
          'characters': ['Adam', 'Ève', 'Noé', 'Abraham', 'Isaac', 'Jacob'],
          'themes': ['création', 'chute', 'alliance', 'promesse', 'foi']
        },
        {
          'name': 'Exode et Désert',
          'startYear': -1800,
          'endYear': -1400,
          'description': 'Sortie d\'Égypte et errance dans le désert',
          'books': ['Exode', 'Lévitique', 'Nombres', 'Deutéronome'],
          'keyEvents': [
            'Esclavage en Égypte',
            'Naissance de Moïse',
            'Les 10 plaies',
            'Traversée de la mer Rouge',
            'Don de la Loi au Sinaï',
            '40 ans dans le désert'
          ],
          'characters': ['Moïse', 'Aaron', 'Miriam', 'Josué', 'Caleb'],
          'themes': ['libération', 'délivrance', 'loi', 'alliance', 'sainteté']
        },
        {
          'name': 'Conquête et Juges',
          'startYear': -1400,
          'endYear': -1050,
          'description': 'Conquête de Canaan et période des juges',
          'books': ['Josué', 'Juges', 'Ruth'],
          'keyEvents': [
            'Conquête de Jéricho',
            'Partage de Canaan',
            'Période des juges',
            'Cycle d\'apostasie et délivrance'
          ],
          'characters': ['Josué', 'Caleb', 'Gédéon', 'Samson', 'Déborah', 'Ruth'],
          'themes': ['conquête', 'possession', 'jugement', 'délivrance', 'fidélité']
        },
        {
          'name': 'Royaume Unifié',
          'startYear': -1050,
          'endYear': -930,
          'description': 'Règnes de Saül, David et Salomon',
          'books': ['1 Samuel', '2 Samuel', '1 Rois 1-11', 'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique'],
          'keyEvents': [
            'Règne de Saül',
            'Règne de David',
            'Conquête de Jérusalem',
            'Règne de Salomon',
            'Construction du Temple'
          ],
          'characters': ['Saül', 'David', 'Salomon', 'Samuel', 'Nathan', 'Bathsheba'],
          'themes': ['royaume', 'alliance', 'temple', 'sagesse', 'adoration']
        },
        {
          'name': 'Royaume Divisé',
          'startYear': -930,
          'endYear': -722,
          'description': 'Royaume d\'Israël (Nord) et Juda (Sud)',
          'books': ['1 Rois 12-22', '2 Rois 1-17', 'Osée', 'Amos', 'Michée', 'Ésaïe 1-39'],
          'keyEvents': [
            'Division du royaume',
            'Règnes des rois d\'Israël et Juda',
            'Ministère des prophètes',
            'Chute d\'Israël (722 av. J.-C.)'
          ],
          'characters': ['Jéroboam', 'Achab', 'Jézabel', 'Élie', 'Élisée', 'Ésaïe'],
          'themes': ['division', 'idolâtrie', 'prophétie', 'jugement', 'restauration']
        },
        {
          'name': 'Exil et Retour',
          'startYear': -722,
          'endYear': -400,
          'description': 'Exil babylonien et retour à Jérusalem',
          'books': ['2 Rois 18-25', '2 Chroniques', 'Esdras', 'Néhémie', 'Esther', 'Ésaïe 40-66', 'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel', 'Aggée', 'Zacharie', 'Malachie'],
          'keyEvents': [
            'Chute de Juda (586 av. J.-C.)',
            'Exil à Babylone',
            'Règne de Cyrus',
            'Retour à Jérusalem',
            'Reconstruction du Temple',
            'Reconstruction des murailles'
          ],
          'characters': ['Nebucadnetsar', 'Daniel', 'Ézéchiel', 'Cyrus', 'Esdras', 'Néhémie', 'Esther'],
          'themes': ['exil', 'restauration', 'temple', 'loi', 'espérance']
        },
        {
          'name': 'Intertestamentaire',
          'startYear': -400,
          'endYear': -4,
          'description': 'Période entre l\'Ancien et le Nouveau Testament',
          'books': ['Apocryphes'],
          'keyEvents': [
            'Règne grec (Alexandre le Grand)',
            'Règne séleucide',
            'Révolte des Maccabées',
            'Règne hasmonéen',
            'Conquête romaine'
          ],
          'characters': ['Alexandre le Grand', 'Antiochus Épiphane', 'Judas Maccabée'],
          'themes': ['hellénisation', 'résistance', 'indépendance', 'attente']
        },
        {
          'name': 'Vie de Jésus',
          'startYear': -4,
          'endYear': 30,
          'description': 'Naissance, ministère, mort et résurrection de Jésus',
          'books': ['Matthieu', 'Marc', 'Luc', 'Jean'],
          'keyEvents': [
            'Naissance de Jésus',
            'Baptême de Jésus',
            'Ministère en Galilée',
            'Sermon sur la montagne',
            'Miracles et paraboles',
            'Entrée à Jérusalem',
            'Crucifixion',
            'Résurrection',
            'Ascension'
          ],
          'characters': ['Jésus', 'Marie', 'Joseph', 'Jean-Baptiste', 'Pierre', 'Jean', 'Paul'],
          'themes': ['incarnation', 'royaume', 'salut', 'amour', 'sacrifice', 'résurrection']
        },
        {
          'name': 'Église Primitive',
          'startYear': 30,
          'endYear': 100,
          'description': 'Formation et expansion de l\'Église',
          'books': ['Actes', 'Romains', '1-2 Corinthiens', 'Galates', 'Éphésiens', 'Philippiens', 'Colossiens', '1-2 Thessaloniciens', '1-2 Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques', '1-2 Pierre', '1-3 Jean', 'Jude', 'Apocalypse'],
          'keyEvents': [
            'Pentecôte',
            'Conversion de Paul',
            'Premier concile de Jérusalem',
            'Voyages missionnaires de Paul',
            'Écriture des épîtres',
            'Persécutions romaines'
          ],
          'characters': ['Pierre', 'Paul', 'Jean', 'Jacques', 'Timothée', 'Tite', 'Barnabas'],
          'themes': ['évangélisation', 'doctrine', 'église', 'sainteté', 'espérance', 'persévérance']
        }
      ],
      'empires': [
        {
          'name': 'Empire Égyptien',
          'startYear': -3000,
          'endYear': -30,
          'description': 'L\'un des plus anciens empires de l\'histoire',
          'keyEvents': ['Construction des pyramides', 'Exode des Hébreux', 'Conquête par Rome']
        },
        {
          'name': 'Empire Assyrien',
          'startYear': -2000,
          'endYear': -612,
          'description': 'Empire mésopotamien puissant',
          'keyEvents': ['Conquête d\'Israël (722 av. J.-C.)', 'Siège de Jérusalem']
        },
        {
          'name': 'Empire Babylonien',
          'startYear': -612,
          'endYear': -539,
          'description': 'Empire de Nebucadnetsar',
          'keyEvents': ['Conquête de Juda (586 av. J.-C.)', 'Exil babylonien']
        },
        {
          'name': 'Empire Perse',
          'startYear': -539,
          'endYear': -330,
          'description': 'Empire de Cyrus et ses successeurs',
          'keyEvents': ['Édit de Cyrus', 'Retour des exilés', 'Reconstruction du Temple']
        },
        {
          'name': 'Empire Grec',
          'startYear': -330,
          'endYear': -63,
          'description': 'Empire d\'Alexandre le Grand',
          'keyEvents': ['Conquête d\'Alexandre', 'Hellénisation', 'Révolte des Maccabées']
        },
        {
          'name': 'Empire Romain',
          'startYear': -63,
          'endYear': 476,
          'description': 'Empire qui dominait à l\'époque de Jésus',
          'keyEvents': ['Conquête de la Palestine', 'Crucifixion de Jésus', 'Destruction du Temple (70 ap. J.-C.)']
        }
      ]
    };
  }

  /// Récupère toutes les périodes bibliques
  static Future<List<Map<String, dynamic>>> getPeriods() async {
    await init();
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      return periods.map((period) => period as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Récupère toutes les périodes d'empires
  static Future<List<Map<String, dynamic>>> getEmpires() async {
    await init();
    if (_timelineData != null) {
      final empires = _timelineData!['empires'] as List<dynamic>? ?? [];
      return empires.map((empire) => empire as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Recherche des périodes par thème
  static Future<List<Map<String, dynamic>>> searchPeriodsByTheme(String theme) async {
    await init();
    final matchingPeriods = <Map<String, dynamic>>[];
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        final themes = periodMap['themes'] as List<dynamic>? ?? [];
        
        if (themes.any((t) => t.toString().toLowerCase().contains(theme.toLowerCase()))) {
          matchingPeriods.add(periodMap);
        }
      }
    }
    
    return matchingPeriods;
  }

  /// Recherche des périodes par personnage
  static Future<List<Map<String, dynamic>>> searchPeriodsByCharacter(String character) async {
    await init();
    final matchingPeriods = <Map<String, dynamic>>[];
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        final characters = periodMap['characters'] as List<dynamic>? ?? [];
        
        if (characters.any((c) => c.toString().toLowerCase().contains(character.toLowerCase()))) {
          matchingPeriods.add(periodMap);
        }
      }
    }
    
    return matchingPeriods;
  }

  /// Récupère la période pour une année donnée
  static Future<Map<String, dynamic>?> getPeriodForYear(int year) async {
    await init();
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        final startYear = periodMap['startYear'] as int? ?? 0;
        final endYear = periodMap['endYear'] as int? ?? 0;
        
        if (year >= startYear && year <= endYear) {
          return periodMap;
        }
      }
    }
    
    return null;
  }

  /// Récupère l'empire dominant pour une année donnée
  static Future<Map<String, dynamic>?> getEmpireForYear(int year) async {
    await init();
    
    if (_timelineData != null) {
      final empires = _timelineData!['empires'] as List<dynamic>? ?? [];
      
      for (final empire in empires) {
        final empireMap = empire as Map<String, dynamic>;
        final startYear = empireMap['startYear'] as int? ?? 0;
        final endYear = empireMap['endYear'] as int? ?? 0;
        
        if (year >= startYear && year <= endYear) {
          return empireMap;
        }
      }
    }
    
    return null;
  }

  /// Récupère la période pour un livre biblique
  static Future<Map<String, dynamic>?> getPeriodForBook(String bookName) async {
    await init();
    
    if (_timelineData != null) {
      // La structure réelle : les livres sont directement des clés
      final bookData = _timelineData![bookName];
      if (bookData != null) {
        return bookData as Map<String, dynamic>;
      }
      
      // Essayer avec des variations du nom
      for (final key in _timelineData!.keys) {
        if (key.toLowerCase().contains(bookName.toLowerCase()) || 
            bookName.toLowerCase().contains(key.toLowerCase())) {
          return _timelineData![key] as Map<String, dynamic>;
        }
      }
    }
    
    return null;
  }

  /// Récupère les événements clés pour une période
  static Future<List<String>> getKeyEventsForPeriod(String periodName) async {
    await init();
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        if (periodMap['name'] == periodName) {
          final events = periodMap['keyEvents'] as List<dynamic>? ?? [];
          return events.map((event) => event.toString()).toList();
        }
      }
    }
    
    return [];
  }

  /// Récupère les personnages pour une période
  static Future<List<String>> getCharactersForPeriod(String periodName) async {
    await init();
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        if (periodMap['name'] == periodName) {
          final characters = periodMap['characters'] as List<dynamic>? ?? [];
          return characters.map((character) => character.toString()).toList();
        }
      }
    }
    
    return [];
  }

  /// Récupère les thèmes pour une période
  static Future<List<String>> getThemesForPeriod(String periodName) async {
    await init();
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        if (periodMap['name'] == periodName) {
          final themes = periodMap['themes'] as List<dynamic>? ?? [];
          return themes.map((theme) => theme.toString()).toList();
        }
      }
    }
    
    return [];
  }

  /// Récupère la chronologie pour un thème spécifique
  static Future<List<Map<String, dynamic>>> getThemeTimeline(String theme) async {
    await init();
    final matchingPeriods = <Map<String, dynamic>>[];
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        final themes = periodMap['themes'] as List<dynamic>? ?? [];
        
        if (themes.any((t) => t.toString().toLowerCase().contains(theme.toLowerCase()))) {
          matchingPeriods.add(periodMap);
        }
      }
    }
    
    return matchingPeriods;
  }

  /// Récupère la chronologie complète avec tous les détails
  static Future<Map<String, dynamic>?> getFullTimeline() async {
    await init();
    return _timelineData;
  }

  /// Recherche avancée dans la chronologie
  static Future<List<Map<String, dynamic>>> advancedSearch({
    String? periodName,
    String? character,
    String? theme,
    int? startYear,
    int? endYear,
  }) async {
    await init();
    final results = <Map<String, dynamic>>[];
    
    if (_timelineData != null) {
      final periods = _timelineData!['periods'] as List<dynamic>? ?? [];
      
      for (final period in periods) {
        final periodMap = period as Map<String, dynamic>;
        bool matches = true;
        
        if (periodName != null && periodMap['name'] != periodName) {
          matches = false;
        }
        
        if (character != null) {
          final characters = periodMap['characters'] as List<dynamic>? ?? [];
          if (!characters.any((c) => c.toString().toLowerCase().contains(character.toLowerCase()))) {
            matches = false;
          }
        }
        
        if (theme != null) {
          final themes = periodMap['themes'] as List<dynamic>? ?? [];
          if (!themes.any((t) => t.toString().toLowerCase().contains(theme.toLowerCase()))) {
            matches = false;
          }
        }
        
        if (startYear != null) {
          final periodStartYear = periodMap['startYear'] as int? ?? 0;
          if (periodStartYear > startYear) {
            matches = false;
          }
        }
        
        if (endYear != null) {
          final periodEndYear = periodMap['endYear'] as int? ?? 0;
          if (periodEndYear < endYear) {
            matches = false;
          }
        }
        
        if (matches) {
          results.add(periodMap);
        }
      }
    }
    
    return results;
  }

  /// Vérifie si le service est initialisé
  static bool get isInitialized => _timelineData != null;

  /// Obtient le nombre de périodes disponibles
  static int get periodCount => _timelineData?['periods']?.length ?? 0;

  /// Obtient le nombre d'empires disponibles
  static int get empireCount => _timelineData?['empires']?.length ?? 0;
}

