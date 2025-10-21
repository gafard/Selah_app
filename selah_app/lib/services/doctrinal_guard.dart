import '../models/plan_preset.dart';

class DoctrinalVerdict {
  final bool blocked;           // vrai => on n'affiche pas ce preset
  final String? reason;         // explication rapide
  final PlanPreset? corrected;  // version corrigée (ex: ajoute Jean)

  const DoctrinalVerdict({
    required this.blocked,
    this.reason,
    this.corrected,
  });
}

class DoctrinalGuard {
  // Livres qui portent clairement les 3 gardes doctrinales :
  // 1) Doctrine de Christ  2) Autorité de l'Écriture  3) Évangile
  static const _christologyCore = <String>{
    'Matthieu','Marc','Luc','Jean','Colossiens','Hébreux','Philippiens'
  };
  static const _gospelCore = <String>{
    'Jean','Romains','Galates','1 Corinthiens','2 Corinthiens'
  };
  static const _scriptureAuthorityCore = <String>{
    '2 Timothée','1 Thessaloniciens','2 Pierre','Apocalypse'
  };

  // Thèmes/titres suspects (ex.: dérives « évangile de prospérité », gnosticisme, etc.)
  static const _blockedKeywords = <String>{
    'prosperite absolue', 'gnose secrete', 'maitrise cosmique',
    'ange gardien personnel', 'revelation privee obligatoire',
    'evangile sans repentance', 'christ energie', 'loi d\'attraction'
  };

  // Si un preset ne contient aucun livre du NT et dure longtemps → on conseille de le corriger.
  static DoctrinalVerdict evaluate(PlanPreset p) {
    final books = p.books.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final nameLower = (p.name).toLowerCase();
    final descLower = (p.description ?? '').toLowerCase();

    // 0) Blocage direct par mots-clés (sécurité dure)
    for (final k in _blockedKeywords) {
      if (nameLower.contains(k) || descLower.contains(k)) {
        return DoctrinalVerdict(
          blocked: true,
          reason: 'Contenu douteux détecté (« $k »).',
        );
      }
    }

    // 1) Hard block : évangile « sans Christ » explicite (rare, mais on garde le garde-fou)
    if (nameLower.contains('sans christ') || descLower.contains('sans christ')) {
      return const DoctrinalVerdict(
        blocked: true,
        reason: 'Rejette explicitement la christologie biblique (1 Jn 4.1-3).',
      );
    }

    // 2) Vérifs de couverture doctrinale (soft guard) — on CORRIGE si besoin
    final hasChristology = books.any(_christologyCore.contains);
    final hasGospel      = books.any(_gospelCore.contains);
    final hasScripture   = books.any(_scriptureAuthorityCore.contains);
    final duration = p.durationDays;

    // Cas A: plan long mais 100% Ancien Testament → on ajoute un évangile (Jean)
    final onlyOT = books.isNotEmpty && books.every((b) => !_isNT(b));
    if (onlyOT && duration >= 28) {
      final corrected = p.copyWith(
        books: [...books, 'Jean'].join(','),
        name: _appendSuffix(p.name, ' + Jean (ancrage Évangile)'),
        durationDays: duration, // on ne touche pas la durée ici
        description: _appendSentence(p.description,
            'Ancrage Évangile ajouté (Jean) pour garder le centre sur Christ et la bonne nouvelle.'),
      );
      return DoctrinalVerdict(blocked: false, corrected: corrected);
    }

    // Cas B: pas de livre « Évangile/Justification » → on ajoute Romains
    if (!hasGospel) {
      final corrected = p.copyWith(
        books: _addIfMissing(books, 'Romains').join(','),
        name: _appendSuffix(p.name, ' + Romains (justification)'),
        description: _appendSentence(p.description,
            'Couverture Évangile renforcée (Romains) — Gal 1.6-9 / Rom 1.16.'),
      );
      return DoctrinalVerdict(blocked: false, corrected: corrected);
    }

    // Cas C: aucun ancrage explicite sur autorité de l'Écriture → on ajoute 2 Timothée
    if (!hasScripture && duration >= 21) {
      final corrected = p.copyWith(
        books: _addIfMissing(books, '2 Timothée').join(','),
        name: _appendSuffix(p.name, ' + 2 Timothee (autorite de l\'Ecriture)'),
        description: _appendSentence(p.description,
            'Ancrage "Toute Ecriture est inspiree de Dieu" (2 Tm 3.16).'),
      );
      return DoctrinalVerdict(blocked: false, corrected: corrected);
    }

    // Cas D: christologie manquante sur plan de caractère uniquement → on ajoute Colossiens
    if (!hasChristology && _looksLikeCharacterPlan(nameLower, descLower)) {
      final corrected = p.copyWith(
        books: _addIfMissing(books, 'Colossiens').join(','),
        name: _appendSuffix(p.name, ' + Colossiens (suprématie de Christ)'),
        description: _appendSentence(p.description,
            'Ancrage christologique renforcé (Col 1:15-20) — 1 Jn 4.1-3.'),
      );
      return DoctrinalVerdict(blocked: false, corrected: corrected);
    }

    // Tout bon ✅
    return const DoctrinalVerdict(blocked: false);
  }

  static bool _looksLikeCharacterPlan(String name, String desc) {
    final bag = '$name $desc';
    return [
      'caractère', 'discipline', 'vertu', 'pratique', 'habitudes',
      'sagesse', 'proverbes', 'relations', 'mariage'
    ].any(bag.contains);
  }

  static bool _isNT(String book) {
    const nt = <String>{
      'Matthieu','Marc','Luc','Jean','Actes','Romains','1 Corinthiens','2 Corinthiens',
      'Galates','Éphésiens','Philippiens','Colossiens','1 Thessaloniciens','2 Thessaloniciens',
      '1 Timothée','2 Timothée','Tite','Philémon','Hébreux','Jacques','1 Pierre','2 Pierre',
      '1 Jean','2 Jean','3 Jean','Jude','Apocalypse'
    };
    return nt.contains(book);
  }

  static List<String> _addIfMissing(List<String> books, String b) {
    if (books.contains(b)) return books;
    return [...books, b];
  }

  static String _appendSuffix(String name, String suffix) {
    return name.contains('•') ? '$name $suffix' : '$name • $suffix';
  }

  static String _appendSentence(String? base, String sentence) {
    if (base == null || base.isEmpty) return sentence;
    final end = base.trim().endsWith('.') ? '' : '.';
    return '$base$end $sentence';
  }
}
