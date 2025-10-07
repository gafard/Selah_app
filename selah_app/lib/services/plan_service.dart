import '../models/plan_models.dart';

abstract class PlanService {
  Future<Plan?> getActivePlan();
  Future<List<PlanDay>> getPlanDays(String planId, {int? fromDay, int? toDay});
  Future<Plan> createFromPreset({
    required String presetSlug,
    required DateTime startDate,
    required Map<String, dynamic> profile, // profil complet -> pour "super intelligente"
  });
  Future<Plan> importFromGenerator({
    required String planName,
    required Uri icsUrl,
  });
  Future<Plan> createLocalPlan({
    required String name,
    required int totalDays,
    required DateTime startDate,
    required String books,
    String? specificBooks,
    required int minutesPerDay,
    List<Map<String, dynamic>>? customPassages,
  });
  Future<void> setActivePlan(String planId);
  Future<void> setDayCompleted(String planId, int dayIndex, bool completed);
  Stream<PlanProgress> watchProgress(String planId);
}