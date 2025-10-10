import 'dart:math';

/// Service de génération aléatoire stable basé sur un seed
/// 
/// Permet de générer des variations apparemment aléatoires mais reproductibles
/// pour le même planId, assurant une expérience cohérente et stable.
/// 
/// Use cases :
/// - Variation des sous-périmètres de lecture sans changer l'équilibre
/// - Sélection stable des passages de méditation
/// - Distribution stable des types de questions
/// - Ordre stable des recommandations
/// 
/// Exemple :
/// ```dart
/// final random = StableRandomService.forPlan('plan_123');
/// final variation = random.nextInt(10); // Toujours le même pour plan_123
/// ```
class StableRandomService {
  final Random _random;
  final String _seed;
  
  /// Crée un générateur stable basé sur un seed
  /// 
  /// [seed] : Seed pour le générateur (ex: planId, userId+date)
  StableRandomService._(this._seed, this._random);
  
  /// Factory pour créer un générateur basé sur un planId
  /// 
  /// [planId] : ID du plan (utilisé comme seed)
  /// 
  /// Le même planId produira toujours la même séquence de nombres
  factory StableRandomService.forPlan(String planId) {
    final seedValue = _stringToSeed(planId);
    final random = Random(seedValue);
    return StableRandomService._(planId, random);
  }
  
  /// Factory pour créer un générateur basé sur un contexte
  /// 
  /// [userId] : ID utilisateur
  /// [date] : Date (optionnel)
  /// [context] : Contexte additionnel (optionnel)
  factory StableRandomService.forContext({
    required String userId,
    DateTime? date,
    String? context,
  }) {
    final dateStr = date?.toIso8601String().split('T').first ?? '';
    final seedString = '$userId-$dateStr-${context ?? 'default'}';
    final seedValue = _stringToSeed(seedString);
    final random = Random(seedValue);
    return StableRandomService._(seedString, random);
  }
  
  /// Convertit une string en seed numérique stable
  static int _stringToSeed(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash + str.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.abs();
  }
  
  /// Génère un entier aléatoire stable entre 0 (inclus) et max (exclus)
  /// 
  /// [max] : Valeur maximale (exclusive)
  /// 
  /// Retourne : Entier entre 0 et max-1
  int nextInt(int max) {
    return _random.nextInt(max);
  }
  
  /// Génère un double aléatoire stable entre 0.0 et 1.0
  double nextDouble() {
    return _random.nextDouble();
  }
  
  /// Génère un booléen aléatoire stable
  bool nextBool() {
    return _random.nextBool();
  }
  
  /// Mélange une liste de manière stable
  /// 
  /// [list] : Liste à mélanger
  /// 
  /// La même liste avec le même seed donnera toujours le même ordre
  List<T> shuffle<T>(List<T> list) {
    final copy = [...list];
    copy.shuffle(_random);
    return copy;
  }
  
  /// Sélectionne N éléments aléatoires d'une liste de manière stable
  /// 
  /// [list] : Liste source
  /// [count] : Nombre d'éléments à sélectionner
  /// 
  /// Retourne : Sous-ensemble stable de la liste
  List<T> pick<T>(List<T> list, int count) {
    if (count >= list.length) return [...list];
    
    final shuffled = shuffle(list);
    return shuffled.take(count).toList();
  }
  
  /// Génère une variation d'un nombre dans une plage stable
  /// 
  /// [base] : Valeur de base
  /// [variance] : Variance en pourcentage (ex: 0.2 = ±20%)
  /// 
  /// Retourne : Valeur variée stable
  int varyInt(int base, double variance) {
    final variation = (base * variance).round();
    final offset = nextInt(variation * 2 + 1) - variation;
    return (base + offset).clamp(1, base * 2);
  }
  
  /// Génère une variation d'un double dans une plage stable
  double varyDouble(double base, double variance) {
    final variation = base * variance;
    final offset = (nextDouble() * variation * 2) - variation;
    return (base + offset).clamp(base * 0.5, base * 1.5);
  }
  
