/// 🚀 APÔTRE - Service ultra-intelligent de frontières sémantiques bibliques
/// 
/// Niveau : Apôtre (Ultra-Intelligent) - Service de référence pour l'intelligence sémantique
/// 
/// Base de données exhaustive des unités littéraires naturelles de la Bible
/// pour une lecture plus fluide et cohérente.
/// 
/// Basé sur :
/// - Structures littéraires bibliques (chiasmes, parallélismes, inclusions)
/// - Divisions canoniques traditionnelles
/// - Recherche exégétique moderne
/// - Contexte liturgique et liturgie des heures
library;

/// Résultat d'un ajustement sémantique simple (par chapitres)
class AdjustedPassage {
  final String book;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final bool adjusted;
  final String reference;
  final SemanticUnit? includedUnit;

  const AdjustedPassage({
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.adjusted,
    required this.reference,
    this.includedUnit,
  });
}

/// Priorité d'une unité sémantique
enum UnitPriority {
  critical,  // Ne JAMAIS diviser (ex: Sermon sur la montagne)
  high,      // Fortement recommandé de garder ensemble
  medium,    // Utile mais peut être divisé si nécessaire
  low,       // Suggestion faible
}

/// Unité sémantique biblique
class SemanticUnit {
  final String book;
  final int startChapter;
  final int endChapter;
  final String name;
  final UnitPriority priority;
  final String? theme;
  final String? liturgicalContext;
  final List<String>? emotionalTones;
  final String? annotation;
  
  const SemanticUnit({
    required this.book,
    required this.startChapter,
    required this.endChapter,
    required this.name,
    required this.priority,
    this.theme,
    this.liturgicalContext,
    this.emotionalTones,
    this.annotation,
  }) : assert(startChapter <= endChapter, 'startChapter ($startChapter) must be <= endChapter ($endChapter)');
  
  /// Nombre de chapitres dans cette unité
  int get length => endChapter - startChapter + 1;
  
  /// Référence formatée
  String get reference {
    if (startChapter == endChapter) {
      return '$book $startChapter';
    }
    return '$book $startChapter–$endChapter';
  }
}

/// Index chapitres → unité pour lookup O(1)
class _UnitsIndex {
  final Map<String, Map<int, SemanticUnit>> _byBook = {};
  
  Map<int, SemanticUnit> forBook(String book) {
    final key = _normalizeBookName(book);
    if (!_byBook.containsKey(key)) {
      final map = <int, SemanticUnit>{};
      for (final u in SemanticPassageBoundaryService.getUnitsForBook(book)) {
        for (var c = u.startChapter; c <= u.endChapter; c++) {
          map[c] = u;
        }
      }
      _byBook[key] = map;
    }
    return _byBook[key]!;
  }
  
  /// Normalise les noms de livres pour éviter les variations
  String _normalizeBookName(String book) {
    return book.trim().toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c');
  }
}

/// 🚀 Service de frontières sémantiques - BASE DE DONNÉES EXHAUSTIVE
class SemanticPassageBoundaryService {
  
  // ═══════════════════════════════════════════════════════════════════
  // 🚀 INDEX DE PERFORMANCE - LOOKUP O(1)
  // ═══════════════════════════════════════════════════════════════════
  
  static final _UnitsIndex _unitsIndex = _UnitsIndex();
  
  // ═══════════════════════════════════════════════════════════════════
  // 📖 NOUVEAU TESTAMENT - ÉVANGILES
  // ═══════════════════════════════════════════════════════════════════
  
