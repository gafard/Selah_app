/// Modèle pour représenter un passage de lecture biblique
class ReadingPassage {
  final String reference;
  final String? text;
  final String? title;
  final bool isLoaded;
  final bool isLoading;
  final String? error;

  const ReadingPassage({
    required this.reference,
    this.text,
    this.title,
    this.isLoaded = false,
    this.isLoading = false,
    this.error,
  });

  /// Crée une copie avec de nouveaux paramètres
  ReadingPassage copyWith({
    String? reference,
    String? text,
    String? title,
    bool? isLoaded,
    bool? isLoading,
    String? error,
  }) {
    return ReadingPassage(
      reference: reference ?? this.reference,
      text: text ?? this.text,
      title: title ?? this.title,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Génère un titre automatique basé sur la référence
  String get autoTitle {
    if (title != null && title!.isNotEmpty) return title!;
    
    // Extraire le livre et le chapitre de la référence
    final parts = reference.split(' ');
    if (parts.length >= 2) {
      final book = parts[0];
      final chapterVerse = parts[1];
      final chapter = chapterVerse.split(':')[0];
      return '$book $chapter';
    }
    
    return reference;
  }

  /// Vérifie si le passage est prêt à être affiché
  bool get isReady => isLoaded && text != null && text!.isNotEmpty;

  /// Vérifie s'il y a une erreur
  bool get hasError => error != null && error!.isNotEmpty;

  @override
  String toString() {
    return 'ReadingPassage(reference: $reference, isLoaded: $isLoaded, isLoading: $isLoading, hasError: $hasError)';
  }
}

/// Modèle pour représenter une session de lecture avec plusieurs passages
class ReadingSession {
  final List<ReadingPassage> passages;
  final String? dayTitle;
  final int currentPassageIndex;

  const ReadingSession({
    required this.passages,
    this.dayTitle,
    this.currentPassageIndex = 0,
  });

  /// Crée une session à partir d'une référence simple (rétrocompatibilité)
  factory ReadingSession.fromSingleReference({
    required String reference,
    String? text,
    String? title,
    String? dayTitle,
  }) {
    return ReadingSession(
      passages: [
        ReadingPassage(
          reference: reference,
          text: text,
          title: title,
          isLoaded: text != null && text.isNotEmpty,
        ),
      ],
      dayTitle: dayTitle,
    );
  }

  /// Crée une session à partir de plusieurs références
  factory ReadingSession.fromReferences({
    required List<String> references,
    String? dayTitle,
  }) {
    return ReadingSession(
      passages: references.map((ref) => ReadingPassage(reference: ref)).toList(),
      dayTitle: dayTitle,
    );
  }

  /// Crée une copie avec de nouveaux paramètres
  ReadingSession copyWith({
    List<ReadingPassage>? passages,
    String? dayTitle,
    int? currentPassageIndex,
  }) {
    return ReadingSession(
      passages: passages ?? this.passages,
      dayTitle: dayTitle ?? this.dayTitle,
      currentPassageIndex: currentPassageIndex ?? this.currentPassageIndex,
    );
  }

  /// Passage actuel
  ReadingPassage? get currentPassage {
    if (passages.isEmpty || currentPassageIndex >= passages.length) {
      return null;
    }
    return passages[currentPassageIndex];
  }

  /// Nombre total de passages
  int get totalPassages => passages.length;

  /// Vérifie s'il y a plusieurs passages
  bool get hasMultiplePassages => passages.length > 1;

  /// Vérifie si on peut naviguer vers le passage précédent
  bool get canGoToPrevious => currentPassageIndex > 0;

  /// Vérifie si on peut naviguer vers le passage suivant
  bool get canGoToNext => currentPassageIndex < passages.length - 1;

  /// Passe au passage suivant
  ReadingSession goToNext() {
    if (!canGoToNext) return this;
    return copyWith(currentPassageIndex: currentPassageIndex + 1);
  }

  /// Passe au passage précédent
  ReadingSession goToPrevious() {
    if (!canGoToPrevious) return this;
    return copyWith(currentPassageIndex: currentPassageIndex - 1);
  }

  /// Met à jour un passage spécifique
  ReadingSession updatePassage(int index, ReadingPassage updatedPassage) {
    if (index < 0 || index >= passages.length) return this;
    
    final newPassages = List<ReadingPassage>.from(passages);
    newPassages[index] = updatedPassage;
    
    return copyWith(passages: newPassages);
  }

  /// Vérifie si tous les passages sont chargés
  bool get allPassagesLoaded => passages.every((p) => p.isLoaded);

  /// Vérifie s'il y a des passages en cours de chargement
  bool get hasLoadingPassages => passages.any((p) => p.isLoading);

  /// Vérifie s'il y a des erreurs
  bool get hasErrors => passages.any((p) => p.hasError);

  @override
  String toString() {
    return 'ReadingSession(passages: ${passages.length}, currentIndex: $currentPassageIndex, dayTitle: $dayTitle)';
  }
}
