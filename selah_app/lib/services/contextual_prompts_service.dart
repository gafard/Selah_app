/// 🧠 Service de génération de prompts contextuels basés sur FalconX
/// 
/// Utilise l'analyse sémantique FalconX pour générer des questions de réflexion
/// adaptées au passage biblique et à la fondation spirituelle du jour.
/// 
/// Intégration avec :
/// - SemanticPassageBoundaryService (FalconX)
/// - SpiritualFoundation (fondation du jour)
/// - BibleTextService (contenu du passage)

import 'semantic_passage_boundary_service.dart';
import '../models/spiritual_foundation.dart';

class ContextualPromptsService {
  
  /// 🎯 Génère des prompts contextuels basés sur l'analyse FalconX
  /// 
  /// [passageRef] : Référence du passage (ex: "Jean 14:1-19")
  /// [foundation] : Fondation spirituelle du jour (optionnel)
  /// [userLevel] : Niveau de l'utilisateur (débutant, intermédiaire, avancé)
  /// 
  /// Retourne : Liste de prompts adaptés au contexte sémantique
  static Future<List<ContextualPrompt>> generateContextualPrompts({
    required String passageRef,
    SpiritualFoundation? foundation,
    String userLevel = 'intermédiaire',
  }) async {
    try {
      // 1. Analyser le passage avec FalconX
      final semanticContext = await _analyzePassageWithFalconX(passageRef);
      
      // 2. Générer des prompts basés sur le contexte sémantique
      final semanticPrompts = _generateSemanticPrompts(semanticContext, userLevel);
      
      // 3. Intégrer la fondation spirituelle si disponible
      final foundationPrompts = foundation != null 
          ? _generateFoundationPrompts(foundation, semanticContext)
          : <ContextualPrompt>[];
      
      // 4. Générer des prompts variés pour plus de diversité
      final variedPrompts = _generateVariedPrompts(passageRef, userLevel);
      
      // 5. Combiner tous les prompts
      final allPrompts = [...semanticPrompts, ...foundationPrompts, ...variedPrompts];
      
      // 6. Mélanger pour éviter la répétition
      allPrompts.shuffle();
      
      // 7. Prioriser et limiter selon le niveau
      return _prioritizePrompts(allPrompts, userLevel);
      
    } catch (e) {
      print('⚠️ Erreur génération prompts contextuels: $e');
      return _getFallbackPrompts();
    }
  }
  
  /// 🔍 Analyse le passage avec FalconX
  static Future<SemanticContext?> _analyzePassageWithFalconX(String passageRef) async {
    try {
      // Extraire livre et chapitre de la référence
      final parts = passageRef.split(' ');
      if (parts.length < 2) return null;
      
      final book = parts[0];
      final chapterPart = parts[1].split(':')[0];
      final chapter = int.tryParse(chapterPart);
      if (chapter == null) return null;
      
      // Utiliser FalconX pour trouver l'unité sémantique
      final unit = SemanticPassageBoundaryService.findUnitContaining(book, chapter);
      if (unit == null) return null;
      
      return SemanticContext(
        unitName: unit.name,
        priority: unit.priority.name,
        theme: unit.theme ?? '',
        liturgicalContext: unit.liturgicalContext,
        emotionalTones: unit.emotionalTones ?? [],
        annotation: unit.annotation,
      );
    } catch (e) {
      print('⚠️ Erreur analyse FalconX: $e');
      return null;
    }
  }
  
  /// 🎨 Génère des prompts basés sur le contexte sémantique
  static List<ContextualPrompt> _generateSemanticPrompts(
    SemanticContext? context, 
    String userLevel
  ) {
    if (context == null) return [];
    
    final prompts = <ContextualPrompt>[];
    
    // Prompts basés sur le thème
    if (context.theme.isNotEmpty) {
      prompts.addAll(_generateThemePrompts(context.theme, userLevel));
    }
    
    // Prompts basés sur les tons émotionnels
    for (final tone in context.emotionalTones) {
      prompts.addAll(_generateEmotionalPrompts(tone, userLevel));
    }
    
    // Prompts basés sur le contexte liturgique
    if (context.liturgicalContext != null && context.liturgicalContext!.isNotEmpty) {
      prompts.addAll(_generateLiturgicalPrompts(context.liturgicalContext!, userLevel));
    }
    
    // Prompts basés sur l'annotation
    if (context.annotation != null && context.annotation!.isNotEmpty) {
      prompts.addAll(_generateAnnotationPrompts(context.annotation!, userLevel));
    }
    
    return prompts;
  }
  
