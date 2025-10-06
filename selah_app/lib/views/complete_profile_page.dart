import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../services/daily_scheduler.dart';
import '../services/user_prefs.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  // Sélections
  String bibleVersion = 'Louis Segond (LSG)';
  int durationMin = 15;
  TimeOfDay reminder = const TimeOfDay(hour: 7, minute: 0);
  String goal = 'Discipline quotidienne';
  String level = 'Fidèle régulier';
  String meditation = 'Méditation biblique';
  bool autoReminder = true;
  bool downloading = false;
  double dlProgress = 0;

  final bibleVersions = const [
    'Louis Segond (LSG)',
    'Segond 21 (S21)', 
    'Bible du Semeur (BDS)',
    'Parole de Vie (PDV)',
    'Traduction Œcuménique de la Bible (TOB)',
    'New International Version (NIV)'
  ];
  final goals = const [
    'Discipline quotidienne',
    'Discipline de prière',
    'Approfondir la Parole',
    'Grandir dans la foi',
    'Développer mon caractère',
    'Trouver de l\'encouragement',
    'Expérimenter la guérison',
    'Partager ma foi',
    'Mieux prier',
  ];
  final levels = const [
    'Nouveau converti',
    'Rétrogarde',
    'Fidèle pas si régulier',
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1D29), Color(0xFF112244)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Contenu scrollable
              Expanded(
                child: Stack(
                  children: [
                    // Ornements légers
                    Positioned(
                      right: -60,
                      top: -40,
                      child: _softBlob(180),
                    ),
                    Positioned(
                      left: -40,
                      bottom: -50,
                      child: _softBlob(220),
                    ),

                    // Contenu centré avec scroll
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 480),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  // Header
                                  _buildHeader(),
                                  const SizedBox(height: 20),

                                  // Formulaire de configuration
                                  _buildConfigurationForm(),
                                  const SizedBox(height: 100), // Espace pour le bouton
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Bouton principal (fixé en bas de l'écran)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF1A1D29).withOpacity(0.9),
              const Color(0xFF1A1D29),
            ],
          ),
        ),
        child: _buildContinueButton(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'PERSONNALISE TON PARCOURS',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
              color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure tes préférences pour une expérience sur mesure',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConfigurationForm() {
    return Column(
      children: [
        // Version de la Bible
        _buildField(
          label: 'Version de la Bible',
          icon: Icons.menu_book_rounded,
          child: _buildDropdown(
            value: bibleVersion,
            items: bibleVersions,
            onChanged: (v) => setState(() => bibleVersion = v),
          ),
        ),

        const SizedBox(height: 16),

        // Durée quotidienne
        _buildField(
          label: 'Durée quotidienne ($durationMin min)',
          icon: Icons.timer_outlined,
          child: _buildDurationSlider(),
        ),

        const SizedBox(height: 16),

        // Rappels quotidiens
        _buildField(
          label: 'Rappels quotidiens',
          icon: Icons.notifications_active_outlined,
          child: _buildSwitchTile(),
        ),

        if (autoReminder) ...[
          const SizedBox(height: 16),
          _buildField(
            label: 'Heure du rappel',
            icon: Icons.access_time,
            child: _buildTimePicker(),
          ),
        ],

        const SizedBox(height: 16),

        // Objectif principal
        _buildField(
          label: 'Ton objectif principal',
          icon: Icons.flag_outlined,
          child: _buildDropdown(
            value: goal,
            items: goals,
            onChanged: (v) => setState(() => goal = v),
          ),
        ),

        const SizedBox(height: 16),

        // Niveau spirituel
        _buildField(
          label: 'Ton niveau spirituel',
          icon: Icons.trending_up_rounded,
          child: _buildDropdown(
            value: level,
            items: levels,
            onChanged: (v) => setState(() => level = v),
          ),
        ),

        const SizedBox(height: 16),

        // Méthode de méditation
        _buildField(
          label: 'Méthode de méditation',
          icon: Icons.spa_outlined,
          child: _buildDropdown(
            value: meditation,
            items: meditations,
            onChanged: (v) => setState(() => meditation = v),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 52, // Hauteur légèrement réduite
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), // Padding réduit
          child: DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF2D1B69),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13), // Taille réduite
            isExpanded: true, // Permet au dropdown de prendre toute la largeur
            items: items.map((e) => DropdownMenuItem(
              value: e,
              child: Text(
                e, 
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13), // Taille réduite
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSlider() {
    return Container(
      height: 52, // Hauteur légèrement réduite
      padding: const EdgeInsets.symmetric(horizontal: 12), // Padding réduit
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Center(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: const Color(0xFF1553FF),
            overlayColor: const Color(0xFF1553FF).withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: durationMin.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            label: '$durationMin min',
            onChanged: (v) => setState(() => durationMin = v.round()),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile() {
    return Container(
      height: 52, // Hauteur légèrement réduite
      padding: const EdgeInsets.symmetric(horizontal: 12), // Padding réduit
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Recevoir des rappels quotidiens',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: autoReminder,
              onChanged: (v) => setState(() => autoReminder = v),
              activeColor: const Color(0xFF1553FF),
              activeTrackColor: const Color(0xFF1553FF).withOpacity(0.3),
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      height: 52, // Hauteur légèrement réduite
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: InkWell(
        onTap: () async {
          final t = await showTimePicker(
            context: context,
            initialTime: reminder,
          );
          if (t != null) setState(() => reminder = t);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), // Padding réduit
          child: Center(
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Heure du rappel',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fmt(reminder),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1553FF),
              Color(0xFF0D47A1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1553FF).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: downloading ? null : _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: downloading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Téléchargement…',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Continuer',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _softBlob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.20), Colors.transparent],
        ),
      ),
    );
  }


  Future<void> _onContinue() async {
    // Extraire le code de la version de la Bible (ex: "LSG" de "Louis Segond (LSG)")
    final bibleVersionCode = bibleVersion.contains('(') 
        ? bibleVersion.substring(bibleVersion.lastIndexOf('(') + 1, bibleVersion.lastIndexOf(')'))
        : bibleVersion;

    // 1) Sauvegarde des préférences utilisateur
    await UserPrefs.saveProfile({
      'bibleVersion': bibleVersionCode,
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
    await UserPrefs.setBibleVersionCode(bibleVersionCode);

    // 3) Téléchargement de la Bible en background avec progression
    setState(() => downloading = true);
    // TODO: Implémenter le téléchargement de la Bible
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    setState(() => downloading = false);

    // 4) Configuration des rappels quotidiens
    if (autoReminder) {
      try {
        await DailyScheduler.scheduleDaily(reminder);
        // Notification immédiate (feedback)
        await NotificationService.instance.showNow(
          title: 'Rappel configuré',
          body: 'Tu recevras un rappel chaque jour à ${_fmt(reminder)}.',
        );
      } catch (e) {
        print('Erreur lors de la configuration du rappel: $e');
        // Continuer même si les rappels ne fonctionnent pas
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Les rappels ne sont pas disponibles sur cet appareil'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      try {
        await DailyScheduler.cancel();
      } catch (e) {
        print('Erreur lors de l\'annulation du rappel: $e');
      }
    }

    if (mounted) Navigator.pushReplacementNamed(context, '/goals');
  }


  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

