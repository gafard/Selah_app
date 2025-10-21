import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';
import '../services/daily_scheduler.dart';
import '../services/cross_platform_alarm_service.dart';
import '../services/user_prefs_sync.dart'; // ✅ UserPrefs ESSENTIEL (offline-first)
import '../services/version_change_notifier.dart';
import '../bootstrap.dart' as bootstrap;
import '../services/intelligent_duration_calculator.dart'; // 🧠 IntelligentDurationCalculator
import '../repositories/user_repository.dart';
import '../widgets/bible_version_selector.dart';
import '../services/bible_version_manager.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  // Sélections
  String? selectedBibleVersion;
  int durationMin = 15;
  TimeOfDay reminder = const TimeOfDay(hour: 7, minute: 0);
  String goal = 'Rencontrer Jésus dans la Parole';
  String level = 'Fidèle régulier';
  String meditation = 'Méditation profonde : Temps de réflexion entre les versets';
  bool autoReminder = true;
  bool isLoading = false; // ← Indicateur de chargement
  
  // ═══ Générateur Ultime (Jean 5:40) ═══
  String heartPosture = 'Écouter la voix de Dieu';
  String motivation = 'Recherche de direction';
  

  final goals = const [
    // ═══ Objectifs Christ-centrés (Jean 5:40) ═══
    'Rencontrer Jésus dans la Parole',
    'Voir Jésus dans chaque livre',
    'Être transformé à son image',
    'Développer l\'intimité avec Dieu',
    'Apprendre à prier comme Jésus',
    'Reconnaître la voix de Dieu',
    'Développer le fruit de l\'Esprit',
    'Renouveler mes pensées',
    'Marcher par l\'Esprit',
    
    // Existants
    'Discipline quotidienne',
    'Discipline de prière',
    'Approfondir la Parole',
    'Grandir dans la foi',
    'Développer mon caractère',
    'Trouver de l\'encouragement',
    'Expérimenter la guérison',
    'Partager ma foi',
    'Témoigner avec audace',
    'Évangéliser en ligne',
    'Mieux prier',
    'Sagesse',
  ];
  
  final levels = const [
    'Nouveau converti',
    'Rétrograde',
    'Fidèle pas si régulier',
    'Fidèle régulier',
    'Serviteur/leader',
  ];
  
  final meditations = const [
    'Méditation profonde : Temps de réflexion entre les versets',
    'Prière : Pauses pour prier',
    'Application : Temps pour réfléchir à l\'application',
    'Mémorisation : Répétition des versets clés',
  ];
  
  // ═══ Posture du cœur (Jean 5:40) ═══
  final heartPostures = const [
    'Rencontrer Jésus personnellement',
    'Être transformé par l\'Esprit',
    'Écouter la voix de Dieu',
    'Approfondir ma connaissance',
    'Recevoir la puissance de l\'Esprit',
    'Développer l\'intimité avec le Père',
  ];
  
  // ═══ Motivation spirituelle (Hébreux 11:6) ═══
  final spiritualMotivations = const [
    'Passion pour Christ',
    'Amour pour Dieu',
    'Obéissance joyeuse',
    'Désir de connaître Dieu',
    'Besoin de transformation',
    'Recherche de direction',
    'Discipline spirituelle',
  ];


  @override
  void initState() {
    super.initState();
    _loadSavedPreferences(); // ✅ Charger les préférences sauvegardées
    _calculateDurationRecommendations(); // 🧠 Calculer les recommandations
  }
  
  /// 🧠 Calcule les recommandations de durée pour différents objectifs
  Future<void> _calculateDurationRecommendations() async {
    // Calcul silencieux en arrière-plan pour les systèmes intelligents
    try {
      for (final goalOption in goals) {
        IntelligentDurationCalculator.calculateOptimalDuration(
          goal: goalOption,
          level: level,
          dailyMinutes: durationMin,
          meditationType: meditation,
        );
      }
      print('🧠 Recommandations calculées en arrière-plan');
    } catch (e) {
      print('❌ Erreur calcul recommandations: $e');
    }
  }
  
  /// ✅ Charger les préférences sauvegardées depuis UserPrefsHive (système unifié)
  Future<void> _loadSavedPreferences() async {
    try {
      // ✅ Synchroniser d'abord les deux systèmes
      await UserPrefsSync.syncBidirectional();
      
      // ✅ Utiliser UserPrefsHive comme source principale (comme profile_settings_page)
      final prefs = bootstrap.userPrefs;
      final profile = prefs.profile;
      
      if (profile.isEmpty) {
        print('ℹ️ Aucune préférence sauvegardée');
        return;
      }
      
      setState(() {
        // Charger tous les paramètres sauvegardés depuis UserPrefsHive
        selectedBibleVersion = profile['bibleVersion'] as String? ?? 'lsg1910';
        durationMin = profile['durationMin'] as int? ?? 15;
        
        // Charger l'heure du rappel
        final reminderHour = profile['reminderHour'] as int? ?? 7;
        final reminderMinute = profile['reminderMinute'] as int? ?? 0;
        reminder = TimeOfDay(hour: reminderHour, minute: reminderMinute);
        
        autoReminder = profile['autoReminder'] as bool? ?? true;
        goal = profile['goal'] as String? ?? 'Rencontrer Jésus dans la Parole';
        final rawLevel = profile['level'] as String? ?? 'Fidèle régulier';
        // ✅ Corriger l'incohérence "Rétrogarde" vs "Rétrograde"
        level = rawLevel == 'Rétrogarde' ? 'Rétrograde' : rawLevel;
        // ✅ Corriger les anciennes valeurs de méditation vers les nouvelles
        final rawMeditation = profile['meditation'] as String? ?? 'Méditation profonde : Temps de réflexion entre les versets';
        meditation = _normalizeMeditationType(rawMeditation);
        
        // ✅ Charger les nouveaux champs (Générateur Ultime)
        heartPosture = profile['heartPosture'] as String? ?? 'Écouter la voix de Dieu';
        motivation = profile['motivation'] as String? ?? 'Recherche de direction';
      });
      
      print('✅ Préférences chargées depuis UserPrefsHive (système unifié)');
    } catch (e) {
      print('⚠️ Erreur chargement préférences: $e');
      // Continuer avec les valeurs par défaut
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  // Header
                                  _buildHeader(),
                                  const SizedBox(height: 20),

                                  // Formulaire de configuration
                                  _buildConfigurationForm(),
                                  const SizedBox(height: 100), // ✅ Espace pour le bouton fixé
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
      bottomNavigationBar: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: _buildContinueButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'PERSONNALISE TON PARCOURS',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Configure tes préférences pour une expérience sur mesure',
          style: TextStyle(
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
          child: BibleVersionSelector(
            selectedVersion: selectedBibleVersion,
            onVersionChanged: (version) {
              setState(() {
                selectedBibleVersion = version;
              });
            },
            label: 'Version de la Bible',
            showLabel: false,
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
        
        // 🧠 Section de recommandations intelligentes
        _buildIntelligenceRecommendations(),
        
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
            onChanged: (v) {
              setState(() => goal = v);
              // 🧠 Recalculer les recommandations quand l'objectif change
              _calculateDurationRecommendations();
            },
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

        // ═══ NOUVEAU ! Posture du cœur (Jean 5:40) ═══
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

        // ═══ NOUVEAU ! Motivation spirituelle ═══
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
            onChanged: (v) {
              setState(() => durationMin = v.round());
              // 🧠 Recalculer les recommandations quand la durée change
              _calculateDurationRecommendations();
            },
          ),
        ),
      ),
    );
  }
  
  // Les systèmes intelligents travaillent en arrière-plan sans interface visible
  Widget _buildIntelligenceRecommendations() {
    return SizedBox.shrink(); // Pas d'interface visible
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
            const Expanded(
              child: Text(
                'Recevoir des rappels quotidiens',
                style: TextStyle(
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
                const Expanded(
                  child: Text(
                    'Heure du rappel',
                    style: TextStyle(
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
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Configuration...',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Continuer',
                  style: TextStyle(
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
      
      // Utiliser la version sélectionnée
      final bibleVersionCode = selectedBibleVersion ?? 'lsg1910';
      
      print('📖 Version Bible: $bibleVersionCode');

      // 1) Normaliser les clés attendues par le système spirituel
      final preferredTime = _fmt(reminder);       // "HH:mm"
      final dailyMinutes = durationMin;           // miroir pour compat
      final correctedLevel = level == 'Rétrogarde' ? 'Rétrograde' : level; // ✅ corrige la valeur

      print('🔧 Clés normalisées:');
      print('   preferredTime: $preferredTime');
      print('   dailyMinutes: $dailyMinutes');
      print('   level corrigé: $correctedLevel');

      // 2) Sauvegarde des préférences utilisateur avec toutes les clés (système unifié)
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
        
        // ═══ NOUVEAU ! Générateur Ultime (Jean 5:40) ═══
        'heartPosture': heartPosture,
        'motivation': motivation,
        
        'daysOfWeek': [1, 2, 3, 4, 5, 6, 7], // Tous les jours par défaut
      };
      
      // ✅ Utiliser le même système que profile_settings_page.dart
      final prefs = bootstrap.userPrefs;
      await prefs.patchProfile(payload);
      print('✅ Profil sauvegardé dans UserPrefsHive');

      // ✅ Synchroniser vers UserPrefs pour compatibilité
      await UserPrefsSync.syncFromHiveToPrefs();
      print('✅ Synchronisation vers UserPrefs terminée');
      
      // ✅ Notifier le changement de version (comme profile_settings_page)
      VersionChangeNotifier.notifyVersionChange(bibleVersionCode);
      print('✅ Changement de version notifié');
      
      // 2.5) Marquer le profil comme complet dans UserRepository
      print('✅ Marquage profil comme complet...');
      final userRepo = UserRepository();
      await userRepo.markProfileComplete();
      print('✅ Profil marqué comme complet');

      // 3) Téléchargement de la Bible en ARRIÈRE-PLAN (non bloquant, offline-first ⭐)
      print('📥 Lancement téléchargement Bible...');
      _downloadBibleInBackground(bibleVersionCode);
      print('✅ Téléchargement lancé');

      // 4) Configuration des rappels quotidiens avec alarme intelligente
      print('🔔 Configuration alarme intelligente...');
      if (autoReminder) {
        try {
          await CrossPlatformAlarmService.scheduleAlarm(reminder);
          // Notification immédiate (feedback)
          await NotificationService.instance.showNow(
            title: 'Alarme configurée',
            body: 'Tu recevras une alarme chaque jour à ${_fmt(reminder)} avec rappel automatique.',
          );
          print('✅ Rappels configurés');
        } catch (e) {
          print('⚠️ Erreur lors de la configuration du rappel: $e');
          // Continuer même si les rappels ne fonctionnent pas
          // Message supprimé pour éviter l'affichage persistant
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
  
  /// Normalise les anciennes valeurs de méditation vers les nouvelles
  String _normalizeMeditationType(String rawMeditation) {
    // Correspondance des anciennes valeurs vers les nouvelles
    switch (rawMeditation) {
      case 'Lectio Divina':
        return 'Méditation profonde : Temps de réflexion entre les versets';
      case 'Contemplation':
        return 'Méditation profonde : Temps de réflexion entre les versets';
      case 'Prière silencieuse':
        return 'Prière : Pauses pour prier';
      case 'Méditation biblique':
        return 'Méditation profonde : Temps de réflexion entre les versets';
      default:
        // Si c'est déjà une nouvelle valeur, la garder
        if (meditations.contains(rawMeditation)) {
          return rawMeditation;
        }
        // Sinon, utiliser la valeur par défaut
        return 'Méditation profonde : Temps de réflexion entre les versets';
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// Téléchargement Bible en ARRIÈRE-PLAN (Offline-First ⭐)
  /// ═══════════════════════════════════════════════════════════
  void _downloadBibleInBackground(String versionCode) {
    // Ne pas bloquer l'UI - téléchargement asynchrone
    Future.microtask(() async {
      try {
        print('📖 Téléchargement Bible $versionCode en arrière-plan...');
        
        // ✅ Vérifier si la version est déjà disponible
        final isAvailable = await BibleVersionManager.isVersionAvailable(versionCode);
        if (isAvailable) {
          print('✅ Version $versionCode déjà disponible');
          return;
        }
        
        // ✅ Télécharger la version depuis VideoPsalm
        final success = await BibleVersionManager.downloadVideoPsalmVersion(versionCode);
        
        if (success) {
          print('✅ Bible $versionCode téléchargée avec succès (arrière-plan)');
          
          // ✅ Notification discrète de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Version $versionCode téléchargée avec succès'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print('⚠️ Échec du téléchargement de $versionCode');
        }
        
      } catch (e) {
        print('⚠️ Erreur téléchargement Bible (non bloquant): $e');
        
        // ✅ Notification d'erreur discrète
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur téléchargement $versionCode: ${e.toString()}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }
}

