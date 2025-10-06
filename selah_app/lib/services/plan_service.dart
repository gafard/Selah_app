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
  Future<void> setActivePlan(String planId);
  Future<void> setDayCompleted(String planId, int dayIndex, bool completed);
  Stream<PlanProgress> watchProgress(String planId);
}