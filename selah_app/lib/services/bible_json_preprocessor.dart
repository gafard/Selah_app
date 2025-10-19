import 'package:json5/json5.dart';

/// Préprocesseur JSON/JSON5 "tolérant".
/// Objectif : faire passer des fichiers partiellement corrompus (clés non-quotées,
/// retours à la ligne entre clés, etc.) dans JSON5.parse().
///
/// Pipeline :
/// 1) Essai JSON5 brut
/// 2) Si échec → preprocess() → JSON5.parse() à nouveau
/// 3) Si encore échec → on relance l'erreur
class LooseJsonPreprocessor {
  final List<String> log = [];

  static Map<String, dynamic> parseOrThrow(String raw, {LooseJsonPreprocessor? out}) {
    final prep = out ?? LooseJsonPreprocessor();

    // 1) Essai brut (JSON5 supporte déjà pas mal de relâchements)
    try {
      final data = JSON5.parse(raw);
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const FormatException('Le JSON racine n\'est pas un objet');
    } catch (e) {
      prep.log.add('JSON5 brut a échoué: $e');
    }

    // 2) Réparation
    final fixed = prep.preprocess(raw);

    // 3) Second essai
    final data2 = JSON5.parse(fixed);
    if (data2 is Map) return Map<String, dynamic>.from(data2);
    throw const FormatException('Le JSON réparé n\'est pas un objet');
  }