  static const _matthieuUnits = [
    // Prologue et naissance
    SemanticUnit(
      book: 'Matthieu', startChapter: 1, endChapter: 2,
      name: 'Naissance du Roi',
      priority: UnitPriority.critical,
      theme: 'Incarnation',
      annotation: '👑 Naissance du Roi promis',
      emotionalTones: ['wonder', 'anticipation', 'fulfillment'],
    ),
    
    // Ministère inaugural
    SemanticUnit(
      book: 'Matthieu', startChapter: 3, endChapter: 4,
      name: 'Début du ministère',
      priority: UnitPriority.high,
      theme: 'Mission',
      annotation: '🔥 Baptême et tentation',
      emotionalTones: ['preparation', 'victory'],
    ),
    
    // SERMON SUR LA MONTAGNE - critique !
    SemanticUnit(
      book: 'Matthieu', startChapter: 5, endChapter: 7,
        name: 'Sermon sur la montagne',
      priority: UnitPriority.critical,
      theme: 'Éthique du Royaume',
      liturgicalContext: 'Toussaint',
      annotation: '⛰️ Les Béatitudes et l\'éthique du Royaume',
      emotionalTones: ['transformation', 'radical_love', 'kingdom_values'],
    ),
    
    // Miracles et autorité
    SemanticUnit(
      book: 'Matthieu', startChapter: 8, endChapter: 9,
      name: 'Dix miracles',
        priority: UnitPriority.high,
      theme: 'Autorité divine',
      annotation: '✨ La puissance du Roi',
      emotionalTones: ['awe', 'faith', 'healing'],
    ),
    
    // Discours missionnaire
    SemanticUnit(
      book: 'Matthieu', startChapter: 10, endChapter: 10,
      name: 'Envoi des Douze',
      priority: UnitPriority.high,
      theme: 'Mission',
      annotation: '🚀 Commission missionnaire',
      emotionalTones: ['courage', 'mission', 'sacrifice'],
    ),
    
    // Opposition croissante
    SemanticUnit(
      book: 'Matthieu', startChapter: 11, endChapter: 12,
      name: 'Questions et opposition',
        priority: UnitPriority.medium,
      theme: 'Conflit',
      annotation: '⚔️ Jésus face aux critiques',
      emotionalTones: ['tension', 'discernment'],
    ),
    
    // Paraboles du Royaume
    SemanticUnit(
      book: 'Matthieu', startChapter: 13, endChapter: 13,
      name: 'Paraboles du Royaume',
        priority: UnitPriority.critical,
      theme: 'Royaume de Dieu',
      annotation: '🌾 Sept paraboles du Royaume',
      emotionalTones: ['mystery', 'revelation', 'growth'],
    ),
    
    // Ministère en Galilée (suite)
    SemanticUnit(
      book: 'Matthieu', startChapter: 14, endChapter: 17,
      name: 'Miracles et révélation',
      priority: UnitPriority.medium,
      theme: 'Identité du Messie',
      annotation: '⭐ Qui est Jésus ? Transfiguration',
      emotionalTones: ['revelation', 'glory', 'faith'],
    ),
    
    // Vie de la communauté
    SemanticUnit(
      book: 'Matthieu', startChapter: 18, endChapter: 18,
      name: 'Discours ecclésial',
      priority: UnitPriority.high,
      theme: 'Église',
      annotation: '⛪ Vie dans la communauté',
      emotionalTones: ['humility', 'forgiveness', 'accountability'],
    ),
    
    // Route vers Jérusalem
    SemanticUnit(
      book: 'Matthieu', startChapter: 19, endChapter: 23,
      name: 'Montée à Jérusalem',
      priority: UnitPriority.medium,
      theme: 'Confrontation',
      annotation: '🚶 Vers la croix',
      emotionalTones: ['tension', 'urgency', 'warning'],
    ),
    
    // Discours eschatologique
    SemanticUnit(
      book: 'Matthieu', startChapter: 24, endChapter: 25,
      name: 'Discours sur la fin des temps',
        priority: UnitPriority.critical,
      theme: 'Eschatologie',
      annotation: '⏰ Veiller et être prêt',
      emotionalTones: ['vigilance', 'hope', 'readiness'],
    ),
    
    // Passion et Résurrection - TOUJOURS ensemble
    SemanticUnit(
      book: 'Matthieu', startChapter: 26, endChapter: 28,
      name: 'Passion et Résurrection',
      priority: UnitPriority.critical,
      theme: 'Rédemption',
      liturgicalContext: 'Semaine Sainte + Pâques',
      annotation: '✝️ Mort et résurrection du Roi',
      emotionalTones: ['sorrow', 'sacrifice', 'victory', 'joy'],
    ),
  ];
  
  static const _marcUnits = [
    // Début du ministère (Marc commence direct)
    SemanticUnit(
      book: 'Marc', startChapter: 1, endChapter: 1,
      name: 'Commencement de l\'Évangile',
      priority: UnitPriority.high,
      theme: 'Inauguration',
      annotation: '⚡ Jésus surgit avec puissance',
      emotionalTones: ['urgency', 'power', 'immediacy'],
    ),
    
    // Ministère en Galilée - miracles rapides
    SemanticUnit(
      book: 'Marc', startChapter: 2, endChapter: 5,
      name: 'Miracles en Galilée',
        priority: UnitPriority.medium,
      theme: 'Autorité',
      annotation: '✨ Le Serviteur en action',
      emotionalTones: ['power', 'compassion', 'faith'],
    ),
    
    // Mission des Douze
    SemanticUnit(
      book: 'Marc', startChapter: 6, endChapter: 8,
      name: 'Formation des disciples',
        priority: UnitPriority.medium,
      theme: 'Discipulat',
      annotation: '🎓 École de la foi',
      emotionalTones: ['learning', 'growth', 'perseverance'],
    ),
    
    // Révélation de la croix
    SemanticUnit(
      book: 'Marc', startChapter: 8, endChapter: 10,
      name: 'Le chemin de la croix',
        priority: UnitPriority.high,
      theme: 'Sacrifice',
      annotation: '✝️ Trois annonces de la Passion',
      emotionalTones: ['sacrifice', 'cost', 'following'],
    ),
    
    // Ministère à Jérusalem
    SemanticUnit(
      book: 'Marc', startChapter: 11, endChapter: 13,
      name: 'Entrée et controverses',
      priority: UnitPriority.medium,
      theme: 'Confrontation',
      annotation: '🌴 Rameaux et enseignements finaux',
      emotionalTones: ['conflict', 'teaching', 'warning'],
    ),
    
    // Passion et Résurrection
    SemanticUnit(
      book: 'Marc', startChapter: 14, endChapter: 16,
      name: 'Passion et Résurrection',
        priority: UnitPriority.critical,
      theme: 'Rédemption',
      liturgicalContext: 'Semaine Sainte + Pâques',
      annotation: '✝️ Le Serviteur souffrant triomphe',
      emotionalTones: ['suffering', 'abandonment', 'victory', 'mission'],
    ),
  ];
  
