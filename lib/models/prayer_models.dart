import 'package:flutter/material.dart';

enum PrayerCategory {
  actionDeGrace, 
  repentance, 
  promesse, 
  obeissance, 
  avertissement, 
  foiVerite, 
  intercession
}

final Map<PrayerCategory, List<Pattern>> lexicon = {
  PrayerCategory.actionDeGrace: [
    RegExp(r'\b(merci|remercie|louange|reconnaissance|grâce)\b', caseSensitive: false),
  ],
  PrayerCategory.repentance: [
    RegExp(r'\b(pardon|pardonne|repentance|me repent|confesse|faute|péché|pécher)\b', caseSensitive: false),
  ],
  PrayerCategory.promesse: [
    RegExp(r'\b(promesse|promet|assure|sera|sera donné)\b', caseSensitive: false),
  ],
  PrayerCategory.obeissance: [
    RegExp(r'\b(obéir|obéissance|faire|appliquer|mettre en pratique|suivre|exécuter|agir)\b', caseSensitive: false),
  ],
  PrayerCategory.avertissement: [
    RegExp(r'\b(avertissement|garde-toi|attention|ne pas|danger|risque)\b', caseSensitive: false),
  ],
  PrayerCategory.foiVerite: [
    RegExp(r'\b(croire|foi|vérité|me montre|révèle|compris|enseigne)\b', caseSensitive: false),
  ],
  PrayerCategory.intercession: [
    RegExp(r'\b(prions pour|mon prochain|église|frères|soeurs|pauvres|malades|autorités)\b', caseSensitive: false),
  ],
};

class PrayerAnalysis {
  final Map<PrayerCategory, int> categoryScores;
  final List<PrayerCategory> detectedCategories;
  final String originalText;

  PrayerAnalysis({
    required this.categoryScores,
    required this.detectedCategories,
    required this.originalText,
  });

  factory PrayerAnalysis.analyze(String text) {
    final scores = <PrayerCategory, int>{};
    final detected = <PrayerCategory>[];

    for (final entry in lexicon.entries) {
      final category = entry.key;
      final patterns = entry.value;
      int score = 0;

      for (final pattern in patterns) {
        final matches = pattern.allMatches(text);
        score += matches.length;
      }

      scores[category] = score;
      if (score > 0) {
        detected.add(category);
      }
    }

    return PrayerAnalysis(
      categoryScores: scores,
      detectedCategories: detected,
      originalText: text,
    );
  }

  String getCategoryDisplayName(PrayerCategory category) {
    switch (category) {
      case PrayerCategory.actionDeGrace:
        return 'Action de grâce';
      case PrayerCategory.repentance:
        return 'Repentance';
      case PrayerCategory.promesse:
        return 'Promesse';
      case PrayerCategory.obeissance:
        return 'Obéissance';
      case PrayerCategory.avertissement:
        return 'Avertissement';
      case PrayerCategory.foiVerite:
        return 'Foi & Vérité';
      case PrayerCategory.intercession:
        return 'Intercession';
    }
  }

  Color getCategoryColor(PrayerCategory category) {
    switch (category) {
      case PrayerCategory.actionDeGrace:
        return const Color(0xFFFFD36A); // Gold
      case PrayerCategory.repentance:
        return const Color(0xFFFF7CCB); // Rose
      case PrayerCategory.promesse:
        return const Color(0xFF56E6C2); // Green
      case PrayerCategory.obeissance:
        return const Color(0xFFB39DFF); // Lavender
      case PrayerCategory.avertissement:
        return const Color(0xFFFF6B6B); // Red
      case PrayerCategory.foiVerite:
        return const Color(0xFF4ECDC4); // Teal
      case PrayerCategory.intercession:
        return const Color(0xFFFFA726); // Orange
    }
  }
}

class PrayerClassifier {
  final double threshold; // ex: 1.5

  PrayerClassifier({this.threshold = 1.5});

  Map<PrayerCategory, double> score(String answer) {
    final s = answer.toLowerCase();
    final scores = <PrayerCategory, double>{ for (var c in PrayerCategory.values) c: 0.0 };

    for (final entry in lexicon.entries) {
      for (final p in entry.value) {
        if (p is RegExp) {
          final matches = p.allMatches(s).length;
          if (matches > 0) scores[entry.key] = (scores[entry.key] ?? 0) + matches * 1.0;
        }
      }
    }
    return scores;
  }

  List<PrayerCategory> classify(String answer) {
    final scores = score(answer);
    final maxScore = scores.values.fold<double>(0, (a,b)=>a>b?a:b);
    if (maxScore == 0) return [PrayerCategory.foiVerite]; // fallback neutre

    // toutes les catégories "fortes"
    final selected = scores.entries
      .where((e) => e.value >= threshold && (maxScore - e.value) <= 0.5)
      .map((e) => e.key)
      .toList();

    return selected.isEmpty ? [scores.entries.firstWhere((e)=>e.value==maxScore).key] : selected;
  }

  String buildPrayerItem(PrayerCategory c, String answer) {
    switch (c) {
      case PrayerCategory.actionDeGrace:
        return "Merci Seigneur pour ceci que j'ai compris : « $answer »";
      case PrayerCategory.repentance:
        return "Je confesse et je me détourne de : « $answer » ; aide-moi à marcher dans ta voie.";
      case PrayerCategory.promesse:
        return "Je m'approprie ta promesse : « $answer » ; fortifie ma foi.";
      case PrayerCategory.obeissance:
        return "Je décide d'obéir aujourd'hui en : « $answer » ; conduis-moi et rends-moi fidèle.";
      case PrayerCategory.avertissement:
        return "Garde-moi de tomber dans : « $answer » ; ouvre mes yeux et mon cœur.";
      case PrayerCategory.foiVerite:
        return "Je crois cette vérité : « $answer » ; grave-la en moi.";
      case PrayerCategory.intercession:
        return "Je te présente mon prochain/Église : « $answer » ; agis avec grâce et puissance.";
    }
  }
}