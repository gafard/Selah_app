import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/plan_day.dart';
import 'local_storage_service.dart';

/// Helper pour comparer dates calendaires (Y/M/D uniquement)
DateTime _atStartOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Service de rattrapage intelligent pour les jours manqués
/// 
/// Fonctionnalités :
/// 1. Détecte automatiquement les jours manqués
/// 2. Marque comme "skipped" les jours passés non complétés
/// 3. Recale le calendrier pour rattraper
/// 4. Propose des options de rattrapage flexibles
/// 
/// Modes de rattrapage :
/// - CATCH_UP : Ajoute les jours manqués à la fin
/// - RESCHEDULE : Décale tout le planning
/// - SKIP : Ignore les jours manqués et continue
/// - FLEXIBLE : Mix intelligent selon contexte
class PlanCatchupService {
  
  /// Vérifie si des jours ont été manqués pour un plan
  /// 
  /// [planId] : ID du plan
  /// [planDays] : Liste complète des jours du plan
  /// 
  /// Retourne : Liste des jours manqués
  static List<PlanDay> detectMissedDays({
    required String planId,
    required List<PlanDay> planDays,
  }) {
    final todayYMD = _atStartOfDay(DateTime.now());
    final missedDays = <PlanDay>[];
    
    for (final day in planDays) {
      final dayYMD = _atStartOfDay(day.date);
      // Si le jour est dans le passé (calendaire) et pas complété → manqué
      if (dayYMD.isBefore(todayYMD) && day.status == 'pending') {
        missedDays.add(day);
      }
    }
    
    if (missedDays.isNotEmpty) {
      print('⚠️ ${missedDays.length} jour(s) manqué(s) détecté(s) pour le plan $planId');
    }
    
    return missedDays;
  }
  
  /// Marque les jours manqués comme "skipped"
  /// 
  /// [planId] : ID du plan
  /// [missedDays] : Liste des jours manqués
  /// 
  /// Retourne : Nombre de jours marqués
  static Future<int> markMissedDaysAsSkipped({
    required String planId,
    required List<PlanDay> missedDays,
  }) async {
    int markedCount = 0;
    
    for (final day in missedDays) {
      try {
        // Récupérer la progression actuelle
        final progress = LocalStorageService.getDayProgress(planId, day.dayNumber) ?? {};
        
        // Marquer comme skipped
        progress['status'] = 'skipped';
        progress['skipped_at'] = DateTime.now().toIso8601String();
        progress['reason'] = 'auto_detected_missed';
        
        // Sauvegarder
        await LocalStorageService.saveDayProgress(planId, day.dayNumber, progress);
        
        markedCount++;
      } catch (e) {
        print('⚠️ Erreur marquage jour ${day.dayNumber}: $e');
      }
    }
    
    print('✅ $markedCount jour(s) marqué(s) comme skipped');
    return markedCount;
  }
  
  /// Recale le calendrier du plan selon le mode de rattrapage
  /// 
  /// [planId] : ID du plan
  /// [planDays] : Liste complète des jours
  /// [missedDays] : Jours manqués
  /// [mode] : Mode de rattrapage
  /// 
  /// Retourne : Liste des jours recalés
  static Future<List<PlanDay>> reschedule({
    required String planId,
    required List<PlanDay> planDays,
    required List<PlanDay> missedDays,
    required CatchupMode mode,
  }) async {
    print('🔄 Recalage du calendrier (mode: ${mode.name})...');
    
    switch (mode) {
      case CatchupMode.catchUp:
        return await _catchUpMode(planId, planDays, missedDays);
        
      case CatchupMode.reschedule:
        return await _rescheduleMode(planId, planDays);
        
      case CatchupMode.skip:
        return await _skipMode(planId, planDays, missedDays);
        
      case CatchupMode.flexible:
        return await _flexibleMode(planId, planDays, missedDays);
    }
  }
  
