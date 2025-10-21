import 'package:hive/hive.dart';
import '../domain/user_prefs.dart';

class UserPrefsHive implements UserPrefs {
  final Box box;
  UserPrefsHive(this.box);

  // Méthode de compatibilité pour l'ancien code
  Map<String, dynamic> get profile => Map<String, dynamic>.from(box.get('profile') ?? {});

  // Implémentation de l'interface UserPrefs
  @override
  Future<UserProfile> get() async {
    final data = box.get('profile', defaultValue: <String, dynamic>{});
    return UserProfile.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> set(UserProfile profile) async {
    await box.put('profile', profile.toJson());
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

  // Méthodes existantes (compatibilité)
  @override
  Future<void> setHasOnboarded(bool v) async {
    final p = profile;
    p['hasOnboarded'] = v;
    p['updated_at'] = DateTime.now().toIso8601String();
    await box.put('profile', p);
  }

  Future<void> patchProfile(Map<String, dynamic> patch) async {
    final p = profile..addAll(patch)..['updated_at'] = DateTime.now().toIso8601String();
    await box.put('profile', p);
  }
}