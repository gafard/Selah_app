import 'dart:math';

/// ----- Entrées minimales attendues -----

class PlanPreset {
  final String id;
  final String name;
  final List<String> tags;         // ex: ['christology','gospel','scripture','galates','jean','romains']
  final List<String> verseAnchors; // ex: ['1Jn 4:1-3','2Tm 3:16','Ga 1:6-9']
  final int durationDays;
  final int? minutesPerDay;

  // optionnel: focus pré-rempli (0..1)
  final double? focusDoctrineOfChrist;
  final double? focusAuthorityOfBible;
  final double? focusGospelOfJesus;

  const PlanPreset({
    required this.id,
    required this.name,
    required this.tags,
    required this.verseAnchors,
    required this.durationDays,
    this.minutesPerDay,
    this.focusDoctrineOfChrist,
    this.focusAuthorityOfBible,
    this.focusGospelOfJesus,
  });

  PlanPreset copyWith({
    String? name,
  }) => PlanPreset(
    id: id,
    name: name ?? this.name,
    tags: tags,
    verseAnchors: verseAnchors,
    durationDays: durationDays,
    minutesPerDay: minutesPerDay,
    focusDoctrineOfChrist: focusDoctrineOfChrist,
    focusAuthorityOfBible: focusAuthorityOfBible,
    focusGospelOfJesus: focusGospelOfJesus,
  );
}

class CompleteProfilePrefs {
  final bool affirmsDoctrineOfChrist;   // "Jésus-Christ venu en chair, Fils de Dieu…"
  final bool affirmsAuthorityOfBible;   // "Toute Écriture est inspirée…"
  final bool affirmsGospelOfJesus;      // "L'Évangile de la grâce, anathème aux autres évangiles"
  const CompleteProfilePrefs({
    required this.affirmsDoctrineOfChrist,
    required this.affirmsAuthorityOfBible,
    required this.affirmsGospelOfJesus,
  });
}

/// ----- Moteur de sélection doctrinale -----

class TheologyGate {
  /// Poids (tu peux les ajuster)
  static const _wDoctrine = 0.40;
  static const _wAuthority = 0.30;
  static const _wGospel   = 0.30;

  /// Seuil minimal pour être retenu (0..1)
  static const _keepThreshold = 0.55;

  /// Sélectionne et ordonne les presets selon les 3 critères
  static List<PlanPreset> selectForProfile({
    required List<PlanPreset> candidates,
    required CompleteProfilePrefs prefs,
    int topN = 12,
    void Function(String log)? debug,
  }) {
    final scored = <_ScoredPreset>[];

    for (final p in candidates) {
      final sDoc = _scoreDoctrineOfChrist(p, prefs);
      final sAut = _scoreAuthorityOfBible(p, prefs);
      final sGos = _scoreGospelOfJesus(p, prefs);

      // score global pondéré
      final global = (_wDoctrine * sDoc) + (_wAuthority * sAut) + (_wGospel * sGos);

      // Hard-filters (si l'utilisateur affirme un critère, on interdit les signaux contraires)
      if (_hardReject(p, prefs)) {
        debug?.call('⛔ REJECT ${p.name} : hard-fail doctrinal');
        continue;
      }

      // Seuil minimal
      if (global < _keepThreshold) {
        debug?.call('⚠️ DROP  ${p.name} : global=$global < $_keepThreshold');
        continue;
      }

      scored.add(_ScoredPreset(preset: p, sDoc: sDoc, sAut: sAut, sGos: sGos, global: global));
      debug?.call('✅ KEEP  ${p.name} : D=$sDoc A=$sAut G=$sGos | global=${global.toStringAsFixed(2)}');
    }

    // Tri par score global, puis par focus doctrine (prioriser christologie)
    scored.sort((a, b) {
      final c = b.global.compareTo(a.global);
      if (c != 0) return c;
      return (b.sDoc).compareTo(a.sDoc);
    });

    return scored.take(topN).map((e) => e.preset).toList(growable: false);
  }

  /// ----- Scoring par critère -----

