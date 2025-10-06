abstract class PlanRepo {
  Future<List<WeekCell>> getWeekOverview({required DateTime date});
  Future<List<PlanTask>> getTodayTasks({required DateTime date});
  Future<HeroOfDay?> getHeroOfDay({required DateTime date});
  Future<void> startReading({required String taskId});
}

class WeekCell {
  final String day; // Dim, Lun…
  final int date;
  final bool isToday;
  final bool hasPlannedReading;
  final bool done;
  
  WeekCell({
    required this.day,
    required this.date,
    required this.isToday,
    required this.hasPlannedReading,
    required this.done,
  });
}

class PlanTask {
  final String id;
  final String? passageRef;
  final bool done;
  
  PlanTask({
    required this.id,
    this.passageRef,
    required this.done,
  });
}

class HeroOfDay {
  final String imageUrl;
  
  HeroOfDay(this.imageUrl);
}