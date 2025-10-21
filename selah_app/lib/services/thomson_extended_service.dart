import 'dart:convert';
import 'package:flutter/services.dart';

/// Service étendu pour les chaînes de références Thompson
/// 
/// Sources de données :
/// - assets/data/thomson_index.json (Index Thompson complet)
/// - assets/data/thomson_analysis.json (Données Thomson existantes)
/// 
/// Fonctionnalités :
/// - Chaînes de références Thompson
/// - Thèmes bibliques enrichis
/// - Notices archéologiques
/// - Portraits de personnages
class ThomsonExtendedService {
  static Map<String, dynamic>? _thomsonIndex;
  static bool _isLoading = false;
  
  /// Initialise le service Thompson étendu
  static Future<void> init() async {
    if (_thomsonIndex != null || _isLoading) return;
    _isLoading = true;
    
    try {
      // Charger l'index Thompson complet
      final String jsonString = await rootBundle.loadString('assets/data/thomson_index.json');
      _thomsonIndex = json.decode(jsonString);
      
      final pages = _thomsonIndex!['pages'] as List<dynamic>? ?? [];
      print('✅ ThomsonExtendedService initialisé avec ${pages.length} pages');
    } catch (e) {
      print('⚠️ Erreur chargement index Thompson: $e');
      _thomsonIndex = {};
    } finally {
      _isLoading = false;
    }
  }
  
  /// Récupère les chaînes de références Thompson pour un passage
  /// 
  /// [reference] : Référence biblique (ex: "1 Pierre 1:1")
  /// 
  /// Retourne : Liste des références liées selon Thompson
  static Future<List<String>> getThompsonChains(String reference) async {
    await init();
    
    if (_thomsonIndex == null) return [];
    
    print('🔍 ThomsonExtendedService.getThompsonChains pour: $reference');
    
    final chains = <String>[];
    final pages = _thomsonIndex!['pages'] as List<dynamic>? ?? [];
    
    // Rechercher dans toutes les pages
    for (final page in pages) {
      final pageData = page as Map<String, dynamic>;
      final sections = pageData['sections'] as List<dynamic>? ?? [];
      
      for (final section in sections) {
        final sectionData = section as Map<String, dynamic>;
        final content = sectionData['content'] as String? ?? '';
        final references = sectionData['references'] as List<dynamic>? ?? [];
        
        // Vérifier si la référence est mentionnée dans le contenu
        if (content.toLowerCase().contains(reference.toLowerCase())) {
          print('🔍 Chaîne Thompson trouvée dans le contenu pour: $reference');
          // Ajouter les références de cette section
          for (final ref in references) {
            if (ref is String && ref.isNotEmpty) {
              chains.add(ref);
              print('🔍 Référence ajoutée: $ref');
            }
          }
        }
      }
    }
    
    final uniqueChains = chains.toSet().toList();
    print('🔍 ThomsonExtendedService.getThompsonChains résultat: ${uniqueChains.length} chaînes');
    return uniqueChains;
  }
  
  /// Récupère les thèmes Thompson pour un passage
  /// 
  /// [reference] : Référence biblique
  /// 
  /// Retourne : Liste des thèmes Thompson
  static Future<List<String>> getThompsonThemes(String reference) async {
    await init();
    
    if (_thomsonIndex == null) return [];
    
    final themes = <String>[];
    final pages = _thomsonIndex!['pages'] as List<dynamic>? ?? [];
    
    // Mots-clés thématiques Thompson
    final thematicKeywords = [
      'salut', 'grâce', 'foi', 'amour', 'espérance', 'sainteté',
      'prière', 'adoration', 'repentance', 'rédemption', 'alliance',
      'royaume', 'église', 'ministère', 'évangélisation', 'souffrance',
      'gloire', 'résurrection', 'jugement', 'éternité'
    ];
    
    for (final page in pages) {
      final pageData = page as Map<String, dynamic>;
      final sections = pageData['sections'] as List<dynamic>? ?? [];
      
      for (final section in sections) {
        final sectionData = section as Map<String, dynamic>;
        final content = sectionData['content'] as String? ?? '';
        
        // Vérifier si la référence est mentionnée
        if (content.toLowerCase().contains(reference.toLowerCase())) {
          // Chercher des mots-clés thématiques dans le contenu
          for (final keyword in thematicKeywords) {
            if (content.toLowerCase().contains(keyword.toLowerCase())) {
              themes.add(keyword);
            }
          }
        }
      }
    }
    
    return themes.toSet().toList();
  }
  
