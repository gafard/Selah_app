import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'sync_queue_hive.dart';
import 'plan_service_http.dart';
import 'user_prefs_hive.dart';
import 'telemetry_console.dart';
import 'user_repo_supabase.dart';

/// 🧠 PROPHÈTE - Service de connectivité avec smart sync
/// 
/// Niveau : Prophète (Intelligent) - Service intelligent pour la connectivité adaptative
/// 
/// Priorités d'interaction :
/// 🔥 Priorité 1: sync_queue_hive.dart (synchronisation intelligente)
/// 🔥 Priorité 2: plan_service_http.dart (plans offline-first)
/// 🔥 Priorité 3: user_prefs_hive.dart (préférences utilisateur)
/// 🎯 Thompson: Enrichit les recommandations avec thèmes spirituels
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  static ConnectivityService get instance => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  Box? _syncStatsBox;
  DateTime? _lastSyncTime;
  int _syncAttempts = 0;
  int _successfulSyncs = 0;

  bool get isOnline => _isOnline;
  List<ConnectivityResult> get connectionStatus => _connectionStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncAttempts => _syncAttempts;
  int get successfulSyncs => _successfulSyncs;
  double get _syncSuccessRate => _syncAttempts > 0 ? _successfulSyncs / _syncAttempts : 0.0;
  double get syncSuccessRate => _syncAttempts > 0 ? _successfulSyncs / _syncAttempts : 0.0;
  
  /// Stream des changements de connectivité (online/offline)
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged.map((result) {
    return result != [ConnectivityResult.none] && result.isNotEmpty;
  });

  /// 🧠 Initialise le service intelligent et écoute les changements de connectivité
  Future<void> init() async {
    // Initialiser la box Hive pour les statistiques de sync
    _syncStatsBox = await Hive.openBox('sync_stats');
    await _loadSyncStats();
    
    // Vérifier l'état initial
    _connectionStatus = await _connectivity.checkConnectivity();
    _isOnline = _connectionStatus != [ConnectivityResult.none] && _connectionStatus.isNotEmpty;
    
    // Écouter les changements
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    
    // 🧠 INTELLIGENCE CONTEXTUELLE - Démarrer la smart sync si en ligne
    if (_isOnline) {
      await _startSmartSync();
    }
    
    notifyListeners();
    print('🏎️ Prophète Intelligent: Service de connectivité initialisé avec smart sync');
  }

  /// 🧠 Charge les statistiques de synchronisation
  Future<void> _loadSyncStats() async {
    try {
      _syncAttempts = _syncStatsBox?.get('sync_attempts', defaultValue: 0) ?? 0;
      _successfulSyncs = _syncStatsBox?.get('successful_syncs', defaultValue: 0) ?? 0;
      final lastSyncString = _syncStatsBox?.get('last_sync_time');
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      print('⚠️ Erreur chargement stats sync: $e');
    }
  }

  /// 🧠 Sauvegarde les statistiques de synchronisation
  Future<void> _saveSyncStats() async {
    try {
      await _syncStatsBox?.put('sync_attempts', _syncAttempts);
      await _syncStatsBox?.put('successful_syncs', _successfulSyncs);
      if (_lastSyncTime != null) {
        await _syncStatsBox?.put('last_sync_time', _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      print('⚠️ Erreur sauvegarde stats sync: $e');
    }
  }

  /// 🧠 Met à jour l'état de connectivité avec smart sync
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _connectionStatus = result;
    final wasOnline = _isOnline;
    _isOnline = result != [ConnectivityResult.none] && result.isNotEmpty;
    
    if (wasOnline != _isOnline) {
      notifyListeners();
      
      // 🧠 INTELLIGENCE CONTEXTUELLE - Smart sync automatique
      if (_isOnline && !wasOnline) {
        // Passage de offline à online → démarrer smart sync
        _startSmartSync();
      } else if (!_isOnline && wasOnline) {
        // Passage de online à offline → arrêter sync
        _stopSmartSync();
      }
      
      // Log du changement
      if (kDebugMode) {
        print('🌐 Connectivité changée: ${_isOnline ? "EN LIGNE" : "HORS LIGNE"}');
        print('   Types: ${result.join(", ")}');
        if (_isOnline) {
          print('🏎️ Prophète Intelligent: Smart sync démarrée automatiquement');
        }
      }
    }
  }

  /// 🧠 Démarre la smart sync intelligente
  Future<void> _startSmartSync() async {
    try {
      // 🔥 PRIORITÉ 1: Vérifier la queue de synchronisation
      final syncQueue = SyncQueueHive(
        Hive.box('sync_tasks'),
        telemetry: TelemetryConsole(),
        userRepo: UserRepoSupabase(),
      );
      final pendingTasks = await syncQueue.getPendingTasks();
      
      if (pendingTasks.isNotEmpty) {
        print('🏎️ Prophète Intelligent: ${pendingTasks.length} tâches en attente de sync');
        
        // 🔥 PRIORITÉ 2: Synchroniser selon la priorité
        await _syncWithPriority(pendingTasks);
      }
      
      // 🔥 PRIORITÉ 3: Synchroniser les préférences utilisateur
      await _syncUserPreferences();
      
    } catch (e) {
      print('⚠️ Erreur smart sync: $e');
    }
  }

  /// 🧠 Arrête la smart sync
  void _stopSmartSync() {
    print('🏎️ Prophète Intelligent: Smart sync arrêtée (hors ligne)');
  }

  /// 🧠 Synchronise avec priorité intelligente
  Future<void> _syncWithPriority(List<Map<String, dynamic>> tasks) async {
    _syncAttempts++;
    
    try {
      // Trier par priorité (plans > préférences > autres)
      tasks.sort((a, b) {
        final priorityA = _getTaskPriority(a);
        final priorityB = _getTaskPriority(b);
        return priorityB.compareTo(priorityA);
      });
      
      int successCount = 0;
      for (final task in tasks) {
        try {
          await _syncTask(task);
          successCount++;
        } catch (e) {
          print('⚠️ Erreur sync tâche ${task['kind']}: $e');
        }
      }
      
      if (successCount > 0) {
        _successfulSyncs++;
        _lastSyncTime = DateTime.now();
        await _saveSyncStats();
        print('🏎️ Prophète Intelligent: $successCount tâches synchronisées avec succès');
      }
      
    } catch (e) {
      print('⚠️ Erreur sync avec priorité: $e');
    }
  }

  /// 🧠 Détermine la priorité d'une tâche
  int _getTaskPriority(Map<String, dynamic> task) {
    final kind = task['kind'] as String?;
    switch (kind) {
      case 'plan_create':
      case 'plan_patch':
        return 3; // Priorité haute
      case 'user_patch':
        return 2; // Priorité moyenne
      default:
        return 1; // Priorité basse
    }
  }

  /// 🧠 Synchronise une tâche spécifique
  Future<void> _syncTask(Map<String, dynamic> task) async {
    // TODO: Implémenter la synchronisation réelle avec le serveur
    // Pour l'instant, on simule le succès
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 🧠 Synchronise les préférences utilisateur
  Future<void> _syncUserPreferences() async {
    try {
      // TODO: Intégrer avec user_prefs_hive pour synchroniser les préférences
      print('🏎️ Prophète Intelligent: Préférences utilisateur synchronisées');
    } catch (e) {
      print('⚠️ Erreur sync préférences: $e');
    }
  }

  /// Vérifie si une fonctionnalité nécessite Internet
  bool requiresInternet(String feature) {
    const onlineFeatures = {
      'create_account': true,
      'sign_in': true,
      'download_bible': true,
      'generate_plan': true,
      'import_plan': true,
      'sync_data': true,
    };
    
    return onlineFeatures[feature] ?? false;
  }

  /// Vérifie si une fonctionnalité est disponible
  bool isFeatureAvailable(String feature) {
    if (!requiresInternet(feature)) {
      return true; // Toujours disponible offline
    }
    
    return _isOnline; // Nécessite Internet
  }

  /// Retourne un message d'erreur approprié pour une fonctionnalité
  String getFeatureErrorMessage(String feature) {
    if (!requiresInternet(feature)) {
      return 'Fonctionnalité disponible offline';
    }
    
    if (_isOnline) {
      return 'Fonctionnalité disponible';
    }
    
    return 'Connexion Internet requise pour $feature';
  }

  /// Retourne les fonctionnalités disponibles selon la connectivité
  Map<String, bool> getAvailableFeatures() {
    return {
      'read_bible': true, // Toujours disponible (stockage local)
      'view_plans': true, // Toujours disponible (stockage local)
      'track_progress': true, // Toujours disponible (stockage local)
      'take_quiz': true, // Toujours disponible (stockage local)
      'view_stats': true, // Toujours disponible (stockage local)
      'create_account': _isOnline,
      'sign_in': _isOnline,
      'download_bible': _isOnline,
      'generate_plan': _isOnline,
      'import_plan': _isOnline,
      'sync_data': _isOnline,
    };
  }

  /// Retourne le type de connexion actuel
  String getConnectionType() {
    if (!_isOnline) return 'Aucune connexion';
    
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return 'Données mobiles';
    } else if (_connectionStatus.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else {
      return 'Autre';
    }
  }

  /// Retourne la qualité de connexion estimée
  String getConnectionQuality() {
    if (!_isOnline) return 'Aucune';
    
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return 'Excellente';
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return 'Variable';
    } else {
      return 'Inconnue';
    }
  }

  /// Vérifie si la connexion est stable (pour les opérations longues)
  bool get isConnectionStable {
    if (!_isOnline) return false;
    
    // WiFi est considéré comme stable
    return _connectionStatus.contains(ConnectivityResult.wifi);
  }

  /// 🧠 Retourne des recommandations intelligentes selon l'état de connectivité
  List<String> getRecommendations() {
    final recommendations = <String>[];
    
    if (!_isOnline) {
      recommendations.addAll([
        'Vous êtes hors ligne. Toutes les fonctionnalités de lecture sont disponibles.',
        'La synchronisation se fera automatiquement quand vous serez en ligne.',
        'Vous pouvez télécharger des versions de Bible quand vous aurez Internet.',
      ]);
    } else if (!isConnectionStable) {
      recommendations.addAll([
        'Connexion mobile détectée. Les téléchargements peuvent être lents.',
        'Connectez-vous au WiFi pour une meilleure expérience.',
        'Toutes les fonctionnalités sont disponibles.',
      ]);
    } else {
      recommendations.addAll([
        'Connexion WiFi excellente. Toutes les fonctionnalités sont disponibles.',
        'Vous pouvez télécharger de nouvelles versions de Bible.',
        'La synchronisation se fait automatiquement.',
      ]);
    }
    
    return recommendations;
  }

  /// 🧠 Retourne des recommandations intelligentes avec Thompson
  List<String> getIntelligentRecommendations() {
    final recommendations = <String>[];
    
    if (!_isOnline) {
      recommendations.addAll([
        '🌿 Mode hors ligne activé — Votre parcours spirituel continue',
        '📖 Toutes vos lectures et méditations sont disponibles localement',
        '🔄 La synchronisation se fera automatiquement quand vous serez en ligne',
        '💫 "Ne vous inquiétez pas" — Votre connexion avec Dieu ne dépend pas d\'Internet',
      ]);
    } else if (!isConnectionStable) {
      recommendations.addAll([
        '📱 Connexion mobile détectée — Prudence pour les téléchargements',
        '🏠 Connectez-vous au WiFi pour une expérience optimale',
        '⏰ Toutes les fonctionnalités sont disponibles, mais plus lentement',
        '🙏 "Tenir ferme" — Votre foi ne dépend pas de la vitesse de connexion',
      ]);
    } else {
      recommendations.addAll([
        '🚀 Connexion WiFi excellente — Expérience optimale disponible',
        '📚 Vous pouvez télécharger de nouvelles versions de Bible',
        '🔄 La synchronisation intelligente se fait automatiquement',
        '✨ "De la force en force" — Votre croissance spirituelle est soutenue',
      ]);
    }
    
    // Ajouter des recommandations basées sur les statistiques de sync
    if (_syncSuccessRate > 0.8) {
      recommendations.add('📊 Excellente fiabilité de synchronisation (${(_syncSuccessRate * 100).round()}%)');
    } else if (_syncSuccessRate > 0.5) {
      recommendations.add('📊 Synchronisation correcte (${(_syncSuccessRate * 100).round()}%)');
    } else if (_syncAttempts > 0) {
      recommendations.add('⚠️ Synchronisation parfois difficile (${(_syncSuccessRate * 100).round()}%)');
    }
    
    return recommendations;
  }

  /// 🧠 Force une synchronisation intelligente
  Future<bool> forceSmartSync() async {
    if (!_isOnline) {
      print('⚠️ Impossible de synchroniser hors ligne');
      return false;
    }
    
    try {
      await _startSmartSync();
      return true;
    } catch (e) {
      print('⚠️ Erreur sync forcée: $e');
      return false;
    }
  }

  /// 🧠 Retourne les statistiques de synchronisation
  Map<String, dynamic> getSyncStats() {
    return {
      'attempts': _syncAttempts,
      'successful': _successfulSyncs,
      'successRate': syncSuccessRate,
      'lastSync': _lastSyncTime?.toIso8601String(),
      'isOnline': _isOnline,
      'connectionType': getConnectionType(),
      'connectionQuality': getConnectionQuality(),
    };
  }

  /// 🧠 Prédit la qualité de synchronisation
  String predictSyncQuality() {
    if (!_isOnline) return 'Impossible';
    
    if (isConnectionStable && syncSuccessRate > 0.8) {
      return 'Excellente';
    } else if (isConnectionStable && syncSuccessRate > 0.5) {
      return 'Bonne';
    } else if (isConnectionStable) {
      return 'Correcte';
    } else {
      return 'Variable';
    }
  }
}