  /// Applique toutes les réparations **sans toucher au contenu textuel** (ex: guillemets
  /// typographiques laissés tels quels dans les **valeurs** de chaînes).
  String preprocess(String raw) {
    var s = raw;

    // 0) Normalisation bas niveau
    s = s.replaceAll('\uFEFF', '');
    s = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    log.add('✓ Normalisation des retours + BOM');

    // 0.5) Convertir les \n littéraux en vrais retours à la ligne
    s = s.replaceAll(r'\n', '\n');
    log.add('✓ \\n littéraux convertis en retours à la ligne');

    // 1) Quoter les clés non-quotées
    final keyLike = RegExp(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', multiLine: true);
    s = s.replaceAllMapped(keyLike, (m) => '${m[1]} "${m[2]}":');
    log.add('✓ Clés non-quotées → "clé":');

    // 2) Supprimer les séquences \n littérales hors des chaînes (au cas où il en reste)
    s = _fixLiteralBackslashNOutsideStrings(s);
    log.add('✓ Séquences \\n littérales hors chaînes supprimées');

    // 3) Réparer les clés coupées par retour à la ligne AVANT de réparer les multi-lignes
    s = _healKeySplits(s);
    log.add('✓ Clés coupées par retour à la ligne réparées');

    // 4) Réparer les "Text" multi-lignes (avec logs)
    s = _fixMultilineTextWithLogs(s, log: (l) => log.add(l));

    // 4) Échapper les apostrophes dans les chaînes (AVANT les guillemets)
    s = _fixSingleQuotesInStrings(s);
    log.add('✓ Apostrophes dans les chaînes échappées');

    // 5) Échapper les guillemets internes dans les chaînes de valeur
    s = _escapeBareQuotesOnlyInValueStrings(s);
    log.add('✓ Guillemets internes échappés (valeurs uniquement)');

    // 6) Échapper les retours à la ligne restants dans les chaînes
    s = _fixNewlinesInsideStrings(s);
    log.add('✓ Retours à la ligne dans les chaînes échappés');

    // 7) Normaliser les caractères Unicode problématiques
    s = _normalizeUnicodeChars(s);
    log.add('✓ Caractères Unicode normalisés');

    // 5) Nettoyage final
    final orphan = RegExp(r'([,\{\}\[\]])\s*([A-Za-z])\s*([,\}\]\{])');
    for (int i = 0; i < 2; i++) {
      final before = s;
      s = s.replaceAllMapped(orphan, (m) => '${m[1]} ${m[3]}');
      if (s == before) break;
    }
    s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    log.add('✓ Nettoyage final des caractères de contrôle');

    return s;
  }

  // ---------------------------------------------------------------------------
  // Helpers bas-niveau (tous hors chaînes sauf indication contraire)
  // ---------------------------------------------------------------------------

  /// Ajoute des guillemets autour des clés non-quotées (hors chaînes).
  String _quoteUnquotedKeys(String s) {
    final sb = StringBuffer();
    bool inStr = false;
    String? q;
    bool esc = false;

    for (int i = 0; i < s.length; i++) {
      final ch = s[i];

      if (!inStr) {
        if (ch == '"' || ch == '\'') {
          inStr = true;
          q = ch;
          sb.write(ch);
          continue;
        }

        // clé non-quotée suivie de :
        if (_isKeyStart(ch)) {
          final start = i;
          int j = i + 1;
          while (j < s.length && _isKeyBody(s[j])) j++;

          // skip espaces
          int k = j;
          while (k < s.length && (s[k] == ' ' || s[k] == '\t')) k++;

          if (k < s.length && s[k] == ':') {
            final key = s.substring(start, j);
            sb.write('"$key"');
            i = j - 1;
            continue;
          }
        }

        sb.write(ch);
        continue;
      }

      // in string
      if (esc) {
        sb.write(ch);
        esc = false;
        continue;
      }
      if (ch == '\\') {
        sb.write(ch);
        esc = true;
        continue;
      }
      if (ch == q) {
        inStr = false;
        sb.write(ch);
        continue;
      }
      sb.write(ch);
    }

    return sb.toString();
  }

  bool _isKeyStart(String ch) {
    final r = RegExp(r'[A-Za-z_\$À-ÿ]');
    return r.hasMatch(ch);
  }

  bool _isKeyBody(String ch) {
    final r = RegExp(r'[A-Za-z0-9_\-\$À-ÿ]');
    return r.hasMatch(ch);
    }

  /// Répare les clés JSON coupées par un retour à la ligne, par ex:
  ///   "ID":7,
  ///   Text:"..."  →  "ID":7,"Text":"..."
  ///   ID:12,
  ///   Text:       →  "ID":12,"Text":
  /// Fonctionne aussi pour "Verse":5,\n"Text": etc.
  String _healKeySplits(String input) {
    // 1) clé + valeur + virgule puis saut(s) de ligne + espaces/tabs + clé suivante non-quotée
    final rx1 = RegExp(
      r'("?[A-Za-z_][A-Za-z0-9_\-]*"?\s*:\s*[^,\}\]]+)\s*,\s*\n+\s*[\t ]*([A-Za-z_][A-Za-z0-9_\-]*)\s*:',
      multiLine: true,
    );
    input = input.replaceAllMapped(rx1, (m) {
      final left = m.group(1)!;
      final rightKey = m.group(2)!;
      return '$left,"$rightKey":';
    });

    // 2) même cas mais clé suivante déjà entre guillemets
    final rx2 = RegExp(
      r'("?[A-Za-z_][A-Za-z0-9_\-]*"?\s*:\s*[^,\}\]]+)\s*,\s*\n+\s*[\t ]*"([A-Za-z_][A-Za-z0-9_\-]*)"\s*:',
      multiLine: true,
    );
    input = input.replaceAllMapped(rx2, (m) {
      final left = m.group(1)!;
      final right = m.group(2)!;
      return '$left,"$right":';
    });

    // 3) sans guillemets sur la première clé non-quotée + espaces/tabs avant 2ᵉ clé
    final rx3 = RegExp(
      r'([A-Za-z_][A-Za-z0-9_\-]*\s*:\s*[^,\}\]]+)\s*,\s*\n+\s*[\t ]*([A-Za-z_][A-Za-z0-9_\-]*)\s*:',
      multiLine: true,
    );
    input = input.replaceAllMapped(rx3, (m) {
      final leftKey = m.group(1)!.split(':').first.trim();
      final leftVal = m.group(1)!.split(':').sublist(1).join(':');
      final rightKey = m.group(2)!;
      return '"$leftKey":$leftVal,"$rightKey":';
    });

    // 4) Normaliser les virgules + saut de ligne multiples / tabulations
    input = input.replaceAll(RegExp(r',\s*\n+\s*[\t ]*'), ', ');

    return input;
  }

  /// Reconstruit les champs "Text":"..." cassés sur plusieurs lignes,
  /// en remplaçant chaque retour à la ligne par \\n et en loggant les corrections.
  /// - Suppose que la clé est exactement "Text" (sensible à la casse).
  /// - Tolère les fermetures par `",` ou `"}`.
  /// - N'altère pas les guillemets typographiques « » " " — ils restent dans le contenu JSON.
  /// - Laisse intacts les autres champs.
  /// - Produit des logs du type:
  ///   [fixMultilineStrings] Text réparé L:12345-12348 (3 lignes) → "Dieu dit \"alors\": ..."
  String _fixMultilineTextWithLogs(
    String input, {
    void Function(String line)? log,   // optionnel : callback pour logger
    int previewMax = 80,               // taille d'aperçu dans les logs
  }) {
    final lines = input.split('\n');

    // buffer global pour la sortie
    final out = StringBuffer();

    // état de réparation
    bool insideText = false;
    int startLine = -1;        // 1-based
    final textPrefix = StringBuffer(); // tout jusqu'au 1er guillemet ouvrant (inclu)
    final textContent = StringBuffer(); // contenu réel du verset (sans guillemets)
    String? pendingTail;       // suffixe après la fermeture (",  ou "})

    // Parcourt des lignes
    int currentLine = 1; // 1-based pour logs

    // Utilitaires de logs
    void _log(String s) {
      if (log != null) log!(s);
    }

    // Écrit une réparation complète dans la sortie + log
    void flushRepaired() {
      // Recompose la ligne "Text":"...<content>..." + le tail
      final preview = textContent.toString().replaceAll('\n', r'\n');
      final fixed = '${textPrefix.toString()}${preview.replaceAll('\n', r'\n')}"${pendingTail ?? ''}';

      out.writeln(fixed);

      final mergedLines = (startLine == -1) ? 0 : (currentLine - startLine);
      final previewStr = (preview.length > previewMax)
          ? preview.substring(0, previewMax) + '…'
          : preview;

      _log('[fixMultilineStrings] Text réparé L:$startLine-${currentLine - 1} '
          '(${mergedLines} lignes) → "${previewStr}"');

      // reset état
      insideText = false;
      startLine = -1;
      textPrefix.clear();
      textContent.clear();
      pendingTail = null;
    }

    for (final rawLine in lines) {
      var line = rawLine;

      if (!insideText) {
        // Chercher un début de champ "Text":" …"
        // On cherche le motif : "Text":
        final keyIdx = line.indexOf('"Text"');
        if (keyIdx == -1) {
          out.writeln(line);
          currentLine++;
          continue;
        }

        // Vérifier qu'on a bien "Text":"
        // 1) après "Text" -> skip espaces -> :
        int i = keyIdx + '"Text"'.length;
        while (i < line.length && (line[i] == ' ' || line[i] == '\t')) i++;
        if (i >= line.length || line[i] != ':') {
          // ce n'est pas un champ JSON correct → écrire tel quel
          out.writeln(line);
          currentLine++;
          continue;
        }
        i++; // skip ':'
        while (i < line.length && (line[i] == ' ' || line[i] == '\t')) i++;
        if (i >= line.length || line[i] != '"') {
          // pas d'ouverture de chaîne → écrire tel quel
          out.writeln(line);
          currentLine++;
          continue;
        }

        // On a bien "Text":" → on passe en mode capture
        insideText = true;
        startLine = currentLine;

        // tout avant et incluant le premier guillemet ouvrant
        final openQuoteIdx = i; // position du guillemet ouvrant
        textPrefix
          ..clear()
          ..write(line.substring(0, openQuoteIdx + 1)); // inclut le "

        // Le reste de la ligne, après l'ouverture
        var afterOpen = line.substring(openQuoteIdx + 1);

        // Est-ce que la fermeture est sur la même ligne ? (\"", ou \"})
        // On cherche la prochaine occurrence de guillemet fermant " suivie de , ou }
        // → mais sans se tromper avec des guillemets échappés.
        int j = 0;
        bool foundClose = false;
        while (j < afterOpen.length) {
          final ch = afterOpen[j];
          if (ch == '\\') {
            // sauter le caractère suivant (échappement)
            j += 2;
            continue;
          }
          if (ch == '"') {
            // candidat à fermeture si suivi de , ou }
            final next = (j + 1 < afterOpen.length) ? afterOpen[j + 1] : '\u0000';
            if (next == ',' || next == '}') {
              // fermeture inline
              final content = afterOpen.substring(0, j);
              // remplacer les vrais \n par \\n (il ne devrait pas y en avoir inline, mais au cas où…)
              textContent.write(content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll('\n', r'\n'));
              pendingTail = afterOpen.substring(j + 1); // ,...  ou }...
              flushRepaired();
              foundClose = true;
              break;
            }
          }
          j++;
        }

        if (!foundClose) {
          // pas de fermeture : on accumule et on continue aux lignes suivantes
          // ici, on conserve tous les \n comme des \n (on les re-escapera au flush)
          textContent.write(afterOpen.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
        }
      } else {
        // On est en plein milieu d'un Text multi-lignes
        final l = line.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        // Chercher guillemet de fermeture non échappé suivi de , ou }
        int j = 0;
        bool foundClose = false;
        while (j < l.length) {
          final ch = l[j];
          if (ch == '\\') {
            j += 2;
            continue;
          }
          if (ch == '"') {
            final next = (j + 1 < l.length) ? l[j + 1] : '\u0000';
            if (next == ',' || next == '}') {
              // On ferme ici : tout avant est du contenu
              final before = l.substring(0, j);
              // ajoute un \n avant la dernière portion (car nouvelle ligne)
              if (textContent.isNotEmpty) textContent.write('\n');
              textContent.write(before);

              pendingTail = l.substring(j + 1); // ,… ou }…
              flushRepaired();
              foundClose = true;
              break;
            }
          }
          j++;
        }

        if (!foundClose) {
          // Toute la ligne est du contenu ; on ajoute un \n entre les lignes accumulées
          if (textContent.isNotEmpty) textContent.write('\n');
          textContent.write(l);
        }
      }

      currentLine++;
    }

    // Si le fichier se termine alors qu'on n'a jamais trouvé de fermeture
    if (insideText) {
      pendingTail ??= '"}'; // fallback minimal ; à ajuster selon tes fichiers
      flushRepaired();
    }

    return out.toString();
  }

  /// Supprime les séquences littérales "\n" (backslash + n)
  /// qui apparaissent en dehors des chaînes JSON.
  /// Exemple : {"ID":2,\n"Text":" → {"ID":2,"Text":"
  String _fixLiteralBackslashNOutsideStrings(String input) {
    final sb = StringBuffer();

    bool inString = false;
    String quote = '';
    bool escape = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        // on détecte début de chaîne
        if (ch == '"' || ch == '\'') {
          inString = true;
          quote = ch;
          sb.write(ch);
          continue;
        }

        // cas problématique : séquence \n littérale hors chaîne
        if (ch == '\\' && i + 1 < input.length && input[i + 1] == 'n') {
          // on saute les deux caractères \ et n
          i++; 
          continue;
        }

        // sinon, on garde le caractère normal
        sb.write(ch);
        continue;
      }

      // --- à l'intérieur d'une chaîne ---
      if (escape) {
        sb.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\') {
        escape = true;
        sb.write(ch);
        continue;
      }

      if (ch == quote) {
        inString = false;
        sb.write(ch);
        continue;
      }

      sb.write(ch);
    }

    return sb.toString();
  }

