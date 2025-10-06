import '../models/plan_profile.dart';
import 'remote_plan_generator.dart';

class PlanRules {
  /// Traduit (level, goals, minutes, totalDays) en paramètres du générateur.
  static Uri buildGeneratorUrl(PlanProfile p, {required String version}) {
    // ORDER
    final wantsChrono = p.goals.contains(Goal.deepenWord) || p.goals.contains(Goal.wholeBible);
    final order = wantsChrono ? 'chronological' : 'traditional';

    // BOOKS
    String books = 'OT,NT';
    if (p.goals.contains(Goal.prayer) && p.totalDays <= 30) {
      books = 'NT'; // plus léger sur 30 jours orienté prière
    }

    // DAILY PSALM/PROVERB
    final dailyPsalm   = p.goals.contains(Goal.prayer) || p.minutesPerDay >= 20;
    final dailyProverb = p.minutesPerDay >= 15 && !p.goals.contains(Goal.wholeBible);

    // LOGIC: words/chapters — on garde "words" pour équilibrer la longueur quotidienne
    const logic = 'words';

    // SITE / VERSION (adapter selon ton choix réel)
    const urlsite     = 'biblegateway';
    final urlversion  = version; // ex: 'LSG'/'S21' etc.

    return RemotePlanGenerator.buildUrl(
      start: p.startDate,
      totalDays: p.totalDays,
      format: 'calendar', // on tentera CSV d'abord dans fetchPlan()
      order: order,
      books: books,
      lang: 'fr',
      urlsite: urlsite,
      urlversion: urlversion,
      dailyPsalm: dailyPsalm,
      dailyProverb: dailyProverb,
      otntOverlap: false,
      logic: logic,
    );
  }
}