  /// 🌟 Génère des prompts basés sur la fondation spirituelle
  static List<ContextualPrompt> _generateFoundationPrompts(
    SpiritualFoundation foundation,
    SemanticContext? semanticContext
  ) {
    final prompts = <ContextualPrompt>[];
    
    // Prompts basés sur le titre de la fondation
    prompts.add(ContextualPrompt(
      text: 'Comment ${foundation.name} résonne-t-il avec ce passage ?',
      category: 'fondation',
      priority: 1,
      context: 'Fondation spirituelle',
    ));
    
    // Prompts basés sur la description
    if (foundation.shortDescription.isNotEmpty) {
      prompts.add(ContextualPrompt(
        text: 'En quoi ce passage illustre-t-il : "${foundation.shortDescription}" ?',
        category: 'fondation',
        priority: 2,
        context: 'Description de la fondation',
      ));
    }
    
    // Prompts basés sur le verset de référence
    if (foundation.verseReference.isNotEmpty) {
      prompts.add(ContextualPrompt(
        text: 'Comment ce passage se connecte-t-il au verset clé : "${foundation.verseReference}" ?',
        category: 'fondation',
        priority: 1,
        context: 'Verset clé de la fondation',
      ));
    }
    
    // Prompts basés sur le ton de prière
    if (foundation.prayerTone.isNotEmpty) {
      prompts.add(ContextualPrompt(
        text: 'Comment ce passage m\'aide-t-il à prier avec un ton de ${foundation.prayerTone} ?',
        category: 'fondation',
        priority: 2,
        context: 'Ton de prière de la fondation',
      ));
    }
    
    return prompts;
  }
  
  /// 🎨 Génère des prompts basés sur le thème
  static List<ContextualPrompt> _generateThemePrompts(String theme, String userLevel) {
    final prompts = <ContextualPrompt>[];
    
    switch (theme.toLowerCase()) {
      case 'incarnation':
        prompts.addAll([
          ContextualPrompt(
            text: 'Comment ce passage révèle-t-il l\'incarnation de Dieu ?',
            category: 'thème',
            priority: 1,
            context: 'Thème: Incarnation',
          ),
          ContextualPrompt(
            text: 'Qu\'est-ce que cela signifie que Dieu soit devenu homme ?',
            category: 'thème',
            priority: 2,
            context: 'Thème: Incarnation',
          ),
        ]);
        break;
        
      case 'rédemption':
        prompts.addAll([
          ContextualPrompt(
            text: 'Comment ce passage montre-t-il l\'œuvre de rédemption ?',
            category: 'thème',
            priority: 1,
            context: 'Thème: Rédemption',
          ),
          ContextualPrompt(
            text: 'Qu\'est-ce que ce passage m\'apprend sur le prix de ma rédemption ?',
            category: 'thème',
            priority: 2,
            context: 'Thème: Rédemption',
          ),
        ]);
        break;
        
      case 'royaume de dieu':
        prompts.addAll([
          ContextualPrompt(
            text: 'Comment ce passage décrit-il le Royaume de Dieu ?',
            category: 'thème',
            priority: 1,
            context: 'Thème: Royaume de Dieu',
          ),
          ContextualPrompt(
            text: 'Qu\'est-ce que cela signifie de vivre selon les valeurs du Royaume ?',
            category: 'thème',
            priority: 2,
            context: 'Thème: Royaume de Dieu',
          ),
        ]);
        break;
        
      case 'sagesse':
        prompts.addAll([
          ContextualPrompt(
            text: 'Quelle sagesse pratique ce passage m\'offre-t-il ?',
            category: 'thème',
            priority: 1,
            context: 'Thème: Sagesse',
          ),
          ContextualPrompt(
            text: 'Comment puis-je appliquer cette sagesse dans ma vie quotidienne ?',
            category: 'thème',
            priority: 2,
            context: 'Thème: Sagesse',
          ),
        ]);
        break;
        
      default:
        prompts.add(ContextualPrompt(
          text: 'Comment ce passage illustre-t-il le thème de "$theme" ?',
          category: 'thème',
          priority: 2,
          context: 'Thème: $theme',
        ));
    }
    
    return prompts;
  }
  
