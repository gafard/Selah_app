import 'package:http/http.dart' as http;
import '../domain/plan_repo.dart';

class PlanServiceHttp implements PlanRepo {
  final http.Client _client;
  
  PlanServiceHttp(this._client);

  @override
  Future<List<WeekCell>> getWeekOverview({required DateTime date}) async {
    // GET /plans/week?date=YYYY-MM-DD
    final base = _startOfWeek(date);
    const names = ['Dim','Lun','Mar','Mer','Jeu','Ven','Sam'];
    
    // Mock pour l'instant - dans une vraie implémentation, on ferait un appel API
    return List.generate(7, (i) {
      final d = base.add(Duration(days: i));
      return WeekCell(
        day: names[i],
        date: d.day,
        isToday: _isSameDay(d, date),
        hasPlannedReading: i != 6, // Pas de lecture le dimanche
        done: _isSameDay(d, date) ? false : i % 3 == 0, // Mock des tâches terminées
      );
    });
  }

  @override
  Future<List<PlanTask>> getTodayTasks({required DateTime date}) async {
    // GET /plans/today
    // Mock pour l'instant
    return [
      PlanTask(id: 't1', passageRef: 'Jean 3:16-21', done: false),
      PlanTask(id: 't2', passageRef: 'Psaume 23', done: true),
      PlanTask(id: 't3', passageRef: 'Matthieu 5:1-12', done: false),
    ];
  }

  @override
  Future<HeroOfDay?> getHeroOfDay({required DateTime date}) async {
    // Optionnel : image de couverture du plan du jour
    return HeroOfDay('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=300&fit=crop');
  }

  @override
  Future<void> startReading({required String taskId}) async {
    // POST /plans/task/{id}/start
    // Mock pour l'instant
    await Future.delayed(const Duration(milliseconds: 100));
  }

  DateTime _startOfWeek(DateTime d) => d.subtract(Duration(days: d.weekday % 7));
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}