  /// Mode CATCH_UP : Ajoute les jours manqués à la fin du plan
  static Future<List<PlanDay>> _catchUpMode(
    String planId,
    List<PlanDay> planDays,
    List<PlanDay> missedDays,
  ) async {
    print('  📅 Mode CATCH_UP: Ajout de ${missedDays.length} jour(s) à la fin');
    
    // 1. Marquer les jours manqués
    await markMissedDaysAsSkipped(planId: planId, missedDays: missedDays);
    
    // 2. Trouver la date de fin actuelle
    final lastDay = planDays.last;
    var nextDate = lastDay.date.add(const Duration(days: 1));
    
    // 3. Ajouter les jours manqués à la fin
    final catchupDays = <PlanDay>[];
    final planIdInt = int.tryParse(planId) ?? 0;
    final now = DateTime.now();
    
    for (final missedDay in missedDays) {
      final newDay = PlanDay(
        id: null, // ID auto-généré par la base
        planId: planIdInt,
        dayNumber: planDays.length + catchupDays.length + 1,
        date: nextDate,
        bibleReferences: missedDay.bibleReferences,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      
      catchupDays.add(newDay);
      nextDate = nextDate.add(const Duration(days: 1));
    }
    
    print('  ✅ ${catchupDays.length} jour(s) de rattrapage ajoutés');
    return [...planDays, ...catchupDays];
  }
  
  /// Mode RESCHEDULE : Décale tous les jours restants
  static Future<List<PlanDay>> _rescheduleMode(
    String planId,
    List<PlanDay> planDays,
  ) async {
    print('  📅 Mode RESCHEDULE: Décalage de tous les jours restants');
    
    final today = DateTime.now();
    final rescheduled = <PlanDay>[];
    var currentDate = today;
    
    for (final day in planDays) {
      // Si déjà complété, garder tel quel
      if (day.status == 'completed') {
        rescheduled.add(day);
        continue;
      }
      
      // Si dans le passé et non complété, marquer skipped
      if (day.date.isBefore(today)) {
        final skippedDay = day.copyWith(
          status: 'skipped',
        );
        rescheduled.add(skippedDay);
        
        // Sauvegarder le statut
        final progress = LocalStorageService.getDayProgress(planId, day.dayNumber) ?? {};
        progress['status'] = 'skipped';
        await LocalStorageService.saveDayProgress(planId, day.dayNumber, progress);
        continue;
      }
      
      // Recaler les jours futurs
      final rescheduledDay = day.copyWith(
        date: currentDate,
      );
      rescheduled.add(rescheduledDay);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    print('  ✅ Planning recalé (nouveau dernier jour: ${DateFormat('dd/MM/yyyy').format(currentDate)})');
    return rescheduled;
  }
  
  /// Mode SKIP : Ignore les jours manqués et continue normalement
  static Future<List<PlanDay>> _skipMode(
    String planId,
    List<PlanDay> planDays,
    List<PlanDay> missedDays,
  ) async {
    print('  📅 Mode SKIP: Ignorer ${missedDays.length} jour(s) manqué(s)');
    
    // Simplement marquer comme skipped
    await markMissedDaysAsSkipped(planId: planId, missedDays: missedDays);
    
    // Retourner le plan tel quel
    return planDays.map((day) {
      final isMissed = missedDays.any((m) => m.dayNumber == day.dayNumber);
      return isMissed ? day.copyWith(status: 'skipped') : day;
    }).toList();
  }
  
  /// 🔄 RECOMMENCE LE PLAN DEPUIS LE JOUR 1
  /// Remet à zéro la progression et recalcule les dates
  static Future<void> restartPlanFromDay1(String planId) async {
    print('🔄 Recommencement du plan $planId depuis le jour 1...');
    
    try {
      // 1) Récupérer le plan actuel depuis le cache
      final planBox = Hive.box('plans');
      final planData = planBox.get('plan:$planId') as Map<String, dynamic>?;
      
      if (planData == null) {
        throw Exception('Plan non trouvé');
      }
      
      // 2) Récupérer tous les jours du plan
      final daysBox = Hive.box('plan_days');
      final daysData = daysBox.get('days:$planId') as List<dynamic>?;
      
      if (daysData == null || daysData.isEmpty) {
        throw Exception('Aucun jour trouvé pour ce plan');
      }
      
      final planDays = daysData.map((d) => PlanDay.fromJson(d as Map<String, dynamic>)).toList();
      
      // 3) Marquer TOUS les jours comme "pending" (remise à zéro)
      for (final day in planDays) {
        final progress = LocalStorageService.getDayProgress(planId, day.dayNumber) ?? {};
        progress['status'] = 'pending';
        progress['completed'] = false;
        progress['restarted_at'] = DateTime.now().toIso8601String();
        await LocalStorageService.saveDayProgress(planId, day.dayNumber, progress);
      }
      
      // 4) Recalculer les dates depuis aujourd'hui
      final today = _atStartOfDay(DateTime.now());
      final rescheduledDays = <PlanDay>[];
      var currentDate = today;
      
      for (final day in planDays) {
        final rescheduledDay = day.copyWith(
          date: currentDate,
          status: 'pending',
        );
        rescheduledDays.add(rescheduledDay);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      // 5) Sauvegarder les nouveaux jours
      await daysBox.put('days:$planId', rescheduledDays.map((d) => d.toJson()).toList());
      
      // 6) Mettre à jour la date de début du plan
      final updatedPlanData = Map<String, dynamic>.from(planData);
      updatedPlanData['start_date'] = today.toIso8601String();
      updatedPlanData['updated_at'] = DateTime.now().toIso8601String();
      await planBox.put('plan:$planId', updatedPlanData);
      
      print('✅ Plan $planId recommencé depuis le jour 1');
      print('📅 Nouvelle date de début: ${DateFormat('dd/MM/yyyy').format(today)}');
      
    } catch (e) {
      print('❌ Erreur recommencement plan: $e');
      rethrow;
    }
  }

  /// 📅 REPLANIFIE LE PLAN DEPUIS AUJOURD'HUI
  /// Garde les jours complétés, marque skipped les jours passés, recalcule le futur
  static Future<void> rescheduleFromToday(String planId) async {
    print('📅 Replanification du plan $planId depuis aujourd\'hui...');
    
    try {
      // 1) Récupérer le plan actuel depuis le cache
      final planBox = Hive.box('plans');
      final planData = planBox.get('plan:$planId') as Map<String, dynamic>?;
      
      if (planData == null) {
        throw Exception('Plan non trouvé');
      }
      
      // 2) Récupérer tous les jours du plan
      final daysBox = Hive.box('plan_days');
      final daysData = daysBox.get('days:$planId') as List<dynamic>?;
      
      if (daysData == null || daysData.isEmpty) {
        throw Exception('Aucun jour trouvé pour ce plan');
      }
      
      final planDays = daysData.map((d) => PlanDay.fromJson(d as Map<String, dynamic>)).toList();
      
      // 3) Utiliser le mode RESCHEDULE existant (parfait pour cette fonctionnalité)
      final rescheduledDays = await _rescheduleMode(planId, planDays);
      
      // 4) Sauvegarder les jours replanifiés
      await daysBox.put('days:$planId', rescheduledDays.map((d) => d.toJson()).toList());
      
      // 5) Mettre à jour la date de début du plan
      final today = _atStartOfDay(DateTime.now());
      final updatedPlanData = Map<String, dynamic>.from(planData);
      updatedPlanData['start_date'] = today.toIso8601String();
      updatedPlanData['updated_at'] = DateTime.now().toIso8601String();
      await planBox.put('plan:$planId', updatedPlanData);
      
      print('✅ Plan $planId replanifié depuis aujourd\'hui');
      print('📅 Nouvelle date de début: ${DateFormat('dd/MM/yyyy').format(today)}');
      
    } catch (e) {
      print('❌ Erreur replanification plan: $e');
      rethrow;
    }
  }

  /// Mode FLEXIBLE : Mix intelligent selon le contexte
  static Future<List<PlanDay>> _flexibleMode(
    String planId,
    List<PlanDay> planDays,
    List<PlanDay> missedDays,
  ) async {
    print('  📅 Mode FLEXIBLE: Analyse intelligente...');
    
    final missedCount = missedDays.length;
    final totalDays = planDays.length;
    final missedPercentage = (missedCount / totalDays * 100).round();
    
    // Logique intelligente
    if (missedPercentage <= 10) {
      // < 10% manqué → Catch up (peu de jours à rattraper)
      print('    → $missedPercentage% manqués → Mode CATCH_UP');
      return await _catchUpMode(planId, planDays, missedDays);
    } else if (missedPercentage <= 30) {
      // 10-30% manqué → Reschedule (trop pour catch up)
      print('    → $missedPercentage% manqués → Mode RESCHEDULE');
      return await _rescheduleMode(planId, planDays);
    } else {
      // > 30% manqué → Skip (plan probablement abandonné)
      print('    → $missedPercentage% manqués → Mode SKIP (plan à risque)');
      return await _skipMode(planId, planDays, missedDays);
    }
  }
  
  /// Analyse le plan et propose le meilleur mode de rattrapage
  /// 
  /// [planId] : ID du plan
  /// [planDays] : Liste des jours
  /// 
  /// Retourne : Mode recommandé avec justification
  static CatchupRecommendation analyzePlan({
    required String planId,
    required List<PlanDay> planDays,
  }) {
    // Garde contre plan vide
    if (planDays.isEmpty) {
      return CatchupRecommendation(
        mode: CatchupMode.skip,
        reason: 'Plan vide',
        missedCount: 0,
        affectedDays: 0,
      );
    }
    
    final missedDays = detectMissedDays(planId: planId, planDays: planDays);
    
    if (missedDays.isEmpty) {
      return CatchupRecommendation(
        mode: CatchupMode.skip,
        reason: 'Aucun jour manqué - Plan à jour',
        missedCount: 0,
        affectedDays: 0,
      );
    }
    
    final totalDays = planDays.length;
    final missedCount = missedDays.length;
    final missedPercentage = ((missedCount / totalDays) * 100).round();
    
    // Calculer la série de jours manqués consécutifs
    final consecutiveMissed = _countConsecutiveMissed(missedDays);
    
    // Analyse intelligente
    if (missedPercentage <= 10 && consecutiveMissed <= 3) {
      return CatchupRecommendation(
        mode: CatchupMode.catchUp,
        reason: 'Peu de jours manqués ($missedPercentage%) - Rattrapage facile',
        missedCount: missedCount,
        affectedDays: missedCount,
      );
    } else if (missedPercentage <= 30 || consecutiveMissed > 5) {
      return CatchupRecommendation(
        mode: CatchupMode.reschedule,
        reason: 'Plusieurs jours manqués ($missedPercentage%) - Recalage recommandé',
        missedCount: missedCount,
        affectedDays: totalDays - planDays.where((d) => d.status == 'completed').length,
      );
    } else {
      return CatchupRecommendation(
        mode: CatchupMode.skip,
        reason: 'Trop de jours manqués ($missedPercentage%) - Envisager un nouveau plan',
        missedCount: missedCount,
        affectedDays: 0,
      );
    }
  }
  
  /// Compte le nombre de jours manqués consécutifs (max)
  static int _countConsecutiveMissed(List<PlanDay> missedDays) {
    if (missedDays.isEmpty) return 0;
    
    // Trier par date
    final sorted = [...missedDays]..sort((a, b) => a.date.compareTo(b.date));
    
    int maxConsecutive = 1;
    int currentConsecutive = 1;
    
    for (int i = 1; i < sorted.length; i++) {
      final prev = _atStartOfDay(sorted[i - 1].date);
      final curr = _atStartOfDay(sorted[i].date);
      final diff = curr.difference(prev).inDays;
      
      if (diff == 1) {
        // Consécutif
        currentConsecutive++;
        maxConsecutive = math.max(maxConsecutive, currentConsecutive);
      } else {
        // Rupture
        currentConsecutive = 1;
      }
    }
    
    return maxConsecutive;
  }
  
  /// Applique automatiquement le rattrapage au démarrage de l'app
  /// 
  /// [planId] : ID du plan actif
  /// [planDays] : Liste des jours
  /// 
  /// Retourne : true si rattrapage effectué
  static Future<bool> autoApplyCatchup({
    required String planId,
    required List<PlanDay> planDays,
  }) async {
    print('🔍 Vérification automatique du rattrapage...');
    
    final missedDays = detectMissedDays(planId: planId, planDays: planDays);
    
    if (missedDays.isEmpty) {
      print('  ✅ Aucun jour manqué');
      return false;
    }
    
    // Analyser et appliquer
    final recommendation = analyzePlan(planId: planId, planDays: planDays);
    
    print('  📋 Recommandation: ${recommendation.mode.name}');
    print('  💡 Raison: ${recommendation.reason}');
    
    // Appliquer automatiquement en mode flexible
    await reschedule(
      planId: planId,
      planDays: planDays,
      missedDays: missedDays,
      mode: CatchupMode.flexible,
    );
    
    return true;
  }
  
  /// Génère un rapport de rattrapage pour l'utilisateur
  /// 
  /// [planId] : ID du plan
  /// [planDays] : Liste des jours
  /// 
  /// Retourne : Rapport lisible
  static CatchupReport generateReport({
    required String planId,
    required List<PlanDay> planDays,
  }) {
    final total = planDays.length;
    final totalSafe = total == 0 ? 1 : total; // éviter /0
    
    final missedDays = detectMissedDays(planId: planId, planDays: planDays);
    final recommendation = analyzePlan(planId: planId, planDays: planDays);
    
    final completedDays = planDays.where((d) => d.status == 'completed').length;
    final skippedDays = planDays.where((d) => d.status == 'skipped').length;
    final pendingDays = planDays.where((d) => d.status == 'pending').length;
    
    final completionRate = ((completedDays / totalSafe) * 100).round();
    final missedRate = ((missedDays.length / totalSafe) * 100).round();
    
    return CatchupReport(
      planId: planId,
      totalDays: total,
      completedDays: completedDays,
      skippedDays: skippedDays,
      pendingDays: pendingDays,
      missedDays: missedDays.length,
      completionRate: completionRate,
      missedRate: missedRate,
      recommendation: recommendation,
      message: _generateMessage(completionRate, missedRate, missedDays.length),
    );
  }
  
  /// Génère un message d'encouragement/action
  static String _generateMessage(int completionRate, int missedRate, int missedCount) {
    if (missedCount == 0) {
      return '🎉 Excellent ! Vous êtes à jour dans votre plan.';
    } else if (missedRate <= 10) {
      return '💪 Bon rythme ! Rattrapez les $missedCount jour(s) manqués pour rester sur la bonne voie.';
    } else if (missedRate <= 30) {
      return '⚠️ Attention ! $missedCount jours manqués. Recalez votre planning pour continuer sereinement.';
    } else {
      return '🔄 Plan en difficulté. Envisagez de recommencer un nouveau plan adapté à votre rythme actuel.';
    }
  }
}

/// Modes de rattrapage
enum CatchupMode {
  catchUp,    // Ajouter les jours manqués à la fin
  reschedule, // Décaler tout le planning
  skip,       // Ignorer les jours manqués
  flexible,   // Mode intelligent (auto)
}

/// Recommandation de rattrapage
class CatchupRecommendation {
  final CatchupMode mode;
  final String reason;
  final int missedCount;
  final int affectedDays;
  
  CatchupRecommendation({
    required this.mode,
    required this.reason,
    required this.missedCount,
    required this.affectedDays,
  });
  
  @override
  String toString() {
    return 'Mode: ${mode.name}\nRaison: $reason\nJours manqués: $missedCount\nJours affectés: $affectedDays';
  }
}

/// Rapport de rattrapage
class CatchupReport {
  final String planId;
  final int totalDays;
  final int completedDays;
  final int skippedDays;
  final int pendingDays;
  final int missedDays;
  final int completionRate;
  final int missedRate;
  final CatchupRecommendation recommendation;
  final String message;
  
  CatchupReport({
    required this.planId,
    required this.totalDays,
    required this.completedDays,
    required this.skippedDays,
    required this.pendingDays,
    required this.missedDays,
    required this.completionRate,
    required this.missedRate,
    required this.recommendation,
    required this.message,
  });
  
  /// Retourne un résumé formaté
  String get summary {
    return '''
📊 Résumé du plan:
• Total: $totalDays jours
• Complétés: $completedDays ($completionRate%)
• Manqués: $missedDays ($missedRate%)
• En attente: $pendingDays

${recommendation.toString()}

$message
''';
  }
}

/// Extension pour PlanDay
extension PlanDayExtension on PlanDay {
  /// Crée une copie avec modifications
  PlanDay copyWith({
    int? id,
    int? planId,
    int? dayNumber,
    DateTime? date,
    List<String>? bibleReferences,
    String? status,
    DateTime? completedAt,
  }) {
    return PlanDay(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      bibleReferences: bibleReferences ?? this.bibleReferences,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}


