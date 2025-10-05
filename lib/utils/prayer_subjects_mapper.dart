import 'dart:math';
import 'package:flutter/material.dart';

/// Sortie attendue par PayerpageWidget :
/// [{ 'theme': 'Repentance', 'subject': 'Demander un cœur pur' }, ...]
typedef PrayerSubject = Map<String, String>;

class PrayerItem {
  final String theme;
  final String subject;
  final Color color;
  bool validated;
  String notes; // Notes de ce que l'utilisateur reçoit de Dieu
  PrayerItem({
    required this.theme,
    required this.subject,
    required this.color,
    this.validated = false,
    this.notes = '',
  });

  factory PrayerItem.fromMap(Map m) {
    Color parseHex(String hex) {
      final h = (hex as String).replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    }
    return PrayerItem(
      theme: m['theme'] ?? '',
      subject: m['subject'] ?? '',
      color: m['color'] != null ? parseHex(m['color']) : const Color(0xFF6366F1),
    );
  }
}

/// Helper pour créer des sujets de prière basés sur les réponses de méditation
List<PrayerItem> buildPrayerItemsFromMeditation({
  required Map<String, Set<String>> selectedTagsByField,
  required Map<String, Set<String>> selectedAnswersByField, // Les réponses cochées
  required Map<String, String> freeTextResponses, // Les réponses écrites
  String? passageText,
  String? passageRef,
}) {
  final items = <PrayerItem>[];
  
  // Analyser les réponses pour créer des sujets personnalisés
  final responses = _analyzeMeditationResponses(
    selectedTagsByField, 
    selectedAnswersByField,
    freeTextResponses,
    passageText,
    passageRef
  );
  
  // Créer des sujets de prière basés sur l'analyse
  for (final response in responses) {
    items.add(PrayerItem(
      theme: response['theme']!,
      subject: response['subject']!,
      color: response['color']!,
    ));
  }
  
  // Si pas assez de sujets, ajouter des sujets par défaut
  if (items.length < 3) {
    items.addAll(_getDefaultPrayerItems(passageRef));
  }
  
  return items.take(5).toList(); // Maximum 5 sujets
}

/// Analyse les réponses de méditation pour créer des sujets personnalisés
List<Map<String, dynamic>> _analyzeMeditationResponses(
  Map<String, Set<String>> selectedTagsByField,
  Map<String, Set<String>> selectedAnswersByField,
  Map<String, String> freeTextResponses,
  String? passageText,
  String? passageRef,
) {
  final responses = <Map<String, dynamic>>[];
  
  // Analyser chaque champ de réponse avec le contexte complet
  selectedTagsByField.forEach((field, tags) {
    if (tags.isNotEmpty) {
      final selectedAnswers = selectedAnswersByField[field] ?? <String>{};
      final freeText = freeTextResponses[field] ?? '';
      
      final analysis = _analyzeFieldWithContext(
        field, 
        tags, 
        selectedAnswers, 
        freeText, 
        passageText, 
        passageRef
      );
      if (analysis != null) {
        responses.add(analysis);
      }
    }
  });
  
  return responses;
}

/// Analyse un champ avec le contexte complet (tags, réponses, texte libre, passage)
Map<String, dynamic>? _analyzeFieldWithContext(
  String field,
  Set<String> tags,
  Set<String> selectedAnswers,
  String freeText,
  String? passageText,
  String? passageRef,
) {
  // Créer un sujet de prière basé sur le contexte complet
  final context = _buildContextualSubject(field, tags, selectedAnswers, freeText, passageText, passageRef);
  return context;
}

/// Construit un sujet de prière contextuel basé sur tous les éléments
Map<String, dynamic>? _buildContextualSubject(
  String field,
  Set<String> tags,
  Set<String> selectedAnswers,
  String freeText,
  String? passageText,
  String? passageRef,
) {
  // Déterminer le thème principal basé sur les tags
  String theme = 'Prière';
  Color color = const Color(0xFF6366F1);
  
  if (tags.contains('praise') || tags.contains('gratitude')) {
    theme = 'Louange';
    color = const Color(0xFFFF6B6B);
  } else if (tags.contains('repentance') || tags.contains('warning')) {
    theme = 'Repentance';
    color = const Color(0xFF8E44AD);
  } else if (tags.contains('trust') || tags.contains('promise')) {
    theme = 'Foi';
    color = const Color(0xFF54A0FF);
  } else if (tags.contains('obedience') || tags.contains('responsibility')) {
    theme = 'Obéissance';
    color = const Color(0xFFF39C12);
  } else if (tags.contains('intercession')) {
    theme = 'Intercession';
    color = const Color(0xFF96CEB4);
  } else if (tags.contains('guidance')) {
    theme = 'Sagesse';
    color = const Color(0xFF9B59B6);
  }
  
  // Construire le sujet basé sur le contexte
  String subject = _buildSubjectFromContext(field, selectedAnswers, freeText, passageText, passageRef);
  
  return {
    'theme': theme,
    'subject': subject,
    'color': color,
  };
}

/// Construit le sujet de prière à partir du contexte
String _buildSubjectFromContext(
  String field,
  Set<String> selectedAnswers,
  String freeText,
  String? passageText,
  String? passageRef,
) {
  // Utiliser les réponses sélectionnées et le texte libre pour créer un sujet personnalisé
  final answers = selectedAnswers.join(', ');
  final context = freeText.isNotEmpty ? freeText : answers;
  
  // Vérifier que les réponses sélectionnées sont bien prises en compte
  print('🔍 ANALYSE CONTEXTE pour $field:');
  print('🔍 Réponses cochées: $selectedAnswers');
  print('🔍 Texte libre: "$freeText"');
  print('🔍 Contexte final: "$context"');
  
  // Créer une synthèse intelligente basée sur le champ, les réponses et le passage
  final subject = _createIntelligentPrayerSubject(field, context, passageText, passageRef);
  
  print('🔍 Sujet généré: "$subject"');
  return subject;
}

