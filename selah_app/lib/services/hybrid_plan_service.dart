import 'package:flutter/material.dart';
import '../models/thompson_plan_models.dart';
import '../models/plan_preset.dart';
import 'bible_plan_api_service.dart';
import 'thompson_plan_service.dart';
import 'image_service.dart';

/// Service hybride qui combine la logique Thompson 21 avec l'API biblereadingplangenerator.com
/// Génère des plans de lecture réels basés sur les thèmes Thompson
class HybridPlanService {
  final ThompsonPlanService _thompsonService;
  final BiblePlanApiService _bibleApiService;
  
  HybridPlanService({
    required ThompsonPlanService thompsonService,
    required BiblePlanApiService bibleApiService,
  }) : _thompsonService = thompsonService,
       _bibleApiService = bibleApiService;

  /// Génère un plan hybride : thèmes Thompson + plan de lecture réel
  static Future<HybridPlanResult> generateHybridPlan(CompleteProfile profile) async {
    try {
      print('🔄 Génération plan hybride Thompson + API...');
      
      // 1. Générer le plan Thompson pour les thèmes et la structure
      final thompsonService = ThompsonPlanService(imageService: ImageService());
      await thompsonService.initialize();
      final thompsonPlan = await thompsonService.generatePlan(profile);
      
      // 2. Extraire les thèmes Thompson
      final themeKeys = thompsonPlan.meta['themeKeys'] as List<dynamic>? ?? [];
      final primaryTheme = themeKeys.isNotEmpty ? themeKeys.first as String : 'spiritual_demand';
      
      print('🎯 Thème principal: $primaryTheme');
      
      // 3. Générer le plan de lecture réel via l'API
      final biblePlanResponse = await BiblePlanApiService.generateThompsonBasedPlan(
        profile: profile,
        thompsonTheme: primaryTheme,
        customPlanName: thompsonPlan.title,
      );
      
      if (!biblePlanResponse.success) {
        print('❌ Échec génération plan API: ${biblePlanResponse.error}');
        // Fallback vers le plan Thompson uniquement
        return HybridPlanResult(
          success: true,
          planPreset: _convertThompsonToPlanPreset(thompsonPlan),
          thompsonPlan: thompsonPlan,
          biblePlanResponse: null,
          isHybrid: false,
        );
      }
      
      print('✅ Plan hybride généré avec succès');
      
      // 4. Créer un PlanPreset combiné
      final hybridPreset = _createHybridPreset(thompsonPlan, biblePlanResponse, primaryTheme);
      
      return HybridPlanResult(
        success: true,
        planPreset: hybridPreset,
        thompsonPlan: thompsonPlan,
        biblePlanResponse: biblePlanResponse,
        isHybrid: true,
      );
      
    } catch (e) {
      print('❌ Erreur génération plan hybride: $e');
      return HybridPlanResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Convertit un plan Thompson en PlanPreset
  static PlanPreset _convertThompsonToPlanPreset(ThompsonPlanPreset thompsonPlan) {
    return PlanPreset(
      slug: thompsonPlan.id,
      name: thompsonPlan.title,
      durationDays: thompsonPlan.durationDays,
      order: 'thematic',
      books: 'OT,NT',
      coverImage: thompsonPlan.meta['coverImage'] as String?,
      minutesPerDay: thompsonPlan.meta['minutesPerDay'] as int?,
      recommended: [PresetLevel.regular],
      description: thompsonPlan.description,
      gradient: _getThompsonGradient(thompsonPlan.meta['themeKeys'] as List<dynamic>?),
      specificBooks: _getSpecificBooksForTheme(thompsonPlan.meta['themeKeys'] as List<dynamic>?),
    );
  }
  
  /// Crée un preset hybride combinant Thompson et API
  static PlanPreset _createHybridPreset(
    ThompsonPlanPreset thompsonPlan,
    BiblePlanResponse biblePlanResponse,
    String primaryTheme,
  ) {
    return PlanPreset(
      slug: 'hybrid_${thompsonPlan.id}',
      name: biblePlanResponse.planName ?? thompsonPlan.title,
      durationDays: biblePlanResponse.totalDays ?? thompsonPlan.durationDays,
      order: 'hybrid', // Nouveau type pour les plans hybrides
      books: biblePlanResponse.books ?? 'OT,NT',
      coverImage: thompsonPlan.meta['coverImage'] as String?,
      minutesPerDay: thompsonPlan.meta['minutesPerDay'] as int?,
      recommended: [PresetLevel.regular],
      description: _createHybridDescription(thompsonPlan, biblePlanResponse, primaryTheme),
      gradient: _getThompsonGradient(thompsonPlan.meta['themeKeys'] as List<dynamic>?),
      specificBooks: _getSpecificBooksForTheme(thompsonPlan.meta['themeKeys'] as List<dynamic>?),
    );
  }
  
  /// Crée une description hybride
  static String _createHybridDescription(
    ThompsonPlanPreset thompsonPlan,
    BiblePlanResponse biblePlanResponse,
    String primaryTheme,
  ) {
    final themeNames = {
      'spiritual_demand': 'Exigence spirituelle',
      'no_worry': 'Paix du cœur',
      'companionship': 'Communion fraternelle',
      'marriage_duties': 'Mariage selon Dieu',
      'prayer_life': 'Vie de prière',
      'forgiveness': 'Pardon & guérison',
      'faith_trials': 'Foi dans l\'épreuve',
      'common_errors': 'Sagesse pratique',
    };
    
    final themeName = themeNames[primaryTheme] ?? 'Plan spirituel';
    final books = biblePlanResponse.books ?? 'OT,NT';
    final days = biblePlanResponse.totalDays ?? thompsonPlan.durationDays;
    
    return 'Plan de lecture biblique personnalisé basé sur le thème "$themeName" de la Bible d\'étude Thompson 21. '
           'Parcours de $days jours à travers $books avec des passages sélectionnés pour approfondir ce thème spirituel. '
           'Idéal pour une méditation quotidienne guidée par la Parole de Dieu.';
  }
  
  /// Génère un gradient pour les thèmes Thompson
  static List<Color>? _getThompsonGradient(List<dynamic>? themeKeys) {
    if (themeKeys == null || themeKeys.isEmpty) return null;
    
    final themes = themeKeys.cast<String>();
    
    if (themes.contains('no_worry')) {
      return [const Color(0xFF4FD1C5), const Color(0xFF06B6D4)]; // Teal pour la paix
    }
    if (themes.contains('spiritual_demand')) {
      return [const Color(0xFF7C8CFF), const Color(0xFF6366F1)]; // Indigo pour la discipline
    }
    if (themes.contains('marriage_duties')) {
      return [const Color(0xFFEC4899), const Color(0xFFF472B6)]; // Rose pour le mariage
    }
    if (themes.contains('companionship')) {
      return [const Color(0xFF34D399), const Color(0xFF10B981)]; // Vert pour la communauté
    }
    if (themes.contains('prayer_life')) {
      return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)]; // Violet pour la prière
    }
    if (themes.contains('forgiveness')) {
      return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]; // Orange pour le pardon
    }
    if (themes.contains('faith_trials')) {
      return [const Color(0xFFEF4444), const Color(0xFFF87171)]; // Rouge pour les épreuves
    }
    
