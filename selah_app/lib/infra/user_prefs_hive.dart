import 'package:hive/hive.dart';
import '../domain/user_prefs.dart';

class UserPrefsHive implements UserPrefs {
  final Box _box;
  
  UserPrefsHive(this._box);

  @override
  Future<UserProfile> get() async {
    final data = _box.get('profile', defaultValue: <String, dynamic>{});
    return UserProfile.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> set(UserProfile profile) async {
    await _box.put('profile', profile.toJson());
  }

  @override
  Stream<UserProfile> get profileStream async* {
    yield await get();
    // Pour l'instant, on retourne juste le profil actuel
    // Dans une vraie implémentation, on écouterait les changements Hive
  }

  @override
  Future<void> update(UserProfile profile) async {
    await set(profile);
  }

  @override
  Future<void> setHasOnboarded(bool value) async {
    final p = profile;
    p['hasOnboarded'] = value;
    p['updated_at'] = DateTime.now().toIso8601String();
    await _box.put('profile', p);
  }

  // Méthode de compatibilité pour l'ancien code
  Map<String, dynamic> get profile {
    final data = _box.get('profile', defaultValue: <String, dynamic>{});
    return Map<String, dynamic>.from(data);
  }
}
