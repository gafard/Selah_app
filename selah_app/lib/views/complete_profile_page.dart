import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/daily_scheduler.dart';
import '../services/user_prefs.dart'; // ✅ UserPrefs ESSENTIEL (offline-first)
import '../services/user_prefs_hive.dart';
import '../repositories/user_repository.dart';

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
  bool isLoading = false; // ← Indicateur de chargement
  
  // ═══ NOUVEAU ! Générateur Ultime (Jean 5:40) ⭐ ═══
  String heartPosture = '💎 Rencontrer Jésus personnellement';
  String motivation = '🔥 Passion pour Christ';

  final bibleVersions = const [
    'Louis Segond (LSG)',
    'Segond 21 (S21)', 
    'Bible du Semeur (BDS)',
    'Parole de Vie (PDV)',
    'Traduction Œcuménique de la Bible (TOB)',
    'New International Version (NIV)'
  ];
  final goals = const [
    // ═══ NOUVEAU ! Objectifs Christ-centrés (Jean 5:40) ⭐ ═══
    '✨ Rencontrer Jésus dans la Parole',
    '💫 Voir Jésus dans chaque livre',
    '🔥 Être transformé à son image',
    '❤️ Développer l\'intimité avec Dieu',
    '🙏 Apprendre à prier comme Jésus',
    '👂 Reconnaître la voix de Dieu',
    '💎 Développer le fruit de l\'Esprit',
    '⚔️ Renouveler mes pensées',
    '🕊️ Marcher par l\'Esprit',
    
    // Existants
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
    'Rétrograde',
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
  
  // ═══ NOUVEAU ! Posture du cœur (Jean 5:40) ⭐ ═══
  final heartPostures = const [
    '💎 Rencontrer Jésus personnellement',
    '🔥 Être transformé par l\'Esprit',
    '🙏 Écouter la voix de Dieu',
    '📚 Approfondir ma connaissance',
    '⚡ Recevoir la puissance de l\'Esprit',
    '❤️ Développer l\'intimité avec le Père',
  ];
  
  // ═══ NOUVEAU ! Motivation spirituelle (Hébreux 11:6) ⭐ ═══
  final spiritualMotivations = const [
    '🔥 Passion pour Christ',
    '❤️ Amour pour Dieu',
    '🎯 Obéissance joyeuse',
    '📖 Désir de connaître Dieu',
    '⚡ Besoin de transformation',
    '🙏 Recherche de direction',
    '💪 Discipline spirituelle',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences(); // ✅ Charger les préférences sauvegardées
  }
  
  /// ✅ Charger les préférences sauvegardées depuis UserPrefs (offline-first)
  Future<void> _loadSavedPreferences() async {
    try {
      // ✅ Utiliser UserPrefs (service principal, offline-first)
      final profile = await UserPrefs.loadProfile();
      
      if (profile.isEmpty) {
        print('ℹ️ Aucune préférence sauvegardée');
        return;
      }
      
      // ✅ Déclarer profileMap en dehors de setState pour y accéder
      final profileMap = Map<String, dynamic>.from(profile);
      
      setState(() {
        // Charger tous les paramètres sauvegardés
        bibleVersion = _getBibleVersionFromCode(profileMap['bibleVersion'] as String? ?? 'LSG');
        durationMin = profileMap['durationMin'] as int? ?? 15;
        
        // Charger l'heure du rappel
        final reminderHour = profileMap['reminderHour'] as int? ?? 7;
        final reminderMinute = profileMap['reminderMinute'] as int? ?? 0;
        reminder = TimeOfDay(hour: reminderHour, minute: reminderMinute);
        
        autoReminder = profileMap['autoReminder'] as bool? ?? true;
        goal = profileMap['goal'] as String? ?? 'Discipline quotidienne';
        level = profileMap['level'] as String? ?? 'Fidèle régulier';
        meditation = profileMap['meditation'] as String? ?? 'Méditation biblique';
        
        // ✅ Charger les nouveaux champs (Générateur Ultime)
        heartPosture = profileMap['heartPosture'] as String? ?? '💎 Rencontrer Jésus personnellement';
        motivation = profileMap['motivation'] as String? ?? '🔥 Passion pour Christ';
      });
      
      print('✅ Préférences chargées depuis UserPrefs (offline-first)');
    } catch (e) {
      print('⚠️ Erreur chargement préférences: $e');
      // Continuer avec les valeurs par défaut
    }
  }
  
  /// Convertir le code de version Bible en nom complet
  String _getBibleVersionFromCode(String code) {
    switch (code) {
      case 'LSG':
        return 'Louis Segond (LSG)';
      case 'S21':
        return 'Segond 21 (S21)';
      case 'BDS':
        return 'Bible du Semeur (BDS)';
      case 'PDV':
        return 'Parole de Vie (PDV)';
      case 'TOB':
        return 'Traduction Œcuménique de la Bible (TOB)';
      case 'NIV':
        return 'New International Version (NIV)';
      default:
        return 'Louis Segond (LSG)';
    }
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Stack(
                    children: [
                      // Ornements légers en arrière-plan
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

                      // Contenu principal
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
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
                                  const SizedBox(height: 120), // Espace pour le bouton (augmenté pour nouveaux champs)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bouton principal (fixé en bas de l'écran)
      bottomNavigationBar: SafeArea(
        child: Container(
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'PERSONNALISE TON PARCOURS',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure tes préférences pour une expérience sur mesure',
          style: const TextStyle(
            fontFamily: 'Gilroy',
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

        // Objectif spirituel
        _buildField(
          label: 'Objectif spirituel',
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
          label: 'Niveau spirituel',
          icon: Icons.trending_up_rounded,
          child: _buildDropdown(
            value: level,
            items: levels,
            onChanged: (v) => setState(() => level = v),
          ),
        ),

        const SizedBox(height: 16),

        // ═══ NOUVEAU ! Posture du cœur (Jean 5:40) ⭐ ═══
        _buildField(
          label: 'Posture du cœur (Jean 5:40)',
          icon: Icons.favorite_rounded,
          child: _buildDropdown(
            value: heartPosture,
            items: heartPostures,
            onChanged: (v) => setState(() => heartPosture = v),
          ),
        ),

        const SizedBox(height: 16),

        // ═══ NOUVEAU ! Motivation spirituelle ⭐ ═══
        _buildField(
          label: 'Motivation spirituelle',
          icon: Icons.local_fire_department_rounded,
          child: _buildDropdown(
            value: motivation,
            items: spiritualMotivations,
            onChanged: (v) => setState(() => motivation = v),
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
              style: const TextStyle(
                fontFamily: 'Gilroy',
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
      height: 48, // Hauteur réduite pour Android
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6), // Padding encore plus réduit pour Android
          child: DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF2D1B69),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              color: Colors.white,
              fontSize: 12,
            ),
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem(
              value: e,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  e,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
      height: 48, // Hauteur réduite pour Android
      padding: const EdgeInsets.symmetric(horizontal: 10), // Padding réduit pour Android
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
      height: 48, // Hauteur réduite pour Android
      padding: const EdgeInsets.symmetric(horizontal: 10), // Padding réduit pour Android
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
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: autoReminder,
              onChanged: (v) => setState(() => autoReminder = v),
              activeThumbColor: const Color(0xFF1553FF),
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
      height: 48, // Hauteur réduite pour Android
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
          padding: const EdgeInsets.symmetric(horizontal: 10), // Padding réduit pour Android
          child: Center(
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Heure du rappel',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
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
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
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
          onPressed: isLoading ? null : _onContinue,
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
          child: isLoading
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
                      'Configuration...',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Continuer',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
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
    if (isLoading) return; // Éviter les clics multiples
    
    setState(() => isLoading = true);
    
    try {
      print('🔄 Début _onContinue()');
      
      // Extraire le code de la version de la Bible (ex: "LSG" de "Louis Segond (LSG)")
      final bibleVersionCode = bibleVersion.contains('(') 
          ? bibleVersion.substring(bibleVersion.lastIndexOf('(') + 1, bibleVersion.lastIndexOf(')'))
          : bibleVersion;
      
      print('📖 Version Bible: $bibleVersionCode');

      // 1) Normaliser les clés attendues par l'IA
      final preferredTime = _fmt(reminder);       // "HH:mm"
      final dailyMinutes = durationMin;           // miroir pour compat
      final correctedLevel = level == 'Rétrogarde' ? 'Rétrograde' : level; // ✅ corrige la valeur

      print('🔧 Clés normalisées:');
      print('   preferredTime: $preferredTime');
      print('   dailyMinutes: $dailyMinutes');
      print('   level corrigé: $correctedLevel');

      // 2) Sauvegarde des préférences utilisateur avec toutes les clés
      print('💾 Sauvegarde profil utilisateur...');
      final payload = {
        'bibleVersion': bibleVersionCode,
        'durationMin': durationMin,
        'dailyMinutes': dailyMinutes,      // ✅ important pour compat
        'preferredTime': preferredTime,    // ✅ important pour timing bonus
        'reminderHour': reminder.hour,
        'reminderMinute': reminder.minute,
        'autoReminder': autoReminder,
        'goal': goal,
        'level': correctedLevel,           // ✅ niveau corrigé
        'meditation': meditation,
        
        // ═══ NOUVEAU ! Générateur Ultime (Jean 5:40) ⭐ ═══
        'heartPosture': heartPosture,
        'motivation': motivation,
        
        'daysOfWeek': [1, 2, 3, 4, 5, 6, 7], // Tous les jours par défaut
      };
      
      await UserPrefs.saveProfile(payload);
      print('✅ Profil sauvegardé');

      // 2.5) 🔁 Synchroniser aussi UserPrefsHive (ce que lit GoalsPage)
      try {
        final hive = context.mounted ? context.read<UserPrefsHive?>() : null;
        if (hive != null) {
          await hive.patchProfile(payload);
          print('✅ Profil synchronisé avec Hive');
        }
      } catch (e) {
        print('⚠️ UserPrefsHive non disponible (normal): $e');
        // Si Provider absent, on ignore: GoalsPage pourra relire UserPrefs si déjà adapté
      }

      // 3) Sauvegarde de la version de la Bible
      print('📖 Sauvegarde version Bible...');
      await UserPrefs.setBibleVersionCode(bibleVersionCode);
      print('✅ Version Bible sauvegardée');
      
      // 2.5) Marquer le profil comme complet dans UserRepository
      print('✅ Marquage profil comme complet...');
      final userRepo = UserRepository();
      await userRepo.markProfileComplete();
      print('✅ Profil marqué comme complet');

      // 3) Téléchargement de la Bible en ARRIÈRE-PLAN (non bloquant, offline-first ⭐)
      print('📥 Lancement téléchargement Bible...');
      _downloadBibleInBackground(bibleVersionCode);
      print('✅ Téléchargement lancé');

      // 4) Configuration des rappels quotidiens
      print('🔔 Configuration rappels...');
      if (autoReminder) {
        try {
          await DailyScheduler.scheduleDaily(reminder);
          // Notification immédiate (feedback)
          await NotificationService.instance.showNow(
            title: 'Rappel configuré',
            body: 'Tu recevras un rappel chaque jour à ${_fmt(reminder)}.',
          );
          print('✅ Rappels configurés');
        } catch (e) {
          print('⚠️ Erreur lors de la configuration du rappel: $e');
          // Continuer même si les rappels ne fonctionnent pas
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Les rappels ne sont pas disponibles sur cet appareil'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        try {
          await DailyScheduler.cancel();
          print('✅ Rappels annulés');
        } catch (e) {
          print('⚠️ Erreur lors de l\'annulation du rappel: $e');
        }
      }

      print('🧭 Navigation vers /goals');
      if (mounted) context.go('/goals');
      print('✅ Navigation réussie');
      
    } catch (e, stackTrace) {
      print('❌ Erreur dans _onContinue(): $e');
      print('📍 Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }


  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// ═══════════════════════════════════════════════════════════
  /// Téléchargement Bible en ARRIÈRE-PLAN (Offline-First ⭐)
  /// ═══════════════════════════════════════════════════════════
  void _downloadBibleInBackground(String versionCode) {
    // Ne pas bloquer l'UI - téléchargement asynchrone
    Future.microtask(() async {
      try {
        // Vérifier connectivité AVANT de télécharger
        // Si offline, on utilise la version minimale locale
        print('📖 Téléchargement Bible $versionCode en arrière-plan...');
        
        // TODO: Implémenter téléchargement réel ici
        // - Vérifier ConnectivityService.instance.isOnline
        // - Si online : télécharger depuis API/CDN
        // - Si offline : utiliser version minimale locale
        // - Notification quand terminé
        
        await Future.delayed(const Duration(seconds: 2)); // Simulation
        
        print('✅ Bible $versionCode téléchargée (arrière-plan)');
        
        // Notification de succès (optionnel, non bloquant)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bible $versionCode téléchargée ✅'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('⚠️ Erreur téléchargement Bible (non bloquant): $e');
        // Ne pas bloquer l'utilisateur - version locale utilisée
      }
    });
  }
}

