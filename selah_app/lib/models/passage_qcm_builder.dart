import 'dart:math';

enum QcmType { single, multi }

class QcmQuestion {
  final String id;
  final String title;
  final QcmType type;
  final List<QcmOption> options;
  final bool allowFreeWrite;
  QcmQuestion({
    required this.id,
    required this.title,
    required this.type,
    required this.options,
    this.allowFreeWrite = true,
  });
}

class QcmOption {
  final String label;
  final List<String> tags; // optionnel: pour ton mapping ultérieur
  QcmOption(this.label, {this.tags = const []});
}

/// QCM NEUTRE (sans IA).
/// - Questions factuelles (qui/quoi/où/quand/à qui)
/// - Paraphrases pré-écrites (anti-ennui)
/// - Toujours "Je ne sais pas" + "J'écris moi-même"
/// - Aucune "bonne" réponse n'est imposée
final _rnd = Random();

String _pick(List<String> variants) => variants[_rnd.nextInt(variants.length)];

List<QcmQuestion> buildDynamicQcm(String passageText) {
  // NB: si tu veux extraire quelques noms propres pour personnaliser,
  // tu peux détecter les mots Capitalisés (FR) — mais ce n'est pas obligatoire.
  // On reste neutre; on évite d'inférer du sens.

  final whoTitle = _pick([
    'Qui est mentionné dans le passage ?',
    'Quels personnages sont présents ?',
    'De qui parle ce texte ?',
  ]);

  final whatTitle = _pick([
    'Que se passe-t-il dans ce passage ?',
    'Quelles actions principales sont décrites ?',
    'Quels événements sont rapportés ?',
  ]);

  final whereTitle = _pick([
    'Où se déroule la scène ?',
    'Dans quel(s) lieu(x) cela se passe-t-il ?',
    'Quel est le cadre géographique ?',
  ]);

  final whenTitle = _pick([
    'À quel moment cela se passe-t-il ?',
    'Quel est l\'indice temporel (jour/heure/période) ?',
    'Le texte indique-t-il un moment précis ?',
  ]);

  final toWhomTitle = _pick([
    'À qui s\'adressent les paroles/gestes ?',
    'Qui est destinataire d\'une parole ou d\'une action ?',
    'Vers qui est dirigée l\'interaction ?',
  ]);

  // Options neutres génériques — l'utilisateur peut combiner + écrire sa propre réponse.
  List<QcmOption> neutralOptions(List<String> labels) => [
        ...labels.map((l) => QcmOption(l)),
        QcmOption('Je ne sais pas / pas sûr(e)'),
      ];

  return [
    QcmQuestion(
      id: 'who',
      title: whoTitle,
      type: QcmType.multi,
      options: neutralOptions([
        'Personnages principaux identifiés',
        'Personnages secondaires mentionnés',
        'Groupe ou foule',
        'Aucun nom explicite',
      ]),
      allowFreeWrite: true,
    ),
    QcmQuestion(
      id: 'what',
      title: whatTitle,
      type: QcmType.multi,
      options: neutralOptions([
        'Dialogue / parole échangée',
        'Action concrète (déplacement, geste…)',
        'Enseignement / déclaration',
        'Événement / situation décrite',
      ]),
      allowFreeWrite: true,
    ),
    QcmQuestion(
      id: 'where',
      title: whereTitle,
      type: QcmType.single,
      options: neutralOptions([
        'Lieu explicite (ville, maison, temple…)',
        'Lieu implicite (déduit du contexte)',
        'Lieu non précisé',
      ]),
      allowFreeWrite: true,
    ),
    QcmQuestion(
      id: 'when',
      title: whenTitle,
      type: QcmType.single,
      options: neutralOptions([
        'Moment explicite (heure/jour/fête)',
        'Période implicite (contexte)',
        'Aucune indication temporelle',
      ]),
      allowFreeWrite: true,
    ),
    QcmQuestion(
      id: 'to_whom',
      title: toWhomTitle,
      type: QcmType.multi,
      options: neutralOptions([
        'Une personne précise',
        'Un groupe précis',
        'Public indéterminé',
        'Non précisé',
      ]),
      allowFreeWrite: true,
    ),
  ];
}