    return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
  }

  /// Génère les livres spécifiques pour un thème Thompson
  static String? _getSpecificBooksForTheme(List<dynamic>? themeKeys) {
    if (themeKeys == null || themeKeys.isEmpty) return null;
    
    final themes = themeKeys.cast<String>();
    
    // Livres spécifiques aux thèmes Thompson
    if (themes.contains('no_worry')) {
      return 'Matthieu 6, Psaumes 23, 27, 46, 91, 121';
    }
    if (themes.contains('spiritual_demand')) {
      return 'Matthieu 5-7, Romains 12-14, Éphésiens 4-6';
    }
    if (themes.contains('marriage_duties')) {
      return 'Genèse 2, Proverbes 31, Éphésiens 5, 1 Corinthiens 7';
    }
    if (themes.contains('companionship')) {
      return 'Genèse 2, Proverbes 18, Actes 2, 1 Corinthiens 13';
    }
    if (themes.contains('prayer_life')) {
      return 'Psaumes 1-50, Matthieu 6, Luc 11, Éphésiens 6';
    }
    if (themes.contains('forgiveness')) {
      return 'Matthieu 18, Luc 15, Éphésiens 4, Colossiens 3';
    }
    if (themes.contains('faith_trials')) {
      return 'Jacques 1, Romains 5, 1 Pierre 1, Hébreux 11';
    }
    if (themes.contains('common_errors')) {
      return 'Proverbes 1-10, Jacques 1-5, Galates 5';
    }
    
    return null;
  }
  
  /// Sauvegarde un plan hybride
  static Future<void> saveHybridPlan(HybridPlanResult result) async {
    if (!result.success) return;
    
    try {
      // Sauvegarder le plan Thompson
      if (result.thompsonPlan != null) {
        final thompsonService = ThompsonPlanService(imageService: ImageService());
        await thompsonService.initialize();
        await thompsonService.savePlan(result.thompsonPlan!);
      }
      
      // TODO: Sauvegarder le plan de lecture API (HTML ou données parsées)
      // Pour l'instant, on peut stocker l'URL ou le contenu HTML
      
      print('💾 Plan hybride sauvegardé');
    } catch (e) {
      print('❌ Erreur sauvegarde plan hybride: $e');
    }
  }
}

/// Résultat d'un plan hybride
class HybridPlanResult {
  final bool success;
  final String? error;
  final PlanPreset? planPreset;
  final ThompsonPlanPreset? thompsonPlan;
  final BiblePlanResponse? biblePlanResponse;
  final bool isHybrid; // true si combine Thompson + API, false si Thompson seul
  
  const HybridPlanResult({
    required this.success,
    this.error,
    this.planPreset,
    this.thompsonPlan,
    this.biblePlanResponse,
    this.isHybrid = false,
  });
}