/// Crée un sujet de prière intelligent et personnalisé
String _createIntelligentPrayerSubject(
  String field,
  String context,
  String? passageText,
  String? passageRef,
) {
  // Analyser le contexte pour extraire des éléments clés
  final contextLower = context.toLowerCase();
  final passageLower = passageText?.toLowerCase() ?? '';
  
  // Analyser le passage pour comprendre son contexte thématique
  final passageAnalysis = _analyzePassageContext(passageText, passageRef);
  
  switch (field) {
    case 'de_quoi_qui':
      return _createSubjectAboutPassageContent(context, passageLower, passageAnalysis);
    
    case 'apprend_dieu':
      return _createSubjectAboutGodRevelation(context, passageLower, passageAnalysis);
    
    case 'exemple':
      return _createSubjectAboutExample(context, passageLower, passageAnalysis);
    
    case 'ordre':
      return _createSubjectAboutCommand(context, passageLower, passageAnalysis);
    
    case 'promesse':
      return _createSubjectAboutPromise(context, passageLower, passageAnalysis);
    
    case 'avertissement':
      return _createSubjectAboutWarning(context, passageLower, passageAnalysis);
    
    case 'commande':
      return _createSubjectAboutCommand(context, passageLower, passageAnalysis);
    
    case 'personnage_principal':
      return _createSubjectAboutMainCharacter(context, passageLower, passageAnalysis);
    
    case 'emotion':
      return _createSubjectAboutEmotion(context, passageLower, passageAnalysis);
    
    case 'application':
      return _createSubjectAboutApplication(context, passageLower, passageAnalysis);
    
    default:
      return 'Seigneur, aide-moi à comprendre et appliquer ce passage dans ma vie';
  }
}

/// Analyse le contexte du passage pour comprendre ses thèmes principaux
Map<String, dynamic> _analyzePassageContext(String? passageText, String? passageRef) {
  final passage = passageText?.toLowerCase() ?? '';
  final analysis = <String, dynamic>{};
  
  // Analyser les thèmes principaux du passage
  if (passage.contains('je suis le chemin') || passage.contains('chemin, la vérité')) {
    analysis['main_theme'] = 'jesus_way';
    analysis['key_concept'] = 'Jésus comme chemin vers le Père';
  }
  
  if (passage.contains('demeures') || passage.contains('maison de mon père')) {
    analysis['main_theme'] = 'heavenly_home';
    analysis['key_concept'] = 'Promesse du ciel et des demeures célestes';
  }
  
  if (passage.contains('consolateur') || passage.contains('esprit de vérité')) {
    analysis['main_theme'] = 'holy_spirit';
    analysis['key_concept'] = 'Promesse du Saint-Esprit';
  }
  
  if (passage.contains('croyez en dieu') || passage.contains('croyez en moi')) {
    analysis['main_theme'] = 'faith_trust';
    analysis['key_concept'] = 'Appel à la foi et à la confiance';
  }
  
  if (passage.contains('œuvres') || passage.contains('faire les œuvres')) {
    analysis['main_theme'] = 'works_service';
    analysis['key_concept'] = 'Appel à faire les œuvres de Dieu';
  }
  
  if (passage.contains('demanderez en mon nom')) {
    analysis['main_theme'] = 'prayer_power';
    analysis['key_concept'] = 'Puissance de la prière au nom de Jésus';
  }
  
  if (passage.contains('gardez mes commandements')) {
    analysis['main_theme'] = 'obedience';
    analysis['key_concept'] = 'Appel à l\'obéissance et à l\'amour';
  }
  
  // Analyser les personnages mentionnés
  if (passage.contains('thomas') || passage.contains('philippe')) {
    analysis['characters'] = ['Thomas', 'Philippe'];
  }
  
  // Analyser les émotions et sentiments
  if (passage.contains('cœur ne se trouble')) {
    analysis['emotion'] = 'peace_comfort';
  }
  
  if (passage.contains('orphelins')) {
    analysis['emotion'] = 'abandonment_fear';
  }
  
  return analysis;
}

/// Crée un sujet de prière sur le contenu du passage
String _createSubjectAboutPassageContent(String context, String passage, Map<String, dynamic> passageAnalysis) {
  final mainTheme = passageAnalysis['main_theme'] as String?;
  final keyConcept = passageAnalysis['key_concept'] as String?;
  
  // Vérifier que les réponses sélectionnées sont bien prises en compte
  final contextLower = context.toLowerCase();
  
  // Combiner l'analyse du passage avec les réponses spécifiques
  if (contextLower.contains('jésus') || contextLower.contains('christ')) {
    if (mainTheme == 'jesus_way') {
      return 'Seigneur Jésus, comme il est écrit "Je suis le chemin, la vérité, et la vie", aide-moi à te suivre fidèlement.';
    }
    return 'Seigneur Jésus, merci de te révéler dans ce passage. Aide-moi à mieux te connaître et à te suivre fidèlement.';
  }
  
  if (contextLower.contains('royaume') || contextLower.contains('ciel') || mainTheme == 'heavenly_home') {
    return 'Père céleste, comme il est écrit "Il y a plusieurs demeures dans la maison de mon Père", aide-moi à vivre en citoyen du ciel.';
  }
  
  if (contextLower.contains('esprit') || contextLower.contains('consolateur') || mainTheme == 'holy_spirit') {
    return 'Esprit Saint, comme il est écrit "Je prierai le Père, et il vous donnera un autre consolateur", aide-moi à être sensible à ta voix.';
  }
  
  if (mainTheme == 'faith_trust') {
    return 'Seigneur, comme il est écrit "Croyez en Dieu, et croyez en moi", renforce ma foi dans les moments difficiles.';
  }
  
  return 'Seigneur, aide-moi à comprendre ce que tu veux me dire à travers ce passage.';
}

