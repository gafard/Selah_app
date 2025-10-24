class PrayerSubject {
  final String label;
  final String category; // gratitude, repentance, ...
  PrayerSubject(this.label, this.category);
}

class PrayerSubjectsBuilder {
  // --- Micro-templates concis, non moralisateurs, prêts à être personnalisés ---
  static const Map<String, List<String>> _templates = {
    'gratitude': [
      'Dire merci pour {topic}',
      'Remercier pour {topic} aujourd\'hui',
      'Reconnaître la bonté de Dieu dans {topic}',
    ],
    'repentance': [
      'Déposer devant Dieu cette faiblesse autour de {topic}',
      'Demander un cœur renouvelé à propos de {topic}',
    ],
    'obedience': [
      'Mettre en pratique {smallStep} concernant {topic}',
      'Choisir un petit pas d\'obéissance lié à {topic}',
    ],
    'promise': [
      'M\'appuyer sur la promesse lue concernant {topic}',
      'Redire cette promesse sur {topic} dans la prière',
    ],
    'intercession': [
      'Porter {person} devant Dieu à propos de {topic}',
      'Prier pour {person} (soutien concret autour de {topic})',
    ],
    'praise': [
      'Adorer Dieu pour {topic}',
      'Dire qui est Dieu : {topic}',
    ],
    'trust': [
      'Confier à Dieu {topic} et accueillir sa paix',
      'Remettre {topic} entre Ses mains',
    ],
    'guidance': [
      'Demander sagesse et clarté pour {topic}',
      'Chercher la direction de Dieu concernant {topic}',
    ],
    'warning': [
      'Établir un garde-fou doux autour de {topic}',
      'Veiller avec lucidité sur {topic}',
    ],
    // fallback
    'other': [
      'Parler à Dieu de {topic}',
    ],
  };

  // Petites expressions "pas durs" pour l'obéissance
  static const List<String> _smallSteps = [
    'un geste simple',
    'une action discrète',
    'un premier pas',
    'un choix concret',
  ];

  // Mots à ignorer dans l'extraction de "topics"
  static const Set<String> _stop = {
    'le','la','les','un','une','des','de','du','au','aux','à','pour','par','avec','dans','sur',
    'et','ou','mais','que','qui','dont','ça','ce','cette','ces','mon','ma','mes','ton','ta','tes',
    'son','sa','ses','notre','nos','votre','vos','leur','leurs','plus','moins','très','trop',
  };

  // --- API 1: depuis QCM (tags) ---
  static List<PrayerSubject> fromQcm({required List<String> selectedOptionTags}) {
    final tags = selectedOptionTags.where((e) => e.trim().isNotEmpty).toList();
    if (tags.isEmpty) return _defaults();

    // Comptage/pondération basique par tag
    final freq = <String,int>{};
    for (final t in tags) { freq[t] = (freq[t] ?? 0) + 1; }

    // Génère 1–2 sujets par tag le plus fréquent, sans texte libre (topic = "ce qui me concerne aujourd'hui")
    final top = freq.keys.toList()
      ..sort((a,b) => (freq[b]!).compareTo(freq[a]!));

    final out = <PrayerSubject>[];
    for (final tag in top.take(4)) {
      final tpls = _templates[tag] ?? _templates['other']!;
      const topic = 'ce qui me concerne aujourd\'hui';
      final s1 = _fill(tpls[0], topic: topic);
      out.add(PrayerSubject(s1, tag));
      if (tpls.length > 1) {
        final s2 = _fill(tpls[1], topic: topic);
        out.add(PrayerSubject(s2, tag));
      }
    }
    return _dedupe(out).take(6).toList();
  }

