import 'dart:math';

/// Calculateur de densité de lecture par livre biblique
/// 
/// Prend en compte la nature du contenu (narratif vs épîtres) pour ajuster
/// la granularité de lecture (chapitres/versets par jour).
/// 
/// Principes :
/// - Épîtres/Poésie : Dense → Moins de versets/jour (méditation approfondie)
/// - Narratif : Fluide → Plus de chapitres/jour (continuité de l'histoire)
/// - Loi/Généalogie : Complexe → Dosage modéré
class BookDensityCalculator {
  
  /// Base de données de densité par livre biblique
  static const Map<String, BookDensity> _bookDensities = {
    // ANCIEN TESTAMENT - PENTATEUQUE
    'Genèse': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 28, // versets/chapitre
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.light,
      versesPerMinute: 4.0,
      chaptersPerDay: 2, // 2 chapitres = ~56 versets = ~14 min
    ),
    'Exode': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 25,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.medium,
      versesPerMinute: 3.5,
      chaptersPerDay: 2,
    ),
    'Lévitique': BookDensity(
      type: BookType.law,
      averageChapterLength: 17,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 2.0,
      chaptersPerDay: 1, // Dense, lois complexes
    ),
    'Nombres': BookDensity(
      type: BookType.mixed,
      averageChapterLength: 26,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.medium,
      versesPerMinute: 3.0,
      chaptersPerDay: 2,
    ),
    'Deutéronome': BookDensity(
      type: BookType.law,
      averageChapterLength: 29,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 2.5,
      chaptersPerDay: 1,
    ),
    
    // LIVRES HISTORIQUES
    'Josué': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 24,
      readingSpeed: ReadingSpeed.fast,
      meditationDepth: MeditationDepth.light,
      versesPerMinute: 5.0,
      chaptersPerDay: 2,
    ),
    '1 Samuel': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 25,
      readingSpeed: ReadingSpeed.fast,
      meditationDepth: MeditationDepth.light,
      versesPerMinute: 4.5,
      chaptersPerDay: 2,
    ),
    '2 Samuel': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 24,
      readingSpeed: ReadingSpeed.fast,
      meditationDepth: MeditationDepth.light,
      versesPerMinute: 4.5,
      chaptersPerDay: 2,
    ),
    
    // LIVRES POÉTIQUES
    'Psaumes': BookDensity(
      type: BookType.poetry,
      averageChapterLength: 13, // Très variable (1-176)
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.veryDeep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1, // 1 psaume par jour pour méditation profonde
    ),
    'Proverbes': BookDensity(
      type: BookType.wisdom,
      averageChapterLength: 22,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 2.0,
      chaptersPerDay: 1,
    ),
    'Job': BookDensity(
      type: BookType.poetry,
      averageChapterLength: 17,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.veryDeep,
      versesPerMinute: 1.8,
      chaptersPerDay: 1,
    ),
    'Ecclésiaste': BookDensity(
      type: BookType.wisdom,
      averageChapterLength: 11,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 2.0,
      chaptersPerDay: 1,
    ),
    'Cantique des cantiques': BookDensity(
      type: BookType.poetry,
      averageChapterLength: 13,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.veryDeep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1,
    ),
    
    // PROPHÈTES
    'Ésaïe': BookDensity(
      type: BookType.prophecy,
      averageChapterLength: 21,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 2.5,
      chaptersPerDay: 1,
    ),
    'Jérémie': BookDensity(
      type: BookType.prophecy,
      averageChapterLength: 35,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 2.5,
      chaptersPerDay: 1,
    ),
    
    // NOUVEAU TESTAMENT - ÉVANGILES
    'Matthieu': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 30,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.medium,
      versesPerMinute: 3.5,
      chaptersPerDay: 2, // 2 chapitres = ~60 versets = ~17 min
    ),
    'Marc': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 31,
      readingSpeed: ReadingSpeed.fast,
      meditationDepth: MeditationDepth.light,
      versesPerMinute: 4.0,
      chaptersPerDay: 2,
    ),
    'Luc': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 36,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.medium,
      versesPerMinute: 3.5,
      chaptersPerDay: 2,
    ),
    'Jean': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 25,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 2.5,
      chaptersPerDay: 1, // Plus méditatif que les synoptiques
    ),
    'Actes': BookDensity(
      type: BookType.narrative,
      averageChapterLength: 33,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.light,
      versesPerMinute: 4.0,
      chaptersPerDay: 2,
    ),
    
    // ÉPÎTRES PAULINIENNES (DENSE!)
    'Romains': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 24,
      readingSpeed: ReadingSpeed.verySlow,
      meditationDepth: MeditationDepth.veryDeep,
      versesPerMinute: 1.2, // Très théologique
      chaptersPerDay: 1, // 1 chapitre = ~24 versets = ~20 min
    ),
    '1 Corinthiens': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 27,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1,
    ),
    '2 Corinthiens': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 17,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1,
    ),
    'Galates': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 24,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1,
    ),
    'Éphésiens': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 21,
      readingSpeed: ReadingSpeed.verySlow,
      meditationDepth: MeditationDepth.veryDeep,
      versesPerMinute: 1.2,
      chaptersPerDay: 1,
    ),
    'Philippiens': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 18,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1,
    ),
    'Colossiens': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 18,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1,
    ),
    'Hébreux': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 19,
      readingSpeed: ReadingSpeed.verySlow,
      meditationDepth: MeditationDepth.veryDeep,
      versesPerMinute: 1.0, // Le plus dense du NT
      chaptersPerDay: 1,
    ),
    
    // ÉPÎTRES COURTES
    '1 Thessaloniciens': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 14,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.medium,
      versesPerMinute: 2.0,
      chaptersPerDay: 1,
    ),
    '1 Timothée': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 13,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.medium,
      versesPerMinute: 2.0,
      chaptersPerDay: 1,
    ),
    'Jacques': BookDensity(
      type: BookType.wisdom,
      averageChapterLength: 18,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 1.8,
      chaptersPerDay: 1,
    ),
    '1 Pierre': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 16,
      readingSpeed: ReadingSpeed.moderate,
      meditationDepth: MeditationDepth.medium,
      versesPerMinute: 2.0,
      chaptersPerDay: 1,
    ),
    '1 Jean': BookDensity(
      type: BookType.epistle,
      averageChapterLength: 19,
      readingSpeed: ReadingSpeed.slow,
      meditationDepth: MeditationDepth.deep,
      versesPerMinute: 1.5,
      chaptersPerDay: 1,
    ),
  };
  
  /// Calcule la charge de lecture quotidienne pour un livre
  /// 
  /// [book] : Nom du livre biblique
  /// [dailyMinutes] : Minutes disponibles par jour
  /// 
  /// Retourne : Nombre de chapitres ou versets à lire par jour
  static ReadingLoad calculateDailyLoad({
    required String book,
    required int dailyMinutes,
  }) {
    final density = _bookDensities[book] ?? _defaultDensity;
    
    // Calculer le nombre de versets lisibles dans le temps disponible
    final versesPerDay = (dailyMinutes * density.versesPerMinute).round();
    
    // Convertir en chapitres selon la longueur moyenne
    final chaptersPerDay = (versesPerDay / density.averageChapterLength).round()
        .clamp(1, 5); // Min 1, Max 5 chapitres/jour
    
    // Adapter selon le type de livre
    final adjustedChapters = _adjustByType(
      baseChapters: chaptersPerDay,
      type: density.type,
      dailyMinutes: dailyMinutes,
    );
    
    return ReadingLoad(
      book: book,
      chaptersPerDay: adjustedChapters,
      versesPerDay: versesPerDay,
      estimatedMinutes: dailyMinutes,
      bookType: density.type,
      meditationDepth: density.meditationDepth,
    );
  }
  
  /// Ajuste le nombre de chapitres selon le type de livre
  static int _adjustByType({
    required int baseChapters,
    required BookType type,
    required int dailyMinutes,
  }) {
    switch (type) {
      case BookType.narrative:
        // Narratif : Favoriser la continuité (2-3 chapitres)
        return baseChapters.clamp(2, 3);
        
      case BookType.epistle:
        // Épîtres : Dense, 1 chapitre suffit pour méditation
        return 1;
        
      case BookType.poetry:
        // Poésie : 1 psaume par jour (méditation profonde)
        return 1;
        
      case BookType.wisdom:
        // Sagesse : 1 chapitre (dense, méditatif)
        return 1;
        
      case BookType.prophecy:
        // Prophétie : 1 chapitre (complexe)
        return 1;
        
      case BookType.law:
        // Loi : 1 chapitre (très dense)
        return 1;
        
      case BookType.mixed:
        // Mixte : Utiliser base
        return baseChapters.clamp(1, 2);
    }
  }
  
  /// Calcule la distribution optimale pour un plan multi-livres
  /// 
  /// [books] : Liste des livres à inclure
  /// [totalDays] : Durée totale du plan
  /// [dailyMinutes] : Minutes disponibles par jour
  /// 
  /// Retourne : Distribution des jours par livre
  static Map<String, int> distributeBooksOverDays({
    required List<String> books,
    required int totalDays,
    required int dailyMinutes,
  }) {
    final distribution = <String, int>{};
    int remainingDays = totalDays;
    
    // 1. Calculer le nombre de chapitres total par livre
    final bookChapters = <String, int>{};
    int totalChapters = 0;
    
    for (final book in books) {
      final chapters = _getBookChapterCount(book);
      bookChapters[book] = chapters;
      totalChapters += chapters;
    }
    
    // 2. Distribuer les jours proportionnellement avec densité
    for (final book in books) {
      final density = _bookDensities[book] ?? _defaultDensity;
      final chapters = bookChapters[book]!;
      
      // Nombre de jours basé sur la densité
      final daysNeeded = (chapters / density.chaptersPerDay).ceil();
      
      // Proportionner selon le total de jours disponibles
      final proportionalDays = ((daysNeeded / totalChapters) * totalDays).round();
      
      distribution[book] = proportionalDays.clamp(1, remainingDays);
      remainingDays -= distribution[book]!;
    }
    
    // 3. Redistribuer les jours restants (au cas où)
    if (remainingDays > 0) {
      distribution[books.first] = distribution[books.first]! + remainingDays;
    }
    
    return distribution;
  }
  
  /// Génère un plan détaillé jour par jour avec granularité adaptée
  /// 
  /// [book] : Livre biblique
  /// [totalDays] : Nombre de jours alloués à ce livre
  /// [dailyMinutes] : Minutes disponibles par jour
  /// 
  /// Retourne : Liste de références quotidiennes
  static List<DailyReading> generateDailyReadings({
    required String book,
    required int totalDays,
    required int dailyMinutes,
  }) {
    final density = _bookDensities[book] ?? _defaultDensity;
    final totalChapters = _getBookChapterCount(book);
    final readings = <DailyReading>[];
    
    // Calculer la granularité
    final chaptersPerDay = (totalChapters / totalDays).ceil()
        .clamp(1, density.chaptersPerDay);
    
    int currentChapter = 1;
    
    for (int day = 0; day < totalDays; day++) {
      final endChapter = min(currentChapter + chaptersPerDay - 1, totalChapters);
      
      final reference = currentChapter == endChapter
          ? '$book $currentChapter'
          : '$book $currentChapter–$endChapter';
      
      final estimatedVerses = density.averageChapterLength * (endChapter - currentChapter + 1);
      final estimatedMinutes = (estimatedVerses / density.versesPerMinute).round();
      
      readings.add(DailyReading(
        dayNumber: day + 1,
        book: book,
        reference: reference,
        chapterStart: currentChapter,
        chapterEnd: endChapter,
        estimatedVerses: estimatedVerses,
        estimatedMinutes: estimatedMinutes,
        density: density,
      ));
      
      currentChapter = endChapter + 1;
      
      if (currentChapter > totalChapters) break;
    }
    
    return readings;
  }
  
  /// Obtient le nombre de chapitres d'un livre
  static int _getBookChapterCount(String book) {
    const chapterCounts = {
      // Ancien Testament
      'Genèse': 50, 'Exode': 40, 'Lévitique': 27, 'Nombres': 36, 'Deutéronome': 34,
      'Josué': 24, '1 Samuel': 31, '2 Samuel': 24,
      'Psaumes': 150, 'Proverbes': 31, 'Job': 42, 'Ecclésiaste': 12, 'Cantique des cantiques': 8,
      'Ésaïe': 66, 'Jérémie': 52,
      
      // Nouveau Testament
      'Matthieu': 28, 'Marc': 16, 'Luc': 24, 'Jean': 21, 'Actes': 28,
      'Romains': 16, '1 Corinthiens': 16, '2 Corinthiens': 13,
      'Galates': 6, 'Éphésiens': 6, 'Philippiens': 4, 'Colossiens': 4,
      '1 Thessaloniciens': 5, '2 Thessaloniciens': 3,
      '1 Timothée': 6, '2 Timothée': 4, 'Tite': 3, 'Philémon': 1,
      'Hébreux': 13, 'Jacques': 5, '1 Pierre': 5, '2 Pierre': 3,
      '1 Jean': 5, '2 Jean': 1, '3 Jean': 1, 'Jude': 1, 'Apocalypse': 22,
    };
    
    return chapterCounts[book] ?? 20; // Fallback
  }
  
  /// Densité par défaut si livre non trouvé
  static const _defaultDensity = BookDensity(
    type: BookType.mixed,
    averageChapterLength: 20,
    readingSpeed: ReadingSpeed.moderate,
    meditationDepth: MeditationDepth.medium,
    versesPerMinute: 3.0,
    chaptersPerDay: 1,
  );
}

