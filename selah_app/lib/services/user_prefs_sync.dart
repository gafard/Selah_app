import 'dart:async';
import 'user_prefs.dart';
import 'user_prefs_hive.dart';

/// Service de synchronisation bidirectionnelle entre UserPrefs et UserPrefsHive
class UserPrefsSync {
  static UserPrefsHive? _userPrefsHive;
  static bool _isInitialized = false;
  
  /// Initialise le service de synchronisation
  static void init(UserPrefsHive userPrefsHive) {
    _userPrefsHive = userPrefsHive;
    _isInitialized = true;
  }
  
  /// Vérifie si le service est initialisé
  static bool get isInitialized => _isInitialized && _userPrefsHive != null;
  
  /// Synchronise UserPrefsHive vers UserPrefs (pour compatibilité)
  static Future<void> syncFromHiveToPrefs() async {
    if (!isInitialized) return;
    
    try {
      final profile = _userPrefsHive!.profile;
      if (profile.isNotEmpty) {
        await UserPrefs.saveProfile(profile);
        print('🔄 UserPrefsSync: Profil synchronisé de UserPrefsHive vers UserPrefs');
      }
    } catch (e) {
      print('⚠️ UserPrefsSync: Erreur synchronisation Hive→Prefs: $e');
    }
  }
  
  /// Synchronise UserPrefs vers UserPrefsHive (pour compatibilité)
  static Future<void> syncFromPrefsToHive() async {
    if (!isInitialized) return;
    
    try {
      final profile = await UserPrefs.loadProfile();
      if (profile.isNotEmpty) {
        await _userPrefsHive!.patchProfile(profile);
        print('🔄 UserPrefsSync: Profil synchronisé de UserPrefs vers UserPrefsHive');
      }
    } catch (e) {
      print('⚠️ UserPrefsSync: Erreur synchronisation Prefs→Hive: $e');
    }
  }
  
  /// Synchronise bidirectionnellement (merge intelligent)
  static Future<void> syncBidirectional() async {
    if (!isInitialized) return;
    
    try {
      final hiveProfile = _userPrefsHive!.profile;
      final prefsProfile = await UserPrefs.loadProfile();
      
      // Merge intelligent : UserPrefsHive a priorité (plus récent)
      final mergedProfile = Map<String, dynamic>.from(prefsProfile);
      mergedProfile.addAll(hiveProfile);
      mergedProfile['updated_at'] = DateTime.now().toIso8601String();
      
      // Sauvegarder dans les deux systèmes
      await UserPrefs.saveProfile(mergedProfile);
      await _userPrefsHive!.patchProfile(mergedProfile);
      
      print('🔄 UserPrefsSync: Synchronisation bidirectionnelle terminée');
    } catch (e) {
      print('⚠️ UserPrefsSync: Erreur synchronisation bidirectionnelle: $e');
    }
  }
  
  /// Sauvegarde dans les deux systèmes (pour les nouvelles données)
  static Future<void> saveToBoth(Map<String, dynamic> data) async {
    if (!isInitialized) return;
    
    try {
      // Sauvegarder dans UserPrefsHive (système principal)
      await _userPrefsHive!.patchProfile(data);
      
      // Synchroniser vers UserPrefs (pour compatibilité)
      await syncFromHiveToPrefs();
      
      print('🔄 UserPrefsSync: Données sauvegardées dans les deux systèmes');
    } catch (e) {
      print('⚠️ UserPrefsSync: Erreur sauvegarde double: $e');
    }
  }
  
  /// Surveille les changements et synchronise automatiquement
  static Future<void> startAutoSync() async {
    if (!isInitialized) return;
    
    // Synchronisation périodique toutes les 30 secondes
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!isInitialized) {
        timer.cancel();
        return;
      }
      
      try {
        await syncBidirectional();
      } catch (e) {
        print('⚠️ UserPrefsSync: Erreur synchronisation automatique: $e');
      }
    });
    
    print('🔄 UserPrefsSync: Surveillance automatique démarrée');
  }
}
