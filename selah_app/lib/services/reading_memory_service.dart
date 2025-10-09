import 'package:hive/hive.dart';

/// Service offline pour mémoriser et retenir des passages
/// 
/// Fonctionnalités :
/// 1. File "Mémoriser ce passage" → Queue de versets à mémoriser
/// 2. "Retenu de ma lecture" → Ce que l'utilisateur a retenu aujourd'hui
/// 3. Proposition Poster en fin de prière
/// 
/// Box Hive : 'reading_mem'
/// 
/// Structure :
/// {
///   'memory_queue': [
///     {id: "Jean.3.16", note: "Verset central", date: "ISO8601", ...}
///   ],
///   'retentions': [
///     {id: "Luc.15.32", retained: "Dieu cherche les perdus", date: "ISO8601", ...}
///   ]
/// }
class ReadingMemoryService {
  static Box? _memBox;
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _memBox = await Hive.openBox('reading_mem');
    print('✅ ReadingMemoryService initialisé');
  }
  
  /// Ajoute un verset à la queue de mémorisation
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
      
      // Ajouter à la queue
      queue.add({
        'id': id,
        'note': note,
        'date_added': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, memorized, dismissed
      });
      
      await _memBox?.put('memory_queue', queue);
      print('✅ Verset $id ajouté à la queue de mémorisation');
    } catch (e) {
      print('❌ Erreur queueMemoryVerse($id): $e');
    }
  }
  
  /// Sauvegarde ce que l'utilisateur a retenu de sa lecture
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
      
      // Ajouter la nouvelle rétention
      retentions.add({
        'id': id,
        'retained': retained,
        'date': date.toIso8601String(),
        'add_to_journal': addToJournal,
        'add_to_wall': addToWall,
        'poster_created': false, // Flag pour proposer Poster plus tard
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await _memBox?.put('retentions', retentions);
      print('✅ Rétention sauvegardée pour $id');
      
      // Si addToJournal, déclencher aussi la sauvegarde dans le journal
      if (addToJournal) {
        await _saveToJournal(id, retained, date);
      }
      
      // Si addToWall, marquer pour publication
      if (addToWall) {
        await _saveToWall(id, retained, date);
      }
    } catch (e) {
      print('❌ Erreur saveRetention: $e');
    }
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
  
  /// Sauvegarde dans le journal spirituel
  static Future<void> _saveToJournal(String id, String retained, DateTime date) async {
    // TODO: Intégrer avec MeditationJournalService
    print('📔 Sauvegardé dans le journal: $id');
  }
  
  /// Sauvegarde sur le mur spirituel
  static Future<void> _saveToWall(String id, String retained, DateTime date) async {
    // TODO: Intégrer avec SpiritualWallService
    print('🧱 Publié sur le mur: $id');
  }
}