/// Types de livres bibliques
enum BookType {
  narrative,   // Histoires (Genèse, Évangiles, Actes)
  epistle,     // Épîtres (Romains, Corinthiens, etc.)
  poetry,      // Poésie (Psaumes, Cantique)
  wisdom,      // Sagesse (Proverbes, Ecclésiaste)
  prophecy,    // Prophétie (Ésaïe, Jérémie, etc.)
  law,         // Loi (Lévitique, Deutéronome)
  mixed,       // Mixte (Exode, Nombres)
}

/// Vitesse de lecture
enum ReadingSpeed {
  verySlow,    // 1-1.5 versets/min (Romains, Hébreux, Psaumes)
  slow,        // 1.5-2.5 versets/min (Épîtres, Prophétie)
  moderate,    // 2.5-3.5 versets/min (Évangiles)
  fast,        // 3.5-4.5 versets/min (Historiques)
}

/// Profondeur de méditation
enum MeditationDepth {
  light,       // Lecture fluide (Historiques)
  medium,      // Réflexion modérée (Évangiles)
  deep,        // Méditation profonde (Épîtres)
  veryDeep,    // Méditation très profonde (Psaumes, Romains)
}

/// Densité d'un livre biblique
class BookDensity {
  final BookType type;
  final int averageChapterLength; // Versets par chapitre
  final ReadingSpeed readingSpeed;
  final MeditationDepth meditationDepth;
  final double versesPerMinute; // Vitesse de lecture méditative
  final int chaptersPerDay; // Recommandation par défaut
  
