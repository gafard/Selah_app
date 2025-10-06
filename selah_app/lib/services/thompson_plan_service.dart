import 'package:hive/hive.dart';
import '../models/thompson_plan_models.dart';
import 'thompson_plan_generator.dart';
import 'image_service.dart';

/// Service pour gérer les plans Thompson 21
/// Gère la génération, la persistance et la synchronisation des plans
class ThompsonPlanService {
  static const String _boxName = 'thompson_plans';
  static const String _currentPlanKey = 'current_plan';
  static const String _userProfileKey = 'user_profile';
  
  late Box<Map> _box;
  final ThompsonPlanGenerator _generator;
  final ImageService _imageService;

  ThompsonPlanService({
    required ImageService imageService,
  }) : _imageService = imageService,
       _generator = ThompsonPlanGenerator(imageFor: (key) => ImageService.getImage(key));

  /// Initialise le service
  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  /// Génère et sauvegarde un plan Thompson basé sur le profil utilisateur
  static Future<ThompsonPlanPreset> generateAndSave(CompleteProfile profile) async {
    final imageService = ImageService();
    final service = ThompsonPlanService(imageService: imageService);
    await service.initialize();
    
    return await service.generatePlan(profile);
  }

  /// Génère un nouveau plan Thompson
  Future<ThompsonPlanPreset> generatePlan(CompleteProfile profile) async {
    print('🎯 Génération plan Thompson pour profil: ${profile.goals.join(", ")}');
    
    final plan = _generator.build(profile);
    
    // Sauvegarder le plan
    await savePlan(plan);
    
    // Marquer comme plan actuel
    await setCurrentPlan(plan.id);
    
    // Sauvegarder le profil utilisateur
    await saveUserProfile(profile);
    
    print('✅ Plan Thompson sauvegardé: ${plan.title}');
    return plan;
  }

  /// Sauvegarde un plan Thompson
  Future<void> savePlan(ThompsonPlanPreset plan) async {
    await _box.put(plan.id, plan.toMap());
    print('💾 Plan sauvegardé: ${plan.id}');
  }

  /// Récupère un plan par son ID
  Future<ThompsonPlanPreset?> getPlan(String planId) async {
    final data = _box.get(planId);
    if (data == null) return null;
    
    return ThompsonPlanPreset.fromMap(Map<String, dynamic>.from(data));
  }

  /// Récupère tous les plans sauvegardés
  Future<List<ThompsonPlanPreset>> getAllPlans() async {
    final plans = <ThompsonPlanPreset>[];
    
    for (final key in _box.keys) {
      if (key == _currentPlanKey || key == _userProfileKey) continue;
      
      final data = _box.get(key);
      if (data != null) {
        try {
          plans.add(ThompsonPlanPreset.fromMap(Map<String, dynamic>.from(data)));
        } catch (e) {
          print('❌ Erreur parsing plan $key: $e');
        }
      }
    }
    
    return plans;
  }

  /// Définit le plan actuel
  Future<void> setCurrentPlan(String planId) async {
    await _box.put(_currentPlanKey, {'planId': planId, 'setAt': DateTime.now().toIso8601String()});
  }

  /// Récupère le plan actuel
  Future<ThompsonPlanPreset?> getCurrentPlan() async {
    final currentData = _box.get(_currentPlanKey);
    if (currentData == null) return null;
    
    final planId = currentData['planId'] as String?;
    if (planId == null) return null;
    
    return await getPlan(planId);
  }

  /// Sauvegarde le profil utilisateur
  Future<void> saveUserProfile(CompleteProfile profile) async {
    await _box.put(_userProfileKey, profile.toMap());
  }

  /// Récupère le profil utilisateur sauvegardé
  Future<CompleteProfile?> getUserProfile() async {
    final data = _box.get(_userProfileKey);
    if (data == null) return null;
    
    return CompleteProfile.fromUserPrefs(Map<String, dynamic>.from(data));
  }

