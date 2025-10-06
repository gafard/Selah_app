import 'dart:math';
import 'package:flutter/material.dart';
import '../models/plan_preset.dart';

class DynamicPresetGenerator {
  static final Random _random = Random();
  
  // Thèmes bibliques avec variations dynamiques
  static const List<String> _themes = [
    'Fondations de la foi',
    'Vie de prière',
    'Sagesse pratique',
    'Espérance et réconfort',
    'Mission et témoignage',
    'Relations et famille',
    'Trials et persévérance',
    'Louange et adoration',
    'Repentance et pardon',
    'Foi et miracles',
    'Leadership spirituel',
    'Communion fraternelle'
  ];
  
  // Adjectifs pour personnaliser les noms
  static const List<String> _adjectives = [
    'Essentiel', 'Profond', 'Transformateur', 'Inspirant', 'Révélateur',
    'Puissant', 'Guérisseur', 'Libérateur', 'Édifiant', 'Raffermissant',
    'Éclairant', 'Rénovateur', 'Stimulant', 'Apaisant', 'Fortifiant'
  ];
  
  // Formats de noms dynamiques
  static const List<String> _nameFormats = [
    '{adjective} {theme}',
    '{theme} {adjective}',
    'Parcours {theme}',
    'Découverte {theme}',
    'Exploration {theme}',
    'Immersion {theme}',
    'Aventure {theme}',
    'Voyage {theme}'
  ];
  
  // Descriptions dynamiques
  static const List<String> _descriptions = [
    'Un parcours personnalisé pour approfondir ta relation avec Dieu',
    'Découvre les trésors cachés de la Parole de Dieu',
    'Un voyage spirituel adapté à ton rythme de vie',
    'Explore les fondements de ta foi de manière progressive',
    'Renforce ta marche chrétienne avec des enseignements pratiques',
    'Développe une compréhension plus profonde des Écritures',
    'Cultive une intimité grandissante avec le Seigneur',
    'Bâtis une foi solide sur des bases bibliques solides'
  ];
  
  // Durées variées
  static const List<int> _durations = [7, 14, 21, 30, 45, 60, 90, 120];
  
  // Temps de lecture variés
  static const List<int> _readingTimes = [5, 10, 15, 20, 25, 30];
  