  /// Corrige les retours à la ligne UNIQUEMENT à l'intérieur des chaînes JSON.
  /// - Convertit '\n' et '\r' en '\n' dans les chaînes
  /// - Ignore les retours hors des chaînes
  /// - Gère les échappements comme \", \n, \\ correctement
  String _fixNewlinesInsideStrings(String input) {
    final sb = StringBuffer();

    bool inString = false; // sommes-nous dans une chaîne ?
    String quote = ''; // type de guillemet courant (' ou ")
    bool escape = false; // est-on dans une séquence d'échappement ?

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        // Début d'une chaîne : " ou '
        if (ch == '"' || ch == '\'') {
          inString = true;
          quote = ch;
        }
        sb.write(ch);
        continue;
      }

      // --- À l'intérieur d'une chaîne ---
      if (escape) {
        sb.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\') {
        escape = true;
        sb.write(ch);
        continue;
      }

      if (ch == quote) {
        // Fin de chaîne
        inString = false;
        sb.write(ch);
        continue;
      }

      // Si on rencontre un saut de ligne dans une chaîne → remplacer par \n
      if (ch == '\n' || ch == '\r') {
        sb.write('\\n');
        continue;
      }

      // Sinon, caractère normal
      sb.write(ch);
    }

    return sb.toString();
  }

  /// Échappe les apostrophes dans les chaînes JSON délimitées par des guillemets doubles.
  /// - Convertit ' en \' dans les chaînes délimitées par "
  /// - Ignore les apostrophes hors des chaînes
  /// - Gère les échappements correctement
  String _fixSingleQuotesInStrings(String input) {
    final sb = StringBuffer();

    bool inString = false; // sommes-nous dans une chaîne ?
    bool escape = false; // est-on dans une séquence d'échappement ?

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        // Début d'une chaîne : seulement "
        if (ch == '"') {
          inString = true;
        }
        sb.write(ch);
        continue;
      }

      // --- À l'intérieur d'une chaîne délimitées par " ---
      if (escape) {
        sb.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\') {
        escape = true;
        sb.write(ch);
        continue;
      }

      if (ch == '"') {
        // Fin de chaîne
        inString = false;
        sb.write(ch);
        continue;
      }

      // Si on rencontre une apostrophe dans une chaîne → l'échapper
      if (ch == '\'') {
        sb.write('\\');
        sb.write(ch);
        continue;
      }

      // Sinon, caractère normal
      sb.write(ch);
    }

    return sb.toString();
  }

  /// Normalise les caractères Unicode problématiques dans les chaînes JSON.
  /// - Convertit les caractères accentués en ASCII équivalent
  /// - Préserve les guillemets typographiques dans le contenu
  String _normalizeUnicodeChars(String input) {
    return input
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('å', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ÿ', 'y')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n')
        .replaceAll('À', 'A')
        .replaceAll('Á', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('Ä', 'A')
        .replaceAll('Å', 'A')
        .replaceAll('È', 'E')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('Ì', 'I')
        .replaceAll('Í', 'I')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ò', 'O')
        .replaceAll('Ó', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('Ù', 'U')
        .replaceAll('Ú', 'U')
        .replaceAll('Û', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ý', 'Y')
        .replaceAll('Ç', 'C')
        .replaceAll('Ñ', 'N');
  }

  /// Échappe uniquement les guillemets nus à l'intérieur des chaînes **de valeur**
  /// (pas dans les clés). On s'appuie sur le dernier séparateur significatif vu
  /// ( '{' ',' ':' ) pour deviner si la chaîne qui commence est une clé (avant ':')
  /// ou une valeur (après ':').
  ///
  /// Hypothèses : JSON/JSON5 classique sans bizarreries de multi-lignes pour les clés.
  String _escapeBareQuotesOnlyInValueStrings(String input) {
    final sb = StringBuffer();

    bool inString = false;
    String quoteChar = '"';
    bool escape = false;

    // Quand on entre dans une string, on marque si c'est une clé ou une valeur.
    bool inKeyString = false;
    bool inValueString = false;

    // Dernier séparateur « significatif » rencontré hors string, pour décider le contexte
    // '{' ou ','  => prochaine string est probablement une clé
    // ':'         => prochaine string est probablement une valeur
    String? lastSig; // '{', ',', ':'

    // helper: retourne le prochain non-espace (ou '\u0000' si fin)
    String nextNonWsChar(int from) {
      for (int j = from; j < input.length; j++) {
        final ch = input[j];
        if (ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r') return ch;
      }
      return '\u0000';
    }

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        // On est hors string : on met à jour lastSig quand on voit { , :
        if (ch == '"' || ch == '\'') {
          // On entre dans une string: décider si c'est une clé ou une valeur
          inString = true;
          quoteChar = ch;

          // Heuristique : si le dernier sig est ':' => valeur ; sinon ( '{' ou ',' ) => clé
          if (lastSig == ':') {
            inKeyString = false;
            inValueString = true;
          } else {
            inKeyString = true;
            inValueString = false;
          }

          sb.write(ch);
          continue;
        }

        // tenir à jour le dernier séparateur significatif
        if (ch == '{' || ch == ',' || ch == ':') {
          lastSig = ch;
        } else if (ch == '}' || ch == ']') {
          // ferme un bloc → reset soft (pas indispensable, mais sain)
          lastSig = null;
        }

        sb.write(ch);
        continue;
      }

      // ----------------------------
      // On est DANS une chaîne
      // ----------------------------
      if (escape) {
        // caractère échappé tel quel
        sb.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\') {
        sb.write(ch);
        escape = true;
        continue;
      }

      if (ch == quoteChar) {
        // Potentiel guillemet de fermeture de la chaîne.
        // Décision : si on est dans une chaîne **valeur**, on échappe ce "ch"
        // UNIQUEMENT s'il n'est PAS un guillemet de fermeture.
        //
        // Pour le savoir, on regarde le prochain non-espace ET le caractère précédent.
        final next = nextNonWsChar(i + 1);
        final prev = i > 0 ? input[i - 1] : '';
        final looksLikeClosing = (next == ',' || next == '}' || next == ']' || next == '\u0000');
        final looksLikeInternal = (prev != ' ' && prev != '\t' && prev != '\n' && prev != '\r' && prev != ',');

        if (inValueString && !looksLikeClosing) {
          // guillemet interne dans la valeur → on l'échappe
          sb.write('\\');
          sb.write(ch);
          continue;
        } else {
          // guillemet de fermeture (ou chaîne de clé) → on ferme
          inString = false;
          inKeyString = false;
          inValueString = false;
          sb.write(ch);

          // Après la fermeture, on ne met PAS à jour lastSig ici :
          // ça se fera naturellement au prochain caractère significatif vu hors string.
          continue;
        }
      }

      // caractère normal dans la string
      sb.write(ch);
    }

    return sb.toString();
  }

  /// Supprime les virgules traînantes **hors chaînes**.
  String _stripTrailingCommas(String s) {
    final sb = StringBuffer();
    bool inStr = false;
    String? q;
    bool esc = false;

    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (!inStr) {
        if (ch == '"' || ch == '\'') {
          inStr = true;
          q = ch;
          sb.write(ch);
          continue;
        }
        if (ch == ',' && i + 1 < s.length) {
          int j = i + 1;
          while (j < s.length && (s[j] == ' ' || s[j] == '\n' || s[j] == '\t')) j++;
          if (j < s.length && (s[j] == ']' || s[j] == '}')) {
            // on skip la virgule
            continue;
          }
        }
        sb.write(ch);
        continue;
      }

      if (esc) {
        sb.write(ch);
        esc = false;
        continue;
      }
      if (ch == '\\') {
        esc = true;
        sb.write(ch);
        continue;
      }
      if (ch == q) {
        inStr = false;
        sb.write(ch);
        continue;
      }
      sb.write(ch);
    }

    return sb.toString();
  }
}