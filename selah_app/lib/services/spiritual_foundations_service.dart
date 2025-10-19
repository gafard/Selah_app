import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/spiritual_foundation.dart';
import '../models/plan_models.dart';

/// Service de gestion des fondations spirituelles
class SpiritualFoundationsService {
  static List<SpiritualFoundation>? _foundations;
  static bool _isLoading = false;

  /// Charge les fondations depuis le fichier JSON
  static Future<List<SpiritualFoundation>> loadFoundations() async {
    if (_foundations != null) return _foundations!;
    if (_isLoading) {
      // Attendre que le chargement en cours se termine
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _foundations ?? [];
    }

    _isLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/theology/spiritual_foundations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> foundationsJson = jsonData['foundations'] as List<dynamic>;
      
      _foundations = foundationsJson
          .map((json) => SpiritualFoundation.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('✅ SpiritualFoundationsService: ${_foundations!.length} fondations chargées');
      return _foundations!;
    } catch (e) {
      print('❌ SpiritualFoundationsService: Erreur chargement fondations: $e');
      _foundations = [];
      return [];
    } finally {
      _isLoading = false;
    }
  }

  /// Retourne la fondation du jour basée sur le plan et le profil utilisateur
  static Future<SpiritualFoundation> getFoundationOfDay(
    Plan? plan,
    int dayNumber,
    dynamic profile,
  ) async {
    final allFoundations = await loadFoundations();
    if (allFoundations.isEmpty) {
      throw Exception('Aucune fondation disponible');
    }

    // 1. Rotation basée sur le plan (si disponible et lié)
    if (plan != null && plan.foundationIds != null && plan.foundationIds!.isNotEmpty) {
      final foundationIdForDay = plan.foundationIds![(dayNumber - 1) % plan.foundationIds!.length];
      final foundation = allFoundations.firstWhere(
        (f) => f.id == foundationIdForDay,
        orElse: () => allFoundations[0],
      );
      print('🧠 Fondation du jour (Plan): ${foundation.name}');
      return foundation;
    }

    // 2. 🧠 INTELLIGENCE ADAPTÉE - Utiliser le système intelligent existant de goals_page.dart
    final intelligentFoundations = _getIntelligentFoundations(allFoundations, profile, dayNumber);
    if (intelligentFoundations.isNotEmpty) {
      final foundation = intelligentFoundations.first;
      print('🧠 Fondation du jour (Intelligence): ${foundation.name}');
      return foundation;
    }

    // 3. Fallback: rotation simple basée sur le niveau
    String spiritualLevel = 'beginner';
    if (profile is Map<String, dynamic>) {
      spiritualLevel = _mapProfileToLevel(profile['level'] ?? 'beginner');
    } else if (profile != null) {
      try {
        final level = profile.level ?? 'beginner';
        spiritualLevel = _mapProfileToLevel(level);
      } catch (e) {
        print('⚠️ Erreur accès niveau profil: $e, utilisation de beginner');
        spiritualLevel = 'beginner';
      }
    }
    
    final filtered = allFoundations.where((f) =>
        f.targetProfiles.contains(spiritualLevel)
    ).toList();

    if (filtered.isEmpty) {
      final index = (dayNumber - 1) % allFoundations.length;
      print('🧠 Fondation du jour (Fallback): ${allFoundations[index].name}');
      return allFoundations[index];
    }

    final index = (dayNumber - 1) % filtered.length;
    print('🧠 Fondation du jour (Niveau): ${filtered[index].name}');
    return filtered[index];
  }

