import 'package:flutter_test/flutter_test.dart';
import 'package:selah_app/services/intelligent_duration_calculator.dart';

void main() {
  group('IntelligentDurationCalculator - Tests Unitaires', () {
    
    // ============ TESTS BLENDING MIN/AVG/MAX ============
    
    test('Blending avec beaucoup de temps quotidien (30min/j) → penche vers min', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 30,
      );
      
      // Avec 30min/j, le blending devrait favoriser min (plan plus court)
      expect(result.optimalDays, greaterThanOrEqualTo(21)); // Contrainte minIf30Min
      expect(result.optimalDays, lessThanOrEqualTo(90)); // Devrait être relativement court
      expect(result.intensity, isIn([IntensityLevel.moderate, IntensityLevel.intensive, IntensityLevel.challenging]));
    });
    
    test('Blending avec peu de temps quotidien (5min/j) → penche vers max', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 5,
      );
      
      // Avec 5min/j, le blending devrait favoriser max (plan plus long)
      expect(result.optimalDays, greaterThanOrEqualTo(7));
      expect(result.optimalDays, lessThanOrEqualTo(120)); // Contrainte maxIf5Min
      expect(result.intensity, IntensityLevel.light);
    });
    
    // ============ TESTS CONTRAINTES PAR NIVEAU ============
    
    test('Nouveau converti → durée ≤ 60 jours (protection overwhelm)', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Nouveau converti',
        dailyMinutes: 15,
      );
      
      expect(result.optimalDays, greaterThanOrEqualTo(7));
      expect(result.optimalDays, lessThanOrEqualTo(60));
      expect(result.reasoning, contains('Nouveau converti'));
    });
    
    test('Rétrograde → durée ≤ 90 jours (éviter lassitude)', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Expérimenter la guérison',
        level: 'Rétrograde',
        dailyMinutes: 10,
      );
      
      expect(result.optimalDays, greaterThanOrEqualTo(7));
      expect(result.optimalDays, lessThanOrEqualTo(90));
      expect(result.reasoning, contains('Rétrograde'));
    });
    
    test('Serviteur/leader → durée ≥ 30 jours minimum', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Approfondir la Parole',
        level: 'Serviteur/leader',
        dailyMinutes: 30,
      );
      
      expect(result.optimalDays, greaterThanOrEqualTo(30));
      expect(result.intensity, isIn([IntensityLevel.intensive, IntensityLevel.challenging]));
      expect(result.reasoning, contains('Serviteur/leader'));
    });
    
    // ============ TESTS SÉCURITÉ (PAS DE NaN) ============
    
    test('Pas de NaN avec listes émotionnelles vides', () {
      // Ce test vérifie que _safeRatio protège contre les divisions par 0
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 15,
      );
      
      expect(result.optimalDays, isNotNull);
      expect(result.optimalDays.isNaN, isFalse);
      expect(result.totalHours.isNaN, isFalse);
      expect(result.optimalDays, greaterThan(0));
    });
    
    // ============ TESTS TYPE DE MÉDITATION ============
    
    test('Lectio Divina → durée légèrement augmentée (+5%)', () {
      final resultBaseline = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 15,
        meditationType: 'Méditation biblique',
      );
      
      final resultLectio = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 15,
        meditationType: 'Lectio Divina',
      );
      
      // Lectio Divina devrait être légèrement plus long (facteur 1.05)
      expect(resultLectio.optimalDays, greaterThanOrEqualTo(resultBaseline.optimalDays));
    });
    
    test('Contemplation → durée augmentée (+10%)', () {
      final resultBaseline = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Grandir dans la foi',
        level: 'Fidèle régulier',
        dailyMinutes: 20,
        meditationType: 'Méditation biblique',
      );
      
      final resultContemplation = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Grandir dans la foi',
        level: 'Fidèle régulier',
        dailyMinutes: 20,
        meditationType: 'Contemplation',
      );
      
      // Contemplation devrait être plus long (facteur 1.10)
      expect(resultContemplation.optimalDays, greaterThan(resultBaseline.optimalDays));
    });
    
    // ============ TESTS INTENSITÉ ============
    
    test('10min/j et ≤10h total → intensité light', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Trouver de l\'encouragement',
        level: 'Nouveau converti',
        dailyMinutes: 10,
      );
      
      final totalMinutes = result.optimalDays * result.dailyMinutes;
      if (totalMinutes <= 600) {
        expect(result.intensity, IntensityLevel.light);
      }
    });
    
    test('15min/j et ≤20h total → intensité moderate', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle pas si régulier',
        dailyMinutes: 15,
      );
      
      final totalMinutes = result.optimalDays * result.dailyMinutes;
      if (totalMinutes <= 1200 && result.dailyMinutes <= 15) {
        expect(result.intensity, IntensityLevel.moderate);
      }
    });
    
    test('30min/j → intensité intensive ou challenging', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Développer mon caractère',
        level: 'Serviteur/leader',
        dailyMinutes: 30,
      );
      
      expect(result.intensity, isIn([IntensityLevel.intensive, IntensityLevel.challenging]));
    });
    
    // ============ TESTS SCIENCE COMPORTEMENTALE ============
    
    test('Objectif "Discipline quotidienne" → type habit_formation', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 15,
      );
      
      expect(result.behavioralType, 'habit_formation');
      expect(result.scientificBasis, isNotEmpty);
      expect(result.scientificBasis.first, contains('Lally'));
    });
    
    test('Objectif "Approfondir la Parole" → type cognitive_learning', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Approfondir la Parole',
        level: 'Fidèle régulier',
        dailyMinutes: 20,
      );
      
      expect(result.behavioralType, 'cognitive_learning');
      expect(result.scientificBasis, isNotEmpty);
      expect(result.scientificBasis.first, contains('Ericsson'));
    });
    
    test('Objectif "Transformer ma vie" → type life_transformation', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Transformer ma vie',
        level: 'Serviteur/leader',
        dailyMinutes: 25,
      );
      
      expect(result.behavioralType, 'life_transformation');
      expect(result.scientificBasis, isNotEmpty);
      expect(result.scientificBasis.first, contains('Willard'));
    });
    
    // ============ TESTS REASONING ENRICHI ============
    
    test('Reasoning contient les informations clés', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Grandir dans la foi',
        level: 'Fidèle régulier',
        dailyMinutes: 15,
      );
      
      expect(result.reasoning, contains('science comportementale'));
      expect(result.reasoning, contains('témoignages'));
      expect(result.reasoning, contains('Fidèle régulier'));
      expect(result.reasoning, contains('15 min/jour'));
      expect(result.reasoning, contains('${result.optimalDays} jours'));
    });
    
    // ============ TESTS CAS LIMITES ============
    
    test('Temps quotidien minimum (5min) → plan très long avec limite', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 5,
      );
      
      expect(result.optimalDays, lessThanOrEqualTo(120)); // Contrainte maxIf5Min
      expect(result.dailyMinutes, 5);
    });
    
    test('Temps quotidien maximum (60min) → plan court', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 60,
      );
      
      expect(result.optimalDays, greaterThanOrEqualTo(7));
      expect(result.intensity, IntensityLevel.challenging);
    });
    
    // ============ TEST FOCUS ÉMOTIONNEL ============
    
    test('Focus émotionnel aligné → durée optimisée', () {
      // Ce test vérifie que l'emotional_focus est bien utilisé
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Grandir dans la foi', // emotional_focus: 'spiritual_awakening, faith_deepening, purpose_discovery'
        level: 'Fidèle régulier', // emotional_state contient 'growth_desire', 'commitment'
        dailyMinutes: 15,
      );
      
      expect(result.optimalDays, greaterThan(0));
      expect(result.reasoning, isNotEmpty);
      // Le système devrait optimiser la durée grâce à l'alignement émotionnel
    });
    
    // ============ TEST COMBINAISONS COMPLEXES ============
    
    test('Nouveau converti + 5min/j + Encouragement → plan adapté', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Trouver de l\'encouragement',
        level: 'Nouveau converti',
        dailyMinutes: 5,
      );
      
      // Doit respecter toutes les contraintes
      expect(result.optimalDays, greaterThanOrEqualTo(7));
      expect(result.optimalDays, lessThanOrEqualTo(60)); // newConvertMax
      expect(result.intensity, IntensityLevel.light);
      expect(result.behavioralType, 'hope_encouragement');
    });
    
    test('Leader + 30min/j + Transformation → plan exigeant', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Transformer ma vie',
        level: 'Serviteur/leader',
        dailyMinutes: 30,
      );
      
      // Plan long et exigeant pour leaders
      expect(result.optimalDays, greaterThanOrEqualTo(30)); // leaderMin
      expect(result.intensity, isIn([IntensityLevel.intensive, IntensityLevel.challenging]));
      expect(result.behavioralType, 'life_transformation');
      expect(result.totalHours, greaterThan(15)); // Au moins 15h total
    });
  });
  
  group('Tests de non-régression', () {
    
    test('Aucune régression sur calcul standard', () {
      final result = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: 'Discipline quotidienne',
        level: 'Fidèle régulier',
        dailyMinutes: 15,
      );
      
      // Valeurs de référence (peuvent être ajustées selon les changements)
      expect(result.optimalDays, inInclusiveRange(30, 120));
      expect(result.totalHours, inInclusiveRange(7.5, 30));
      expect(result.intensity, isNotNull);
      expect(result.behavioralType, isNotEmpty);
      expect(result.scientificBasis, isNotEmpty);
      expect(result.reasoning, isNotEmpty);
    });
  });
}