  /// Sélectionne un élément d'une liste de manière stable
  T choose<T>(List<T> list) {
    if (list.isEmpty) throw ArgumentError('Liste vide');
    return list[nextInt(list.length)];
  }
  
  /// Sélectionne un élément selon des poids stables
  /// 
  /// [items] : Liste des éléments
  /// [weights] : Liste des poids (même longueur que items)
  /// 
  /// Retourne : Élément sélectionné
  T weightedChoice<T>(List<T> items, List<double> weights) {
    if (items.length != weights.length) {
      throw ArgumentError('items et weights doivent avoir la même longueur');
    }
    
    final totalWeight = weights.reduce((a, b) => a + b);
    final random = nextDouble() * totalWeight;
    
    double cumulative = 0.0;
    for (int i = 0; i < items.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) {
        return items[i];
      }
    }
    
    return items.last; // Fallback
  }
  
  /// Génère une distribution stable de N éléments
  /// 
  /// [total] : Total à distribuer
  /// [buckets] : Nombre de buckets
  /// [variance] : Variance (0.0 = uniforme, 1.0 = très variable)
  /// 
  /// Retourne : Distribution stable
  List<int> distribute(int total, int buckets, {double variance = 0.2}) {
    final base = total ~/ buckets;
    final distribution = <int>[];
    int remaining = total;
    
    for (int i = 0; i < buckets - 1; i++) {
      final varied = varyInt(base, variance);
      final allocated = varied.clamp(1, remaining - (buckets - i - 1));
      distribution.add(allocated);
      remaining -= allocated;
    }
    
    // Dernier bucket prend le reste
    distribution.add(remaining);
    
    return distribution;
  }
}

/// Service de variation de plan avec seed stable
/// 
/// Permet de créer des variations d'un plan sans changer l'équilibre global
class PlanVariationService {
  
  /// Varie les références de lecture tout en gardant l'équilibre
  /// 
  /// [planId] : ID du plan (seed)
  /// [baseReferences] : Références de base
  /// [variancePercent] : Pourcentage de variation (défaut: 10%)
  /// 
  /// Exemple :
  /// Base: "Jean 1-3" → Variation: "Jean 1-2, 5"
  static List<String> varyReferences({
    required String planId,
    required List<String> baseReferences,
    double variancePercent = 0.1,
  }) {
    final random = StableRandomService.forPlan(planId);
    final varied = <String>[];
    
    for (final ref in baseReferences) {
      // 90% de chances de garder tel quel, 10% de varier
      if (random.nextDouble() > variancePercent) {
        varied.add(ref);
      } else {
        // Créer une variation
        final variedRef = _createVariation(ref, random);
        varied.add(variedRef);
      }
    }
    
    return varied;
  }
  
  /// Crée une variation d'une référence biblique
  static String _createVariation(String ref, StableRandomService random) {
    // Parser la référence (simplifié)
    // Ex: "Jean 3" → "Jean 2-3" ou "Jean 3-4"
    
    final parts = ref.split(' ');
    if (parts.length < 2) return ref;
    
    final book = parts[0];
    final chapterPart = parts[1];
    
    // Si déjà une plage, garder
    if (chapterPart.contains('–') || chapterPart.contains('-')) {
      return ref;
    }
    
    // Créer une petite variation
    final chapter = int.tryParse(chapterPart);
    if (chapter == null) return ref;
    
    // 50% de chances d'ajouter le chapitre précédent ou suivant
    if (random.nextBool()) {
      final prevChapter = max(1, chapter - 1);
      return '$book $prevChapter–$chapter';
    } else {
      final nextChapter = chapter + 1;
      return '$book $chapter–$nextChapter';
    }
  }
  
