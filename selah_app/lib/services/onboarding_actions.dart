import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/user_prefs.dart';
import '../domain/telemetry.dart';
import '../services/daily_alarm.dart';
import '../services/background_tasks.dart';

class OnboardingActions {
  static bool _busy = false;

  static Future<void> complete(BuildContext context) async {
    if (_busy) return;
    _busy = true;

    final prefs = context.read<UserPrefs>();
    final telemetry = context.read<Telemetry>();

    try {
      // 1) Charger profil pour les infos utiles (heure, version…)
      final profile = await prefs.get();

      // 2) Marquer hasOnboarded = true
      await prefs.setHasOnboarded(true);

      // 3) Programmer l'alarme quotidienne (si tu veux la placer ici)
      final hhmm = (profile.preferredTime?.isNotEmpty == true) ? profile.preferredTime! : '07:00';
      await DailyAlarm.scheduleDaily(hhmm);

      // 4) Lancer en tâche de fond le téléchargement de la version choisie
      final version = (profile.bibleVersion?.isNotEmpty == true) ? profile.bibleVersion! : 'LSG';
      // await BackgroundTasks.queueBible(version);

      // 5) Event analytics
      telemetry.track('onboarding_completed', {
        'preferred_time': hhmm,
        'bible_version': version,
        'daily_minutes': profile.dailyMinutes,
      });
    } catch (e) {
      // Option: feedback doux (pas bloquant)
      debugPrint('Onboarding complete failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration terminée (mode dégradé).'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }
}
