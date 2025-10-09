/// ═══════════════════════════════════════════════════════════════════════════
/// SEMANTIC PASSAGE BOUNDARY SERVICE v2.0 - Production Grade
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Améliore v1 avec :
/// ✅ Précision verse-level (pas juste chapitres)
/// ✅ Convergence itérative (unités imbriquées)
/// ✅ Sélection dominante (priorité + taille)
/// ✅ Intégration minutes/jour via ChapterIndex
/// ✅ Support collections > unités simples
/// ✅ Données offline (JSON → Hive)
///
/// Audit complet : voir AUDIT_SEMANTIC_SERVICE.md
/// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:hive/hive.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MODELS
/// ═══════════════════════════════════════════════════════════════════════════

/// Range de versets (verse-level precision)
class VerseRange {
  final int sc; // startChapter
  final int sv; // startVerse
  final int ec; // endChapter
  final int ev; // endVerse

  const VerseRange(this.sc, this.sv, this.ec, this.ev);

  VerseRange copyWith({int? sc, int? sv, int? ec, int? ev}) {
    return VerseRange(
      sc ?? this.sc,
      sv ?? this.sv,
      ec ?? this.ec,
      ev ?? this.ev,
    );
  }

  @override
  String toString() => '($sc:$sv → $ec:$ev)';
}

/// Priorité d'une unité littéraire
enum UnitPriority {
  critical, // Sermon sur la montagne, paraboles majeures
  high, // Discours importants, récits clés
  medium, // Sections thématiques
  low, // Regroupements suggestifs
}

/// Type d'unité littéraire
enum UnitType {
  parable, // Parabole
  discourse, // Discours
  narrative, // Récit continu
  collection, // Collection de paraboles/miracles
  argument, // Argument théologique
  poetry, // Psaume/poème
  prophecy, // Oracle prophétique
  genealogy, // Généalogie
  letter, // Section de lettre
}

/// Unité littéraire (ex: Sermon sur la montagne)
class LiteraryUnit {
  final String name;
  final String book;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final UnitType type;
  final UnitPriority priority;
  final String? description;

  const LiteraryUnit({
    required this.name,
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.type,
    required this.priority,
    this.description,
  });

  int get sizeInVerses {
    if (startChapter == endChapter) {
      return endVerse - startVerse + 1;
    }
    // Approximation (nécessite ChapterIndex pour précision)
    return (endChapter - startChapter + 1) * 25;
  }

  VerseRange get range => VerseRange(startChapter, startVerse, endChapter, endVerse);

  Map<String, dynamic> toJson() => {
        'name': name,
        'book': book,
        'startChapter': startChapter,
        'startVerse': startVerse,
        'endChapter': endChapter,
        'endVerse': endVerse,
        'type': type.name,
        'priority': priority.name,
        'description': description,
      };

  factory LiteraryUnit.fromJson(Map<String, dynamic> json) => LiteraryUnit(
        name: json['name'] as String,
        book: json['book'] as String,
        startChapter: json['startChapter'] as int,
        startVerse: json['startVerse'] as int,
        endChapter: json['endChapter'] as int,
        endVerse: json['endVerse'] as int,
        type: UnitType.values.firstWhere((t) => t.name == json['type']),
        priority: UnitPriority.values.firstWhere((p) => p.name == json['priority']),
        description: json['description'] as String?,
      );
}

/// Résultat d'ajustement de passage
class PassageBoundary {
  final String book;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final bool adjusted;
  final String reason;
  final LiteraryUnit? includedUnit;
  final List<String>? tags;

  const PassageBoundary({
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.adjusted,
    required this.reason,
    this.includedUnit,
    this.tags,
  });

  String get reference {
    if (startChapter == endChapter) {
      if (startVerse == endVerse) {
        return '$book $startChapter:$startVerse';
      }
      return '$book $startChapter:$startVerse-$endVerse';
    }
    return '$book $startChapter:$startVerse–$endChapter:$endVerse';
  }

  String get shortReference {
    if (startChapter == endChapter) {
      return '$book $startChapter';
    }
    return '$book $startChapter–$endChapter';
  }
}

/// Passage quotidien optimisé
class DailyPassage {
  final int dayNumber;
  final String reference;
  final String book;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final bool wasAdjusted;
  final String? adjustmentReason;
  final LiteraryUnit? includedUnit;
  final int? estimatedMinutes;
  final List<String>? tags;

