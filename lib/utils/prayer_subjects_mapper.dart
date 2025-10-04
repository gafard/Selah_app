import 'dart:math';

/// Sortie attendue par PayerpageWidget :
/// [{ 'theme': 'Repentance', 'subject': 'Demander un cœur pur' }, ...]
typedef PrayerSubject = Map<String, String>;

List<PrayerSubject> buildPrayerSubjectsFromMeditation({
  String mode = 'free', // 'free' | 'qcm'
  Map<String, List<String>>? qcmAnswers,     // MeditationQcmPage
  Map<String, String>? freeAnswers,          // MeditationFreePage
}) {
  final subjects = <PrayerSubject>[];

  if (mode == 'qcm' && qcmAnswers != null) {
    subjects.addAll(_fromQcm(qcmAnswers));
  } else if (mode == 'free' && freeAnswers != null) {
    subjects.addAll(_fromFree(freeAnswers));
  }

  // Nettoyage: dédupliquer, couper les sujets trop longs
  String clamp(String s) => s.length <= 120 ? s : '${s.substring(0, 117)}…';

  final seen = <String>{};
  final out = <PrayerSubject>[];
  for (final item in subjects) {
    final key = '${item['theme']}|${item['subject']}';
    if (seen.add(key)) {
      out.add({'theme': item['theme']!, 'subject': clamp(item['subject']!)});
    }
  }

  // On limite à 8–10 cartes pour rester lisible
  return out.take(10).toList();
}

/// Règles simples basées sur les libellés des options cochées (pas d'IA).
List<PrayerSubject> _fromQcm(Map<String, List<String>> answers) {
  final out = <PrayerSubject>[];

  // Helpers
  void add(String theme, String subject) =>
      out.add({'theme': theme, 'subject': subject});

  bool anyContains(List<String>? list, List<String> needles) {
    if (list == null) return false;
    final joined = list.join(' ').toLowerCase();
    return needles.any((n) => joined.contains(n.toLowerCase()));
  }

  // topic / aboutGod / commands / promise / warning / apply...
  final topic      = answers['topic'];
  final aboutGod   = answers['aboutGod'];
  final commands   = answers['commands'];
  final promise    = answers['promise'];
  final warning    = answers['warning'];
  final apply      = answers['apply'];

  // 1) Action de grâce / Louange si Dieu, amour, fidélité, caractère
  if (anyContains(aboutGod, ['amour', 'fidélité', 'grâce', 'miséricorde', 'bienveillance', 'caractère']) ||
      anyContains(topic, ['Dieu'])) {
    add('Action de grâce', "Remercier Dieu pour son caractère et sa bonté révélés aujourd'hui");
    add('Louange', "Adorer Dieu pour ce qu'il est, tel qu'aperçu dans le passage");
  }

  // 2) Obéissance si un ordre a été coché
  if (anyContains(commands, ['Oui'])) {
    add('Obéissance', "Mettre en pratique concrètement l'appel du texte aujourd'hui");
  }

  // 3) Promesse / Foi si promesse cochée
  if (anyContains(promise, ['Oui'])) {
    add('Foi', "M'approprier la promesse lue et m'y appuyer dans la semaine");
    add('Promesse', "Rappeler cette promesse dans la prière et la proclamer avec foi");
  }

  // 4) Repentance si avertissement / exemple à éviter / justice/sainteté
  if (anyContains(warning, ['Oui']) ||
      anyContains(topic, ['éviter']) ||
      anyContains(aboutGod, ['justice', 'sainteté'])) {
    add('Repentance', "Reconnaître et abandonner une attitude/une habitude signalée par le texte");
  }

  // 5) Intercession si "prochain", "église", "ville", etc. apparaissent
  if (anyContains(topic, ['prochain']) ||
      anyContains(apply, ['intercéder']) ||
      anyContains(aboutGod, ['direction']) // souvent lié à prier pour d'autres
     ) {
    add('Intercession', "Prier pour une personne précise concernée par ce que j'ai lu");
  }

  // 6) Sagesse / Guidance si "direction / sagesse / décision"
  if (anyContains(aboutGod, ['sagesse', 'direction']) ||
      anyContains(apply, ['sagesse'])) {
    add('Sagesse', "Demander la sagesse et la direction de Dieu dans mes décisions");
  }

  // 7) Paix / Confiance si "confiance, peur, inquiétude"
  if (anyContains(apply, ['croire', 'confiance', 'paix']) ||
      anyContains(aboutGod, ['confiance'])) {
    add('Paix', "Recevoir la paix et la confiance au milieu de l'incertitude");
  }

  // 8) S'il y a une réponse libre dans certaines questions, on les transforme
  answers.forEach((qid, list) {
    for (final v in list) {
      if (v.trim().isEmpty) continue;
      if (qid == 'apply')      add('Obéissance', 'Mettre en œuvre: $v');
      if (qid == 'warning')    add('Repentance', 'Prendre au sérieux: $v');
      if (qid == 'promise')    add('Promesse', 'Se rappeler: $v');
      if (qid == 'aboutGod')   add('Action de grâce', 'Remercier pour: $v');
    }
  });

  return out;
}

/// Déductions douces à partir des champs libres.
/// Pas d'interprétation : on range ce que l'utilisateur a écrit.
List<PrayerSubject> _fromFree(Map<String, String> free) {
  final out = <PrayerSubject>[];
  void add(String theme, String subject) =>
      out.add({'theme': theme, 'subject': subject});

  final aboutGod   = (free['aboutGod'] ?? '').trim();
  final neighbor   = (free['neighbor'] ?? '').trim();
  final apply      = (free['applyToday'] ?? '').trim();
  final memory     = (free['memoryVerse'] ?? '').trim();

  if (aboutGod.isNotEmpty) {
    add('Action de grâce', "Remercier Dieu pour: $aboutGod");
    add('Louange', "Adorer Dieu tel qu'entrevu: $aboutGod");
  }
  if (neighbor.isNotEmpty) {
    add('Intercession', "Porter dans la prière: $neighbor");
  }
  if (apply.isNotEmpty) {
    add('Obéissance', "Mettre en pratique aujourd'hui: $apply");
  }
  if (memory.isNotEmpty) {
    add('Foi', "Méditer et proclamer: $memory");
    add('Promesse', "Garder ce verset comme appui: $memory");
  }

  return out;
}
