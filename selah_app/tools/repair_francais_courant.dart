import 'dart:io';
import 'dart:convert';
import 'package:json5/json5.dart';

/// Pipeline "lenient" -> "json5 clean" -> "parse"
/// - Corrige guillemets typographiques, clés non-quotées, newlines non échappées, caractères isolés.
void main(List<String> args) async {
  final inPath  = args.isNotEmpty ? args[0] : 'assets/bibles/francais_courant.json';
  final outPath = args.length > 1 ? args[1] : 'assets/bibles/francais_courant.fixed.json5';

  print('🔧 Réparation automatique de $inPath...');
  
  final raw = await File(inPath).readAsString();
  print('📄 Taille originale: ${raw.length} caractères');

  // 1) Normalisations de base
  var s = raw
      .replaceAll('\uFEFF', '') // BOM
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  // 2) Guillemets typographiques → guillemets droits
  s = s
      .replaceAll('\u201C', '"')
      .replaceAll('\u201D', '"')
      .replaceAll('\u201E', '"')
      .replaceAll('\u201F', '"')
      .replaceAll('\u00AB', '"')
      .replaceAll('\u00BB', '"')
      .replaceAll('\u2018', '\'')
      .replaceAll('\u2019', '\'')
      .replaceAll('\u2032', '\'')
      .replaceAll('\u2033', '"');

  // 3) Assainir apostrophes dans les clés (on forcera des clés quotées ensuite)
  //    Exemple: Abbreviation: → "Abbreviation":
  final keyLike = RegExp(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', multiLine: true);
  s = s.replaceAllMapped(keyLike, (m) => '${m[1]} "${m[2]}":');

  // 4) Newlines non échappés à l'intérieur de chaînes → espace
  //    Heuristique: " ... \n ..." (entre guillemets) → " ...  ..."
  //    On rabat les retours à la ligne entre paires de guillemets.
  s = _collapseNewlinesInsideQuotes(s);

  // 5) Caractères orphelins entre délimiteurs, ex: , D ,  ou } D ,
  //    Heuristique sûre: si un mot isolé (1 lettre ou 1 token) se situe
  //    entre séparateurs JSON, on le supprime.
  final orphan = RegExp(r'([,\{\}\[\]])\s*([A-Za-z])\s*([,\}\]\{])');
  for (int i = 0; i < 5; i++) { // quelques passes
    final before = s;
    s = s.replaceAllMapped(orphan, (m) => '${m[1]} ${m[3]}');
    if (s == before) break;
  }

  // 6) Validation JSON5
  dynamic data;
  try {
    data = JSON5.parse(s);
    print('✅ JSON5 parsé avec succès');
  } catch (e) {
    print('❌ Échec JSON5 après réparation: $e');
    
    // Dernier filet de sécurité: nettoyage agressif
    print('🔧 Nettoyage agressif...');
    s = s
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ') // caractères de contrôle
        .replaceAll(RegExp(r'[^\x20-\x7E\u00C0-\u017F\u201C\u201D\u2018\u2019]'), ' ') // caractères non-ASCII sauf français
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

  // 7) Sauvegarde du JSON5 réparé
  await File(outPath).writeAsString(s);
  print('✅ Fichier réparé écrit dans: $outPath');
  print('📄 Taille après réparation: ${s.length} caractères');

  // Vérification de la structure
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

  // (Optionnel) Vérif JSON strict si besoin:
  try {
    final strict = jsonEncode(data);
    final strictPath = outPath.replaceAll('.json5', '.json');
    await File(strictPath).writeAsString(strict);
    print('✅ Version JSON stricte créée: $strictPath');
  } catch (e) {
    print('⚠️ Impossible de créer la version JSON stricte: $e');
  }
}

/// Replace unescaped newlines INSIDE quotes by spaces, conservant le reste.
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

    // inString
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