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
}
