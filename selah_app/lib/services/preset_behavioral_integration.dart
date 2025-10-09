/// ═══════════════════════════════════════════════════════════════════════════
/// PRESET BEHAVIORAL INTEGRATION - Helper d'intégration safe
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Wrapper robuste pour intégrer PresetBehavioralScorer dans le générateur
/// existant sans casser le code legacy.
///
/// Gère :
/// - Normalisation robuste des strings
/// - Fallbacks sûrs si champs manquants
/// - Harmonisation des clés (compat multi-formats)
/// - Télémétrie optionnelle
/// ═══════════════════════════════════════════════════════════════════════════

import 'preset_behavioral_scorer.dart';
import 'preset_behavioral_config.dart';

class PresetBehavioralIntegration {
  /// Enrichit un preset avec scoring comportemental (version safe)
  /// 
  /// Gère tous les cas edge :
  /// - Champs manquants → fallbacks
  /// - Formats variés → normalisation
  /// - Null safety complète
  /// 
  /// Usage:
  ///   final enriched = enrichWithBehavior(preset, userProfile);
  static Map<String, dynamic> enrichWithBehavior(
    Map<String, dynamic> preset,
    Map<String, dynamic> profile,
  ) {
    try {
      // ═══════════════════════════════════════════════════════════════════
      // 1) NORMALISER PROFIL (éviter accents/casse)
      // ═══════════════════════════════════════════════════════════════════

      final normalizedProfile = {
        'goal': PresetBehavioralConfig.mapGoalToBehavioralType(
          profile['goal']?.toString() ?? 'discipline quotidienne',
        ),
        'level': PresetBehavioralConfig.mapLevel(
          profile['level']?.toString() ?? 'fidèle régulier',
        ),
        'durationMin': _safeInt(profile['durationMin'], 15),
      };

      // ═══════════════════════════════════════════════════════════════════
      // 2) EXTRAIRE DONNÉES PRESET (fallbacks sûrs)
      // ═══════════════════════════════════════════════════════════════════

      // Book : peut être 'book', 'books', 'bookName'
      final book = _extractBook(preset);

      // Duration : peut être 'duration', 'durationDays', 'days'
      final duration = _extractDuration(preset);

      // Score existant
      final currentScore = _safeDouble(preset['score'], 0.0);

      // ═══════════════════════════════════════════════════════════════════
      // 3) CALCULER SCORE COMPORTEMENTAL
      // ═══════════════════════════════════════════════════════════════════

      final behavioralScore = PresetBehavioralScorer.scorePreset(
        duration: duration,
        book: book,
        level: normalizedProfile['level'] as String,
        goal: normalizedProfile['goal'] as String,
        dailyMinutes: normalizedProfile['durationMin'] as int,
      );

      // ═══════════════════════════════════════════════════════════════════
      // 4) COMBINER SCORES
      // ═══════════════════════════════════════════════════════════════════

      final baseWeight = 1.0 - PresetBehavioralConfig.injectInFinalScore;
      final enrichedScore = currentScore * baseWeight +
          behavioralScore.combinedScore * PresetBehavioralConfig.injectInFinalScore;

      // ═══════════════════════════════════════════════════════════════════
      // 5) HARMONISER CLÉS (compat avec reste du système)
      // ═══════════════════════════════════════════════════════════════════

      final result = {
        ...preset,
        'score': enrichedScore,
        'durationDays': duration, // Harmonisation
        'meta': {
          ..._safeMeta(preset),
          'completionProbability': behavioralScore.completionProbability,
          'behavioralScore': behavioralScore.combinedScore,
          'scientificReasoning': behavioralScore.reasoning,
          'scientificBasis': behavioralScore.scientificBasis,
          'testimonies': behavioralScore.testimonies,
          'testimonyResonance': behavioralScore.testimonyResonanceScore,
          'motivationAlignment': behavioralScore.motivationAlignment,
        },
      };

      // ═══════════════════════════════════════════════════════════════════
      // 6) TÉLÉMÉTRIE (optionnel)
      // ═══════════════════════════════════════════════════════════════════

      PresetBehavioralConfig.logBehavioralEvent(
        event: 'preset_scored_behavioral',
        data: {
          'preset': preset['slug'] ?? preset['name'] ?? 'unknown',
          'duration': duration,
          'completionProb': (behavioralScore.completionProbability * 100).round(),
          'finalScore': (enrichedScore * 100).round(),
        },
      );

      return result;
    } catch (e) {
      // Fallback sûr : retourner preset inchangé si erreur
      print('⚠️ PresetBehavioralIntegration error: $e');
      return preset;
    }
  }

