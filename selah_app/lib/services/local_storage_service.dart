import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service de stockage local pour l'approche offline-first
class LocalStorageService {
  static Box? _userBox;
  static Box? _plansBox;
  static Box? _bibleBox;
  static Box? _progressBox;
  
  /// Initialisation des boîtes Hive
  static Future<void> init() async {
    _userBox = await Hive.openBox('local_user');
    _plansBox = await Hive.openBox('local_plans');
    _bibleBox = await Hive.openBox('local_bible');
    _progressBox = await Hive.openBox('local_progress');
  }
  
  /// Vérifie la connectivité
  static Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // ===== GESTION UTILISATEUR LOCAL =====
  
  /// Sauvegarde un utilisateur local
  static Future<void> saveLocalUser(Map<String, dynamic> userData) async {
    await _userBox?.put('current_user', userData);
  }
  
  /// Récupère l'utilisateur local
  static Map<String, dynamic>? getLocalUser() {
    final userData = _userBox?.get('current_user');
    if (userData == null) return null;
    return Map<String, dynamic>.from(userData as Map);
  }
  
  /// Vérifie si un utilisateur local existe
  static bool hasLocalUser() {
    return _userBox?.containsKey('current_user') ?? false;
  }
  
  /// Supprime l'utilisateur local
  static Future<void> clearLocalUser() async {
    await _userBox?.delete('current_user');
  }
  
  /// ✅ Récupère le profil utilisateur (offline-first)
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      // Vérifier dans la box 'prefs' (UserPrefs utilise SharedPreferences)
      final prefsBox = await Hive.openBox('prefs');
      final profile = prefsBox.get('profile');
      
      if (profile != null && profile is Map) {
        return Map<String, dynamic>.from(profile as Map);
      }
      
      // Fallback : lire depuis current_user si présent
      final user = getLocalUser();
      if (user != null) {
        return user;
      }
      