  /// 🎭 Génère des prompts basés sur les tons émotionnels
  static List<ContextualPrompt> _generateEmotionalPrompts(String tone, String userLevel) {
    final prompts = <ContextualPrompt>[];
    
    switch (tone.toLowerCase()) {
      case 'wonder':
        prompts.add(ContextualPrompt(
          text: 'Qu\'est-ce qui m\'émerveille dans ce passage ?',
          category: 'émotion',
          priority: 2,
          context: 'Ton: Émerveillement',
        ));
        break;
        
      case 'joy':
        prompts.add(ContextualPrompt(
          text: 'Comment ce passage peut-il augmenter ma joie ?',
          category: 'émotion',
          priority: 2,
          context: 'Ton: Joie',
        ));
        break;
        
      case 'peace':
        prompts.add(ContextualPrompt(
          text: 'Comment ce passage m\'apporte-t-il la paix ?',
          category: 'émotion',
          priority: 2,
          context: 'Ton: Paix',
        ));
        break;
        
      case 'hope':
        prompts.add(ContextualPrompt(
          text: 'Quel espoir ce passage me donne-t-il ?',
          category: 'émotion',
          priority: 2,
          context: 'Ton: Espoir',
        ));
        break;
        
      case 'sacrifice':
        prompts.add(ContextualPrompt(
          text: 'Qu\'est-ce que ce passage m\'enseigne sur le sacrifice ?',
          category: 'émotion',
          priority: 2,
          context: 'Ton: Sacrifice',
        ));
        break;
        
      case 'love':
        prompts.add(ContextualPrompt(
          text: 'Comment ce passage révèle-t-il l\'amour de Dieu ?',
          category: 'émotion',
          priority: 2,
          context: 'Ton: Amour',
        ));
        break;
    }
    
    return prompts;
  }
  
  /// ⛪ Génère des prompts basés sur le contexte liturgique
  static List<ContextualPrompt> _generateLiturgicalPrompts(String liturgicalContext, String userLevel) {
    final prompts = <ContextualPrompt>[];
    
    if (liturgicalContext.toLowerCase().contains('noël')) {
      prompts.add(ContextualPrompt(
        text: 'Comment ce passage s\'inscrit-il dans la joie de Noël ?',
        category: 'liturgie',
        priority: 1,
        context: 'Contexte: Noël',
      ));
    } else if (liturgicalContext.toLowerCase().contains('pâques')) {
      prompts.add(ContextualPrompt(
        text: 'Comment ce passage célèbre-t-il la victoire de Pâques ?',
        category: 'liturgie',
        priority: 1,
        context: 'Contexte: Pâques',
      ));
    } else if (liturgicalContext.toLowerCase().contains('carême')) {
      prompts.add(ContextualPrompt(
        text: 'Comment ce passage m\'accompagne-t-il dans le Carême ?',
        category: 'liturgie',
        priority: 1,
        context: 'Contexte: Carême',
      ));
    }
    
    return prompts;
  }
  
  /// 📝 Génère des prompts basés sur l'annotation
  static List<ContextualPrompt> _generateAnnotationPrompts(String annotation, String userLevel) {
    final prompts = <ContextualPrompt>[];
    
    // Extraire des mots-clés de l'annotation pour générer des prompts
    if (annotation.toLowerCase().contains('béatitudes')) {
      prompts.add(ContextualPrompt(
        text: 'Comment puis-je vivre les Béatitudes dans ma vie ?',
        category: 'annotation',
        priority: 1,
        context: 'Annotation: Béatitudes',
      ));
    } else if (annotation.toLowerCase().contains('miracles')) {
      prompts.add(ContextualPrompt(
        text: 'Quel miracle de Dieu ai-je besoin aujourd\'hui ?',
        category: 'annotation',
        priority: 2,
        context: 'Annotation: Miracles',
      ));
    } else if (annotation.toLowerCase().contains('paraboles')) {
      prompts.add(ContextualPrompt(
        text: 'Quelle leçon cette parabole m\'enseigne-t-elle ?',
        category: 'annotation',
        priority: 2,
        context: 'Annotation: Paraboles',
      ));
    }
    
    return prompts;
  }
  
