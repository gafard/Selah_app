import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  // Variables pour les paramètres de méditation
  String _selectedBibleVersion = 'Louis Segond';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  double _meditationDuration = 15.0;
  String _timeMode = 'Single time';
  String _selectedClockTime = '8:00 am';
  String _selectedMeditationType = 'Méditation guidée';
  String _selectedAmbiance = 'Nature';

  final List<String> _bibleVersions = [
    'Louis Segond',
    'Bible de Jérusalem',
    'Traduction Œcuménique',
    'Bible en français courant',
    'Parole de Vie',
    'Semeur',
    'King James (Anglais)',
  ];

  final List<String> _meditationTypes = [
    'Méditation guidée',
    'Méditation silencieuse',
    'Méditation de pleine conscience',
    'Méditation chrétienne',
    'Méditation de gratitude',
    'Méditation de respiration',
  ];

  final List<String> _ambiances = [
    'Nature',
    'Pluie',
    'Océan',
    'Forêt',
    'Silence',
    'Musique douce',
  ];

  final List<String> _timeOptions = ['6:00 am', '7:00 am', '8:00 am', '9:00 am'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // gray-900
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 384), // max-w-sm
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              // Header
                _buildHeader(),
                
                const SizedBox(height: 16),
                
                // Version de la Bible
                _buildSettingCard(
                  icon: Icons.menu_book,
                  title: 'Version de la Bible',
                  child: _buildBibleVersionContent(),
                ),
                
                const SizedBox(height: 16),
                
                // Durée de méditation
                _buildSettingCard(
                  icon: Icons.timer,
                  title: 'Durée de méditation',
                  child: _buildDurationContent(),
                ),
                
                const SizedBox(height: 16),
                
                // Rappel
                _buildSettingCard(
                  icon: Icons.access_time,
                  title: 'Me rappeler',
                  child: _buildReminderContent(),
                ),
                
                const SizedBox(height: 16),
                
                // Type de méditation
                _buildSettingCard(
                  icon: Icons.self_improvement,
                  title: 'Type de méditation',
                  child: _buildMeditationTypeContent(),
                ),
                
                const SizedBox(height: 16),
                
                // Ambiance sonore
                _buildSettingCard(
                  icon: Icons.music_note,
                  title: 'Ambiance sonore',
                  child: _buildSoundContent(),
              ),
              
              const SizedBox(height: 24),
              
                // Bottom Actions
                _buildBottomActions(),
              ],
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
            'Personnalise ta méditation',
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
                color: const Color(0xFF1F2937), // gray-800
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF9CA3AF), // gray-400
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
        color: const Color(0xFF1F2937), // gray-800
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildBibleVersionContent() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.menu_book,
              size: 20,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(width: 12),
            Text(
              'Version de la Bible',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF), // gray-400
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6), // blue-500
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedBibleVersion,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Dropdown pour la version de la Bible
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF374151), // gray-700
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4B5563), // gray-600
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: _selectedBibleVersion,
            dropdownColor: const Color(0xFF374151), // gray-700
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
                  _selectedBibleVersion = newValue;
                });
              }
            },
            items: _bibleVersions.map<DropdownMenuItem<String>>((String value) {
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

  Widget _buildDurationContent() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.timer,
              size: 20,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(width: 12),
            Text(
              'Durée de méditation',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF), // gray-400
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '${_meditationDuration.round()} min',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF3B82F6), // blue-500
              inactiveTrackColor: const Color(0xFF374151), // gray-700
              thumbColor: const Color(0xFF3B82F6), // blue-500
              overlayColor: const Color(0xFF3B82F6).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _meditationDuration,
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (double value) {
                setState(() {
                  _meditationDuration = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderContent() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(width: 12),
            Text(
              'Me rappeler',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF), // gray-400
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(_reminderTime),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Heure scrollable
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF374151), // gray-700
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4B5563), // gray-600
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Heures
              Expanded(
                child: _buildTimeScrollable(
                  'Heures',
                  _reminderTime.hour,
                  0,
                  23,
                  (value) {
                    setState(() {
                      _reminderTime = TimeOfDay(hour: value, minute: _reminderTime.minute);
                    });
                  },
                ),
              ),
              Container(
                width: 1,
                color: const Color(0xFF4B5563),
              ),
              // Minutes
              Expanded(
                child: _buildTimeScrollable(
                  'Minutes',
                  _reminderTime.minute,
                  0,
                  59,
                  (value) {
                    setState(() {
                      _reminderTime = TimeOfDay(hour: _reminderTime.hour, minute: value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bouton pour créer l'alarme
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _createAlarm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6), // blue-500
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Créer l\'alarme',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeModeButton(String mode) {
    final isSelected = _timeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeMode = mode;
        });
      },
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF4B5563),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            mode,
            style: GoogleFonts.inter(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockWidget() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4B5563), width: 2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        children: [
          // Clock hands
          Center(
            child: Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
              transform: Matrix4.identity()..rotateZ(-0.785), // -45 degrees
            ),
          ),
          Center(
            child: Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
              transform: Matrix4.identity()..rotateZ(1.57), // 90 degrees
            ),
          ),
          // Center dot
          Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Clock numbers
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Text(
              '12',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 10,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '3',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 10,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Text(
              '6',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 10,
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '9',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String time) {
    final isSelected = _selectedClockTime == time;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedClockTime = time;
          });
        },
        child: Text(
          time,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationTypeContent() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.self_improvement,
              size: 20,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(width: 12),
        Text(
              'Type de méditation',
          style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF), // gray-400
            fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              _selectedMeditationType,
              style: GoogleFonts.inter(
            color: Colors.white,
                fontSize: 16,
              ),
          ),
          ],
        ),
        const SizedBox(height: 12),
        // Dropdown pour le type de méditation
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
            color: const Color(0xFF374151), // gray-700
            borderRadius: BorderRadius.circular(8),
                  border: Border.all(
              color: const Color(0xFF4B5563), // gray-600
                    width: 1,
                  ),
                ),
          child: DropdownButton<String>(
            value: _selectedMeditationType,
            dropdownColor: const Color(0xFF374151), // gray-700
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
                  _selectedMeditationType = newValue;
                });
              }
            },
            items: _meditationTypes.map<DropdownMenuItem<String>>((String value) {
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

  Widget _buildSoundContent() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.music_note,
              size: 20,
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(width: 12),
            Text(
              'Ambiance sonore',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF), // gray-400
                fontSize: 16,
              ),
            ),
            const Spacer(),
        Text(
              _selectedAmbiance,
          style: GoogleFonts.inter(
            color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Dropdown pour l'ambiance sonore
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF374151), // gray-700
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4B5563), // gray-600
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: _selectedAmbiance,
            dropdownColor: const Color(0xFF374151), // gray-700
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
                  _selectedAmbiance = newValue;
                });
              }
            },
            items: _ambiances.map<DropdownMenuItem<String>>((String value) {
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

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            // Reset all settings
            setState(() {
              _selectedBibleVersion = 'Louis Segond';
              _reminderTime = const TimeOfDay(hour: 8, minute: 0);
              _meditationDuration = 15.0;
              _timeMode = 'Single time';
              _selectedClockTime = '8:00 am';
              _selectedMeditationType = 'Méditation guidée';
              _selectedAmbiance = 'Nature';
            });
          },
          child: Text(
            'Reset all',
          style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF), // gray-400
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB), // blue-600
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: Text(
            'Continue',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeScrollable(String label, int value, int min, int max, Function(int) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: max - min + 1,
            itemBuilder: (context, index) {
              final itemValue = min + index;
              final isSelected = itemValue == value;
              return GestureDetector(
                onTap: () => onChanged(itemValue),
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
          decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    itemValue.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _createAlarm() {
    // Simule la création d'une alarme
    // Dans une vraie app, vous utiliseriez flutter_alarm_clock
    // FlutterAlarmClock.createAlarm(hour: _reminderTime.hour, minutes: _reminderTime.minute);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarme créée pour ${_formatTime(_reminderTime)}'),
        backgroundColor: const Color(0xFF10B981), // emerald-500
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }

  void _saveSettings() {
    // Sauvegarder les paramètres
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text('Paramètres de méditation sauvegardés !'),
        backgroundColor: Color(0xFF10B981), // emerald-500
      ),
    );
    
    // Naviguer vers la page d'accueil
    Navigator.pushReplacementNamed(context, '/home');
  }
}