  // Gradients dynamiques
  static const List<List<Color>> _gradients = [
    [Color(0xFF60A5FA), Color(0xFF93C5FD)], // Bleu
    [Color(0xFFA78BFA), Color(0xFFC4B5FD)], // Violet
    [Color(0xFF34D399), Color(0xFF6EE7B7)], // Vert
    [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Orange
    [Color(0xFFEF4444), Color(0xFFF87171)], // Rouge
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // Violet foncé
    [Color(0xFF06B6D4), Color(0xFF67E8F9)], // Cyan
    [Color(0xFF84CC16), Color(0xFFA3E635)], // Lime
    [Color(0xFFEC4899), Color(0xFFF472B6)], // Rose
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo
  ];
  
  /// Génère 4+ presets dynamiques basés sur le profil utilisateur
  static List<PlanPreset> generateDynamicPresets(Map<String, dynamic>? userProfile) {
    final presets = <PlanPreset>[];
    final usedThemes = <String>{};
    final usedNames = <String>{};
    
    // Déterminer le nombre de presets (minimum 4, maximum 6)
    final presetCount = 4 + _random.nextInt(3);
    
    // Analyser le profil pour personnaliser
    final level = userProfile?['level'] as String? ?? 'Nouveau converti';
    final goal = userProfile?['goal'] as String? ?? 'Discipline quotidienne';
    final timeAvailable = userProfile?['minutesPerDay'] as int? ?? 15;
    
    for (int i = 0; i < presetCount; i++) {
      String theme;
      String name;
      String description;
      
      // Éviter les doublons
      do {
        theme = _themes[_random.nextInt(_themes.length)];
      } while (usedThemes.contains(theme));
      usedThemes.add(theme);
      
      // Générer un nom unique
      do {
        final format = _nameFormats[_random.nextInt(_nameFormats.length)];
        final adjective = _adjectives[_random.nextInt(_adjectives.length)];
        name = format
            .replaceAll('{adjective}', adjective)
            .replaceAll('{theme}', theme);
      } while (usedNames.contains(name));
      usedNames.add(name);
      
      // Personnaliser selon le niveau
      if (level == 'Nouveau converti') {
        description = _getBeginnerDescription(theme);
      } else if (level == 'Chrétien mature') {
        description = _getAdvancedDescription(theme);
      } else {
        description = _descriptions[_random.nextInt(_descriptions.length)];
      }
      
      // Adapter la durée selon le temps disponible
      int duration = _getAdaptedDuration(timeAvailable);
      int readingTime = _getAdaptedReadingTime(timeAvailable);
      
      // Générer un slug unique
      final slug = _generateSlug(name, i);
      
      // Créer le preset
      final preset = PlanPreset(
        slug: slug,
        name: name,
        durationDays: duration,
        order: _getOrderForTheme(theme),
        books: _getBooksForTheme(theme),
        coverImage: _getCoverImageForTheme(theme),
        minutesPerDay: readingTime,
        recommended: _getRecommendedLevels(level),
        description: description,
        gradient: _gradients[i % _gradients.length],
      );
      
      presets.add(preset);
    }
    
    return presets;
  }
  
  static String _getBeginnerDescription(String theme) {
    final beginnerDescriptions = {
      'Fondations de la foi': 'Parfait pour découvrir les bases de la foi chrétienne',
      'Vie de prière': 'Apprends à prier avec confiance et simplicité',
      'Sagesse pratique': 'Découvre la sagesse biblique pour la vie quotidienne',
      'Espérance et réconfort': 'Trouve la paix et l\'espérance dans les promesses de Dieu',
    };
    return beginnerDescriptions[theme] ?? 'Un parcours adapté aux débutants pour découvrir la Parole de Dieu';
  }
  
  static String _getAdvancedDescription(String theme) {
    final advancedDescriptions = {
      'Fondations de la foi': 'Approfondis ta compréhension des doctrines fondamentales',
      'Vie de prière': 'Développe une vie de prière plus profonde et mature',
      'Sagesse pratique': 'Explore les nuances de la sagesse biblique',
      'Espérance et réconfort': 'Médite sur les aspects profonds de l\'espérance chrétienne',
    };
    return advancedDescriptions[theme] ?? 'Un parcours approfondi pour les chrétiens matures';
  }
  
  static int _getAdaptedDuration(int timeAvailable) {
    if (timeAvailable <= 10) {
      return _durations[_random.nextInt(4)]; // 7-30 jours
    } else if (timeAvailable <= 20) {
      return _durations[2 + _random.nextInt(4)]; // 21-60 jours
    } else {
      return _durations[4 + _random.nextInt(4)]; // 45-120 jours
    }
  }
  
  static int _getAdaptedReadingTime(int timeAvailable) {
    if (timeAvailable <= 10) {
      return _readingTimes[_random.nextInt(3)]; // 5-15 min
    } else if (timeAvailable <= 20) {
      return _readingTimes[2 + _random.nextInt(3)]; // 15-25 min
    } else {
      return _readingTimes[3 + _random.nextInt(3)]; // 20-30 min
    }
  }
  
  static String _generateSlug(String name, int index) {
    final slug = name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return '${slug}_${index + 1}';
  }
  
  static String _getOrderForTheme(String theme) {
    final orderMap = {
      'Fondations de la foi': 'chronological',
      'Vie de prière': 'thematic',
      'Sagesse pratique': 'random',
      'Espérance et réconfort': 'thematic',
      'Mission et témoignage': 'chronological',
      'Relations et famille': 'thematic',
      'Trials et persévérance': 'random',
      'Louange et adoration': 'thematic',
      'Repentance et pardon': 'chronological',
      'Foi et miracles': 'thematic',
      'Leadership spirituel': 'chronological',
      'Communion fraternelle': 'thematic',
    };
    return orderMap[theme] ?? 'thematic';
  }
  
  static String _getBooksForTheme(String theme) {
    final booksMap = {
      'Fondations de la foi': 'Genesis,Exodus,Matthew,John',
      'Vie de prière': 'Psalms,Matthew,John,Acts',
      'Sagesse pratique': 'Proverbs,Ecclesiastes,James,1Peter',
      'Espérance et réconfort': 'Psalms,Isaiah,John,Revelation',
      'Mission et témoignage': 'Matthew,Acts,Romans,Ephesians',
      'Relations et famille': 'Genesis,Proverbs,Ephesians,1Corinthians',
      'Trials et persévérance': 'Job,Psalms,James,1Peter',
      'Louange et adoration': 'Psalms,Isaiah,Revelation',
      'Repentance et pardon': 'Psalms,Isaiah,Matthew,Luke',
      'Foi et miracles': 'Exodus,Matthew,Mark,Acts',
      'Leadership spirituel': 'Exodus,1Samuel,Acts,1Timothy',
      'Communion fraternelle': 'Acts,Romans,1Corinthians,1John',
    };
    return booksMap[theme] ?? 'OT,NT';
  }
  
  static String? _getCoverImageForTheme(String theme) {
    // Retourner des URLs d'images basées sur le thème
    final imageMap = {
      'Fondations de la foi': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'Vie de prière': 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400',
      'Sagesse pratique': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
      'Espérance et réconfort': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
    };
    return imageMap[theme];
  }
  
  static List<PresetLevel> _getRecommendedLevels(String level) {
    switch (level) {
      case 'Nouveau converti':
        return [PresetLevel.beginner, PresetLevel.regular];
      case 'Chrétien mature':
        return [PresetLevel.regular, PresetLevel.leader];
      default:
        return [PresetLevel.regular];
    }
  }
}