  // --- API 2: depuis textes libres + tags par champ ---
  static List<PrayerSubject> fromFree({
    required Map<String, Set<String>> selectedTagsByField,
    Map<String, String>? freeTexts,
    String? passageText,
    String? passageRef,
  }) {
    final subjects = <PrayerSubject>[];
    final tagWeight = _tagWeights(selectedTagsByField);

    // 1) Extraire des "topics" (3–5 mots pertinents max)
    final topics = _extractTopics(freeTexts, passageText);
    final person  = _guessPerson(freeTexts); // "maman", "un collègue", etc.
    final topicOrDefault = topics.isNotEmpty ? topics.first : _extractPassageTopics(passageText);

    // 2) Générer par tags, mais en injectant le(s) topic(s)
    //    On pousse 1–2 templates par tag avec topic/person/step personnalisés
    final orderedTags = tagWeight.keys.toList()
      ..sort((a,b) => tagWeight[b]!.compareTo(tagWeight[a]!));

    for (final tag in orderedTags) {
      final tpls = _templates[tag] ?? _templates['other']!;
      final smallStep = (List<String>.from(_smallSteps)..shuffle()).first;

      final t1 = _fill(tpls[0], topic: topicOrDefault, person: person, smallStep: smallStep);
      subjects.add(PrayerSubject(t1, tag));

      if (tpls.length > 1 && topics.length > 1) {
        final t2 = _fill(tpls[1], topic: topics[1], person: person, smallStep: smallStep);
        subjects.add(PrayerSubject(t2, tag));
      }
    }

    // 3) Champ-spécifiques doux (si fournis)
    if (freeTexts != null) {
      final aboutGod = freeTexts['aboutGod']?.trim();
      if ((aboutGod ?? '').isNotEmpty) {
        subjects.add(PrayerSubject('Redire qui est Dieu : "$aboutGod"', 'praise'));
        subjects.add(PrayerSubject('Dire merci pour cette lumière : "$aboutGod"', 'gratitude'));
      }
      final neighbor = freeTexts['neighbor']?.trim() ?? freeTexts['aboutNeighbor']?.trim();
      if ((neighbor ?? '').isNotEmpty) {
        final who = person ?? 'une personne proche';
        subjects.add(PrayerSubject('Confier $who : "$neighbor"', 'intercession'));
        subjects.add(PrayerSubject('Aimer en acte à propos de "$neighbor"', 'obedience'));
      }
      final apply = freeTexts['applyToday']?.trim()
        ?? freeTexts['correctToday']?.trim()
        ?? freeTexts['setDifferent']?.trim();
      if ((apply ?? '').isNotEmpty) {
        final step = (List<String>.from(_smallSteps)..shuffle()).first;
        subjects.add(PrayerSubject('Choisir $step autour de "$apply"', 'obedience'));
        subjects.add(PrayerSubject('Demander persévérance pour "$apply"', 'trust'));
      }
      final verseHit = freeTexts['verseHit']?.trim();
      if ((verseHit ?? '').isNotEmpty) {
        subjects.add(PrayerSubject('Méditer et redire ce verset : "$verseHit"', 'promise'));
      }
    }

    final clean = _dedupe(subjects);
    return clean.isEmpty ? _defaults() : clean.take(8).toList();
  }

  // ----------------- helpers -----------------

  static List<PrayerSubject> _defaults() => [
    PrayerSubject('Dire merci pour une bonté précise d\'aujourd\'hui', 'gratitude'),
    PrayerSubject('Confier en paix ce qui pèse sur mon cœur', 'trust'),
    PrayerSubject('Demander sagesse pour un choix concret', 'guidance'),
    PrayerSubject('Porter une personne devant Dieu', 'intercession'),
  ];

  static Map<String,double> _tagWeights(Map<String, Set<String>> byField) {
    // pondère par nombre d'occurrences (fusion de tous les champs)
    final w = <String,double>{};
    for (final tags in byField.values) {
      for (final t in tags) {
        w[t] = (w[t] ?? 0) + 1.0;
      }
    }
    return w;
  }