  /// 🧠 INTELLIGENCE ADAPTÉE - Utilise le système intelligent existant de goals_page.dart
  static List<SpiritualFoundation> _getIntelligentFoundations(
    List<SpiritualFoundation> allFoundations,
    dynamic userProfile,
    int dayNumber,
  ) {
    if (userProfile == null) return [];

    // Convertir le profil en Map si nécessaire
    Map<String, dynamic> profileMap;
    if (userProfile is Map<String, dynamic>) {
      profileMap = userProfile;
    } else {
      try {
        // Si c'est un UserProfile, essayer d'accéder aux propriétés
        profileMap = {
          'level': userProfile.level ?? 'beginner',
          'goal': userProfile.goal ?? 'Discipline quotidienne',
          'heartPosture': userProfile.heartPosture ?? '🙏 Écouter la voix de Dieu',
          'motivation': userProfile.motivation ?? '🙏 Recherche de direction',
        };
      } catch (e) {
        print('⚠️ Erreur conversion profil: $e');
        return [];
      }
    }

    final goal = profileMap['goal'] as String? ?? '';
    final heartPosture = profileMap['heartPosture'] as String? ?? '';
    final motivation = profileMap['motivation'] as String? ?? '';
    final level = profileMap['level'] as String? ?? '';

    // 🎯 SCORING INTELLIGENT basé sur le système existant de goals_page.dart
    final scoredFoundations = allFoundations.map((foundation) {
      int score = 0;
      final name = foundation.name.toLowerCase();
      final description = foundation.fullDescription.toLowerCase();

      // Objectifs Christ-centrés (même logique que goals_page.dart)
      if (goal.contains('Rencontrer Jésus') && (name.contains('christ') || name.contains('jésus') || name.contains('fondement'))) {
        score += 3;
      } else if (goal.contains('Voir Jésus') && (name.contains('christ') || name.contains('jésus') || name.contains('gloire'))) {
        score += 3;
      } else if (goal.contains('transformé') && (name.contains('nouveau') || name.contains('renouveler') || name.contains('changer'))) {
        score += 3;
      } else if (goal.contains('intimité') && (name.contains('prière') || name.contains('méditation') || name.contains('relation'))) {
        score += 3;
      } else if (goal.contains('prier') && (name.contains('prière') || name.contains('méditation'))) {
        score += 3;
      } else if (goal.contains('voix de Dieu') && (name.contains('écouter') || name.contains('parole'))) {
        score += 3;
      } else if (goal.contains('fruit de l\'Esprit') && (name.contains('amour') || name.contains('joie') || name.contains('paix'))) {
        score += 3;
      } else if (goal.contains('Renouveler') && (name.contains('nouveau') || name.contains('renouveler'))) {
        score += 3;
      } else if (goal.contains('Esprit') && (name.contains('esprit') || name.contains('saint'))) {
        score += 3;
      }

      // Posture du cœur
      if (heartPosture.contains('Rencontrer Jésus') && (name.contains('christ') || name.contains('jésus'))) {
        score += 2;
      } else if (heartPosture.contains('transformé') && (name.contains('nouveau') || name.contains('changer'))) {
        score += 2;
      } else if (heartPosture.contains('Écouter') && (name.contains('écouter') || name.contains('parole'))) {
        score += 2;
      } else if (heartPosture.contains('intimité') && (name.contains('prière') || name.contains('relation'))) {
        score += 2;
      }

      // Motivation
      if (motivation.contains('direction') && (name.contains('chemin') || name.contains('voie'))) {
        score += 1;
      } else if (motivation.contains('croissance') && (name.contains('grandir') || name.contains('croître'))) {
        score += 1;
      } else if (motivation.contains('paix') && (name.contains('paix') || name.contains('sérénité'))) {
        score += 1;
      }

      // Niveau spirituel
      final spiritualLevel = _mapProfileToLevel(level);
      if (foundation.targetProfiles.contains(spiritualLevel)) {
        score += 1;
      }

      return MapEntry(foundation, score);
    }).toList();

    // Trier par score décroissant et retourner les meilleures
    scoredFoundations.sort((a, b) => b.value.compareTo(a.value));
    
    // Retourner les fondations avec le score le plus élevé
    final maxScore = scoredFoundations.isNotEmpty ? scoredFoundations.first.value : 0;
    if (maxScore > 0) {
      return scoredFoundations
          .where((entry) => entry.value == maxScore)
          .map((entry) => entry.key)
          .toList();
    }

    return [];
  }


  /// Retourne une fondation par son ID
  static Future<SpiritualFoundation?> getFoundationById(String id) async {
    final foundations = await loadFoundations();
    try {
      return foundations.firstWhere((f) => f.id == id);
    } catch (e) {
      print('⚠️ Fondation "$id" non trouvée');
      return null;
    }
  }

  /// Retourne les fondations adaptées au profil utilisateur
  static Future<List<SpiritualFoundation>> getFoundationsForProfile(String spiritualLevel) async {
    final allFoundations = await loadFoundations();
    final level = _mapProfileToLevel(spiritualLevel);
    
    return allFoundations.where((f) => f.targetProfiles.contains(level)).toList();
  }

  /// Retourne les fondations par catégorie
  static Future<List<SpiritualFoundation>> getFoundationsByCategory(String category) async {
    final foundations = await loadFoundations();
    return foundations.where((f) => f.category == category).toList();
  }

  /// Retourne les fondations de base (essentielles)
  static Future<List<SpiritualFoundation>> getFoundationStones() async {
    return getFoundationsByCategory('foundation');
  }

  /// Retourne les pratiques spirituelles
  static Future<List<SpiritualFoundation>> getPractices() async {
    return getFoundationsByCategory('practice');
  }

  /// Retourne les pièges à éviter
  static Future<List<SpiritualFoundation>> getPitfalls() async {
    return getFoundationsByCategory('pitfall');
  }

