import 'dart:convert';
import 'package:flutter/services.dart';
import 'bsb_topical_service.dart';
import 'bsb_concordance_service.dart';

/// 🧠 Service d'extraction de thèmes sémantiques depuis la lecture du jour
class SemanticThemeExtractor {
  static const List<String> _commonBiblicalThemes = [
    'amour', 'foi', 'grâce', 'espérance', 'paix', 'joie', 'sagesse',
    'vérité', 'vie', 'mort', 'résurrection', 'salut', 'pardon',
    'justice', 'miséricorde', 'compassion', 'humilité', 'servir',
    'prière', 'adoration', 'sainteté', 'pureté', 'obéissance',
    'crainte', 'crainte de Dieu', 'repentance', 'conversion',
    'alliance', 'promesse', 'bénédiction', 'malédiction',
    'tentation', 'épreuve', 'souffrance', 'consolation',
    'rédemption', 'réconciliation', 'adoption', 'héritage',
    'royaume', 'royaume de Dieu', 'église', 'communion',
    'service', 'ministère', 'don', 'don spirituel',
    'prophétie', 'révélation', 'vision', 'rêve',
    'ange', 'démon', 'satan', 'tentateur',
    'jugement', 'condamnation', 'châtiment', 'discipline',
    'liberté', 'esclavage', 'captivité', 'délivrance',
    'guérison', 'miracle', 'signe', 'prodiges',
    'parole', 'parole de Dieu', 'Écriture', 'loi',
    'commandement', 'précepte', 'statut', 'ordonnance',
    'cœur', 'âme', 'esprit', 'corps',
    'péché', 'iniquité', 'transgression', 'rébellion',
    'confession', 'aveu', 'reconnaissance', 'témoignage',
    'évangélisation', 'mission', 'témoin', 'apôtre',
    'pasteur', 'ancien', 'diacre', 'évêque',
    'baptême', 'cène', 'sacrement', 'ordonnance',
    'mariage', 'famille', 'enfant', 'parent',
    'richesse', 'pauvreté', 'générosité', 'avarice',
    'travail', 'repos', 'sabbat', 'fête',
    'temps', 'saison', 'génération', 'âge',
    'fin', 'fin des temps', 'retour', 'avènement',
    'nouvelle', 'nouvelle création', 'ciel', 'terre nouvelle'
  ];

  /// Extrait les thèmes principaux d'un passage biblique
  static Future<List<String>> extractThemesFromPassage(String passageText, String passageRef) async {
    try {
      // 1. Analyser le texte pour identifier les mots-clés thématiques
      final keywords = _extractKeywordsFromText(passageText);
      
      // 2. Matcher avec les thèmes bibliques communs
      final matchedThemes = _matchWithBiblicalThemes(keywords);
      
      // 3. Enrichir avec l'analyse BSB
      final bsbThemes = await _getBSBThemesForPassage(passageRef, keywords);
      
      // 4. Combiner et prioriser les thèmes
      final allThemes = [...matchedThemes, ...bsbThemes];
      final uniqueThemes = allThemes.toSet().toList();
      
      // 5. Trier par pertinence (fréquence dans le texte)
      final rankedThemes = _rankThemesByRelevance(uniqueThemes, passageText);
      
      return rankedThemes.take(5).toList(); // Top 5 thèmes
    } catch (e) {
      print('❌ Erreur extraction thèmes sémantiques: $e');
      return ['amour', 'foi', 'grâce']; // Fallback
    }
  }

  /// Extrait les mots-clés du texte
  static List<String> _extractKeywordsFromText(String text) {
    // Normaliser le texte
    final normalizedText = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Diviser en mots
    final words = normalizedText.split(' ');
    
    // Filtrer les mots significatifs (plus de 3 caractères, pas de mots vides)
    final stopWords = {
      'que', 'qui', 'dont', 'où', 'le', 'la', 'les', 'un', 'une', 'des',
      'du', 'de', 'et', 'ou', 'mais', 'donc', 'car', 'ni', 'or',
      'ce', 'cette', 'ces', 'son', 'sa', 'ses', 'mon', 'ma', 'mes',
      'ton', 'ta', 'tes', 'notre', 'nos', 'votre', 'vos', 'leur', 'leurs',
      'il', 'elle', 'ils', 'elles', 'nous', 'vous', 'je', 'tu', 'on',
      'est', 'sont', 'était', 'étaient', 'sera', 'seront', 'être', 'avoir',
      'faire', 'dire', 'aller', 'venir', 'voir', 'savoir', 'pouvoir',
      'vouloir', 'devoir', 'falloir', 'paraître', 'sembler', 'rester',
      'devenir', 'rendre', 'mettre', 'prendre', 'donner', 'tenir',
      'laisser', 'passer', 'sortir', 'entrer', 'monter', 'descendre',
      'ouvrir', 'fermer', 'commencer', 'finir', 'continuer', 'arrêter'
    };
    
    return words
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toList();
  }

  /// Match les mots-clés avec les thèmes bibliques
  static List<String> _matchWithBiblicalThemes(List<String> keywords) {
    final matchedThemes = <String>[];
    
    for (final keyword in keywords) {
      for (final theme in _commonBiblicalThemes) {
        if (theme.contains(keyword) || keyword.contains(theme)) {
          matchedThemes.add(theme);
        }
      }
    }
    
    return matchedThemes;
  }

  /// Obtient les thèmes BSB pour un passage
  static Future<List<String>> _getBSBThemesForPassage(String passageRef, List<String> keywords) async {
    try {
      await BSBTopicalService.init();
      
      // Extraire le livre du passage
      final book = _extractBookFromReference(passageRef);
      if (book.isEmpty) return [];
      
      // Rechercher des thèmes liés au livre
      final bookThemes = await BSBTopicalService.searchTheme(book);
      
      // Rechercher des thèmes liés aux mots-clés
      final keywordThemes = <String>[];
      for (final keyword in keywords.take(3)) {
        final themes = await BSBTopicalService.searchTheme(keyword);
        keywordThemes.addAll(themes);
      }
      
      return [...bookThemes, ...keywordThemes];
    } catch (e) {
      print('❌ Erreur récupération thèmes BSB: $e');
      return [];
    }
  }

  /// Extrait le nom du livre d'une référence biblique
  static String _extractBookFromReference(String reference) {
    final parts = reference.split(' ');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return '';
  }

  /// Classe les thèmes par pertinence
  static List<String> _rankThemesByRelevance(List<String> themes, String passageText) {
    final themeScores = <String, int>{};
    
    for (final theme in themes) {
      int score = 0;
      final themeWords = theme.split(' ');
      
      for (final word in themeWords) {
        // Compter les occurrences du mot dans le texte
        final regex = RegExp(word.toLowerCase());
        final matches = regex.allMatches(passageText.toLowerCase());
        score += matches.length;
      }
      
      themeScores[theme] = score;
    }
    
    // Trier par score décroissant
    final sortedThemes = themeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedThemes.map((e) => e.key).toList();
  }

  /// Obtient un thème principal pour la carte d'étude
  static Future<String> getMainThemeForStudy(String passageText, String passageRef) async {
    final themes = await extractThemesFromPassage(passageText, passageRef);
    return themes.isNotEmpty ? themes.first : 'amour';
  }
}
