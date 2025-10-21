import 'dart:convert';
import 'package:flutter/services.dart';
import 'thomson_extended_service.dart';

/// Service Thomson pour l'analyse biblique et l'étude des personnages/thèmes
/// 
/// Intégré avec ThomsonExtendedService pour les chaînes de références Thompson
class ThomsonService {
  static Map<String, dynamic>? _thomsonData;
  
  /// Initialise le service Thomson
  static Future<void> init() async {
    if (_thomsonData != null) return;
    
    try {
      // Initialiser les deux services
      final String jsonString = await rootBundle.loadString('assets/data/thomson_analysis.json');
      _thomsonData = json.decode(jsonString);
      
      // Initialiser le service étendu Thompson
      await ThomsonExtendedService.init();
      
      print('✅ ThomsonService initialisé avec ${_thomsonData?.length ?? 0} entrées + Thompson étendu');
    } catch (e) {
      print('⚠️ Erreur chargement ThomsonService: $e');
      _thomsonData = {};
    }
  }
  
  /// Récupère les données d'étude pour un verset
  static Future<Map<String, dynamic>> getStudyData(String verseId) async {
    await init();
    
    print('🔍 ThomsonService.getStudyData pour: $verseId');
    
    if (_thomsonData == null) {
      print('⚠️ _thomsonData est null');
      return {
        'themes': <String>[],
        'characters': <String>[],
        'context': '',
      };
    }
    
    // Extraire le livre et chapitre du verseId (ex: "Jean.3.16" -> "Jean", 3)
    final parts = verseId.split('.');
    if (parts.length < 2) {
      print('⚠️ VerseId invalide: $verseId');
      return _getDefaultData();
    }
    
    final book = parts[0];
    final chapter = int.tryParse(parts[1]);
    if (chapter == null) {
      print('⚠️ Chapitre invalide: ${parts[1]}');
      return _getDefaultData();
    }
    
    print('🔍 Recherche: livre=$book, chapitre=$chapter');
    
    // Chercher dans les données Thomson
    final bookData = _thomsonData![book];
    if (bookData == null) {
      print('⚠️ Livre non trouvé: $book');
      print('🔍 Livres disponibles: ${_thomsonData!.keys.toList()}');
      
      // Fallback intelligent : utiliser des données génériques
      return _getFallbackDataForBook(book, chapter, 1);
    }
    
    print('✅ Livre trouvé: $book');
    
    // Récupérer les thèmes et personnages pour ce chapitre
    final themes = <String>[];
    final characters = <String>[];
    
    // Parcourir les versets du chapitre
    final chapterData = bookData['chapters']?[chapter.toString()];
    if (chapterData != null) {
      print('✅ Chapitre trouvé: $chapter');
      print('🔍 Versets disponibles: ${chapterData.keys.toList()}');
      
      chapterData.forEach((verseNum, verseData) {
        print('🔍 Traitement verset $verseNum: $verseData');
        if (verseData is Map<String, dynamic>) {
          // Ajouter les thèmes
          final verseThemes = verseData['themes'] as List?;
          if (verseThemes != null) {
            themes.addAll(verseThemes.cast<String>());
            print('🔍 Thèmes ajoutés: $verseThemes');
          }
          
          // Ajouter les personnages
          final verseCharacters = verseData['characters'] as List?;
          if (verseCharacters != null) {
            characters.addAll(verseCharacters.cast<String>());
            print('🔍 Personnages ajoutés: $verseCharacters');
          }
        }
      });
    } else {
      print('⚠️ Chapitre non trouvé: $chapter');
    }
    
    // Supprimer les doublons et limiter
    final uniqueThemes = themes.toSet().take(5).toList();
    final uniqueCharacters = characters.toSet().take(5).toList();
    
    print('🔍 Résultat final - Thèmes: $uniqueThemes, Personnages: $uniqueCharacters');
    
    return {
      'themes': uniqueThemes,
      'characters': uniqueCharacters,
      'context': _getContextualInfo(book, chapter),
    };
  }
  
