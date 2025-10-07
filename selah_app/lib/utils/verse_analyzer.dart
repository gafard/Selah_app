import 'dart:math';

/// Classe utilitaire pour analyser le texte saisi et trouver le verset exact correspondant
class VerseAnalyzer {
  
  /// Base de données de versets populaires avec leurs références
  static final Map<String, List<Map<String, String>>> _verseDatabase = {
    'jean': [
      {
        'text': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
        'ref': 'Jean 3:16'
      },
      {
        'text': 'Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.',
        'ref': 'Jean 14:6'
      },
      {
        'text': 'Que votre cœur ne se trouble point. Croyez en Dieu, et croyez en moi.',
        'ref': 'Jean 14:1'
      },
      {
        'text': 'Il y a plusieurs demeures dans la maison de mon Père. Si cela n\'était pas, je vous l\'aurais dit. Je vais vous préparer une place.',
        'ref': 'Jean 14:2'
      },
      {
        'text': 'Si vous m\'aimez, gardez mes commandements.',
        'ref': 'Jean 14:15'
      },
      {
        'text': 'Je ne vous laisserai pas orphelins, je viendrai à vous.',
        'ref': 'Jean 14:18'
      },
    ],
    'psaume': [
      {
        'text': 'L\'Éternel est mon berger: je ne manquerai de rien.',
        'ref': 'Psaume 23:1'
      },
      {
        'text': 'Il me fait reposer dans de verts pâturages, Il me dirige près des eaux paisibles.',
        'ref': 'Psaume 23:2'
      },
      {
        'text': 'Ta parole est une lampe à mes pieds, et une lumière sur mon sentier.',
        'ref': 'Psaume 119:105'
      },
      {
        'text': 'L\'Éternel est ma lumière et mon salut: De qui aurais-je peur?',
        'ref': 'Psaume 27:1'
      },
      {
        'text': 'Cherchez l\'Éternel et sa force, Cherchez continuellement sa face!',
        'ref': 'Psaume 105:4'
      },
    ],
    'matthieu': [
      {
        'text': 'Heureux les pauvres en esprit, car le royaume des cieux est à eux!',
        'ref': 'Matthieu 5:3'
      },
      {
        'text': 'Heureux les affligés, car ils seront consolés!',
        'ref': 'Matthieu 5:4'
      },
      {
        'text': 'Heureux les débonnaires, car ils hériteront la terre!',
        'ref': 'Matthieu 5:5'
      },
      {
        'text': 'Heureux ceux qui ont faim et soif de la justice, car ils seront rassasiés!',
        'ref': 'Matthieu 5:6'
      },
      {
        'text': 'Heureux les miséricordieux, car ils obtiendront miséricorde!',
        'ref': 'Matthieu 5:7'
      },
      {
        'text': 'Heureux ceux qui ont le cœur pur, car ils verront Dieu!',
        'ref': 'Matthieu 5:8'
      },
      {
        'text': 'Heureux ceux qui procurent la paix, car ils seront appelés fils de Dieu!',
        'ref': 'Matthieu 5:9'
      },
      {
        'text': 'Heureux ceux qui sont persécutés pour la justice, car le royaume des cieux est à eux!',
        'ref': 'Matthieu 5:10'
      },
    ],
    'romains': [
      {
        'text': 'Car tous ont péché et sont privés de la gloire de Dieu.',
        'ref': 'Romains 3:23'
      },
      {
        'text': 'Car le salaire du péché, c\'est la mort; mais le don gratuit de Dieu, c\'est la vie éternelle en Jésus-Christ notre Seigneur.',
        'ref': 'Romains 6:23'
      },
      {
        'text': 'Nous savons, du reste, que toutes choses concourent au bien de ceux qui aiment Dieu, de ceux qui sont appelés selon son dessein.',
        'ref': 'Romains 8:28'
      },
      {
        'text': 'Si Dieu est pour nous, qui sera contre nous?',
        'ref': 'Romains 8:31'
      },
    ],
    'proverbes': [
      {
        'text': 'La crainte de l\'Éternel est le commencement de la science; Les insensés méprisent la sagesse et l\'instruction.',
        'ref': 'Proverbes 1:7'
      },
      {
        'text': 'Confie-toi en l\'Éternel de tout ton cœur, Et ne t\'appuie pas sur ta sagesse.',
        'ref': 'Proverbes 3:5'
      },
      {
        'text': 'Reconnais-le dans toutes tes voies, Et il aplanira tes sentiers.',
        'ref': 'Proverbes 3:6'
      },
    ],
    'esai': [
      {
        'text': 'Car un enfant nous est né, un fils nous est donné, Et la domination reposera sur son épaule; On l\'appellera Admirable, Conseiller, Dieu puissant, Père éternel, Prince de la paix.',
        'ref': 'Ésaïe 9:6'
      },
      {
        'text': 'Mais ceux qui se confient en l\'Éternel renouvellent leur force. Ils prennent le vol comme les aigles; Ils courent, et ne se lassent point, Ils marchent, et ne se fatiguent point.',
        'ref': 'Ésaïe 40:31'
      },
    ],
    'jeremie': [
      {
        'text': 'Car je connais les projets que j\'ai sur vous, dit l\'Éternel, projets de paix et non de malheur, afin de vous donner un avenir et de l\'espérance.',
        'ref': 'Jérémie 29:11'
      },
    ],
    'philippiens': [
      {
        'text': 'Je puis tout par celui qui me fortifie.',
        'ref': 'Philippiens 4:13'
      },
      {
        'text': 'Et la paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus-Christ.',
        'ref': 'Philippiens 4:7'
      },
    ],
    'corinthiens': [
      {
        'text': 'L\'amour est patient, il est plein de bonté; l\'amour n\'est point envieux; l\'amour ne se vante point, il ne s\'enfle point d\'orgueil.',
        'ref': '1 Corinthiens 13:4'
      },
      {
        'text': 'L\'amour ne fait rien de malhonnête, il ne cherche point son intérêt, il ne s\'irrite point, il ne soupçonne point le mal.',
        'ref': '1 Corinthiens 13:5'
      },
    ],
  };

