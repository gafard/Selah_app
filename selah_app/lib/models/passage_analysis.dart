import 'dart:math';

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

  // Liste de lieux géographiques bibliques connus
  final knownPlaces = {
    'Pont', 'Galatie', 'Cappadoce', 'Asie', 'Bithynie', 'Jérusalem', 'Galilée', 
    'Juda', 'Samarie', 'Béthanie', 'Capharnaüm', 'Nazareth', 'Jéricho',
    'Antioche', 'Corinthe', 'Éphèse', 'Rome', 'Alexandrie', 'Damas',
    'Tarse', 'Philippes', 'Colosses', 'Laodicée', 'Sardes', 'Thyatire',
    'Pergame', 'Smyrne', 'Philadelphie', 'Patmos', 'Chypre', 'Crète',
    'Macédoine', 'Achaïe', 'Illyrie', 'Espagne', 'Pamphylie',
    'Pisidie', 'Lycaonie', 'Phrygie', 'Mysie', 'Troas', 'Milet',
    'Césarée', 'Césarée de Philippe', 'Tyr', 'Sidon', 'Décapole',
    'Pérée', 'Idumée', 'Trachonitide', 'Iturée', 'Abilène'
  };

  // Liste de noms de personnages bibliques connus
  final knownPeople = {
    'Pierre', 'Paul', 'Jean', 'Jacques', 'André', 'Philippe', 'Barthélemy',
    'Thomas', 'Matthieu', 'Simon', 'Judas', 'Jésus', 'Christ', 'Messie',
    'Marie', 'Joseph', 'Anne', 'Élisabeth', 'Zacharie', 'Jean-Baptiste',
    'Hérode', 'Pilate', 'Caïphe', 'Annas', 'Nicodème', 'Joseph d\'Arimathée',
    'Lazare', 'Marthe', 'Marie de Magdala', 'Salomé', 'Cléopas', 'Emmaüs',
    'Barnabas', 'Silas', 'Timothée', 'Tite', 'Onésime', 'Épaphras',
    'Archippe', 'Philémon', 'Tychique', 'Trophime', 'Démas', 'Luc',
    'Marc', 'Apollos', 'Aquilas', 'Priscille', 'Lydie', 'Dorcas',
    'Étienne', 'Corneille', 'Agrippa', 'Bérénice', 'Festus',
    'Gamaliel', 'Saül', 'Ananias', 'Saphira', 'Simon le magicien',
    'Élymas'
  };

  // Liste de mots à exclure (adjectifs, verbes, etc.)
  final excludedWords = {
    'les', 'le', 'la', 'des', 'de', 'du', 'dans', 'sur', 'avec', 'pour', 'par',
    'c\'est', 'ce', 'cette', 'ces', 'son', 'sa', 'ses', 'leur', 'leurs',
    'bénit', 'béni', 'bénie', 'bénies', 'bénis', 'bénits',
    'saint', 'sainte', 'saints', 'saintes', 'sainteté',
    'juste', 'justes', 'justice', 'justification',
    'fidèle', 'fidèles', 'fidélité', 'fidèlement',
    'humble', 'humbles', 'humilité', 'humblement',
    'pur', 'pure', 'purs', 'pures', 'pureté', 'purifier',
    'sacré', 'sacrée', 'sacrés', 'sacrées', 'sacrément',
    'divin', 'divine', 'divins', 'divines', 'divinité',
    'éternel', 'éternelle', 'éternels', 'éternelles', 'éternité',
    'parfait', 'parfaite', 'parfaits', 'parfaites', 'perfection',
    'gracieux', 'gracieuse', 'gracieuses', 'grâce',
    'miséricordieux', 'miséricordieuse', 'miséricordieuses',
    'compassion', 'compassionnel', 'compassionnelle',
    'amour', 'aimer', 'aimé', 'aimée', 'aimés', 'aimées',
    'foi', 'croire', 'cru', 'crue', 'crus', 'crues',
    'espérance', 'espérer', 'espéré', 'espérée', 'espérés', 'espérées',
    'paix', 'pacifique', 'pacifiquement',
    'joie', 'joyeux', 'joyeuse', 'joyeusement',
    'sagesse', 'sage', 'sagement',
    'force', 'fort', 'forte', 'fortement',
    'puissance', 'puissant', 'puissante', 'puissamment',
    'gloire', 'glorieux', 'glorieuse', 'glorieusement',
    'honneur', 'honorable', 'honorablement',
    'dignité', 'digne', 'dignement',
    'respect', 'respectable', 'respectueux', 'respectueuse',
    'obéissance', 'obéir', 'obéi', 'obéie', 'obéissant', 'obéissante',
    'soumission', 'soumettre', 'soumis', 'soumise', 'soumissionnaire',
    'servir', 'servi', 'servie', 'serviteur', 'servante',
    'ministère', 'ministre', 'ministériel', 'ministérielle',
    'apostolat', 'apostolique', 'apostoliquement',
    'évangélique', 'évangéliquement', 'évangélisation',
    'mission', 'missionnaire', 'missionnel', 'missionnelle',
    'témoignage', 'témoigner', 'témoin', 'témoins',
    'prophétie', 'prophète', 'prophétique', 'prophétiquement',
    'révélation', 'révéler', 'révélé', 'révélée', 'révélateur',
    'inspiration', 'inspirer', 'inspiré', 'inspirée', 'inspirateur',
    'souffrance', 'souffrir', 'souffert', 'souffrante', 'souffrant',
    'persécution', 'persécuter', 'persécuté', 'persécutée', 'persécuteur',
    'tribulation', 'tribuler', 'tribulé', 'tribulée',
    'épreuve', 'éprouver', 'éprouvé', 'éprouvée', 'éprouvant',
    'tentation', 'tenter', 'tenté', 'tentée', 'tentateur',
    'péché', 'pécher', 'pécheur', 'pécheresse', 'pécheurs',
    'repentance', 'se repentir', 'repenti', 'repentie',
    'conversion', 'se convertir', 'converti', 'convertie',
    'rédemption', 'rédempteur', 'rédemptrice',
    'salut', 'sauver', 'sauvé', 'sauvée', 'sauveur',
    'régénération', 'régénérer', 'régénéré', 'régénérée',
    'sanctification', 'sanctifier', 'sanctifié', 'sanctifiée',
    'consécration', 'consacrer', 'consacré', 'consacrée',
    'vocation', 'appeler', 'appelé', 'appelée', 'vocational',
    'élection', 'élire', 'élu', 'élue', 'électeur',
    'prédestination', 'prédestiner', 'prédestiné', 'prédestinée',
    'adoption', 'adopter', 'adopté', 'adoptée', 'adoptif',
    'héritage', 'hériter', 'hérité', 'héritée', 'héritier',
    'promesse', 'promettre', 'promis', 'promise', 'prometteur',
    'alliance', 'allier', 'allié', 'alliée',
    'covenant', 'covenanter', 'covenanté', 'covenantée',
    'testament', 'testamentaire', 'testamentairement',
    'nouveau', 'nouvelle', 'nouveaux', 'nouvelles', 'nouvellement',
    'ancien', 'ancienne', 'anciens', 'anciennes', 'anciennement',
    'premier', 'première', 'premiers', 'premières', 'premièrement',
    'dernier', 'dernière', 'derniers', 'dernières', 'dernièrement',
    'seul', 'seule', 'seuls', 'seules', 'seulement',
    'unique', 'uniquement', 'unicité',
    'multiple', 'multiples', 'multiplicité',
    'commun', 'commune', 'communs', 'communes', 'communément',
    'particulier', 'particulière', 'particuliers', 'particulières',
    'spécial', 'spéciale', 'spéciaux', 'spéciales', 'spécialement',
    'général', 'générale', 'généraux', 'générales', 'généralement',
    'universel', 'universelle', 'universels', 'universelles',
    'local', 'locale', 'locaux', 'locales', 'localement',
    'national', 'nationale', 'nationaux', 'nationales',
    'international', 'internationale', 'internationaux', 'internationales',
    'mondial', 'mondiale', 'mondiaux', 'mondiales', 'mondialement',
    'temporaire', 'temporairement', 'temporalité',
    'permanent', 'permanente', 'permanents', 'permanentes', 'permanemment',
    'spirituel', 'spirituelle', 'spirituels', 'spirituelles', 'spirituellement',
    'matériel', 'matérielle', 'matériels', 'matérielles', 'matériellement',
    'physique', 'physiquement', 'physicalité',
    'mental', 'mentale', 'mentaux', 'mentales', 'mentalement',
    'émotionnel', 'émotionnelle', 'émotionnels', 'émotionnelles',
    'intellectuel', 'intellectuelle', 'intellectuels', 'intellectuelles',
    'moral', 'morale', 'moraux', 'morales', 'moralement',
    'éthique', 'éthiquement', 'éthicité',
    'légitime', 'légitimement', 'légitimité',
    'droit', 'droite', 'droits', 'droites', 'droiture',
    'équitable', 'équitablement', 'équité',
    'impartial', 'impartiale', 'impartiaux', 'impartiales', 'impartialement',
    'objectif', 'objective', 'objectifs', 'objectives', 'objectivement',
    'subjectif', 'subjective', 'subjectifs', 'subjectives', 'subjectivement',
    'personnel', 'personnelle', 'personnels', 'personnelles', 'personnellement',
    'individuel', 'individuelle', 'individuels', 'individuelles', 'individuellement',
    'collectif', 'collective', 'collectifs', 'collectives', 'collectivement',
    'social', 'sociale', 'sociaux', 'sociales', 'socialement',
    'communautaire', 'communautairement', 'communauté',
    'ecclésial', 'ecclésiale', 'ecclésiaux', 'ecclésiales', 'ecclésialement',
    'religieux', 'religieuse', 'religieuses', 'religieusement',
    'profane', 'profanes', 'profanement',
    'laïc', 'laïque', 'laïcs', 'laïques', 'laïquement',
    'séculier', 'séculière', 'séculiers', 'séculières', 'séculièrement',
    'temporel', 'temporelle', 'temporels', 'temporelles', 'temporellement',
    'humain', 'humaine', 'humains', 'humaines', 'humainement',
    'céleste', 'célestes', 'célestement', 'célestité',
    'terrestre', 'terrestres', 'terrestrement', 'terrestrité',
    'visible', 'visibles', 'visiblement', 'visibilité',
    'invisible', 'invisibles', 'invisiblement', 'invisibilité',
    'apparent', 'apparente', 'apparents', 'apparentes', 'apparemment',
    'caché', 'cachée', 'cachés', 'cachées', 'cachément',
    'secret', 'secrète', 'secrets', 'secrètes', 'secrètement',
    'public', 'publique', 'publics', 'publiques', 'publiquement',
    'privé', 'privée', 'privés', 'privées', 'privément',
    'ouvert', 'ouverte', 'ouverts', 'ouvertes', 'ouvertement',
    'fermé', 'fermée', 'fermés', 'fermées', 'fermement',
    'libre', 'libres', 'librement', 'liberté',
    'esclave', 'esclaves', 'esclavement', 'esclavage',
    'maître', 'maîtres', 'maîtresse', 'maîtresses', 'maîtriser',
    'seigneur', 'seigneurs', 'seigneurie', 'seigneurial',
    'roi', 'rois', 'royal', 'royale', 'royaux', 'royales', 'royalement',
    'reine', 'reines', 'régal', 'régale', 'régaux', 'régales',
    'prince', 'princes', 'princesse', 'princesses', 'princier',
    'noble', 'nobles', 'noblesse', 'noblement',
    'pauvre', 'pauvres', 'pauvreté', 'pauvrement',
    'riche', 'riches', 'richesse', 'richement',
    'faible', 'faibles', 'faiblesse', 'faiblement',
    'grand', 'grande', 'grands', 'grandes', 'grandeur', 'grandement',
    'petit', 'petite', 'petits', 'petites', 'petitesse', 'petitement',
    'haut', 'haute', 'hauts', 'hautes', 'hauteur', 'hautement',
    'bas', 'basse', 'basses', 'bassesse', 'bassement',
    'profond', 'profonde', 'profonds', 'profondes', 'profondeur', 'profondément',
    'superficiel', 'superficielle', 'superficiels', 'superficielles', 'superficiellement',
    'large', 'larges', 'largeur', 'largement',
    'étroit', 'étroite', 'étroits', 'étroites', 'étroitesse', 'étroitement',
    'long', 'longue', 'longs', 'longues', 'longueur', 'longuement',
    'court', 'courte', 'courts', 'courtes', 'brièveté', 'brièvement',
    'rapide', 'rapides', 'rapidité', 'rapidement',
    'lent', 'lente', 'lents', 'lentes', 'lenteur', 'lentement',
    'vite', 'vitesse',
    'tard', 'tardif', 'tardive', 'tardifs', 'tardives', 'tardivement',
    'tôt', 'précoce', 'précocement', 'précocité',
    'jeune', 'jeunes', 'jeunesse', 'jeunement',
    'vieux', 'vieille', 'vieilles', 'vieillesse', 'vieillement',
    'moderne', 'modernes', 'modernité', 'modernement',
    'traditionnel', 'traditionnelle', 'traditionnels', 'traditionnelles', 'traditionnellement',
    'contemporain', 'contemporaine', 'contemporains', 'contemporaines', 'contemporainement',
    'actuel', 'actuelle', 'actuels', 'actuelles', 'actuellement',
    'présent', 'présente', 'présents', 'présentes', 'présentement',
    'passé', 'passée', 'passés', 'passées',
    'futur', 'future', 'futurs', 'futures',
    'constant', 'constante', 'constants', 'constantes', 'constamment',
    'variable', 'variables', 'variabilité', 'variablement',
    'stable', 'stables', 'stabilité', 'stablement',
    'instable', 'instables', 'instabilité', 'instablement',
    'fixe', 'fixes', 'fixité', 'fixement',
    'mobile', 'mobiles', 'mobilité', 'mobilement',
    'immobile', 'immobiles', 'immobilité', 'immobilement',
    'mouvement', 'mouvements', 'mouvementé', 'mouvementée', 'mouvementément',
    'repos', 'reposer', 'reposé', 'reposée', 'reposément',
    'tranquille', 'tranquilles', 'tranquillité', 'tranquillement',
    'agité', 'agitée', 'agités', 'agitées', 'agitation', 'agitement',
    'calme', 'calmes', 'calmement', 'calmer',
    'bruyant', 'bruyante', 'bruyants', 'bruyantes', 'bruit', 'bruyamment',
    'silencieux', 'silencieuse', 'silencieuses', 'silence', 'silencieusement',
    'sonore', 'sonores', 'sonorité', 'sonorement',
    'muet', 'muette', 'muets', 'muettes', 'mutisme', 'muettement',
    'parlant', 'parlante', 'parlants', 'parlantes', 'parole', 'parlantement'
  };

  // Heuristique améliorée : distinguer personnages et lieux
  for (final t in tokens) {
    final trimmed = t.trim();
    if (trimmed.length >= 3 && 
        trimmed[0].toUpperCase() == trimmed[0] && 
        trimmed.substring(1).toLowerCase() == trimmed.substring(1)) {
      
      // Exclure d'abord les mots non-personnages
      if (excludedWords.contains(trimmed.toLowerCase())) {
        continue; // Ignorer ce mot
      }
      
      // Vérifier d'abord si c'est un lieu connu
      if (knownPlaces.contains(trimmed)) {
        places.add(trimmed);
      }
      // Sinon, vérifier si c'est un personnage connu
      else if (knownPeople.contains(trimmed)) {
        people.add(trimmed);
      }
      // Pour les autres mots capitalisés, utiliser des indices contextuels
      else {
        // Si le mot apparaît dans un contexte géographique (près de "dans", "à", "de", etc.)
        final context = text.toLowerCase();
        final wordIndex = context.indexOf(trimmed.toLowerCase());
        if (wordIndex > 0) {
          final beforeWord = context.substring(max(0, wordIndex - 20), wordIndex);
          final afterWord = context.substring(wordIndex + trimmed.length, 
              min(context.length, wordIndex + trimmed.length + 20));
          
          // Indices géographiques
          if (beforeWord.contains(' dans ') || beforeWord.contains(' à ') || 
              beforeWord.contains(' de ') || beforeWord.contains(' en ') ||
              afterWord.contains(' de ') || afterWord.contains(' dans ') ||
              afterWord.contains(' à ') || afterWord.contains(' en ')) {
            places.add(trimmed);
          }
          // Sinon, considérer comme personnage seulement si ce n'est pas un mot exclu
          else if (!excludedWords.contains(trimmed.toLowerCase())) {
      people.add(trimmed);
          }
        }
      }
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