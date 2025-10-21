import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les intentions quotidiennes
class IntentionsService {
  static const String _enabledKey = 'intentions_enabled';
  static const String _textKey = 'intentions_text';
  
  /// Active ou désactive les intentions
  static Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
      print('📝 Intentions ${enabled ? 'activées' : 'désactivées'}');
    } catch (e) {
      print('❌ Erreur activation intentions: $e');
      rethrow;
    }
  }
  
  /// Vérifie si les intentions sont activées
  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      print('❌ Erreur vérification intentions: $e');
      return false;
    }
  }
  
  /// Sauvegarde l'intention du jour
  static Future<void> saveTodayIntention(String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_textKey, text.trim());
      print('📝 Intention du jour sauvegardée: ${text.trim()}');
    } catch (e) {
      print('❌ Erreur sauvegarde intention: $e');
      rethrow;
    }
  }
  
  /// Récupère l'intention du jour
  static Future<String?> getIntention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_textKey);
      return (text != null && text.trim().isNotEmpty) ? text.trim() : null;
    } catch (e) {
      print('❌ Erreur récupération intention: $e');
      return null;
    }
  }
  
  /// Supprime l'intention du jour
  static Future<void> clearIntention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_textKey);
      print('🗑️ Intention du jour supprimée');
    } catch (e) {
      print('❌ Erreur suppression intention: $e');
      rethrow;
    }
  }
  
  /// Vérifie si une intention existe pour aujourd'hui
  static Future<bool> hasIntention() async {
    final intention = await getIntention();
    return intention != null && intention.isNotEmpty;
  }
  
  /// Met à jour l'intention (combine get + save)
  static Future<void> updateIntention(String newText) async {
    await saveTodayIntention(newText);
  }
}





