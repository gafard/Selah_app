import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../domain/user_prefs.dart';
import '../domain/plan_service.dart';
import '../domain/bible_repo.dart';
import '../domain/telemetry.dart';
import '../services/daily_alarm.dart';
import '../services/background_tasks.dart';
import '../services/ics_import_service.dart';

/// Page unifiée Profil + Paramètres avec design Calm/Superlist
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final UserPrefs prefs;
  late final PlanService planSvc;
  late final BibleRepo bible;
  late final Telemetry telemetry;

  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _languages = const ['Français', 'English', 'Español'];
  String _bibleVersion = 'LSG';
  String _time = '07:00';
  int _minutes = 15;
  bool _notifications = true;
  List<String> _availableVersions = ['LSG', 'S21', 'NIV', 'ESV', 'KJV'];

  @override
  void initState() {
    super.initState();
    prefs = context.read<UserPrefs>();
    planSvc = context.read<PlanService>();
    bible = context.read<BibleRepo>();
    telemetry = context.read<Telemetry>();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await prefs.get();
      final versions = await bible.versions();
      
      setState(() {
        _profile = profile;
        _nameController.text = profile.displayName ?? '';
        _bibleVersion = profile.bibleVersion ?? 'LSG';
        _time = profile.preferredTime ?? '08:00';
        _minutes = profile.dailyMinutes ?? 15;
        _notifications = true; // TODO: récupérer depuis le profil
        _availableVersions = versions.map((v) => v['id'] as String).toList();
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
    final changedVersion = _bibleVersion != _profile!.bibleVersion;

    try {
      final updated = _profile!.copyWith(
        displayName: _nameController.text.trim().isEmpty 
            ? _profile!.displayName 
            : _nameController.text.trim(),
        bibleVersion: _bibleVersion,
        preferredTime: _time,
        dailyMinutes: _minutes,
      );

      await prefs.update(updated);
      
      // Programmer l'alarme quotidienne
      if (_notifications) {
        await DailyAlarm.scheduleDaily(_time);
      } else {
        await DailyAlarm.cancelDaily();
      }

      // Si la version de la Bible a changé
      if (changedVersion) {
        // 1) Téléchargement offline en tâche de fond
        // await BackgroundTasks.queueBible(_bibleVersion);

        // 2) Régénérer le plan courant si présent
        final currentPlanId = updated.preferences?['currentPlanId'] as String?;
        if (currentPlanId != null) {
          final icsUrl = buildGeneratorIcsUrl(
            start: DateTime.now(),
            totalDays: 365,
            order: 'traditional',
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
            books: 'OT,NT',
            lang: 'fr',
            logic: 'words',
            includeUrls: true,
            urlSite: 'biblegateway',
            urlVersion: _bibleVersion,
          );
          // await // BackgroundTasks.queueRegen // TODO: Implémenter(currentPlanId, icsUrl.toString());
        }
      }

      // Télémétrie
      telemetry.track('settings_saved', {
        'version': _bibleVersion,
        'minutes': _minutes,
        'time': _time,
        'changedVersion': changedVersion,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildCard(child: _buildIdentity()),
              const SizedBox(height: 12),
              _buildCard(child: _buildReadingPrefs()),
              const SizedBox(height: 12),
              _buildCard(child: _buildNotifications()),
              const SizedBox(height: 20),
              _buildPrimaryButton(
                text: _saving ? 'Enregistrement…' : 'Sauvegarder',
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      const BackButton(color: Colors.white70),
      const SizedBox(width: 8),
      Text(
        'Profil & paramètres',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _buildCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _buildIdentity() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Identité',
        style: GoogleFonts.inter(color: Colors.white70),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _nameController,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: _buildInputDecoration('Nom d\'utilisateur'),
      ),
    ],
  );

  Widget _buildReadingPrefs() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Préférences de méditation',
        style: GoogleFonts.inter(color: Colors.white70),
      ),
      const SizedBox(height: 12),
      _buildRow(
        'Version de la Bible',
        trailing: DropdownButton<String>(
          value: _bibleVersion,
          dropdownColor: const Color(0xFF374151),
          items: _availableVersions
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      v,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _bibleVersion = v!),
        ),
      ),
      const SizedBox(height: 8),
      _buildRow(
        'Heure quotidienne',
        trailing: _buildTimeButton(),
      ),
      const SizedBox(height: 8),
      _buildRow(
        'Minutes / jour',
        trailing: Slider(
          value: _minutes.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          activeColor: const Color(0xFF3B82F6),
          onChanged: (v) => setState(() => _minutes = v.round()),
        ),
      ),
    ],
  );

  Widget _buildNotifications() => Row(
    children: [
      Expanded(
        child: Text(
          'Rappels quotidiens',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      Switch(
        value: _notifications,
        onChanged: (v) => setState(() => _notifications = v),
        activeTrackColor: const Color(0xFF3B82F6).withOpacity(.35),
        activeThumbColor: const Color(0xFF3B82F6),
      ),
    ],
  );

  Widget _buildRow(String title, {required Widget trailing}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      trailing,
    ],
  );

  InputDecoration _buildInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    filled: true,
    fillColor: const Color(0xFF374151),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF4B5563)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF4B5563)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
    ),
  );

  Widget _buildTimeButton() => OutlinedButton(
    onPressed: () async {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: int.parse(_time.split(':')[0]),
          minute: int.parse(_time.split(':')[1]),
        ),
        builder: (ctx, child) => Theme(
          data: ThemeData.dark(),
          child: child!,
        ),
      );
      if (time != null) {
        setState(() {
          _time = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        });
      }
    },
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF4B5563)),
    ),
    child: Text(
      _time,
      style: const TextStyle(color: Colors.white),
    ),
  );

  Widget _buildPrimaryButton({required String text, VoidCallback? onTap}) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