/// Crée un sujet de prière sur la révélation de Dieu
String _createSubjectAboutGodRevelation(String context, String passage, Map<String, dynamic> passageAnalysis) {
  final mainTheme = passageAnalysis['main_theme'] as String?;
  
  // Basé sur l'analyse du passage Jean 14
  if (mainTheme == 'jesus_way') {
    return 'Père, merci de révéler Jésus comme le chemin vers toi. Aide-moi à comprendre que nul ne vient à toi que par lui.';
  }
  
  if (mainTheme == 'holy_spirit') {
    return 'Père, merci de promettre l\'Esprit de vérité. Aide-moi à recevoir ce consolateur et à être sensible à sa voix.';
  }
  
  if (context.contains('saint') || context.contains('pur')) {
    return 'Dieu saint, aide-moi à vivre dans la sainteté comme tu es saint. Purifie mon cœur et mes pensées.';
  }
  
  if (context.contains('puissant') || context.contains('majesté')) {
    return 'Dieu tout-puissant, je reconnais ta majesté. Aide-moi à t\'adorer avec crainte et respect.';
  }
  
  return 'Père, révèle-toi davantage à moi à travers ce passage. Aide-moi à mieux te connaître et à t\'aimer.';
}

/// Crée un sujet de prière sur l'exemple à suivre
String _createSubjectAboutExample(String context, String passage, Map<String, dynamic> passageAnalysis) {
  if (context.contains('foi') || context.contains('croire')) {
    return 'Seigneur, aide-moi à avoir une foi ferme comme l\'exemple de ce passage. Renforce ma confiance en toi.';
  }
  if (context.contains('amour') || context.contains('aimer')) {
    return 'Jésus, aide-moi à aimer comme tu aimes. Donne-moi un cœur rempli d\'amour pour Dieu et pour mon prochain.';
  }
  if (context.contains('obéissance') || context.contains('obéir')) {
    return 'Seigneur, aide-moi à obéir à tes commandements avec joie, comme l\'exemple de ce passage.';
  }
  if (context.contains('repentance') || context.contains('repentir')) {
    return 'Père, aide-moi à me repentir sincèrement de mes péchés et à revenir à toi.';
  }
  return 'Seigneur, aide-moi à suivre les bons exemples de ce passage et à éviter les mauvais.';
}

/// Crée un sujet de prière sur les commandements/ordres
String _createSubjectAboutCommand(String context, String passage, Map<String, dynamic> passageAnalysis) {
  final mainTheme = passageAnalysis['main_theme'] as String?;
  final contextLower = context.toLowerCase();
  
  // Basé sur l'analyse du passage Jean 14 avec références scripturaires
  if (mainTheme == 'obedience' || contextLower.contains('garder') || contextLower.contains('commandements')) {
    return 'Jésus, comme il est écrit "Si vous m\'aimez, gardez mes commandements", aide-moi à t\'aimer par l\'obéissance.';
  }
  
  if (mainTheme == 'works_service' || contextLower.contains('œuvres')) {
    return 'Seigneur, comme il est écrit "Celui qui croit en moi fera aussi les œuvres que je fais", aide-moi à te servir fidèlement.';
  }
  
  if (contextLower.contains('croyez en dieu') || contextLower.contains('croyez en moi')) {
    return 'Seigneur, comme il est écrit "Croyez en Dieu, et croyez en moi", renforce ma foi en toi.';
  }
  
  if (contextLower.contains('cœur ne se trouble')) {
    return 'Jésus, comme il est écrit "Que votre cœur ne se trouble point", donne-moi ta paix.';
  }
  
  if (contextLower.contains('prier') || contextLower.contains('méditer')) {
    return 'Père, aide-moi à prier et méditer ta Parole régulièrement. Approfondis ma relation avec toi.';
  }
  
  return 'Seigneur, aide-moi à obéir à tes commandements avec joie et persévérance.';
}

/// Crée un sujet de prière sur les promesses
String _createSubjectAboutPromise(String context, String passage, Map<String, dynamic> passageAnalysis) {
  final mainTheme = passageAnalysis['main_theme'] as String?;
  final contextLower = context.toLowerCase();
  
  // Basé sur l'analyse du passage Jean 14 avec références scripturaires
  if (mainTheme == 'heavenly_home' || contextLower.contains('demeures') || contextLower.contains('maison')) {
    return 'Jésus, comme il est écrit "Je vais vous préparer une place", aide-moi à vivre dans l\'espérance de ton retour.';
  }
  
  if (mainTheme == 'holy_spirit' || contextLower.contains('consolateur') || contextLower.contains('esprit de vérité')) {
    return 'Père, comme il est écrit "Je prierai le Père, et il vous donnera un autre consolateur", aide-moi à recevoir l\'Esprit de vérité.';
  }
  
  if (contextLower.contains('orphelins') || contextLower.contains('viendrai à vous')) {
    return 'Jésus, comme il est écrit "Je ne vous laisserai pas orphelins, je viendrai à vous", aide-moi à sentir ta présence constante.';
  }
  
  if (contextLower.contains('demanderez en mon nom') || mainTheme == 'prayer_power') {
    return 'Jésus, comme il est écrit "Tout ce que vous demanderez en mon nom, je le ferai", aide-moi à prier selon ta volonté.';
  }
  
  if (contextLower.contains('œuvres') && contextLower.contains('plus grandes')) {
    return 'Seigneur, comme il est écrit "Celui qui croit en moi fera aussi les œuvres que je fais, et il en fera de plus grandes", aide-moi à te servir.';
  }
  
  return 'Père, aide-moi à recevoir tes promesses avec foi et à les vivre pleinement.';
}