  /// Récupère les thèmes pour un verset spécifique
  static Future<List<String>> getThemes(String verseId) async {
    final data = await getStudyData(verseId);
    return data['themes'] as List<String>;
  }
  
  /// Récupère les personnages pour un verset spécifique
  static Future<List<String>> getCharacters(String verseId) async {
    final data = await getStudyData(verseId);
    return data['characters'] as List<String>;
  }
  
  /// Récupère le contexte pour un livre et chapitre
  static Future<String> getContext(String verseId) async {
    final data = await getStudyData(verseId);
    return data['context'] as String;
  }
  
  /// Données par défaut si aucune donnée Thomson n'est trouvée
  static Map<String, dynamic> _getDefaultData() {
    return {
      'themes': <String>[],
      'characters': <String>[],
      'context': '',
    };
  }
  
  /// Données de fallback intelligentes pour les livres sans données spécifiques
  static Map<String, dynamic> _getFallbackDataForBook(String book, int chapter, int verse) {
    print('🔄 Génération de données de fallback pour $book $chapter:$verse');
    
    // Thèmes génériques basés sur le type de livre
    final themes = _getGenericThemesForBook(book);
    
    // Personnages génériques basés sur le livre
    final characters = _getGenericCharactersForBook(book);
    
    // Contexte générique
    final context = _getGenericContextForBook(book, chapter);
    
    return {
      'themes': themes,
      'characters': characters,
      'context': context,
    };
  }
  
  /// Thèmes génériques basés sur le type de livre
  static List<String> _getGenericThemesForBook(String book) {
    final bookThemes = {
      'Matthieu': ['Royaume de Dieu', 'Jésus Messie', 'Enseignement', 'Prophétie'],
      'Marc': ['Ministère de Jésus', 'Miracles', 'Serviteur', 'Évangile'],
      'Luc': ['Salut universel', 'Grâce', 'Prière', 'Esprit Saint'],
      'Jean': ['Vie éternelle', 'Amour de Dieu', 'Vérité', 'Révélation'],
      'Actes': ['Église primitive', 'Esprit Saint', 'Mission', 'Témoignage'],
      'Romains': ['Justification', 'Grâce', 'Foi', 'Salut'],
      '1 Corinthiens': ['Église', 'Amour', 'Résurrection', 'Dons spirituels'],
      '2 Corinthiens': ['Ministère', 'Souffrance', 'Gloire', 'Réconciliation'],
      'Galates': ['Liberté', 'Foi', 'Esprit', 'Loi vs Grâce'],
      'Éphésiens': ['Église', 'Unité', 'Amour', 'Armure de Dieu'],
      'Philippiens': ['Joie', 'Christ', 'Humilité', 'Contentement'],
      'Colossiens': ['Prééminence de Christ', 'Sagesse', 'Prière', 'Vie nouvelle'],
      '1 Thessaloniciens': ['Espérance', 'Retour de Christ', 'Sainteté', 'Édification'],
      '2 Thessaloniciens': ['Retour de Christ', 'Persévérance', 'Travail', 'Ordre'],
      '1 Timothée': ['Ministère', 'Doctrine', 'Conduite', 'Église'],
      '2 Timothée': ['Fidélité', 'Souffrance', 'Évangile', 'Héritage'],
      'Tite': ['Bonnes œuvres', 'Doctrine', 'Conduite', 'Grâce'],
      'Philémon': ['Grâce', 'Réconciliation', 'Amour', 'Fraternité'],
      'Hébreux': ['Christ supérieur', 'Foi', 'Persévérance', 'Nouvelle alliance'],
      'Jacques': ['Foi et œuvres', 'Sagesse', 'Épreuves', 'Prière'],
      '1 Pierre': ['Souffrance', 'Espérance', 'Sainte conduite', 'Grâce'],
      '2 Pierre': ['Connaissance', 'Virtue', 'Croissance', 'Prophétie'],
      '1 Jean': ['Amour', 'Vie éternelle', 'Vérité', 'Communion'],
      '2 Jean': ['Vérité', 'Amour', 'Marche', 'Doctrine'],
      '3 Jean': ['Hospitalité', 'Vérité', 'Bien-être', 'Témoignage'],
      'Jude': ['Foi', 'Miséricorde', 'Jugement', 'Préservation'],
      'Apocalypse': ['Révélation', 'Jugement', 'Espérance', 'Victoire'],
    };
    
    return bookThemes[book] ?? ['Étude biblique', 'Parole de Dieu', 'Foi', 'Espérance'];
  }
  
