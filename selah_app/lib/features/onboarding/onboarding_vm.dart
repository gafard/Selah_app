import 'package:flutter/foundation.dart';
import '../../domain/user_prefs.dart';
import '../../models/plan.dart';
import '../../services/user_prefs_hive.dart';
import '../../services/plan_service.dart';
import '../../services/image_service.dart';
import '../../services/local_storage_service.dart';

class OnboardingCard {
  final String title;
  final String subtitle;
  final String content;
  final String imageUrl; // 3D/illu
  final int indexAccent; // pour varier l'accent shape
  OnboardingCard({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.imageUrl,
    required this.indexAccent,
  });
}

class OnboardingVM extends ChangeNotifier {
  OnboardingVM({required this.prefs, required this.plans});

  final UserPrefsHive prefs;
  final PlanService plans;

  UserProfile? profile;
  Plan? plan;
  List<OnboardingCard> cards = [];
  bool loading = true;
  Object? error;

  Future<void> load() async {
    print('🎯 OnboardingVM.load() démarré');
    loading = true; error = null; notifyListeners();
    try {
      // Récupérer le profil utilisateur complet depuis LocalStorageService
      final localUser = LocalStorageService.getLocalUser();
      print('🎯 OnboardingVM: localUser=$localUser');
      
      if (localUser != null) {
        profile = UserProfile.fromJson(localUser);
      } else {
        // Fallback vers UserPrefsHive si pas de profil local
        final profileData = prefs.profile;
        print('🎯 OnboardingVM: profileData fallback=$profileData');
        profile = UserProfile.fromJson(profileData);
      }
      final currentPlanId = profile!.preferences?['currentPlanId'] as String?;
      if (currentPlanId != null) {
        // TODO: Corriger le conflit de types Plan
        // final activePlan = await plans.getActivePlan();
        // if (activePlan != null) {
        //   plan = activePlan;
        // }
      }

      _buildCards();
      print('🎯 OnboardingVM: cards construites=${cards.length}');
      loading = false; notifyListeners();
    } catch (e) {
      print('🎯 OnboardingVM: erreur=$e');
      error = e; loading = false; notifyListeners();
    }
  }

  void _buildCards() {
    final p = profile!;
    
    // Récupérer le nom depuis le profil utilisateur local (LocalStorageService)
    String display = 'ami';
    try {
      // Essayer de récupérer depuis displayName d'abord
      if (p.displayName != null && p.displayName!.isNotEmpty) {
        display = p.displayName!;
      } else {
        // Fallback: essayer de récupérer depuis les préférences
        display = p.preferences?['name'] as String? ?? 
                 p.preferences?['firstName'] as String? ?? 
                 p.preferences?['displayName'] as String? ?? 
                 'ami';
      }
    } catch (e) {
      print('❌ Erreur récupération nom: $e');
      display = 'ami';
    }
    
    print('🎯 Nom utilisateur récupéré: $display');
    
    // Récupérer les données depuis UserPrefsHive directement
    final profileData = prefs.profile;
    final goal = profileData['goal'] as String? ?? 'discipline';
    final level = profileData['level'] as String? ?? 'Fidèle régulier';
    final heartPosture = profileData['heartPosture'] as String? ?? 'Rencontrer Jésus';
    final motivation = profileData['motivation'] as String? ?? 'Passion pour Christ';

    // 1) Encouragement (intro) - PERSONNALISÉ
    cards.add(OnboardingCard(
      title: 'Bienvenue $display,',
      subtitle: _getPersonalizedSubtitle(level, goal),
      content: plan != null
          ? 'Tu démarres « ${plan!.name} » sur ${plan!.totalDays} jours. On est avec toi.'
          : _getPersonalizedContent(goal, heartPosture, motivation),
      imageUrl: plan?.coverUrl ?? ImageService.heroForGoal(goal),
      indexAccent: 0,
    ));

    // 2) Appel a la discipline
    cards.add(OnboardingCard(
      title: 'La regularite precede la profondeur.',
      subtitle: 'Discipline joyeuse',
      content:
          'Rendez-vous quotidien a ${p.preferredTime} • ${p.dailyMinutes} min. On te rappellera, mais c\'est ton "oui" qui fera la difference.',
      imageUrl: ImageService.heroForGoal('discipline'),
      indexAccent: 1,
    ));

    // 3) Quand c'est dur
    cards.add(OnboardingCard(
      title: 'Quand c\'est difficile, repose-toi sur le Seigneur.',
      subtitle: 'Grace et perseverance',
      content:
          'Respire, prie, avance. « Ma grace te suffit » — ne lache pas, va jusqu\'au bout du plan.',
      imageUrl: ImageService.heroForGoal('memorisation'),
      indexAccent: 2,
    ));
  }