/// Crée un sujet de prière sur les avertissements
String _createSubjectAboutWarning(String context, String passage, Map<String, dynamic> passageAnalysis) {
  if (context.contains('péché') || context.contains('faute')) {
    return 'Seigneur, aide-moi à fuir le péché et à vivre dans la justice. Donne-moi la force de résister à la tentation.';
  }
  if (context.contains('orgueil') || context.contains('fier')) {
    return 'Père, garde-moi de l\'orgueil. Aide-moi à rester humble et dépendant de toi.';
  }
  if (context.contains('idolâtrie') || context.contains('idole')) {
    return 'Seigneur, aide-moi à ne rien mettre avant toi. Tu es le seul digne de mon adoration.';
  }
  if (context.contains('jugement') || context.contains('condamnation')) {
    return 'Dieu, aide-moi à me repentir avant qu\'il ne soit trop tard. Donne-moi un cœur sensible à tes avertissements.';
  }
  return 'Père, aide-moi à prendre au sérieux tes avertissements et à changer ce qui doit l\'être.';
}

/// Crée un sujet de prière sur le personnage principal
String _createSubjectAboutMainCharacter(String context, String passage, Map<String, dynamic> passageAnalysis) {
  if (context.contains('jésus') || context.contains('christ')) {
    return 'Seigneur Jésus, merci d\'être le centre de ce passage. Aide-moi à te suivre de plus en plus fidèlement.';
  }
  if (context.contains('éternel') || context.contains('dieu')) {
    return 'Père éternel, merci de te révéler dans ce passage. Aide-moi à mieux te connaître et t\'adorer.';
  }
  if (context.contains('esprit') || context.contains('saint-esprit')) {
    return 'Esprit Saint, aide-moi à être sensible à ta voix et à te laisser me transformer.';
  }
  return 'Seigneur, aide-moi à comprendre le rôle du personnage principal et à l\'imiter dans ma vie.';
}

/// Crée un sujet de prière sur les émotions
String _createSubjectAboutEmotion(String context, String passage, Map<String, dynamic> passageAnalysis) {
  if (context.contains('joie') || context.contains('allégresse')) {
    return 'Seigneur, aide-moi à vivre dans la joie de ton salut. Donne-moi un cœur reconnaissant et joyeux.';
  }
  if (context.contains('paix') || context.contains('sérénité')) {
    return 'Jésus, donne-moi ta paix qui surpasse toute intelligence. Aide-moi à rester calme dans les épreuves.';
  }
  if (context.contains('crainte') || context.contains('respect')) {
    return 'Père, aide-moi à t\'adorer avec crainte et respect. Donne-moi un cœur qui te révère.';
  }
  if (context.contains('amour') || context.contains('tendresse')) {
    return 'Dieu d\'amour, aide-moi à aimer comme tu aimes. Donne-moi un cœur rempli de tendresse.';
  }
  return 'Seigneur, aide-moi à cultiver les bonnes émotions et à les exprimer de manière saine.';
}

/// Crée un sujet de prière sur l'application pratique
String _createSubjectAboutApplication(String context, String passage, Map<String, dynamic> passageAnalysis) {
  if (context.contains('aujourd\'hui') || context.contains('maintenant')) {
    return 'Seigneur, aide-moi à appliquer ce passage dès aujourd\'hui. Donne-moi la force de changer.';
  }
  if (context.contains('quotidien') || context.contains('vie')) {
    return 'Père, aide-moi à vivre ce passage dans ma vie quotidienne. Transforme mes habitudes.';
  }
  if (context.contains('famille') || context.contains('proche')) {
    return 'Seigneur, aide-moi à partager ces vérités avec ma famille et mes proches.';
  }
  if (context.contains('travail') || context.contains('service')) {
    return 'Dieu, aide-moi à honorer ce passage dans mon travail et mon service.';
  }
  return 'Seigneur, aide-moi à mettre en pratique ce passage concrètement dans ma vie.';
}

/// Analyse un champ spécifique de méditation
Map<String, dynamic>? _analyzeField(String field, Set<String> tags, String? passageText) {
  switch (field) {
    // Champs de la méditation QCM
    case 'de_quoi_qui':
      return _analyzeDeQuoiQui(tags, passageText);
    case 'apprend_dieu':
      return _analyzeApprendDieu(tags, passageText);
    case 'exemple':
      return _analyzeExemple(tags, passageText);
    case 'ordre':
      return _analyzeOrdre(tags, passageText);
    case 'promesse':
      return _analyzePromesse(tags, passageText);
    case 'avertissement':
      return _analyzeAvertissement(tags, passageText);
    case 'commande':
      return _analyzeCommande(tags, passageText);
    case 'personnage_principal':
      return _analyzePersonnagePrincipal(tags, passageText);
    case 'emotion':
      return _analyzeEmotion(tags, passageText);
    case 'application':
      return _analyzeApplication(tags, passageText);
    
    // Champs de la méditation libre
    case 'aboutGod':
      return _analyzeAboutGod(tags, passageText);
    case 'neighbor':
      return _analyzeNeighbor(tags, passageText);
    case 'applyToday':
      return _analyzeApplyToday(tags, passageText);
    case 'verseHit':
      return _analyzeVerseHit(tags, passageText);
    default:
      return _analyzeGenericField(field, tags, passageText);
  }
}

