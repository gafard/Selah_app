import 'package:flutter/material.dart';
import '../services/user_prefs_hive.dart';
import '../services/telemetry_console.dart';
import '../services/daily_alarm.dart';
import '../domain/user_prefs.dart';
import '../bootstrap.dart' as bootstrap;

class OnboardingActions {
  static bool _busy = false;

  static Future<void> complete(BuildContext context) async {
    if (_busy) return;
    _busy = true;

    try {
      // Utiliser bootstrap au lieu des providers
      final prefs = bootstrap.userPrefs;
      final telemetry = bootstrap.telemetry;

      // 1) Charger profil pour les infos utiles (heure, version…)
      final profileData = prefs.profile;
      final profile = UserProfile.fromJson(profileData);

      // 2) Marquer hasOnboarded = true (déjà fait dans _finishOnboarding)
      // await prefs.setHasOnboarded(true);

      // 3) Programmer l'alarme quotidienne (si tu veux la placer ici)
      final hhmm = (profile.preferredTime?.isNotEmpty == true) ? profile.preferredTime! : '07:00';
      await DailyAlarm.scheduleDaily(hhmm);

      // 4) Lancer en tâche de fond le téléchargement de la version choisie
      final version = (profile.bibleVersion?.isNotEmpty == true) ? profile.bibleVersion! : 'LSG';
      // await BackgroundTasks.queueBible(version);

      // 5) Event analytics
      telemetry.event('onboarding_completed', {
        'preferred_time': hhmm,
        'bible_version': version,
        'daily_minutes': profile.dailyMinutes,
      });
           } catch (e) {
             // Option: feedback doux (pas bloquant)
             debugPrint('Onboarding complete failed: $e');
             // Supprimé le SnackBar qui causait le message jaune
           } finally {
      _busy = false;
    }
  }
}