  /// Analyse le texte saisi par l'utilisateur et trouve le verset exact correspondant
  static Map<String, String> analyzeUserText(String userText) {
    if (userText.trim().isEmpty) {
      return {
        'text': 'Ta parole est une lampe à mes pieds, et une lumière sur mon sentier.',
        'ref': 'Psaume 119:105'
      };
    }

    final text = userText.toLowerCase().trim();
    
    // Recherche par similarité de texte
    double bestMatch = 0.0;
    Map<String, String> bestVerse = {
      'text': 'Ta parole est une lampe à mes pieds, et une lumière sur mon sentier.',
      'ref': 'Psaume 119:105'
    };

    // Parcourir tous les versets
    for (final book in _verseDatabase.values) {
      for (final verse in book) {
        final verseText = verse['text']!.toLowerCase();
        final similarity = _calculateSimilarity(text, verseText);
        
        if (similarity > bestMatch) {
          bestMatch = similarity;
          bestVerse = verse;
        }
      }
    }

    // Si la similarité est trop faible (< 30%), retourner un verset par défaut
    if (bestMatch < 0.3) {
      return _getDefaultVerse();
    }

    return bestVerse;
  }

  /// Choisit un verset intelligent basé sur les réponses de méditation
  static Map<String, String> chooseVerseFromMeditation({
    required Map<String, Set<String>> selectedTagsByField,
    required Map<String, Set<String>> selectedAnswersByField,
    required Map<String, String> freeTextResponses,
    String? passageRef,
    String? passageText,
  }) {
    // Analyser les thèmes dominants
    final themes = <String, int>{};
    
    // Compter les occurrences de chaque thème
    for (final tags in selectedTagsByField.values) {
      for (final tag in tags) {
        themes[tag] = (themes[tag] ?? 0) + 1;
      }
    }

    // Analyser le texte libre pour des mots-clés
    for (final text in freeTextResponses.values) {
      final lowerText = text.toLowerCase();
      if (lowerText.contains('foi') || lowerText.contains('croire')) {
        themes['trust'] = (themes['trust'] ?? 0) + 2;
      }
      if (lowerText.contains('amour') || lowerText.contains('aimer')) {
        themes['love'] = (themes['love'] ?? 0) + 2;
      }
      if (lowerText.contains('paix') || lowerText.contains('calme')) {
        themes['peace'] = (themes['peace'] ?? 0) + 2;
      }
      if (lowerText.contains('force') || lowerText.contains('puissance')) {
        themes['strength'] = (themes['strength'] ?? 0) + 2;
      }
      if (lowerText.contains('sagesse') || lowerText.contains('comprendre')) {
        themes['wisdom'] = (themes['wisdom'] ?? 0) + 2;
      }
    }

    // Si on a le texte du passage, extraire les versets et choisir selon le thème
    if (passageText != null && passageText.isNotEmpty) {
      final passageVerses = _extractVersesFromPassage(passageText, passageRef);
      final dominantTheme = themes.isNotEmpty 
          ? themes.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'default';
      
      return _chooseVerseFromPassage(passageVerses, dominantTheme, passageRef);
    }

    // Fallback vers l'ancienne logique si pas de passage
    final dominantTheme = themes.isNotEmpty 
        ? themes.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'default';

    switch (dominantTheme) {
      case 'trust':
      case 'faith':
        return {
          'text': 'Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.',
          'ref': 'Jean 14:6'
        };
      
      case 'love':
        return {
          'text': 'L\'amour est patient, il est plein de bonté; l\'amour n\'est point envieux; l\'amour ne se vante point, il ne s\'enfle point d\'orgueil.',
          'ref': '1 Corinthiens 13:4'
        };
      
      case 'peace':
        return {
          'text': 'Et la paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus-Christ.',
          'ref': 'Philippiens 4:7'
        };
      
      case 'strength':
        return {
          'text': 'Je puis tout par celui qui me fortifie.',
          'ref': 'Philippiens 4:13'
        };
      
      case 'wisdom':
        return {
          'text': 'Confie-toi en l\'Éternel de tout ton cœur, Et ne t\'appuie pas sur ta sagesse.',
          'ref': 'Proverbes 3:5'
        };
      
      case 'praise':
      case 'gratitude':
        return {
          'text': 'L\'Éternel est ma lumière et mon salut: De qui aurais-je peur?',
          'ref': 'Psaume 27:1'
        };
      
      case 'repentance':
        return {
          'text': 'Car tous ont péché et sont privés de la gloire de Dieu.',
          'ref': 'Romains 3:23'
        };
      
      case 'obedience':
        return {
          'text': 'Si vous m\'aimez, gardez mes commandements.',
          'ref': 'Jean 14:15'
        };
      
      case 'promise':
        return {
          'text': 'Car je connais les projets que j\'ai sur vous, dit l\'Éternel, projets de paix et non de malheur, afin de vous donner un avenir et de l\'espérance.',
          'ref': 'Jérémie 29:11'
        };
      
      default:
        return _getDefaultVerse();
    }
  }