  const DailyPassage({
    required this.dayNumber,
    required this.reference,
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    this.wasAdjusted = false,
    this.adjustmentReason,
    this.includedUnit,
    this.estimatedMinutes,
    this.tags,
  });

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'reference': reference,
        'book': book,
        'startChapter': startChapter,
        'startVerse': startVerse,
        'endChapter': endChapter,
        'endVerse': endVerse,
        'wasAdjusted': wasAdjusted,
        'adjustmentReason': adjustmentReason,
        'includedUnit': includedUnit?.toJson(),
        'estimatedMinutes': estimatedMinutes,
        'tags': tags,
      };
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CHAPTER INDEX SERVICE (offline)
/// ═══════════════════════════════════════════════════════════════════════════

abstract class ChapterIndex {
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox('chapter_index');
  }

  /// Nombre de versets dans un chapitre
  static int verseCount(String book, int chapter) {
    final key = 'verses:$book:$chapter';
    return _box?.get(key, defaultValue: 25) ?? 25; // fallback intelligent
  }

  /// Densité de lecture du livre (1.0 = narratif, 1.25 = épître dense)
  static double density(String book) {
    final key = 'density:$book';
    final stored = _box?.get(key, defaultValue: 1.0) ?? 1.0;
    return stored as double;
  }

  /// Estimation du temps de lecture (en secondes)
  static int estimateSeconds({
    required String book,
    required int startChapter,
    required int startVerse,
    required int endChapter,
    required int endVerse,
  }) {
    int totalVerses = 0;

    if (startChapter == endChapter) {
      totalVerses = endVerse - startVerse + 1;
    } else {
      // Premier chapitre
      totalVerses += verseCount(book, startChapter) - startVerse + 1;
      // Chapitres intermédiaires
      for (int ch = startChapter + 1; ch < endChapter; ch++) {
        totalVerses += verseCount(book, ch);
      }
      // Dernier chapitre
      totalVerses += endVerse;
    }

    final d = density(book);
    return (totalVerses * d * 2.0).round(); // 2s/verset ajusté densité
  }

  /// Hydratation depuis JSON
  static Future<void> hydrate(Map<String, dynamic> data) async {
    await init();

    // Versets par chapitre
    final verses = data['verses'] as Map<String, dynamic>? ?? {};
    for (final entry in verses.entries) {
      await _box?.put('verses:${entry.key}', entry.value);
    }

    // Densités par livre
    final densities = data['densities'] as Map<String, dynamic>? ?? {};
    for (final entry in densities.entries) {
      await _box?.put('density:${entry.key}', entry.value);
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SEMANTIC PASSAGE BOUNDARY SERVICE v2
/// ═══════════════════════════════════════════════════════════════════════════

class SemanticPassageBoundaryService {
  static Box? _unitsBox;

  static Future<void> init() async {
    _unitsBox = await Hive.openBox('literary_units');
    await ChapterIndex.init();
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// KNOWLEDGE BASE - Unités littéraires enrichies
  /// ═══════════════════════════════════════════════════════════════════════

  static final Map<String, List<LiteraryUnit>> _literaryUnits = {
    'Matthieu': [
      LiteraryUnit(
        name: 'Sermon sur la montagne',
        book: 'Matthieu',
        startChapter: 5,
        startVerse: 1,
        endChapter: 7,
        endVerse: 29,
        type: UnitType.discourse,
        priority: UnitPriority.critical,
        description: 'Enseignement fondamental de Jésus',
      ),
      LiteraryUnit(
        name: 'Discours missionnaire',
        book: 'Matthieu',
        startChapter: 10,
        startVerse: 1,
        endChapter: 10,
        endVerse: 42,
        type: UnitType.discourse,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Paraboles du Royaume',
        book: 'Matthieu',
        startChapter: 13,
        startVerse: 1,
        endChapter: 13,
        endVerse: 52,
        type: UnitType.collection,
        priority: UnitPriority.critical,
        description: '7 paraboles sur le Royaume',
      ),
      LiteraryUnit(
        name: 'Discours sur l\'Église',
        book: 'Matthieu',
        startChapter: 18,
        startVerse: 1,
        endChapter: 18,
        endVerse: 35,
        type: UnitType.discourse,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Discours eschatologique',
        book: 'Matthieu',
        startChapter: 24,
        startVerse: 1,
        endChapter: 25,
        endVerse: 46,
        type: UnitType.discourse,
        priority: UnitPriority.critical,
      ),
    ],
    'Luc': [
      LiteraryUnit(
        name: 'Collection de paraboles (Luc 15)',
        book: 'Luc',
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 32,
        type: UnitType.collection,
        priority: UnitPriority.critical,
        description: 'Brebis, drachme, fils prodigue',
      ),
      LiteraryUnit(
        name: 'Parabole de la brebis perdue',
        book: 'Luc',
        startChapter: 15,
        startVerse: 3,
        endChapter: 15,
        endVerse: 7,
        type: UnitType.parable,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Parabole de la drachme perdue',
        book: 'Luc',
        startChapter: 15,
        startVerse: 8,
        endChapter: 15,
        endVerse: 10,
        type: UnitType.parable,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Parabole du fils prodigue',
        book: 'Luc',
        startChapter: 15,
        startVerse: 11,
        endChapter: 15,
        endVerse: 32,
        type: UnitType.parable,
        priority: UnitPriority.critical,
      ),
    ],
    'Jean': [
      LiteraryUnit(
        name: 'Discours du pain de vie',
        book: 'Jean',
        startChapter: 6,
        startVerse: 22,
        endChapter: 6,
        endVerse: 71,
        type: UnitType.discourse,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Discours d\'adieu (partie 1)',
        book: 'Jean',
        startChapter: 13,
        startVerse: 1,
        endChapter: 14,
        endVerse: 31,
        type: UnitType.discourse,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Discours d\'adieu (partie 2)',
        book: 'Jean',
        startChapter: 15,
        startVerse: 1,
        endChapter: 17,
        endVerse: 26,
        type: UnitType.discourse,
        priority: UnitPriority.critical,
        description: 'Cep, haine, Esprit, prière sacerdotale',
      ),
    ],
    'Romains': [
      LiteraryUnit(
        name: 'Argument sur la justification',
        book: 'Romains',
        startChapter: 3,
        startVerse: 21,
        endChapter: 5,
        endVerse: 21,
        type: UnitType.argument,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Vie par l\'Esprit',
        book: 'Romains',
        startChapter: 8,
        startVerse: 1,
        endChapter: 8,
        endVerse: 39,
        type: UnitType.argument,
        priority: UnitPriority.critical,
      ),
    ],
  };

  /// ═══════════════════════════════════════════════════════════════════════
  /// CORE ALGORITHMS - Verse-level precision
  /// ═══════════════════════════════════════════════════════════════════════

  /// Vérifie si un range coupe une unité littéraire
  static bool _cutsUnit(VerseRange range, LiteraryUnit unit) {
    final uRange = unit.range;

    // L'unité est-elle partiellement incluse ?
    final rangeStart = _versePosition(range.sc, range.sv);
    final rangeEnd = _versePosition(range.ec, range.ev);
    final unitStart = _versePosition(uRange.sc, uRange.sv);
    final unitEnd = _versePosition(uRange.ec, uRange.ev);

    // Cas 1 : range coupe le début de l'unité
    if (rangeStart < unitStart && rangeEnd >= unitStart && rangeEnd < unitEnd) {
      return true;
    }

    // Cas 2 : range coupe la fin de l'unité
    if (rangeStart > unitStart && rangeStart <= unitEnd && rangeEnd > unitEnd) {
      return true;
    }

    return false;
  }

  /// Position absolue approximative d'un verset (pour comparaisons)
  static int _versePosition(int chapter, int verse) {
    return chapter * 1000 + verse;
  }

  /// Sélectionne l'unité dominante parmi plusieurs cuts
  static LiteraryUnit? _pickDominantCut(List<LiteraryUnit> cuts) {
    if (cuts.isEmpty) return null;

    // Trier par : priorité (critical > high > ...), puis taille
    cuts.sort((a, b) {
      // 1. Priorité (index plus petit = priorité plus haute)
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;

      // 2. Type : collection > autres
      if (a.type == UnitType.collection && b.type != UnitType.collection) {
        return -1;
      }
      if (b.type == UnitType.collection && a.type != UnitType.collection) {
        return 1;
      }

      // 3. Taille (plus grand = mieux)
      return b.sizeInVerses.compareTo(a.sizeInVerses);
    });

    return cuts.first;
  }

  /// Résout un cut en incluant l'unité complète
  static VerseRange _includeUnit(VerseRange range, LiteraryUnit unit) {
    final uRange = unit.range;
    final rangeStart = _versePosition(range.sc, range.sv);
    final rangeEnd = _versePosition(range.ec, range.ev);
    final unitStart = _versePosition(uRange.sc, uRange.sv);
    final unitEnd = _versePosition(uRange.ec, uRange.ev);

    // Inclure l'unité complète
    final newStart = rangeStart < unitStart ? rangeStart : unitStart;
    final newEnd = rangeEnd > unitEnd ? rangeEnd : unitEnd;

    return VerseRange(
      newStart ~/ 1000,
      newStart % 1000,
      newEnd ~/ 1000,
      newEnd % 1000,
    );
  }

  /// Résout un cut selon la priorité de l'unité
  static VerseRange _resolveCut(VerseRange range, LiteraryUnit unit) {
    if (unit.priority == UnitPriority.critical ||
        unit.priority == UnitPriority.high ||
        unit.type == UnitType.collection) {
      // Inclure l'unité complète
      return _includeUnit(range, unit);
    }

    // Pour low/medium : exclure l'unité (ajuster avant)
    final uRange = unit.range;
    final unitStart = _versePosition(uRange.sc, uRange.sv);
    final rangeEnd = _versePosition(range.ec, range.ev);

    if (rangeEnd > unitStart) {
      // Terminer juste avant l'unité
      return VerseRange(
        range.sc,
        range.sv,
        uRange.sc,
        max(1, uRange.sv - 1),
      );
    }

    return range;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PUBLIC API - Verse-level
  /// ═══════════════════════════════════════════════════════════════════════

  /// Ajuste un passage pour respecter les unités littéraires (verse-level)
  static PassageBoundary adjustPassageVerses({
    required String book,
    required int startChapter,
    required int startVerse,
    required int endChapter,
    required int endVerse,
  }) {
    var range = VerseRange(startChapter, startVerse, endChapter, endVerse);
    final units = _getUnitsForBook(book);

    LiteraryUnit? finalUnit;
    String reason = 'Aucune unité coupée';
    int iterations = 0;

    // Convergence itérative (max 5 pour éviter edge-cases)
    for (int i = 0; i < 5; i++) {
      iterations = i + 1;
      final cuts = units.where((u) => _cutsUnit(range, u)).toList();

      if (cuts.isEmpty) {
        reason = i == 0
            ? 'Aucune unité coupée'
            : 'Ajusté pour ${iterations - 1} unité(s) imbriquée(s)';
        break;
      }

      final dominantUnit = _pickDominantCut(cuts)!;
      finalUnit = dominantUnit;
      range = _resolveCut(range, dominantUnit);
      reason = 'Inclus "${dominantUnit.name}" (${dominantUnit.priority.name})';
    }

    // Vérification finale
    if (iterations >= 5) {
      reason = 'Ajusté (limite itérations atteinte)';
    }

    return PassageBoundary(
      book: book,
      startChapter: range.sc,
      startVerse: range.sv,
      endChapter: range.ec,
      endVerse: range.ev,
      adjusted: iterations > 0 && (range.sc != startChapter || range.sv != startVerse || range.ec != endChapter || range.ev != endVerse),
      reason: reason,
      includedUnit: finalUnit,
      tags: finalUnit != null ? [finalUnit.type.name] : null,
    );
  }

  /// Ajuste un passage (chapitre-level, backward compat)
  static PassageBoundary adjustPassageChapters({
    required String book,
    required int startChapter,
    required int endChapter,
  }) {
    final startVerse = 1;
    final endVerse = ChapterIndex.verseCount(book, endChapter);

    return adjustPassageVerses(
      book: book,
      startChapter: startChapter,
      startVerse: startVerse,
      endChapter: endChapter,
      endVerse: endVerse,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// PLAN GENERATION - Minutes/jour optimized
  /// ═══════════════════════════════════════════════════════════════════════

  /// Génère un plan optimisé basé sur minutes/jour
  static List<DailyPassage> splitByTargetMinutes({
    required String book,
    required int totalChapters,
    required int targetDays,
    required int minutesPerDay,
  }) {
    final targetSeconds = minutesPerDay * 60;
    final passages = <DailyPassage>[];

    int sc = 1, sv = 1, day = 1;

    while (sc <= totalChapters && day <= targetDays) {
      int cumulSeconds = 0;
      int ec = sc, ev = sv;

      // Grossir jusqu'à atteindre le poids cible
      while (cumulSeconds < targetSeconds && ec <= totalChapters) {
        final chapterVerseCount = ChapterIndex.verseCount(book, ec);

        // Si même chapitre, compter les versets restants
        if (ec == sc) {
          final remainingVerses = chapterVerseCount - sv + 1;
          final estimatedSec = ChapterIndex.estimateSeconds(
            book: book,
            startChapter: sc,
            startVerse: sv,
            endChapter: ec,
            endVerse: chapterVerseCount,
          );

          if (cumulSeconds + estimatedSec <= targetSeconds) {
            cumulSeconds += estimatedSec;
            ev = chapterVerseCount;
            ec++;
            ev = 1;
          } else {
            // Chercher le bon verset de fin
            final versesNeeded = ((targetSeconds - cumulSeconds) / 2.0 / ChapterIndex.density(book)).round();
            ev = min(chapterVerseCount, sv + versesNeeded - 1);
            break;
          }
        } else {
          // Chapitre suivant
          final chapterSec = ChapterIndex.estimateSeconds(
            book: book,
            startChapter: ec,
            startVerse: 1,
            endChapter: ec,
            endVerse: chapterVerseCount,
          );

          if (cumulSeconds + chapterSec <= targetSeconds) {
            cumulSeconds += chapterSec;
            ev = chapterVerseCount;
            ec++;
          } else {
            break;
          }
        }
      }

      // Ajuster sémantiquement
      final adj = adjustPassageVerses(
        book: book,
        startChapter: sc,
        startVerse: sv,
        endChapter: ec,
        endVerse: ev,
      );

      final estimatedMinutes = ChapterIndex.estimateSeconds(
            book: book,
            startChapter: adj.startChapter,
            startVerse: adj.startVerse,
            endChapter: adj.endChapter,
            endVerse: adj.endVerse,
          ) ~/
          60;

      passages.add(DailyPassage(
        dayNumber: day,
        reference: adj.reference,
        book: book,
        startChapter: adj.startChapter,
        startVerse: adj.startVerse,
        endChapter: adj.endChapter,
        endVerse: adj.endVerse,
        wasAdjusted: adj.adjusted,
        adjustmentReason: adj.reason,
        includedUnit: adj.includedUnit,
        estimatedMinutes: estimatedMinutes,
        tags: adj.tags,
      ));

      // Prochain bloc
      sc = adj.endChapter;
      sv = adj.endVerse + 1;

      // Si on a fini le chapitre, passer au suivant
      if (sv > ChapterIndex.verseCount(book, sc)) {
        sc++;
        sv = 1;
      }

      day++;
    }

    return passages;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// DATA MANAGEMENT - Offline
  /// ═══════════════════════════════════════════════════════════════════════

  /// Récupère les unités pour un livre (cache → Hive → hardcoded)
  static List<LiteraryUnit> _getUnitsForBook(String book) {
    // 1. Essayer cache mémoire
    if (_literaryUnits.containsKey(book)) {
      return _literaryUnits[book]!;
    }

    // 2. Essayer Hive
    final stored = _unitsBox?.get('units:$book') as List<dynamic>?;
    if (stored != null) {
      return stored
          .map((json) => LiteraryUnit.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    // 3. Fallback vide
    return const [];
  }

  /// Hydrate les unités depuis JSON
  static Future<void> hydrateUnits(Map<String, dynamic> data) async {
    await init();

    for (final entry in data.entries) {
      final book = entry.key;
      final units = (entry.value as List)
          .map((json) => LiteraryUnit.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache mémoire
      _literaryUnits[book] = units;

      // Hive
      await _unitsBox?.put(
        'units:$book',
        units.map((u) => u.toJson()).toList(),
      );
    }
  }

  /// Stats de la base de connaissances
  static Map<String, int> getStats() {
    return {
      'totalBooks': _literaryUnits.length,
      'totalUnits': _literaryUnits.values.fold(0, (sum, units) => sum + units.length),
      'criticalUnits': _literaryUnits.values
          .expand((units) => units)
          .where((u) => u.priority == UnitPriority.critical)
          .length,
      'collections': _literaryUnits.values
          .expand((units) => units)
          .where((u) => u.type == UnitType.collection)
          .length,
    };
  }
}