/// Analyse les réponses sur Dieu
Map<String, dynamic>? _analyzeAboutGod(Set<String> tags, String? passageText) {
  if (tags.contains('praise') || tags.contains('gratitude')) {
    return {
      'theme': 'Louange',
      'subject': _generatePersonalPraiseSubject(tags, passageText),
      'color': const Color(0xFFFF6B6B),
    };
  }
  if (tags.contains('trust') || tags.contains('faith')) {
    return {
      'theme': 'Foi',
      'subject': _generateTrustSubject(tags, passageText),
      'color': const Color(0xFF54A0FF),
    };
  }
  return null;
}

/// Analyse les réponses sur le prochain
Map<String, dynamic>? _analyzeNeighbor(Set<String> tags, String? passageText) {
  if (tags.contains('intercession') || tags.contains('love')) {
    return {
      'theme': 'Intercession',
      'subject': _generateIntercessionSubject(tags, passageText),
      'color': const Color(0xFF96CEB4),
    };
  }
  return null;
}

/// Analyse les réponses sur l'application
Map<String, dynamic>? _analyzeApplyToday(Set<String> tags, String? passageText) {
  if (tags.contains('obedience') || tags.contains('action')) {
    return {
      'theme': 'Obéissance',
      'subject': _generateObedienceSubject(tags, passageText),
      'color': const Color(0xFFFECA57),
    };
  }
  if (tags.contains('repentance') || tags.contains('change')) {
    return {
      'theme': 'Repentance',
      'subject': _generateRepentanceSubject(tags, passageText),
      'color': const Color(0xFF45B7D1),
    };
  }
  return null;
}

/// Analyse les versets qui ont touché
Map<String, dynamic>? _analyzeVerseHit(Set<String> tags, String? passageText) {
  if (tags.contains('promise') || tags.contains('hope')) {
    return {
      'theme': 'Promesse',
      'subject': _generatePromiseSubject(tags, passageText),
      'color': const Color(0xFF9B59B6),
    };
  }
  return null;
}

/// Analyse générique pour d'autres champs
Map<String, dynamic>? _analyzeGenericField(String field, Set<String> tags, String? passageText) {
  // Logique générique basée sur les tags
  if (tags.contains('praise')) {
    return {
      'theme': 'Louange',
      'subject': 'Adorer Dieu pour ce qu\'il m\'a révélé dans ma méditation',
      'color': const Color(0xFFFF6B6B),
    };
  }
  if (tags.contains('gratitude')) {
    return {
      'theme': 'Action de grâce',
      'subject': 'Remercier Dieu pour ses bienfaits dans ma vie',
      'color': const Color(0xFF54A0FF),
    };
  }
  return null;
}

/// Génère un sujet de louange personnalisé
String _generatePersonalPraiseSubject(Set<String> tags, String? passageText) {
  if (tags.contains('praise') && tags.contains('gratitude')) {
    return 'Adorer Dieu pour sa bonté et sa fidélité révélées dans ce passage';
  } else if (tags.contains('praise')) {
    return 'Exalter Dieu pour sa grandeur manifestée dans ma méditation';
  } else {
    return 'Remercier Dieu pour ses bienfaits dans ma vie';
  }
}

/// Génère un sujet de foi personnalisé
String _generateTrustSubject(Set<String> tags, String? passageText) {
  if (tags.contains('trust') && tags.contains('faith')) {
    return 'Renforcer ma confiance en Dieu face aux défis actuels';
  } else {
    return 'Demander une foi plus ferme en Dieu';
  }
}

/// Génère un sujet d'intercession personnalisé
String _generateIntercessionSubject(Set<String> tags, String? passageText) {
  if (tags.contains('intercession') && tags.contains('love')) {
    return 'Prier pour mes proches qui ont besoin de connaître Dieu';
  } else {
    return 'Intercéder pour ceux qui souffrent autour de moi';
  }
}

/// Génère un sujet d'obéissance personnalisé
String _generateObedienceSubject(Set<String> tags, String? passageText) {
  if (tags.contains('obedience') && tags.contains('action')) {
    return 'Mettre en pratique concrètement ce que j\'ai appris';
  } else {
    return 'Demander la force d\'obéir à Dieu dans ma vie quotidienne';
  }
}

/// Génère un sujet de repentance personnalisé
String _generateRepentanceSubject(Set<String> tags, String? passageText) {
  if (tags.contains('repentance') && tags.contains('change')) {
    return 'Demander pardon et la force de changer mes mauvaises habitudes';
  } else {
    return 'Reconnaître mes fautes et demander le pardon de Dieu';
  }
}

/// Génère un sujet de promesse personnalisé
String _generatePromiseSubject(Set<String> tags, String? passageText) {
  if (tags.contains('promise') && tags.contains('hope')) {
    return 'S\'appuyer sur les promesses de Dieu pour l\'avenir';
  } else {
    return 'Croire aux promesses de Dieu pour ma vie';
  }
}

/// Sujets de prière par défaut si pas assez de réponses
List<PrayerItem> _getDefaultPrayerItems(String? passageRef) {
  return [
    PrayerItem(
      theme: 'Louange',
      subject: 'Adorer Dieu pour sa Parole révélée',
      color: const Color(0xFFFF6B6B),
    ),
    PrayerItem(
      theme: 'Sagesse',
      subject: 'Demander la compréhension de ce passage',
      color: const Color(0xFF54A0FF),
    ),
    PrayerItem(
      theme: 'Obéissance',
      subject: 'Mettre en pratique ce que j\'ai appris',
      color: const Color(0xFF96CEB4),
    ),
  ];
}

