// lib/services/preset_theology_gate_v2.dart
import 'dart:math';

class PlanPreset {
  final String id;
  final String name;
  final List<String> tags;         // ex: ['christology','gospel','scripture','colossiens','ps119']
  final List<String> verseAnchors; // ex: ['1Jn 4:1-3','2Tm 3:16','Ga 1:6-9']
  final int durationDays;
  final int? minutesPerDay;

  // Facul.: signaux internes déjà calculés (0..1). Sinon null.
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
}

class TheologyGateV2 {
  // Pondérations (modifiables)
  static const _wDoctrine = 0.40;
  static const _wAuthority = 0.30;
  static const _wGospel   = 0.30;

  // Seuil minimal pour garder un preset
  static const _keepThreshold = 0.55;

  /// userProfile est **optionnel** et non-bloquant. Ne nécessite aucun nouveau champ.
  static List<PlanPreset> select({
    required List<PlanPreset> candidates,
    Map<String, dynamic>? userProfile,
    int topN = 12,
    void Function(String log)? debug,
  }) {
    final scored = <_ScoredPreset>[];

    // Déductions légères depuis le profil *si présent* (aucune obligation)
    final softBoostDoctrine  = _softBoostFromProfile(userProfile, ['christ', 'jesus', 'incarnation', 'deity']);
    final softBoostAuthority = _softBoostFromProfile(userProfile, ['scripture', 'bible', 'sola', 'authority']);
    final softBoostGospel    = _softBoostFromProfile(userProfile, ['gospel', 'evangile', 'grace', 'justification']);

    for (final p in candidates) {
      final sDoc = _scoreDoctrineOfChrist(p)  + softBoostDoctrine;
      final sAut = _scoreAuthorityOfBible(p)  + softBoostAuthority;
      final sGos = _scoreGospelOfJesus(p)     + softBoostGospel;

      // clamp 0..1
      final doc = sDoc.clamp(0.0, 1.0);
      final aut = sAut.clamp(0.0, 1.0);
      final gos = sGos.clamp(0.0, 1.0);

      final global = (_wDoctrine * doc) + (_wAuthority * aut) + (_wGospel * gos);

      // Rejets durs si tags contraires explicites
      if (_hardReject(p)) {
        debug?.call('⛔ REJECT ${p.name} (hard-fail)');
        continue;
      }

      if (global < _keepThreshold) {
        debug?.call('⚠️ DROP  ${p.name} : global=${global.toStringAsFixed(2)} < $_keepThreshold');
        continue;
      }

      scored.add(_ScoredPreset(preset: p, sDoc: doc, sAut: aut, sGos: gos, global: global));
      debug?.call('✅ KEEP  ${p.name} : D=${doc.toStringAsFixed(2)} '
          'A=${aut.toStringAsFixed(2)} G=${gos.toStringAsFixed(2)} | '
          'global=${global.toStringAsFixed(2)}');
    }

    scored.sort((a, b) {
      final c = b.global.compareTo(a.global);
      if (c != 0) return c;
      return b.sDoc.compareTo(a.sDoc); // priorité à la christologie en cas d'égalité
    });

    return scored.take(topN).map((e) => e.preset).toList(growable: false);
  }

  // ── Scoring par critère (basé uniquement sur tags/verses + focus interne si dispo)

  static double _scoreDoctrineOfChrist(PlanPreset p) {
    final tags = _lower(p.tags);
    final verses = _lower(p.verseAnchors);

    final hits = <bool>[
      tags.any((t) => _any(t, ['christology','christ','incarnation','deity','colossiens','hébreux','jean'])),
      verses.any((v) => v.contains('1jn 4:1-3') || v.contains('1 jean 4:1-3') || v.contains('1jn 4')),
      verses.any((v) => v.contains('jn 1') || v.contains('col 1') || v.contains('heb 1')),
    ].where((b) => b).length;

    final prior = p.focusDoctrineOfChrist ?? 0.0;
    return _blend(hits / 3.0, prior);
  }

  static double _scoreAuthorityOfBible(PlanPreset p) {
    final tags = _lower(p.tags);
    final verses = _lower(p.verseAnchors);

    final hits = <bool>[
      tags.any((t) => _any(t, ['scripture','sola scriptura','inspiration','ps119','psaume 119','canon'])),
      verses.any((v) => v.contains('2tm 3:16') || v.contains('2 timothée 3:16') || v.contains('2 tim 3:16')),
      verses.any((v) => v.contains('ap 22:18') || v.contains('apocalypse 22:18') || v.contains('rev 22:18')),
    ].where((b) => b).length;

    final prior = p.focusAuthorityOfBible ?? 0.0;
    return _blend(hits / 3.0, prior);
  }

  static double _scoreGospelOfJesus(PlanPreset p) {
    final tags = _lower(p.tags);
    final verses = _lower(p.verseAnchors);

    final hits = <bool>[
      tags.any((t) => _any(t, ['gospel','evangile','grace','justification','romains','galates','croix','salut'])),
      verses.any((v) => v.contains('ga 1:6-9') || v.contains('galates 1:6-9') || v.contains('gal 1')),
      verses.any((v) => v.contains('rom 3') || v.contains('romains 3') || v.contains('1 cor 15:1-4')),
    ].where((b) => b).length;

    final prior = p.focusGospelOfJesus ?? 0.0;
    return _blend(hits / 3.0, prior);
  }

  // ── Rejets durs si indicateurs contraires explicites (basé uniquement sur tags)
  static bool _hardReject(PlanPreset p) {
    final tags = _lower(p.tags);
    if (_anyList(tags, ['deny-christ-deity','arian','anti-incarnation'])) return true;         // contre 1 Jn 4
    if (_anyList(tags, ['extra-biblical-authority-core','revelation-additions-required'])) return true; // contre 2 Tm 3:16 / Ap 22:18
    if (_anyList(tags, ['works-based-salvation-core','another-gospel'])) return true;          // contre Ga 1:6-9
    return false;
  }

  // ── Soft boosts facultatifs depuis le profil existant (aucune exigence UI)
  static double _softBoostFromProfile(Map<String, dynamic>? profile, List<String> needles) {
    if (profile == null || profile.isEmpty) return 0.0;
    final hay = profile.entries.map((e) => '${e.key}:${e.value}'.toLowerCase()).join(' ');
    final matches = needles.where((k) => hay.contains(k)).length;
    // boost léger max 0.10
    return min(0.10, matches * 0.03);
    // (ex.: si "tradition:evangelical" + "reads_gospels_often:true" → +0.06)
  }

  // ── Utils
  static List<String> _lower(List<String> xs) => xs.map((e) => e.toLowerCase()).toList();
  static bool _any(String s, List<String> needles) => needles.any((n) => s.contains(n));
  static bool _anyList(List<String> list, List<String> needles) =>
      list.any((s) => needles.any((n) => s.contains(n)));
  static double _blend(double signal, double prior) => (0.7 * signal) + (0.3 * prior);
}

class _ScoredPreset {
  final PlanPreset preset;
  final double sDoc, sAut, sGos, global;
  _ScoredPreset({required this.preset, required this.sDoc, required this.sAut, required this.sGos, required this.global});
}
