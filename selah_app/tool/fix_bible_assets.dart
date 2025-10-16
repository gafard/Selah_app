// tool/fix_bible_assets.dart
import 'dart:convert';
import 'dart:io';

/// Remet des guillemets autour des clés non-quotées en JSON.
/// Exemple:  Testaments:[ ... ]  ->  "Testaments":[ ... ]
String _quoteKeys(String raw) {
  // 1) Protège déjà-quoté: si la clé est déjà "clé":, ne change rien
  // 2) Ajoute des guillemets aux clés non-quotées entre { ou , et :
  final withQuoted = raw.replaceAllMapped(
    RegExp(r'(?<=\{|,)\s*([A-Za-zÀ-ÿ0-9 _\-]+)\s*:', multiLine: true),
    (m) {
      final key = m.group(1)!.trim();
      if (key.startsWith('"') && key.endsWith('"')) return m.group(0)!;
      return ' "$key":';
    },
  );

  // 3) Optionnel: corrige les guillemets typographiques (si présents)
  return withQuoted
      .replaceAll('"', '"')
      .replaceAll('"', '"')
      .replaceAll("'", "'");
}

/// Échappe les guillemets dans les valeurs Text
String _escapeTextValues(String raw) {
  // Cherche tous les patterns Text:"..." et échappe les guillemets internes
  return raw.replaceAllMapped(
    RegExp(r'Text:"([^"]*(?:"[^"]*)*[^"]*)"'),
    (match) {
      final text = match.group(1)!;
      final escapedText = text.replaceAll('"', '\\"');
      return 'Text:"$escapedText"';
    },
  );
}

Map<String, dynamic> _parseLenient(String raw, String path) {
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    // Étape 1: Échapper les guillemets dans les valeurs Text
    String step1 = _escapeTextValues(raw);
    
    // Étape 2: Ajouter des guillemets aux clés
    String step2 = _quoteKeys(step1);
    
    try {
      return jsonDecode(step2) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('❌ $path: JSON invalide même après correction: $e');
    }
  }
}

void _validateStructure(Map<String, dynamic> root, String path) {
  // On s'attend à: { "Testaments": [ { "Books": [ { "Chapters": [ { "Verses": [ { "Text": "..."} ] } ] } ] } ] }
  if (root['Testaments'] is! List) {
    throw Exception('❌ $path: "Testaments" absent ou non-list');
  }
  final testaments = root['Testaments'] as List;
  if (testaments.isEmpty) throw Exception('❌ $path: Testaments[] vide');

  // On vérifie quelques niveaux mais sans imposer le nombre exact
  final t0 = testaments.first;
  if (t0 is! Map || t0['Books'] is! List) {
    throw Exception('❌ $path: testaments[0].Books manquant/incorrect');
  }
  final books = t0['Books'] as List;
  if (books.isEmpty) {
    print('⚠️ $path: Books[] vide dans le premier testament (OK si découpé autrement)');
  } else {
    final b0 = books.first;
    if (b0 is! Map || b0['Chapters'] is! List) {
      throw Exception('❌ $path: testaments[0].books[0].Chapters manquant/incorrect');
    }
    final chapters = b0['Chapters'] as List;
    if (chapters.isEmpty) {
      print('⚠️ $path: Chapters[] vide pour le premier Book');
    } else {
      final c0 = chapters.first;
      if (c0 is! Map || c0['Verses'] is! List) {
        throw Exception('❌ $path: ...Chapters[0].Verses manquant/incorrect');
      }
      final verses = c0['Verses'] as List;
      if (verses.isEmpty) {
        print('⚠️ $path: Verses[] vide pour le premier chapitre');
      } else {
        final v0 = verses.first;
        if (v0 is! Map || v0['Text'] is! String) {
          throw Exception('❌ $path: ...Verses[0].Text manquant/incorrect');
        }
      }
    }
  }
}

Future<void> fixOne(String path) async {
  final file = File(path);
  if (!await file.exists()) throw Exception('Fichier introuvable: $path');

  final raw = await file.readAsString();
  final root = _parseLenient(raw, path);
  _validateStructure(root, path);

  // Ecrit un JSON strict, pretty
  final pretty = const JsonEncoder.withIndent('  ').convert(root);
  await file.writeAsString(pretty);
  print('✅ Corrigé et validé: $path');
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tool/fix_bible_assets.dart <chemin1.json> <chemin2.json> ...');
    exit(64);
  }
  for (final p in args) {
    try {
      await fixOne(p);
    } catch (e) {
      print(e);
      exitCode = 1;
    }
  }
}