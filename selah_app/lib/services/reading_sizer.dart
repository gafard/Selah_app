/// ═══════════════════════════════════════════════════════════════════════════
/// READING SIZER - Calcul intelligent de charge de lecture
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Estime la charge de lecture quotidienne à partir des métadonnées chapitres.
/// 
/// Prend en compte :
/// - Nombre de versets (via ChapterIndexLoader)
/// - Densité textuelle (discours vs récit)
/// - Durée cible en minutes/jour
/// - Frontières sémantiques (via SemanticPassageBoundaryService)
///
/// Objectif : Déterminer combien de chapitres (ou fractions) doivent être lus
///            pour atteindre environ N minutes de lecture.
///
/// Utilisation :
///   final chapters = ReadingSizer.estimateChaptersForDay(
///     book: 'Luc',
///     totalChapters: 24,
///     targetMinutes: 10,
///   );
///   // → 2 chapitres
///
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:math';
import 'chapter_index_loader.dart';

class ReadingSizer {
  /// Temps moyen pour lire 25 versets avec densité 1.0
  /// 
  /// Calibration :
  /// - Lecteur rapide : 4-5 min
  /// - Lecteur moyen : 6 min (défaut)
  /// - Lecteur lent : 8-10 min
  static const double baseMinutes = 6.0;

  /// Calcule combien de chapitres doivent être lus pour atteindre la durée cible
  /// 
  /// Paramètres:
  /// - book: Nom du livre (ex: "Luc")
  /// - totalChapters: Nombre total de chapitres du livre
  /// - targetMinutes: Durée cible en minutes
  /// - startChapter: Premier chapitre à considérer (défaut: 1)
  /// 
  /// Retourne: Nombre de chapitres à lire (minimum 1)
  /// 
  /// Exemple:
  ///   estimateChaptersForDay(
  ///     book: 'Luc',
  ///     totalChapters: 24,
  ///     targetMinutes: 10,
  ///   )
  ///   → 2 (Luc 1: ~14 min, mais on s'arrête car proche de 10)
  static int estimateChaptersForDay({
    required String book,
    required int totalChapters,
    required double targetMinutes,
    int startChapter = 1,
  }) {
    double accumulated = 0;
    int chapters = 0;

    for (int c = startChapter; c <= totalChapters; c++) {
      final est = ChapterIndexLoader.estimateMinutes(
        book: book,
        chapter: c,
        baseMinutes: baseMinutes.toInt(),
      );

      // Si ajouter ce chapitre dépasse trop la cible, s'arrêter
      // (sauf si c'est le premier chapitre)
      if (chapters > 0 && accumulated + est > targetMinutes * 1.3) {
        break;
      }

      accumulated += est;
      chapters++;

      // Si on a atteint ou dépassé la cible, s'arrêter
      if (accumulated >= targetMinutes) break;
    }

    return max(1, chapters); // Minimum 1 chapitre par jour
  }

  /// Retourne une estimation détaillée pour affichage dans l'UI
  /// 
  /// Utile pour preview d'un plan avant création.
  /// 
  /// Exemple:
  ///   final summary = dayReadingSummary(
  ///     book: 'Luc',
  ///     startChapter: 1,
  ///     totalChapters: 24,
  ///     targetMinutes: 10,
  ///   );
  ///   
  ///   print(summary['range']);        // "Luc 1–2"
  ///   print(summary['approxMinutes']); // 12
  ///   print(summary['chapters']);      // 2
  static Map<String, dynamic> dayReadingSummary({
    required String book,
    required int startChapter,
    required int totalChapters,
    required double targetMinutes,
  }) {
    final needed = estimateChaptersForDay(
      book: book,
      totalChapters: totalChapters,
      targetMinutes: targetMinutes,
      startChapter: startChapter,
    );

    // Calculer la durée réelle estimée
    double actualMinutes = 0;
    for (int c = startChapter; c < startChapter + needed; c++) {
      actualMinutes += ChapterIndexLoader.estimateMinutes(
        book: book,
        chapter: c,
        baseMinutes: baseMinutes.toInt(),
      );
    }

    final endChapter = min(startChapter + needed - 1, totalChapters);

    return {
      'chapters': needed,
      'approxMinutes': actualMinutes.round(),
      'targetMinutes': targetMinutes.round(),
      'range': startChapter == endChapter
          ? '$book $startChapter'
          : '$book $startChapter–$endChapter',
      'startChapter': startChapter,
      'endChapter': endChapter,
      'book': book,
    };
  }

