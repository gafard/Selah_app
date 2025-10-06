import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';
import '../services/bible_download_service.dart';
import '../services/daily_scheduler.dart';
import '../services/user_prefs.dart';
import '../models/plan_profile.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  // Sélections
  String bibleVersion = 'LSG';
  int durationMin = 15;
  TimeOfDay reminder = const TimeOfDay(hour: 7, minute: 0);
  String goal = 'Discipline quotidienne';
  String level = 'Fidèle régulier';
  String meditation = 'Méditation biblique';
  bool autoReminder = true;
  bool downloading = false;
  double dlProgress = 0;

  final bibleVersions = const ['LSG', 'S21', 'BDS', 'PDV', 'TOB', 'NIV'];
  final goals = const [
    'Discipline quotidienne',
    'Approfondir la Parole',
    'Mieux prier',
    'Grandir dans la foi',
  ];
  final levels = const [
    'Nouveau converti',
    'Fidèle régulier',
    'Serviteur/leader',
  ];
  final meditations = const [
    'Méditation biblique',
    'Lectio Divina',
    'Contemplation',
    'Prière silencieuse',
  ];

  @override
  void initState() {
    super.initState();
    // Charger préférences (si besoin)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Dégradé Calm/Superlist + léger glow
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Micro-shapes
              Positioned.fill(child: _BackgroundMist()),
              // Contenu
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 12),
                    _sectionTitle('Version de la Bible'),
                    _GlassCard(
                      child: _DropdownTile(
                        icon: Icons.menu_book_rounded,
                        value: bibleVersion,
                        items: bibleVersions,
                        onChanged: (v) => setState(() => bibleVersion = v),
                      ),
                    ).animate().fadeIn().moveY(begin: 16, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 16),
                    _sectionTitle('Durée quotidienne'),
                    _GlassCard(
                      child: _DurationSlider(
                        value: durationMin,
                        onChanged: (v) => setState(() => durationMin = v),
                      ),
                    ).animate().fadeIn().moveY(begin: 16, end: 0),

                    const SizedBox(height: 16),
                    _sectionTitle('Rappel'),
                    _GlassCard(
                      child: Column(
                        children: [
                          _SwitchTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Activer le rappel',
                            value: autoReminder,
                            onChanged: (v) => setState(() => autoReminder = v),
                          ),
                          if (autoReminder) ...[
                            const SizedBox(height: 12),
                            _TimePickerTile(
                              icon: Icons.access_time,
                              timeOfDay: reminder,
                              onPick: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: reminder,
                                );
                                if (t != null) setState(() => reminder = t);
                              },
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn().moveY(begin: 16, end: 0),

                    const SizedBox(height: 16),
                    _sectionTitle('Objectif & Niveau'),
                    _GlassCard(
                      child: Column(
                        children: [
                          _DropdownTile(
                            icon: Icons.flag_outlined,
                            value: goal,
                            items: goals,
                            onChanged: (v) => setState(() => goal = v),
                          ),
                          const SizedBox(height: 12),
                          _DropdownTile(
                            icon: Icons.bolt_outlined,
                            value: level,
                            items: levels,
                            onChanged: (v) => setState(() => level = v),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().moveY(begin: 16, end: 0),

                    const SizedBox(height: 16),
                    _sectionTitle('Préférences'),
                    _GlassCard(
                      child: Column(
                        children: [
                          _DropdownTile(
                            icon: Icons.self_improvement_outlined,
                            value: meditation,
                            items: meditations,
                            onChanged: (v) => setState(() => meditation = v),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().moveY(begin: 16, end: 0),

                    const SizedBox(height: 24),
                    _primaryButton(
                      label: downloading ? 'Téléchargement…' : 'Continuer',
                      icon: downloading ? Icons.downloading : Icons.check,
                      onPressed: downloading ? null : _onContinue,
                    ),
                    if (downloading) ...[
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                const Icon(Icons.download, color: Colors.white70, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Téléchargement de $bibleVersion…',
                                    style: GoogleFonts.inter(color: Colors.white70),
                                  ),
                                ),
                                Text(
                                  '${(dlProgress * 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: dlProgress,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF49C98D)),
                              minHeight: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Personnalise ton parcours',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: GoogleFonts.inter(
        color: Colors.white.withOpacity(0.9),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _primaryButton({required String label, required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF49C98D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    // 1) Sauvegarde des préférences utilisateur
    await UserPrefs.saveProfile({
      'bibleVersion': bibleVersion,
      'durationMin': durationMin,
      'reminderHour': reminder.hour,
      'reminderMinute': reminder.minute,
      'autoReminder': autoReminder,
      'goal': goal,
      'level': level,
      'meditation': meditation,
      'daysOfWeek': [1, 2, 3, 4, 5, 6, 7], // Tous les jours par défaut
    });

    // 2) Sauvegarde de la version de la Bible
    await UserPrefs.setBibleVersionCode(bibleVersion);

    // 3) Téléchargement de la Bible en background avec progression
    setState(() => downloading = true);
    // TODO: Implémenter le téléchargement de la Bible
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    setState(() => downloading = false);

    // 4) Configuration des rappels quotidiens
    if (autoReminder) {
      await DailyScheduler.scheduleDaily(reminder);
      // Notification immédiate (feedback)
      await NotificationService.instance.showNow(
        title: 'Rappel configuré',
        body: 'Tu recevras un rappel chaque jour à ${_fmt(reminder)}.',
      );
    } else {
      await DailyScheduler.cancel();
    }

    if (mounted) Navigator.pushReplacementNamed(context, '/goals');
  }

  PlanProfile _createPlanProfile() {
    // Convertir les choix de l'utilisateur en PlanProfile
    Level userLevel;
    switch (level) {
      case 'Nouveau converti':
        userLevel = Level.newBeliever;
        break;
      case 'Serviteur/leader':
        userLevel = Level.leader;
        break;
      default:
        userLevel = Level.regular;
    }

    Set<Goal> userGoals = {};
    switch (goal) {
      case 'Discipline quotidienne':
        userGoals.add(Goal.discipline);
        break;
      case 'Approfondir la Parole':
        userGoals.add(Goal.deepenWord);
        break;
      case 'Mieux prier':
        userGoals.add(Goal.prayer);
        break;
      case 'Grandir dans la foi':
        userGoals.add(Goal.faithGrowth);
        break;
    }

    // Déterminer la durée du plan selon le niveau et la durée quotidienne
    int totalDays;
    if (userLevel == Level.newBeliever) {
      totalDays = durationMin <= 15 ? 30 : 90;
    } else if (userLevel == Level.leader) {
      totalDays = durationMin >= 20 ? 90 : 30;
    } else {
      totalDays = durationMin >= 20 ? 90 : 30;
    }

    return PlanProfile(
      level: userLevel,
      goals: userGoals,
      minutesPerDay: durationMin,
      totalDays: totalDays,
      startDate: DateTime.now(),
    );
  }

  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

// ============= UI helpers (Calm/Superlist vibe) =============

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF2D1B69),
              items: items.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.inter(color: Colors.white)),
              )).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: const Color(0xFFC6F830),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$value min',
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
            ),
            Text('$value min', style: GoogleFonts.inter(color: Colors.white)),
          ],
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: GoogleFonts.inter(color: Colors.white))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFFC6F830),
        )
      ],
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.icon,
    required this.timeOfDay,
    required this.onPick,
  });

  final IconData icon;
  final TimeOfDay timeOfDay;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onPick,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Text('Heure du rappel', style: GoogleFonts.inter(color: Colors.white70)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(fmt(timeOfDay), style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BackgroundMist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MistPainter(),
      ),
    );
  }
}

class _MistPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    paint.color = const Color(0xFF1553FF).withOpacity(0.18);
    canvas.drawCircle(Offset(size.width * .2, size.height * .25), 80, paint);
    paint.color = const Color(0xFF49C98D).withOpacity(0.16);
    canvas.drawCircle(Offset(size.width * .8, size.height * .35), 100, paint);
    paint.color = const Color(0xFFC6F830).withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * .6, size.height * .75), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}