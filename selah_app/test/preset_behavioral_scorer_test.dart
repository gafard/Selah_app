/// ═══════════════════════════════════════════════════════════════════════════
/// TESTS - Preset Behavioral Scorer
/// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:selah_app/services/preset_behavioral_scorer.dart';
import 'package:selah_app/services/preset_behavioral_config.dart';
import 'package:selah_app/services/preset_behavioral_integration.dart';

void main() {
  group('🧪 PresetBehavioralScorer - Tests rapides', () {
    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 1 : 40 jours Fidèle régulier → Score élevé
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 1: 40j Fidèle régulier → score élevé (sweet spot + Jésus)', () {
      final score = PresetBehavioralScorer.scorePreset(
        duration: 40,
        book: 'Jean',
        level: 'Fidèle régulier',
        goal: 'Discipline quotidienne',
        dailyMinutes: 15,
      );

      // Vérifications
      expect(score.completionProbability, greaterThan(0.65),
          reason: '40j est dans sweet spot [40,60,90] pour Fidèle régulier');

      expect(score.testimonyResonanceScore, greaterThan(0.7),
          reason: '40j résonne avec "Jésus au désert" (strength 0.95)');

      expect(score.behavioralFitScore, greaterThan(0.8),
          reason: '40j est le peak de habit_formation');

      expect(score.combinedScore, greaterThan(0.75),
          reason: 'Score combiné devrait être élevé');

      // Témoignages pertinents
      expect(score.testimonies, isNotEmpty);
      expect(score.testimonies.first, contains('Jésus'));

      print('✅ TEST 1 PASSÉ');
      print('   40j Fidèle régulier:');
      print('   - Complétion: ${(score.completionProbability * 100).round()}%');
      print('   - Témoignage: ${(score.testimonyResonanceScore * 100).round()}%');
      print('   - Behavioral: ${(score.behavioralFitScore * 100).round()}%');
      print('   - Combined: ${(score.combinedScore * 100).round()}%');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 2 : 90 jours + Peu de minutes → Risque élevé
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 2: 90j + 8 min/jour → faible complétion (plan trop long)', () {
      final score = PresetBehavioralScorer.scorePreset(
        duration: 90,
        book: 'Romains',
        level: 'Fidèle pas si régulier',
        goal: 'Approfondir la Parole',
        dailyMinutes: 8, // Peu de temps
      );

      // 90j + peu de temps + niveau pas régulier = risque
      expect(score.completionProbability, lessThan(0.5),
          reason: '90j avec 8 min/j pour Fidèle pas régulier = risque abandon');

      expect(score.combinedScore, lessThan(0.6),
          reason: 'Score global devrait être modéré/faible');

      print('✅ TEST 2 PASSÉ');
      print('   90j + 8 min/j Pas régulier:');
      print('   - Complétion: ${(score.completionProbability * 100).round()}%');
      print('   - Combined: ${(score.combinedScore * 100).round()}%');
      print('   - Reasoning: ${score.reasoning}');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 3 : 21 jours Nouveau converti → Sweet spot
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 3: 21j Nouveau converti → bon fit (sweet spot + Daniel)', () {
      final score = PresetBehavioralScorer.scorePreset(
        duration: 21,
        book: 'Marc',
        level: 'Nouveau converti',
        goal: 'Discipline',
        dailyMinutes: 12,
      );

      // 21j est dans sweet spot [21,30,40] pour Nouveau
      expect(score.behavioralFitScore, greaterThan(0.6),
          reason: '21j est bon pour habit_formation');

      expect(score.completionProbability, greaterThan(0.6),
          reason: '21j est dans sweet spot [21,30,40] pour Nouveau converti');

      expect(score.testimonies, isNotEmpty,
          reason: '21j devrait avoir témoignage Daniel');

      print('✅ TEST 3 PASSÉ');
      print('   21j Nouveau converti:');
      print('   - Behavioral: ${(score.behavioralFitScore * 100).round()}%');
      print('   - Complétion: ${(score.completionProbability * 100).round()}%');
      print('   - Témoignages: ${score.testimonies}');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 4 : 120 jours Nouveau → Très faible (overwhelm)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 4: 120j Nouveau converti → très faible (overwhelm)', () {
      final score = PresetBehavioralScorer.scorePreset(
        duration: 120,
        book: 'Romains',
        level: 'Nouveau converti',
        goal: 'Connaissance Bible',
        dailyMinutes: 15,
      );

      // 120j pour Nouveau = overwhelm
      expect(score.completionProbability, lessThan(0.35),
          reason: '120j dépasse maxSafe (60) pour Nouveau converti');

      expect(score.combinedScore, lessThan(0.45),
          reason: 'Score global devrait être faible (risque abandon élevé)');

      print('✅ TEST 4 PASSÉ');
      print('   120j Nouveau converti:');
      print('   - Complétion: ${(score.completionProbability * 100).round()}%');
      print('   - Combined: ${(score.combinedScore * 100).round()}%');
      print('   ⚠️ Risque overwhelm élevé');
    });
  });

  group('🧪 PresetBehavioralIntegration - Tests safe', () {
    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 5 : Intégration avec preset complet
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 5: Enrichissement preset complet', () {
      final preset = {
        'id': 'luc_40',
        'slug': 'discipline_luc_40d',
        'book': 'Luc',
        'duration': 40,
        'score': 0.75, // Score basique
      };

      final profile = {
        'level': 'Fidèle régulier',
        'goal': 'Discipline quotidienne',
        'durationMin': 15,
      };

      final enriched = PresetBehavioralIntegration.enrichWithBehavior(
        preset,
        profile,
      );

      // Vérifier enrichissement
      expect(enriched['score'], greaterThan(0.75),
          reason: 'Score devrait augmenter avec behavioral');

      expect(enriched['meta'], isNotNull);
      expect(enriched['meta']['completionProbability'], isNotNull);
      expect(enriched['meta']['behavioralScore'], isNotNull);
      expect(enriched['meta']['testimonies'], isNotEmpty);

      print('✅ TEST 5 PASSÉ');
      print('   Score avant: 0.75');
      print('   Score après: ${enriched['score']}');
      print('   Complétion: ${(enriched['meta']['completionProbability'] * 100).round()}%');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 6 : Preset avec champs manquants (robustesse)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 6: Preset minimal (fallbacks activés)', () {
      final preset = {
        'id': 'minimal',
        // Pas de book, duration, score
      };

      final profile = {
        // Profil minimal
      };

      final enriched = PresetBehavioralIntegration.enrichWithBehavior(
        preset,
        profile,
      );

      // Ne devrait pas crasher
      expect(enriched, isNotNull);
      expect(enriched['score'], isNotNull);
      expect(enriched['meta'], isNotNull);

      print('✅ TEST 6 PASSÉ');
      print('   Fallbacks activés:');
      print('   - Book: Psaumes (défaut)');
      print('   - Duration: 30 (défaut)');
      print('   - Level: Fidèle régulier (défaut)');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 7 : Normalisation robuste
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 7: Normalisation strings (accents, casse)', () {
      final profiles = [
        {'level': 'FIDÈLE RÉGULIER', 'goal': 'DISCIPLINE'}, // Majuscules + accents
        {'level': 'fidèle régulier', 'goal': 'discipline'}, // Minuscules + accents
        {'level': 'Fidele Regulier', 'goal': 'Discipline'}, // Sans accents
      ];

      for (final profile in profiles) {
        final preset = {'book': 'Luc', 'duration': 40, 'score': 0.7};

        final enriched = PresetBehavioralIntegration.enrichWithBehavior(
          preset,
          profile,
        );

        // Tous devraient donner le même résultat
        expect(enriched['score'], isNotNull);
        expect(enriched['meta']['completionProbability'], greaterThan(0.6));
      }

      print('✅ TEST 7 PASSÉ');
      print('   Normalisation robuste (accents, casse) OK');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 8 : UI Helpers
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 8: UI helpers (extraction données)', () {
      final preset = {
        'book': 'Luc',
        'duration': 40,
        'score': 0.85,
        'meta': {
          'completionProbability': 0.78,
          'testimonies': ['Jésus au désert (Matt 4:1-11)'],
          'scientificReasoning': 'Durée optimale\nSeconde ligne\nTroisième ligne',
        },
      };

      final prob = PresetBehavioralIntegration.getCompletionProbability(preset);
      expect(prob, 0.78);

      final testimony = PresetBehavioralIntegration.getMainTestimony(preset);
      expect(testimony, contains('Jésus'));

      final reasoning = PresetBehavioralIntegration.getScientificReasoning(preset);
      expect(reasoning, isNotNull);
      expect(reasoning!.split('\n').length, lessThanOrEqualTo(2));

      final hasLow = PresetBehavioralIntegration.hasLowCompletion(preset);
      expect(hasLow, false); // 78% > 45%

      final hasTestimony = PresetBehavioralIntegration.hasRelevantTestimony(preset);
      expect(hasTestimony, true);

      print('✅ TEST 8 PASSÉ');
      print('   UI helpers OK:');
      print('   - Complétion: ${(prob! * 100).round()}%');
      print('   - Témoignage: $testimony');
      print('   - Reasoning: ${reasoning?.split('\n').first}...');
    });
  });
}