  /// Personnages génériques basés sur le livre
  static List<String> _getGenericCharactersForBook(String book) {
    final bookCharacters = {
      'Matthieu': ['Jésus', 'Marie', 'Joseph', 'Pierre', 'Jean'],
      'Marc': ['Jésus', 'Pierre', 'Jean', 'Jacques', 'Marie'],
      'Luc': ['Jésus', 'Marie', 'Pierre', 'Paul', 'Jean'],
      'Jean': ['Jésus', 'Pierre', 'Jean', 'Marie', 'Thomas'],
      'Actes': ['Pierre', 'Paul', 'Jean', 'Barnabas', 'Étienne'],
      'Romains': ['Paul', 'Pierre', 'Timothée', 'Priscille', 'Aquilas'],
      '1 Corinthiens': ['Paul', 'Pierre', 'Apollos', 'Timothée', 'Étienne'],
      '2 Corinthiens': ['Paul', 'Timothée', 'Tite', 'Barnabas', 'Pierre'],
      'Galates': ['Paul', 'Pierre', 'Barnabas', 'Tite', 'Timothée'],
      'Éphésiens': ['Paul', 'Tychique', 'Timothée', 'Pierre', 'Jean'],
      'Philippiens': ['Paul', 'Timothée', 'Épaphrodite', 'Pierre', 'Jean'],
      'Colossiens': ['Paul', 'Tychique', 'Onésime', 'Timothée', 'Pierre'],
      '1 Thessaloniciens': ['Paul', 'Silvain', 'Timothée', 'Pierre', 'Jean'],
      '2 Thessaloniciens': ['Paul', 'Silvain', 'Timothée', 'Pierre', 'Jean'],
      '1 Timothée': ['Paul', 'Timothée', 'Pierre', 'Jean', 'Barnabas'],
      '2 Timothée': ['Paul', 'Timothée', 'Pierre', 'Jean', 'Onésiphore'],
      'Tite': ['Paul', 'Tite', 'Pierre', 'Jean', 'Timothée'],
      'Philémon': ['Paul', 'Philémon', 'Onésime', 'Tite', 'Timothée'],
      'Hébreux': ['Paul', 'Pierre', 'Jean', 'Timothée', 'Barnabas'],
      'Jacques': ['Jacques', 'Jésus', 'Pierre', 'Jean', 'Paul'],
      '1 Pierre': ['Pierre', 'Paul', 'Jean', 'Marie', 'Jésus'],
      '2 Pierre': ['Pierre', 'Paul', 'Jean', 'Jésus', 'Marie'],
      '1 Jean': ['Jean', 'Jésus', 'Pierre', 'Paul', 'Marie'],
      '2 Jean': ['Jean', 'Jésus', 'Pierre', 'Paul', 'Marie'],
      '3 Jean': ['Jean', 'Gaïus', 'Démétrius', 'Pierre', 'Paul'],
      'Jude': ['Jude', 'Jésus', 'Pierre', 'Jean', 'Paul'],
      'Apocalypse': ['Jean', 'Jésus', 'Pierre', 'Paul', 'Marie'],
    };
    
    return bookCharacters[book] ?? ['Auteur biblique', 'Personnages bibliques'];
  }
  
