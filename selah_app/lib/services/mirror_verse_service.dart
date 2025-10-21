import 'package:hive/hive.dart';
import 'mirror_verse_extended_service.dart';

/// Service offline pour les versets miroirs (typologie biblique)
/// 
/// Sources de données :
/// - Hive box 'bible_mirrors'
/// - Hydratée depuis assets/jsons/mirrors.json
/// 
/// Format :
/// {
///   "Genèse.22.8": "Jean.1.29",  // Agneau de Dieu
///   "Exode.12.13": "1Corinthiens.5.7",  // Pâque → Christ
///   "Nombres.21.9": "Jean.3.14",  // Serpent élevé
///   ...
/// }
/// 
/// Concept : Versets de l'AT qui préfigurent le NT (typologie)
class MirrorVerseService {
  static Box? _mirrorsBox;
  
  /// Initialise la box Hive
  static Future<void> init() async {
    _mirrorsBox = await Hive.openBox('bible_mirrors');
    print('📦 Box Hive de base ouverte: ${_mirrorsBox?.length ?? 0} entrées');
    
    // Initialiser aussi le service etendu
    try {
      print('🔄 Tentative d\'initialisation du service etendu...');
      await MirrorVerseExtendedService.init();
      print('✅ Service etendu initialise avec succes');
    } catch (e) {
      print('⚠️ Erreur initialisation service etendu: $e');
    }
    
    // Recuperer le nombre total d'entrees (base + etendues)
    final baseCount = _mirrorsBox?.length ?? 0;
    try {
      final extendedCount = await MirrorVerseExtendedService.getExtendedStats();
      final totalCount = baseCount + (extendedCount['totalConnections'] ?? 0);
      print('✅ MirrorVerseService initialise ($baseCount entrees de base + ${extendedCount['totalConnections'] ?? 0} etendues = $totalCount total)');
    } catch (e) {
      print('⚠️ Erreur recuperation stats etendues: $e');
      print('✅ MirrorVerseService initialise ($baseCount entrees de base + 0 etendues = $baseCount total)');
    }
  }
  
  /// Récupère le verset miroir d'un verset
  ///
  /// [id] : ID du verset (ex: "Genèse.22.8")
  ///
  /// Retourne : ID du verset miroir ou null
  static Future<String?> mirrorOf(String id) async {
    try {
      // Chercher d'abord dans les donnees etendues
      final extendedMirror = await MirrorVerseExtendedService.extendedMirrorOf(id);
      if (extendedMirror != null) return extendedMirror;
      
      // Chercher dans les donnees de base
      final forward = _mirrorsBox?.get(id) as String?;
      if (forward != null) return forward;

      // Chercher en sens inverse dans les donnees de base
      final allKeys = _mirrorsBox?.keys ?? [];
      for (final key in allKeys) {
        final value = _mirrorsBox?.get(key) as String?;
        if (value == id) return key as String;
      }

      return null;
    } catch (e) {
      print('⚠️ Erreur mirrorOf($id): $e');
      return null;
    }
  }
  
  /// Récupère le verset miroir enrichi avec texte et explication
  ///
  /// [id] : ID du verset
  /// [getVerseText] : Fonction pour récupérer le texte
  ///
  /// Retourne : MirrorVerse enrichi ou null
  static Future<MirrorVerse?> enrichedMirror(
    String id, {
    required Future<String?> Function(String verseId) getVerseText,
  }) async {
    // Essayer d'abord le service etendu
    final extendedMirror = await MirrorVerseExtendedService.enrichedExtendedMirror(
      id,
      getVerseText: getVerseText,
    );
    if (extendedMirror != null) return extendedMirror;
    
    // Fallback sur le service de base
    final mirrorId = await mirrorOf(id);
    if (mirrorId == null) return null;

    final originalText = await getVerseText(id);
    final mirrorText = await getVerseText(mirrorId);
    final connection = _getConnectionType(id, mirrorId);

    return MirrorVerse(
      originalId: id,
      mirrorId: mirrorId,
      originalText: originalText,
      mirrorText: mirrorText,
      connectionType: connection,
      explanation: _getExplanation(id, mirrorId),
    );
  }
  
  /// Détermine le type de connexion typologique
  static ConnectionType _getConnectionType(String original, String mirror) {
    // Heuristiques simples basées sur les livres
    final origBook = original.split('.').first;
    final mirrBook = mirror.split('.').first;
    
    // AT → NT
    if (_isOldTestament(origBook) && _isNewTestament(mirrBook)) {
      return ConnectionType.prophecyFulfillment;
    }
    
    // NT → AT
    if (_isNewTestament(origBook) && _isOldTestament(mirrBook)) {
      return ConnectionType.typology;
    }
    
    // Même testament
    return ConnectionType.parallel;
  }
  
