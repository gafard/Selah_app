import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Temporairement désactivé
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import '../widgets/selah_logo.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- Variables d'état ---
  final _displayNameController = TextEditingController();
  Map<String, dynamic> _preferences = {};
  bool _isLoading = false;

  // --- Thème pour la page (plus clair pour les settings)
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _secondaryBlue = Color(0xFF60A5FA);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentPurple = Color(0xFF8B5CF6);
  static const Color _accentRed = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);

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
        _preferences = profile['preferences'] ?? {};
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      // Simulation de sauvegarde pour les tests
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    try {
      // Simulation de mise à jour des préférences pour les tests
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préférences enregistrées ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
        // Simulation de déconnexion pour les tests
        await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      context.go('/welcome'); // Redirection vers la page de bienvenue
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        backgroundColor: _lightBackground,
        elevation: 0,
        title: Row(
          children: [
            const SelahAppIcon(size: 32, useBlueBackground: false),
            const SizedBox(width: 12),
            Text(
              'Paramètres',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildSettingsGrid(),
                  const SizedBox(height: 24),
                  _buildAccountSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Justin',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'justin@example.com',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Membre depuis Janvier 2024',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildSettingCard(
              icon: Icons.palette,
              title: 'Thème',
              subtitle: 'Mode sombre',
              color: _accentPurple,
              onTap: () => _showThemeDialog(),
            ),
            _buildSettingCard(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Rappels quotidiens',
              color: _accentOrange,
              onTap: () => _showNotificationSettings(),
            ),
            _buildSettingCard(
              icon: Icons.book,
              title: 'Bible',
              subtitle: 'Version LSG',
              color: _accentGreen,
              onTap: () => _showBibleVersionDialog(),
            ),
            _buildSettingCard(
              icon: Icons.schedule,
              title: 'Rappels',
              subtitle: '08:00',
              color: _primaryBlue,
              onTap: () => _showTimePicker(),
            ),
            _buildSettingCard(
              icon: Icons.font_download,
              title: 'Police',
              subtitle: 'Taille moyenne',
              color: _accentRed,
              onTap: () => _showFontSettings(),
            ),
            _buildSettingCard(
              icon: Icons.language,
              title: 'Langue',
              subtitle: 'Français',
              color: _secondaryBlue,
              onTap: () => _showLanguageDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compte',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildAccountItem(
                icon: Icons.edit_note,
                title: 'Gérer mon plan',
                subtitle: 'Personnaliser votre parcours',
                color: _accentGreen,
                onTap: () => context.push('/plan_choice'),
              ),
              const Divider(height: 24),
              _buildAccountItem(
                icon: Icons.file_download,
                title: 'Exporter mes données',
                subtitle: 'Sauvegarder votre journal',
                color: _primaryBlue,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible !'))),
              ),
              const Divider(height: 24),
              _buildAccountItem(
                icon: Icons.logout,
                title: 'Déconnexion',
                subtitle: 'Se déconnecter de l\'application',
                color: _accentRed,
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: _textSecondary,
          ),
        ],
      ),
    );
  }

  // Méthodes de dialogue pour les paramètres
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Mode clair'),
              onTap: () {
                setState(() => _preferences['darkMode'] = false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Mode sombre'),
              onTap: () {
                setState(() => _preferences['darkMode'] = true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Activer les notifications'),
              value: _preferences['notificationsEnabled'] ?? true,
              onChanged: (value) => setState(() => _preferences['notificationsEnabled'] = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showBibleVersionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version de la Bible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Louis Segond'),
              onTap: () {
                setState(() => _preferences['bibleVersion'] = 'LSG');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Segond 21'),
              onTap: () {
                setState(() => _preferences['bibleVersion'] = 'S21');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Traduction Œcuménique'),
              onTap: () {
                setState(() => _preferences['bibleVersion'] = 'TOB');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_preferences['reminderTime']?.split(':')[0] ?? '8'),
        minute: int.parse(_preferences['reminderTime']?.split(':')[1] ?? '0'),
      ),
    );
    if (time != null) {
      setState(() {
        _preferences['reminderTime'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showFontSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres de police'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Taille: ${((_preferences['reader']?['fontScale'] ?? 1.0) * 100).toInt()}%'),
            Slider(
              value: _preferences['reader']?['fontScale'] ?? 1.0,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              onChanged: (value) => setState(() {
                _preferences['reader'] ??= {};
                _preferences['reader']['fontScale'] = value;
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}