  static const _lucUnits = [
    // Préface et enfances
    SemanticUnit(
      book: 'Luc', startChapter: 1, endChapter: 2,
      name: 'Enfances de Jean et Jésus',
        priority: UnitPriority.critical,
      theme: 'Incarnation',
      liturgicalContext: 'Avent + Noël',
      annotation: '🎄 Magnificat et nativité',
      emotionalTones: ['joy', 'praise', 'wonder'],
    ),
    
    // Début du ministère
    SemanticUnit(
      book: 'Luc', startChapter: 3, endChapter: 4,
      name: 'Inauguration du ministère',
        priority: UnitPriority.high,
      theme: 'Mission',
      annotation: '🔥 Baptême et mission à Nazareth',
      emotionalTones: ['anointing', 'liberation', 'proclamation'],
    ),
    
    // Sermon dans la plaine
    SemanticUnit(
      book: 'Luc', startChapter: 6, endChapter: 6,
      name: 'Sermon dans la plaine',
        priority: UnitPriority.critical,
      theme: 'Compassion',
      annotation: '🏔️ Béatitudes et éthique de l\'amour',
      emotionalTones: ['compassion', 'justice', 'mercy'],
    ),
    
    // Miracles et paraboles
    SemanticUnit(
      book: 'Luc', startChapter: 7, endChapter: 9,
      name: 'Compassion et révélation',
      priority: UnitPriority.medium,
      theme: 'Miséricorde',
      annotation: '❤️ Le cœur de Jésus pour les perdus',
      emotionalTones: ['compassion', 'inclusion', 'healing'],
    ),
    
    // Montée vers Jérusalem (grande section propre à Luc)
    SemanticUnit(
      book: 'Luc', startChapter: 9, endChapter: 19,
      name: 'Voyage vers Jérusalem',
      priority: UnitPriority.high,
      theme: 'Discipulat',
      annotation: '🚶 Enseignements sur le chemin (paraboles uniques)',
      emotionalTones: ['teaching', 'perseverance', 'joy'],
    ),
    
    // Ministère à Jérusalem
    SemanticUnit(
      book: 'Luc', startChapter: 19, endChapter: 21,
      name: 'Entrée et enseignements',
      priority: UnitPriority.medium,
      theme: 'Autorité',
      annotation: '🏛️ Dans le temple',
      emotionalTones: ['authority', 'warning'],
    ),
    
    // Passion et Résurrection
    SemanticUnit(
      book: 'Luc', startChapter: 22, endChapter: 24,
      name: 'Passion et Résurrection',
        priority: UnitPriority.critical,
      theme: 'Rédemption',
      liturgicalContext: 'Semaine Sainte + Pâques',
      annotation: '✝️ Le Sauveur du monde triomphe',
      emotionalTones: ['forgiveness', 'sacrifice', 'restoration', 'joy'],
    ),
  ];
  
