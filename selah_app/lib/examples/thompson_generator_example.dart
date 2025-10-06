import '../models/thompson_plan_models.dart';
import '../services/thompson_plan_service.dart';

/// Exemple d'utilisation du générateur Thompson
/// 
/// Usage:
/// ```dart
/// await ThompsonGeneratorExample.runExample();
/// ```
class ThompsonGeneratorExample {
  
  /// Exemple basique - génère un plan pour un utilisateur "growing"
  static Future<void> runBasicExample() async {
    print('🎯 === Exemple Thompson Generator ===');
    
    // Créer un profil complet
    final profile = CompleteProfile(
      language: 'fr',
      minutesPerDay: 12,
      daysPerWeek: 6,
      goals: ['discipline', 'anxiety', 'community'],
      experience: 'growing',
      prefersThemes: true,
      hasPhysicalBible: true,
      startDate: DateTime.now(),
    );
    
    // Générer et sauvegarder le preset
    final preset = await ThompsonPlanService.generateAndSave(profile);
    
    print('✅ Preset Thompson généré: ${preset.title}');
    print('📅 Durée: ${preset.durationDays} jours');
    print('🎯 Thèmes: ${preset.meta['themeKeys']}');
    print('📖 Première tâche: ${preset.days.first.tasks.first.title}');
    
    // Récupérer les tâches du jour
    final todayTasks = await ThompsonPlanService.getTodayTasks();
    if (todayTasks != null) {
      print('📋 Tâches d\'aujourd\'hui: ${todayTasks.length}');
      for (final task in todayTasks) {
        print('  - ${task.title} (${task.kind.name})');
        if (task.passageRef != null) {
          print('    📖 ${task.passageRef}');
        }
        if (task.payload?['prompt'] != null) {
          print('    💭 ${task.payload!['prompt']}');
        }
      }
    }
  }
  
  /// Exemple pour un nouveau converti
  static Future<void> runNewBelieverExample() async {
    print('🎯 === Exemple Nouveau Converti ===');
    
    final profile = CompleteProfile(
      language: 'fr',
      minutesPerDay: 8,
      daysPerWeek: 5,
      goals: ['discipline', 'prayer'],
      experience: 'new',
      prefersThemes: true,
      hasPhysicalBible: true,
      startDate: DateTime.now(),
    );
    
    final preset = await ThompsonPlanService.generateAndSave(profile);
    
    print('✅ Plan nouveau converti: ${preset.title}');
    print('📅 Durée: ${preset.durationDays} jours');
    print('⏱️ Minutes/jour: ${preset.meta['minutesPerDay']}');
    
    // Afficher les 3 premiers jours
    for (int i = 0; i < 3 && i < preset.days.length; i++) {
      final day = preset.days[i];
      print('\n📅 Jour ${i + 1} (${day.date.day}/${day.date.month}):');
      for (final task in day.tasks) {
        print('  - ${task.title}');
        if (task.passageRef != null) {
          print('    📖 ${task.passageRef}');
        }
      }
    }
  }
  
  /// Exemple pour un leader mature
  static Future<void> runMatureLeaderExample() async {
    print('🎯 === Exemple Leader Mature ===');
    
    final profile = CompleteProfile(
      language: 'fr',
      minutesPerDay: 25,
      daysPerWeek: 7,
      goals: ['discipline', 'wisdom', 'community', 'marriage'],
      experience: 'mature',
      prefersThemes: true,
      hasPhysicalBible: true,
      startDate: DateTime.now(),
    );
    
    final preset = await ThompsonPlanService.generateAndSave(profile);
    
    print('✅ Plan leader mature: ${preset.title}');
    print('📅 Durée: ${preset.durationDays} jours');
    print('⏱️ Minutes/jour: ${preset.meta['minutesPerDay']}');
    print('🎯 Objectifs: ${preset.meta['goals']}');
    
    // Compter les types de tâches
    final taskCounts = <String, int>{};
    for (final day in preset.days) {
      for (final task in day.tasks) {
        taskCounts[task.kind.name] = (taskCounts[task.kind.name] ?? 0) + 1;
      }
    }
    
    print('\n📊 Répartition des tâches:');
    taskCounts.forEach((kind, count) {
      print('  - $kind: $count tâches');
    });
  }
  
  /// Exemple avec objectif spécifique (mariage)
  static Future<void> runMarriageExample() async {
    print('🎯 === Exemple Objectif Mariage ===');
    
    final profile = CompleteProfile(
      language: 'fr',
      minutesPerDay: 15,
      daysPerWeek: 6,
      goals: ['marriage', 'community'],
      experience: 'growing',
      prefersThemes: true,
      hasPhysicalBible: true,
      startDate: DateTime.now(),
    );
    
    final preset = await ThompsonPlanService.generateAndSave(profile);
    
    print('✅ Plan mariage: ${preset.title}');
    print('📅 Durée: ${preset.durationDays} jours');
    
    // Chercher les références bibliques liées au mariage
    final marriageRefs = <String>{};
    for (final day in preset.days) {
      for (final task in day.tasks) {
        if (task.passageRef != null && 
            (task.passageRef!.contains('Gn 2') || 
             task.passageRef!.contains('Ep 5') || 
             task.passageRef!.contains('1P 3'))) {
          marriageRefs.add(task.passageRef!);
        }
      }
    }
    
    print('\n💒 Références mariage trouvées:');
    for (final ref in marriageRefs) {
      print('  - $ref');
    }
  }
  
  /// Exécute tous les exemples
  static Future<void> runAllExamples() async {
    await runBasicExample();
    print('\n${'='*50}\n');
    
    await runNewBelieverExample();
    print('\n${'='*50}\n');
    
    await runMatureLeaderExample();
    print('\n${'='*50}\n');
    
    await runMarriageExample();
    
    print('\n🎉 Tous les exemples terminés !');
  }
}

