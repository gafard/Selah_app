import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';

/// Service pour réinitialiser complètement l'application
/// Supprime toutes les données locales (comptes, plans, préférences, etc.)
class AppResetService {
  /// 🔥 RÉINITIALISATION COMPLÈTE DE L'APPLICATION
  /// ⚠️ DANGER : Supprime TOUTES les données locales
  static Future<void> resetEverything() async {
    print('🔥 === RÉINITIALISATION COMPLÈTE DE L\'APPLICATION ===');
    
    try {
      // 1. Supprimer toutes les boxes Hive
      await _deleteAllHiveBoxes();
      
      // 2. Supprimer toutes les SharedPreferences
      await _clearSharedPreferences();
      
      // 3. Supprimer les données de LocalStorageService
      await _clearLocalStorage();
      
      print('✅ Réinitialisation complète terminée !');
      print('📱 Redémarrez l\'application pour créer un nouveau compte.');
      
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la réinitialisation: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Supprime toutes les boxes Hive
  static Future<void> _deleteAllHiveBoxes() async {
    print('🗑️ Suppression des boxes Hive...');
    
    final boxNames = [
      'local_user',      // Utilisateurs locaux
      'local_plans',     // Plans locaux
      'local_bible',     // Bibles téléchargées
      'local_progress',  // Progression
      'user_prefs',      // Préférences utilisateur
      'sync_tasks',      // Tâches de synchronisation
      'plans',           // Cache des plans
      'plan_days',       // Cache des jours de plans
      'prefs',           // Préférences (UserPrefs)
      'profile_box',     // Profil utilisateur
      'reading_log',     // Journal de lecture
      'meditation_journal', // Journal de méditation
    ];
    
    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          print('  ✅ Box "$boxName" vidée');
        } else {
          // Ouvrir et vider la box si elle existe
          try {
            final box = await Hive.openBox(boxName);
            await box.clear();
            await box.close();
            print('  ✅ Box "$boxName" vidée et fermée');
          } catch (e) {
            print('  ℹ️ Box "$boxName" n\'existe pas (ignoré)');
          }
        }
      } catch (e) {
        print('  ⚠️ Erreur suppression box "$boxName": $e');
      }
    }
    
    // Supprimer complètement Hive (optionnel - radical)
    try {
      await Hive.deleteFromDisk();
      print('  ✅ Hive supprimé du disque');
    } catch (e) {
      print('  ⚠️ Impossible de supprimer Hive du disque: $e');
    }
  }
  
  /// Supprime toutes les SharedPreferences
  static Future<void> _clearSharedPreferences() async {
    print('🗑️ Suppression des SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('  ✅ SharedPreferences vidées');
    } catch (e) {
      print('  ⚠️ Erreur suppression SharedPreferences: $e');
    }
  }
  
  /// Supprime les données de LocalStorageService
  static Future<void> _clearLocalStorage() async {
    print('🗑️ Suppression LocalStorageService...');
    
    try {
      await LocalStorageService.clearLocalUser();
      print('  ✅ Utilisateur local supprimé');
    } catch (e) {
      print('  ⚠️ Erreur suppression LocalStorageService: $e');
    }
  }
  
  /// 🧪 RÉINITIALISATION PARTIELLE (seulement profil, garde les plans)
  static Future<void> resetProfileOnly() async {
    print('🔄 Réinitialisation du profil uniquement...');
    
    try {
      // Vider seulement les boxes de profil
      final profileBoxNames = ['user_prefs', 'prefs', 'profile_box', 'local_user'];
      
      for (final boxName in profileBoxNames) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            print('  ✅ Box "$boxName" vidée');
          } else {
            final box = await Hive.openBox(boxName);
            await box.clear();
            await box.close();
            print('  ✅ Box "$boxName" vidée');
          }
        } catch (e) {
          print('  ⚠️ Box "$boxName": $e');
        }
      }
      
      // Vider SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      print('✅ Profil réinitialisé !');
    } catch (e) {
      print('❌ Erreur réinitialisation profil: $e');
      rethrow;
    }
  }
}


