import '../services/intelligent_prayer_generator.dart';

/// Exemple d'intégration du générateur de prières intelligentes
class IntelligentPrayerIntegrationExample {
  
  /// Exemple d'utilisation avec des données réelles
  static Future<void> demonstrateIntegration() async {
    print('🚀 === DÉMONSTRATION INTÉGRATION PRIÈRES INTELLIGENTES ===\n');
    
    // 1. Créer un contexte de prière avec des données réalistes
    final ctx = PrayerContext(
      userProfile: {
        'level': 'Fidèle régulier',
        'goal': 'Discipline de prière',
        'durationMin': 15,
        'meditation': 'Méditation biblique',
      },
      season: 'ordinary',
      detectedThemes: ['family', 'love', 'faith'],
      answers: {
        'aboutGod': {'grâce', 'amour', 'fidélité'},
        'neighbor': {'service', 'compassion'},
        'applyToday': {'patience', 'humilité'},
        'verseHit': {'"Dieu est amour"'},
      },
      passageRef: '1 Jean 4:8',
      passageText: 'Celui qui n\'aime pas n\'a pas connu Dieu, car Dieu est amour.',
    );
    
    print('📋 Contexte créé:');
    print('  • Niveau: ${ctx.userProfile['level']}');
    print('  • Objectif: ${ctx.userProfile['goal']}');
    print('  • Saison: ${ctx.season}');
    print('  • Thèmes détectés: ${ctx.detectedThemes}');
    print('  • Passage: ${ctx.passageRef}');
    print('  • Texte: "${ctx.passageText}"\n');
    
    // 2. Générer les prières intelligentes
    final ideas = IntelligentPrayerGenerator.generate(ctx);
    
    print('🎯 === PRIÈRES GÉNÉRÉES ===\n');
    
    for (int i = 0; i < ideas.length; i++) {
      final idea = ideas[i];
      print('${i + 1}. ${idea.title}');
      print('   Catégorie: ${idea.category}');
      print('   Score: ${idea.score.toStringAsFixed(2)}');
      print('   Émotion: ${idea.emotion ?? 'neutre'}');
      print('   Verset: ${idea.verseRef ?? 'aucun'}');
      print('   Tags: ${idea.tags.join(', ')}');
      print('   Corps: "${idea.body}"');
      print('   Métadonnées: ${idea.metadata}');
      print('');
    }
    
    // 3. Conversion vers le format UI existant
    print('🔄 === CONVERSION VERS FORMAT UI ===\n');
    
    final prayerItems = ideas.map((idea) => idea.toPrayerItem()).toList();
    
    for (final item in prayerItems) {
      print('• ${item['subject']}');
      print('  Thème: ${item['theme']}');
      print('  Catégorie: ${item['category']}');
      print('  Score: ${item['score']}');
      print('');
    }
    
    // 4. Test avec différents profils utilisateur
    print('👥 === TEST PROFILS DIFFÉRENTS ===\n');
    
    final profiles = [
      {'level': 'Nouveau converti', 'goal': 'Grandir dans la foi'},
      {'level': 'Rétrograde', 'goal': 'Expérimenter la guérison'},
      {'level': 'Serviteur/leader', 'goal': 'Partager ma foi'},
    ];
    
    for (final profile in profiles) {
      final testCtx = PrayerContext(
        userProfile: {
          ...profile,
          'durationMin': 10,
          'meditation': 'Lectio Divina',
        },
        season: 'lent',
        detectedThemes: ['repentance', 'restoration'],
        answers: {
          'aboutGod': {'miséricorde', 'pardon'},
          'neighbor': {'réconciliation'},
        },
        passageRef: 'Luc 15:20',
        passageText: 'Il courut vers son fils, le prit dans ses bras et l\'embrassa.',
      );
      
      final testIdeas = IntelligentPrayerGenerator.generate(testCtx);
      
      print('Profil: ${profile['level']} - ${profile['goal']}');
      print('  → ${testIdeas.length} prières générées');
      print('  → Équilibre: ${_analyzeBalance(testIdeas)}');
      print('  → Top émotion: ${_getTopEmotion(testIdeas)}');
      print('');
    }
  }
  
