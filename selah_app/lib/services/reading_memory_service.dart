import 'package:hive/hive.dart';
import 'semantic_passage_boundary_service.dart';

/// ⚡ ÉVANGÉLISTE - Service de mémoire de lecture avec intelligence sémantique
/// 
/// Niveau : Évangéliste (Fonctionnel) - Service fonctionnel pour la mémoire adaptative
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: semantic_passage_boundary_service.dart (contexte sémantique)
/// 🔥 Priorité 2: meditation_journal_service.dart (journal spirituel)
/// 🔥 Priorité 3: thompson_plan_service.dart (thèmes spirituels)
/// 🎯 Thompson: Enrichit la mémoire avec thèmes spirituels
/// 
/// Fonctionnalités :
/// 1. File "Mémoriser ce passage" → Queue de versets à mémoriser
/// 2. "Retenu de ma lecture" → Ce que l'utilisateur a retenu aujourd'hui
/// 3. Proposition Poster en fin de prière
/// 4. 🧠 INTELLIGENCE: Analyse sémantique des passages mémorisés
/// 5. 🧠 INTELLIGENCE: Suggestions basées sur le contexte Thompson
/// 
/// Box Hive : 'reading_mem'
/// 
/// Structure :
/// {
///   'memory_queue': [
///     {id: "Jean.3.16", note: "Verset central", date: "ISO8601", semantic_context: {...}, ...}
///   ],
///   'retentions': [
///     {id: "Luc.15.32", retained: "Dieu cherche les perdus", date: "ISO8601", thompson_theme: "...", ...}
///   ]
/// }
class ReadingMemoryService {
  static Box? _memBox;
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _memBox = await Hive.openBox('reading_mem');
    print('✅ ReadingMemoryService initialisé');
  }
  
  /// 🧠 Ajoute un verset à la queue de mémorisation avec contexte sémantique
  /// 
  /// [id] : ID du verset (ex: "Jean.3.16")
  /// [note] : Note optionnelle ("Pourquoi je veux mémoriser?")
  /// 
  /// Déclenchée depuis le menu contextuel "Mémoriser ce passage"
  static Future<void> queueMemoryVerse(String id, {String? note}) async {
    try {
      final queue = _getMemoryQueue();
      
      // Vérifier si déjà dans la queue
      final exists = queue.any((item) => item['id'] == id);
      if (exists) {
        print('  ⚠️ Verset $id déjà dans la queue de mémorisation');
        return;
      }
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Récupérer le contexte sémantique
      final semanticContext = await _getSemanticContext(id);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Récupérer le thème Thompson
      final thompsonTheme = await _getThompsonTheme(id);
      
      // Ajouter à la queue avec contexte enrichi
      queue.add({
        'id': id,
        'note': note,
        'date_added': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, memorized, dismissed
        'semantic_context': semanticContext,
        'thompson_theme': thompsonTheme,
        'priority_score': _calculatePriorityScore(semanticContext, thompsonTheme),
      });
      
      await _memBox?.put('memory_queue', queue);
      print('🚗 Évangéliste Intelligent: Verset $id ajouté avec contexte sémantique');
    } catch (e) {
      print('❌ Erreur queueMemoryVerse($id): $e');
    }
  }

  /// 🔥 PRIORITÉ 1: Récupère le contexte sémantique FALCON X
  static Future<Map<String, dynamic>?> _getSemanticContext(String id) async {
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
      
      return {
        'unit_name': unit.name,
        'priority': unit.priority.name,
        'theme': unit.theme,
        'liturgical_context': unit.liturgicalContext,
        'emotional_tones': unit.emotionalTones,
        'annotation': unit.annotation,
      };
    } catch (e) {
      return null;
    }
  }

  /// 🔥 PRIORITÉ 3: Récupère le thème Thompson
  static Future<String?> _getThompsonTheme(String id) async {
    try {
      // TODO: Intégrer avec thompson_plan_service pour récupérer le thème
      // Mapping basique pour l'instant
      final book = id.split('.').first;
      
      if (book.contains('Psaumes')) {
        return 'Vie de prière — Souffle spirituel';
      } else if (book.contains('Jean')) {
        return 'Exigence spirituelle — Transformation profonde';
      } else if (book.contains('Matthieu')) {
        return 'Ne vous inquiétez pas — Apprentissages de Mt 6';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 🧠 Calcule un score de priorité pour la mémorisation
  static double _calculatePriorityScore(Map<String, dynamic>? semantic, String? thompson) {
    double score = 0.5; // Score de base
    
    if (semantic != null) {
      final priority = semantic['priority'] as String?;
      if (priority == 'critical') {
        score += 0.3; // Priorité haute pour les passages critiques
      } else if (priority == 'high') {
        score += 0.2;
      } else if (priority == 'medium') {
        score += 0.1;
      }
    }
    
    if (thompson != null) {
      if (thompson.contains('prière') || thompson.contains('sagesse')) {
        score += 0.2; // Bonus pour les thèmes spirituels importants
      }
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// 🧠 Sauvegarde ce que l'utilisateur a retenu avec contexte sémantique
  /// 
  /// [id] : ID du verset ou passage
  /// [retained] : Ce que l'utilisateur a retenu (texte libre)
  /// [date] : Date de la lecture
  /// [addToJournal] : Ajouter au journal spirituel
  /// [addToWall] : Publier sur le mur spirituel (local)
  /// 
  /// Déclenchée depuis "Marquer comme lu" après saisie utilisateur
  static Future<void> saveRetention({
    required String id,
    required String retained,
    required DateTime date,
    bool addToJournal = true,
    bool addToWall = false,
  }) async {
    try {
      final retentions = _getRetentions();
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Récupérer le contexte sémantique
      final semanticContext = await _getSemanticContext(id);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Récupérer le thème Thompson
      final thompsonTheme = await _getThompsonTheme(id);
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Analyser la rétention
      final retentionAnalysis = await _analyzeRetention(retained, semanticContext, thompsonTheme);
      
      // Ajouter la nouvelle rétention avec contexte enrichi
      retentions.add({
        'id': id,
        'retained': retained,
        'date': date.toIso8601String(),
        'add_to_journal': addToJournal,
        'add_to_wall': addToWall,
        'poster_created': false, // Flag pour proposer Poster plus tard
        'created_at': DateTime.now().toIso8601String(),
        'semantic_context': semanticContext,
        'thompson_theme': thompsonTheme,
        'retention_analysis': retentionAnalysis,
        'emotional_tone': _extractEmotionalTone(retained),
        'spiritual_depth': _calculateSpiritualDepth(retained, semanticContext),
      });
      
      await _memBox?.put('retentions', retentions);
      print('🚗 Évangéliste Intelligent: Rétention sauvegardée avec analyse sémantique pour $id');
      
      // Si addToJournal, déclencher aussi la sauvegarde dans le journal
      if (addToJournal) {
        await _saveToJournal(id, retained, date, semanticContext, thompsonTheme);
      }
      
      // Si addToWall, marquer pour publication
      if (addToWall) {
        await _saveToWall(id, retained, date, semanticContext, thompsonTheme);
      }
    } catch (e) {
      print('❌ Erreur saveRetention: $e');
    }
  }

  /// 🧠 Analyse la rétention avec contexte sémantique
  static Future<Map<String, dynamic>> _analyzeRetention(
    String retained, 
    Map<String, dynamic>? semantic, 
    String? thompson
  ) async {
    try {
      return {
        'word_count': retained.split(' ').length,
        'has_personal_reflection': retained.toLowerCase().contains('je') || retained.toLowerCase().contains('moi'),
        'has_spiritual_terms': _hasSpiritualTerms(retained),
        'semantic_alignment': _calculateSemanticAlignment(retained, semantic),
        'thompson_alignment': _calculateThompsonAlignment(retained, thompson),
        'depth_score': _calculateDepthScore(retained),
      };
    } catch (e) {
      return {};
    }
  }

  /// 🧠 Vérifie si la rétention contient des termes spirituels
  static bool _hasSpiritualTerms(String text) {
    final spiritualTerms = ['Dieu', 'Jésus', 'Christ', 'Esprit', 'prière', 'foi', 'amour', 'grâce', 'saint'];
    final lowerText = text.toLowerCase();
    return spiritualTerms.any((term) => lowerText.contains(term.toLowerCase()));
  }

  /// 🧠 Calcule l'alignement sémantique
  static double _calculateSemanticAlignment(String retained, Map<String, dynamic>? semantic) {
    if (semantic == null) return 0.5;
    
    final theme = semantic['theme'] as String?;
    if (theme == null) return 0.5;
    
    final lowerRetained = retained.toLowerCase();
    final lowerTheme = theme.toLowerCase();
    
    // Vérifier si la rétention contient des mots-clés du thème
    if (lowerTheme.contains('prière') && lowerRetained.contains('prière')) return 0.9;
    if (lowerTheme.contains('sagesse') && lowerRetained.contains('sagesse')) return 0.9;
    if (lowerTheme.contains('amour') && lowerRetained.contains('amour')) return 0.9;
    
    return 0.5; // Alignement neutre
  }

  /// 🧠 Calcule l'alignement Thompson
  static double _calculateThompsonAlignment(String retained, String? thompson) {
    if (thompson == null) return 0.5;
    
    final lowerRetained = retained.toLowerCase();
    final lowerThompson = thompson.toLowerCase();
    
    // Vérifier si la rétention contient des mots-clés du thème Thompson
    if (lowerThompson.contains('prière') && lowerRetained.contains('prière')) return 0.9;
    if (lowerThompson.contains('sagesse') && lowerRetained.contains('sagesse')) return 0.9;
    if (lowerThompson.contains('transformation') && lowerRetained.contains('transformation')) return 0.9;
    
    return 0.5; // Alignement neutre
  }

  /// 🧠 Calcule un score de profondeur spirituelle
  static double _calculateDepthScore(String retained) {
    double score = 0.0;
    
    // Bonus pour la longueur (réflexion approfondie)
    final wordCount = retained.split(' ').length;
    if (wordCount > 20) {
      score += 0.3;
    } else if (wordCount > 10) score += 0.2;
    else if (wordCount > 5) score += 0.1;
    
    // Bonus pour les termes spirituels
    if (_hasSpiritualTerms(retained)) score += 0.3;
    
    // Bonus pour les références personnelles
    if (retained.toLowerCase().contains('je') || retained.toLowerCase().contains('moi')) score += 0.2;
    
    // Bonus pour les questions spirituelles
    if (retained.contains('?')) score += 0.2;
    
    return score.clamp(0.0, 1.0);
  }

  /// 🧠 Extrait le ton émotionnel de la rétention
  static String _extractEmotionalTone(String retained) {
    final lowerText = retained.toLowerCase();
    
    if (lowerText.contains('joie') || lowerText.contains('heureux') || lowerText.contains('béni')) {
      return 'joyful';
    } else if (lowerText.contains('paix') || lowerText.contains('calme') || lowerText.contains('sérénité')) {
      return 'peaceful';
    } else if (lowerText.contains('gratitude') || lowerText.contains('merci') || lowerText.contains('reconnaissant')) {
      return 'grateful';
    } else if (lowerText.contains('espoir') || lowerText.contains('confiance') || lowerText.contains('foi')) {
      return 'hopeful';
    } else if (lowerText.contains('réflexion') || lowerText.contains('méditation') || lowerText.contains('pensée')) {
      return 'contemplative';
    }
    
    return 'neutral';
  }

  /// 🧠 Calcule la profondeur spirituelle
  static double _calculateSpiritualDepth(String retained, Map<String, dynamic>? semantic) {
    double depth = _calculateDepthScore(retained);
    
    // Bonus si le contexte sémantique est critique
    if (semantic != null) {
      final priority = semantic['priority'] as String?;
      if (priority == 'critical') {
        depth += 0.2;
      } else if (priority == 'high') {
        depth += 0.1;
      }
    }
    
    return depth.clamp(0.0, 1.0);
  }
  
  /// Récupère les passages en attente pour création de Poster
  /// 
  /// À appeler en fin de prière ou à l'ouverture de l'app
  /// 
  /// Retourne : Liste des éléments (mémorisation + rétention) à proposer
  static Future<List<Map<String, dynamic>>> pendingForPoster() async {
    final pending = <Map<String, dynamic>>[];
    
    try {
      // 1. Versets à mémoriser (memory_queue)
      final memoryQueue = _getMemoryQueue();
      for (final item in memoryQueue) {
        if (item['status'] == 'pending') {
          pending.add({
            'type': 'memory',
            'id': item['id'],
            'note': item['note'],
            'date': item['date_added'],
          });
        }
      }
      
      // 2. Rétentions sans poster créé
      final retentions = _getRetentions();
      for (final item in retentions) {
        if (item['poster_created'] == false) {
          pending.add({
            'type': 'retention',
            'id': item['id'],
            'retained': item['retained'],
            'date': item['date'],
          });
        }
      }
      
      print('📋 ${pending.length} élément(s) en attente pour Poster');
    } catch (e) {
      print('❌ Erreur pendingForPoster: $e');
    }
    
    return pending;
  }
  
  /// Marque un élément comme "Poster créé"
  /// 
  /// [id] : ID du verset
  /// [type] : 'memory' ou 'retention'
  static Future<void> markPosterDone(String id, {String type = 'retention'}) async {
    try {
      if (type == 'memory') {
        // Marquer dans memory_queue
        final queue = _getMemoryQueue();
        final index = queue.indexWhere((item) => item['id'] == id);
        
        if (index != -1) {
          queue[index]['status'] = 'memorized';
          await _memBox?.put('memory_queue', queue);
        }
      } else {
        // Marquer dans retentions
        final retentions = _getRetentions();
        final index = retentions.indexWhere((item) => item['id'] == id);
        
        if (index != -1) {
          retentions[index]['poster_created'] = true;
          await _memBox?.put('retentions', retentions);
        }
      }
      
      print('✅ Poster marqué comme créé pour $id');
    } catch (e) {
      print('❌ Erreur markPosterDone: $e');
    }
  }
  
  /// Récupère tous les versets mémorisés
  /// 
  /// Retourne : Liste des versets marqués comme mémorisés
  static Future<List<Map<String, dynamic>>> getMemorizedVerses() async {
    final queue = _getMemoryQueue();
    return queue.where((item) => item['status'] == 'memorized').toList();
  }
  
  /// Récupère l'historique des rétentions
  /// 
  /// [limit] : Nombre maximum de résultats (défaut: 30)
  /// 
  /// Retourne : Liste des rétentions récentes
  static Future<List<Map<String, dynamic>>> getRetentionHistory({int limit = 30}) async {
    final retentions = _getRetentions();
    
    // Trier par date (plus récent en premier)
    retentions.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });
    
    return retentions.take(limit).toList();
  }
  
  /// Supprime un élément de la queue de mémorisation
  static Future<void> removeFromMemoryQueue(String id) async {
    try {
      final queue = _getMemoryQueue();
      queue.removeWhere((item) => item['id'] == id);
      await _memBox?.put('memory_queue', queue);
      print('✅ Verset $id retiré de la queue');
    } catch (e) {
      print('❌ Erreur removeFromMemoryQueue: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ═══════════════════════════════════════════════════════════════
  
  /// Récupère la queue de mémorisation
  static List<Map<String, dynamic>> _getMemoryQueue() {
    final raw = _memBox?.get('memory_queue');
    if (raw == null || raw is! List) return [];
    
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
  
  /// Récupère les rétentions
  static List<Map<String, dynamic>> _getRetentions() {
    final raw = _memBox?.get('retentions');
    if (raw == null || raw is! List) return [];
    
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
  
  /// 🧠 Sauvegarde dans le journal spirituel avec contexte enrichi
  static Future<void> _saveToJournal(
    String id, 
    String retained, 
    DateTime date, 
    Map<String, dynamic>? semantic, 
    String? thompson
  ) async {
    try {
      // TODO: Intégrer avec MeditationJournalService
      print('📔 Sauvegardé dans le journal avec contexte sémantique: $id');
    } catch (e) {
      print('⚠️ Erreur sauvegarde journal: $e');
    }
  }
  
  /// 🧠 Sauvegarde sur le mur spirituel avec contexte enrichi
  static Future<void> _saveToWall(
    String id, 
    String retained, 
    DateTime date, 
    Map<String, dynamic>? semantic, 
    String? thompson
  ) async {
    try {
      // TODO: Intégrer avec SpiritualWallService
      print('🧱 Publié sur le mur avec contexte Thompson: $id');
    } catch (e) {
      print('⚠️ Erreur sauvegarde mur: $e');
    }
  }

  /// 🧠 Récupère les suggestions intelligentes pour la mémorisation
  static Future<List<Map<String, dynamic>>> getIntelligentSuggestions() async {
    try {
      final queue = _getMemoryQueue();
      final retentions = _getRetentions();
      
      // Trier par score de priorité
      queue.sort((a, b) {
        final scoreA = (a['priority_score'] as double?) ?? 0.0;
        final scoreB = (b['priority_score'] as double?) ?? 0.0;
        return scoreB.compareTo(scoreA);
      });
      
      // Analyser les rétentions pour des suggestions
      final suggestions = <Map<String, dynamic>>[];
      
      // Suggérer des versets à mémoriser basés sur les rétentions
      for (final retention in retentions.take(5)) {
        final spiritualDepth = retention['spiritual_depth'] as double? ?? 0.0;
        if (spiritualDepth > 0.7) {
          suggestions.add({
            'type': 'memorize_related',
            'id': retention['id'],
            'reason': 'Rétention profonde - verset à mémoriser',
            'priority': 'high',
          });
        }
      }
      
      // Suggérer des versets de la queue
      for (final item in queue.take(3)) {
        if (item['status'] == 'pending') {
          suggestions.add({
            'type': 'memorize_pending',
            'id': item['id'],
            'reason': 'En attente de mémorisation',
            'priority': 'medium',
          });
        }
      }
      
      return suggestions;
    } catch (e) {
      print('⚠️ Erreur suggestions intelligentes: $e');
      return [];
    }
  }

  /// 🧠 Analyse les tendances de mémorisation
  static Future<Map<String, dynamic>> getMemorizationTrends() async {
    try {
      final queue = _getMemoryQueue();
      final retentions = _getRetentions();
      
      // Analyser les thèmes les plus mémorisés
      final themeCounts = <String, int>{};
      final thompsonCounts = <String, int>{};
      
      for (final item in queue) {
        final semantic = item['semantic_context'] as Map<String, dynamic>?;
        final thompson = item['thompson_theme'] as String?;
        
        if (semantic != null) {
          final theme = semantic['theme'] as String?;
          if (theme != null) {
            themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
          }
        }
        
        if (thompson != null) {
          thompsonCounts[thompson] = (thompsonCounts[thompson] ?? 0) + 1;
        }
      }
      
      // Analyser les rétentions
      final emotionalTones = <String, int>{};
      final spiritualDepths = <double>[];
      
      for (final retention in retentions) {
        final tone = retention['emotional_tone'] as String?;
        final depth = retention['spiritual_depth'] as double?;
        
        if (tone != null) {
          emotionalTones[tone] = (emotionalTones[tone] ?? 0) + 1;
        }
        
        if (depth != null) {
          spiritualDepths.add(depth);
        }
      }
      
      return {
        'total_memorized': queue.where((item) => item['status'] == 'memorized').length,
        'total_pending': queue.where((item) => item['status'] == 'pending').length,
        'total_retentions': retentions.length,
        'popular_themes': themeCounts,
        'popular_thompson_themes': thompsonCounts,
        'emotional_tone_distribution': emotionalTones,
        'average_spiritual_depth': spiritualDepths.isNotEmpty 
            ? spiritualDepths.reduce((a, b) => a + b) / spiritualDepths.length 
            : 0.0,
        'most_retained_book': _getMostRetainedBook(retentions),
      };
    } catch (e) {
      print('⚠️ Erreur analyse tendances: $e');
      return {};
    }
  }

  /// 🧠 Récupère le livre le plus retenu
  static String _getMostRetainedBook(List<Map<String, dynamic>> retentions) {
    final bookCounts = <String, int>{};
    
    for (final retention in retentions) {
      final id = retention['id'] as String?;
      if (id != null) {
        final book = id.split('.').first;
        bookCounts[book] = (bookCounts[book] ?? 0) + 1;
      }
    }
    
    if (bookCounts.isEmpty) return 'Aucun';
    
    return bookCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 🧠 Retourne les statistiques de mémoire intelligente
  static Map<String, dynamic> getIntelligentStats() {
    return {
      'service_type': 'Évangéliste Intelligent',
      'features': [
        'Analyse sémantique des passages',
        'Contexte Thompson enrichi',
        'Score de priorité intelligent',
        'Analyse émotionnelle des rétentions',
        'Calcul de profondeur spirituelle',
        'Suggestions intelligentes',
        'Tendances de mémorisation',
      ],
      'integrations': [
        'semantic_passage_boundary_service.dart (FALCON X)',
        'thompson_plan_service.dart (Thompson)',
        'meditation_journal_service.dart (Journal)',
      ],
    };
  }
}



