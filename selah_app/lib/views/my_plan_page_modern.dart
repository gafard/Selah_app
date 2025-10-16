// my_plan_page_modern.dart
// Page "Mon Plan" — version moderne : header glass, stats, actions, grille 42 jours
// - SliverAppBar translucide avec blur
// - Carte récap (titre plan, progression, jours restants)
// - CTA "Reprendre la lecture d'aujourd'hui"
// - Grille 6x7 modernisée (états: aujourd'hui, sélection, dans plan, terminé)
// - Scroll to today, haptics, petites animations
// - Conserve la logique existante: planService, showPlanDaySheet, GoRouter '/reader'

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../bootstrap.dart' as bootstrap;
import '../models/plan_models.dart';
// import '../widgets/reading_plan_sheet.dart'; // TODO: Créer ce widget

class MyPlanPageModern extends StatefulWidget {
  const MyPlanPageModern({super.key});

  @override
  State<MyPlanPageModern> createState() => _MyPlanPageModernState();
}

class _MyPlanPageModernState extends State<MyPlanPageModern> {
  DateTime _monthAnchor = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected; // jour tapé
  Plan? _plan;
  double _progress = 0; // 0..1
  int _daysDone = 0;
  int _daysTotal = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadActivePlan();
  }

  Future<void> _loadActivePlan() async {
    try {
      final plan = await bootstrap.planService.getActivePlan();
      if (!mounted || plan == null) return;
      int total = plan.totalDays;
      final start = DateTime(plan.startDate.year, plan.startDate.month, plan.startDate.day);
      final today = DateTime.now();
      final elapsed = today.isBefore(start)
          ? 0
          : today.difference(start).inDays + 1; // index du jour courant
      final clampedElapsed = elapsed.clamp(0, total);

      setState(() {
        _plan = plan;
        _daysTotal = total;
        _daysDone = clampedElapsed; // approximation; remplacable par un vrai compteur "completed"
        _progress = total == 0 ? 0 : _daysDone / total;
      });
    } catch (e) {
      debugPrint('❌ loadActivePlan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _plan?.name ?? 'Mon plan';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _GlassAppBar(title: title, onClose: () => context.pop()),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(child: _HeaderStrip(
            month: _monthAnchor,
            onPrev: () => setState(() {
              _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month - 1);
            }),
            onNext: () => setState(() {
              _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month + 1);
            }),
          )),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(child: _StatsCard(
            progress: _progress,
            daysDone: _daysDone,
            daysTotal: _daysTotal,
            onResumeToday: _plan == null ? null : () async {
              final today = DateTime.now();
              final planDay = await _getPlanDayForDate(today);
              if (!mounted) return;
              _openDaySheet(today, planDay);
            },
          )),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _WeekdayStrip()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final days = _compute42Days(_monthAnchor);
                  final d = days[i];
                  final isToday = _sameDay(d, DateTime.now());
                  final isSelected = _selected != null && _sameDay(d, _selected!);
                  final isInMonth = d.month == _monthAnchor.month;
                  final inPlan = _isInActivePlan(d);

                  return _DayCell(
                    date: d,
                    isToday: isToday,
                    isSelected: isSelected,
                    dimmed: !isInMonth,
                    inPlan: inPlan,
                    completedFuture: _isCompleted(d),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = d);
                      final planDay = await _getPlanDayForDate(d);
                      if (!mounted) return;
                      _openDaySheet(d, planDay);
                    },
                  );
                },
                childCount: 42,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _JumpTodayButton(onTap: _jumpToToday),
    );
  }

  Future<void> _jumpToToday() async {
    setState(() {
      _monthAnchor = DateTime(DateTime.now().year, DateTime.now().month);
      _selected = DateTime.now();
    });
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  // ===== Logic =====
  List<DateTime> _compute42Days(DateTime anchor) {
    final first = DateTime(anchor.year, anchor.month, 1);
    final startOffset = (first.weekday + 6) % 7; // lundi=0
    final start = first.subtract(Duration(days: startOffset));
    return List.generate(42, (i) => DateTime(start.year, start.month, start.day + i));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInActivePlan(DateTime date) {
    final p = _plan; if (p == null) return false;
    final start = DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
    final end = start.add(Duration(days: p.totalDays - 1));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  Future<bool> _isCompleted(DateTime date) async {
    if (!_isInActivePlan(date)) return false;
    try {
      final planDay = await _getPlanDayForDate(date);
      return planDay?.completed ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<PlanDay?> _getPlanDayForDate(DateTime date) async {
    final p = _plan; if (p == null) return null;
    final idx = date.difference(DateTime(p.startDate.year, p.startDate.month, p.startDate.day)).inDays + 1;
    if (idx < 1 || idx > p.totalDays) return null;
    try {
      final planDays = await bootstrap.planService.getPlanDays(p.id);
      final dayData = planDays.firstWhere(
        (day) => day.dayIndex == idx,
        orElse: () => PlanDay(
          id: '${p.id}_$idx', planId: p.id, dayIndex: idx, date: date, completed: false, readings: [],
        ),
      );
      return dayData;
    } catch (e) {
      debugPrint('⚠️ getPlanDayForDate($idx): $e');
      return PlanDay(
        id: '${p.id}_$idx', planId: p.id, dayIndex: idx, date: date, completed: false, readings: [],
      );
    }
  }

  void _openDaySheet(DateTime date, PlanDay? planDay) {
    // TODO: Implémenter showPlanDaySheet ou créer un dialog temporaire
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Jour ${planDay?.dayIndex ?? '?'}'),
        content: Text('Date: ${date.day}/${date.month}/${date.year}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (planDay != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/reader', extra: {
                  'dayTitle': 'Jour ${planDay.dayIndex}',
                });
              },
              child: const Text('Lire'),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _GlassAppBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: const Color(0xFF0F172A).withOpacity(0.65),
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
        ),
      ),
      leading: IconButton(
        onPressed: onClose,
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }
}

class _HeaderStrip extends StatelessWidget {
  final DateTime month; final VoidCallback onPrev; final VoidCallback onNext;
  const _HeaderStrip({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    const months = ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    final title = '${months[month.month - 1]} ${month.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(
            fontFamily: 'Gilroy', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
          )),
          const Spacer(),
          _RoundIcon(onTap: onPrev, icon: Icons.chevron_left_rounded),
          const SizedBox(width: 8),
          _RoundIcon(onTap: onNext, icon: Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final VoidCallback onTap; final IconData icon;
  const _RoundIcon({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _WeekdayStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labels = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: labels.map((t) => Expanded(
          child: Center(
            child: Text(t, style: const TextStyle(
              fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60,
            )),
          ),
        )).toList(),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final double progress; final int daysDone; final int daysTotal; final VoidCallback? onResumeToday;
  const _StatsCard({required this.progress, required this.daysDone, required this.daysTotal, this.onResumeToday});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final remaining = (daysTotal - daysDone).clamp(0, daysTotal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1F2A61), Color(0xFF4C1D95)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4C1D95).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            // Gauge simple
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64, height: 64,
                  child: CircularProgressIndicator(
                    value: progress.isNaN ? 0 : progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                  ),
                ),
                Text('$percent%', style: const TextStyle(
                  fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white,
                )),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progression du plan', style: TextStyle(
                    fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70,
                  )),
                  const SizedBox(height: 6),
                  Text('$daysDone / $daysTotal jours', style: const TextStyle(
                    fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                  )),
                  const SizedBox(height: 2),
                  Text('$remaining jours restants', style: const TextStyle(
                    fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60,
                  )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onResumeToday,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Aujourd\'hui'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool dimmed;
  final bool inPlan;
  final Future<bool> completedFuture;
  final VoidCallback onTap;
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.dimmed,
    required this.inPlan,
    required this.completedFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = isToday ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.10);
    final selectedColor = const Color(0xFF1553FF);

    final bg = isSelected
        ? selectedColor
        : isToday
            ? Colors.white.withOpacity(0.10)
            : inPlan
                ? Colors.white.withOpacity(0.04)
                : Colors.transparent;

    final textColor = isSelected
        ? Colors.white
        : dimmed
            ? Colors.white30
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? selectedColor : baseBorder, width: 1),
        ),
        child: FutureBuilder<bool>(
          future: completedFuture,
          builder: (context, snap) {
            final completed = snap.data ?? false;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${date.day}', style: TextStyle(
                    fontFamily: 'Gilroy', fontSize: 16,
                    fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                  )),
                  if (inPlan)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 12,
                        color: completed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _JumpTodayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _JumpTodayButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.today_rounded),
      label: const Text('Aujourd\'hui'),
    );
  }
}