  /// 🎯 Priorise les prompts selon le niveau utilisateur
  static List<ContextualPrompt> _prioritizePrompts(List<ContextualPrompt> prompts, String userLevel) {
    // Limiter selon le niveau utilisateur
    int maxPrompts;
    switch (userLevel.toLowerCase()) {
      case 'débutant':
        maxPrompts = 3;
        break;
      case 'intermédiaire':
        maxPrompts = 5;
        break;
      case 'avancé':
        maxPrompts = 7;
        break;
      default:
        maxPrompts = 5;
    }
    
    // Assurer la diversité en prenant des prompts de différentes catégories
    final categorizedPrompts = <String, List<ContextualPrompt>>{};
    for (final prompt in prompts) {
      categorizedPrompts.putIfAbsent(prompt.category, () => []).add(prompt);
    }
    
    final selectedPrompts = <ContextualPrompt>[];
    
    // Prendre au moins un prompt de chaque catégorie disponible
    for (final category in categorizedPrompts.keys) {
      if (selectedPrompts.length >= maxPrompts) break;
      final categoryPrompts = categorizedPrompts[category]!;
      if (categoryPrompts.isNotEmpty) {
        selectedPrompts.add(categoryPrompts.first);
      }
    }
    
    // Compléter avec les prompts restants si nécessaire
    if (selectedPrompts.length < maxPrompts) {
      final remainingPrompts = prompts.where((p) => !selectedPrompts.contains(p)).toList();
      selectedPrompts.addAll(remainingPrompts.take(maxPrompts - selectedPrompts.length));
    }
    
    return selectedPrompts;
  }
  
  /// 🔄 Prompts de secours si l'analyse échoue
  static List<ContextualPrompt> _getFallbackPrompts() {
    return [
      ContextualPrompt(
        text: 'Qu\'est-ce que ce passage me dit aujourd\'hui ?',
        category: 'général',
        priority: 1,
        context: 'Prompts généraux',
      ),
      ContextualPrompt(
        text: 'Comment puis-je appliquer ce passage dans ma vie ?',
        category: 'général',
        priority: 2,
        context: 'Prompts généraux',
      ),
      ContextualPrompt(
        text: 'Qu\'est-ce que ce passage révèle sur le caractère de Dieu ?',
        category: 'général',
        priority: 2,
        context: 'Prompts généraux',
      ),
    ];
  }

  /// 🎲 Génère des prompts variés et diversifiés
  static List<ContextualPrompt> _generateVariedPrompts(String passageRef, String userLevel) {
    final prompts = <ContextualPrompt>[];
    
    // Prompts variés selon le niveau utilisateur
    final generalPrompts = [
      'Quel verset me touche le plus dans ce passage ?',
      'Comment ce passage transforme-t-il ma vision de Dieu ?',
      'Quelle promesse divine puis-je retenir ici ?',
      'Comment ce passage m\'encourage-t-il aujourd\'hui ?',
      'Qu\'est-ce que Jésus me dit personnellement ?',
      'Comment puis-je partager cette vérité avec d\'autres ?',
      'Quelle prière ce passage m\'inspire-t-il ?',
      'Comment ce passage change-t-il ma perspective ?',
      'Quel défi ce passage me lance-t-il ?',
      'Comment puis-je vivre cette vérité concrètement ?',
    ];
    
    // Prompts pour niveau avancé
    if (userLevel.toLowerCase() == 'avancé') {
      generalPrompts.addAll([
        'Comment ce passage s\'inscrit-il dans le plan de Dieu ?',
        'Quelles sont les implications théologiques de ce texte ?',
        'Comment ce passage éclaire-t-il d\'autres passages bibliques ?',
        'Quelle est la signification historique de ce passage ?',
        'Comment ce passage révèle-t-il la nature trinitaire de Dieu ?',
      ]);
    }
    
    // Mélanger et sélectionner 3-5 prompts aléatoires
    generalPrompts.shuffle();
    final selectedPrompts = generalPrompts.take(userLevel.toLowerCase() == 'débutant' ? 3 : 5).toList();
    
    for (int i = 0; i < selectedPrompts.length; i++) {
      prompts.add(ContextualPrompt(
        text: selectedPrompts[i],
        category: 'varié',
        priority: i + 1,
        context: 'Prompts variés',
      ));
    }
    
    return prompts;
  }
}

/// 🎯 Modèle pour un prompt contextuel
class ContextualPrompt {
  final String text;
  final String category;
  final int priority; // 1 = plus important
  final String context;
  
  const ContextualPrompt({
    required this.text,
    required this.category,
    required this.priority,
    required this.context,
  });
}

/// 🧠 Contexte sémantique extrait par FalconX
class SemanticContext {
  final String unitName;
  final String priority;
  final String theme;
  final String? liturgicalContext;
  final List<String> emotionalTones;
  final String? annotation;
  
  const SemanticContext({
    required this.unitName,
    required this.priority,
    required this.theme,
    this.liturgicalContext,
    required this.emotionalTones,
    this.annotation,
  });
}