  static const _jeanUnits = [
    // Prologue - JAMAIS diviser
    SemanticUnit(
      book: 'Jean', startChapter: 1, endChapter: 1,
      name: 'Prologue - Le Verbe',
      priority: UnitPriority.critical,
      theme: 'Incarnation',
      liturgicalContext: 'Noël',
      annotation: '✨ Au commencement était la Parole',
      emotionalTones: ['wonder', 'glory', 'light'],
    ),
    
    // Signes et dialogues (Livre des Signes - 7 signes)
    SemanticUnit(
      book: 'Jean', startChapter: 2, endChapter: 4,
      name: 'Premiers signes',
        priority: UnitPriority.high,
      theme: 'Révélation',
      annotation: '🍷 Cana, temple, Nicodème, Samaritaine',
      emotionalTones: ['transformation', 'new_life', 'living_water'],
    ),
    
    SemanticUnit(
      book: 'Jean', startChapter: 5, endChapter: 5,
      name: 'Le Fils égal au Père',
        priority: UnitPriority.high,
      theme: 'Christologie',
      annotation: '⚖️ Autorité divine',
      emotionalTones: ['authority', 'identity'],
    ),
    
    // Pain de vie - CRITIQUE
    SemanticUnit(
      book: 'Jean', startChapter: 6, endChapter: 6,
      name: 'Pain de vie',
        priority: UnitPriority.critical,
      theme: 'Eucharistie',
      liturgicalContext: 'Corpus Christi',
      annotation: '🍞 Je suis le pain de vie',
      emotionalTones: ['sustenance', 'life', 'communion'],
    ),
    
    // Fête des Tabernacles
    SemanticUnit(
      book: 'Jean', startChapter: 7, endChapter: 8,
      name: 'Lumière du monde',
      priority: UnitPriority.high,
      theme: 'Révélation',
      annotation: '💡 Je suis la lumière du monde',
      emotionalTones: ['light', 'truth', 'freedom'],
    ),
    
    // Bon berger
    SemanticUnit(
      book: 'Jean', startChapter: 10, endChapter: 10,
      name: 'Le bon berger',
        priority: UnitPriority.critical,
      theme: 'Protection',
      liturgicalContext: 'Dimanche du Bon Pasteur',
      annotation: '🐑 Je suis le bon berger',
      emotionalTones: ['security', 'care', 'belonging'],
    ),
    
    // Lazare - signe suprême
    SemanticUnit(
      book: 'Jean', startChapter: 11, endChapter: 12,
      name: 'Résurrection et royauté',
        priority: UnitPriority.high,
      theme: 'Vie',
      annotation: '🌅 Je suis la résurrection et la vie',
      emotionalTones: ['life', 'victory', 'worship'],
    ),
    
    // Discours d'adieu - CRITIQUE (testament spirituel)
    SemanticUnit(
      book: 'Jean', startChapter: 13, endChapter: 17,
      name: 'Discours d\'adieu',
        priority: UnitPriority.critical,
      theme: 'Intimité',
      annotation: '💬 Testament de Jésus (Lavement, Cep, Prière sacerdotale)',
      emotionalTones: ['intimacy', 'love', 'unity', 'prayer'],
    ),
    
    // Passion et Résurrection
    SemanticUnit(
      book: 'Jean', startChapter: 18, endChapter: 21,
      name: 'Passion, Résurrection et envoi',
        priority: UnitPriority.critical,
      theme: 'Gloire',
      liturgicalContext: 'Semaine Sainte + Pâques',
      annotation: '✝️ L\'heure de la gloire - Je suis ressuscité',
      emotionalTones: ['glory', 'victory', 'mission', 'restoration'],
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════════
  // 📖 PSAUMES - Structure liturgique et thématique
  // ═══════════════════════════════════════════════════════════════════
  
  static const _psaumesUnits = [
    // Introduction - Les deux voies
    SemanticUnit(
      book: 'Psaumes', startChapter: 1, endChapter: 2,
      name: 'Introduction - Les deux voies',
      priority: UnitPriority.critical,
      theme: 'Sagesse',
      annotation: '🌳 Bienheureux celui qui médite',
      emotionalTones: ['meditation', 'choice', 'blessing'],
    ),
    
    // Psaumes de David - Livre I (lamentations et confiance)
    SemanticUnit(
      book: 'Psaumes', startChapter: 3, endChapter: 14,
      name: 'Lamentations et confiance',
      priority: UnitPriority.medium,
      theme: 'Confiance en Dieu',
      annotation: '🛡️ Dieu mon bouclier',
      emotionalTones: ['trust', 'protection', 'deliverance'],
    ),
    
    // Psaume 22-24 (Trilogie du Berger)
    SemanticUnit(
      book: 'Psaumes', startChapter: 22, endChapter: 24,
      name: 'Trilogie du Berger',
        priority: UnitPriority.critical,
      theme: 'Providence',
      annotation: '🐑 Souffrance, Bergerie, Roi de gloire',
      emotionalTones: ['suffering', 'care', 'glory'],
    ),
    
    // Psaumes de confiance
    SemanticUnit(
      book: 'Psaumes', startChapter: 42, endChapter: 43,
      name: 'Soif de Dieu',
      priority: UnitPriority.critical,
      theme: 'Désir de Dieu',
      annotation: '💧 Comme une biche soupire',
      emotionalTones: ['longing', 'thirst', 'hope'],
    ),
    
    // Psaumes royaux
    SemanticUnit(
      book: 'Psaumes', startChapter: 44, endChapter: 51,
      name: 'Royauté et repentance',
      priority: UnitPriority.medium,
      theme: 'Royauté et confession',
      annotation: '👑 Gloire du roi et repentir (Ps 51)',
      emotionalTones: ['glory', 'repentance', 'restoration'],
    ),
    
    // Psaumes de louange collective
    SemanticUnit(
      book: 'Psaumes', startChapter: 95, endChapter: 100,
      name: 'Louange universelle',
        priority: UnitPriority.high,
      theme: 'Adoration',
      annotation: '🎵 Venez chantons à l\'Éternel',
      emotionalTones: ['joy', 'celebration', 'worship'],
    ),
    
    // Psaume 119 - SEUL (acrostiche géant)
    SemanticUnit(
      book: 'Psaumes', startChapter: 119, endChapter: 119,
      name: 'Amour de la Loi',
        priority: UnitPriority.critical,
      theme: 'Parole de Dieu',
      annotation: '📜 Méditation géante (176 versets)',
      emotionalTones: ['meditation', 'love_of_word', 'obedience'],
    ),
    
    // PSAUMES DE MONTÉE (pèlerinage) - TOUJOURS ensemble
    SemanticUnit(
      book: 'Psaumes', startChapter: 120, endChapter: 134,
      name: 'Psaumes des montées',
        priority: UnitPriority.critical,
      theme: 'Pèlerinage',
      liturgicalContext: 'Pèlerinages à Jérusalem',
      annotation: '⛰️ Chants de pèlerinage vers Sion',
      emotionalTones: ['journey', 'anticipation', 'community', 'worship'],
    ),
    
    // Hallel final - Explosion de louange
    SemanticUnit(
      book: 'Psaumes', startChapter: 146, endChapter: 150,
      name: 'Grand Hallel',
        priority: UnitPriority.critical,
      theme: 'Louange pure',
      annotation: '🎺 Que tout ce qui respire loue l\'Éternel !',
      emotionalTones: ['ecstasy', 'praise', 'glory', 'culmination'],
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════════
  // 📖 LIVRES PAULINIENS
  // ═══════════════════════════════════════════════════════════════════
  
  static const _romainsUnits = [
    // Introduction théologique
    SemanticUnit(
      book: 'Romains', startChapter: 1, endChapter: 3,
      name: 'Condamnation universelle',
        priority: UnitPriority.high,
      theme: 'Péché',
      annotation: '⚖️ Tous ont péché',
      emotionalTones: ['conviction', 'judgment', 'need'],
    ),
    
    // Justification par la foi - CŒUR de Romains
    SemanticUnit(
      book: 'Romains', startChapter: 4, endChapter: 5,
      name: 'Justification par la foi',
      priority: UnitPriority.critical,
      theme: 'Salut',
      annotation: '✝️ Abraham et la grâce',
      emotionalTones: ['grace', 'faith', 'peace'],
    ),
    
    // Vie en Christ
    SemanticUnit(
      book: 'Romains', startChapter: 6, endChapter: 8,
      name: 'Vie dans l\'Esprit',
      priority: UnitPriority.critical,
      theme: 'Sanctification',
      annotation: '🕊️ Plus de condamnation - L\'Esprit nous libère',
      emotionalTones: ['freedom', 'life', 'hope', 'assurance'],
    ),
    
    // Israël dans le plan de Dieu
    SemanticUnit(
      book: 'Romains', startChapter: 9, endChapter: 11,
      name: 'Le mystère d\'Israël',
        priority: UnitPriority.high,
      theme: 'Souveraineté',
      annotation: '🌿 L\'olivier franc et sauvage',
      emotionalTones: ['mystery', 'sovereignty', 'faithfulness'],
    ),
    
    // Application pratique
    SemanticUnit(
      book: 'Romains', startChapter: 12, endChapter: 16,
      name: 'Vie transformée',
      priority: UnitPriority.medium,
      theme: 'Éthique',
      annotation: '🔥 Sacrifices vivants',
      emotionalTones: ['transformation', 'service', 'love'],
    ),
  ];
  
  static const _galatesUnits = [
    // Défense de l'Évangile
    SemanticUnit(
      book: 'Galates', startChapter: 1, endChapter: 2,
      name: 'Un seul Évangile',
        priority: UnitPriority.high,
      theme: 'Autorité',
      annotation: '⚡ Anathème sur les faux évangiles',
      emotionalTones: ['urgency', 'defense', 'truth'],
    ),
    
    // Justification par la foi
    SemanticUnit(
      book: 'Galates', startChapter: 3, endChapter: 4,
      name: 'Liberté en Christ',
      priority: UnitPriority.critical,
      theme: 'Grâce',
      annotation: '🔓 La loi était un pédagogue',
      emotionalTones: ['freedom', 'grace', 'adoption'],
    ),
    
    // Vie par l'Esprit
    SemanticUnit(
      book: 'Galates', startChapter: 5, endChapter: 6,
      name: 'Fruit de l\'Esprit',
      priority: UnitPriority.critical,
      theme: 'Sanctification',
      annotation: '🍇 Marchez par l\'Esprit',
      emotionalTones: ['fruit', 'freedom', 'transformation'],
    ),
  ];
  
  static const _ephesiensUnits = [
    // Richesse en Christ
    SemanticUnit(
      book: 'Éphésiens', startChapter: 1, endChapter: 3,
      name: 'Richesse spirituelle',
      priority: UnitPriority.critical,
      theme: 'Identité en Christ',
      annotation: '💎 Béni de toute bénédiction',
      emotionalTones: ['blessing', 'identity', 'mystery'],
    ),
    
    // Vie pratique
    SemanticUnit(
      book: 'Éphésiens', startChapter: 4, endChapter: 6,
      name: 'Marche digne',
      priority: UnitPriority.high,
      theme: 'Éthique',
      annotation: '🛡️ Armure de Dieu',
      emotionalTones: ['unity', 'purity', 'warfare'],
    ),
  ];
  
  static const _philippiensUnits = [
    // Joie dans l'épreuve
    SemanticUnit(
      book: 'Philippiens', startChapter: 1, endChapter: 2,
      name: 'Hymne à Christ',
      priority: UnitPriority.critical,
      theme: 'Joie et humilité',
      annotation: '😊 Réjouissez-vous + Hymne christologique',
      emotionalTones: ['joy', 'humility', 'unity'],
    ),
    
    // Course et prix
    SemanticUnit(
      book: 'Philippiens', startChapter: 3, endChapter: 4,
      name: 'Courir vers le but',
      priority: UnitPriority.high,
      theme: 'Persévérance',
      annotation: '🏃 Je cours vers le but',
      emotionalTones: ['perseverance', 'joy', 'peace'],
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════════
  // 📖 ANCIEN TESTAMENT
  // ═══════════════════════════════════════════════════════════════════
  
  static const _geneseUnits = [
    // Création
    SemanticUnit(
      book: 'Genèse', startChapter: 1, endChapter: 2,
      name: 'Création du monde',
      priority: UnitPriority.critical,
      theme: 'Création',
      annotation: '🌍 Au commencement, Dieu créa',
      emotionalTones: ['wonder', 'order', 'blessing'],
    ),
    
    // Chute
    SemanticUnit(
      book: 'Genèse', startChapter: 3, endChapter: 3,
      name: 'La chute',
      priority: UnitPriority.critical,
      theme: 'Péché',
      liturgicalContext: 'Carême',
      annotation: '🍎 Entrée du péché',
      emotionalTones: ['temptation', 'shame', 'consequence', 'hope'],
    ),
    
    // Déluge et alliance
    SemanticUnit(
      book: 'Genèse', startChapter: 6, endChapter: 9,
      name: 'Noé et le déluge',
      priority: UnitPriority.high,
      theme: 'Jugement et grâce',
      annotation: '🌈 Arc-en-ciel de l\'alliance',
      emotionalTones: ['judgment', 'salvation', 'covenant'],
    ),
    
    // Abraham - cycle complet
    SemanticUnit(
      book: 'Genèse', startChapter: 12, endChapter: 25,
      name: 'Abraham - Père de la foi',
      priority: UnitPriority.high,
      theme: 'Alliance',
      annotation: '⭐ Promesses à Abraham',
      emotionalTones: ['faith', 'promise', 'obedience'],
    ),
    
    // Joseph - saga complète
    SemanticUnit(
      book: 'Genèse', startChapter: 37, endChapter: 50,
      name: 'Joseph - Providence divine',
      priority: UnitPriority.high,
      theme: 'Providence',
      annotation: '👔 Vous avez voulu me faire du mal, Dieu l\'a changé en bien',
      emotionalTones: ['suffering', 'perseverance', 'providence', 'forgiveness'],
    ),
  ];
  
  static const _exodeUnits = [
    // Oppression et appel de Moïse
    SemanticUnit(
      book: 'Exode', startChapter: 1, endChapter: 4,
      name: 'Esclavage et appel',
      priority: UnitPriority.high,
      theme: 'Libération',
      annotation: '🔥 Buisson ardent',
      emotionalTones: ['oppression', 'calling', 'mission'],
    ),
    
    // Plaies et Pâque
    SemanticUnit(
      book: 'Exode', startChapter: 7, endChapter: 12,
      name: 'Plaies et Pâque',
      priority: UnitPriority.critical,
      theme: 'Rédemption',
      liturgicalContext: 'Pâques',
      annotation: '🩸 Agneau pascal',
      emotionalTones: ['judgment', 'deliverance', 'remembrance'],
    ),
    
    // Mer Rouge et désert
    SemanticUnit(
      book: 'Exode', startChapter: 13, endChapter: 18,
      name: 'Passage et voyage',
      priority: UnitPriority.high,
      theme: 'Délivrance',
      annotation: '🌊 Traversée de la Mer Rouge',
      emotionalTones: ['deliverance', 'victory', 'provision'],
    ),
    
    // Alliance au Sinaï - CRITIQUE
    SemanticUnit(
      book: 'Exode', startChapter: 19, endChapter: 24,
      name: 'Alliance au Sinaï',
      priority: UnitPriority.critical,
      theme: 'Loi',
      annotation: '⚡ Les Dix Commandements',
      emotionalTones: ['reverence', 'covenant', 'obedience'],
    ),
    
    // Tabernacle
    SemanticUnit(
      book: 'Exode', startChapter: 25, endChapter: 40,
      name: 'Construction du Tabernacle',
      priority: UnitPriority.medium,
      theme: 'Présence de Dieu',
      annotation: '⛺ La gloire de Dieu habite',
      emotionalTones: ['worship', 'presence', 'holiness'],
    ),
  ];
  
  static const _proverbesUnits = [
    // Introduction
    SemanticUnit(
      book: 'Proverbes', startChapter: 1, endChapter: 9,
      name: 'Appel de la Sagesse',
      priority: UnitPriority.critical,
      theme: 'Sagesse',
      annotation: '📚 La crainte de l\'Éternel est le commencement',
      emotionalTones: ['wisdom', 'instruction', 'discernment'],
    ),
    
    // Proverbes de Salomon (lecture quotidienne possible)
    SemanticUnit(
      book: 'Proverbes', startChapter: 10, endChapter: 29,
      name: 'Sagesse pratique',
      priority: UnitPriority.low, // Peut être divisé par chapitre/jour
      theme: 'Vie quotidienne',
      annotation: '💡 Proverbes pour la vie',
      emotionalTones: ['practical_wisdom', 'discipline', 'righteousness'],
    ),
    
    // Conclusion
    SemanticUnit(
      book: 'Proverbes', startChapter: 30, endChapter: 31,
      name: 'Paroles d\'Agur et femme vaillante',
      priority: UnitPriority.high,
      theme: 'Sagesse culminante',
      annotation: '👑 La femme vertueuse',
      emotionalTones: ['excellence', 'virtue', 'wisdom'],
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════════
  // 🗺️ MAP COMPLÈTE DE TOUS LES LIVRES
  // ═══════════════════════════════════════════════════════════════════
  
  static final Map<String, List<SemanticUnit>> _allBoundaries = {
    'Matthieu': _matthieuUnits,
    'Marc': _marcUnits,
    'Luc': _lucUnits,
    'Jean': _jeanUnits,
    'Psaumes': _psaumesUnits,
    'Romains': _romainsUnits,
    'Galates': _galatesUnits,
    'Éphésiens': _ephesiensUnits,
    'Philippiens': _philippiensUnits,
    'Genèse': _geneseUnits,
    'Exode': _exodeUnits,
    'Proverbes': _proverbesUnits,
  };
  
  // ═══════════════════════════════════════════════════════════════════
  // 🧠 API PUBLIQUE
  // ═══════════════════════════════════════════════════════════════════
  
  /// Récupère toutes les unités sémantiques pour un livre
  static List<SemanticUnit> getUnitsForBook(String book) {
    return _allBoundaries[book] ?? [];
  }
  
  /// Trouve l'unité sémantique contenant un chapitre donné (O(1) avec index)
  static SemanticUnit? findUnitContaining(String book, int chapter) {
    final index = _unitsIndex.forBook(book);
    return index[chapter];
  }
  
  /// 🎯 Suggère le meilleur découpage pour une liste de chapitres
  /// selon le profil utilisateur et les priorités sémantiques
  static List<SemanticUnit> suggestOptimalUnits({
    required String book,
    required int fromChapter,
    required int toChapter,
    UnitPriority? minPriority,
    List<String>? preferredThemes,
    String? liturgicalSeason,
  }) {
    final units = getUnitsForBook(book);
    final result = <SemanticUnit>[];
    
    for (final unit in units) {
      // Vérifie si l'unité chevauche la plage demandée
      final overlaps = unit.startChapter <= toChapter && unit.endChapter >= fromChapter;
      if (!overlaps) continue;
      
      // Filtrer par priorité minimum
      if (minPriority != null) {
        final priorityIndex = UnitPriority.values.indexOf(unit.priority);
        final minPriorityIndex = UnitPriority.values.indexOf(minPriority);
        if (priorityIndex > minPriorityIndex) continue; // Priorité trop basse
      }
      
      // Filtrer par thème préféré
      if (preferredThemes != null && unit.theme != null) {
        if (!preferredThemes.contains(unit.theme)) continue;
      }
      
      // Filtrer par saison liturgique
      if (liturgicalSeason != null && unit.liturgicalContext != null) {
        if (!unit.liturgicalContext!.toLowerCase().contains(liturgicalSeason.toLowerCase())) {
          continue;
        }
      }
      
      result.add(unit);
    }
    
    return result;
  }
  
  /// 🧠 Algorithme intelligent : Découpe une liste de chapitres en unités optimales
  /// 
  /// Stratégie :
  /// 1. Privilégier les unités CRITICAL/HIGH qui tombent dans la plage
  /// 2. Compléter avec des chapitres individuels pour les zones non couvertes
  /// 3. Adapter selon le profil utilisateur (débutant = unités plus courtes)
  static List<String> splitIntoOptimalReadings({
    required String book,
    required int startChapter,
    required int endChapter,
    required int targetReadings, // Nombre de lectures souhaitées
    String? userLevel, // Pour ajuster la taille
  }) {
    final units = getUnitsForBook(book);
    final readings = <String>[];
    
    int currentChapter = startChapter;
    
    while (currentChapter <= endChapter && readings.length < targetReadings) {
      // Chercher une unité sémantique qui commence ici
      SemanticUnit? matchingUnit;
      
      for (final unit in units) {
        if (unit.startChapter == currentChapter && 
            unit.endChapter <= endChapter &&
            (unit.priority == UnitPriority.critical || unit.priority == UnitPriority.high)) {
          matchingUnit = unit;
          break;
        }
      }
      
      if (matchingUnit != null) {
        // Utiliser l'unité sémantique
        readings.add(matchingUnit.reference);
        currentChapter = matchingUnit.endChapter + 1;
      } else {
        // Chapitre individuel
        readings.add('$book $currentChapter');
        currentChapter++;
      }
    }
    
    return readings;
  }
  
  /// 🎨 Récupère l'annotation la plus pertinente pour un chapitre
  static String? getAnnotationForChapter(String book, int chapter) {
    final unit = findUnitContaining(book, chapter);
    return unit?.annotation;
  }
  
  /// 🎭 Récupère les tons émotionnels pour un passage
  static List<String> getEmotionalTonesForChapter(String book, int chapter) {
    final unit = findUnitContaining(book, chapter);
    return unit?.emotionalTones ?? [];
  }
  
  /// 📅 Filtre les unités par saison liturgique
  static List<SemanticUnit> getUnitsForLiturgicalSeason(String season) {
    final result = <SemanticUnit>[];
    
    for (final units in _allBoundaries.values) {
      for (final unit in units) {
        if (unit.liturgicalContext?.toLowerCase().contains(season.toLowerCase()) ?? false) {
          result.add(unit);
        }
      }
    }
    
    return result;
  }
  
  /// 🎯 Trouve les unités les plus pertinentes pour un thème
  static List<SemanticUnit> getUnitsForTheme(String theme) {
    final result = <SemanticUnit>[];
    
    for (final units in _allBoundaries.values) {
      for (final unit in units) {
        if (unit.theme?.toLowerCase().contains(theme.toLowerCase()) ?? false) {
          result.add(unit);
        }
      }
    }
    
    // Trier par priorité
    result.sort((a, b) {
      final aPriority = UnitPriority.values.indexOf(a.priority);
      final bPriority = UnitPriority.values.indexOf(b.priority);
      return aPriority.compareTo(bPriority);
    });
    
    return result;
  }
  
  /// 🎯 Ajuste un passage [startChapter..endChapter] pour éviter de couper
  /// des unités CRITICAL/HIGH. Granularité chapitre.
  static AdjustedPassage adjustPassageVerses({
    required String book,
    required int startChapter,
    required int endChapter,
  }) {
    final units = getUnitsForBook(book);
    final originalStart = startChapter;
    final originalEnd = endChapter;

    if (startChapter > endChapter) {
      // garde un fallback sain
      final tmp = startChapter;
      startChapter = endChapter;
      endChapter = tmp;
    }

    // Étape 1 : si le passage coupe une unité CRITICAL/HIGH, on "snap"
    for (final u in units) {
      final cutsUnit = (startChapter <= u.endChapter) && (endChapter >= u.startChapter);
      if (!cutsUnit) continue;

      final isCriticalOrHigh = u.priority == UnitPriority.critical || u.priority == UnitPriority.high;

      if (isCriticalOrHigh) {
        // Étendre les bornes pour englober l'unité entière (stratégie conservative)
        startChapter = _mathMin(startChapter, u.startChapter);
        endChapter   = _mathMax(endChapter,   u.endChapter);
      }
    }

    // Étape 2 : optionnel — "snap" doux si on tombe juste à +/−1 d'une frontière
    bool adjusted = (startChapter != originalStart) || (endChapter != originalEnd);

    // Trouver une unité majoritaire incluse (pour annotation)
    SemanticUnit? best;
    int bestOverlap = -1;
    for (final u in units) {
      final overlap = _overlapLen(startChapter, endChapter, u.startChapter, u.endChapter);
      if (overlap > bestOverlap) {
        best = u;
        bestOverlap = overlap;
      }
    }

    final ref = (startChapter == endChapter)
        ? '$book $startChapter'
        : '$book $startChapter–$endChapter';

    return AdjustedPassage(
      book: book,
      startChapter: startChapter,
      startVerse: 1,
      endChapter: endChapter,
      endVerse: 999, // signale "fin de chapitre" ; remplace par verseCount si dispo
      adjusted: adjusted,
      reference: ref,
      includedUnit: best,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 🔧 HELPERS INTERNES
  // ═══════════════════════════════════════════════════════════════════
  
  /// Calcule la longueur d'overlap entre deux plages
  static int _overlapLen(int a1, int a2, int b1, int b2) {
    final s = _mathMax(a1, b1);
    final e = _mathMin(a2, b2);
    return (e >= s) ? (e - s + 1) : 0;
  }
  
  /// Math.min sans import dart:math
  static int _mathMin(int a, int b) => (a < b) ? a : b;
  
  /// Math.max sans import dart:math
  static int _mathMax(int a, int b) => (a > b) ? a : b;

  /// 📊 Statistiques de couverture
  static Map<String, dynamic> getStatistics() {
    int totalUnits = 0;
    int criticalUnits = 0;
    int highUnits = 0;
    
    for (final units in _allBoundaries.values) {
      totalUnits += units.length;
      criticalUnits += units.where((u) => u.priority == UnitPriority.critical).length;
      highUnits += units.where((u) => u.priority == UnitPriority.high).length;
    }
    
    return {
      'total_books': _allBoundaries.length,
      'total_units': totalUnits,
      'critical_units': criticalUnits,
      'high_priority_units': highUnits,
      'coverage': '${_allBoundaries.length} livres avec frontières sémantiques',
      'performance': 'Index O(1) activé pour lookup rapide',
    };
  }
}
