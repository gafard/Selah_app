import 'package:hive/hive.dart';

class UserPrefsHive {
  final Box box;
  UserPrefsHive(this.box);

  Map<String, dynamic> get profile => Map<String, dynamic>.from(box.get('profile') ?? {});

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