  /// Calcule la similarité entre deux textes (algorithme simple)
  static double _calculateSimilarity(String text1, String text2) {
    final words1 = text1.split(' ');
    final words2 = text2.split(' ');
    
    int matches = 0;
    int totalWords = max(words1.length, words2.length);
    
    for (final word1 in words1) {
      for (final word2 in words2) {
        if (word1 == word2 || _isSimilarWord(word1, word2)) {
          matches++;
          break;
        }
      }
    }
    
    return totalWords > 0 ? matches / totalWords : 0.0;
  }

  /// Vérifie si deux mots sont similaires (variations, pluriels, etc.)
  static bool _isSimilarWord(String word1, String word2) {
    // Mots très courts
    if (word1.length < 3 || word2.length < 3) return false;
    
    // Correspondance exacte
    if (word1 == word2) return true;
    
    // Correspondance partielle (au moins 70% des caractères)
    final longer = word1.length > word2.length ? word1 : word2;
    final shorter = word1.length > word2.length ? word2 : word1;
    
    if (longer.isEmpty) return true;
    
    final distance = _levenshteinDistance(longer, shorter);
    return (longer.length - distance) / longer.length > 0.7;
  }

  /// Calcule la distance de Levenshtein entre deux chaînes
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Extrait les versets individuels du passage
  static List<Map<String, String>> _extractVersesFromPassage(String passageText, String? passageRef) {
    final verses = <Map<String, String>>[];
    final lines = passageText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    // Pour Jean 14:1-19, on va créer des versets basés sur le contenu
    if (passageRef?.contains('Jean 14') == true) {
      return _getJean14Verses();
    }
    
    // Pour d'autres passages, essayer de détecter les versets
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        // Essayer de détecter le numéro de verset
        final verseMatch = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line);
        if (verseMatch != null) {
          final verseNum = verseMatch.group(1)!;
          final verseText = verseMatch.group(2)!;
          verses.add({
            'text': verseText,
            'ref': '${passageRef?.split(':')[0] ?? 'Passage'}:$verseNum'
          });
        } else {
          // Si pas de numéro, traiter comme un verset continu
          verses.add({
            'text': line,
            'ref': '${passageRef?.split(':')[0] ?? 'Passage'}:${i + 1}'
          });
        }
      }
    }
    
    return verses.isNotEmpty ? verses : _getDefaultVerses();
  }

  /// Versets spécifiques de Jean 14:1-19
  static List<Map<String, String>> _getJean14Verses() {
    return [
      {
        'text': 'Que votre cœur ne se trouble point. Croyez en Dieu, et croyez en moi.',
        'ref': 'Jean 14:1'
      },
      {
        'text': 'Il y a plusieurs demeures dans la maison de mon Père. Si cela n\'était pas, je vous l\'aurais dit. Je vais vous préparer une place.',
        'ref': 'Jean 14:2'
      },
      {
        'text': 'Et, lorsque je m\'en serai allé, et que je vous aurai préparé une place, je reviendrai, et je vous prendrai avec moi, afin que là où je suis vous y soyez aussi.',
        'ref': 'Jean 14:3'
      },
      {
        'text': 'Vous savez où je vais, et vous en savez le chemin.',
        'ref': 'Jean 14:4'
      },
      {
        'text': 'Thomas lui dit: Seigneur, nous ne savons où tu vas; comment pouvons-nous en savoir le chemin?',
        'ref': 'Jean 14:5'
      },
      {
        'text': 'Jésus lui dit: Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.',
        'ref': 'Jean 14:6'
      },
      {
        'text': 'Si vous me connaissiez, vous connaîtriez aussi mon Père. Et dès maintenant vous le connaissez, et vous l\'avez vu.',
        'ref': 'Jean 14:7'
      },
      {
        'text': 'Philippe lui dit: Seigneur, montre-nous le Père, et cela nous suffit.',
        'ref': 'Jean 14:8'
      },
      {
        'text': 'Jésus lui dit: Il y a si longtemps que je suis avec vous, et tu ne m\'as pas connu, Philippe! Celui qui m\'a vu a vu le Père; comment dis-tu: Montre-nous le Père?',
        'ref': 'Jean 14:9'
      },
      {
        'text': 'Ne crois-tu pas que je suis dans le Père, et que le Père est en moi? Les paroles que je vous dis, je ne les dis pas de moi-même; et le Père qui demeure en moi, c\'est lui qui fait les œuvres.',
        'ref': 'Jean 14:10'
      },
      {
        'text': 'Croyez-moi, je suis dans le Père, et le Père est en moi; croyez du moins à cause de ces œuvres.',
        'ref': 'Jean 14:11'
      },
      {
        'text': 'En vérité, en vérité, je vous le dis, celui qui croit en moi fera aussi les œuvres que je fais, et il en fera de plus grandes, parce que je m\'en vais au Père.',
        'ref': 'Jean 14:12'
      },
      {
        'text': 'Et tout ce que vous demanderez en mon nom, je le ferai, afin que le Père soit glorifié dans le Fils.',
        'ref': 'Jean 14:13'
      },
      {
        'text': 'Si vous demandez quelque chose en mon nom, je le ferai.',
        'ref': 'Jean 14:14'
      },
      {
        'text': 'Si vous m\'aimez, gardez mes commandements.',
        'ref': 'Jean 14:15'
      },
      {
        'text': 'Et moi, je prierai le Père, et il vous donnera un autre consolateur, afin qu\'il demeure éternellement avec vous.',
        'ref': 'Jean 14:16'
      },
      {
        'text': 'l\'Esprit de vérité, que le monde ne peut recevoir, parce qu\'il ne le voit point et ne le connaît point; mais vous, vous le connaissez, car il demeure avec vous, et il sera en vous.',
        'ref': 'Jean 14:17'
      },
      {
        'text': 'Je ne vous laisserai pas orphelins, je viendrai à vous.',
        'ref': 'Jean 14:18'
      },
      {
        'text': 'Encore un peu de temps, et le monde ne me verra plus; mais vous, vous me verrez, car je vis, et vous vivrez aussi.',
        'ref': 'Jean 14:19'
      },
    ];
  }

  /// Choisit un verset du passage selon le thème dominant
  static Map<String, String> _chooseVerseFromPassage(
    List<Map<String, String>> passageVerses, 
    String dominantTheme, 
    String? passageRef
  ) {
    // Mapping des thèmes vers des mots-clés dans les versets
    final themeKeywords = {
      'trust': ['croyez', 'croit', 'foi', 'confiance'],
      'faith': ['croyez', 'croit', 'foi', 'confiance'],
      'love': ['aimez', 'amour', 'aimer'],
      'peace': ['paix', 'trouble', 'cœur'],
      'obedience': ['commandements', 'obéir', 'gardez'],
      'promise': ['promesse', 'donnera', 'fera', 'viendrai'],
      'praise': ['gloire', 'glorifié', 'louange'],
      'wisdom': ['connaissez', 'connaître', 'sagesse', 'vérité'],
      'comfort': ['consolateur', 'orphelins', 'demeure'],
      'prayer': ['demanderez', 'prierai', 'prière'],
      'works': ['œuvres', 'faire', 'service'],
    };

    // Chercher le verset qui correspond le mieux au thème
    for (final theme in [dominantTheme, 'default']) {
      final keywords = themeKeywords[theme] ?? [];
      
      for (final verse in passageVerses) {
        final verseText = verse['text']!.toLowerCase();
        
        // Vérifier si le verset contient des mots-clés du thème
        for (final keyword in keywords) {
          if (verseText.contains(keyword)) {
            print('🔍 VERSET CHOISI pour thème "$theme" avec mot-clé "$keyword": "${verse['text']}" (${verse['ref']})');
            return verse;
          }
        }
      }
    }

    // Si aucun verset ne correspond, choisir un verset central du passage
    final middleIndex = passageVerses.length ~/ 2;
    final defaultVerse = passageVerses[middleIndex];
    print('🔍 VERSET PAR DÉFAUT (milieu du passage): "${defaultVerse['text']}" (${defaultVerse['ref']})');
    return defaultVerse;
  }

  /// Retourne des versets par défaut
  static List<Map<String, String>> _getDefaultVerses() {
    return [
      {
        'text': 'Ta parole est une lampe à mes pieds, et une lumière sur mon sentier.',
        'ref': 'Psaume 119:105'
      },
      {
        'text': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
        'ref': 'Jean 3:16'
      },
      {
        'text': 'Je puis tout par celui qui me fortifie.',
        'ref': 'Philippiens 4:13'
      },
    ];
  }

  /// Retourne un verset par défaut
  static Map<String, String> _getDefaultVerse() {
    final defaultVerses = _getDefaultVerses();
    final random = Random();
    return defaultVerses[random.nextInt(defaultVerses.length)];
  }
}