  Future<void> finish() async {
    // marque onboarded
    await prefs.setHasOnboarded(true);
  }

  /// Génère un sous-titre personnalisé selon le niveau et l'objectif
  String _getPersonalizedSubtitle(String level, String goal) {
    switch (level) {
      case 'Nouveau converti':
        return 'Commence sereinement, un jour a la fois.';
      case 'Rétrograde':
        return 'Retrouve le chemin, un pas a la fois.';
      case 'Fidèle pas si régulier':
        return 'Retrouve la constance, un jour a la fois.';
      case 'Serviteur/leader':
        return 'Affermis ton leadership, un jour a la fois.';
      default:
        return 'Approfondis ta marche, un jour a la fois.';
    }
  }

  /// Génère un contenu personnalisé selon l'objectif et la posture du cœur
  String _getPersonalizedContent(String goal, String heartPosture, String motivation) {
    // Objectifs Christ-centrés
    if (goal.contains('Rencontrer Jésus') || heartPosture.contains('Rencontrer Jésus')) {
      return 'Tu es pret a rencontrer Jésus personnellement dans Sa Parole. Chaque jour sera une nouvelle rencontre avec Lui.';
    } else if (goal.contains('transformé') || heartPosture.contains('transformé')) {
      return 'Tu es pret a etre transformé par la Parole de Dieu. Chaque jour apportera une nouvelle revelation de Sa gloire.';
    } else if (goal.contains('intimité') || heartPosture.contains('intimité')) {
      return 'Tu es pret a approfondir ton intimité avec Dieu. Chaque jour sera un moment privilegie avec Lui.';
    } else if (goal.contains('prier') || heartPosture.contains('Écouter')) {
      return 'Tu es pret a apprendre a prier et ecouter la voix de Dieu. Chaque jour sera une nouvelle lecon de priere.';
    } else if (goal.contains('fruit de l\'Esprit')) {
      return 'Tu es pret a voir le fruit de l\'Esprit grandir en toi. Chaque jour sera une nouvelle graine plantee.';
    } else if (goal.contains('Renouveler')) {
      return 'Tu es pret a renouveler tes pensées par la Parole. Chaque jour apportera une nouvelle perspective.';
    } else if (goal.contains('Esprit')) {
      return 'Tu es pret a etre rempli de l\'Esprit Saint. Chaque jour sera une nouvelle onction.';
    }
    
    // Objectifs classiques
    else if (goal.contains('discipline')) {
      return 'Tu es pret a developper une discipline de lecture biblique. Chaque jour sera un pas vers la constance.';
    } else if (goal.contains('Approfondir')) {
      return 'Tu es pret a approfondir ta connaissance de Dieu. Chaque jour sera une nouvelle revelation.';
    } else if (goal.contains('foi')) {
      return 'Tu es pret a fortifier ta foi. Chaque jour sera un nouveau pas de foi.';
    } else if (goal.contains('caractère')) {
      return 'Tu es pret a developper ton caractère chrétien. Chaque jour sera une nouvelle lecon.';
    }
    
    // Fallback
    return 'Tu es pret a lancer ton premier parcours de meditation biblique. Chaque jour sera une nouvelle aventure.';
  }
}