  /// Récupère les notices archéologiques pour un passage
  /// 
  /// [reference] : Référence biblique
  /// 
  /// Retourne : Liste des notices archéologiques
  static Future<List<String>> getArchaeologicalNotices(String reference) async {
    await init();
    
    if (_thomsonIndex == null) return [];
    
    final notices = <String>[];
    final pages = _thomsonIndex!['pages'] as List<dynamic>? ?? [];
    
    // Mots-clés archéologiques
    final archaeologicalKeywords = [
      'découverte', 'fouille', 'archéologie', 'site', 'ruine',
      'inscription', 'monument', 'civilisation', 'culture', 'histoire'
    ];
    
    for (final page in pages) {
      final pageData = page as Map<String, dynamic>;
      final sections = pageData['sections'] as List<dynamic>? ?? [];
      
      for (final section in sections) {
        final sectionData = section as Map<String, dynamic>;
        final content = sectionData['content'] as String? ?? '';
        
        // Vérifier si la référence est mentionnée
        if (content.toLowerCase().contains(reference.toLowerCase())) {
          // Chercher des mots-clés archéologiques
          for (final keyword in archaeologicalKeywords) {
            if (content.toLowerCase().contains(keyword.toLowerCase())) {
              // Extraire le contexte autour du mot-clé
              final keywordIndex = content.toLowerCase().indexOf(keyword.toLowerCase());
              if (keywordIndex >= 0) {
                final start = (keywordIndex - 50).clamp(0, content.length);
                final end = (keywordIndex + 50).clamp(0, content.length);
                final context = content.substring(start, end);
                notices.add(context.trim());
              }
            }
          }
        }
      }
    }
    
    return notices.toSet().toList();
  }
  
  /// Récupère les portraits de personnages pour un passage
  /// 
  /// [reference] : Référence biblique
  /// 
  /// Retourne : Liste des portraits de personnages
  static Future<List<String>> getCharacterPortraits(String reference) async {
    await init();
    
    if (_thomsonIndex == null) return [];
    
    final portraits = <String>[];
    final pages = _thomsonIndex!['pages'] as List<dynamic>? ?? [];
    
    // Noms de personnages bibliques
    final biblicalCharacters = [
      'Jésus', 'Christ', 'Pierre', 'Paul', 'Jean', 'Matthieu', 'Marc', 'Luc',
      'Moïse', 'Abraham', 'David', 'Salomon', 'Ésaïe', 'Jérémie', 'Ézéchiel',
      'Daniel', 'Élie', 'Élisée', 'Samuel', 'Saül', 'Josué', 'Caleb'
    ];
    
    for (final page in pages) {
      final pageData = page as Map<String, dynamic>;
      final sections = pageData['sections'] as List<dynamic>? ?? [];
      
      for (final section in sections) {
        final sectionData = section as Map<String, dynamic>;
        final content = sectionData['content'] as String? ?? '';
        
        // Vérifier si la référence est mentionnée
        if (content.toLowerCase().contains(reference.toLowerCase())) {
          // Chercher des noms de personnages
          for (final character in biblicalCharacters) {
            if (content.toLowerCase().contains(character.toLowerCase())) {
              // Extraire le contexte autour du personnage
              final characterIndex = content.toLowerCase().indexOf(character.toLowerCase());
              if (characterIndex >= 0) {
                final start = (characterIndex - 100).clamp(0, content.length);
                final end = (characterIndex + 100).clamp(0, content.length);
                final context = content.substring(start, end);
                portraits.add('$character: ${context.trim()}');
              }
            }
          }
        }
      }
    }
    
    return portraits.toSet().toList();
  }
  
  /// Recherche avancée dans l'index Thompson
  /// 
  /// [query] : Terme de recherche
  /// 
  /// Retourne : Résultats de recherche avec contexte
  static Future<List<Map<String, dynamic>>> searchThompsonIndex(String query) async {
    await init();
    
    if (_thomsonIndex == null) return [];
    
    final results = <Map<String, dynamic>>[];
    final pages = _thomsonIndex!['pages'] as List<dynamic>? ?? [];
    
    for (final page in pages) {
      final pageData = page as Map<String, dynamic>;
      final pageNumber = pageData['page'] as int? ?? 0;
      final sections = pageData['sections'] as List<dynamic>? ?? [];
      
      for (final section in sections) {
        final sectionData = section as Map<String, dynamic>;
        final content = sectionData['content'] as String? ?? '';
        final heading = sectionData['heading'] as String?;
        
        if (content.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'page': pageNumber,
            'heading': heading,
            'content': content,
            'context': content.length > 200 
                ? '${content.substring(0, 200)}...' 
                : content,
          });
        }
      }
    }
    
    return results;
  }
  
  /// Récupère les données complètes Thompson pour un passage
  /// 
  /// [reference] : Référence biblique
  /// 
  /// Retourne : Toutes les données Thompson disponibles
  static Future<Map<String, dynamic>> getCompleteThompsonData(String reference) async {
    await init();
    
    final chains = await getThompsonChains(reference);
    final themes = await getThompsonThemes(reference);
    final notices = await getArchaeologicalNotices(reference);
    final portraits = await getCharacterPortraits(reference);
    
    return {
      'reference': reference,
      'chains': chains,
      'themes': themes,
      'archaeological_notices': notices,
      'character_portraits': portraits,
      'total_chains': chains.length,
      'total_themes': themes.length,
      'total_notices': notices.length,
      'total_portraits': portraits.length,
    };
  }
}