  /// Donne une durée totale estimée pour un livre entier
  /// 
  /// Utile pour afficher dans l'UI "Temps total estimé: ~2h30"
  /// 
  /// Exemple:
  ///   final total = estimateTotalReadingMinutes('Luc', 24);
  ///   // → ~240 minutes (4h)
  static double estimateTotalReadingMinutes(String book, int totalChapters) {
    double total = 0;
    
    for (int c = 1; c <= totalChapters; c++) {
      total += ChapterIndexLoader.estimateMinutes(
        book: book,
        chapter: c,
        baseMinutes: baseMinutes.toInt(),
      );
    }
    
    return total;
  }

  /// Calcule le nombre de jours nécessaires pour lire un livre
  /// avec une durée cible par jour
  /// 
  /// Exemple:
  ///   final days = estimateDaysForBook('Luc', 24, 10);
  ///   // → ~24 jours (avec 10 min/jour)
  static int estimateDaysForBook({
    required String book,
    required int totalChapters,
    required double targetMinutesPerDay,
  }) {
    final totalMinutes = estimateTotalReadingMinutes(book, totalChapters);
    return (totalMinutes / targetMinutesPerDay).ceil();
  }

  /// Génère un plan de lecture complet jour par jour
  /// 
  /// Retourne une liste de résumés quotidiens.
  /// À utiliser AVANT l'ajustement sémantique.
  /// 
  /// Exemple:
  ///   final plan = generateReadingPlan(
  ///     book: 'Luc',
  ///     totalChapters: 24,
  ///     targetMinutesPerDay: 10,
  ///   );
  ///   
  ///   for (final day in plan) {
  ///     print('Jour ${day['dayNumber']}: ${day['range']} (~${day['approxMinutes']} min)');
  ///   }
  static List<Map<String, dynamic>> generateReadingPlan({
    required String book,
    required int totalChapters,
    required double targetMinutesPerDay,
  }) {
    final plan = <Map<String, dynamic>>[];
    int currentChapter = 1;
    int dayNumber = 1;

    while (currentChapter <= totalChapters) {
      final summary = dayReadingSummary(
        book: book,
        startChapter: currentChapter,
        totalChapters: totalChapters,
        targetMinutes: targetMinutesPerDay,
      );

      plan.add({
        'dayNumber': dayNumber,
        'book': book,
        'startChapter': summary['startChapter'],
        'endChapter': summary['endChapter'],
        'chapters': summary['chapters'],
        'approxMinutes': summary['approxMinutes'],
        'targetMinutes': summary['targetMinutes'],
        'range': summary['range'],
      });

      currentChapter = (summary['endChapter'] as int) + 1;
      dayNumber++;
    }

    return plan;
  }

  /// Ajuste la durée cible en fonction de la vitesse de lecture utilisateur
  /// 
  /// Paramètres:
  /// - baseTargetMinutes: Durée cible de base (ex: 10 min)
  /// - readingSpeed: 'slow', 'normal', 'fast'
  /// 
  /// Retourne: Durée ajustée
  /// 
  /// Exemple:
  ///   adjustForReadingSpeed(10, 'slow')  → 15 min
  ///   adjustForReadingSpeed(10, 'fast')  → 7 min
  static double adjustForReadingSpeed(
    double baseTargetMinutes,
    String readingSpeed,
  ) {
    final factor = switch (readingSpeed.toLowerCase()) {
      'slow' => 1.5,   // +50% de temps
      'fast' => 0.7,   // -30% de temps
      _ => 1.0,        // Normal
    };

    return baseTargetMinutes * factor;
  }

  /// Stats globales pour un plan généré
  /// 
  /// Retourne:
  /// - totalDays: Nombre de jours
  /// - totalMinutes: Temps total estimé
  /// - avgMinutesPerDay: Moyenne par jour
  /// - minDay: Jour le plus court
  /// - maxDay: Jour le plus long
  static Map<String, dynamic> planStats(List<Map<String, dynamic>> plan) {
    if (plan.isEmpty) {
      return {
        'totalDays': 0,
        'totalMinutes': 0,
        'avgMinutesPerDay': 0,
        'minDay': null,
        'maxDay': null,
      };
    }

    int totalMinutes = 0;
    int minMinutes = 999999;
    int maxMinutes = 0;
    Map<String, dynamic>? minDay;
    Map<String, dynamic>? maxDay;

    for (final day in plan) {
      final mins = day['approxMinutes'] as int;
      totalMinutes += mins;

      if (mins < minMinutes) {
        minMinutes = mins;
        minDay = day;
      }

      if (mins > maxMinutes) {
        maxMinutes = mins;
        maxDay = day;
      }
    }

    return {
      'totalDays': plan.length,
      'totalMinutes': totalMinutes,
      'avgMinutesPerDay': (totalMinutes / plan.length).round(),
      'minDay': minDay,
      'maxDay': maxDay,
      'variance': maxMinutes - minMinutes,
    };
  }
}