/// Helper pour mapper les tags vers des items de prière avec couleurs (ancienne méthode)
List<PrayerItem> buildPrayerItemsFromTags(Set<String> tags) {
  final items = <PrayerItem>[];
  
  // Mapping des tags vers des thèmes et sujets spécifiques
  final tagMapping = {
    // Tags de louange et gratitude
    'praise': {'theme': 'Louange', 'subject': 'Adorer Dieu pour sa grandeur révélée dans ce passage'},
    'gratitude': {'theme': 'Action de grâce', 'subject': 'Remercier Dieu pour ses bienfaits mentionnés'},
    
    // Tags de repentance et obéissance
    'repentance': {'theme': 'Repentance', 'subject': 'Demander pardon pour mes manquements'},
    'obedience': {'theme': 'Obéissance', 'subject': 'Mettre en pratique les enseignements de ce passage'},
    'responsibility': {'theme': 'Responsabilité', 'subject': 'Prendre mes responsabilités au sérieux'},
    
    // Tags d'intercession et de foi
    'intercession': {'theme': 'Intercession', 'subject': 'Prier pour ceux qui ont besoin d\'entendre ce message'},
    'trust': {'theme': 'Foi', 'subject': 'Renforcer ma confiance en Dieu face aux défis'},
    
    // Tags de guidance et promesses
    'guidance': {'theme': 'Sagesse', 'subject': 'Demander la direction divine pour ma vie'},
    'promise': {'theme': 'Promesse', 'subject': 'S\'appuyer sur les promesses de Dieu révélées ici'},
    'hope': {'theme': 'Espérance', 'subject': 'Cultiver l\'espérance face aux difficultés'},
    
    // Tags d'avertissement et de vigilance
    'warning': {'theme': 'Vigilance', 'subject': 'Rester vigilant face aux avertissements donnés'},
    'awe': {'theme': 'Crainte', 'subject': 'Reverence devant la sainteté de Dieu'},
  };
  
  // Couleurs pour chaque thème
  final themeColors = {
    'Louange': const Color(0xFFFF6B6B),
    'Action de grâce': const Color(0xFF4ECDC4),
    'Repentance': const Color(0xFF45B7D1),
    'Obéissance': const Color(0xFF96CEB4),
    'Responsabilité': const Color(0xFF6C5CE7),
    'Intercession': const Color(0xFFFECA57),
    'Foi': const Color(0xFFFF9FF3),
    'Sagesse': const Color(0xFF54A0FF),
    'Promesse': const Color(0xFF5F27CD),
    'Espérance': const Color(0xFF00B894),
    'Vigilance': const Color(0xFFFF6348),
    'Crainte': const Color(0xFF2D3436),
  };
  
  // Convertir les tags en items
  for (final tag in tags) {
    if (tagMapping.containsKey(tag)) {
      final mapping = tagMapping[tag]!;
      final theme = mapping['theme'] as String;
      final color = themeColors[theme] ?? const Color(0xFF6366F1);
      
      items.add(PrayerItem(
        theme: theme,
        subject: mapping['subject'] as String,
        color: color,
      ));
    }
  }
  
  // Si aucun tag valide, ajouter des items par défaut basés sur la méditation
  if (items.isEmpty) {
    items.addAll([
      PrayerItem(
        theme: 'Louange',
        subject: 'Adorer Dieu pour sa Parole révélée',
        color: const Color(0xFFFF6B6B),
      ),
      PrayerItem(
        theme: 'Sagesse',
        subject: 'Demander la compréhension de ce passage',
        color: const Color(0xFF54A0FF),
      ),
      PrayerItem(
        theme: 'Obéissance',
        subject: 'Mettre en pratique ce que j\'ai appris',
        color: const Color(0xFF96CEB4),
      ),
    ]);
  }
  
  return items;
}

List<PrayerSubject> buildPrayerSubjectsFromMeditation({
  String mode = 'free', // 'free' | 'qcm'
  Map<String, List<String>>? qcmAnswers,     // MeditationQcmPage
  Map<String, String>? freeAnswers,          // MeditationFreePage
}) {
  final subjects = <PrayerSubject>[];

  if (mode == 'qcm' && qcmAnswers != null) {
    subjects.addAll(_fromQcm(qcmAnswers));
  } else if (mode == 'free' && freeAnswers != null) {
    subjects.addAll(_fromFree(freeAnswers));
  }

  // Nettoyage: dédupliquer, couper les sujets trop longs
  String clamp(String s) => s.length <= 120 ? s : '${s.substring(0, 117)}…';

  final seen = <String>{};
  final out = <PrayerSubject>[];
  for (final item in subjects) {
    final key = '${item['theme']}|${item['subject']}';
    if (seen.add(key)) {
      out.add({'theme': item['theme']!, 'subject': clamp(item['subject']!)});
    }
  }

  // On limite à 8–10 cartes pour rester lisible
  return out.take(10).toList();
}

