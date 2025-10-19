import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔧 Réparation finale v2 du fichier semeur.json...');
  
  final inputFile = File('assets/bibles/semeur.json');
  final outputFile = File('assets/bibles/semeur_final_v2.json');
  
  if (!await inputFile.exists()) {
    print('❌ Fichier semeur.json non trouvé');
    return;
  }
  
  try {
    String content = await inputFile.readAsString();
    print('📖 Fichier lu: ${content.length} caractères');
    
    // Réparation finale v2
    String fixedContent = _fixJsonFinalV2(content);
    
    await outputFile.writeAsString(fixedContent);
    print('✅ Fichier réparé sauvegardé: semeur_final_v2.json');
    
    // Vérifier que le JSON est valide
    try {
      json.decode(fixedContent);
      print('✅ JSON valide confirmé');
    } catch (e) {
      print('❌ JSON invalide: $e');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

String _fixJsonFinalV2(String content) {
  print('🔧 Application des corrections JSON finales v2...');
  
  // 1. Nettoyer les caractères problématiques
  String fixed = content
      .replaceAll('\uFEFF', '') // BOM
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\u201C', '"').replaceAll('\u201D', '"')
      .replaceAll('\u201E', '"').replaceAll('\u201F', '"')
      .replaceAll('\u00AB', '"').replaceAll('\u00BB', '"')
      .replaceAll('\u2018', "'").replaceAll('\u2019', "'")
      .replaceAll('\u2032', "'").replaceAll('\u2033', '"');
  
  // 2. Ajouter des guillemets autour des clés non-quotées
  final keyPattern = RegExp(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', multiLine: true);
  fixed = fixed.replaceAllMapped(keyPattern, (match) {
    return '${match.group(1)} "${match.group(2)}":';
  });
  
  // 3. Corriger les sauts de ligne dans les chaînes
  fixed = _fixNewlinesInStrings(fixed);
  
  // 4. Corriger les guillemets simples dans les chaînes
  fixed = _fixSingleQuotesInStrings(fixed);
  
  // 5. Nettoyer les caractères de contrôle
  fixed = fixed
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  
  // 6. Correction finale des guillemets manquants
  fixed = _fixMissingQuotes(fixed);
  
  // 7. NOUVEAU: Corriger les sauts de ligne non échappés
  fixed = _fixUnescapedNewlines(fixed);
  
  return fixed;
}

String _fixNewlinesInStrings(String input) {
  final sb = StringBuffer();
  bool inString = false;
  String quote = '';
  bool escape = false;

  for (int i = 0; i < input.length; i++) {
    final ch = input[i];

    if (!inString) {
      if (ch == '"' || ch == "'") {
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
      escape = true;
      sb.write(ch);
      continue;
    }

    if (ch == quote) {
      inString = false;
      sb.write(ch);
      continue;
    }

    // Dans une chaîne, remplacer les sauts de ligne par \n
    if (ch == '\n') {
      sb.write('\\n');
    } else {
      sb.write(ch);
    }
  }

  return sb.toString();
}

String _fixSingleQuotesInStrings(String input) {
  final sb = StringBuffer();
  bool inString = false;
  String quote = '';
  bool escape = false;

  for (int i = 0; i < input.length; i++) {
    final ch = input[i];

    if (!inString) {
      if (ch == '"' || ch == "'") {
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
      escape = true;
      sb.write(ch);
      continue;
    }

    if (ch == quote) {
      inString = false;
      sb.write(ch);
      continue;
    }

    // Dans une chaîne, échapper les guillemets simples
    if (ch == "'" && quote == '"') {
      sb.write("\\'");
    } else {
      sb.write(ch);
    }
  }

  return sb.toString();
}

String _fixMissingQuotes(String input) {
  // Corriger les clés manquantes après les virgules
  String fixed = input.replaceAllMapped(
    RegExp(r',\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:'),
    (match) => ', "${match.group(1)}":'
  );
  
  // Corriger les clés manquantes au début des objets
  fixed = fixed.replaceAllMapped(
    RegExp(r'{\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:'),
    (match) => '{ "${match.group(1)}":'
  );
  
  return fixed;
}

String _fixUnescapedNewlines(String input) {
  // Corriger les sauts de ligne non échappés dans le JSON
  // Pattern: "Guid":"...",\n"Testaments"
  String fixed = input.replaceAllMapped(
    RegExp(r'"([^"]*)"\s*,\s*\n\s*"([^"]*)"'),
    (match) => '"${match.group(1)}", "${match.group(2)}"'
  );
  
  // Pattern: "Guid":"...",\n"Testaments"
  fixed = fixed.replaceAllMapped(
    RegExp(r'"([^"]*)"\s*,\s*\n\s*"([^"]*)"'),
    (match) => '"${match.group(1)}", "${match.group(2)}"'
  );
  
  return fixed;
}

