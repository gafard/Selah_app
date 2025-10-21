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
import 'biblical_timeline_service.dart';

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
    return '$book $startChapter:$startVerse-$endChapter:$endVerse';
  }

  String get shortReference {
    if (startChapter == endChapter) {
      return '$book $startChapter';
    }
    return '$book $startChapter-$endChapter';
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
    // ═══════════════════════════════════════════════════════════════════════════
    // ANCIEN TESTAMENT
    // ═══════════════════════════════════════════════════════════════════════════
    
    'Genèse': [
      LiteraryUnit(
        name: 'Création',
        book: 'Genèse',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 25,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
        description: 'Récit de la création',
      ),
      LiteraryUnit(
        name: 'Chute de l\'homme',
        book: 'Genèse',
        startChapter: 3,
        startVerse: 1,
        endChapter: 3,
        endVerse: 24,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Déluge',
        book: 'Genèse',
        startChapter: 6,
        startVerse: 1,
        endChapter: 9,
        endVerse: 29,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Tour de Babel',
        book: 'Genèse',
        startChapter: 11,
        startVerse: 1,
        endChapter: 11,
        endVerse: 9,
        type: UnitType.narrative,
        priority: UnitPriority.medium,
      ),
      LiteraryUnit(
        name: 'Appel d\'Abraham',
        book: 'Genèse',
        startChapter: 12,
        startVerse: 1,
        endChapter: 12,
        endVerse: 20,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Sacrifice d\'Isaac',
        book: 'Genèse',
        startChapter: 22,
        startVerse: 1,
        endChapter: 22,
        endVerse: 19,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
    ],
    
    'Exode': [
      LiteraryUnit(
        name: 'Appel de Moïse',
        book: 'Exode',
        startChapter: 3,
        startVerse: 1,
        endChapter: 4,
        endVerse: 31,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Dix plaies',
        book: 'Exode',
        startChapter: 7,
        startVerse: 8,
        endChapter: 12,
        endVerse: 36,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Traversée de la mer Rouge',
        book: 'Exode',
        startChapter: 14,
        startVerse: 1,
        endChapter: 15,
        endVerse: 21,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Dix commandements',
        book: 'Exode',
        startChapter: 20,
        startVerse: 1,
        endChapter: 20,
        endVerse: 17,
        type: UnitType.discourse,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Veau d\'or',
        book: 'Exode',
        startChapter: 32,
        startVerse: 1,
        endChapter: 32,
        endVerse: 35,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
    ],
    
    'Lévitique': [
      LiteraryUnit(
        name: 'Lois sur les sacrifices',
        book: 'Lévitique',
        startChapter: 1,
        startVerse: 1,
        endChapter: 7,
        endVerse: 38,
        type: UnitType.discourse,
        priority: UnitPriority.medium,
      ),
      LiteraryUnit(
        name: 'Jour des expiations',
        book: 'Lévitique',
        startChapter: 16,
        startVerse: 1,
        endChapter: 16,
        endVerse: 34,
        type: UnitType.discourse,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Loi de sainteté',
        book: 'Lévitique',
        startChapter: 19,
        startVerse: 1,
        endChapter: 20,
        endVerse: 27,
        type: UnitType.discourse,
        priority: UnitPriority.high,
      ),
    ],
    
    'Nombres': [
      LiteraryUnit(
        name: 'Murmures dans le désert',
        book: 'Nombres',
        startChapter: 11,
        startVerse: 1,
        endChapter: 12,
        endVerse: 16,
        type: UnitType.narrative,
        priority: UnitPriority.medium,
      ),
      LiteraryUnit(
        name: 'Espionnage de Canaan',
        book: 'Nombres',
        startChapter: 13,
        startVerse: 1,
        endChapter: 14,
        endVerse: 45,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Révolte de Koré',
        book: 'Nombres',
        startChapter: 16,
        startVerse: 1,
        endChapter: 17,
        endVerse: 13,
        type: UnitType.narrative,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Deutéronome': [
      LiteraryUnit(
        name: 'Premier discours de Moïse',
        book: 'Deutéronome',
        startChapter: 1,
        startVerse: 1,
        endChapter: 4,
        endVerse: 43,
        type: UnitType.discourse,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Deuxième discours de Moïse',
        book: 'Deutéronome',
        startChapter: 5,
        startVerse: 1,
        endChapter: 26,
        endVerse: 19,
        type: UnitType.discourse,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Bénédictions et malédictions',
        book: 'Deutéronome',
        startChapter: 27,
        startVerse: 1,
        endChapter: 28,
        endVerse: 68,
        type: UnitType.discourse,
        priority: UnitPriority.high,
      ),
    ],
    
    'Josué': [
      LiteraryUnit(
        name: 'Conquête de Jéricho',
        book: 'Josué',
        startChapter: 6,
        startVerse: 1,
        endChapter: 6,
        endVerse: 27,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Partage du pays',
        book: 'Josué',
        startChapter: 13,
        startVerse: 1,
        endChapter: 21,
        endVerse: 45,
        type: UnitType.narrative,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Juges': [
      LiteraryUnit(
        name: 'Cycle des juges',
        book: 'Juges',
        startChapter: 2,
        startVerse: 6,
        endChapter: 16,
        endVerse: 31,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Gédéon',
        book: 'Juges',
        startChapter: 6,
        startVerse: 1,
        endChapter: 8,
        endVerse: 35,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Samson',
        book: 'Juges',
        startChapter: 13,
        startVerse: 1,
        endChapter: 16,
        endVerse: 31,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
    ],
    
    'Ruth': [
      LiteraryUnit(
        name: 'Livre de Ruth',
        book: 'Ruth',
        startChapter: 1,
        startVerse: 1,
        endChapter: 4,
        endVerse: 22,
        type: UnitType.narrative,
        priority: UnitPriority.high,
        description: 'Récit complet de Ruth',
      ),
    ],
    
    '1 Samuel': [
      LiteraryUnit(
        name: 'Appel de Samuel',
        book: '1 Samuel',
        startChapter: 3,
        startVerse: 1,
        endChapter: 3,
        endVerse: 21,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Onction de David',
        book: '1 Samuel',
        startChapter: 16,
        startVerse: 1,
        endChapter: 16,
        endVerse: 13,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'David et Goliath',
        book: '1 Samuel',
        startChapter: 17,
        startVerse: 1,
        endChapter: 17,
        endVerse: 58,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
    ],
    
    '2 Samuel': [
      LiteraryUnit(
        name: 'Règne de David',
        book: '2 Samuel',
        startChapter: 5,
        startVerse: 1,
        endChapter: 8,
        endVerse: 18,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Péché de David',
        book: '2 Samuel',
        startChapter: 11,
        startVerse: 1,
        endChapter: 12,
        endVerse: 31,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
    ],
    
    '1 Rois': [
      LiteraryUnit(
        name: 'Sagesse de Salomon',
        book: '1 Rois',
        startChapter: 3,
        startVerse: 1,
        endChapter: 4,
        endVerse: 34,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Construction du temple',
        book: '1 Rois',
        startChapter: 6,
        startVerse: 1,
        endChapter: 7,
        endVerse: 51,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Élie et les prophètes de Baal',
        book: '1 Rois',
        startChapter: 18,
        startVerse: 1,
        endChapter: 18,
        endVerse: 46,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
    ],
    
    '2 Rois': [
      LiteraryUnit(
        name: 'Élie enlevé au ciel',
        book: '2 Rois',
        startChapter: 2,
        startVerse: 1,
        endChapter: 2,
        endVerse: 12,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Élisée',
        book: '2 Rois',
        startChapter: 2,
        startVerse: 13,
        endChapter: 13,
        endVerse: 21,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
    ],
    
    '1 Chroniques': [
      LiteraryUnit(
        name: 'Généalogies',
        book: '1 Chroniques',
        startChapter: 1,
        startVerse: 1,
        endChapter: 9,
        endVerse: 44,
        type: UnitType.genealogy,
        priority: UnitPriority.low,
      ),
      LiteraryUnit(
        name: 'Règne de David',
        book: '1 Chroniques',
        startChapter: 11,
        startVerse: 1,
        endChapter: 29,
        endVerse: 30,
        type: UnitType.narrative,
        priority: UnitPriority.medium,
      ),
    ],
    
    '2 Chroniques': [
      LiteraryUnit(
        name: 'Règne de Salomon',
        book: '2 Chroniques',
        startChapter: 1,
        startVerse: 1,
        endChapter: 9,
        endVerse: 31,
        type: UnitType.narrative,
        priority: UnitPriority.medium,
      ),
      LiteraryUnit(
        name: 'Réforme de Josias',
        book: '2 Chroniques',
        startChapter: 34,
        startVerse: 1,
        endChapter: 35,
        endVerse: 27,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
    ],
    
    'Esdras': [
      LiteraryUnit(
        name: 'Retour d\'exil',
        book: 'Esdras',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 70,
        type: UnitType.narrative,
        priority: UnitPriority.medium,
      ),
      LiteraryUnit(
        name: 'Reconstruction du temple',
        book: 'Esdras',
        startChapter: 3,
        startVerse: 1,
        endChapter: 6,
        endVerse: 22,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
    ],
    
    'Néhémie': [
      LiteraryUnit(
        name: 'Reconstruction des murailles',
        book: 'Néhémie',
        startChapter: 1,
        startVerse: 1,
        endChapter: 7,
        endVerse: 73,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Réforme de Néhémie',
        book: 'Néhémie',
        startChapter: 8,
        startVerse: 1,
        endChapter: 13,
        endVerse: 31,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
    ],
    
    'Esther': [
      LiteraryUnit(
        name: 'Livre d\'Esther',
        book: 'Esther',
        startChapter: 1,
        startVerse: 1,
        endChapter: 10,
        endVerse: 3,
        type: UnitType.narrative,
        priority: UnitPriority.high,
        description: 'Récit complet d\'Esther',
      ),
    ],
    
    'Job': [
      LiteraryUnit(
        name: 'Prologue',
        book: 'Job',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 13,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Dialogues',
        book: 'Job',
        startChapter: 3,
        startVerse: 1,
        endChapter: 31,
        endVerse: 40,
        type: UnitType.poetry,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Discours de Dieu',
        book: 'Job',
        startChapter: 38,
        startVerse: 1,
        endChapter: 42,
        endVerse: 6,
        type: UnitType.poetry,
        priority: UnitPriority.critical,
      ),
    ],
    
    'Psaumes': [
      LiteraryUnit(
        name: 'Psaumes de louange',
        book: 'Psaumes',
        startChapter: 1,
        startVerse: 1,
        endChapter: 50,
        endVerse: 23,
        type: UnitType.poetry,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Psaumes royaux',
        book: 'Psaumes',
        startChapter: 2,
        startVerse: 1,
        endChapter: 110,
        endVerse: 7,
        type: UnitType.poetry,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Psaumes de lamentation',
        book: 'Psaumes',
        startChapter: 22,
        startVerse: 1,
        endChapter: 88,
        endVerse: 18,
        type: UnitType.poetry,
        priority: UnitPriority.high,
      ),
    ],
    
    'Proverbes': [
      LiteraryUnit(
        name: 'Proverbes de Salomon',
        book: 'Proverbes',
        startChapter: 1,
        startVerse: 1,
        endChapter: 9,
        endVerse: 18,
        type: UnitType.poetry,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Collection de proverbes',
        book: 'Proverbes',
        startChapter: 10,
        startVerse: 1,
        endChapter: 29,
        endVerse: 27,
        type: UnitType.poetry,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Ecclésiaste': [
      LiteraryUnit(
        name: 'Vanité des vanités',
        book: 'Ecclésiaste',
        startChapter: 1,
        startVerse: 1,
        endChapter: 12,
        endVerse: 14,
        type: UnitType.poetry,
        priority: UnitPriority.high,
        description: 'Réflexions sur la vie',
      ),
    ],
    
    'Cantique des Cantiques': [
      LiteraryUnit(
        name: 'Cantique des Cantiques',
        book: 'Cantique des Cantiques',
        startChapter: 1,
        startVerse: 1,
        endChapter: 8,
        endVerse: 14,
        type: UnitType.poetry,
        priority: UnitPriority.high,
        description: 'Poème d\'amour',
      ),
    ],
    
    'Ésaïe': [
      LiteraryUnit(
        name: 'Prophéties messianiques',
        book: 'Ésaïe',
        startChapter: 7,
        startVerse: 1,
        endChapter: 12,
        endVerse: 6,
        type: UnitType.prophecy,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Serviteur souffrant',
        book: 'Ésaïe',
        startChapter: 52,
        startVerse: 13,
        endChapter: 53,
        endVerse: 12,
        type: UnitType.prophecy,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Nouvelle création',
        book: 'Ésaïe',
        startChapter: 65,
        startVerse: 1,
        endChapter: 66,
        endVerse: 24,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
    ],
    
    'Jérémie': [
      LiteraryUnit(
        name: 'Appel de Jérémie',
        book: 'Jérémie',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 19,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Nouvelle alliance',
        book: 'Jérémie',
        startChapter: 31,
        startVerse: 1,
        endChapter: 31,
        endVerse: 40,
        type: UnitType.prophecy,
        priority: UnitPriority.critical,
      ),
    ],
    
    'Lamentations': [
      LiteraryUnit(
        name: 'Lamentations',
        book: 'Lamentations',
        startChapter: 1,
        startVerse: 1,
        endChapter: 5,
        endVerse: 22,
        type: UnitType.poetry,
        priority: UnitPriority.high,
        description: 'Lamentations sur Jérusalem',
      ),
    ],
    
    'Ézéchiel': [
      LiteraryUnit(
        name: 'Vision des ossements',
        book: 'Ézéchiel',
        startChapter: 37,
        startVerse: 1,
        endChapter: 37,
        endVerse: 14,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Nouveau temple',
        book: 'Ézéchiel',
        startChapter: 40,
        startVerse: 1,
        endChapter: 48,
        endVerse: 35,
        type: UnitType.prophecy,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Daniel': [
      LiteraryUnit(
        name: 'Daniel dans la fosse aux lions',
        book: 'Daniel',
        startChapter: 6,
        startVerse: 1,
        endChapter: 6,
        endVerse: 28,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Vision des quatre bêtes',
        book: 'Daniel',
        startChapter: 7,
        startVerse: 1,
        endChapter: 7,
        endVerse: 28,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
    ],
    
    'Osée': [
      LiteraryUnit(
        name: 'Mariage symbolique',
        book: 'Osée',
        startChapter: 1,
        startVerse: 1,
        endChapter: 3,
        endVerse: 5,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
    ],
    
    'Joël': [
      LiteraryUnit(
        name: 'Jour de l\'Éternel',
        book: 'Joël',
        startChapter: 1,
        startVerse: 1,
        endChapter: 3,
        endVerse: 21,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
    ],
    
    'Amos': [
      LiteraryUnit(
        name: 'Prophéties contre les nations',
        book: 'Amos',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 16,
        type: UnitType.prophecy,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Abdias': [
      LiteraryUnit(
        name: 'Prophétie contre Édom',
        book: 'Abdias',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 21,
        type: UnitType.prophecy,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Jonas': [
      LiteraryUnit(
        name: 'Jonas et le grand poisson',
        book: 'Jonas',
        startChapter: 1,
        startVerse: 1,
        endChapter: 4,
        endVerse: 11,
        type: UnitType.narrative,
        priority: UnitPriority.high,
        description: 'Récit complet de Jonas',
      ),
    ],
    
    'Michée': [
      LiteraryUnit(
        name: 'Prophétie messianique',
        book: 'Michée',
        startChapter: 5,
        startVerse: 1,
        endChapter: 5,
        endVerse: 15,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
    ],
    
    'Nahum': [
      LiteraryUnit(
        name: 'Prophétie contre Ninive',
        book: 'Nahum',
        startChapter: 1,
        startVerse: 1,
        endChapter: 3,
        endVerse: 19,
        type: UnitType.prophecy,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Habakuk': [
      LiteraryUnit(
        name: 'Dialogue avec Dieu',
        book: 'Habakuk',
        startChapter: 1,
        startVerse: 1,
        endChapter: 3,
        endVerse: 19,
        type: UnitType.prophecy,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Sophonie': [
      LiteraryUnit(
        name: 'Jour de l\'Éternel',
        book: 'Sophonie',
        startChapter: 1,
        startVerse: 1,
        endChapter: 3,
        endVerse: 20,
        type: UnitType.prophecy,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Aggée': [
      LiteraryUnit(
        name: 'Reconstruction du temple',
        book: 'Aggée',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 23,
        type: UnitType.prophecy,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Zacharie': [
      LiteraryUnit(
        name: 'Vision du grand prêtre',
        book: 'Zacharie',
        startChapter: 3,
        startVerse: 1,
        endChapter: 3,
        endVerse: 10,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
    ],
    
    'Malachie': [
      LiteraryUnit(
        name: 'Prophétie finale',
        book: 'Malachie',
        startChapter: 1,
        startVerse: 1,
        endChapter: 4,
        endVerse: 6,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════════════════
    // NOUVEAU TESTAMENT
    // ═══════════════════════════════════════════════════════════════════════════
    
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
    
    'Marc': [
      LiteraryUnit(
        name: 'Ministère en Galilée',
        book: 'Marc',
        startChapter: 1,
        startVerse: 1,
        endChapter: 8,
        endVerse: 30,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Chemin vers Jérusalem',
        book: 'Marc',
        startChapter: 8,
        startVerse: 31,
        endChapter: 10,
        endVerse: 52,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Semaine de la passion',
        book: 'Marc',
        startChapter: 11,
        startVerse: 1,
        endChapter: 16,
        endVerse: 20,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
    ],
    
    'Luc': [
      LiteraryUnit(
        name: 'Enfance de Jésus',
        book: 'Luc',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 52,
        type: UnitType.narrative,
        priority: UnitPriority.high,
      ),
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
        name: 'Prologue',
        book: 'Jean',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 18,
        type: UnitType.poetry,
        priority: UnitPriority.critical,
      ),
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
    
    'Actes': [
      LiteraryUnit(
        name: 'Pentecôte',
        book: 'Actes',
        startChapter: 2,
        startVerse: 1,
        endChapter: 2,
        endVerse: 47,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Conversion de Paul',
        book: 'Actes',
        startChapter: 9,
        startVerse: 1,
        endChapter: 9,
        endVerse: 31,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Conseil de Jérusalem',
        book: 'Actes',
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 35,
        type: UnitType.narrative,
        priority: UnitPriority.high,
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
      LiteraryUnit(
        name: 'Élection et prédestination',
        book: 'Romains',
        startChapter: 9,
        startVerse: 1,
        endChapter: 11,
        endVerse: 36,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
    ],
    
    '1 Corinthiens': [
      LiteraryUnit(
        name: 'Problèmes de l\'Église',
        book: '1 Corinthiens',
        startChapter: 1,
        startVerse: 1,
        endChapter: 4,
        endVerse: 21,
        type: UnitType.letter,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Chapitre de l\'amour',
        book: '1 Corinthiens',
        startChapter: 13,
        startVerse: 1,
        endChapter: 13,
        endVerse: 13,
        type: UnitType.poetry,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Résurrection',
        book: '1 Corinthiens',
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 58,
        type: UnitType.argument,
        priority: UnitPriority.critical,
      ),
    ],
    
    '2 Corinthiens': [
      LiteraryUnit(
        name: 'Ministère de la réconciliation',
        book: '2 Corinthiens',
        startChapter: 5,
        startVerse: 1,
        endChapter: 5,
        endVerse: 21,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Collection pour Jérusalem',
        book: '2 Corinthiens',
        startChapter: 8,
        startVerse: 1,
        endChapter: 9,
        endVerse: 15,
        type: UnitType.letter,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Galates': [
      LiteraryUnit(
        name: 'Justification par la foi',
        book: 'Galates',
        startChapter: 2,
        startVerse: 15,
        endChapter: 3,
        endVerse: 29,
        type: UnitType.argument,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Liberté en Christ',
        book: 'Galates',
        startChapter: 5,
        startVerse: 1,
        endChapter: 5,
        endVerse: 26,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
    ],
    
    'Éphésiens': [
      LiteraryUnit(
        name: 'Bénédictions spirituelles',
        book: 'Éphésiens',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 23,
        type: UnitType.poetry,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Unité de l\'Église',
        book: 'Éphésiens',
        startChapter: 4,
        startVerse: 1,
        endChapter: 4,
        endVerse: 16,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
    ],
    
    'Philippiens': [
      LiteraryUnit(
        name: 'Hymne de l\'abaissement',
        book: 'Philippiens',
        startChapter: 2,
        startVerse: 5,
        endChapter: 2,
        endVerse: 11,
        type: UnitType.poetry,
        priority: UnitPriority.critical,
      ),
    ],
    
    'Colossiens': [
      LiteraryUnit(
        name: 'Hymne christologique',
        book: 'Colossiens',
        startChapter: 1,
        startVerse: 15,
        endChapter: 1,
        endVerse: 20,
        type: UnitType.poetry,
        priority: UnitPriority.critical,
      ),
      LiteraryUnit(
        name: 'Mise en garde contre les philosophies',
        book: 'Colossiens',
        startChapter: 2,
        startVerse: 1,
        endChapter: 2,
        endVerse: 10,
        type: UnitType.argument,
        priority: UnitPriority.high,
        description: 'Mise en garde contre les philosophies trompeuses et les traditions humaines',
      ),
      LiteraryUnit(
        name: 'Circoncision spirituelle',
        book: 'Colossiens',
        startChapter: 2,
        startVerse: 11,
        endChapter: 2,
        endVerse: 15,
        type: UnitType.argument,
        priority: UnitPriority.high,
        description: 'Enseignement sur la circoncision spirituelle et la victoire sur les puissances',
      ),
      LiteraryUnit(
        name: 'Mise en garde contre les observances',
        book: 'Colossiens',
        startChapter: 2,
        startVerse: 16,
        endChapter: 2,
        endVerse: 23,
        type: UnitType.argument,
        priority: UnitPriority.medium,
        description: 'Mise en garde contre les observances religieuses et les règles humaines',
      ),
    ],
    
    '1 Thessaloniciens': [
      LiteraryUnit(
        name: 'Seconde venue',
        book: '1 Thessaloniciens',
        startChapter: 4,
        startVerse: 13,
        endChapter: 5,
        endVerse: 11,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
    ],
    
    '2 Thessaloniciens': [
      LiteraryUnit(
        name: 'Homme de péché',
        book: '2 Thessaloniciens',
        startChapter: 2,
        startVerse: 1,
        endChapter: 2,
        endVerse: 12,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
    ],
    
    '1 Timothée': [
      LiteraryUnit(
        name: 'Qualifications des anciens',
        book: '1 Timothée',
        startChapter: 3,
        startVerse: 1,
        endChapter: 3,
        endVerse: 16,
        type: UnitType.letter,
        priority: UnitPriority.medium,
      ),
    ],
    
    '2 Timothée': [
      LiteraryUnit(
        name: 'Testament spirituel',
        book: '2 Timothée',
        startChapter: 4,
        startVerse: 1,
        endChapter: 4,
        endVerse: 22,
        type: UnitType.letter,
        priority: UnitPriority.high,
      ),
    ],
    
    'Tite': [
      LiteraryUnit(
        name: 'Instructions pour Tite',
        book: 'Tite',
        startChapter: 1,
        startVerse: 1,
        endChapter: 3,
        endVerse: 15,
        type: UnitType.letter,
        priority: UnitPriority.medium,
      ),
    ],
    
    'Philémon': [
      LiteraryUnit(
        name: 'Lettre à Philémon',
        book: 'Philémon',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 25,
        type: UnitType.letter,
        priority: UnitPriority.medium,
        description: 'Lettre complète à Philémon',
      ),
    ],
    
    'Hébreux': [
      LiteraryUnit(
        name: 'Supériorité de Christ',
        book: 'Hébreux',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 18,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Chapitre de la foi',
        book: 'Hébreux',
        startChapter: 11,
        startVerse: 1,
        endChapter: 11,
        endVerse: 40,
        type: UnitType.narrative,
        priority: UnitPriority.critical,
      ),
    ],
    
    'Jacques': [
      LiteraryUnit(
        name: 'Foi et œuvres',
        book: 'Jacques',
        startChapter: 2,
        startVerse: 14,
        endChapter: 2,
        endVerse: 26,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Langue et sagesse',
        book: 'Jacques',
        startChapter: 3,
        startVerse: 1,
        endChapter: 3,
        endVerse: 18,
        type: UnitType.argument,
        priority: UnitPriority.medium,
      ),
    ],
    
    '1 Pierre': [
      LiteraryUnit(
        name: 'Souffrance et gloire',
        book: '1 Pierre',
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 10,
        type: UnitType.letter,
        priority: UnitPriority.high,
      ),
    ],
    
    '2 Pierre': [
      LiteraryUnit(
        name: 'Faux prophètes',
        book: '2 Pierre',
        startChapter: 2,
        startVerse: 1,
        endChapter: 2,
        endVerse: 22,
        type: UnitType.argument,
        priority: UnitPriority.medium,
      ),
    ],
    
    '1 Jean': [
      LiteraryUnit(
        name: 'Amour de Dieu',
        book: '1 Jean',
        startChapter: 4,
        startVerse: 7,
        endChapter: 4,
        endVerse: 21,
        type: UnitType.argument,
        priority: UnitPriority.high,
      ),
    ],
    
    '2 Jean': [
      LiteraryUnit(
        name: 'Lettre à l\'élue',
        book: '2 Jean',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 13,
        type: UnitType.letter,
        priority: UnitPriority.medium,
        description: 'Lettre complète à l\'élue',
      ),
    ],
    
    '3 Jean': [
      LiteraryUnit(
        name: 'Lettre à Gaïus',
        book: '3 Jean',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 15,
        type: UnitType.letter,
        priority: UnitPriority.medium,
        description: 'Lettre complète à Gaïus',
      ),
    ],
    
    'Jude': [
      LiteraryUnit(
        name: 'Contre les apostats',
        book: 'Jude',
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 25,
        type: UnitType.argument,
        priority: UnitPriority.medium,
        description: 'Lettre complète de Jude',
      ),
    ],
    
    'Apocalypse': [
      LiteraryUnit(
        name: 'Lettres aux sept Églises',
        book: 'Apocalypse',
        startChapter: 2,
        startVerse: 1,
        endChapter: 3,
        endVerse: 22,
        type: UnitType.letter,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Vision du trône',
        book: 'Apocalypse',
        startChapter: 4,
        startVerse: 1,
        endChapter: 5,
        endVerse: 14,
        type: UnitType.prophecy,
        priority: UnitPriority.high,
      ),
      LiteraryUnit(
        name: 'Nouvelle Jérusalem',
        book: 'Apocalypse',
        startChapter: 21,
        startVerse: 1,
        endChapter: 22,
        endVerse: 21,
        type: UnitType.prophecy,
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
    final units = getUnitsForBook(book);

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
  static List<LiteraryUnit> getUnitsForBook(String book) {
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

  /// Enrichit une description d'unité littéraire avec le contexte historique
  static Future<String> enrichDescriptionWithTimeline(String book, String? originalDescription) async {
    try {
      // Initialiser le service Timeline
      await BiblicalTimelineService.init();
      
      // Récupérer la période historique pour ce livre
      final period = await BiblicalTimelineService.getPeriodForBook(book);
      
      if (period != null) {
        final periodName = period['name'] as String? ?? '';
        final periodDescription = period['description'] as String? ?? '';
        final keyEvents = period['keyEvents'] as List<dynamic>? ?? [];
        
        // Construire le contexte enrichi
        String enrichedDescription = originalDescription ?? '';
        
        if (periodName.isNotEmpty) {
          enrichedDescription = enrichedDescription.isEmpty 
              ? 'Contexte: $periodName'
              : '$enrichedDescription — Contexte: $periodName';
        }
        
        if (periodDescription.isNotEmpty && enrichedDescription.length < 200) {
          enrichedDescription += ' — $periodDescription';
        }
        
        // Ajouter un événement clé pertinent si disponible
        if (keyEvents.isNotEmpty && enrichedDescription.length < 150) {
          final relevantEvent = keyEvents.first.toString();
          enrichedDescription += ' — $relevantEvent';
        }
        
        return enrichedDescription;
      }
      
      return originalDescription ?? '';
    } catch (e) {
      print('⚠️ Erreur enrichissement description Timeline: $e');
      return originalDescription ?? '';
    }
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

  /// ═══════════════════════════════════════════════════════════════════════
  /// CHRONOLOGIE BIBLIQUE INTÉGRATION
  /// ═══════════════════════════════════════════════════════════════════════

  /// Enrichit une unité littéraire avec le contexte historique
  static Future<LiteraryUnit> enrichWithHistoricalContext(LiteraryUnit unit) async {
    try {
      // Déterminer la période historique basée sur le livre
      final period = await _getHistoricalPeriodForBook(unit.book);
      
      if (period != null) {
        // Enrichir la description avec le contexte historique
        final enrichedDescription = _buildEnrichedDescription(unit, period);
        
        return LiteraryUnit(
          name: unit.name,
          book: unit.book,
          startChapter: unit.startChapter,
          startVerse: unit.startVerse,
          endChapter: unit.endChapter,
          endVerse: unit.endVerse,
          type: unit.type,
          priority: unit.priority,
          description: enrichedDescription,
        );
      }
    } catch (e) {
      print('⚠️ Erreur enrichissement contexte historique: $e');
    }
    
    return unit;
  }

  /// Détermine la période historique pour un livre
  static Future<Map<String, dynamic>?> _getHistoricalPeriodForBook(String book) async {
    try {
        final periods = await BiblicalTimelineService.getPeriods();
      
      for (final period in periods) {
        final books = period['books'] as List<dynamic>? ?? [];
        if (books.any((b) => b.toString().toLowerCase().contains(book.toLowerCase()))) {
          return period;
        }
      }
    } catch (e) {
      print('⚠️ Erreur recherche période historique: $e');
    }
    
    return null;
  }

  /// Construit une description enrichie avec le contexte historique
  static String _buildEnrichedDescription(LiteraryUnit unit, Map<String, dynamic> period) {
    final baseDescription = unit.description ?? '';
    final periodName = period['name'] as String? ?? '';
    final periodDescription = period['description'] as String? ?? '';
    final themes = period['themes'] as List<dynamic>? ?? [];
    final keyEvents = period['keyEvents'] as List<dynamic>? ?? [];
    
    final contextThemes = themes.take(3).join(', ');
    final contextEvents = keyEvents.take(2).join(', ');
    
    final enrichedParts = <String>[];
    
    if (baseDescription.isNotEmpty) {
      enrichedParts.add(baseDescription);
    }
    
    enrichedParts.add('Contexte historique: $periodName ($periodDescription)');
    
    if (contextThemes.isNotEmpty) {
      enrichedParts.add('Thèmes de l\'époque: $contextThemes');
    }
    
    if (contextEvents.isNotEmpty) {
      enrichedParts.add('Événements clés: $contextEvents');
    }
    
    return enrichedParts.join(' • ');
  }

  /// Ajuste un passage avec le contexte chronologique
  static Future<PassageBoundary> adjustPassageWithTimeline({
    required String book,
    required int startChapter,
    required int startVerse,
    required int endChapter,
    required int endVerse,
  }) async {
    // Ajustement sémantique standard
    final boundary = adjustPassageVerses(
      book: book,
      startChapter: startChapter,
      startVerse: startVerse,
      endChapter: endChapter,
      endVerse: endVerse,
    );

    // Enrichir avec le contexte historique si une unité est incluse
    if (boundary.includedUnit != null) {
      try {
        final enrichedUnit = await enrichWithHistoricalContext(boundary.includedUnit!);
        
        return PassageBoundary(
          book: boundary.book,
          startChapter: boundary.startChapter,
          startVerse: boundary.startVerse,
          endChapter: boundary.endChapter,
          endVerse: boundary.endVerse,
          adjusted: boundary.adjusted,
          reason: '${boundary.reason} (contexte historique: ${enrichedUnit.description})',
          includedUnit: enrichedUnit,
          tags: boundary.tags,
        );
      } catch (e) {
        print('⚠️ Erreur enrichissement contexte: $e');
      }
    }

    return boundary;
  }

  /// Recherche des unités littéraires par période historique
  static Future<List<LiteraryUnit>> searchUnitsByHistoricalPeriod(String periodName) async {
    final results = <LiteraryUnit>[];
    
    try {
        final periods = await BiblicalTimelineService.getPeriods();
      final targetPeriod = periods.firstWhere(
        (p) => p['name'].toString().toLowerCase().contains(periodName.toLowerCase()),
        orElse: () => <String, dynamic>{},
      );
      
      if (targetPeriod.isNotEmpty) {
        final books = targetPeriod['books'] as List<dynamic>? ?? [];
        
        for (final book in books) {
          final bookName = book.toString();
          if (_literaryUnits.containsKey(bookName)) {
            results.addAll(_literaryUnits[bookName]!);
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur recherche par période: $e');
    }
    
    return results;
  }

  /// Recherche des unités littéraires par thème historique
  static Future<List<LiteraryUnit>> searchUnitsByHistoricalTheme(String theme) async {
    final results = <LiteraryUnit>[];
    
    try {
      final periods = await BiblicalTimelineService.searchPeriodsByTheme(theme);
      
      for (final period in periods) {
        final books = period['books'] as List<dynamic>? ?? [];
        
        for (final book in books) {
          final bookName = book.toString();
          if (_literaryUnits.containsKey(bookName)) {
            results.addAll(_literaryUnits[bookName]!);
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur recherche par thème: $e');
    }
    
    return results;
  }

  /// Recherche des unités littéraires par personnage historique
  static Future<List<LiteraryUnit>> searchUnitsByHistoricalCharacter(String character) async {
    final results = <LiteraryUnit>[];
    
    try {
      final periods = await BiblicalTimelineService.searchPeriodsByCharacter(character);
      
      for (final period in periods) {
        final books = period['books'] as List<dynamic>? ?? [];
        
        for (final book in books) {
          final bookName = book.toString();
          if (_literaryUnits.containsKey(bookName)) {
            results.addAll(_literaryUnits[bookName]!);
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur recherche par personnage: $e');
    }
    
    return results;
  }
}