/// Règles simples basées sur les libellés des options cochées (pas d'IA).
List<PrayerSubject> _fromQcm(Map<String, List<String>> answers) {
  final out = <PrayerSubject>[];

  // Helpers
  void add(String theme, String subject) =>
      out.add({'theme': theme, 'subject': subject});

  bool anyContains(List<String>? list, List<String> needles) {
    if (list == null) return false;
    final joined = list.join(' ').toLowerCase();
    return needles.any((n) => joined.contains(n.toLowerCase()));
  }

  // topic / aboutGod / commands / promise / warning / apply...
  final topic      = answers['topic'];
  final aboutGod   = answers['aboutGod'];
  final commands   = answers['commands'];
  final promise    = answers['promise'];
  final warning    = answers['warning'];
  final apply      = answers['apply'];

  // 1) Action de grâce / Louange si Dieu, amour, fidélité, caractère
  if (anyContains(aboutGod, ['amour', 'fidélité', 'grâce', 'miséricorde', 'bienveillance', 'caractère']) ||
      anyContains(topic, ['Dieu'])) {
    add('Action de grâce', "Remercier Dieu pour son caractère et sa bonté révélés aujourd'hui");
    add('Louange', "Adorer Dieu pour ce qu'il est, tel qu'aperçu dans le passage");
  }

  // 2) Obéissance si un ordre a été coché
  if (anyContains(commands, ['Oui'])) {
    add('Obéissance', "Mettre en pratique concrètement l'appel du texte aujourd'hui");
  }

  // 3) Promesse / Foi si promesse cochée
  if (anyContains(promise, ['Oui'])) {
    add('Foi', "M'approprier la promesse lue et m'y appuyer dans la semaine");
    add('Promesse', "Rappeler cette promesse dans la prière et la proclamer avec foi");
  }

  // 4) Repentance si avertissement / exemple à éviter / justice/sainteté
  if (anyContains(warning, ['Oui']) ||
      anyContains(topic, ['éviter']) ||
      anyContains(aboutGod, ['justice', 'sainteté'])) {
    add('Repentance', "Reconnaître et abandonner une attitude/une habitude signalée par le texte");
  }

  // 5) Intercession si "prochain", "église", "ville", etc. apparaissent
  if (anyContains(topic, ['prochain']) ||
      anyContains(apply, ['intercéder']) ||
      anyContains(aboutGod, ['direction']) // souvent lié à prier pour d'autres
     ) {
    add('Intercession', "Prier pour une personne précise concernée par ce que j'ai lu");
  }

  // 6) Sagesse / Guidance si "direction / sagesse / décision"
  if (anyContains(aboutGod, ['sagesse', 'direction']) ||
      anyContains(apply, ['sagesse'])) {
    add('Sagesse', "Demander la sagesse et la direction de Dieu dans mes décisions");
  }

  // 7) Paix / Confiance si "confiance, peur, inquiétude"
  if (anyContains(apply, ['croire', 'confiance', 'paix']) ||
      anyContains(aboutGod, ['confiance'])) {
    add('Paix', "Recevoir la paix et la confiance au milieu de l'incertitude");
  }

  // 8) S'il y a une réponse libre dans certaines questions, on les transforme
  answers.forEach((qid, list) {
    for (final v in list) {
      if (v.trim().isEmpty) continue;
      if (qid == 'apply')      add('Obéissance', 'Mettre en œuvre: $v');
      if (qid == 'warning')    add('Repentance', 'Prendre au sérieux: $v');
      if (qid == 'promise')    add('Promesse', 'Se rappeler: $v');
      if (qid == 'aboutGod')   add('Action de grâce', 'Remercier pour: $v');
    }
  });

  return out;
}

/// Déductions douces à partir des champs libres.
/// Pas d'interprétation : on range ce que l'utilisateur a écrit.
List<PrayerSubject> _fromFree(Map<String, String> free) {
  final out = <PrayerSubject>[];
  void add(String theme, String subject) =>
      out.add({'theme': theme, 'subject': subject});

  final aboutGod   = (free['aboutGod'] ?? '').trim();
  final neighbor   = (free['neighbor'] ?? '').trim();
  final apply      = (free['applyToday'] ?? '').trim();
  final memory     = (free['memoryVerse'] ?? '').trim();

  if (aboutGod.isNotEmpty) {
    add('Action de grâce', "Remercier Dieu pour: $aboutGod");
    add('Louange', "Adorer Dieu tel qu'entrevu: $aboutGod");
  }
  if (neighbor.isNotEmpty) {
    add('Intercession', "Porter dans la prière: $neighbor");
  }
  if (apply.isNotEmpty) {
    add('Obéissance', "Mettre en pratique aujourd'hui: $apply");
  }
  if (memory.isNotEmpty) {
    add('Foi', "Méditer et proclamer: $memory");
    add('Promesse', "Garder ce verset comme appui: $memory");
  }

  return out;
}

// ===== NOUVELLES FONCTIONS D'ANALYSE POUR LA QCM =====

/// Analyse "De quoi/qui parle ce passage ?"
Map<String, dynamic>? _analyzeDeQuoiQui(Set<String> tags, String? passageText) {
  if (tags.contains('praise') || tags.contains('gratitude')) {
    return {
      'theme': 'Louange',
      'subject': 'Adorer Dieu pour ce qu\'il révèle dans ce passage',
      'color': const Color(0xFFFF6B6B),
    };
  }
  if (tags.contains('trust') || tags.contains('promise')) {
    return {
      'theme': 'Foi',
      'subject': 'Placer ma confiance en Dieu selon ce passage',
      'color': const Color(0xFF54A0FF),
    };
  }
  if (tags.contains('intercession')) {
    return {
      'theme': 'Intercession',
      'subject': 'Prier pour ceux mentionnés dans ce passage',
      'color': const Color(0xFF96CEB4),
    };
  }
  return null;
}

/// Analyse "Qu'apprends-je sur Dieu ?"
Map<String, dynamic>? _analyzeApprendDieu(Set<String> tags, String? passageText) {
  if (tags.contains('repentance') || tags.contains('warning')) {
    return {
      'theme': 'Repentance',
      'subject': 'Demander pardon pour mes péchés révélés par ce passage',
      'color': const Color(0xFF8E44AD),
    };
  }
  if (tags.contains('praise') || tags.contains('awe')) {
    return {
      'theme': 'Louange',
      'subject': 'Adorer Dieu pour ses attributs révélés dans ce passage',
      'color': const Color(0xFFFF6B6B),
    };
  }
  if (tags.contains('trust') || tags.contains('promise')) {
    return {
      'theme': 'Foi',
      'subject': 'Renforcer ma foi en Dieu selon ce passage',
      'color': const Color(0xFF54A0FF),
    };
  }
  return null;
}