  static double _scoreDoctrineOfChrist(PlanPreset p, CompleteProfilePrefs prefs) {
    // Match sémantique sur tags/versets
    final tags = p.tags.map((t) => t.toLowerCase()).toList();
    final verses = p.verseAnchors.map((v) => v.toLowerCase()).toList();

    final hits = <bool>[
      tags.any((t) => _any(t, ['christology','christ','incarnation','deity','colossiens','hébreux','jean'])),
      verses.any((v) => v.contains('1jn 4:1-3') || v.contains('1 jean 4:1-3') || v.contains('1jn 4')),
      verses.any((v) => v.contains('jn 1') || v.contains('col 1') || v.contains('heb 1')),
    ].where((b) => b).length;

    final prior = p.focusDoctrineOfChrist ?? 0.0;
    double score = _blend(hits / 3.0, prior);

    // Si l'utilisateur affirme ce critère, petit bonus
    if (prefs.affirmsDoctrineOfChrist) score = min(1.0, score + 0.10);
    return score;
  }

  static double _scoreAuthorityOfBible(PlanPreset p, CompleteProfilePrefs prefs) {
    final tags = p.tags.map((t) => t.toLowerCase()).toList();
    final verses = p.verseAnchors.map((v) => v.toLowerCase()).toList();

    final hits = <bool>[
      tags.any((t) => _any(t, ['scripture','sola scriptura','revelation warning','inspiration','psaume 119','ps119','2tim 3','2 tm 3'])),
      verses.any((v) => v.contains('2tm 3:16') || v.contains('2 timothée 3:16') || v.contains('2 tim 3:16')),
      verses.any((v) => v.contains('ap 22:18') || v.contains('apocalypse 22:18') || v.contains('rev 22:18')),
    ].where((b) => b).length;

    final prior = p.focusAuthorityOfBible ?? 0.0;
    double score = _blend(hits / 3.0, prior);

    if (prefs.affirmsAuthorityOfBible) score = min(1.0, score + 0.10);
    return score;
  }

  static double _scoreGospelOfJesus(PlanPreset p, CompleteProfilePrefs prefs) {
    final tags = p.tags.map((t) => t.toLowerCase()).toList();
    final verses = p.verseAnchors.map((v) => v.toLowerCase()).toList();

    final hits = <bool>[
      tags.any((t) => _any(t, ['gospel','evangile','justification','romains','galates','croix','salut','grace'])),
      verses.any((v) => v.contains('ga 1:6-9') || v.contains('galates 1:6-9') || v.contains('gal 1')),
      verses.any((v) => v.contains('rom 3') || v.contains('romains 3') || v.contains('1 cor 15:1-4')),
    ].where((b) => b).length;

    final prior = p.focusGospelOfJesus ?? 0.0;
    double score = _blend(hits / 3.0, prior);

    if (prefs.affirmsGospelOfJesus) score = min(1.0, score + 0.10);
    return score;
  }

  /// ----- Hard-filters : rejette si signaux contraires aux affirmations -----
  static bool _hardReject(PlanPreset p, CompleteProfilePrefs prefs) {
    final tags = p.tags.map((t) => t.toLowerCase()).toList();

    if (prefs.affirmsDoctrineOfChrist) {
      // tags problématiques typiques (adapte selon ton catalogue)
      if (_anyList(tags, ['deny-christ-deity','arian','anti-incarnation'])) return true;
    }
    if (prefs.affirmsAuthorityOfBible) {
      if (_anyList(tags, ['extra-biblical-authority-core','revelation-additions-required'])) return true;
    }
    if (prefs.affirmsGospelOfJesus) {
      if (_anyList(tags, ['works-based-salvation-core','another-gospel'])) return true;
    }
    return false;
  }

  /// ----- Utils -----
  static bool _any(String s, List<String> needles) => needles.any((n) => s.contains(n));
  static bool _anyList(List<String> list, List<String> needles) =>
      list.any((s) => needles.any((n) => s.contains(n)));

  static double _blend(double signal, double prior) {
    // moyenne pondérée (prior doux)
    return (0.7 * signal) + (0.3 * prior);
  }
}

class _ScoredPreset {
  final PlanPreset preset;
  final double sDoc, sAut, sGos, global;
  _ScoredPreset({required this.preset, required this.sDoc, required this.sAut, required this.sGos, required this.global});
}
