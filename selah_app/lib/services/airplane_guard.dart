import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:airplane_mode_checker/airplane_mode_checker.dart';
import 'package:app_settings/app_settings.dart';

class AirplaneGuard {
  static const _prefKeySkip = 'skip_airplane_guard';

  /// À appeler avant d'ouvrir le Reader.
  static Future<void> ensureFocusMode(
    BuildContext context, {
    required Future<void> Function() proceed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKeySkip) ?? false) {
      await proceed();
      return;
    }

    // iOS : on ne peut pas "forcer" mode avion ; on conseille DND/Focus.
    if (!Platform.isAndroid) {
      final ok = await _showPrompt(context, platform: 'ios');
      if (ok == true) await proceed();
      return;
    }

    // Android : on lit l'état puis on affiche si OFF.
    try {
      final status = await AirplaneModeChecker.instance.checkAirplaneMode();
      if (status == AirplaneModeStatus.on) {
        await proceed();
        return;
      }
    } catch (_) { /* on continue quand même vers le prompt */ }

    final ok = await _showPrompt(context, platform: 'android');
    if (ok == true) await proceed();
  }

  static Future<bool?> _showPrompt(BuildContext context, {required String platform}) async {
    bool dontRemind = false;
    bool airplaneOn = false;
    StreamSubscription<AirplaneModeStatus>? sub;

    Future<void> _openSettings() async {
      // Ouvre les paramètres généraux de l'appareil
      try {
        await AppSettings.openAppSettings();
      } catch (_) {
        // Fallback silencieux si l'ouverture échoue
      }
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            // ⤵️ S'abonner une seule fois au stream pour fermer auto dès ON
            sub ??= AirplaneModeChecker.instance.listenAirplaneMode().listen((st) async {
              if (st == AirplaneModeStatus.on) {
                setState(() => airplaneOn = true);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_prefKeySkip, dontRemind);
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(true);
              }
            });

            final isAndroid = platform == 'android';
            final title = isAndroid
              ? 'Entre dans la présence de Dieu'
              : 'Prépare ton cœur (Ne pas déranger)';
            final body = isAndroid
              ? "Tu t'apprêtes à écouter Dieu.\n\n"
                "⚠️ Pour ne pas être distrait, active le **mode avion**.\n"
                "Tu pourras le désactiver après ta lecture."
              : "Tu t'apprêtes à écouter Dieu.\n\n"
                "⚠️ Sur iPhone, active **Ne pas déranger / Focus** pour éviter les distractions.\n"
                "Tu pourras le désactiver après ta lecture.";

            return AlertDialog(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(body, style: const TextStyle(color: Colors.white70, height: 1.35)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: dontRemind,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (v) => setState(() => dontRemind = (v ?? false)),
                      ),
                      const Expanded(
                        child: Text("Ne plus me rappeler", style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  if (airplaneOn) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text('Mode avion activé ✔', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_prefKeySkip, dontRemind);
                    Navigator.of(ctx).pop(false); // continuer quand même
                  },
                  child: const Text('Continuer quand même', style: TextStyle(color: Colors.white70)),
                ),
                if (isAndroid) TextButton(
                  onPressed: () async {
                    await _openSettings(); // l'utilisateur active manuellement
                    // Le Stream fermera automatiquement la boîte quand Airplane ON
                  },
                  child: const Text('Ouvrir les paramètres', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    // iOS : "Je suis prêt" (DND activé côté utilisateur)
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_prefKeySkip, dontRemind);
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(isAndroid ? 'J\'ai activé le mode avion' : 'Je suis prêt'),
                ),
              ],
            );
          },
        );
      },
    );

    await sub?.cancel();
    return result;
  }
}
