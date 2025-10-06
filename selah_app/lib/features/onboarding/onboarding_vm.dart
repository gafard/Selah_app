import 'package:flutter/foundation.dart';
import '../../domain/user_prefs.dart';
import '../../models/plan.dart';
import '../../services/user_prefs_service.dart';
import '../../services/plan_service.dart';
import '../../services/image_service.dart';

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

  final UserPrefsService prefs;
  final PlanService plans;

  UserProfile? profile;
  Plan? plan;
  List<OnboardingCard> cards = [];
  bool loading = true;
  Object? error;

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try {
      profile = await prefs.getProfile();
      final currentPlanId = profile!.preferences?['currentPlanId'] as String?;
      if (currentPlanId != null) {
        // TODO: Corriger le conflit de types Plan
        // final activePlan = await plans.getActivePlan();
        // if (activePlan != null) {
        //   plan = activePlan;
        // }
      }

      _buildCards();
      loading = false; notifyListeners();
    } catch (e) {
      error = e; loading = false; notifyListeners();
    }
  }

  void _buildCards() {
    final p = profile!;
    final display = p.displayName ?? 'ami';
    final goals = (p.preferences?['goals'] as List?)?.cast<String>() ?? [];
    final firstGoal = goals.isNotEmpty ? goals.first : 'discipline';

    // 1) Encouragement (intro)
    cards.add(OnboardingCard(
      title: 'Bienvenue $display,',
      subtitle: 'Commence sereinement, un jour a la fois.',
      content: plan != null
          ? 'Tu demarres « ${plan!.name} » sur ${plan!.totalDays} jours. On est avec toi.'
          : 'Tu es pret a lancer ton premier parcours de meditation.',
      imageUrl: plan?.coverUrl ?? ImageService.heroForGoal(firstGoal),
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
    await prefs.setHasOnboarded(value: true);
  }
}
