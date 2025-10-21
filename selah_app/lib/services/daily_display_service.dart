import 'package:hive_flutter/hive_flutter.dart';

/// Service pour gérer l'affichage unique par jour des éléments UI
class DailyDisplayService {
  static const String _boxName = 'daily_displays';
  static const String _airplaneWarningKey = 'airplane_warning_shown_date';
  static const String _preMeditationKey = 'pre_meditation_shown_date';
  static const String _markAsReadKey = 'mark_as_read_shown_date';
  
  static Box? _box;
  
  /// Initialise le service avec la box Hive
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }
  
  /// Vérifie si un élément doit être affiché aujourd'hui
  static bool shouldShowToday(String key) {
    if (_box == null) return true; // Si pas initialisé, afficher par défaut
    
    final lastShownDate = _box!.get(key) as String?;
    if (lastShownDate == null) return true; // Jamais affiché
    
    final today = _getTodayString();
    return lastShownDate != today;
  }
  
  /// Marque un élément comme affiché aujourd'hui
  static Future<void> markAsShownToday(String key) async {
    if (_box == null) return;
    
    final today = _getTodayString();
    await _box!.put(key, today);
  }
  
  /// Vérifie si l'avertissement mode avion doit être affiché aujourd'hui
  static bool shouldShowAirplaneWarning() {
    return shouldShowToday(_airplaneWarningKey);
  }
  
  /// Marque l'avertissement mode avion comme affiché aujourd'hui
  static Future<void> markAirplaneWarningAsShown() async {
    await markAsShownToday(_airplaneWarningKey);
  }
  
  /// Vérifie si la page pre_meditation_prayer doit être affichée aujourd'hui
  static bool shouldShowPreMeditationPrayer() {
    return shouldShowToday(_preMeditationKey);
  }
  
  /// Marque la page pre_meditation_prayer comme affichée aujourd'hui
  static Future<void> markPreMeditationPrayerAsShown() async {
    await markAsShownToday(_preMeditationKey);
  }

  /// Vérifie si le bouton "Marquer comme lu" a été utilisé aujourd'hui
  static bool hasMarkedAsReadToday() {
    return !shouldShowToday(_markAsReadKey);
  }

  /// Marque le passage comme lu aujourd'hui
  static Future<void> markPassageAsReadToday() async {
    await markAsShownToday(_markAsReadKey);
  }
  
  /// Obtient la date d'aujourd'hui au format YYYY-MM-DD
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  /// Nettoie les données anciennes (optionnel, pour maintenance)
  static Future<void> cleanup() async {
    if (_box == null) return;
    
    final today = _getTodayString();
    final keys = _box!.keys.toList();
    
    for (final key in keys) {
      final value = _box!.get(key) as String?;
      if (value != null && value != today) {
        await _box!.delete(key);
      }
    }
  }
}