  /// Contexte générique basé sur le livre et chapitre
  static String _getGenericContextForBook(String book, int chapter) {
    final contexts = {
      'Matthieu': 'Évangile de Matthieu - Jésus comme Roi et Messie promis',
      'Marc': 'Évangile de Marc - Jésus comme Serviteur souffrant',
      'Luc': 'Évangile de Luc - Jésus comme Fils de l\'homme parfait',
      'Jean': 'Évangile de Jean - Jésus comme Fils de Dieu éternel',
      'Actes': 'Livre des Actes - Histoire de l\'Église primitive et de l\'expansion de l\'Évangile',
      'Romains': 'Épître aux Romains - Doctrine de la justification par la foi seule',
      '1 Corinthiens': '1 Corinthiens - Instructions pour l\'Église de Corinthe',
      '2 Corinthiens': '2 Corinthiens - Ministère de Paul et défense de son apostolat',
      'Galates': 'Épître aux Galates - Liberté en Christ contre le légalisme',
      'Éphésiens': 'Épître aux Éphésiens - L\'Église comme corps de Christ',
      'Philippiens': 'Épître aux Philippiens - La joie en Christ malgré les épreuves',
      'Colossiens': 'Épître aux Colossiens - La prééminence de Christ',
      '1 Thessaloniciens': '1 Thessaloniciens - L\'espérance du retour de Christ',
      '2 Thessaloniciens': '2 Thessaloniciens - Instructions sur le retour de Christ',
      '1 Timothée': '1 Timothée - Instructions pour le ministère pastoral',
      '2 Timothée': '2 Timothée - Exhortation à la fidélité dans le ministère',
      'Tite': 'Épître à Tite - Instructions pour l\'organisation de l\'Église',
      'Philémon': 'Épître à Philémon - Exemple de réconciliation chrétienne',
      'Hébreux': 'Épître aux Hébreux - Christ supérieur à l\'ancienne alliance',
      'Jacques': 'Épître de Jacques - La foi qui produit des œuvres',
      '1 Pierre': '1 Pierre - Exhortation à la sainteté dans la souffrance',
      '2 Pierre': '2 Pierre - Croissance dans la grâce et la connaissance',
      '1 Jean': '1 Jean - L\'amour de Dieu et la vie éternelle',
      '2 Jean': '2 Jean - Marcher dans la vérité et l\'amour',
      '3 Jean': '3 Jean - L\'hospitalité et le soutien des missionnaires',
      'Jude': 'Épître de Jude - Contre les faux enseignants',
      'Apocalypse': 'Apocalypse - Révélation de Jésus-Christ et de la fin des temps',
    };
    
    return contexts[book] ?? 'Livre biblique - Parole de Dieu inspirée';
  }
  