  const BookDensity({
    required this.type,
    required this.averageChapterLength,
    required this.readingSpeed,
    required this.meditationDepth,
    required this.versesPerMinute,
    required this.chaptersPerDay,
  });
}

/// Charge de lecture quotidienne
class ReadingLoad {
  final String book;
  final int chaptersPerDay;
  final int versesPerDay;
  final int estimatedMinutes;
  final BookType bookType;
  final MeditationDepth meditationDepth;
  
  ReadingLoad({
    required this.book,
    required this.chaptersPerDay,
    required this.versesPerDay,
    required this.estimatedMinutes,
    required this.bookType,
    required this.meditationDepth,
  });
  
  @override
  String toString() {
    return '$book: $chaptersPerDay ch/jour (~$versesPerDay versets, ~${estimatedMinutes}min)';
  }
}

/// Lecture quotidienne détaillée
class DailyReading {
  final int dayNumber;
  final String book;
  final String reference; // "Jean 3" ou "Jean 3–5"
  final int chapterStart;
  final int chapterEnd;
  final int estimatedVerses;
  final int estimatedMinutes;
  final BookDensity density;
  
  DailyReading({
    required this.dayNumber,
    required this.book,
    required this.reference,
    required this.chapterStart,
    required this.chapterEnd,
    required this.estimatedVerses,
    required this.estimatedMinutes,
    required this.density,
  });
  
  /// Retourne le type de méditation recommandé
  String get recommendedMeditationType {
    switch (density.meditationDepth) {
      case MeditationDepth.veryDeep:
        return 'Lectio Divina'; // Méditation très profonde
      case MeditationDepth.deep:
        return 'Méditation biblique'; // Méditation profonde
      case MeditationDepth.medium:
        return 'Réflexion guidée'; // Réflexion modérée
      case MeditationDepth.light:
        return 'Lecture continue'; // Lecture fluide
    }
  }
  
  @override
  String toString() {
    return 'Jour $dayNumber: $reference (~$estimatedMinutes min, $recommendedMeditationType)';
  }
}