  /// Supprime un plan
  Future<void> deletePlan(String planId) async {
    await _box.delete(planId);
    
    // Si c'était le plan actuel, le retirer
    final currentData = _box.get(_currentPlanKey);
    if (currentData != null && currentData['planId'] == planId) {
      await _box.delete(_currentPlanKey);
    }
  }

  /// Récupère la tâche du jour actuel
  Future<ThompsonPlanTask?> getTodayTask() async {
    final currentPlan = await getCurrentPlan();
    if (currentPlan == null) return null;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Trouver le jour correspondant
    for (final day in currentPlan.days) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      if (dayDate.isAtSameMomentAs(todayDate)) {
        // Retourner la première tâche non-préparation
        for (final task in day.tasks) {
          if (task.kind != ThompsonTaskKind.prepare) {
            return task;
          }
        }
        return day.tasks.isNotEmpty ? day.tasks.first : null;
      }
    }
    
    return null;
  }

  /// Récupère le jour actuel du plan
  Future<ThompsonPlanDay?> getTodayPlanDay() async {
    final currentPlan = await getCurrentPlan();
    if (currentPlan == null) return null;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Trouver le jour correspondant
    for (final day in currentPlan.days) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      if (dayDate.isAtSameMomentAs(todayDate)) {
        return day;
      }
    }
    
    return null;
  }

  /// Calcule le progrès du plan actuel
  Future<Map<String, dynamic>> getPlanProgress() async {
    final currentPlan = await getCurrentPlan();
    if (currentPlan == null) {
      return {
        'totalDays': 0,
        'completedDays': 0,
        'currentDay': 0,
        'progress': 0.0,
        'isActive': false,
      };
    }
    
    final today = DateTime.now();
    final startDate = currentPlan.startDate;
    final totalDays = currentPlan.durationDays;
    
    // Calculer le jour actuel (0-indexé)
    final daysSinceStart = today.difference(startDate).inDays;
    final currentDay = daysSinceStart.clamp(0, totalDays - 1);
    
    // Pour simplifier, on considère qu'un jour est "complété" s'il est passé
    final completedDays = daysSinceStart.clamp(0, totalDays);
    final progress = totalDays > 0 ? completedDays / totalDays : 0.0;
    
    return {
      'totalDays': totalDays,
      'completedDays': completedDays,
      'currentDay': currentDay,
      'progress': progress,
      'isActive': daysSinceStart >= 0 && daysSinceStart < totalDays,
      'planTitle': currentPlan.title,
      'themeKeys': currentPlan.meta['themeKeys'] as List<dynamic>? ?? [],
    };
  }

  /// Génère des statistiques d'usage
  Future<Map<String, dynamic>> getUsageStats() async {
    final plans = await getAllPlans();
    final currentPlan = await getCurrentPlan();
    final progress = await getPlanProgress();
    
    return {
      'totalPlans': plans.length,
      'currentPlanId': currentPlan?.id,
      'currentPlanTitle': currentPlan?.title,
      'progress': progress,
      'lastGenerated': plans.isNotEmpty 
          ? plans.map((p) => p.meta['generatedAt'] as String?).where((d) => d != null).toList()
          : [],
    };
  }

  /// Nettoie les anciens plans (garde seulement les 5 plus récents)
  Future<void> cleanupOldPlans() async {
    final plans = await getAllPlans();
    
    if (plans.length <= 5) return;
    
    // Trier par date de génération
    plans.sort((a, b) {
      final aTime = a.meta['generatedAt'] as String? ?? '';
      final bTime = b.meta['generatedAt'] as String? ?? '';
      return bTime.compareTo(aTime); // Plus récent en premier
    });
    
    // Supprimer les plans anciens (garder les 5 plus récents)
    final plansToDelete = plans.skip(5);
    for (final plan in plansToDelete) {
      await deletePlan(plan.id);
    }
    
    print('🧹 Nettoyage: ${plansToDelete.length} anciens plans supprimés');
  }

  /// Ferme le service
  Future<void> close() async {
    await _box.close();
  }
}