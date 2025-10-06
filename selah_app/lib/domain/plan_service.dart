import '../models/plan.dart';

/// Contrat pour la gestion des plans de lecture
abstract class PlanService {
  Future<Plan?> getById(String id);
  Future<void> regenerateFromGenerator({
    required String userId,
    required String planId,
    required Uri generatorIcsUrl,
  });
}

