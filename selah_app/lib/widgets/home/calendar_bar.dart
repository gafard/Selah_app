import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../bootstrap.dart' as bootstrap;
import '../../services/home_vm.dart';

class CalendarBar extends StatefulWidget {
  final String? planId;
  
  const CalendarBar({super.key, this.planId});
  
  @override
  State<CalendarBar> createState() => _CalendarBarState();
}

class _CalendarBarState extends State<CalendarBar> {
  Map<DateTime, bool> _completedDays = {};
  bool _isLoading = true;
  
  /// Méthode publique pour rafraîchir le calendrier
  void refreshCalendar() {
    if (mounted) {
      _loadCompletedDays();
    }
  }
  
  @override
  void initState() {
    super.initState();
    _loadCompletedDays();
  }
  
  @override
  void didUpdateWidget(CalendarBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planId != widget.planId) {
      _loadCompletedDays();
    }
  }
  
  /// Rafraîchir le calendrier manuellement
  void refresh() {
    _loadCompletedDays();
  }
  
  Future<void> _loadCompletedDays() async {
    if (widget.planId == null) {
      setState(() {
        _completedDays = {};
        _isLoading = false;
      });
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      // Récupérer le plan pour calculer les indices des jours
      final plan = await bootstrap.planService.getActivePlan();
      if (plan == null) {
        setState(() {
          _completedDays = {};
          _isLoading = false;
        });
        return;
      }
      
      final completedDays = <DateTime, bool>{};
      
      // Charger les 7 jours de la semaine
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dayIndex = date.difference(plan.startDate).inDays + 1;
        
        if (dayIndex >= 1 && dayIndex <= plan.totalDays) {
          try {
            final days = await bootstrap.planService.getPlanDays(
              widget.planId!, 
              fromDay: dayIndex, 
              toDay: dayIndex
            );
            completedDays[date] = days.isNotEmpty ? days.first.completed : false;
          } catch (e) {
            completedDays[date] = false;
          }
        } else {
          completedDays[date] = false;
        }
      }
      
      setState(() {
        _completedDays = completedDays;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement jours complétés: $e');
      setState(() {
        _completedDays = {};
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeVM>(
      builder: (context, homeVM, child) {
        // Rafraîchir les données quand HomeVM notifie un changement
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadCompletedDays();
          }
        });
        return _buildCalendarRow();
      },
    );
  }
  
  Widget _buildCalendarRow() {
    const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final now = DateTime.now();
    
    return Row(
      children: List.generate(7, (i) {
        final date = now.subtract(Duration(days: now.weekday - 1 - i));
        final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
        final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
        final isCompleted = _completedDays[date] ?? false;
        
        // Déterminer l'icône et la couleur selon l'état
        IconData iconData;
        Color iconColor;
        
        if (isToday) {
          if (isCompleted) {
            iconData = Icons.check_circle;
            iconColor = Colors.white;
          } else {
            iconData = Icons.radio_button_checked;
            iconColor = Colors.white70;
          }
        } else if (isPast) {
          if (isCompleted) {
            iconData = Icons.check_circle;
            iconColor = const Color(0xFF10B981);
          } else {
            iconData = Icons.close;
            iconColor = const Color(0xFFEF4444);
          }
        } else {
          // Jour futur
          iconData = Icons.radio_button_unchecked;
          iconColor = Colors.white30;
        }
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: isToday ? 1 : 2),
            padding: EdgeInsets.symmetric(
              vertical: isToday ? 12 : 10, 
              horizontal: isToday ? 8 : 6
            ),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF1553FF) : Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isToday ? Colors.transparent : Colors.white.withOpacity(.14)),
            ),
            child: Column(children: [
              Text(dayNames[i], style: TextStyle(fontFamily: 'Gilroy', fontSize: 10, color: isToday ? Colors.white : Colors.white70)),
              const SizedBox(height: 4),
              Text('${date.day}', style: TextStyle(fontFamily: 'Gilroy', fontSize: isToday ? 16 : 14, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600, color: isToday ? Colors.white : Colors.white)),
              const SizedBox(height: 2),
              _isLoading 
                ? const SizedBox(
                    width: 10, 
                    height: 10, 
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                    )
                  )
                : Icon(iconData, size: 10, color: iconColor),
            ]),
          ),
        );
      }),
    );
  }
}