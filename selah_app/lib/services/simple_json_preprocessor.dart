import 'package:json5/json5.dart';

/// Préprocesseur JSON simplifié qui se concentre sur les problèmes essentiels
class SimpleJsonPreprocessor {
  final List<String> log = [];

  static Map<String, dynamic> parseOrThrow(String raw, {SimpleJsonPreprocessor? out}) {
    final prep = out ?? SimpleJsonPreprocessor();

    // 1) Essai brut (JSON5 supporte déjà pas mal de relâchements)
    try {
      final data = JSON5.parse(raw);
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const FormatException('Le JSON racine n\'est pas un objet');
    } catch (e) {
      prep.log.add('JSON5 brut a échoué: $e');
    }

    // 2) Réparation simple
    final fixed = prep.preprocess(raw);

    // 3) Second essai
    final data2 = JSON5.parse(fixed);
    if (data2 is Map) return Map<String, dynamic>.from(data2);
    throw const FormatException('Le JSON réparé n\'est pas un objet');
  }

  /// Pipeline simplifié qui se concentre sur les problèmes essentiels
  String preprocess(String raw) {
    var s = raw;

    // 1) Normalisation bas niveau
    s = s.replaceAll('\uFEFF', ''); // BOM
    s = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    log.add('✓ Normalisation des retours + BOM');

    // 2) Convertir les \n littéraux en vrais retours à la ligne
    s = s.replaceAll(r'\n', '\n');
    log.add('✓ \\n littéraux convertis en retours à la ligne');

    // 3) Quoter les clés non-quotées
    final keyLike = RegExp(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', multiLine: true);
    s = s.replaceAllMapped(keyLike, (m) => '${m[1]} "${m[2]}":');
    log.add('✓ Clés non-quotées → "clé":');

    // 4) Réparer les clés coupées par retour à la ligne
    s = _healKeySplits(s);
    log.add('✓ Clés coupées par retour à la ligne réparées');

    // 5) Échapper les guillemets internes dans les chaînes (approche simple)
    s = _escapeQuotesInStrings(s);
    log.add('✓ Guillemets internes échappés');

    // 6) Échapper les apostrophes dans les chaînes
    s = _escapeApostrophesInStrings(s);
    log.add('✓ Apostrophes échappées');

    // 7) Collapser les newlines dans les chaînes
    s = _collapseNewlinesInStrings(s);
    log.add('✓ Newlines dans les chaînes collapsés');

    // 8) Nettoyage final
    s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    log.add('✓ Nettoyage final');

    return s;
  }

  /// Répare les clés coupées par retour à la ligne
  String _healKeySplits(String input) {
    // Pattern: "clé":valeur,\nCléSuivante:
    final pattern = RegExp(
      r'("?[A-Za-z_][A-Za-z0-9_\-]*"?\s*:\s*[^,\}\]]+)\s*,\s*\n+\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:',
      multiLine: true,
    );
    
    return input.replaceAllMapped(pattern, (m) {
      final left = m.group(1)!;
      final rightKey = m.group(2)!;
      return '$left,"$rightKey":';
    });
  }

  /// Échappe les guillemets internes dans les chaînes (approche simple)
  String _escapeQuotesInStrings(String input) {
    final sb = StringBuffer();
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        if (ch == '"') {
          inString = true;
        }
        sb.write(ch);
        continue;
      }

      if (escape) {
        sb.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\') {
        sb.write(ch);
        escape = true;
        continue;
      }

      if (ch == '"') {
        // Vérifier si c'est un guillemet de fermeture
        final next = _nextNonWsChar(input, i + 1);
        if (next == ',' || next == '}' || next == ']' || next == '\u0000') {
          // Guillemet de fermeture
          inString = false;
          sb.write(ch);
        } else {
          // Guillemet interne - l'échapper
          sb.write('\\');
          sb.write(ch);
        }
        continue;
      }

      sb.write(ch);
    }

    return sb.toString();
  }

  /// Échappe les apostrophes dans les chaînes
  String _escapeApostrophesInStrings(String input) {
    final sb = StringBuffer();
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        if (ch == '"') {
          inString = true;
        }
        sb.write(ch);
        continue;
      }

      if (escape) {
        sb.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\') {
        sb.write(ch);
        escape = true;
        continue;
      }

      if (ch == '"') {
        inString = false;
        sb.write(ch);
        continue;
      }

      if (ch == '\'') {
        sb.write('\\');
        sb.write(ch);
        continue;
      }

      sb.write(ch);
    }

    return sb.toString();
  }

  /// Collapse les newlines dans les chaînes
  String _collapseNewlinesInStrings(String input) {
    final sb = StringBuffer();
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];

      if (!inString) {
        if (ch == '"') {
          inString = true;
        }
        sb.write(ch);
        continue;
      }

      if (escape) {
        sb.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\') {
        sb.write(ch);
        escape = true;
        continue;
      }

      if (ch == '"') {
        inString = false;
        sb.write(ch);
        continue;
      }

      if (ch == '\n') {
        sb.write(' ');
        continue;
      }

      sb.write(ch);
    }

    return sb.toString();
  }

  /// Trouve le prochain caractère non-espace
  String _nextNonWsChar(String input, int start) {
    for (int i = start; i < input.length; i++) {
      final ch = input[i];
      if (ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r') {
        return ch;
      }
    }
    return '\u0000';
  }
}


