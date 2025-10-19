import 'dart:convert';
import 'package:flutter/services.dart';

/// Service Thomson pour l'analyse biblique et l'étude des personnages/thèmes
class ThomsonService {
  static Map<String, dynamic>? _thomsonData;
  
  /// Initialise le service Thomson
  static Future<void> init() async {
    if (_thomsonData != null) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/thomson_analysis.json');
      _thomsonData = json.decode(jsonString);
      print('✅ ThomsonService initialisé avec ${_thomsonData?.length ?? 0} entrées');
    } catch (e) {
      print('⚠️ Erreur chargement ThomsonService: $e');
      _thomsonData = {};
    }
  }
  
  /// Récupère les données d'étude pour un verset
  static Future<Map<String, dynamic>> getStudyData(String verseId) async {
    await init();
    
    if (_thomsonData == null) {
      return {
        'themes': <String>[],
        'characters': <String>[],
        'context': '',
      };
    }
    
    // Extraire le livre et chapitre du verseId (ex: "Jean.3.16" -> "Jean", 3)
    final parts = verseId.split('.');
    if (parts.length < 2) {
      return _getDefaultData();
    }
    
    final book = parts[0];
    final chapter = int.tryParse(parts[1]);
    if (chapter == null) {
      return _getDefaultData();
    }
    
    // Chercher dans les données Thomson
    final bookData = _thomsonData![book];
    if (bookData == null) {
      return _getDefaultData();
    }
    
    // Récupérer les thèmes et personnages pour ce chapitre
    final themes = <String>[];
    final characters = <String>[];
    
    // Parcourir les versets du chapitre
    final chapterData = bookData['chapters']?[chapter.toString()];
    if (chapterData != null) {
      chapterData.forEach((verseNum, verseData) {
        if (verseData is Map<String, dynamic>) {
          // Ajouter les thèmes
          final verseThemes = verseData['themes'] as List?;
          if (verseThemes != null) {
            themes.addAll(verseThemes.cast<String>());
          }
          
          // Ajouter les personnages
          final verseCharacters = verseData['characters'] as List?;
          if (verseCharacters != null) {
            characters.addAll(verseCharacters.cast<String>());
          }
        }
      });
    }
    
    // Supprimer les doublons et limiter
    final uniqueThemes = themes.toSet().take(5).toList();
    final uniqueCharacters = characters.toSet().take(5).toList();
    
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
}