  /// Génère une explication de la connexion
  static String _getExplanation(String original, String mirror) {
    final origBook = original.split('.').first;
    final mirrBook = mirror.split('.').first;
    
    // Exemples connus
    if (original == 'Genèse.22.8' && mirror == 'Jean.1.29') {
      return 'L\'agneau que Dieu pourvoira (Isaac) préfigure l\'Agneau de Dieu (Jésus)';
    }
    if (original == 'Exode.12.13' && mirror == '1Corinthiens.5.7') {
      return 'L\'agneau pascal protège du jugement → Christ notre Pâque';
    }
    if (original == 'Nombres.21.9' && mirror == 'Jean.3.14') {
      return 'Le serpent élevé apporte la guérison → Jésus élevé apporte le salut';
    }
    
    // Générique
    if (_isOldTestament(origBook) && _isNewTestament(mirrBook)) {
      return 'Ce passage de l\'AT préfigure l\'accomplissement dans le NT';
    }
    
    return 'Ces versets s\'éclairent mutuellement';
  }
  
  /// Vérifie si un livre est dans l'AT
  static bool _isOldTestament(String book) {
    const otBooks = [
      'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
      'Josué', '1Samuel', '2Samuel', '1Rois', '2Rois',
      'Psaumes', 'Proverbes', 'Job', 'Ecclésiaste', 'Cantique',
      'Ésaïe', 'Jérémie', 'Ézéchiel', 'Daniel',
      // ... (simplifier)
    ];
    return otBooks.contains(book);
  }
  
  /// Vérifie si un livre est dans le NT
  static bool _isNewTestament(String book) {
    const ntBooks = [
      'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
      'Romains', '1Corinthiens', '2Corinthiens', 'Galates', 'Éphésiens',
      'Philippiens', 'Colossiens', '1Thessaloniciens', '2Thessaloniciens',
      '1Timothée', '2Timothée', 'Tite', 'Philémon',
      'Hébreux', 'Jacques', '1Pierre', '2Pierre',
      '1Jean', '2Jean', '3Jean', 'Jude', 'Apocalypse',
    ];
    return ntBooks.contains(book);
  }
  
  /// Hydrate la box depuis les assets JSON
  static Future<void> hydrateFromAssets(Map<String, dynamic> lexiconData) async {
    print('💧 Hydratation LexiconService...');
    
    int count = 0;
    for (final entry in lexiconData.entries) {
      await _mirrorsBox?.put(entry.key, entry.value);
      count++;
    }
    
    print('✅ $count entrées hydratées dans bible_lexicon');
  }
}

/// Type de connexion entre versets
enum ConnectionType {
  prophecyFulfillment,  // Prophétie accomplie
  typology,             // Typologie (AT préfigure NT)
  parallel,             // Passages parallèles
  echo,                 // Écho thématique
}

/// Verset miroir enrichi
class MirrorVerse {
  final String originalId;
  final String mirrorId;
  final String? originalText;
  final String? mirrorText;
  final ConnectionType connectionType;
  final String explanation;
  
  MirrorVerse({
    required this.originalId,
    required this.mirrorId,
    this.originalText,
    this.mirrorText,
    required this.connectionType,
    required this.explanation,
  });
  
  /// Titre de la connexion
  String get connectionTitle {
    switch (connectionType) {
      case ConnectionType.prophecyFulfillment:
        return 'Prophétie accomplie';
      case ConnectionType.typology:
        return 'Typologie biblique';
      case ConnectionType.parallel:
        return 'Passage parallèle';
      case ConnectionType.echo:
        return 'Écho thématique';
    }
  }
  
  /// Icône de la connexion
  String get connectionIcon {
    switch (connectionType) {
      case ConnectionType.prophecyFulfillment:
        return '✨';
      case ConnectionType.typology:
        return '🔗';
      case ConnectionType.parallel:
        return '↔️';
      case ConnectionType.echo:
        return '🔊';
    }
  }
}

/// Methodes etendues pour MirrorVerseService
extension MirrorVerseServiceExtended on MirrorVerseService {
  /// Recherche etendue par theme
  static Future<List<Map<String, String>>> searchByTheme(String theme) async {
    return await MirrorVerseExtendedService.searchByTheme(theme);
  }

  /// Recherche etendue par livre
  static Future<List<Map<String, String>>> searchByBook(String book) async {
    return await MirrorVerseExtendedService.searchByBook(book);
  }

  /// Statistiques etendues
  static Future<Map<String, int>> getExtendedStats() async {
    return await MirrorVerseExtendedService.getExtendedStats();
  }

  /// Reinitialise les donnees etendues
  static Future<void> resetExtendedData() async {
    return await MirrorVerseExtendedService.resetExtendedData();
  }
}




