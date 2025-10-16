import 'dart:math';

class DoctrineContext {
  final Map<String, dynamic>? userProfile;
  final int minutesPerDay;
  const DoctrineContext({required this.userProfile, required this.minutesPerDay});

  double weightFor(List<String> hints, {double base = 1.0, double bonus = .25}) {
    final all = (userProfile ?? {}).values.map((v) => (v ?? '').toString().toLowerCase()).join(' ');
    final hit = hints.any((h) => all.contains(h.toLowerCase()));
    return (base + (hit ? bonus : 0)).clamp(.5, 1.6);
  }
}

abstract class DoctrineModule {
  String get id;
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> plan, DoctrineContext ctx);
}

/// Doctrine générique "à ancrages" (références + mots-clés)
abstract class AnchoredDoctrineModule implements DoctrineModule {
  /// identifiant stable (ex: "fear_of_God")
  @override
  final String id;

  /// paires {ref, why}
  final List<Map<String, String>> anchors;

  /// mots-clés pour tagger des lectures déjà pertinentes
  final List<String> keywords;

  /// thème/focus par défaut quand on injecte
  final String theme;
  final String focus;

  /// "indice" de fréquence (3..7 jours). Plus bas = plus fréquent.
  final int baseEveryNDays;

  const AnchoredDoctrineModule({
    required this.id,
    required this.anchors,
    required this.keywords,
    required this.theme,
    required this.focus,
    this.baseEveryNDays = 5,
  });

  /// Intensité (par défaut = 1.0). Les sous-classes peuvent surcharger.
  double intensity(DoctrineContext ctx) => 1.0;

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> plan, DoctrineContext ctx) {
    if (plan.isEmpty) return plan;
    final rng = Random(plan.length ^ id.hashCode);

    print('🕊️ $id: Application avec intensité ${intensity(ctx).toStringAsFixed(2)}');

    // 1) Soft-tag: si le jour colle déjà, on ajoute theme/focus/annotation
    final tagged = plan.map((day) {
      final text = (day['text'] as String? ?? '').toLowerCase();
      final ref  = (day['reference'] as String? ?? '').toLowerCase();
      final hits = keywords.any((k) => text.contains(k) || ref.contains(k));
      if (!hits) return day;
      return {
        ...day,
        'doctrine': {...?day['doctrine'], id: true},
        'theme': day['theme'] ?? theme,
        'focus': day['focus'] ?? focus,
        'annotation': day['annotation'] ?? 'En lien avec $theme',
      };
    }).toList();

    // 2) Injection d'ancrages à intervalle pédagogique
    final everyN = (baseEveryNDays / intensity(ctx)).clamp(3, 7).round();
    final out = <Map<String, dynamic>>[];
    int a = 0;

    print('🕊️ $id: Injection tous les $everyN jours');

    for (var i = 0; i < tagged.length; i++) {
      final day = tagged[i];
      if (i % everyN != 0 || a >= anchors.length) {
        out.add(day);
        continue;
      }
      final anchor = anchors[a++];
      final inject = {
        ...day,
        'reference': anchor['ref'],
        'annotation': '${theme} — ${anchor['why']}',
        'theme': theme,
        'focus': focus,
        'doctrine': {...?day['doctrine'], id: true},
        'wasAdjusted': true,
      };
      // Par défaut on remplace (plus simple pour la durée/jour). On peut alterner :
      out.add(rng.nextBool() ? inject : day);
      print('🕊️ $id: Ancrage injecté à la position $i: ${anchor['ref']}');
    }

    // 3) métadonnée
    return out.map((d) => {
      ...d,
      'meta': {
        ...?d['meta'],
        'doctrine_modules': [
          ...((d['meta']?['doctrine_modules'] as List?) ?? []),
          {'id': id, 'intensity': intensity(ctx)}
        ],
      }
    }).toList();
  }
}
