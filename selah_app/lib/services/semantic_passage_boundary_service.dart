import 'dart:math';

/// Service de détection et respect des frontières sémantiques des passages bibliques
/// 
/// Problème résolu :
/// - Éviter de couper une parabole au milieu
/// - Respecter les unités narratives complètes
/// - Garder les discours cohérents
/// - Préserver les récits complets
/// 
/// Exemple :
/// ❌ Avant : Luc 15:1-10 (coupe la parabole de la brebis perdue)
/// ✅ Après : Luc 15:1-32 (les 3 paraboles complètes)
class SemanticPassageBoundaryService {
  
  /// Base de données des unités littéraires (paraboles, discours, récits)
  static const Map<String, List<LiteraryUnit>> _literaryUnits = {
    
    // ═══════════════════════════════════════════════════════════════
    // MATTHIEU
    // ═══════════════════════════════════════════════════════════════
    'Matthieu': [
      // Sermon sur la montagne (ne PAS couper !)
      LiteraryUnit(
        name: 'Sermon sur la montagne',
        type: UnitType.discourse,
        startChapter: 5,
        startVerse: 1,
        endChapter: 7,
        endVerse: 29,
        priority: UnitPriority.critical, // Ne jamais couper
        tags: ['sermon', 'enseignement', 'béatitudes', 'loi'],
      ),
      
      // Paraboles du Royaume (Matthieu 13)
      LiteraryUnit(
        name: 'Parabole du semeur',
        type: UnitType.parable,
        startChapter: 13,
        startVerse: 1,
        endChapter: 13,
        endVerse: 23,
        priority: UnitPriority.high,
        tags: ['parabole', 'semeur', 'explication'],
      ),
      LiteraryUnit(
        name: 'Paraboles du Royaume (ensemble)',
        type: UnitType.parableCollection,
        startChapter: 13,
        startVerse: 1,
        endChapter: 13,
        endVerse: 52,
        priority: UnitPriority.medium,
        tags: ['paraboles', 'royaume', 'collection'],
      ),
      
      // Récit de la Passion
      LiteraryUnit(
        name: 'Récit de la Passion',
        type: UnitType.narrative,
        startChapter: 26,
        startVerse: 1,
        endChapter: 27,
        endVerse: 66,
        priority: UnitPriority.critical,
        tags: ['passion', 'crucifixion', 'récit'],
      ),
      
      // Résurrection
      LiteraryUnit(
        name: 'Récit de la Résurrection',
        type: UnitType.narrative,
        startChapter: 28,
        startVerse: 1,
        endChapter: 28,
        endVerse: 20,
        priority: UnitPriority.critical,
        tags: ['résurrection', 'apparitions'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // LUC
    // ═══════════════════════════════════════════════════════════════
    'Luc': [
      // 3 paraboles de Luc 15 (ne PAS séparer !)
      LiteraryUnit(
        name: 'Parabole de la brebis perdue',
        type: UnitType.parable,
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 7,
        priority: UnitPriority.medium,
        tags: ['parabole', 'perdu', 'joie'],
      ),
      LiteraryUnit(
        name: 'Parabole de la drachme perdue',
        type: UnitType.parable,
        startChapter: 15,
        startVerse: 8,
        endChapter: 15,
        endVerse: 10,
        priority: UnitPriority.medium,
        tags: ['parabole', 'perdu', 'joie'],
      ),
      LiteraryUnit(
        name: 'Parabole du fils prodigue',
        type: UnitType.parable,
        startChapter: 15,
        startVerse: 11,
        endChapter: 15,
        endVerse: 32,
        priority: UnitPriority.high,
        tags: ['parabole', 'prodigue', 'pardon', 'père'],
      ),
      // Mieux : Les 3 ensemble
      LiteraryUnit(
        name: 'Les 3 paraboles de ce qui était perdu',
        type: UnitType.parableCollection,
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 32,
        priority: UnitPriority.critical, // À lire ensemble !
        tags: ['paraboles', 'perdu', 'retrouvé', 'joie', 'pardon'],
      ),
      
      // Nativité
      LiteraryUnit(
        name: 'Récit de la Nativité',
        type: UnitType.narrative,
        startChapter: 2,
        startVerse: 1,
        endChapter: 2,
        endVerse: 20,
        priority: UnitPriority.critical,
        tags: ['nativité', 'naissance', 'bergers'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // JEAN
    // ═══════════════════════════════════════════════════════════════
    'Jean': [
      // Prologue (unité théologique)
      LiteraryUnit(
        name: 'Prologue - Le Verbe fait chair',
        type: UnitType.theological,
        startChapter: 1,
        startVerse: 1,
        endChapter: 1,
        endVerse: 18,
        priority: UnitPriority.critical,
        tags: ['prologue', 'logos', 'création'],
      ),
      
      // Discours du pain de vie
      LiteraryUnit(
        name: 'Discours du pain de vie',
        type: UnitType.discourse,
        startChapter: 6,
        startVerse: 22,
        endChapter: 6,
        endVerse: 71,
        priority: UnitPriority.high,
        tags: ['pain', 'vie', 'eucharistie'],
      ),
      
      // Discours d'adieu (chapitres 13-17)
      LiteraryUnit(
        name: 'Discours d\'adieu et prière sacerdotale',
        type: UnitType.discourse,
        startChapter: 13,
        startVerse: 1,
        endChapter: 17,
        endVerse: 26,
        priority: UnitPriority.critical,
        tags: ['adieu', 'esprit', 'prière', 'unité'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // ACTES
    // ═══════════════════════════════════════════════════════════════
    'Actes': [
      // Pentecôte
      LiteraryUnit(
        name: 'Récit de la Pentecôte',
        type: UnitType.narrative,
        startChapter: 2,
        startVerse: 1,
        endChapter: 2,
        endVerse: 47,
        priority: UnitPriority.critical,
        tags: ['pentecôte', 'esprit', 'langues'],
      ),
      
      // Conversion de Paul
      LiteraryUnit(
        name: 'Conversion de Saul/Paul',
        type: UnitType.narrative,
        startChapter: 9,
        startVerse: 1,
        endChapter: 9,
        endVerse: 31,
        priority: UnitPriority.high,
        tags: ['conversion', 'paul', 'damas'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // ROMAINS
    // ═══════════════════════════════════════════════════════════════
    'Romains': [
      // Justification par la foi
      LiteraryUnit(
        name: 'Justification par la foi',
        type: UnitType.theological,
        startChapter: 3,
        startVerse: 21,
        endChapter: 5,
        endVerse: 21,
        priority: UnitPriority.high,
        tags: ['justification', 'foi', 'grâce'],
      ),
      
      // Vie dans l'Esprit
      LiteraryUnit(
        name: 'La vie dans l\'Esprit',
        type: UnitType.theological,
        startChapter: 8,
        startVerse: 1,
        endChapter: 8,
        endVerse: 39,
        priority: UnitPriority.critical,
        tags: ['esprit', 'adoption', 'gloire'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // 1 CORINTHIENS
    // ═══════════════════════════════════════════════════════════════
    '1 Corinthiens': [
      // Hymne à l'amour
      LiteraryUnit(
        name: 'Hymne à l\'amour (Agapè)',
        type: UnitType.poetic,
        startChapter: 13,
        startVerse: 1,
        endChapter: 13,
        endVerse: 13,
        priority: UnitPriority.critical,
        tags: ['amour', 'agapè', 'hymne'],
      ),
      
      // Résurrection
      LiteraryUnit(
        name: 'Enseignement sur la résurrection',
        type: UnitType.theological,
        startChapter: 15,
        startVerse: 1,
        endChapter: 15,
        endVerse: 58,
        priority: UnitPriority.high,
        tags: ['résurrection', 'corps', 'victoire'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // GENÈSE
    // ═══════════════════════════════════════════════════════════════
    'Genèse': [
      // Création
      LiteraryUnit(
        name: 'Récit de la Création',
        type: UnitType.narrative,
        startChapter: 1,
        startVerse: 1,
        endChapter: 2,
        endVerse: 25,
        priority: UnitPriority.critical,
        tags: ['création', 'origine', 'adam', 'eve'],
      ),
      
      // Chute
      LiteraryUnit(
        name: 'La Chute',
        type: UnitType.narrative,
        startChapter: 3,
        startVerse: 1,
        endChapter: 3,
        endVerse: 24,
        priority: UnitPriority.critical,
        tags: ['chute', 'péché', 'serpent'],
      ),
      
      // Déluge
      LiteraryUnit(
        name: 'Le Déluge et l\'Arche de Noé',
        type: UnitType.narrative,
        startChapter: 6,
        startVerse: 5,
        endChapter: 9,
        endVerse: 17,
        priority: UnitPriority.high,
        tags: ['déluge', 'noé', 'arche', 'alliance'],
      ),
      
      // Abraham
      LiteraryUnit(
        name: 'Sacrifice d\'Isaac',
        type: UnitType.narrative,
        startChapter: 22,
        startVerse: 1,
        endChapter: 22,
        endVerse: 19,
        priority: UnitPriority.critical,
        tags: ['abraham', 'isaac', 'foi', 'sacrifice'],
      ),
      
      // Joseph
      LiteraryUnit(
        name: 'Histoire de Joseph',
        type: UnitType.narrative,
        startChapter: 37,
        startVerse: 1,
        endChapter: 50,
        endVerse: 26,
        priority: UnitPriority.medium, // Long mais cohérent
        tags: ['joseph', 'égypte', 'providence'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // EXODE
    // ═══════════════════════════════════════════════════════════════
    'Exode': [
      // Les 10 plaies
      LiteraryUnit(
        name: 'Les 10 plaies d\'Égypte',
        type: UnitType.narrative,
        startChapter: 7,
        startVerse: 14,
        endChapter: 11,
        endVerse: 10,
        priority: UnitPriority.high,
        tags: ['plaies', 'égypte', 'jugement'],
      ),
      
      // Pâque et sortie
      LiteraryUnit(
        name: 'La Pâque et la sortie d\'Égypte',
        type: UnitType.narrative,
        startChapter: 12,
        startVerse: 1,
        endChapter: 13,
        endVerse: 22,
        priority: UnitPriority.critical,
        tags: ['pâque', 'agneau', 'libération'],
      ),
      
      // Passage de la Mer Rouge
      LiteraryUnit(
        name: 'Passage de la Mer Rouge',
        type: UnitType.narrative,
        startChapter: 14,
        startVerse: 1,
        endChapter: 14,
        endVerse: 31,
        priority: UnitPriority.critical,
        tags: ['mer', 'rouge', 'miracle', 'délivrance'],
      ),
      
      // Les 10 Commandements
      LiteraryUnit(
        name: 'Les 10 Commandements',
        type: UnitType.law,
        startChapter: 20,
        startVerse: 1,
        endChapter: 20,
        endVerse: 21,
        priority: UnitPriority.critical,
        tags: ['commandements', 'loi', 'sinaï'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // PSAUMES (certains sont des unités à ne pas couper)
    // ═══════════════════════════════════════════════════════════════
    'Psaumes': [
      // Chaque psaume est une unité complète
      // Note : Psaume 119 est très long (176 versets) mais ne devrait pas être coupé
      LiteraryUnit(
        name: 'Psaume 119 (Acrostiche complet)',
        type: UnitType.poetic,
        startChapter: 119,
        startVerse: 1,
        endChapter: 119,
        endVerse: 176,
        priority: UnitPriority.high,
        tags: ['torah', 'acrostiche', 'loi'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════
    // APOCALYPSE
    // ═══════════════════════════════════════════════════════════════
    'Apocalypse': [
      // Lettres aux 7 églises
      LiteraryUnit(
        name: 'Lettres aux 7 églises',
        type: UnitType.epistle,
        startChapter: 2,
        startVerse: 1,
        endChapter: 3,
        endVerse: 22,
        priority: UnitPriority.high,
        tags: ['lettres', 'églises', 'exhortations'],
      ),
      
      // Vision du trône
      LiteraryUnit(
        name: 'Vision du trône céleste',
        type: UnitType.vision,
        startChapter: 4,
        startVerse: 1,
        endChapter: 5,
        endVerse: 14,
        priority: UnitPriority.high,
        tags: ['trône', 'vision', 'adoration'],
      ),
    ],
  };
  
  /// Ajuste un passage pour respecter les frontières sémantiques
  /// 
  /// [book] : Livre biblique
  /// [startChapter] : Chapitre de départ proposé
  /// [endChapter] : Chapitre de fin proposé
  /// 
  /// Retourne : Passage ajusté
  static PassageBoundary adjustPassage({
    required String book,
    required int startChapter,
    required int endChapter,
  }) {
    final units = _literaryUnits[book] ?? [];
    
    // Chercher si le passage proposé coupe une unité littéraire
    for (final unit in units) {
      // Vérifier si on coupe l'unité au milieu
      final cuts = _isUnitCut(
        unit: unit,
        proposedStart: startChapter,
        proposedEnd: endChapter,
      );
      
      if (cuts) {
        print('⚠️ Passage coupe "${unit.name}" au milieu');
        
        // Ajuster selon la priorité
        if (unit.priority == UnitPriority.critical) {
          // Ne JAMAIS couper → Inclure l'unité complète
          return _includeFullUnit(
            unit: unit,
            proposedStart: startChapter,
            proposedEnd: endChapter,
          );
        } else if (unit.priority == UnitPriority.high) {
          // Essayer d'inclure ou d'exclure complètement
          return _tryIncludeOrExclude(
            unit: unit,
            proposedStart: startChapter,
            proposedEnd: endChapter,
          );
        } else {
          // Priorité medium → Ajuster si possible, sinon accepter
          return _adjustIfReasonable(
            unit: unit,
            proposedStart: startChapter,
            proposedEnd: endChapter,
          );
        }
      }
    }
    
    // Pas de coupe détectée → OK tel quel
    return PassageBoundary(
      book: book,
      startChapter: startChapter,
      endChapter: endChapter,
      adjusted: false,
      reason: 'Aucune unité littéraire coupée',
    );
  }
  
  /// Vérifie si une unité est coupée au milieu
  static bool _isUnitCut({
    required LiteraryUnit unit,
    required int proposedStart,
    required int proposedEnd,
  }) {
    // L'unité est coupée si :
    // - Le passage commence dans l'unité mais ne la termine pas
    // - Le passage termine dans l'unité mais ne la commence pas
    
    final startsInside = proposedStart >= unit.startChapter && 
                         proposedStart <= unit.endChapter;
    final endsInside = proposedEnd >= unit.startChapter && 
                       proposedEnd <= unit.endChapter;
    
    // Coupe = commence OU termine dans l'unité, mais pas les deux
    return (startsInside && !endsInside) || (!startsInside && endsInside);
  }
  
  /// Inclut l'unité complète (pour priorité CRITICAL)
  static PassageBoundary _includeFullUnit({
    required LiteraryUnit unit,
    required int proposedStart,
    required int proposedEnd,
  }) {
    // Étendre pour inclure toute l'unité
    final adjustedStart = min(proposedStart, unit.startChapter);
    final adjustedEnd = max(proposedEnd, unit.endChapter);
    
    print('  ✅ Ajusté pour inclure "${unit.name}" complète');
    print('     $proposedStart-$proposedEnd → $adjustedStart-$adjustedEnd');
    
    return PassageBoundary(
      book: unit.book ?? '',
      startChapter: adjustedStart,
      endChapter: adjustedEnd,
      adjusted: true,
      reason: 'Inclusion de "${unit.name}" (${unit.type.name})',
      includedUnit: unit,
    );
  }
  
  /// Essaie d'inclure ou exclure complètement (pour priorité HIGH)
  static PassageBoundary _tryIncludeOrExclude({
    required LiteraryUnit unit,
    required int proposedStart,
    required int proposedEnd,
  }) {
    final unitSize = unit.endChapter - unit.startChapter + 1;
    final proposedSize = proposedEnd - proposedStart + 1;
    
    // Si l'unité est petite par rapport au passage, l'inclure
    if (unitSize <= proposedSize * 0.5) {
      return _includeFullUnit(
        unit: unit,
        proposedStart: proposedStart,
        proposedEnd: proposedEnd,
      );
    }
    
    // Sinon, l'exclure complètement
    if (proposedStart >= unit.startChapter && proposedStart <= unit.endChapter) {
      // Commencer après l'unité
      final adjustedStart = unit.endChapter + 1;
      print('  ✅ Exclu "${unit.name}" - Commence après');
      
      return PassageBoundary(
        book: unit.book ?? '',
        startChapter: adjustedStart,
        endChapter: proposedEnd,
        adjusted: true,
        reason: 'Exclusion de "${unit.name}" pour cohérence',
        excludedUnit: unit,
      );
    } else {
      // Terminer avant l'unité
      final adjustedEnd = unit.startChapter - 1;
      print('  ✅ Exclu "${unit.name}" - Termine avant');
      
      return PassageBoundary(
        book: unit.book ?? '',
        startChapter: proposedStart,
        endChapter: adjustedEnd,
        adjusted: true,
        reason: 'Exclusion de "${unit.name}" pour cohérence',
        excludedUnit: unit,
      );
    }
  }
  
  /// Ajuste si raisonnable (pour priorité MEDIUM)
  static PassageBoundary _adjustIfReasonable({
    required LiteraryUnit unit,
    required int proposedStart,
    required int proposedEnd,
  }) {
    final adjustment = proposedEnd - unit.endChapter;
    
    // Si l'ajustement est raisonnable (< 2 chapitres), inclure
    if (adjustment.abs() <= 2) {
      return _includeFullUnit(
        unit: unit,
        proposedStart: proposedStart,
        proposedEnd: proposedEnd,
      );
    }
    
    // Sinon, accepter la coupe (priorité medium)
    print('  ⚠️ Coupe acceptée pour "${unit.name}" (priorité medium)');
    return PassageBoundary(
      book: unit.book ?? '',
      startChapter: proposedStart,
      endChapter: proposedEnd,
      adjusted: false,
      reason: 'Coupe acceptée (priorité ${unit.priority.name})',
    );
  }
  
  /// Génère des passages optimisés pour un livre complet
  /// 
  /// [book] : Livre biblique
  /// [totalChapters] : Nombre total de chapitres
  /// [targetDays] : Nombre de jours souhaités
  /// 
  /// Retourne : Liste de passages respectant les unités
  static List<DailyPassage> generateOptimizedPassages({
    required String book,
    required int totalChapters,
    required int targetDays,
  }) {
    print('📖 Génération passages optimisés pour $book ($totalChapters ch, $targetDays jours)');
    
    final units = _literaryUnits[book] ?? [];
    final passages = <DailyPassage>[];
    
    int currentChapter = 1;
    int dayNumber = 1;
    
    while (currentChapter <= totalChapters && dayNumber <= targetDays) {
      // Calculer combien de chapitres par jour en moyenne
      final remainingChapters = totalChapters - currentChapter + 1;
      final remainingDays = targetDays - dayNumber + 1;
      final avgChaptersPerDay = (remainingChapters / remainingDays).ceil();
      
      var endChapter = currentChapter + avgChaptersPerDay - 1;
      endChapter = min(endChapter, totalChapters);
      
      // Ajuster pour respecter les unités littéraires
      final adjusted = adjustPassage(
        book: book,
        startChapter: currentChapter,
        endChapter: endChapter,
      );
      
      // Créer le passage du jour
      final reference = adjusted.startChapter == adjusted.endChapter
          ? '$book ${adjusted.startChapter}'
          : '$book ${adjusted.startChapter}–${adjusted.endChapter}';
      
      passages.add(DailyPassage(
        dayNumber: dayNumber,
        reference: reference,
        book: book,
        startChapter: adjusted.startChapter,
        endChapter: adjusted.endChapter,
        wasAdjusted: adjusted.adjusted,
        adjustmentReason: adjusted.reason,
        includedUnit: adjusted.includedUnit,
      ));
      
      currentChapter = adjusted.endChapter + 1;
      dayNumber++;
    }
    
    print('✅ ${passages.length} passages générés (${passages.where((p) => p.wasAdjusted).length} ajustés)');
    
    return passages;
  }
  
  /// Obtient toutes les unités d'un livre
  static List<LiteraryUnit> getUnitsForBook(String book) {
    return _literaryUnits[book] ?? [];
  }
  
  /// Vérifie si un passage contient une unité critique
  static bool containsCriticalUnit({
    required String book,
    required int startChapter,
    required int endChapter,
  }) {
    final units = _literaryUnits[book] ?? [];
    
    for (final unit in units) {
      if (unit.priority != UnitPriority.critical) continue;
      
      // Vérifier si le passage contient cette unité
      final overlaps = !(endChapter < unit.startChapter || 
                        startChapter > unit.endChapter);
      
      if (overlaps) return true;
    }
    
    return false;
  }
}

/// Types d'unités littéraires
enum UnitType {
  narrative,          // Récit (création, déluge, passion)
  parable,            // Parabole unique
  parableCollection,  // Collection de paraboles
  discourse,          // Discours (sermon montagne, adieu)
  theological,        // Enseignement théologique
  poetic,             // Poésie/Hymne
  law,                // Loi/Commandements
  vision,             // Vision prophétique
  epistle,            // Lettre/Épître
}

/// Priorité de l'unité (importance de ne pas couper)
enum UnitPriority {
  critical,  // Ne JAMAIS couper (sermon montagne, passion, etc.)
  high,      // Éviter fortement de couper (paraboles principales)
  medium,    // Préférable de ne pas couper mais acceptable
  low,       // Peut être coupé si nécessaire
}

/// Unité littéraire (parabole, discours, récit, etc.)
class LiteraryUnit {
  final String name;
  final UnitType type;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final UnitPriority priority;
  final List<String> tags;
  final String? book; // Optionnel, déduit du contexte
  
  const LiteraryUnit({
    required this.name,
    required this.type,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.priority,
    required this.tags,
    this.book,
  });
  
  /// Référence complète
  String getReference(String bookName) {
    if (startChapter == endChapter) {
      return '$bookName $startChapter:$startVerse-$endVerse';
    }
    return '$bookName $startChapter:$startVerse–$endChapter:$endVerse';
  }
  
  /// Taille en chapitres
  int get sizeInChapters => endChapter - startChapter + 1;
  
  /// Estimation versets (approximatif)
  int get estimatedVerses {
    if (startChapter == endChapter) {
      return endVerse - startVerse + 1;
    }
    return sizeInChapters * 25; // Moyenne 25 versets/chapitre
  }
}

/// Frontière de passage ajustée
class PassageBoundary {
  final String book;
  final int startChapter;
  final int endChapter;
  final bool adjusted;
  final String reason;
  final LiteraryUnit? includedUnit;
  final LiteraryUnit? excludedUnit;
  
  PassageBoundary({
    required this.book,
    required this.startChapter,
    required this.endChapter,
    required this.adjusted,
    required this.reason,
    this.includedUnit,
    this.excludedUnit,
  });
  
  /// Référence formatée
  String get reference {
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
  final int endChapter;
  final bool wasAdjusted;
  final String? adjustmentReason;
  final LiteraryUnit? includedUnit;
  
  DailyPassage({
    required this.dayNumber,
    required this.reference,
    required this.book,
    required this.startChapter,
    required this.endChapter,
    required this.wasAdjusted,
    this.adjustmentReason,
    this.includedUnit,
  });
  
  /// Annotation pour l'utilisateur
  String? get annotation {
    if (includedUnit != null) {
      return '📖 ${includedUnit!.name}';
    }
    return null;
  }
  
  @override
  String toString() {
    final base = 'Jour $dayNumber: $reference';
    if (annotation != null) {
      return '$base - $annotation';
    }
    return base;
  }
}

