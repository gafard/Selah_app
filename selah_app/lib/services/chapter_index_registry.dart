/// ═══════════════════════════════════════════════════════════════════════════
/// REGISTRE COMPLET - 66 Livres de la Bible
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Mapping canonique : Nom français → Abbr → Slug fichier → Ordre
/// Utilisé par ChapterIndexLoader pour charger les métadonnées offline
/// ═══════════════════════════════════════════════════════════════════════════

class BibleBook {
  final String name; // "Genèse"
  final String abbr; // "Gn"
  final String slug; // "genese" → assets/json/chapters/genese.json
  final int order; // 1..66

  const BibleBook(this.name, this.abbr, this.slug, this.order);

  @override
  String toString() => '$name ($abbr) [$slug]';
}

class ChapterIndexRegistry {
  /// Liste canonique des 66 livres (39 AT + 27 NT)
  static const List<BibleBook> books = [
    // ═══════════════════════════════════════════════════════════════════════
    // ANCIEN TESTAMENT (39 livres)
    // ═══════════════════════════════════════════════════════════════════════
    
    // Pentateuque (5)
    BibleBook('Genèse', 'Gn', 'genese', 1),
    BibleBook('Exode', 'Ex', 'exode', 2),
    BibleBook('Lévitique', 'Lv', 'levitique', 3),
    BibleBook('Nombres', 'Nb', 'nombres', 4),
    BibleBook('Deutéronome', 'Dt', 'deuteronome', 5),
    
    // Livres historiques (12)
    BibleBook('Josué', 'Jos', 'josue', 6),
    BibleBook('Juges', 'Jg', 'juges', 7),
    BibleBook('Ruth', 'Rt', 'ruth', 8),
    BibleBook('1 Samuel', '1S', '1_samuel', 9),
    BibleBook('2 Samuel', '2S', '2_samuel', 10),
    BibleBook('1 Rois', '1R', '1_rois', 11),
    BibleBook('2 Rois', '2R', '2_rois', 12),
    BibleBook('1 Chroniques', '1Ch', '1_chroniques', 13),
    BibleBook('2 Chroniques', '2Ch', '2_chroniques', 14),
    BibleBook('Esdras', 'Esd', 'esdras', 15),
    BibleBook('Néhémie', 'Ne', 'nehemie', 16),
    BibleBook('Esther', 'Est', 'esther', 17),
    
    // Poétiques et Sagesse (5)
    BibleBook('Job', 'Job', 'job', 18),
    BibleBook('Psaumes', 'Ps', 'psaumes', 19),
    BibleBook('Proverbes', 'Pr', 'proverbes', 20),
    BibleBook('Ecclésiaste', 'Ec', 'ecclesiaste', 21),
    BibleBook('Cantique des cantiques', 'Ct', 'cantique', 22),
    
    // Grands prophètes (5)
    BibleBook('Ésaïe', 'Es', 'esaie', 23),
    BibleBook('Jérémie', 'Jr', 'jeremie', 24),
    BibleBook('Lamentations', 'Lm', 'lamentations', 25),
    BibleBook('Ézéchiel', 'Ez', 'ezechiel', 26),
    BibleBook('Daniel', 'Dn', 'daniel', 27),
    
    // Petits prophètes (12)
    BibleBook('Osée', 'Os', 'osee', 28),
    BibleBook('Joël', 'Jl', 'joel', 29),
    BibleBook('Amos', 'Am', 'amos', 30),
    BibleBook('Abdias', 'Ab', 'abdias', 31),
    BibleBook('Jonas', 'Jon', 'jonas', 32),
    BibleBook('Michée', 'Mi', 'michee', 33),
    BibleBook('Nahum', 'Na', 'nahum', 34),
    BibleBook('Habacuc', 'Ha', 'habacuc', 35),
    BibleBook('Sophonie', 'So', 'sophonie', 36),
    BibleBook('Aggée', 'Ag', 'aggee', 37),
    BibleBook('Zacharie', 'Za', 'zacharie', 38),
    BibleBook('Malachie', 'Ml', 'malachie', 39),
    
    // ═══════════════════════════════════════════════════════════════════════
    // NOUVEAU TESTAMENT (27 livres)
    // ═══════════════════════════════════════════════════════════════════════
    
    // Évangiles (4)
    BibleBook('Matthieu', 'Mt', 'matthieu', 40),
    BibleBook('Marc', 'Mc', 'marc', 41),
    BibleBook('Luc', 'Lc', 'luc', 42),
    BibleBook('Jean', 'Jn', 'jean', 43),
    
    // Histoire (1)
    BibleBook('Actes', 'Ac', 'actes', 44),
    
    // Épîtres de Paul (13)
    BibleBook('Romains', 'Rm', 'romains', 45),
    BibleBook('1 Corinthiens', '1Co', '1_corinthiens', 46),
    BibleBook('2 Corinthiens', '2Co', '2_corinthiens', 47),
    BibleBook('Galates', 'Ga', 'galates', 48),
    BibleBook('Éphésiens', 'Ep', 'ephesiens', 49),
    BibleBook('Philippiens', 'Ph', 'philippiens', 50),
    BibleBook('Colossiens', 'Col', 'colossiens', 51),
    BibleBook('1 Thessaloniciens', '1Th', '1_thessaloniciens', 52),
    BibleBook('2 Thessaloniciens', '2Th', '2_thessaloniciens', 53),
    BibleBook('1 Timothée', '1Tm', '1_timothee', 54),
    BibleBook('2 Timothée', '2Tm', '2_timothee', 55),
    BibleBook('Tite', 'Tt', 'tite', 56),
    BibleBook('Philémon', 'Phm', 'philemon', 57),
    
    // Épîtres générales (8)
    BibleBook('Hébreux', 'He', 'hebreux', 58),
    BibleBook('Jacques', 'Jc', 'jacques', 59),
    BibleBook('1 Pierre', '1P', '1_pierre', 60),
    BibleBook('2 Pierre', '2P', '2_pierre', 61),
    BibleBook('1 Jean', '1Jn', '1_jean', 62),
    BibleBook('2 Jean', '2Jn', '2_jean', 63),
    BibleBook('3 Jean', '3Jn', '3_jean', 64),
    BibleBook('Jude', 'Jud', 'jude', 65),
    
    // Apocalypse (1)
    BibleBook('Apocalypse', 'Ap', 'apocalypse', 66),
  ];

  /// Recherche par nom exact
  static BibleBook? byName(String name) {
    try {
      return books.firstWhere(
        (b) => b.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Recherche par slug (nom de fichier)
  static BibleBook? bySlug(String slug) {
    try {
      return books.firstWhere(
        (b) => b.slug.toLowerCase() == slug.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Recherche par abréviation
  static BibleBook? byAbbr(String abbr) {
    try {
      return books.firstWhere(
        (b) => b.abbr.toLowerCase() == abbr.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Recherche par ordre canonique
  static BibleBook? byOrder(int order) {
    try {
      return books.firstWhere((b) => b.order == order);
    } catch (_) {
      return null;
    }
  }

  /// Liste tous les slugs (pour itération)
  static List<String> get allSlugs => books.map((b) => b.slug).toList();

  /// Liste tous les noms
  static List<String> get allNames => books.map((b) => b.name).toList();

  /// Stats
  static int get totalBooks => books.length;
  static int get oldTestamentCount => 39;
  static int get newTestamentCount => 27;
}