  /// Génère des informations contextuelles basiques
  static String _getContextualInfo(String book, int chapter) {
    final contextMap = {
      'Jean': 'Évangile de Jean - Révélation de Jésus comme Fils de Dieu',
      'Matthieu': 'Évangile de Matthieu - Jésus comme Roi et Messie',
      'Marc': 'Évangile de Marc - Jésus comme Serviteur',
      'Luc': 'Évangile de Luc - Jésus comme Fils de l\'homme',
      'Actes': 'Livre des Actes - Histoire de l\'Église primitive',
      'Romains': 'Épître aux Romains - Doctrine de la justification par la foi',
      '1 Corinthiens': '1 Corinthiens - Instructions pour l\'Église de Corinthe',
      '2 Corinthiens': '2 Corinthiens - Ministère de Paul et défense de son apostolat',
      'Galates': 'Épître aux Galates - Liberté en Christ vs légalisme',
      'Éphésiens': 'Épître aux Éphésiens - L\'Église comme corps de Christ',
      'Philippiens': 'Épître aux Philippiens - Joie en Christ malgré les épreuves',
      'Colossiens': 'Épître aux Colossiens - Supériorité de Christ',
      '1 Thessaloniciens': '1 Thessaloniciens - Espérance du retour de Christ',
      '2 Thessaloniciens': '2 Thessaloniciens - Enseignements sur les derniers temps',
      '1 Timothée': '1 Timothée - Instructions pour le ministère pastoral',
      '2 Timothée': '2 Timothée - Dernières exhortations de Paul',
      'Tite': 'Épître à Tite - Organisation de l\'Église en Crète',
      'Philémon': 'Épître à Philémon - Réconciliation et pardon',
      'Hébreux': 'Épître aux Hébreux - Supériorité de Christ sur l\'Ancienne Alliance',
      'Jacques': 'Épître de Jacques - Foi et œuvres',
      '1 Pierre': '1 Pierre - Souffrance et espérance chrétienne',
      '2 Pierre': '2 Pierre - Croissance spirituelle et vigilance',
      '1 Jean': '1 Jean - Amour de Dieu et communion fraternelle',
      '2 Jean': '2 Jean - Marche dans la vérité',
      '3 Jean': '3 Jean - Hospitalité et vérité',
      'Jude': 'Épître de Jude - Contre les faux enseignants',
      'Apocalypse': 'Apocalypse - Révélation de Jésus-Christ et des temps de la fin',
    };
    
    return contextMap[book] ?? 'Contexte biblique général';
  }
  
  /// Vérifie si le service est initialisé
  static bool get isInitialized => _thomsonData != null;
  
  /// Obtient le nombre d'entrées chargées
  static int get entryCount => _thomsonData?.length ?? 0;
  
  /// Récupère les chaînes de références Thompson pour un passage
  /// 
  /// [reference] : Référence biblique complète (ex: "1 Pierre 1:1-2:25")
  /// 
  /// Retourne : Liste des références liées selon Thompson
  static Future<List<String>> getThompsonChains(String reference) async {
    await init();
    return await ThomsonExtendedService.getThompsonChains(reference);
  }
  
  /// Récupère les thèmes Thompson enrichis pour un passage
  /// 
  /// [reference] : Référence biblique complète
  /// 
  /// Retourne : Liste des thèmes Thompson
  static Future<List<String>> getThompsonThemes(String reference) async {
    await init();
    return await ThomsonExtendedService.getThompsonThemes(reference);
  }
  
  /// Récupère les notices archéologiques pour un passage
  /// 
  /// [reference] : Référence biblique complète
  /// 
  /// Retourne : Liste des notices archéologiques
  static Future<List<String>> getArchaeologicalNotices(String reference) async {
    await init();
    return await ThomsonExtendedService.getArchaeologicalNotices(reference);
  }
  
  /// Récupère les portraits de personnages pour un passage
  /// 
  /// [reference] : Référence biblique complète
  /// 
  /// Retourne : Liste des portraits de personnages
  static Future<List<String>> getCharacterPortraits(String reference) async {
    await init();
    return await ThomsonExtendedService.getCharacterPortraits(reference);
  }
  
  /// Récupère toutes les données Thompson étendues pour un passage
  /// 
  /// [reference] : Référence biblique complète
  /// 
  /// Retourne : Toutes les données Thompson disponibles
  static Future<Map<String, dynamic>> getCompleteThompsonData(String reference) async {
    await init();
    return await ThomsonExtendedService.getCompleteThompsonData(reference);
  }
  
  /// Recherche avancée dans l'index Thompson
  /// 
  /// [query] : Terme de recherche
  /// 
  /// Retourne : Résultats de recherche avec contexte
  static Future<List<Map<String, dynamic>>> searchThompsonIndex(String query) async {
    await init();
    return await ThomsonExtendedService.searchThompsonIndex(query);
  }
}
