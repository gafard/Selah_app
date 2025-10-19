import 'dart:io';
import 'dart:convert';
import '../lib/services/bible_asset_importer.dart';

void main() async {
  print('🔧 Réparation avec le système de réparation de l\'application...');
  
  final inputFile = File('assets/bibles/semeur.json');
  final outputFile = File('assets/bibles/semeur_app_fixed.json');
  
  if (!await inputFile.exists()) {
    print('❌ Fichier semeur.json non trouvé');
    return;
  }
  
  try {
    String content = await inputFile.readAsString();
    print('📖 Fichier lu: ${content.length} caractères');
    
    // Utiliser le système de réparation de l'application
    try {
      // Simuler le processus d'import de l'application
      String fixedContent = await _repairWithAppSystem(content);
      
      await outputFile.writeAsString(fixedContent);
      print('✅ Fichier réparé sauvegardé: semeur_app_fixed.json');
      
      // Vérifier que le JSON est valide
      try {
        json.decode(fixedContent);
        print('✅ JSON valide confirmé');
      } catch (e) {
        print('❌ JSON invalide: $e');
      }
      
    } catch (e) {
      print('❌ Erreur de réparation: $e');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

Future<String> _repairWithAppSystem(String content) async {
  print('🔧 Utilisation du système de réparation de l\'application...');
  
  // Utiliser le système de réparation de BibleAssetImporter
  try {
    // Simuler le processus d'import
    var data = Map<String, dynamic>.from(json5Decode(content));
    return jsonEncode(data);
  } catch (e) {
    print('⚠️ Erreur JSON5: $e');
    print('🔧 Tentative de réparation automatique...');
    
    // Pipeline de réparation en mémoire amélioré
    var s = content
        .replaceAll('\uFEFF', '') // BOM
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u201C', '"').replaceAll('\u201D', '"')
        .replaceAll('\u201E', '"').replaceAll('\u201F', '"')
        .replaceAll('\u00AB', '"').replaceAll('\u00BB', '"')
        .replaceAll('\u2018', '\'').replaceAll('\u2019', '\'')
        .replaceAll('\u2032', '\'').replaceAll('\u2033', '"');

    // Quotation des clés non-quotées (amélioré)
    final keyLike = RegExp(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', multiLine: true);
    s = s.replaceAllMapped(keyLike, (m) => '${m[1]} "${m[2]}":');

    // NOUVEAU: Correction des sauts de ligne dans les chaînes (plus robuste)
    s = _fixNewlinesInStrings(s);

    // Collapse des newlines dans les strings
    s = _collapseNewlinesInsideQuotes(s);
    
    // NOUVEAU: Correction des guillemets simples dans les chaînes
    s = _fixSingleQuotesInStrings(s);
    
    // Suppression des caractères orphelins
    final orphan = RegExp(r'([,\{\}\[\]])\s*([A-Za-z])\s*([,\}\]\{])');
    for (int i = 0; i < 5; i++) {
      final before = s;
      s = s.replaceAllMapped(orphan, (m) => '${m[1]} ${m[3]}');
      if (s == before) break;
    }

    // Nettoyage agressif des caractères problématiques
    s = s
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ') // caractères de contrôle
        .replaceAll(RegExp(r'[^\x20-\x7E\u00C0-\u017F]'), ' ') // caractères non-ASCII sauf français
        .replaceAll(RegExp(r'\s{2,}'), ' ') // espaces multiples
        .trim();

    try {
      var data = Map<String, dynamic>.from(json5Decode(s));
      print('✅ JSON réparé avec succès');
      return jsonEncode(data);
    } catch (e2) {
      print('❌ Échec de la réparation: $e2');
      throw Exception('FICHIER_CORROMPU_NON_REPARABLE');
    }
  }
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

String _collapseNewlinesInsideQuotes(String input) {
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

