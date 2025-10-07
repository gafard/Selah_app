import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Variables d'état
  final _displayNameController = TextEditingController();
  Map<String, dynamic> _preferences = {};
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
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
        _preferences = profile['preferences'] ?? {};
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final appState = context.read<AppState>();
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

  Future<void> _signOut() async {
    try {
      final appState = context.read<AppState>();
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
                  
                  // Langue
                  _buildSettingCard(
                    icon: Icons.language,
                    title: 'Langue',
                    child: _buildLanguageContent(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Taille de police
                  _buildSettingCard(
                    icon: Icons.text_fields,
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
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
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
              activeThumbColor: const Color(0xFF3B82F6),
              activeTrackColor: const Color(0xFF3B82F6).withOpacity(0.3),
              inactiveThumbColor: const Color(0xFF9CA3AF),
              inactiveTrackColor: const Color(0xFF374151),
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
              activeThumbColor: const Color(0xFF3B82F6),
              activeTrackColor: const Color(0xFF3B82F6).withOpacity(0.3),
              inactiveThumbColor: const Color(0xFF9CA3AF),
              inactiveTrackColor: const Color(0xFF374151),
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