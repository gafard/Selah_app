import '../domain/user_prefs.dart';

/// Contrat pour la gestion des préférences utilisateur
abstract class UserPrefsService {
  Future<UserProfile> getProfile();
  Future<void> setHasOnboarded({required bool value});
}

/// Implémentation locale avec simulation de délais
class UserPrefsLocal implements UserPrefsService {
  // TODO: Branche à ton storage (SharedPrefs/Hive/Supabase…)
  @override
  Future<UserProfile> getProfile() async {
    // Simulation de lecture depuis le stockage
    await Future.delayed(const Duration(milliseconds: 120));
    return UserProfile(
      displayName: 'Jean',
      preferences: {
        'hasOnboarded': false,
        'goals': ['memorisation','discipline','connaissance'],
        'audioMode': true,
        'currentPlanId': 'plan_42',
      },
      bibleVersion: 'LSG',
      preferredTime: '07:00',
      dailyMinutes: 15,
    );
  }

  @override
  Future<void> setHasOnboarded({required bool value}) async {
    // TODO: Écrire dans le stockage/backend
    await Future.delayed(const Duration(milliseconds: 80));
  }
}