import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../bootstrap.dart' as bootstrap;
import '../services/user_prefs_hive.dart';
import '../services/plan_service.dart';
import '../services/telemetry_console.dart';

/// Page épurée des paramètres selon la spécification
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final UserPrefsHive prefs;
  late final PlanService planSvc;
  late final TelemetryConsole telemetry;

  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;

  // Contrôleurs
  final _nameController = TextEditingController();

  // Profil
  bool _biometricsEnabled = false;

  // Lecture & Affichage
  String _bibleVersion = 'LSG';
  String _selectedLanguage = 'Français';
  double _fontSize = 16.0;
  String _themeMode = 'system'; // system|light|dark
  String _accentTheme = 'calm'; // calm|nocturne|scriptura

  // Notifications
  String _time = '07:00';
  int _minutes = 15;
  bool _notifications = true;
  String _notifSound = 'Harpe'; // Harpe|Cloche|Silence
  bool _quietHours = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _weeklySummary = false;

  // Hors-ligne & données
  bool _offlineMode = false;
  int _downloadsSizeBytes = 0;

  // Journal & favoris
  bool _autoJournal = true;
  bool _keepFavorites = true;

  // Listes
  final _languages = const ['Français', 'English', 'Español', 'Português', 'العربية'];
  final _availableVersions = ['LSG', 'S21', 'NIV', 'ESV', 'KJV'];

  @override
  void initState() {
    super.initState();
    prefs = bootstrap.userPrefs;
    planSvc = bootstrap.planService;
    telemetry = bootstrap.telemetry;
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = prefs.profile;
      
      setState(() {
        _profile = profile;
        _nameController.text = profile['displayName'] ?? '';
        _bibleVersion = profile['bibleVersion'] ?? 'LSG';
        _time = profile['preferredTime'] ?? '08:00';
        _minutes = profile['dailyMinutes'] ?? 15;
        _notifications = true; // TODO: récupérer depuis le profil
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _save() async {
    if (_profile == null) return;
    
    setState(() => _saving = true);

    try {
      final updated = Map<String, dynamic>.from(_profile!);
      updated['displayName'] = _nameController.text.trim().isEmpty 
          ? _profile!['displayName'] 
          : _nameController.text.trim();
      updated['bibleVersion'] = _bibleVersion;
      updated['preferredTime'] = _time;
      updated['dailyMinutes'] = _minutes;
      updated['notifications'] = _notifications;
      updated['themeMode'] = _themeMode;
      updated['accentTheme'] = _accentTheme;
      updated['notifSound'] = _notifSound;
      updated['quietHours'] = {
        'enabled': _quietHours,
        'start': '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}',
        'end': '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}',
      };
      updated['weeklySummary'] = _weeklySummary;
      updated['offlineMode'] = _offlineMode;
      updated['biometricsEnabled'] = _biometricsEnabled;
      updated['autoJournal'] = _autoJournal;
      updated['keepFavorites'] = _keepFavorites;

      await prefs.patchProfile(updated);
      
      // Télémétrie
      telemetry.event('settings_saved', {
        'version': _bibleVersion,
        'minutes': _minutes,
        'time': _time,
        'notifications': _notifications,
        'themeMode': _themeMode,
        'accentTheme': _accentTheme,
        'notifSound': _notifSound,
        'quietHours': _quietHours,
        'weeklySummary': _weeklySummary,
        'offlineMode': _offlineMode,
        'biometricsEnabled': _biometricsEnabled,
        'autoJournal': _autoJournal,
        'keepFavorites': _keepFavorites,
      });

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences enregistrées'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _onRestartPlanTapped() async {
    final confirmed = await _confirm(
      title: 'Recommencer ce plan ?',
      message: 'Toute la progression sera remise à zéro et les dates recalculées depuis aujourd\'hui.',
      confirmLabel: 'Recommencer',
    );
    
    if (!confirmed) return;

    try {
      final activePlanId = prefs.profile['activePlanId'] as String?;

      if (activePlanId == null) {
        _toast('Aucun plan actif trouvé', error: true);
        return;
      }

      // TODO: Implémenter restartPlanFromDay1
      // await planSvc.restartPlanFromDay1(activePlanId);
      
      _toast('Plan recommencé depuis le jour 1 !');
      
    } catch (e) {
      _toast('Erreur: ${e.toString().split(':').last.trim()}', error: true);
    }
  }

  Future<void> _onRescheduleTapped() async {
    final confirmed = await _confirm(
      title: 'Replanifier depuis aujourd\'hui ?',
      message: 'Les jours complétés seront gardés, les jours passés marqués comme sautés, et le futur recalculé depuis aujourd\'hui.',
      confirmLabel: 'Replanifier',
    );
    
    if (!confirmed) return;

    try {
      final activePlanId = prefs.profile['activePlanId'] as String?;

      if (activePlanId == null) {
        _toast('Aucun plan actif trouvé', error: true);
        return;
      }

      // TODO: Implémenter rescheduleFromToday
      // await planSvc.rescheduleFromToday(activePlanId);
      
      _toast('Plan replanifié depuis aujourd\'hui !');
      
    } catch (e) {
      _toast('Erreur: ${e.toString().split(':').last.trim()}', error: true);
    }
  }

  Future<void> _onStartNewPlanTapped() async {
    final confirmed = await _confirm(
      title: 'Archiver le plan actuel ?',
      message: 'Vous pourrez toujours le retrouver dans votre historique.',
      confirmLabel: 'Archiver & continuer',
    );
    
    if (!confirmed) return;

    try {
      final activePlanId = prefs.profile['activePlanId'] as String?;

      // 1) Archive le plan actif (si existe)
      if (activePlanId != null) {
        await planSvc.archivePlan(activePlanId);
      }

      // 2) Déréférence le plan actif côté profil local
      await prefs.patchProfile({'activePlanId': null});

      telemetry.event('start_new_plan_clicked', {'had_active_plan': activePlanId != null});

      // 3) Navigation directe vers complete_profile
      context.go('/complete_profile');

      _toast('Plan archivé. Configure un nouveau plan.');
    } catch (e) {
      _toast('Erreur: ${e.toString().split(':').last.trim()}', error: true);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(fontFamily: 'Gilroy', color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel, style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Actions pour les données
  void _clearDownloads() {
    // TODO: Implémenter la suppression des téléchargements
    _toast('Téléchargements effacés');
  }

  void _exportData() {
    // TODO: Implémenter l'export JSON
    _toast('Données exportées');
  }

  void _importData() {
    // TODO: Implémenter l'import JSON
    _toast('Données importées');
  }

  // Actions pour l'aide
  void _openSupportLink() {
    // TODO: Ouvrir le lien de support
    _toast('Ouverture du lien de support');
  }

  void _openFeedbackForm() {
    // TODO: Ouvrir le formulaire de feedback
    _toast('Ouverture du formulaire de feedback');
  }

  void _openLicenses() {
    // TODO: Ouvrir les licences
    _toast('Ouverture des licences');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
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
                      RepaintBoundary(
                        child: Positioned(
                          right: -60,
                          top: -40,
                          child: _softBlob(180),
                        ),
                      ),
                      RepaintBoundary(
                        child: Positioned(
                          left: -40,
                          bottom: -50,
                          child: _softBlob(220),
                        ),
                      ),

                      // Contenu principal avec sections thématiques
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Header modernisé
                            _buildModernHeader(),
                            const SizedBox(height: 24),

                            // Section Profil
                            _buildProfileSection(),
                            const SizedBox(height: 20),

                            // Section Lecture & Affichage
                            _buildReadingSection(),
                            const SizedBox(height: 20),

                            // Section Notifications
                            _buildNotificationsSection(),
                            const SizedBox(height: 20),

                            // Section Hors-ligne & données
                            _buildOfflineSection(),
                            const SizedBox(height: 20),

                            // Section Journal & favoris
                            _buildJournalSection(),
                            const SizedBox(height: 20),

                            // Section Actions de plan
                            _buildPlanActionsSection(),
                            const SizedBox(height: 20),

                            // Section Aide & À propos
                            _buildHelpSection(),
                            const SizedBox(height: 100), // Espace pour le bouton fixé
                          ],
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
            child: _buildSaveButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PARAMÈTRES',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure tes préférences et gère ton plan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSectionCard(
      title: '🧍 Profil',
      icon: Icons.person_rounded,
      children: [
        _buildField(
          label: 'Nom d\'utilisateur',
          icon: Icons.person_rounded,
          child: TextField(
            controller: _nameController,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Entrez votre nom',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Sécurité',
          icon: Icons.lock_outline,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Verrouillage biométrique / code',
                  style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
                ),
              ),
              Switch(
                value: _biometricsEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _biometricsEnabled = v);
                },
                activeThumbColor: const Color(0xFF2563EB),
                activeTrackColor: const Color(0xFF2563EB).withOpacity(0.3),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadingSection() {
    return _buildSectionCard(
      title: '📖 Lecture & Affichage',
      icon: Icons.menu_book_rounded,
      children: [
        _buildField(
          label: 'Version de la Bible',
          icon: Icons.menu_book_rounded,
          child: _buildDropdown(
            value: _bibleVersion,
            items: _availableVersions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _bibleVersion = v);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Langue de l\'interface',
          icon: Icons.language_rounded,
          child: _buildDropdown(
            value: _selectedLanguage,
            items: _languages,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _selectedLanguage = v);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Taille de police (${_fontSize.round()}px)',
          icon: Icons.text_fields_rounded,
          child: _buildFontSizeSlider(),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Thème',
          icon: Icons.palette_outlined,
          child: Column(
            children: [
              _buildDropdown(
                value: _themeMode,
                items: const ['system', 'light', 'dark'],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _themeMode = v);
                },
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _accentTheme,
                items: const ['calm', 'nocturne', 'scriptura'],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _accentTheme = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSectionCard(
      title: '🔔 Notifications',
      icon: Icons.notifications_active_outlined,
      children: [
        _buildField(
          label: 'Rappel quotidien (heure)',
          icon: Icons.access_time,
          child: _buildTimeButton(),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Durée quotidienne ($_minutes min)',
          icon: Icons.timer_outlined,
          child: _buildDurationSlider(),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Sons de notification',
          icon: Icons.music_note_outlined,
          child: _buildDropdown(
            value: _notifSound,
            items: const ['Harpe', 'Cloche', 'Silence'],
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _notifSound = v);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Silence sacré',
          icon: Icons.nights_stay_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Activer',
                      style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
                    ),
                  ),
                  Switch(
                    value: _quietHours,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _quietHours = v);
                    },
                    activeThumbColor: const Color(0xFF2563EB),
                    activeTrackColor: const Color(0xFF2563EB).withOpacity(0.3),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
              if (_quietHours) ...[
                const SizedBox(height: 8),
                _timeRangeRow('De', _quietStart, (t) => setState(() => _quietStart = t)),
                const SizedBox(height: 8),
                _timeRangeRow('À', _quietEnd, (t) => setState(() => _quietEnd = t)),
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Résumé hebdomadaire',
          icon: Icons.event_available_outlined,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Notification chaque dimanche',
                  style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
                ),
              ),
              Switch(
                value: _weeklySummary,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _weeklySummary = v);
                },
                activeThumbColor: const Color(0xFF2563EB),
                activeTrackColor: const Color(0xFF2563EB).withOpacity(0.3),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineSection() {
    return _buildSectionCard(
      title: '📱 Hors-ligne & données',
      icon: Icons.cloud_off_outlined,
      children: [
        _buildField(
          label: 'Mode hors-ligne',
          icon: Icons.cloud_off_outlined,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Désactiver la synchronisation auto',
                  style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
                ),
              ),
              Switch(
                value: _offlineMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _offlineMode = v);
                },
                activeThumbColor: const Color(0xFF2563EB),
                activeTrackColor: const Color(0xFF2563EB).withOpacity(0.3),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Téléchargements',
          icon: Icons.download_for_offline_outlined,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Espace utilisé : ${(_downloadsSizeBytes / 1024 / 1024).toStringAsFixed(1)} Mo',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: _clearDownloads,
                child: const Text('Vider', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Export / Import',
          icon: Icons.import_export_outlined,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _exportData,
                  child: const Text('Exporter JSON'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _importData,
                  child: const Text('Importer JSON'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJournalSection() {
    return _buildSectionCard(
      title: '📝 Journal & favoris',
      icon: Icons.bookmark_border,
      children: [
        _buildField(
          label: 'Journal & favoris',
          icon: Icons.bookmark_border,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Journal automatique',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Switch(
                    value: _autoJournal,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _autoJournal = v);
                    },
                    activeThumbColor: const Color(0xFF2563EB),
                    activeTrackColor: const Color(0xFF2563EB).withOpacity(0.3),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Conserver les versets favoris',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Switch(
                    value: _keepFavorites,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _keepFavorites = v);
                    },
                    activeThumbColor: const Color(0xFF2563EB),
                    activeTrackColor: const Color(0xFF2563EB).withOpacity(0.3),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanActionsSection() {
    return _buildSectionCard(
      title: '🔥 Actions de plan',
      icon: Icons.warning_amber_rounded,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[300], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ces actions modifient définitivement votre plan de lecture. Utilisez avec précaution.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.red[200],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Recommencer ce plan
        _buildPlanActionItem(
          icon: Icons.refresh,
          title: 'Recommencer ce plan (jour 1)',
          subtitle: 'Remet à zéro la progression et recalcule les dates',
          onTap: _onRestartPlanTapped,
        ),
        const SizedBox(height: 12),
        // Replanifier depuis aujourd'hui
        _buildPlanActionItem(
          icon: Icons.schedule,
          title: 'Replanifier depuis aujourd\'hui',
          subtitle: 'Garde les jours complétés et recalcule le futur',
          onTap: _onRescheduleTapped,
        ),
        const SizedBox(height: 12),
        // Commencer un nouveau plan
        _buildPlanActionItem(
          icon: Icons.restart_alt,
          title: 'Commencer un nouveau plan',
          subtitle: 'Archive le plan actuel et relance la configuration',
          onTap: _onStartNewPlanTapped,
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return _buildSectionCard(
      title: '💝 Aide & À propos',
      icon: Icons.favorite_outline,
      children: [
        _buildField(
          label: 'Soutenir & À propos',
          icon: Icons.favorite_outline,
          child: Column(
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.volunteer_activism, color: Colors.white70),
                title: const Text('Soutenir Selah', style: TextStyle(color: Colors.white)),
                onTap: _openSupportLink,
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.feedback_outlined, color: Colors.white70),
                title: const Text('Envoyer un feedback', style: TextStyle(color: Colors.white)),
                onTap: _openFeedbackForm,
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                title: const Text('Crédits & licences', style: TextStyle(color: Colors.white)),
                onTap: _openLicenses,
              ),
              const SizedBox(height: 6),
              const Text(
                'v1.0.0 • Changelog 10/2025',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
            value: _minutes.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            label: '$_minutes min',
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: InkWell(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: int.parse(_time.split(':')[0]),
              minute: int.parse(_time.split(':')[1]),
            ),
          );
          if (time != null) {
            setState(() {
              _time = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Heure quotidienne',
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
                    _time,
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

  Widget _buildFontSizeSlider() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
            value: _fontSize,
            min: 12,
            max: 24,
            divisions: 12,
            label: '${_fontSize.round()}px',
            onChanged: (v) => setState(() => _fontSize = v),
          ),
        ),
      ),
    );
  }

  Widget _timeRangeRow(String label, TimeOfDay current, ValueChanged<TimeOfDay> onPick) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: current);
        if (t != null) onPick(t);
      },
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.red[300], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.red[200],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.red[100],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.red[300], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _saving ? null : _save,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _saving
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
                          'Sauvegarde...',
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
                      'Sauvegarder',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}