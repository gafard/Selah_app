import 'package:flutter/material.dart';
import '../services/intelligent_local_preset_generator.dart';

/// Exemple d'utilisation du système enrichi avec adaptation émotionnelle
class EnrichedGeneratorExample {
  
  /// Exemple complet d'utilisation des enrichissements
  static void demonstrateEnrichedFeatures() {
    print('\n🚀 === DÉMONSTRATION SYSTÈME ENRICHI ===\n');

    // 1. Profil utilisateur simulé
    final userProfile = {
      'goal': 'Mieux prier',
      'level': 'Fidèle régulier',
      'durationMin': 20,
      'meditation': 'Méditation biblique',
    };

    // 2. Simulation d'historique utilisateur
    _simulateUserHistory();

    // 3. Génération de presets enrichis
    final enrichedPresets = IntelligentLocalPresetGenerator.generateEnrichedPresets(userProfile);
    print('📚 ${enrichedPresets.length} presets enrichis générés');

    // 4. Adaptation émotionnelle
    final emotionalState = IntelligentLocalPresetGenerator.getEmotionalState(userProfile['level']);
    print('💝 État émotionnel adapté: ${emotionalState.join(', ')}');

    // 5. Recommandations spirituelles
    final recommendations = IntelligentLocalPresetGenerator.getSpiritualRecommendations();
    print('🙏 Recommandations spirituelles:');
    for (final rec in recommendations) {
      print('   • $rec');
    }

    // 6. Explications détaillées
    final explanations = IntelligentLocalPresetGenerator.explainPresets(enrichedPresets, userProfile);
    print('\n🎯 Explications des presets:');
    for (final explanation in explanations) {
      print('\n   📋 ${explanation.name} (Score: ${explanation.totalScore})');
      for (final reason in explanation.reasons) {
        final sign = reason.weight >= 0 ? '+' : '';
        print('      • ${reason.label}: ${sign}${reason.weight.toStringAsFixed(2)}');
      }
    }

    print('\n==========================================\n');
  }

  /// Simule un historique utilisateur pour la démonstration
  static void _simulateUserHistory() {
    // Ajouter des plans à l'historique
    IntelligentLocalPresetGenerator.addToPlanHistory('prayer_life_beginner');
    IntelligentLocalPresetGenerator.addToPlanHistory('psalms_meditation');

    // Enregistrer du feedback utilisateur
    IntelligentLocalPresetGenerator.recordUserFeedback('prayer_life_beginner', 0.9);
    IntelligentLocalPresetGenerator.recordUserFeedback('psalms_meditation', 0.7);

    // Ajouter des entrées au journal spirituel
    final now = DateTime.now();
    IntelligentLocalPresetGenerator.addSpiritualJournalEntry(
      SpiritualJournalEntry(
        date: now.subtract(const Duration(days: 5)),
        emotion: 'peace',
        planSlug: 'prayer_life_beginner',
        dayIndex: 3,
        reflection: 'Moment de paix profonde pendant la prière',
        satisfaction: 0.9,
      ),
    );

    IntelligentLocalPresetGenerator.addSpiritualJournalEntry(
      SpiritualJournalEntry(
        date: now.subtract(const Duration(days: 2)),
        emotion: 'joy',
        planSlug: 'psalms_meditation',
        dayIndex: 1,
        reflection: 'Joie en découvrant de nouveaux psaumes',
        satisfaction: 0.8,
      ),
    );

    print('📖 Historique simulé: 2 plans, 2 feedbacks, 2 entrées journal');
  }

  /// Widget d'exemple pour afficher l'état émotionnel
  static Widget buildEmotionalStateCard(String level) {
    final emotions = IntelligentLocalPresetGenerator.getEmotionalState(level);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'État émotionnel adapté',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emotions.map((emotion) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getEmotionColor(emotion).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getEmotionColor(emotion).withOpacity(0.3)),
                ),
                child: Text(
                  _getEmotionLabel(emotion),
                  style: TextStyle(
                    color: _getEmotionColor(emotion),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget d'exemple pour afficher les recommandations spirituelles
  static Widget buildSpiritualRecommendationsCard() {
    return FutureBuilder<List<String>>(
      future: Future.value(IntelligentLocalPresetGenerator.getSpiritualRecommendations()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ));
        }

        final recommendations = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Recommandations spirituelles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'joy': return Colors.orange;
      case 'peace': return Colors.blue;
      case 'hope': return Colors.green;
      case 'growth': return Colors.purple;
      case 'wisdom': return Colors.indigo;
      case 'encouragement': return Colors.teal;
      case 'discipline': return Colors.red;
      case 'perseverance': return Colors.brown;
      case 'responsibility': return Colors.grey;
      case 'vision': return Colors.pink;
      default: return Colors.grey;
    }
  }

  static String _getEmotionLabel(String emotion) {
    switch (emotion) {
      case 'joy': return 'Joie';
      case 'peace': return 'Paix';
      case 'hope': return 'Espérance';
      case 'growth': return 'Croissance';
      case 'wisdom': return 'Sagesse';
      case 'encouragement': return 'Encouragement';
      case 'discipline': return 'Discipline';
      case 'perseverance': return 'Persévérance';
      case 'responsibility': return 'Responsabilité';
      case 'vision': return 'Vision';
      case 'anticipation': return 'Anticipation';
      case 'foundation': return 'Fondation';
      case 'repentance': return 'Repentance';
      case 'restoration': return 'Restauration';
      case 'renewal': return 'Renouveau';
      default: return emotion;
    }
  }
}