  /// Mappe le niveau de profil utilisateur vers les niveaux de fondations
  static String _mapProfileToLevel(String userLevel) {
    switch (userLevel.toLowerCase()) {
      case 'nouveau converti':
      case 'rétrograde':
      case 'débutant':
      case 'beginner':
        return 'beginner';
      case 'fidèle pas si régulier':
      case 'fidèle régulier':
      case 'chrétien fidèle':
      case 'intermédiaire':
      case 'intermediate':
        return 'intermediate';
      case 'serviteur/leader':
      case 'leader spirituel':
      case 'avancé':
      case 'advanced':
        return 'advanced';
      default:
        return 'beginner';
    }
  }

  /// Retourne le message de rappel contextuel pour une fondation
  static String getReminderText(SpiritualFoundation foundation) {
    switch (foundation.id) {
      case 'christ_foundation':
        return 'Aujourd\'hui, bâtis ta vie sur le Christ, le roc inébranlable.';
      case 'word_keystone':
        return 'Que la Parole de Dieu soit la clé de voûte de tes décisions.';
      case 'humility_prayer':
        return 'Aujourd\'hui, médite dans un esprit d\'humilité et de prière.';
      case 'forgiveness':
        return 'Y a-t-il quelqu\'un que tu dois pardonner selon ce texte ?';
      case 'trust_god':
        return 'Bâtis ta sécurité sur Dieu, pas sur ce monde.';
      case 'priorities':
        return 'Aligne tes priorités sur la volonté de Dieu.';
      case 'discernment':
        return 'Examine-toi toi-même avant de juger les autres.';
      case 'obedience':
        return 'Mets en pratique ce que tu lis dans la Parole.';
      case 'practice':
        return 'Transforme ta connaissance en action concrète.';
      case 'sand_foundation':
        return 'Évite de bâtir sur des fondations instables.';
      case 'vain_work':
        return 'Assure-toi que Dieu dirige tes efforts.';
      default:
        return 'Vive cette fondation spirituelle aujourd\'hui.';
    }
  }

  /// Retourne les prières contextuelles pour une fondation
  static List<String> getFoundationPrayers(SpiritualFoundation foundation) {
    switch (foundation.id) {
      case 'christ_foundation':
        return [
          'Seigneur, aide-moi à bâtir ma vie sur toi, le roc inébranlable.',
          'Que mes actions d\'aujourd\'hui reflètent mon obéissance à ta Parole.',
        ];
      case 'word_keystone':
        return [
          'Père, que ta Parole soit la clé de voûte de toutes mes décisions.',
          'Aide-moi à ne pas seulement écouter, mais à mettre en pratique ce que je lis.',
        ];
      case 'humility_prayer':
        return [
          'Seigneur, que je médite dans un esprit d\'humilité et de prière constante.',
          'Apprends-moi à prier sans cesse et à marcher humblement devant toi.',
        ];
      case 'forgiveness':
        return [
          'Père, aide-moi à pardonner comme tu m\'as pardonné.',
          'Donne-moi la grâce de libérer ceux qui m\'ont blessé.',
        ];
      case 'trust_god':
        return [
          'Seigneur, je veux bâtir ma sécurité sur toi, pas sur ce monde.',
          'Aide-moi à te faire confiance plutôt qu\'aux choses éphémères.',
        ];
      case 'priorities':
        return [
          'Père, aligne mes priorités sur ta volonté.',
          'Que je cherche d\'abord ton royaume et ta justice.',
        ];
      case 'discernment':
        return [
          'Seigneur, donne-moi le discernement pour juger avec justesse.',
          'Aide-moi à m\'examiner moi-même avant de juger les autres.',
        ];
      case 'obedience':
        return [
          'Seigneur, aide-moi à obéir à ta Parole dans ma vie quotidienne.',
          'Que mon amour pour toi se manifeste par mon obéissance.',
        ];
      case 'practice':
        return [
          'Père, aide-moi à transformer ma connaissance en action.',
          'Que ma foi soit vivante et se manifeste par des œuvres.',
        ];
      case 'sand_foundation':
        return [
          'Seigneur, garde-moi de bâtir sur des fondations instables.',
          'Aide-moi à rejeter les vanités de ce monde.',
        ];
      case 'vain_work':
        return [
          'Père, dirige mes efforts pour qu\'ils ne soient pas vains.',
          'Que tout ce que je fais soit fait avec toi et pour toi.',
        ];
      default:
        return [
          'Seigneur, aide-moi à vivre cette fondation aujourd\'hui.',
        ];
    }
  }

  /// Force le rechargement des fondations (utile pour les tests)
  static Future<void> reload() async {
    _foundations = null;
    _isLoading = false;
    await loadFoundations();
  }
}
