import 'anchored_doctrine_base.dart';

/// 🕊️ Crainte de Dieu (déjà vue)
class FearOfGodDoctrine extends AnchoredDoctrineModule {
  FearOfGodDoctrine() : super(
    id: 'fear_of_God',
    theme: 'Crainte de Dieu',
    focus: 'Révérence, sagesse, fidélité',
    keywords: ['crainte', 'craignez', 'révérence', 'respect', 'sagesse', 'sainteté'],
    anchors: const [
      {'ref':'Proverbes 1:7',    'why':'Commencement de la sagesse.'},
      {'ref':'Proverbes 9:10',   'why':'La vraie connaissance commence ici.'},
      {'ref':'Psaume 111:10',    'why':'Pensée saine pour ceux qui obéissent.'},
      {'ref':'Proverbes 19:23',  'why':'La crainte mène à la vie.'},
      {'ref':'Exode 20:20',      'why':'Elle nous détourne du péché.'},
      {'ref':'Ecclésiaste 12:13','why':'Résumé du devoir de l\'homme.'},
      {'ref':'Hébreux 12:28',    'why':'Culte avec piété et crainte.'},
      {'ref':'1 Pierre 1:17',    'why':'Se conduire avec crainte.'},
    ],
  );

  @override
  double intensity(DoctrineContext ctx) => ctx.weightFor(
    ['sagesse','sainteté','respect','révérence','discipline'],
    base: 1.0, bonus: .3,
  );
}

/// ✨ Sainteté
class HolinessDoctrine extends AnchoredDoctrineModule {
  HolinessDoctrine() : super(
    id: 'holiness',
    theme: 'Sainteté',
    focus: 'Consécration, pureté, obéissance',
    keywords: ['saint','sainteté','pur','pureté','consécration'],
    anchors: const [
      {'ref':'1 Pierre 1:15-16', 'why':'Soyez saints dans toute votre conduite.'},
      {'ref':'Hébreux 12:14',    'why':'Sans la sanctification, nul ne verra le Seigneur.'},
      {'ref':'Lévitique 19:2',   'why':'Soyez saints, car je suis saint.'},
      {'ref':'2 Corinthiens 7:1','why':'Parachever la sainteté dans la crainte de Dieu.'},
    ],
    baseEveryNDays: 6,
  );

  @override
  double intensity(DoctrineContext ctx) => ctx.weightFor(
    ['sainteté','pureté','consécration','repentance'],
    base: 1.0, bonus: .25,
  );
}

/// 🤝 Humilité
class HumilityDoctrine extends AnchoredDoctrineModule {
  HumilityDoctrine() : super(
    id: 'humility',
    theme: 'Humilité',
    focus: 'Abaissement, service, dépendance',
    keywords: ['humble','humilité','serviteur','abaissement'],
    anchors: const [
      {'ref':'Philippiens 2:3-8', 'why':'Esprit de service, modèle du Christ.'},
      {'ref':'Jacques 4:6',       'why':'Dieu résiste aux orgueilleux, fait grâce aux humbles.'},
      {'ref':'1 Pierre 5:5-6',    'why':'Humiliez-vous sous la puissante main de Dieu.'},
      {'ref':'Luc 18:13-14',      'why':'Le publicain justifié, pas le pharisien.'},
    ],
    baseEveryNDays: 6,
  );

  @override
  double intensity(DoctrineContext ctx) => ctx.weightFor(
    ['service','leader','orgueil','caractère','discipline'],
    base: .95, bonus: .25,
  );
}

/// 🎁 Grâce
class GraceDoctrine extends AnchoredDoctrineModule {
  GraceDoctrine() : super(
    id: 'grace',
    theme: 'Grâce',
    focus: 'Salut, faveur imméritée, transformation',
    keywords: ['grâce','faveur','miséricorde','justification'],
    anchors: const [
      {'ref':'Éphésiens 2:8-9', 'why':'Salut par grâce, non par les œuvres.'},
      {'ref':'Tite 2:11-12',    'why':'La grâce éduque à renoncer au péché.'},
      {'ref':'Romains 5:20-21', 'why':'Là où le péché a abondé…'},
      {'ref':'Hébreux 4:16',    'why':'S\'avancer avec assurance vers le trône de la grâce.'},
    ],
    baseEveryNDays: 5,
  );

  @override
  double intensity(DoctrineContext ctx) => ctx.weightFor(
    ['pardon','culpabilité','évangile','nouveau converti'],
    base: 1.0, bonus: .3,
  );
}

/// 🙏 Prière
class PrayerDoctrine extends AnchoredDoctrineModule {
  PrayerDoctrine() : super(
    id: 'prayer',
    theme: 'Prière',
    focus: 'Intimité, dépendance, persévérance',
    keywords: ['prière','prier','supplication','intercession','psaume'],
    anchors: const [
      {'ref':'1 Thessaloniciens 5:17','why':'Priez sans cesse.'},
      {'ref':'Matthieu 6:6-13',      'why':'Le Notre Père, cœur de la prière.'},
      {'ref':'Luc 11:1-13',          'why':'Apprends-nous à prier.'},
      {'ref':'Psaume 62:9',          'why':'Répandez votre cœur devant lui.'},
    ],
    baseEveryNDays: 4, // un peu plus fréquent
  );

  @override
  double intensity(DoctrineContext ctx) => ctx.weightFor(
    ['prière','méditation','psaumes','intimité','entendre Dieu'],
    base: 1.05, bonus: .35,
  );
}

/// 💡 Sagesse
class WisdomDoctrine extends AnchoredDoctrineModule {
  WisdomDoctrine() : super(
    id: 'wisdom',
    theme: 'Sagesse',
    focus: 'Discernement, crainte, conduite droite',
    keywords: ['sagesse','discernement','intelligence','prudence'],
    anchors: const [
      {'ref':'Jacques 1:5',     'why':'Demander la sagesse à Dieu.'},
      {'ref':'Proverbes 2:1-6', 'why':'La sagesse vient de l\'Éternel.'},
      {'ref':'Proverbes 3:5-7', 'why':'Ne t\'appuie pas sur ta sagesse.'},
      {'ref':'Colossiens 3:16', 'why':'La Parole habite richement en vous.'},
    ],
    baseEveryNDays: 5,
  );

  @override
  double intensity(DoctrineContext ctx) => ctx.weightFor(
    ['sagesse','décision','proverbes','étude biblique'],
    base: 1.0, bonus: .25,
  );
}