  static List<String> _extractTopics(Map<String,String>? free, String? passageText) {
    final bag = <String,int>{};

    // Extraire des textes libres
    if (free != null) {
      for (final v in free.values) {
        if (v.isEmpty) continue;
        final text = v.toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
        if (text.isEmpty) continue;
        for (final w in text.split(' ')) {
          if (w.length <= 2 || _stop.contains(w)) continue;
          bag[w] = (bag[w] ?? 0) + 1;
        }
      }
    }

    // Extraire du passage biblique
    if (passageText != null && passageText.isNotEmpty) {
      final text = passageText.toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
      if (text.isNotEmpty) {
        // Prioriser les mots clés bibliques importants
        final biblicalKeywords = [
          'jésus', 'christ', 'dieu', 'seigneur', 'père', 'esprit', 'saint',
          'royaume', 'salut', 'grâce', 'amour', 'foi', 'espérance',
          'prière', 'adoration', 'louange', 'gratitude', 'repentance',
          'obéissance', 'service', 'mission', 'témoignage', 'évangile'
        ];
        
        for (final w in text.split(' ')) {
          if (w.length <= 2 || _stop.contains(w)) continue;
          // Donner plus de poids aux mots clés bibliques
          final weight = biblicalKeywords.contains(w) ? 3 : 1;
          bag[w] = (bag[w] ?? 0) + weight;
        }
      }
    }

    final sorted = bag.keys.toList()..sort((a,b)=>bag[b]!.compareTo(bag[a]!));
    // on combine 1–3 mots clés pour faire un topic lisible
    final top = sorted.take(6).toList();
    final topics = <String>[];
    if (top.isNotEmpty) topics.add(top.take(3).join(' '));
    if (top.length > 3) topics.add(top.skip(3).take(3).join(' '));
    return topics.map(_toTitle).toList();
  }

  static String _extractPassageTopics(String? passageText) {
    if (passageText == null || passageText.isEmpty) return 'ce que je vis';
    
    // Extraire des mots clés significatifs du passage
    final text = passageText.toLowerCase()
      .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
    
    if (text.isEmpty) return 'ce que je vis';
    
    // Chercher des mots clés bibliques importants
    final biblicalKeywords = [
      'jésus', 'christ', 'dieu', 'seigneur', 'père', 'esprit', 'saint',
      'royaume', 'salut', 'grâce', 'amour', 'foi', 'espérance',
      'prière', 'adoration', 'louange', 'gratitude', 'repentance',
      'obéissance', 'service', 'mission', 'témoignage', 'évangile'
    ];
    
    final words = text.split(' ');
    final significantWords = <String>[];
    
    // Prioriser les mots clés bibliques
    for (final word in words) {
      if (word.length > 3 && 
          !_stop.contains(word) && 
          (biblicalKeywords.contains(word) || significantWords.length < 2)) {
        significantWords.add(word);
        if (significantWords.length >= 3) break;
      }
    }
    
    if (significantWords.isEmpty) return 'ce que je vis';
    
    // Créer un topic cohérent
    final topic = significantWords.join(' ');
    return topic.isNotEmpty ? topic : 'ce que je vis';
  }

  static String? _guessPerson(Map<String,String>? free) {
    if (free == null) return null;
    final text = free.values.join(' ').toLowerCase();
    final hits = <String>[
      'maman','papa','mon frère','ma sœur','un ami','une amie','mon collègue','ma collègue',
      'mon voisin','ma voisine','mon enfant','ma fille','mon fils','mon conjoint','ma conjointe'
    ];
    for (final h in hits) {
      if (text.contains(h)) return h;
    }
    return null;
  }

  static String _fill(String tpl, {required String topic, String? person, String? smallStep}) {
    return tpl
      .replaceAll('{topic}', topic)
      .replaceAll('{person}', person ?? 'quelqu\'un')
      .replaceAll('{smallStep}', smallStep ?? 'un premier pas');
  }

  static String _toTitle(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static List<PrayerSubject> _dedupe(List<PrayerSubject> items) {
    final seen = <String>{};
    final out  = <PrayerSubject>[];
    for (final it in items) {
      final key = '${it.category}|${it.label.toLowerCase()}';
      if (seen.add(key)) out.add(it);
    }
    return out;
  }
}