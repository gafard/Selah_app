import '../models/plan_profile.dart';
import 'plan_rules.dart';
import 'remote_plan_generator.dart';

class PlanOrchestrator {
  /// Appelé après "CompleteProfile" (ou depuis les paramètres).
  static Future<void> generateAndCachePlan({
    required PlanProfile profile,
    required String bibleVersion, // 'LSG', 'S21', etc.
  }) async {
    final url = PlanRules.buildGeneratorUrl(profile, version: bibleVersion);
    final days = await RemotePlanGenerator.fetchPlan(url);

    await RemotePlanGenerator.cachePlan(
      planId: 'remote_${profile.level}_${profile.goals.hashCode}_${profile.totalDays}_$bibleVersion',
      days: days,
      meta: {
        'title': _title(profile, bibleVersion),
        'start': profile.startDate.toIso8601String(),
        'totalDays': profile.totalDays,
        'minutesPerDay': profile.minutesPerDay,
        'level': profile.level.toString(),
        'goals': profile.goals.map((g) => g.name).toList(),
        'version': bibleVersion,
        'source': url.toString(),
      },
    );
  }

  static String _title(PlanProfile p, String v) {
    return 'Plan ${p.totalDays}j • ${v.toUpperCase()}';
  }
}

