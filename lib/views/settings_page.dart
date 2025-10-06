import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Temporairement désactivé
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';

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
  static const Color _lightBackground = Color(0xFFF6F5F1);
  static const Color _calmBlue = Color(0xFF5B6C9D);
  static const Color _softBlack = Color(0xFF333333);

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
    // On applique le thème clair à cette page
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: _lightBackground,
        appBarTheme: const AppBarTheme(backgroundColor: _lightBackground, foregroundColor: _softBlack, elevation: 0),
        listTileTheme: const ListTileThemeData(tileColor: _softBlack),
        switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.all(_calmBlue)),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: [
                  _buildSectionTitle('Profil'),
                  _buildProfileSection(),
                  _buildSectionTitle('Préférences'),
                  _buildPreferencesSection(),
                  _buildSectionTitle('Lecture & Méditation'),
                  _buildReaderSection(),
                  _buildSectionTitle('Compte'),
                  _buildAccountSection(),
                  _buildSectionTitle('À propos'),
                  _buildAboutSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(title.toUpperCase(), style: GoogleFonts.lato(fontSize: 12, color: _calmBlue, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(hintText: 'Nom d\'affichage', border: InputBorder.none),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email),
                title: Text(context.read<AppState>().user?['email'] ?? 'Email non disponible'),
            enabled: false, // Email en lecture seule
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: const Text('Enregistrer le profil'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Mode sombre'),
            value: _preferences['darkMode'] ?? false,
            onChanged: (value) => setState(() => _preferences['darkMode'] = value),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Version de la Bible'),
            trailing: DropdownButton<String>(
              value: _preferences['bibleVersion'] ?? 'LSG',
              items: const [
                DropdownMenuItem(value: 'LSG', child: Text('Louis Segond')),
                DropdownMenuItem(value: 'S21', child: Text('Segond 21')),
                DropdownMenuItem(value: 'TOB', child: Text('Traduction Œcuménique')),
              ],
              onChanged: (value) => setState(() => _preferences['bibleVersion'] = value),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Heure de rappel'),
            trailing: TextButton(
              onPressed: () async {
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
              },
              child: Text(_preferences['reminderTime'] ?? '08:00'),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Activer les notifications'),
            value: _preferences['notificationsEnabled'] ?? true,
            onChanged: (value) => setState(() => _preferences['notificationsEnabled'] = value),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePreferences,
                child: const Text('Enregistrer les préférences'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Taille de la police'),
            trailing: Text('${((_preferences['reader']?['fontScale'] ?? 1.0) * 100).toInt()}%'),
          ),
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
          ListTile(
            leading: const Icon(Icons.format_line_spacing),
            title: const Text('Interligne'),
            trailing: Text('${((_preferences['reader']?['lineHeight'] ?? 1.4) * 10).toInt()}'),
          ),
          Slider(
            value: _preferences['reader']?['lineHeight'] ?? 1.4,
            min: 1.2,
            max: 1.8,
            divisions: 6,
            onChanged: (value) => setState(() {
              _preferences['reader'] ??= {};
              _preferences['reader']['lineHeight'] = value;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Gérer mon plan'),
            onTap: () => context.push('/plan_choice'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Exporter mes données'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible !'))),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version de l\'application'),
            trailing: Text('1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Politique de confidentialité'),
            onTap: () => _launchURL('https://your-privacy-policy-url.com'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Conditions Générales d\'Utilisation'),
            onTap: () => _launchURL('https://your-terms-url.com'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}