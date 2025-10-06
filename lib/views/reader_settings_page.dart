import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/reader_settings_service.dart';

class ReaderSettingsPage extends StatefulWidget {
  const ReaderSettingsPage({super.key});

  @override
  State<ReaderSettingsPage> createState() => _ReaderSettingsPageState();
}

class _ReaderSettingsPageState extends State<ReaderSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Réglages de lecture',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ReaderSettingsService>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview du texte
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '10 Jésus lui répondit : « Si tu connaissais le don de Dieu et qui est celui qui te dit : "Donne-moi à boire", tu lui aurais toi-même demandé à boire, et il t\'aurait donné de l\'eau vive. »',
                        style: settings.getFontStyle(),
                        textAlign: settings.getTextAlign(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Section Thème
                _buildSectionTitle('Thème'),
                _buildThemeOptions(settings),
                
                const SizedBox(height: 30),
                
                // Section Police
                _buildSectionTitle('Police'),
                _buildFontOptions(settings),
                
                const SizedBox(height: 30),
                
                // Section Taille
                _buildSectionTitle('Taille du texte'),
                _buildFontSizeSlider(settings),
                
                const SizedBox(height: 30),
                
                // Section Luminosité
                _buildSectionTitle('Luminosité'),
                _buildBrightnessSlider(settings),
                
                const SizedBox(height: 30),
                
                // Section Alignement
                _buildSectionTitle('Alignement du texte'),
                _buildTextAlignmentOptions(settings),
                
                const SizedBox(height: 30),
                
                // Section Options
                _buildSectionTitle('Options'),
                _buildOptions(settings),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildThemeOptions(ReaderSettingsService settings) {
    return Row(
      children: [
        Expanded(
          child: _buildThemeOption(
            'Clair',
            Icons.light_mode,
            settings.selectedTheme == 'light',
            () => settings.setTheme('light'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildThemeOption(
            'Sombre',
            Icons.dark_mode,
            settings.selectedTheme == 'dark',
            () => settings.setTheme('dark'),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontOptions(ReaderSettingsService settings) {
    final fonts = [
      {'name': 'Inter', 'display': 'Inter'},
      {'name': 'Playfair Display', 'display': 'Playfair'},
      {'name': 'Lora', 'display': 'Lora'},
      {'name': 'Poppins', 'display': 'Poppins'},
      {'name': 'Montserrat', 'display': 'Montserrat'},
      {'name': 'Source Sans Pro', 'display': 'Source Sans'},
      {'name': 'Open Sans', 'display': 'Open Sans'},
      {'name': 'Roboto', 'display': 'Roboto'},
      {'name': 'Nunito', 'display': 'Nunito'},
      {'name': 'Work Sans', 'display': 'Work Sans'},
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fonts.map((font) {
        final isSelected = settings.selectedFont == font['name'];
        return GestureDetector(
          onTap: () => settings.setFont(font['name']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
              ),
            ),
            child: Text(
              font['display']!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontSizeSlider(ReaderSettingsService settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taille: ${settings.fontSize.round()}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '10 - 24',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: settings.fontSize,
            min: 10,
            max: 24,
            divisions: 14,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey.shade300,
            onChanged: (value) => settings.setFontSize(value),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessSlider(ReaderSettingsService settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Luminosité: ${(settings.brightness * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '10 - 100%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: settings.brightness,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey.shade300,
            onChanged: (value) => settings.setBrightness(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAlignmentOptions(ReaderSettingsService settings) {
    final alignments = [
      {'label': 'Gauche', 'icon': Icons.format_align_left, 'value': 'Left'},
      {'label': 'Centre', 'icon': Icons.format_align_center, 'value': 'Center'},
      {'label': 'Droite', 'icon': Icons.format_align_right, 'value': 'Right'},
      {'label': 'Justifier', 'icon': Icons.format_align_justify, 'value': 'Justify'},
    ];

    return Row(
      children: alignments.map((align) {
        final isSelected = settings.textAlignment == align['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => settings.setTextAlignment(align['value']!.toString()),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    align['icon']! as IconData,
                    color: isSelected ? Colors.blue : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    align['label']!.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptions(ReaderSettingsService settings) {
    return Column(
      children: [
        _buildSwitchOption(
          'Mode hors ligne',
          'Télécharger les passages pour une lecture sans internet',
          Icons.cloud_off,
          settings.isOfflineMode,
          (value) => settings.setOfflineMode(value),
        ),
        const SizedBox(height: 16),
        _buildSwitchOption(
          'Verrouiller la lecture',
          'Empêche les modifications accidentelles',
          Icons.lock,
          settings.isLocked,
          (value) => settings.setLocked(value),
        ),
        const SizedBox(height: 16),
        _buildSwitchOption(
          'Activer la recherche',
          'Permet de rechercher dans le texte',
          Icons.search,
          settings.isSearchEnabled,
          (value) => settings.setSearchEnabled(value),
        ),
        const SizedBox(height: 16),
        _buildSwitchOption(
          'Activer les transitions',
          'Animations fluides entre les pages',
          Icons.animation,
          settings.isTransitionsEnabled,
          (value) => settings.setTransitionsEnabled(value),
        ),
      ],
    );
  }

  Widget _buildSwitchOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: 24,
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
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
