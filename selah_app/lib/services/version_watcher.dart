import '../models/plan_profile.dart';
import 'plan_orchestrator.dart';
import 'user_prefs.dart';
import 'user_prefs_sync.dart';

typedef ProfileProvider = Future<PlanProfile> Function();

class VersionWatcher {
  /// Appelle ceci lorsqu'un utilisateur change la version depuis les réglages.
  static Future<void> onBibleVersionChanged({
    required String newVersionCode,
    required ProfileProvider currentProfile,
    void Function()? onStart,
    void Function()? onSuccess,
    void Function(Object e)? onError,
  }) async {
    try {
      onStart?.call();
      await UserPrefs.setBibleVersionCode(newVersionCode);
      // Synchroniser vers UserPrefsHive
      await UserPrefsSync.syncFromPrefsToHive();
      final profile = await currentProfile();
      await PlanOrchestrator.generateAndCachePlan(
        profile: profile,
        bibleVersion: newVersionCode,
      );
      onSuccess?.call();
    } catch (e) {
      onError?.call(e);
    }
  }
}

