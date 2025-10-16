/// Interface abstraite pour les services de plans
/// Implémentée par PlanServiceHttp (offline-first avec Hive)
library;
import '../models/plan_models.dart';

abstract class PlanService {
  Future<Plan?> getActivePlan();
  Future<Plan?> getActiveLocalPlan(); // ✅ NOUVEAU - Read-back atomique
  Future<List<PlanDay>> getPlanDays(String planId, {int? fromDay, int? toDay});
  Future<void> setActivePlan(String planId);
  Future<void> setDayCompleted(String planId, int dayIndex, bool completed);
  Stream<PlanProgress> watchProgress(String planId);
  Future<void> archivePlan(String planId);
  Future<void> restartPlanFromDay1(String planId);
  Future<void> rescheduleFromToday(String planId);
  
  Future<Plan> createLocalPlan({
    required String name,
    required int totalDays,
    required DateTime startDate,
    required String books,
    String? specificBooks,
    required int minutesPerDay,
    List<Map<String, dynamic>>? customPassages,
    List<int>? daysOfWeek,
  });
}