  /// Distribue les livres sur les jours de manière stable
  /// 
  /// [planId] : ID du plan
  /// [books] : Liste des livres
  /// [totalDays] : Nombre total de jours
  /// 
  /// Retourne : Distribution {livre: jours}
  static Map<String, int> distributeBooks({
    required String planId,
    required List<String> books,
    required int totalDays,
  }) {
    final random = StableRandomService.forPlan(planId);
    
    // Distribution de base (égale)
    final basePerBook = totalDays ~/ books.length;
    
    // Variation stable (±20%)
    final distribution = random.distribute(
      totalDays,
      books.length,
      variance: 0.2,
    );
    
    final result = <String, int>{};
    for (int i = 0; i < books.length; i++) {
      result[books[i]] = distribution[i];
    }
    
    return result;
  }
  
  /// Varie l'ordre des livres de manière stable
  /// 
  /// [planId] : ID du plan
  /// [books] : Liste des livres
  /// [keepFirst] : Garder le premier livre en premier (défaut: true)
  /// 
  /// Retourne : Liste réordonnée stable
  static List<String> varyOrder({
    required String planId,
    required List<String> books,
    bool keepFirst = true,
  }) {
    final random = StableRandomService.forPlan(planId);
    
    if (keepFirst && books.isNotEmpty) {
      final first = books.first;
      final rest = books.sublist(1);
      final shuffled = random.shuffle(rest);
      return [first, ...shuffled];
    }
    
    return random.shuffle(books);
  }
  
  /// Sélectionne des passages de méditation de manière stable
  /// 
  /// [planId] : ID du plan
  /// [allPassages] : Tous les passages disponibles
  /// [count] : Nombre de passages à sélectionner
  /// 
  /// Retourne : Passages sélectionnés stable
  static List<String> selectMeditationPassages({
    required String planId,
    required List<String> allPassages,
    required int count,
  }) {
    final random = StableRandomService.forPlan(planId);
    return random.pick(allPassages, count);
  }
  
  /// Génère des variations de nom de plan stable
  /// 
  /// [planId] : ID du plan
  /// [baseName] : Nom de base
  /// [variations] : Liste de variations possibles
  /// 
  /// Retourne : Nom varié stable
  static String varyPlanName({
    required String planId,
    required String baseName,
    required List<String> variations,
  }) {
    if (variations.isEmpty) return baseName;
    
    final random = StableRandomService.forPlan(planId);
    final selectedVariation = random.choose(variations);
    
    return '$baseName - $selectedVariation';
  }
}

/// Service de personnalisation stable par jour
/// 
/// Permet de varier l'expérience quotidienne tout en restant prévisible
class DailyVariationService {
  
  /// Génère une variation quotidienne stable
  /// 
  /// [planId] : ID du plan
  /// [dayNumber] : Numéro du jour
  /// 
  /// Retourne : Générateur stable pour ce jour
  static StableRandomService forDay({
    required String planId,
    required int dayNumber,
  }) {
    return StableRandomService.forContext(
      userId: planId,
      context: 'day_$dayNumber',
    );
  }
  
  /// Sélectionne un type de méditation pour le jour de manière stable
  /// 
  /// [planId] : ID du plan
  /// [dayNumber] : Numéro du jour
  /// [options] : Options disponibles
  /// [weights] : Poids de chaque option (optionnel)
  /// 
  /// Retourne : Type de méditation pour ce jour
  static String selectMeditationType({
    required String planId,
    required int dayNumber,
    required List<String> options,
    List<double>? weights,
  }) {
    final random = forDay(planId: planId, dayNumber: dayNumber);
    
    if (weights != null && weights.length == options.length) {
      return random.weightedChoice(options, weights);
    }
    
    return random.choose(options);
  }
  
  /// Sélectionne un gradient de couleur pour le jour
  /// 
  /// [planId] : ID du plan
  /// [dayNumber] : Numéro du jour
  /// [gradients] : Liste de gradients disponibles
  /// 
  /// Retourne : Index du gradient stable
  static int selectGradient({
    required String planId,
    required int dayNumber,
    required int gradientsCount,
  }) {
    final random = forDay(planId: planId, dayNumber: dayNumber);
    return random.nextInt(gradientsCount);
  }
  
