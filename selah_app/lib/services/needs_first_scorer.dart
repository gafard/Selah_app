/// 🎯 SCORER NEEDS-FIRST
/// 
/// Algorithme: need_score × doctrinal_safety × time_fit × novelty
/// Poids: need 65%, safety 25%, time 7%, novelty 3%

import '../models/plan_preset.dart';
import 'needs_assessor.dart';
import 'preset_theology_adapter_v2.dart';

class NeedsFirstScorer {
  // Poids de l'algorithme
  static const _weightNeed = 0.65;
  static const _weightSafety = 0.25;
  static const _weightTime = 0.07;
  static const _weightNovelty = 0.03;
  
  /// Score final d'un preset selon l'algorithme needs-first
  static double scorePreset(
    PlanPreset preset,
    NeedsProfile needs,
    Map<String, dynamic>? userProfile,
    List<String> recentPresets, // pour éviter les répétitions
  ) {
    final needScore = _calculateNeedScore(preset, needs);
    final safetyScore = _calculateSafetyScore(preset);
    final timeScore = _calculateTimeScore(preset, userProfile);
    final noveltyScore = _calculateNoveltyScore(preset, recentPresets);
    
    final finalScore = (_weightNeed * needScore) +
                      (_weightSafety * safetyScore) +
                      (_weightTime * timeScore) +
                      (_weightNovelty * noveltyScore);
    
    return finalScore.clamp(0.0, 1.0);
  }
  
  /// Calcule le score de besoin (0-1) - Poids 65%
  static double _calculateNeedScore(PlanPreset preset, NeedsProfile needs) {
    final name = preset.name.toLowerCase();
    final books = preset.books.toLowerCase();
    final description = preset.description?.toLowerCase() ?? '';
    
    double score = 0.0;
    
    // Foundation (Christ/Évangile/Autorité)
    if (needs.foundation > 0.5) {
      if (name.contains('évangiles') || name.contains('jésus') || name.contains('christ') ||
          books.contains('jean') || books.contains('romains') || books.contains('galates')) {
        score += needs.foundation * 0.4;
      }
    }
    
    // Discipline (régularité/constance)
    if (needs.discipline > 0.5) {
      if (name.contains('proverbes') || name.contains('jacques') || name.contains('discipline') ||
          books.contains('proverbes') || books.contains('jacques')) {
        score += needs.discipline * 0.3;
      }
    }
    
    // Repentance (cœur/retour)
    if (needs.repentance > 0.5) {
      if (name.contains('psaumes') || name.contains('repentance') || name.contains('pardon') ||
          books.contains('psaumes') || description.contains('repentance')) {
        score += needs.repentance * 0.2;
      }
    }
    
    // Doctrine (erreurs récurrentes)
    if (needs.doctrine > 0.5) {
      if (books.contains('galates') || books.contains('romains') || books.contains('hébreux') ||
          name.contains('doctrine') || name.contains('grâce')) {
        score += needs.doctrine * 0.2;
      }
    }
    
    // Suffering (épreuve/détresse)
    if (needs.suffering > 0.5) {
      if (books.contains('job') || books.contains('2 corinthiens') || books.contains('1 pierre') ||
          name.contains('épreuve') || name.contains('souffrance') || name.contains('encouragement')) {
        score += needs.suffering * 0.15;
      }
    }
    
    // Anxiety (anxiété/peur)
    if (needs.anxiety > 0.5) {
      if (books.contains('matthieu') || books.contains('philippiens') || books.contains('1 pierre') ||
          name.contains('paix') || name.contains('anxiété') || description.contains('anxiété')) {
        score += needs.anxiety * 0.15;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Calcule le score de sécurité doctrinale (0-1) - Poids 25%
  static double _calculateSafetyScore(PlanPreset preset) {
    // Utilise TheologyGate V2 pour évaluer la sécurité doctrinale
    final theologyPreset = PresetTheologyAdapterV2.convertToTheologyFormat(preset);
    final doctrineScore = theologyPreset.focusDoctrineOfChrist ?? 0.0;
    final authorityScore = theologyPreset.focusAuthorityOfBible ?? 0.0;
    final gospelScore = theologyPreset.focusGospelOfJesus ?? 0.0;
    
    return (doctrineScore + authorityScore + gospelScore) / 3.0;
  }
  
  /// Calcule le score d'ajustement temporel (0.8-1.0) - Poids 7%
  static double _calculateTimeScore(PlanPreset preset, Map<String, dynamic>? userProfile) {
    final userMinutes = userProfile?['durationMin'] as int? ?? 15;
    final presetMinutes = preset.minutesPerDay ?? 15;
    final userLevel = userProfile?['level'] as String? ?? 'Fidèle régulier';
    
    double score = 1.0;
    
    // Ajustement selon le temps quotidien
    final timeDiff = (userMinutes - presetMinutes).abs();
    if (timeDiff > 10) score -= 0.1;
    if (timeDiff > 20) score -= 0.1;
    
    // Ajustement selon le niveau
    final duration = preset.durationDays;
    if (userLevel == 'Nouveau converti' && duration > 60) score -= 0.1;
    if (userLevel == 'Serviteur/leader' && duration < 30) score -= 0.05;
    
    return score.clamp(0.8, 1.0);
  }
  
  /// Calcule le score de nouveauté (0.9-1.0) - Poids 3%
  static double _calculateNoveltyScore(PlanPreset preset, List<String> recentPresets) {
    final presetBooks = preset.books.toLowerCase().split(',').map((b) => b.trim()).toList();
    
    // Vérifier les répétitions récentes
    int repetitions = 0;
    for (final recent in recentPresets) {
      final recentBooks = recent.toLowerCase().split(',').map((b) => b.trim()).toList();
      for (final book in presetBooks) {
        if (recentBooks.any((rb) => rb.contains(book) || book.contains(rb))) {
          repetitions++;
        }
      }
    }
    
    double score = 1.0;
    if (repetitions > 0) score -= 0.05 * repetitions;
    
    return score.clamp(0.9, 1.0);
  }
  
  /// Trie les presets selon le score needs-first
  static List<PlanPreset> rankPresets(
    List<PlanPreset> presets,
    NeedsProfile needs,
    Map<String, dynamic>? userProfile,
    List<String> recentPresets,
  ) {
    final scoredPresets = presets.map((preset) {
      final score = scorePreset(preset, needs, userProfile, recentPresets);
      return MapEntry(preset, score);
    }).toList();
    
    // Trier par score décroissant
    scoredPresets.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredPresets.map((entry) => entry.key).toList();
  }
}