      return {};
    } catch (e) {
      print('⚠️ Erreur getProfile: $e');
      return {};
    }
  }
  
  // ===== GESTION PLANS LOCAUX =====
  
  /// Sauvegarde un plan localement
  static Future<void> saveLocalPlan(String planId, Map<String, dynamic> planData) async {
    await _plansBox?.put(planId, planData);
  }
  
  /// Récupère un plan local
  static Map<String, dynamic>? getLocalPlan(String planId) {
    return _plansBox?.get(planId) as Map<String, dynamic>?;
  }
  
  /// Récupère tous les plans locaux
  static List<Map<String, dynamic>> getAllLocalPlans() {
    final plans = <Map<String, dynamic>>[];
    _plansBox?.values.forEach((plan) {
      if (plan is Map<String, dynamic>) {
        plans.add(plan);
      }
    });
    return plans;
  }
  
  /// Marque un plan comme actif localement
  static Future<void> setActiveLocalPlan(String planId) async {
    await _plansBox?.put('active_plan_id', planId);
  }
  
  /// Récupère le plan actif local
  static String? getActiveLocalPlanId() {
    return _plansBox?.get('active_plan_id') as String?;
  }
  
  // ===== GESTION BIBLE LOCALE =====
  
  /// Sauvegarde une version de Bible localement
  static Future<void> saveBibleVersion(String version, Map<String, dynamic> bibleData) async {
    await _bibleBox?.put(version, bibleData);
  }
  
  /// Récupère une version de Bible locale
  static Map<String, dynamic>? getBibleVersion(String version) {
    return _bibleBox?.get(version) as Map<String, dynamic>?;
  }
  
  /// Récupère toutes les versions de Bible disponibles localement
  static List<String> getAvailableBibleVersions() {
    return _bibleBox?.keys.cast<String>().toList() ?? [];
  }
  
  /// Marque une version comme active
  static Future<void> setActiveBibleVersion(String version) async {
    await _bibleBox?.put('active_version', version);
  }
  
  /// Récupère la version active
  static String? getActiveBibleVersion() {
    return _bibleBox?.get('active_version') as String?;
  }
  
  // ===== GESTION PROGRESSION LOCALE =====
  
  /// Sauvegarde la progression d'un jour
  static Future<void> saveDayProgress(String planId, int dayIndex, Map<String, dynamic> progress) async {
    final key = '${planId}_day_$dayIndex';
    await _progressBox?.put(key, progress);
  }
  
  /// Récupère la progression d'un jour
  static Map<String, dynamic>? getDayProgress(String planId, int dayIndex) {
    final key = '${planId}_day_$dayIndex';
    return _progressBox?.get(key) as Map<String, dynamic>?;
  }
  
  /// Récupère toute la progression d'un plan
  static Map<int, Map<String, dynamic>> getPlanProgress(String planId) {
    final progress = <int, Map<String, dynamic>>{};
    _progressBox?.keys.forEach((key) {
      if (key.toString().startsWith('${planId}_day_')) {
        final dayIndex = int.tryParse(key.toString().split('_day_').last);
        if (dayIndex != null) {
          final data = _progressBox?.get(key) as Map<String, dynamic>?;
          if (data != null) {
            progress[dayIndex] = data;
          }
        }
      }
    });
    return progress;
  }
  
  /// Calcule le pourcentage de progression d'un plan
  static double getPlanProgressPercentage(String planId) {
    final progress = getPlanProgress(planId);
    if (progress.isEmpty) return 0.0;
    
    final completedDays = progress.values.where((p) => p['completed'] == true).length;
    return completedDays / progress.length;
  }
  
  // ===== GESTION SCORES ET STATISTIQUES =====
  
  /// Sauvegarde un score de quiz
  static Future<void> saveQuizScore(String quizId, Map<String, dynamic> score) async {
    await _progressBox?.put('quiz_$quizId', score);
  }
  
  /// Récupère un score de quiz
  static Map<String, dynamic>? getQuizScore(String quizId) {
    return _progressBox?.get('quiz_$quizId') as Map<String, dynamic>?;
  }
  
  /// Récupère tous les scores
  static List<Map<String, dynamic>> getAllQuizScores() {
    final scores = <Map<String, dynamic>>[];
    _progressBox?.keys.forEach((key) {
      if (key.toString().startsWith('quiz_')) {
        final score = _progressBox?.get(key) as Map<String, dynamic>?;
        if (score != null) {
          scores.add(score);
        }
      }
    });
    return scores;
  }
  
  // ===== SYNCHRONISATION =====
  
  /// Marque des données comme nécessitant une synchronisation
  static Future<void> markForSync(String dataType, String dataId) async {
    final rawQueue = _progressBox?.get('sync_queue');
    final syncQueue = <Map<String, dynamic>>[];
    
    // ✅ Convertir List<dynamic> en List<Map<String, dynamic>>
    if (rawQueue != null && rawQueue is List) {
      for (final item in rawQueue) {
        if (item is Map) {
          syncQueue.add(Map<String, dynamic>.from(item));
        }
      }
    }
    
    syncQueue.add({
      'type': dataType,
      'id': dataId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _progressBox?.put('sync_queue', syncQueue);
  }
  
  /// Récupère la queue de synchronisation
  static List<Map<String, dynamic>> getSyncQueue() {
    final rawQueue = _progressBox?.get('sync_queue');
    final syncQueue = <Map<String, dynamic>>[];
    
    // ✅ Convertir List<dynamic> en List<Map<String, dynamic>>
    if (rawQueue != null && rawQueue is List) {
      for (final item in rawQueue) {
        if (item is Map) {
          syncQueue.add(Map<String, dynamic>.from(item));
        }
      }
    }
    
    return syncQueue;
  }
  
  /// Vide la queue de synchronisation
  static Future<void> clearSyncQueue() async {
    await _progressBox?.delete('sync_queue');
  }
  
  // ===== NETTOYAGE =====
  
  /// Nettoie toutes les données locales
  static Future<void> clearAllData() async {
    await _userBox?.clear();
    await _plansBox?.clear();
    await _bibleBox?.clear();
    await _progressBox?.clear();
  }
  
  /// Ferme toutes les boîtes
  static Future<void> close() async {
    await _userBox?.close();
    await _plansBox?.close();
    await _bibleBox?.close();
    await _progressBox?.close();
  }
}
