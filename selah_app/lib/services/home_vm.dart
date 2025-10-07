import 'package:flutter/foundation.dart';
import '../services/user_prefs_hive.dart';
import '../services/telemetry_console.dart';
import '../services/plan_service.dart';
import '../models/plan_models.dart';

class TodayReading {
  final Plan plan;
  final PlanDay? today;
  TodayReading({required this.plan, required this.today});
}

class HomeState {
  final String firstName;
  final int tasksDone;
  final int tasksTotal;
  HomeState({required this.firstName, required this.tasksDone, required this.tasksTotal});
  HomeState copyWith({String? firstName, int? tasksDone, int? tasksTotal}) =>
      HomeState(firstName: firstName ?? this.firstName, tasksDone: tasksDone ?? this.tasksDone, tasksTotal: tasksTotal ?? this.tasksTotal);
  factory HomeState.initial() => HomeState(firstName: 'Ami', tasksDone: 0, tasksTotal: 1);
}

class HomeVM extends ChangeNotifier {
  final UserPrefsHive prefs;
  final TelemetryConsole telemetry;
  final PlanService planService;

  HomeState state = HomeState.initial();
  TodayReading? today;

  HomeVM({required this.prefs, required this.telemetry, required this.planService});


  Future<void> load() async {
    final p = prefs.profile;
    final display = (p['display_name'] ?? 'Ami') as String;
    state = state.copyWith(firstName: display.split(' ').first);
    notifyListeners();

    final plan = await planService.getActivePlan();
    if (plan != null) {
      final dayIndex = DateTime.now().difference(plan.startDate).inDays + 1;
      final days = await planService.getPlanDays(plan.id, fromDay: dayIndex, toDay: dayIndex);
      today = TodayReading(plan: plan, today: days.isEmpty ? null : days.first);
      notifyListeners();

      planService.watchProgress(plan.id).listen((p) {
        state = state.copyWith(tasksDone: p.done, tasksTotal: p.total);
        notifyListeners();
      });
    }
  }

  Future<void> toggleTodayCompleted() async {
    if (today?.today == null) return;
    final d = today!.today!;
    await planService.setDayCompleted(d.planId, d.dayIndex, !d.completed);
  }
}