  /// Génère une variation de questions QCM pour le jour
  /// 
  /// [planId] : ID du plan
  /// [dayNumber] : Numéro du jour
  /// [allQuestions] : Toutes les questions disponibles
  /// [count] : Nombre de questions à sélectionner
  /// 
  /// Retourne : Questions sélectionnées stable
  static List<T> selectQuestions<T>({
    required String planId,
    required int dayNumber,
    required List<T> allQuestions,
    required int count,
  }) {
    final random = forDay(planId: planId, dayNumber: dayNumber);
    return random.pick(allQuestions, count);
  }
  
  /// Varie l'ordre des sections d'une page de manière stable
  /// 
  /// [planId] : ID du plan
  /// [dayNumber] : Numéro du jour
  /// [sections] : Liste des sections
  /// 
  /// Retourne : Sections réordonnées stable
  static List<String> varySectionOrder({
    required String planId,
    required int dayNumber,
    required List<String> sections,
  }) {
    final random = forDay(planId: planId, dayNumber: dayNumber);
    return random.shuffle(sections);
  }
}

/// Service de génération de messages personnalisés stables
class StableMessageService {
  
  /// Génère un message d'accueil stable pour le jour
  /// 
  /// [planId] : ID du plan
  /// [dayNumber] : Numéro du jour
  /// [userName] : Nom de l'utilisateur
  /// 
  /// Retourne : Message personnalisé stable
  static String getDailyGreeting({
    required String planId,
    required int dayNumber,
    required String userName,
  }) {
    final random = DailyVariationService.forDay(
      planId: planId,
      dayNumber: dayNumber,
    );
    
    final greetings = [
      'Bonjour $userName ! Prêt pour le jour $dayNumber ?',
      'Bienvenue $userName ! Jour $dayNumber de votre parcours',
      'Heureux de vous revoir $userName ! Jour $dayNumber',
      'Que cette lecture vous bénisse, $userName ! (Jour $dayNumber)',
      'En route pour le jour $dayNumber, $userName !',
    ];
    
    return random.choose(greetings);
  }
  
  /// Génère un message d'encouragement stable selon la progression
  /// 
  /// [planId] : ID du plan
  /// [dayNumber] : Numéro du jour
  /// [completionRate] : Taux de complétion (0.0 - 1.0)
  /// 
  /// Retourne : Message d'encouragement
  static String getEncouragementMessage({
    required String planId,
    required int dayNumber,
    required double completionRate,
  }) {
    final random = DailyVariationService.forDay(
      planId: planId,
      dayNumber: dayNumber,
    );
    
    List<String> messages;
    
    if (completionRate >= 0.9) {
      messages = [
        '🎉 Incroyable régularité !',
        '⭐ Vous êtes un exemple !',
        '💪 Quelle discipline !',
        '✨ Remarquable persévérance !',
      ];
    } else if (completionRate >= 0.7) {
      messages = [
        '👍 Très bon rythme !',
        '💫 Continuez ainsi !',
        '🌟 Belle progression !',
        '🎯 Vous êtes sur la bonne voie !',
      ];
    } else if (completionRate >= 0.5) {
      messages = [
        '💪 Accrochez-vous !',
        '🌱 Chaque pas compte !',
        '⏰ Il n\'est pas trop tard !',
        '🔄 Reprenez le rythme !',
      ];
    } else {
      messages = [
        '🌅 Recommencez aujourd\'hui !',
        '💝 La grâce de Dieu est nouvelle chaque matin',
        '🔥 Rallumez la flamme !',
        '🙏 Dieu vous attend avec patience',
      ];
    }
    
    return random.choose(messages);
  }
}

/// Extension pour les nombres aléatoires
extension RandomExtensions on Random {
  /// Génère un int dans une plage
  int nextIntInRange(int min, int max) {
    return min + nextInt(max - min + 1);
  }
  
  /// Génère un double dans une plage
  double nextDoubleInRange(double min, double max) {
    return min + nextDouble() * (max - min);
  }
}