  /// Analyse l'équilibre des catégories ACTS
  static String _analyzeBalance(List<PrayerIdea> ideas) {
    final counts = <String, int>{};
    for (final idea in ideas) {
      counts[idea.category] = (counts[idea.category] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}:${e.value}').join(', ');
  }
  
  /// Trouve l'émotion dominante
  static String _getTopEmotion(List<PrayerIdea> ideas) {
    final emotions = ideas.where((i) => i.emotion != null).map((i) => i.emotion!).toList();
    if (emotions.isEmpty) return 'aucune';
    
    final counts = <String, int>{};
    for (final emotion in emotions) {
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    
    final top = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${top.key} (${top.value})';
  }
  
  /// Exemple d'intégration dans une page existante
  static Map<String, dynamic> integrateWithExistingPage({
    required Map<String, dynamic> userProfile,
    required String passageText,
    required String passageRef,
    required Map<String, Set<String>> selectedAnswers,
    List<String>? detectedThemes,
  }) {
    // Créer le contexte
    final ctx = PrayerContext.fromMeditation(
      userProfile: userProfile,
      passageText: passageText,
      passageRef: passageRef,
      answers: selectedAnswers,
      detectedThemes: detectedThemes,
    );
    
    // Générer les prières
    final ideas = IntelligentPrayerGenerator.generate(ctx);
    
    // Convertir vers le format attendu par l'UI
    final prayerItems = ideas.map((idea) => idea.toPrayerItem()).toList();
    
    return {
      'prayerItems': prayerItems,
      'metadata': {
        'totalGenerated': ideas.length,
        'userLevel': userProfile['level'],
        'userGoal': userProfile['goal'],
        'season': ctx.season,
        'passageRef': passageRef,
        'generationTime': DateTime.now().toIso8601String(),
      },
    };
  }
}

/// Utilitaire pour tester l'intégration
class PrayerIntegrationTest {
  static Future<void> runTests() async {
    print('🧪 === TESTS INTÉGRATION PRIÈRES ===\n');
    
    try {
      // Test 1: Génération basique
      print('Test 1: Génération basique...');
      final basicCtx = PrayerContext(
        userProfile: {'level': 'Fidèle régulier', 'goal': 'Discipline quotidienne'},
        season: 'ordinary',
        detectedThemes: [],
        answers: {'aboutGod': {'amour'}},
        passageRef: 'Jean 3:16',
        passageText: 'Car Dieu a tant aimé le monde...',
      );
      
      final basicIdeas = IntelligentPrayerGenerator.generate(basicCtx);
      assert(basicIdeas.isNotEmpty, 'Doit générer au moins une prière');
      assert(basicIdeas.length <= 5, 'Doit générer au maximum 5 prières');
      print('✅ Test 1 réussi: ${basicIdeas.length} prières générées');
      
      // Test 2: Profils émotionnels
      print('\nTest 2: Profils émotionnels...');
      final profiles = ['Nouveau converti', 'Rétrograde', 'Serviteur/leader'];
      
      for (final level in profiles) {
        final emotionProfile = EmotionProfiles.forLevel(level);
        assert(emotionProfile.level == level, 'Profil émotionnel doit correspondre');
        assert(emotionProfile.primaryByCategory.isNotEmpty, 'Doit avoir des émotions définies');
        print('✅ Profil $level: ${emotionProfile.primaryByCategory.length} émotions');
      }
      
      // Test 3: Équilibre ACTS
      print('\nTest 3: Équilibre ACTS...');
      final balancedIdeas = IntelligentPrayerGenerator.generate(basicCtx);
      final categories = balancedIdeas.map((i) => i.category).toSet();
      assert(categories.length >= 2, 'Doit avoir au moins 2 catégories différentes');
      print('✅ Équilibre: ${categories.join(', ')}');
      
      // Test 4: Métadonnées
      print('\nTest 4: Métadonnées...');
      final firstIdea = balancedIdeas.first;
      assert(firstIdea.metadata.isNotEmpty, 'Doit avoir des métadonnées');
      assert(firstIdea.metadata['source'] != null, 'Doit avoir une source');
      print('✅ Métadonnées: ${firstIdea.metadata.keys.join(', ')}');
      
      print('\n🎉 Tous les tests sont passés avec succès !');
      
    } catch (e) {
      print('❌ Test échoué: $e');
      rethrow;
    }
  }
}

/// Point d'entrée pour lancer la démonstration
void main() async {
  await IntelligentPrayerIntegrationExample.demonstrateIntegration();
  await PrayerIntegrationTest.runTests();
}
