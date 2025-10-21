/// ═══════════════════════════════════════════════════════════════════════════
/// SERVICE DE DIFFICULTÉ ADAPTATIVE POUR LE QUIZ
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdaptiveDifficultyService {
  static const String _prefKey = 'quiz_difficulty_profile';
  
  /// Calcule le niveau de difficulté adapté selon l'historique
  static Future<DifficultyLevel> calculateAdaptiveDifficulty(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = prefs.getString(_prefKey);
    
    if (profile == null) {
      print('🎯 Nouveau profil utilisateur - difficulté par défaut: medium');
      return DifficultyLevel.medium; // Démarrage par défaut
    }
    
    try {
      final data = json.decode(profile) as Map<String, dynamic>;
      final recentScores = (data['recent_scores'] as List).cast<double>();
      
      if (recentScores.isEmpty) {
        return DifficultyLevel.medium;
      }
      
      final avgScore = recentScores.reduce((a, b) => a + b) / recentScores.length;
      final difficulty = _calculateDifficultyFromScore(avgScore);
      
      print('🎯 Difficulté adaptative calculée: $difficulty (score moyen: ${(avgScore * 100).toStringAsFixed(1)}%)');
      return difficulty;
    } catch (e) {
      print('⚠️ Erreur calcul difficulté adaptative: $e');
      return DifficultyLevel.medium;
    }
  }
  
  /// Enregistre un score et met à jour le profil
  static Future<void> recordScore(String userId, double score) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = prefs.getString(_prefKey);
    
    Map<String, dynamic> data;
    if (profile == null) {
      data = {'recent_scores': []};
    } else {
      data = json.decode(profile) as Map<String, dynamic>;
    }
    
    final scores = (data['recent_scores'] as List).cast<double>();
    scores.add(score);
    
    // Garder seulement les 10 derniers scores
    if (scores.length > 10) {
      scores.removeAt(0);
    }
    
    data['recent_scores'] = scores;
    data['last_updated'] = DateTime.now().toIso8601String();
    
    await prefs.setString(_prefKey, json.encode(data));
    print('📊 Score enregistré: ${(score * 100).toStringAsFixed(1)}% (${scores.length} scores récents)');
  }
  
  /// Calcule la difficulté basée sur le score moyen
  static DifficultyLevel _calculateDifficultyFromScore(double avgScore) {
    if (avgScore >= 0.85) {
      return DifficultyLevel.hard;
    } else if (avgScore >= 0.65) {
      return DifficultyLevel.medium;
    } else {
      return DifficultyLevel.easy;
    }
  }
  
  /// Obtient le profil de difficulté de l'utilisateur
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = prefs.getString(_prefKey);
    
    if (profile == null) return null;
    
    try {
      return json.decode(profile) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ Erreur lecture profil: $e');
      return null;
    }
  }
  
  /// Réinitialise le profil de difficulté
  static Future<void> resetProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    print('🔄 Profil de difficulté réinitialisé');
  }
  
  /// Obtient les statistiques de performance
  static Future<Map<String, dynamic>> getPerformanceStats(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) {
      return {
        'total_quizzes': 0,
        'average_score': 0.0,
        'current_difficulty': 'medium',
        'improvement_trend': 'stable',
      };
    }
    
    final scores = (profile['recent_scores'] as List).cast<double>();
    if (scores.isEmpty) {
      return {
        'total_quizzes': 0,
        'average_score': 0.0,
        'current_difficulty': 'medium',
        'improvement_trend': 'stable',
      };
    }
    
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final currentDifficulty = _calculateDifficultyFromScore(avgScore);
    
    // Calculer la tendance d'amélioration
    String improvementTrend = 'stable';
    if (scores.length >= 3) {
      final recent = scores.take(3).reduce((a, b) => a + b) / 3;
      final older = scores.skip(3).take(3).reduce((a, b) => a + b) / 3;
      if (recent > older + 0.1) {
        improvementTrend = 'improving';
      } else if (recent < older - 0.1) {
        improvementTrend = 'declining';
      }
    }
    
    return {
      'total_quizzes': scores.length,
      'average_score': avgScore,
      'current_difficulty': currentDifficulty.name,
      'improvement_trend': improvementTrend,
      'recent_scores': scores,
    };
  }
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get name {
    switch (this) {
      case DifficultyLevel.easy:
        return 'easy';
      case DifficultyLevel.medium:
        return 'medium';
      case DifficultyLevel.hard:
        return 'hard';
    }
  }
  
  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Facile';
      case DifficultyLevel.medium:
        return 'Moyen';
      case DifficultyLevel.hard:
        return 'Difficile';
    }
  }
  
  String get description {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Questions de compréhension de base';
      case DifficultyLevel.medium:
        return 'Questions d\'analyse et de synthèse';
      case DifficultyLevel.hard:
        return 'Questions théologiques approfondies';
    }
  }
}



