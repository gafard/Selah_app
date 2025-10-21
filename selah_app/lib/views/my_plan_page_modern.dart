// MyPlanPageModern — style Selah (glass + accent bleu), inspiré du calendrier Android
// - SliverAppBar translucide (blur)
// - Carte récap empilée (stack) + bouton "Aujourd'hui"
// - Grille 6x7 modernisée (états: hors mois, dans plan, aujourd'hui, terminé, sélectionné)
// - Scroll to today, haptics, micro-animations
// - Conserve la logique: planService, show dialog day, GoRouter '/reader'

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../bootstrap.dart' as bootstrap;
import '../models/plan_models.dart';

class MyPlanPageModern extends StatefulWidget {
  const MyPlanPageModern({super.key});
  @override
  State<MyPlanPageModern> createState() => _MyPlanPageModernState();
}

class _MyPlanPageModernState extends State<MyPlanPageModern> {
  // ─── State ───────────────────────────────────────────────────────────────────
  DateTime _monthAnchor = DateTime(DateTime.now().year, DateTime.now().month);
  late List<DateTime> _visible42; // cache de la grille (6 semaines)
  DateTime? _selected;
  Plan? _plan;

  // Stats
  double _progress = 0;
  int _daysDone = 0;
  int _daysTotal = 0;

  // Cache pour optimiser les performances
  List<PlanDay> _planDays = const [];
  Map<int, PlanDay> _byIndex = {}; // dayIndex -> PlanDay
  bool _refreshing = false;

  final ScrollController _scroll = ScrollController();