/// Analyse "Y a-t-il un exemple à suivre ?"
Map<String, dynamic>? _analyzeExemple(Set<String> tags, String? passageText) {
  if (tags.contains('obedience') || tags.contains('responsibility')) {
    return {
      'theme': 'Obéissance',
      'subject': 'Demander la force de suivre l\'exemple de ce passage',
      'color': const Color(0xFFF39C12),
    };
  }
  return null;
}

/// Analyse "Y a-t-il un ordre/commandement ?"
Map<String, dynamic>? _analyzeOrdre(Set<String> tags, String? passageText) {
  if (tags.contains('obedience') || tags.contains('responsibility')) {
    return {
      'theme': 'Obéissance',
      'subject': 'Demander la force d\'obéir aux commandements de ce passage',
      'color': const Color(0xFFF39C12),
    };
  }
  if (tags.contains('intercession')) {
    return {
      'theme': 'Intercession',
      'subject': 'Prier pour que d\'autres obéissent aux commandements de ce passage',
      'color': const Color(0xFF96CEB4),
    };
  }
  return null;
}

/// Analyse "Y a-t-il une promesse ?"
Map<String, dynamic>? _analyzePromesse(Set<String> tags, String? passageText) {
  if (tags.contains('promise') || tags.contains('trust')) {
    return {
      'theme': 'Foi',
      'subject': 'Recevoir avec foi les promesses de ce passage',
      'color': const Color(0xFF54A0FF),
    };
  }
  if (tags.contains('gratitude')) {
    return {
      'theme': 'Gratitude',
      'subject': 'Remercier Dieu pour ses promesses dans ce passage',
      'color': const Color(0xFF2ECC71),
    };
  }
  return null;
}

/// Analyse "Y a-t-il un avertissement ?"
Map<String, dynamic>? _analyzeAvertissement(Set<String> tags, String? passageText) {
  if (tags.contains('warning') || tags.contains('repentance')) {
    return {
      'theme': 'Repentance',
      'subject': 'Me repentir selon les avertissements de ce passage',
      'color': const Color(0xFF8E44AD),
    };
  }
  if (tags.contains('intercession')) {
    return {
      'theme': 'Intercession',
      'subject': 'Prier pour que d\'autres écoutent les avertissements de ce passage',
      'color': const Color(0xFF96CEB4),
    };
  }
  return null;
}

/// Analyse "Y a-t-il une commande ?"
Map<String, dynamic>? _analyzeCommande(Set<String> tags, String? passageText) {
  if (tags.contains('obedience')) {
    return {
      'theme': 'Obéissance',
      'subject': 'Demander la force d\'accomplir les commandements de ce passage',
      'color': const Color(0xFFF39C12),
    };
  }
  if (tags.contains('intercession')) {
    return {
      'theme': 'Intercession',
      'subject': 'Prier pour que d\'autres accomplissent les commandements de ce passage',
      'color': const Color(0xFF96CEB4),
    };
  }
  return null;
}

/// Analyse "Qui est le personnage principal ?"
Map<String, dynamic>? _analyzePersonnagePrincipal(Set<String> tags, String? passageText) {
  if (tags.contains('praise') || tags.contains('trust')) {
    return {
      'theme': 'Louange',
      'subject': 'Adorer Dieu pour le personnage principal de ce passage',
      'color': const Color(0xFFFF6B6B),
    };
  }
  if (tags.contains('intercession')) {
    return {
      'theme': 'Intercession',
      'subject': 'Prier pour ceux qui suivent l\'exemple du personnage principal',
      'color': const Color(0xFF96CEB4),
    };
  }
  return null;
}

/// Analyse "Quelle émotion ressens-tu ?"
Map<String, dynamic>? _analyzeEmotion(Set<String> tags, String? passageText) {
  if (tags.contains('praise') || tags.contains('gratitude')) {
    return {
      'theme': 'Gratitude',
      'subject': 'Remercier Dieu pour les émotions que ce passage éveille',
      'color': const Color(0xFF2ECC71),
    };
  }
  if (tags.contains('repentance') || tags.contains('warning')) {
    return {
      'theme': 'Repentance',
      'subject': 'Me repentir selon les émotions que ce passage éveille',
      'color': const Color(0xFF8E44AD),
    };
  }
  if (tags.contains('trust') || tags.contains('promise')) {
    return {
      'theme': 'Foi',
      'subject': 'Renforcer ma foi selon les émotions que ce passage éveille',
      'color': const Color(0xFF54A0FF),
    };
  }
  return null;
}

/// Analyse "Comment l'appliquer aujourd'hui ?"
Map<String, dynamic>? _analyzeApplication(Set<String> tags, String? passageText) {
  if (tags.contains('obedience') || tags.contains('responsibility')) {
    return {
      'theme': 'Obéissance',
      'subject': 'Demander la force d\'appliquer ce passage dans ma vie',
      'color': const Color(0xFFF39C12),
    };
  }
  if (tags.contains('intercession')) {
    return {
      'theme': 'Intercession',
      'subject': 'Prier pour que d\'autres appliquent ce passage dans leur vie',
      'color': const Color(0xFF96CEB4),
    };
  }
  if (tags.contains('guidance')) {
    return {
      'theme': 'Sagesse',
      'subject': 'Demander la sagesse pour appliquer ce passage',
      'color': const Color(0xFF9B59B6),
    };
  }
  return null;
}
