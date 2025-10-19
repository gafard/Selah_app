import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:airplane_mode_checker/airplane_mode_checker.dart';

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
                "⚠️ Pour ne pas être distrait, active le **mode avion** :\n"
                "• Paramètres → Réseau et Internet → Mode avion\n"
                "• Ou glisse depuis le haut et appuie sur l'icône avion"
              : "Tu t'apprêtes à écouter Dieu.\n\n"
                "⚠️ Sur iPhone, active **Ne pas déranger / Focus** :\n"
                "• Réglages → Focus → Ne pas déranger\n"
                "• Ou glisse depuis le coin supérieur droit";

            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icône avec animation
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            isAndroid ? Icons.flight_takeoff_rounded : Icons.notifications_off_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Titre avec style Selah
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Corps du message
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Checkbox avec style Selah
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: dontRemind,
                                activeColor: const Color(0xFF10B981),
                                checkColor: Colors.white,
                                onChanged: (v) => setState(() => dontRemind = (v ?? false)),
                              ),
                              Expanded(
                                child: Text(
                                  "Ne plus me rappeler",
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (airplaneOn) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981).withOpacity(0.2),
                                  const Color(0xFF10B981).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Mode avion activé ✔',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        
                        // Boutons d'action avec style Selah (taille réduite)
                        Column(
                          children: [
                            // Bouton "Continuer quand même" (ghost)
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool(_prefKeySkip, dontRemind);
                                  Navigator.of(ctx).pop(false);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Continuer quand même',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Bouton principal
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool(_prefKeySkip, dontRemind);
                                  Navigator.of(ctx).pop(true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isAndroid ? 'J\'ai activé le mode avion' : 'Je suis prêt',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await sub?.cancel();
    return result;
  }
}
