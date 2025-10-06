enum Level { newBeliever, regular, leader }
enum Goal  { discipline, deepenWord, prayer, faithGrowth, wholeBible }

class PlanProfile {
  final Level level;
  final Set<Goal> goals;
  final int minutesPerDay; // 10, 15, 20, 30...
  final int totalDays;     // 14, 30, 90, 365
  final DateTime startDate;

  PlanProfile({
    required this.level,
    required this.goals,
    required this.minutesPerDay,
    required this.totalDays,
    required this.startDate,
  });
}

