import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plan_profile.dart';
import '../services/bible_versions_service.dart';
import '../services/plan_orchestrator.dart';

class PlanSelectionPage extends StatefulWidget {
  const PlanSelectionPage({super.key});

  @override
  State<PlanSelectionPage> createState() => _PlanSelectionPageState();
}

class _PlanSelectionPageState extends State<PlanSelectionPage> {
  Level _level = Level.newBeliever;
  final Set<Goal> _goals = {Goal.discipline};
  int _minutes = 15;
  int _days = 30;
  DateTime _start = DateTime.now();
  String? _selectedVersionCode;

  Future<List<BibleVersion>>? _versionsFuture;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _versionsFuture = BibleVersionsService.fetchVersions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      body: SafeArea(
        child: Stack(
          children: [
            // contenu
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _card(
                    child: _levelSelector(),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: _goalSelector(),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: _timeDurationSelector(),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: _versionSelector(),
                  ),
                  const SizedBox(height: 24),
                  _cta(),
                ],
              ),
            ),
            if (_generating) _loaderOverlay(),
            if (_error != null) _retryBanner(_error!),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Text(
          'Configurer ton plan',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222634),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? const Color(0xFF1A1D29) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _levelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Niveau'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              label: 'Nouveau converti',
              selected: _level == Level.newBeliever,
              onTap: () => setState(() => _level = Level.newBeliever),
            ),
            _chip(
              label: 'Régulier',
              selected: _level == Level.regular,
              onTap: () => setState(() => _level = Level.regular),
            ),
            _chip(
              label: 'Serviteur/Leader',
              selected: _level == Level.leader,
              onTap: () => setState(() => _level = Level.leader),
            ),
          ],
        ),
      ],
    );
  }

  Widget _goalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Objectifs'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              label: 'Discipline',
              selected: _goals.contains(Goal.discipline),
              onTap: () => setState(() => _toggleGoal(Goal.discipline)),
            ),
            _chip(
              label: 'Approfondir la Parole',
              selected: _goals.contains(Goal.deepenWord),
              onTap: () => setState(() => _toggleGoal(Goal.deepenWord)),
            ),
            _chip(
              label: 'Prière',
              selected: _goals.contains(Goal.prayer),
              onTap: () => setState(() => _toggleGoal(Goal.prayer)),
            ),
            _chip(
              label: 'Croissance de la foi',
              selected: _goals.contains(Goal.faithGrowth),
              onTap: () => setState(() => _toggleGoal(Goal.faithGrowth)),
            ),
            _chip(
              label: 'Toute la Bible',
              selected: _goals.contains(Goal.wholeBible),
              onTap: () => setState(() => _toggleGoal(Goal.wholeBible)),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleGoal(Goal g) {
    if (_goals.contains(g)) {
      _goals.remove(g);
    } else {
      _goals.add(g);
    }
    setState(() {});
  }

  Widget _timeDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Temps & Durée'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _subCard(
                title: 'Minutes/jour',
                child: Slider(
                  value: _minutes.toDouble(),
                  min: 5, max: 60, divisions: 11,
                  onChanged: (v) => setState(() => _minutes = v.round()),
                ),
                trailing: Text('$_minutes min',
                    style: GoogleFonts.inter(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _subCard(
                title: 'Jours',
                child: Slider(
                  value: _days.toDouble(),
                  min: 7, max: 365, divisions: 10,
                  onChanged: (v) => setState(() => _days = v.round()),
                ),
                trailing: Text('$_days j',
                    style: GoogleFonts.inter(color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _subCard(
          title: 'Date de départ',
          child: TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 0)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                initialDate: _start,
              );
              if (picked != null) setState(() => _start = picked);
            },
            icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
            label: Text(
              '${_start.year}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _subCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _versionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Version de la Bible'),
        const SizedBox(height: 8),
        FutureBuilder<List<BibleVersion>>(
          future: _versionsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _skeleton();
            }
            if (snap.hasError) {
              return _errorBox(
                'Impossible de charger les versions',
                onRetry: () {
                  setState(() {
                    _versionsFuture = BibleVersionsService.fetchVersions(forceRefresh: true);
                  });
                },
              );
            }
            final versions = snap.data!;
            _selectedVersionCode ??= versions.first.code; // défaut
            return Wrap(
              spacing: 8, runSpacing: 8,
              children: versions.map((v) {
                final selected = _selectedVersionCode == v.code;
                return _chip(
                  label: v.name.isNotEmpty ? '${v.name} (${v.code})' : v.code,
                  selected: selected,
                  onTap: () => setState(() => _selectedVersionCode = v.code),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _skeleton() {
    return Wrap(
      spacing: 8,
      children: List.generate(4, (_) {
        return Container(
          width: 140, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
          ),
        );
      }),
    );
  }

  Widget _errorBox(String msg, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2B2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: GoogleFonts.inter(color: Colors.white))),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _cta() {
    final enabled = _selectedVersionCode != null && _goals.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _onGenerate : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF1553FF),
          disabledBackgroundColor: Colors.white24,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          'Générer mon plan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _loaderOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
      ),
    );
  }

  Widget _retryBanner(String message) {
    return Positioned(
      left: 12, right: 12, bottom: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2630),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: GoogleFonts.inter(color: Colors.white))),
            TextButton(
              onPressed: _onGenerate,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String t) => Text(
        t,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  Future<void> _onGenerate() async {
    setState(() {
      _error = null;
      _generating = true;
    });

    try {
      final profile = PlanProfile(
        level: _level,
        goals: _goals,
        minutesPerDay: _minutes,
        totalDays: _days,
        startDate: _start,
      );

      await PlanOrchestrator.generateAndCachePlan(
        profile: profile,
        bibleVersion: _selectedVersionCode!, // ex: 'LSG'
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan généré et stocké hors-ligne ✅'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      // Redirige vers Home/Reader par ex.
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _error = 'Échec de génération : $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

