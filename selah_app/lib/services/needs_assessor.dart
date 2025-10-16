class NeedsProfile {
  final double foundation;  // Christ/Gospel/Scripture (0..1)
  final double discipline;  // régularité
  final double repentance;  // retour / relèvement
  final double doctrine;    // erreurs doctrinales détectées
  final double suffering;   // épreuve
  final double anxiety;     // peur/angoisse

  const NeedsProfile({
    required this.foundation,
    required this.discipline,
    required this.repentance,
    required this.doctrine,
    required this.suffering,
    required this.anxiety,
  });
}

class NeedsAssessor {
  /// Calcule un "manque" (plus c'est haut, plus le besoin est fort).
  static NeedsProfile compute(
    Map<String, dynamic>? profile, {
    int streak = 0,
    int missedDays14 = 0,
    double quizChrist = 0.5,
    double quizGospel = 0.5,
    double quizScripture = 0.5,
    List<String> recentEmotions = const [],
    List<String> commonErrors = const [],
  }) {
    // Fondation : si les quiz sont faibles → besoin élevé
    final foundationLack = 1.0 - ((quizChrist + quizGospel + quizScripture) / 3.0).clamp(0.0, 1.0);

    // Discipline : plus de jours manqués → besoin élevé
    final disciplineLack = (missedDays14 / 14.0).clamp(0.0, 1.0) * 0.8 + (streak == 0 ? 0.2 : 0.0);

    // Repentance : si émotions "culpabilité", "retour", "froid"…
    final repentanceLack = recentEmotions.any((e) =>
      e.contains('culp') || e.contains('retour') || e.contains('froid') || e.contains('éloign'))
      ? 0.7 : 0.3;

    // Doctrine : nombre d'erreurs recensées
    final doctrineLack = (commonErrors.length / 5.0).clamp(0.0, 1.0);

    // Souffrance : si "deuil", "épreuve", "maladie"…
    final sufferingNeed = recentEmotions.any((e) =>
      e.contains('épreuve') || e.contains('maladie') || e.contains('deuil') || e.contains('persécution'))
      ? 0.7 : 0.2;

    // Anxiété : si "stress", "peur", "angoisse"…
    final anxietyNeed = recentEmotions.any((e) =>
      e.contains('stress') || e.contains('peur') || e.contains('angoiss') || e.contains('inquiét'))
      ? 0.7 : 0.3;

    return NeedsProfile(
      foundation: _round2(foundationLack),
      discipline: _round2(disciplineLack),
      repentance: _round2(repentanceLack),
      doctrine: _round2(doctrineLack),
      suffering: _round2(sufferingNeed),
      anxiety: _round2(anxietyNeed),
    );
  }

  /// Renvoie une courte liste de thèmes **orientés besoins** (et non envies).
  static List<String> themesFor(NeedsProfile n) {
    final items = <MapEntry<String, double>>[
      MapEntry('Fondements de l\'Evangile (Jean, Romains, Galates)', n.foundation),
      MapEntry('Discipline & Regularite (Proverbes, Matthieu 6)', n.discipline),
      MapEntry('Retour & Repentance (Psaumes 51, Luc 15)', n.repentance),
      MapEntry('Saine Doctrine (1-2 Timothee, Tite)', n.doctrine),
      MapEntry('Consolation dans l\'epreuve (1 Pierre, Psaumes)', n.suffering),
      MapEntry('Paix contre l\'anxiete (Philippiens 4, Matthieu 6)', n.anxiety),
    ];

    items.sort((a, b) => b.value.compareTo(a.value));
    return items.take(5).map((e) => e.key).toList();
  }

  static double _round2(double v) => double.parse(v.toStringAsFixed(2));
}