  // ─── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _visible42 = _compute42Days(_monthAnchor);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadActivePlan();
    await _refreshDaysAndStats();
  }

  Future<void> _loadActivePlan() async {
    try {
      final plan = await bootstrap.planService.getActivePlan();
      if (!mounted) return;
      if (plan == null) {
        setState(() {
          _plan = null;
          _progress = 0;
          _daysDone = 0;
          _daysTotal = 0;
        });
        return;
      }

      setState(() {
        _plan = plan;
        _daysTotal = plan.totalDays;
        _selected ??= DateTime.now();
      });
    } catch (e) {
      debugPrint('❌ loadActivePlan: $e');
    }
  }

  Future<void> _refreshDaysAndStats() async {
    final p = _plan;
    if (p == null) return;
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      // 1) Charger tous les jours du plan (depuis planService)
      final days = await bootstrap.planService.getPlanDays(p.id);

      // 2) Index rapide pour accès O(1) depuis la grille
      final byIdx = <int, PlanDay>{ for (final d in days) d.dayIndex : d };

      // 3) Compter les "vrais" jours complétés
      final completed = days.where((d) => d.completed == true).length;

      // 4) Mettre à jour les stats
      setState(() {
        _planDays = days;
        _byIndex = byIdx;
        _daysDone = completed;
        _progress = (_daysTotal == 0) ? 0 : (_daysDone / _daysTotal);
      });
    } catch (e) {
      debugPrint('❌ refreshDaysAndStats: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String title = _plan?.name ?? 'Mon plan';
    final bool hasPlan = _plan != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1025), // fond Selah
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        onRefresh: _refreshDaysAndStats,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
          _GlassAppBar(title: title, onClose: () => context.pop()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Header mois + flèches
          SliverToBoxAdapter(
            child: _HeaderStrip(
              month: _monthAnchor,
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Carte stats empilée + CTA aujourd'hui
          SliverToBoxAdapter(
            child: _StatsStackCard(
              progress: _progress,
              daysDone: _daysDone,
              daysTotal: _daysTotal,
              hasPlan: hasPlan,
              onResumeToday: hasPlan ? _resumeToday : null,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: _WeekdayStrip()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final d = _visible42[i];
                  final isInMonth = d.month == _monthAnchor.month;
                  final isToday = _sameDay(d, DateTime.now());
                  final isSelected = _selected != null && _sameDay(d, _selected!);
                  final inPlan = _isInActivePlan(d);

                  return _DayCell(
                    date: d,
                    dimmed: !isInMonth,
                    isToday: isToday,
                    isSelected: isSelected,
                    inPlan: inPlan,
                    // on-demand check (évite N requêtes si hors plan)
                    completedFuture: inPlan ? _isCompleted(d) : Future.value(false),
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
      ),
      floatingActionButton: _JumpTodayButton(onTap: _jumpToToday),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────
  void _changeMonth(int delta) {
    setState(() {
      _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month + delta);
      _visible42 = _compute42Days(_monthAnchor);
      // si le mois affiché contient aujourd'hui, placer la sélection dessus pour le feedback
      final today = DateTime.now();
      if (_monthAnchor.year == today.year && _monthAnchor.month == today.month) {
        _selected = today;
      }
    });
  }

  Future<void> _jumpToToday() async {
    setState(() {
      _monthAnchor = DateTime(DateTime.now().year, DateTime.now().month);
      _visible42 = _compute42Days(_monthAnchor);
      _selected = DateTime.now();
    });
    await Future.delayed(const Duration(milliseconds: 160));
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  Future<void> _resumeToday() async {
    final today = DateTime.now();
    final planDay = await _getPlanDayForDate(today);
    if (!mounted) return;
    _openDaySheet(today, planDay);
  }

  // ─── Logic ───────────────────────────────────────────────────────────────────
  List<DateTime> _compute42Days(DateTime anchor) {
    final first = DateTime(anchor.year, anchor.month, 1);
    final startOffset = (first.weekday + 6) % 7; // lundi=0
    final start = first.subtract(Duration(days: startOffset));
    return List.generate(42, (i) => DateTime(start.year, start.month, start.day + i));
  }

  bool _sameDay(DateTime a, DateTime b)
    => a.year == b.year && a.month == b.month && a.day == b.day;

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
    final start = DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
    final idx = date.difference(start).inDays + 1;
    if (idx < 1 || idx > p.totalDays) return null;

    // ⚡ d'abord en mémoire
    final cached = _byIndex[idx];
    if (cached != null) return cached;

    // 🔁 fallback : charger (utile si _refreshDaysAndStats pas encore passé)
    try {
      final planDays = await bootstrap.planService.getPlanDays(p.id);
      final byIdx = <int, PlanDay>{ for (final d in planDays) d.dayIndex : d };
      setState(() {
        _planDays = planDays;
        _byIndex = byIdx;
        _daysDone = planDays.where((d) => d.completed).length;
        _progress = (_daysTotal == 0) ? 0 : (_daysDone / _daysTotal);
      });
      return byIdx[idx];
    } catch (e) {
      debugPrint('⚠️ getPlanDayForDate($idx): $e');
      return PlanDay(
        id: '${p.id}_$idx',
        planId: p.id,
        dayIndex: idx,
        date: date,
        completed: false,
        readings: const [],
      );
    }
  }

  void _openDaySheet(DateTime date, PlanDay? planDay) {
    // Dialog provisoire (tu pourras brancher ton vrai bottom sheet)
    showDialog(
      context: context,
      builder: (context) {
        final idx = planDay?.dayIndex;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121737).withOpacity(0.85),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idx != null ? 'Jour $idx' : 'Hors plan',
                      style: const TextStyle(
                        fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontFamily: 'Gilroy', fontSize: 14, color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.25)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Fermer', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (planDay != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.go('/reader', extra: {
                                  'dayTitle': 'Jour ${planDay.dayIndex}',
                                  'planId': _plan!.id,
                                  'dayNumber': planDay.dayIndex,
                                });
                              },
                              icon: const Icon(Icons.menu_book_rounded),
                              label: const Text('Lire'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1553FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets (adaptés au design Selah)
// ─────────────────────────────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget {
  final String title; final VoidCallback onClose;
  const _GlassAppBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true, elevation: 0, backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: const Color(0xFF0B1025).withOpacity(0.7)),
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
      actions: const [
        SizedBox(width: 8),
      ],
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
      onTap: onTap, radius: 24,
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
  const _WeekdayStrip();
  @override
  Widget build(BuildContext context) {
    const labels = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: labels.map((t) => Expanded(
          child: Center(
            child: Text(t, style: const TextStyle(
              fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white60,
            )),
          ),
        )).toList(),
      ),
    );
  }
}

class _StatsStackCard extends StatelessWidget {
  final double progress; final int daysDone; final int daysTotal; final VoidCallback? onResumeToday; final bool hasPlan;
  const _StatsStackCard({required this.progress, required this.daysDone, required this.daysTotal, required this.hasPlan, this.onResumeToday});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final remaining = (daysTotal - daysDone).clamp(0, daysTotal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ombres empilées façon "cartes"
          Positioned(
            left: 12, right: 12, bottom: -10,
            child: _shadowBar(opacity: .30),
          ),
          Positioned(
            left: 24, right: 24, bottom: -18,
            child: _shadowBar(opacity: .18, height: 10),
          ),

          // Carte principale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                // Gauge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64, height: 64,
                      child: CircularProgressIndicator(
                        value: progress.isNaN ? 0 : progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF49C98D)),
                      ),
                    ),
                    Text('$percent%', style: const TextStyle(
                      fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white,
                    )),
                  ],
                ),
                const SizedBox(width: 16),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progression du plan', style: TextStyle(
                        fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70,
                      )),
                      const SizedBox(height: 6),
                      Text('$daysDone / $daysTotal jours', style: const TextStyle(
                        fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                      )),
                      const SizedBox(height: 2),
                      Text('$remaining jours restants', style: const TextStyle(
                        fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white60,
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: hasPlan ? onResumeToday : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1553FF),
                    disabledBackgroundColor: const Color(0xFF1553FF).withOpacity(0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Aujourd\'hui', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shadowBar({double opacity = .25, double height = 12}) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(12),
    ),
  );
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
    const Color sel = Color(0xFF1553FF);
    final Color baseBorder = isToday ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.12);

    final bg = isSelected
        ? sel
        : isToday
            ? Colors.white.withOpacity(0.10)
            : inPlan
                ? Colors.white.withOpacity(0.04)
                : Colors.transparent;

    final textColor = isSelected ? Colors.white : (dimmed ? Colors.white30 : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? sel : baseBorder, width: 1),
        ),
        child: FutureBuilder<bool>(
          future: completedFuture,
          builder: (context, snap) {
            final completed = snap.data ?? false;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (inPlan)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 12,
                        color: completed ? const Color(0xFF49C98D) : const Color(0xFFF59E0B),
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
      label: const Text('Aujourd\'hui', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w800)),
    );
  }
}