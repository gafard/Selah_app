import 'package:hive/hive.dart';

class UserPrefs {
  static Future<Map<String, dynamic>> loadProfile() async {
    final box = await Hive.openBox('prefs');
    return (box.get('profile') as Map?)?.cast<String, dynamic>() ?? {};
  }

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final box = await Hive.openBox('prefs');
    await box.put('profile', profile);
  }

  static Future<String?> getBibleVersionCode() async {
    final box = await Hive.openBox('prefs');
    return box.get('bible_version') as String?;
  }

  static Future<void> setBibleVersionCode(String code) async {
    final box = await Hive.openBox('prefs');
    await box.put('bible_version', code);
  }

  // ============ PRÉFÉRENCES DE LECTURE DE VERSETS ============
  
  /// Récupère le profil utilisateur complet
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      return await loadProfile();
    } catch (e) {
      print('⚠️ Erreur chargement profil: $e');
      return null;
    }
  }
  
  /// Récupère les préférences de lecture de versets
  static Future<Map<String, dynamic>> getVerseReadingPreferences() async {
    try {
      final profile = await loadProfile();
      return {
        'minVerses': profile['minVerses'] as int? ?? 4,
        'maxVerses': profile['maxVerses'] as int? ?? 18,
        'meditationType': profile['meditationType'] as String? ?? 'Méditation Biblique',
        'respectLiteraryUnits': profile['respectLiteraryUnits'] as bool? ?? true,
        'useIntelligentLimits': profile['useIntelligentLimits'] as bool? ?? true,
      };
    } catch (e) {
      print('⚠️ Erreur chargement préférences versets: $e');
      return {
        'minVerses': 4,
        'maxVerses': 18,
        'meditationType': 'Méditation Biblique',
        'respectLiteraryUnits': true,
        'useIntelligentLimits': true,
      };
    }
  }
  
  /// Définit les préférences de lecture de versets
  static Future<void> setVerseReadingPreferences({
    int? minVerses,
    int? maxVerses,
    String? meditationType,
    bool? respectLiteraryUnits,
    bool? useIntelligentLimits,
  }) async {
    try {
      final profile = await loadProfile();
      
      if (minVerses != null) profile['minVerses'] = minVerses;
      if (maxVerses != null) profile['maxVerses'] = maxVerses;
      if (meditationType != null) profile['meditationType'] = meditationType;
      if (respectLiteraryUnits != null) profile['respectLiteraryUnits'] = respectLiteraryUnits;
      if (useIntelligentLimits != null) profile['useIntelligentLimits'] = useIntelligentLimits;
      
      await saveProfile(profile);
      print('✅ Préférences de lecture de versets sauvegardées');
    } catch (e) {
      print('⚠️ Erreur sauvegarde préférences versets: $e');
    }
  }
  
  /// Met à jour les préférences de lecture avec un objet VerseReadingPreferences
  static Future<void> setVerseReadingPreferencesFromObject(Map<String, dynamic> prefs) async {
    await setVerseReadingPreferences(
      minVerses: prefs['minVerses'] as int?,
      maxVerses: prefs['maxVerses'] as int?,
      meditationType: prefs['meditationType'] as String?,
      respectLiteraryUnits: prefs['respectLiteraryUnits'] as bool?,
      useIntelligentLimits: prefs['useIntelligentLimits'] as bool?,
    );
  }
}
