import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/user_prefs_hive.dart';
import '../services/telemetry_console.dart';
import '../bootstrap.dart' as bootstrap;
import '../services/plan_service_http.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Variables d'état
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _audioEnabled = true;
  String _selectedLanguage = 'Français';
  double _fontSize = 16.0;

  final List<String> _languages = [
    'Français',
    'English',
    'Español',
    'Português',
    'العربية',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final appState = context.read<AppState>();
    final profile = appState.profile;
    if (profile != null) {
      setState(() {
        _displayNameController.text = profile['display_name'] ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implémenter la mise à jour du profil
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRestartPlanTapped() async {
    final confirmed = await _confirm(
      title: 'Recommencer ce plan ?',
      message: 'Toute la progression sera remise à zéro et les dates recalculées depuis aujourd\'hui.',
      confirmLabel: 'Recommencer',
    );
    
    if (!confirmed) return;

    try {
      final prefs = context.read<UserPrefsHive>();
      final planService = bootstrap.planService as PlanServiceHttp;
      final activePlanId = prefs.profile['activePlanId'] as String?;

      if (activePlanId == null) {
        _toast('Aucun plan actif trouvé', error: true);
        return;
      }

      // Recommencer le plan
      await planService.restartPlanFromDay1(activePlanId);
      
      _toast('Plan recommencé depuis le jour 1 !');
      
      // Optionnel : naviguer vers home pour voir le changement
      context.go('/home');
      
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
      final prefs = context.read<UserPrefsHive>();
      final planService = bootstrap.planService as PlanServiceHttp;
      final activePlanId = prefs.profile['activePlanId'] as String?;

      if (activePlanId == null) {
        _toast('Aucun plan actif trouvé', error: true);
        return;
      }

      // Replanifier le plan
      await planService.rescheduleFromToday(activePlanId);
      
      _toast('Plan replanifié depuis aujourd\'hui !');
      
      // Optionnel : naviguer vers home pour voir le changement
      context.go('/home');
      
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
      final prefs = context.read<UserPrefsHive>();
      final telemetry = context.read<TelemetryConsole>();
      final planService = bootstrap.planService as PlanServiceHttp;

      final activePlanId = prefs.profile['activePlanId'] as String?;

      // 1) Archive le plan actif (si existe)
      if (activePlanId != null) {
        await planService.archivePlan(activePlanId);
      }

      // 2) Déréférence le plan actif côté profil local
      await prefs.patchProfile({'activePlanId': null});

      telemetry.event('start_new_plan_clicked', {'had_active_plan': activePlanId != null});

      // 3) Navigation directe vers complete_profile
      // (hasOnboarded est toujours true ici car on est dans /settings)
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
        title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(message, style: GoogleFonts.inter(color: const Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(cancelLabel, style: const TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
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

  Future<void> _signOut() async {
    try {
      // TODO: Implémenter la déconnexion
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
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
            colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 384),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Profil utilisateur
                  _buildSettingCard(
                    icon: Icons.person,
                    title: 'Profil utilisateur',
                    child: _buildProfileContent(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Plan de lecture
                  _buildSettingCard(
                    icon: Icons.book,
                    title: 'Plan de lecture',
                    child: _buildPlanContent(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notifications
        _buildSettingCard(
          icon: Icons.notifications,
          title: 'Notifications',
          child: _buildNotificationContent(),
        ),
                  
                  const SizedBox(height: 16),
                  
                  // Apparence
        _buildSettingCard(
          icon: Icons.palette,
          title: 'Apparence',
          child: _buildAppearanceContent(),
        ),
                  
                  const SizedBox(height: 16),
                  
                  // Audio
        _buildSettingCard(
          icon: Icons.volume_up,
          title: 'Audio',
          child: _buildAudioContent(),
        ),
                  
                  const SizedBox(height: 16),
                  
                  // Langue
        _buildSettingCard(
          icon: Icons.language,
          title: 'Langue',
          child: _buildLanguageContent(),
        ),
                  
                  const SizedBox(height: 16),
                  
                  // Taille de police
                  _buildSettingCard(
                    icon: Icons.edit,
                    title: 'Taille de police',
                    child: _buildFontSizeContent(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Paramètres',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildPlanContent() {
    return Column(
      children: [
        // Recommencer ce plan (jour 1)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.refresh, color: Colors.white, size: 24),
          title: Text(
            'Recommencer ce plan (jour 1)',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Remet à zéro la progression et recalcule les dates',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          onTap: _onRestartPlanTapped,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          hoverColor: Colors.white.withOpacity(0.05),
        ),
        const SizedBox(height: 12),
        // Replanifier depuis aujourd'hui
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule, color: Colors.white, size: 24),
          title: Text(
            'Replanifier depuis aujourd\'hui',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Garde les jours complétés et recalcule le futur',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          onTap: _onRescheduleTapped,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          hoverColor: Colors.white.withOpacity(0.05),
        ),
        const SizedBox(height: 12),
        // Commencer un nouveau plan
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restart_alt, color: Colors.white, size: 24),
          title: Text(
            'Commencer un nouveau plan',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Archive le plan actuel et relance la configuration',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          onTap: _onStartNewPlanTapped,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          hoverColor: Colors.white.withOpacity(0.05),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.person,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              'Profil utilisateur',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF3B82F6),
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _displayNameController,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Nom d\'utilisateur',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF4B5563),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF4B5563),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationContent() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.notifications,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: const Color(0xFF49C98D),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Recevoir des notifications pour les rappels de méditation et les nouvelles fonctionnalités',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceContent() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.palette,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              'Apparence',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Switch(
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
              activeColor: const Color(0xFF49C98D),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Activer le mode sombre pour une expérience plus confortable',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioContent() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.volume_up,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              'Audio',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Switch(
              value: _audioEnabled,
              onChanged: (value) {
                setState(() {
                  _audioEnabled = value;
                });
              },
              activeColor: const Color(0xFF49C98D),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Activer ou désactiver l\'audio pour les méditations et lectures',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageContent() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.language,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              'Langue',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              _selectedLanguage,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4B5563),
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: const Color(0xFF374151),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
            ),
            underline: Container(),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            isExpanded: true,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLanguage = newValue;
                });
              }
            },
            items: _languages.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeContent() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.text_fields,
              size: 20,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              'Taille de police',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '${_fontSize.round()}px',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: const Color(0xFF374151),
              thumbColor: const Color(0xFF3B82F6),
              overlayColor: const Color(0xFF3B82F6).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              onChanged: (double value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        // Bouton Sauvegarder
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Sauvegarder',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bouton Déconnexion
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Se déconnecter',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}