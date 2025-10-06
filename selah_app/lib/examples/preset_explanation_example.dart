import 'package:flutter/material.dart';
import '../services/intelligent_local_preset_generator.dart';

/// Exemple d'utilisation du système d'explication des presets
class PresetExplanationExample {
  
  /// Exemple complet d'utilisation
  static void demonstrateExplanations() {
    // 1. Profil utilisateur simulé
    final userProfile = {
      'goal': 'Mieux prier',
      'level': 'Fidèle régulier',
      'durationMin': 20,
      'meditation': 'Méditation biblique',
    };

    // 2. Génération des presets
    final presets = IntelligentLocalPresetGenerator.generateIntelligentPresets(userProfile);
    
    // 3. Génération des explications
    final explanations = IntelligentLocalPresetGenerator.explainPresets(presets, userProfile);

    // 4. Affichage des résultats
    print('\n🎯 === EXEMPLE D\'EXPLICATIONS ===');
    for (final explanation in explanations) {
      print('\n📋 ${explanation.name}');
      print('   Score total: ${explanation.totalScore}');
      print('   Raisons:');
      
      for (final reason in explanation.reasons) {
        final sign = reason.weight >= 0 ? '+' : '';
        print('     • ${reason.label}: ${sign}${reason.weight.toStringAsFixed(2)}');
        print('       ${reason.detail}');
      }
    }
    print('\n=================================\n');
  }

  /// Widget d'exemple pour afficher les explications dans l'UI
  static Widget buildExplanationCard(PresetExplanation explanation) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    explanation.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: explanation.totalScore > 0.5 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score: ${explanation.totalScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Raisons détaillées
            Text(
              'Raisons du score:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            
            ...explanation.reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: reason.weight > 0 ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reason.label} (${reason.weight >= 0 ? '+' : ''}${reason.weight.toStringAsFixed(2)})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          reason.detail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
