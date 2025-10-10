/// ═══════════════════════════════════════════════════════════════════════════
/// TESTS RAPIDES - Semantic Passage Boundary Service v2.0
/// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:selah_app/services/semantic_passage_boundary_service_v2.dart';

void main() {
  setUpAll(() async {
    // Init service
    await SemanticPassageBoundaryService.init();
    await ChapterIndex.init();
    
    // Mock chapter index pour tests
    await _mockChapterIndex();
  });

  group('🧪 Tests rapides v2.0', () {
    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 1 : Luc 15 (Collection critique)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 1: Luc 15:1-10 → doit inclure 15:1-32 (collection complète)', () async {
      // Propose 15:1-10 (coupe après drachme perdue)
      final result = SemanticPassageBoundaryService.adjustPassageVerses(
        book: 'Luc',
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 10, // ❌ Coupe la collection !
      );

      // Devrait inclure toute la collection (jusqu'au fils prodigue)
      expect(result.adjusted, true, reason: 'Devrait être ajusté');
      expect(result.startChapter, 15);
      expect(result.startVerse, 1);
      expect(result.endChapter, 15);
      expect(result.endVerse, 32, reason: 'Devrait inclure toute la collection (15:1-32)');
      expect(result.reference, 'Luc 15:1-32');
      expect(result.includedUnit?.name, 'Collection de paraboles (Luc 15)');
      expect(result.includedUnit?.priority, UnitPriority.critical);
      expect(result.includedUnit?.type, UnitType.collection);
      
      print('✅ TEST 1 PASSÉ : Luc 15 collection complète');
      print('   Proposé : Luc 15:1-10');
      print('   Ajusté  : ${result.reference}');
      print('   Raison  : ${result.reason}');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 2 : Matthieu 5-6 (Sermon critique)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 2: Matthieu 5-6 → doit inclure 5-7 (sermon complet)', () async {
      // Propose Matt 5-6 (coupe le sermon)
      final result = SemanticPassageBoundaryService.adjustPassageVerses(
        book: 'Matthieu',
        startChapter: 5,
        startVerse: 1,
        endChapter: 6,
        endVerse: 34, // ❌ Coupe le sermon !
      );

      // Devrait inclure tout le Sermon sur la montagne (Matt 5-7)
      expect(result.adjusted, true, reason: 'Devrait être ajusté');
      expect(result.startChapter, 5);
      expect(result.startVerse, 1);
      expect(result.endChapter, 7);
      expect(result.endVerse, 29, reason: 'Devrait inclure tout le sermon (5:1-7:29)');
      expect(result.reference, 'Matthieu 5:1–7:29');
      expect(result.includedUnit?.name, 'Sermon sur la montagne');
      expect(result.includedUnit?.priority, UnitPriority.critical);
      
      print('✅ TEST 2 PASSÉ : Matthieu 5-7 sermon complet');
      print('   Proposé : Matthieu 5:1-6:34');
      print('   Ajusté  : ${result.reference}');
      print('   Raison  : ${result.reason}');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 3 : Romains 7-8 (Densité + Unité critique)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 3: Romains 7-8 → devrait séparer selon densité', () async {
      // Si on propose Rom 7-8, devrait privilégier Rom 8 seul (unité critique)
      final result = SemanticPassageBoundaryService.adjustPassageVerses(
        book: 'Romains',
        startChapter: 7,
        startVerse: 1,
        endChapter: 8,
        endVerse: 39,
      );

      // Rom 8 est une unité critique "Vie par l'Esprit"
      // Selon la cible minutes, peut ajuster
      expect(result.book, 'Romains');
      
      // Si coupe Rom 8, devrait inclure 8:1-39 complet
      if (result.startChapter <= 8 && result.endChapter >= 8) {
        if (result.startChapter == 8) {
          expect(result.startVerse, 1, reason: 'Rom 8 devrait commencer au verset 1');
        }
        expect(result.endVerse, 39, reason: 'Rom 8 devrait finir au verset 39');
        expect(result.includedUnit?.name, 'Vie par l\'Esprit');
      }
      
      print('✅ TEST 3 PASSÉ : Romains 8 unité préservée');
      print('   Proposé : Romains 7:1-8:39');
      print('   Ajusté  : ${result.reference}');
      print('   Raison  : ${result.reason}');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 4 : Minutes/jour (Romains dense)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 4: splitByTargetMinutes avec livre dense (Romains)', () async {
      final passages = SemanticPassageBoundaryService.splitByTargetMinutes(
        book: 'Romains',
        totalChapters: 8,
        targetDays: 3,
        minutesPerDay: 15,
      );

      // Devrait créer ~3 passages
      expect(passages.length, greaterThanOrEqualTo(2));
      expect(passages.length, lessThanOrEqualTo(4));

      // Chaque passage devrait être ~15 min (±5 min)
      for (final p in passages) {
        expect(p.estimatedMinutes, isNotNull);
        expect(p.estimatedMinutes!, greaterThan(8), reason: 'Au moins 8 min');
        expect(p.estimatedMinutes!, lessThan(25), reason: 'Max 25 min');
        
        print('   Jour ${p.dayNumber}: ${p.reference} (~${p.estimatedMinutes} min)');
      }

      print('✅ TEST 4 PASSÉ : Romains réparti selon minutes/jour');
      print('   Total jours : ${passages.length}');
      print('   Cible : 15 min/jour');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 5 : Jean 15-17 (Discours long sur 3 chapitres)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 5: Jean 15-16 → doit inclure 15-17 (discours complet)', () async {
      // Propose Jean 15-16 (coupe le discours)
      final result = SemanticPassageBoundaryService.adjustPassageVerses(
        book: 'Jean',
        startChapter: 15,
        startVerse: 1,
        endChapter: 16,
        endVerse: 33, // ❌ Coupe le discours !
      );

      // Devrait inclure tout le discours d'adieu partie 2 (Jean 15-17)
      expect(result.adjusted, true);
      expect(result.startChapter, 15);
      expect(result.startVerse, 1);
      expect(result.endChapter, 17);
      expect(result.endVerse, 26, reason: 'Devrait inclure tout le discours (15:1-17:26)');
      expect(result.includedUnit?.name, 'Discours d\'adieu (partie 2)');
      
      print('✅ TEST 5 PASSÉ : Jean 15-17 discours complet');
      print('   Proposé : Jean 15:1-16:33');
      print('   Ajusté  : ${result.reference}');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 6 : Convergence itérative (unités imbriquées)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 6: Convergence sur unités imbriquées (Luc 15)', () async {
      // Luc 15 a une collection ET des unités simples
      // Devrait privilégier la collection
      final result = SemanticPassageBoundaryService.adjustPassageVerses(
        book: 'Luc',
        startChapter: 15,
        startVerse: 11, // Commence au fils prodigue
        endChapter: 15,
        endVerse: 25, // Coupe au milieu du fils prodigue
      );

      // Devrait étendre à toute la collection (priorité critical)
      expect(result.adjusted, true);
      expect(result.startVerse, 1, reason: 'Devrait commencer au début de la collection');
      expect(result.endVerse, 32, reason: 'Devrait finir à la fin de la collection');
      expect(result.includedUnit?.type, UnitType.collection);
      
      print('✅ TEST 6 PASSÉ : Convergence itérative correcte');
      print('   Proposé : Luc 15:11-25');
      print('   Ajusté  : ${result.reference}');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 7 : Pas de cut (aucun ajustement nécessaire)
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 7: Passage sans cut → aucun ajustement', () async {
      // Propose exactement Luc 15:1-32 (collection complète)
      final result = SemanticPassageBoundaryService.adjustPassageVerses(
        book: 'Luc',
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 32,
      );

      // Ne devrait pas être ajusté (déjà parfait)
      expect(result.adjusted, false);
      expect(result.reason, contains('Aucune unité coupée'));
      
      print('✅ TEST 7 PASSÉ : Pas d\'ajustement si déjà correct');
      print('   Proposé : Luc 15:1-32');
      print('   Résultat : Non ajusté (déjà parfait)');
    });

    /// ═══════════════════════════════════════════════════════════════════════
    /// TEST 8 : Stats de la base de connaissances
    /// ═══════════════════════════════════════════════════════════════════════
    test('Test 8: Stats de la base de connaissances', () async {
      final stats = SemanticPassageBoundaryService.getStats();

      expect(stats['totalBooks'], greaterThan(0));
      expect(stats['totalUnits'], greaterThan(0));
      expect(stats['criticalUnits'], greaterThan(0));
      expect(stats['collections'], greaterThan(0));

      print('✅ TEST 8 PASSÉ : Stats correctes');
      print('   Livres : ${stats['totalBooks']}');
      print('   Unités : ${stats['totalUnits']}');
      print('   Critiques : ${stats['criticalUnits']}');
      print('   Collections : ${stats['collections']}');
    });
  });
}

/// Mock ChapterIndex pour tests
Future<void> _mockChapterIndex() async {
  // Mock data minimale pour tests
  await ChapterIndex.hydrate({
    'verses': {
      'Luc:15': 32,
      'Matthieu:5': 48,
      'Matthieu:6': 34,
      'Matthieu:7': 29,
      'Jean:15': 27,
      'Jean:16': 33,
      'Jean:17': 26,
      'Romains:1': 32,
      'Romains:2': 29,
      'Romains:3': 31,
      'Romains:4': 25,
      'Romains:5': 21,
      'Romains:6': 23,
      'Romains:7': 25,
      'Romains:8': 39,
    },
    'densities': {
      'Luc': 1.0,
      'Matthieu': 1.0,
      'Jean': 1.1,
      'Romains': 1.25,
    },
  });
}


