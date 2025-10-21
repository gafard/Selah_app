import 'dart:io';
import 'package:json5/json5.dart';

/// Pipeline hybride Falcon X + LooseJsonPreprocessor
/// - Approche simple de Falcon X pour les corrections de base
/// - Logique d'échappement des guillemets de LooseJsonPreprocessor
void main(List<String> args) async {
  final inPath  = args.isNotEmpty ? args[0] : 'assets/bibles/francais_courant.json';
  final outPath = args.length > 1 ? args[1] : 'assets/bibles/francais_courant.falcon_hybrid.json';

  print('🚀 Réparation hybride Falcon X de $inPath...');
  
  final raw = await File(inPath).readAsString();
  print('📄 Taille originale: ${raw.length} caractères');

  // 1) Normalisations de base (Falcon X)
  var s = raw
      .replaceAll('\uFEFF', '') // BOM
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  // 2) Convertir les \n littéraux en vrais retours à la ligne
  s = s.replaceAll(r'\n', '\n');

  // 3) Quoter les clés non-quotées (Falcon X)
  final keyLike = RegExp(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', multiLine: true);
  s = s.replaceAllMapped(keyLike, (m) => '${m[1]} "${m[2]}":');

  // 4) Réparer les clés coupées par retour à la ligne
  s = _healKeySplits(s);

  // 5) Échapper les guillemets internes dans les chaînes (LooseJsonPreprocessor)
  s = _escapeBareQuotesOnlyInValueStrings(s);

  // 6) Échapper les apostrophes dans les chaînes
  s = _fixSingleQuotesInStrings(s);

  // 7) Collapser les newlines dans les chaînes (Falcon X)
  s = _collapseNewlinesInsideQuotes(s);

  // 8) Nettoyage des caractères orphelins (Falcon X)
  final orphan = RegExp(r'([,\{\}\[\]])\s*([A-Za-z])\s*([,\}\]\{])');
  for (int i = 0; i < 5; i++) {
    final before = s;
    s = s.replaceAllMapped(orphan, (m) => '${m[1]} ${m[3]}');
    if (s == before) break;
  }

  // 9) Validation JSON5
  dynamic data;
  try {
    data = JSON5.parse(s);
    print('✅ JSON5 parsé avec succès');
  } catch (e) {
    print('❌ Échec JSON5 après réparation: $e');
    
    // 10) Nettoyage agressif (Falcon X)
    print('🔧 Nettoyage agressif...');
    s = s
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ') // caractères de contrôle
        .replaceAll(RegExp(r'[^\x20-\x7E\u00C0-\u017F]'), ' ') // caractères non-ASCII sauf français
        .replaceAll(RegExp(r'\s{2,}'), ' ') // espaces multiples
        .trim();
    
    try {
      data = JSON5.parse(s);
      print('✅ JSON5 parsé après nettoyage agressif');
    } catch (e2) {
      print('❌ Échec final après nettoyage agressif: $e2');
      print('📄 Taille du contenu: ${s.length}');
      print('📄 Premiers 200 caractères: ${s.substring(0, s.length > 200 ? 200 : s.length)}');
      rethrow;
    }
  }

  // 11) Sauvegarde
  await File(outPath).writeAsString(s);
  print('✅ Fichier réparé écrit dans: $outPath');
  print('📄 Taille après réparation: ${s.length} caractères');

  // 12) Vérification de la structure
  if (data is Map && data.containsKey('Testaments')) {
    print('✅ Structure Testaments trouvée');
    final testaments = data['Testaments'] as List;
    print('📚 Nombre de testaments: ${testaments.length}');
    
    if (testaments.isNotEmpty) {
      final firstTestament = testaments.first as Map;
      if (firstTestament.containsKey('Books')) {
        final books = firstTestament['Books'] as List;
        print('📚 Nombre de livres: ${books.length}');
        
        // Compter les versets
        int totalVerses = 0;
        for (final book in books) {
          if (book is Map && book.containsKey('Chapters')) {
            final chapters = book['Chapters'] as List;
            for (final chapter in chapters) {
              if (chapter is Map && chapter.containsKey('Verses')) {
                final verses = chapter['Verses'] as List;
                totalVerses += verses.length;
              }
            }
          }
        }
        print('📝 Nombre total de versets: $totalVerses');
      }
    }
  }
}

/// Répare les clés coupées par retour à la ligne
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

/// Échappe uniquement les guillemets nus à l'intérieur des chaînes **de valeur**
String _escapeBareQuotesOnlyInValueStrings(String input) {
  final sb = StringBuffer();
  bool inString = false;
  String? quoteChar;
  bool escape = false;
  bool inKeyString = false;
  bool inValueString = false;
  String lastSig = '';

  for (int i = 0; i < input.length; i++) {
    final ch = input[i];

    if (!inString) {
      if (ch == '"' || ch == '\'') {
        inString = true;
        quoteChar = ch;
        // Deviner si c'est une clé ou une valeur
        if (lastSig == ':' || lastSig == ',') {
          inValueString = true;
        } else {
          inKeyString = true;
        }
      } else if (ch == '{' || ch == ',' || ch == ':') {
        lastSig = ch;
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

    if (ch == quoteChar) {
      final next = _nextNonWsChar(input, i + 1);
      final looksLikeClosing = (next == ',' || next == '}' || next == ']' || next == '\u0000');

      if (inValueString && !looksLikeClosing) {
        sb.write('\\');
        sb.write(ch);
        continue;
      } else {
        inString = false;
        inKeyString = false;
        inValueString = false;
        sb.write(ch);
        continue;
      }
    }

    sb.write(ch);
  }

  return sb.toString();
}

/// Échappe les apostrophes dans les chaînes JSON délimitées par des guillemets doubles
String _fixSingleQuotesInStrings(String input) {
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
      escape = true;
      sb.write(ch);
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

/// Replace unescaped newlines INSIDE quotes by spaces
String _collapseNewlinesInsideQuotes(String input) {
  final sb = StringBuffer();
  bool inString = false;
  String quote = '';
  bool escape = false;

  for (int i = 0; i < input.length; i++) {
    final ch = input[i];

    if (!inString) {
      if (ch == '"' || ch == '\'') {
        inString = true;
        quote = ch;
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

    if (ch == quote) {
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



