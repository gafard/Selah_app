class PassageFacts {
  final Set<String> people;
  final Set<String> places;
  final List<String> keyEvents; // phrases courtes
  PassageFacts({required this.people, required this.places, required this.keyEvents});
}

class McqItem {
  final String question;
  final List<String> choices;
  final int correctIndex;
  McqItem(this.question, this.choices, this.correctIndex);
}

PassageFacts extractFacts(String text) {
  // Utiliser une expression régulière simplifiée
  final tokens = text.split(RegExp(r'\s+|\,|\;|\:|\.|!|\?|\(|\)|\[|\]|«|»|"'));
  final people = <String>{};
  final places = <String>{};
  final events = <String>[];

  // Heuristique : mots capitalisés au milieu de phrase -> candidats personnages/lieux
  for (final t in tokens) {
    final trimmed = t.trim();
    if (trimmed.length >= 3 && 
        trimmed[0].toUpperCase() == trimmed[0] && 
        trimmed.substring(1).toLowerCase() == trimmed.substring(1)) {
      // Tu peux croiser avec une petite liste blanche de prénoms bibliques
      people.add(trimmed);
    }
  }

  // "Événements" : coupe le texte en phrases courtes
  events.addAll(
    text.split(RegExp(r'(?<=[.?!])\s+'))
        .where((s) => s.trim().length > 20)
        .map((s) => s.trim())
  );

  return PassageFacts(
    people: people, 
    places: places, 
    keyEvents: events.take(6).toList()
  );
}

List<McqItem> buildMcqs(String passageText) {
  final f = extractFacts(passageText);
  final items = <McqItem>[];

  // 1) Qui est dans le texte ?
  if (f.people.length >= 2) {
    final list = f.people.toList();
    final correct = list.first;
    list.shuffle();
    items.add(McqItem(
      "Quel personnage apparaît dans ce passage ?",
      [correct, ...list.skip(1).take(3)],
      0,
    ));
  }

  // 2) Vrai / Faux (simulé en MCQ)
  if (f.keyEvents.isNotEmpty) {
    final e = f.keyEvents.first;
    items.add(McqItem(
      "Cette affirmation est-elle vraie selon le passage ?\n« $e »",
      ["Vrai", "Faux"],
      0, // on garde Vrai si on met une phrase exacte du texte
    ));
  }

  // 3) Ordre des événements (si ≥3 phrases)
  if (f.keyEvents.length >= 3) {
    final seq = f.keyEvents.take(3).toList();
    final shuffled = [...seq]..shuffle();
    items.add(McqItem(
      "Remets ces événements dans l'ordre (du passage) :",
      shuffled,
      shuffled.indexOf(seq.first), // on pourrait coder un UI drag&drop; ici, MCQ simplifié
    ));
  }

  return items;
}