  /// Enrichit une liste de presets
  static List<Map<String, dynamic>> enrichPresets(
    List<Map<String, dynamic>> presets,
    Map<String, dynamic> profile,
  ) {
    return presets.map((p) => enrichWithBehavior(p, profile)).toList();
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// HELPERS D'EXTRACTION (robustes)
  /// ═══════════════════════════════════════════════════════════════════════

  /// Extrait le nom du livre (gère plusieurs formats)
  static String _extractBook(Map<String, dynamic> preset) {
    // Essayer plusieurs clés possibles
    final candidates = [
      preset['book'],
      preset['books'],
      preset['bookName'],
      preset['title']?.toString().split(' ').first,
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.toString().isNotEmpty) {
        // Si c'est une liste, prendre le premier
        if (candidate is List && candidate.isNotEmpty) {
          return candidate.first.toString();
        }
        return candidate.toString();
      }
    }

    return 'Psaumes'; // Fallback par défaut
  }

  /// Extrait la durée (gère plusieurs formats)
  static int _extractDuration(Map<String, dynamic> preset) {
    // Essayer plusieurs clés possibles
    final candidates = [
      preset['duration'],
      preset['durationDays'],
      preset['days'],
      preset['totalDays'],
    ];

    for (final candidate in candidates) {
      if (candidate != null) {
        if (candidate is int) return candidate;
        if (candidate is double) return candidate.toInt();
        if (candidate is String) {
          final parsed = int.tryParse(candidate);
          if (parsed != null) return parsed;
        }
      }
    }

    return 30; // Fallback par défaut
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// HELPERS UTILITAIRES
  /// ═══════════════════════════════════════════════════════════════════════

  static int _safeInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _safeDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static Map<String, dynamic> _safeMeta(Map<String, dynamic> preset) {
    final meta = preset['meta'];
    if (meta == null) return {};
    if (meta is Map<String, dynamic>) return meta;
    return {};
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// UI HELPERS - Extraction pour affichage
  /// ═══════════════════════════════════════════════════════════════════════

  /// Extrait la probabilité de complétion (pour badge UI)
  static double? getCompletionProbability(Map<String, dynamic> preset) {
    final meta = _safeMeta(preset);
    return _safeDouble(meta['completionProbability'], -1.0) >= 0 
        ? _safeDouble(meta['completionProbability'], 0.0) 
        : null;
  }

  /// Extrait le premier témoignage pertinent (pour badge UI)
  static String? getMainTestimony(Map<String, dynamic> preset) {
    final meta = _safeMeta(preset);
    final testimonies = meta['testimonies'];
    
    if (testimonies is List && testimonies.isNotEmpty) {
      return testimonies.first.toString();
    }
    
    return null;
  }

  /// Extrait le reasoning scientifique (pour tooltip UI)
  static String? getScientificReasoning(Map<String, dynamic> preset) {
    final meta = _safeMeta(preset);
    final reasoning = meta['scientificReasoning'];
    
    if (reasoning != null && reasoning.toString().isNotEmpty) {
      // Limiter à 2 premières lignes pour UI
      final lines = reasoning.toString().split('\n');
      return lines.take(2).join('\n');
    }
    
    return null;
  }

  /// Vérifie si probabilité est basse (pour afficher suggestion)
  static bool hasLowCompletion(Map<String, dynamic> preset) {
    final prob = getCompletionProbability(preset);
    return prob != null && prob < PresetBehavioralConfig.lowCompletionThreshold;
  }

  /// Vérifie si témoignage est pertinent (pour afficher badge)
  static bool hasRelevantTestimony(Map<String, dynamic> preset) {
    final meta = _safeMeta(preset);
    final resonance = _safeDouble(meta['testimonyResonance'], 0.0);
    return resonance >= PresetBehavioralConfig.testimonyRelevanceThreshold;
  }

  /// Génère suggestion si complétion basse
  static String? getSuggestion(Map<String, dynamic> preset) {
    if (!hasLowCompletion(preset)) return null;

    final duration = _extractDuration(preset);
    
    if (duration < 21) {
      return 'Essaie 30-40 jours pour ancrer l\'habitude';
    } else if (duration > 90) {
      return 'Un plan plus court (40-60j) pourrait être plus réaliste';
    }
    
    return 'Durée optimale: 30-40 jours pour ce niveau';
  }
}

