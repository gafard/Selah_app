// dart run bin/repair_bible_json.dart "/chemin/Francais courant.json" "/chemin/out.json"

import 'dart:io';
import 'package:json5/json5.dart';
import 'package:path/path.dart' as p;
import '../lib/services/bible_json_preprocessor.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run bin/repair_bible_json.dart <in.json> [out.json]');
    exit(1);
  }
  final inPath = args[0];
  final outPath = args.length > 1
      ? args[1]
      : p.setExtension(inPath, '.repaired.json');

  final raw = await File(inPath).readAsString();

  final pre = LooseJsonPreprocessor();
  try {
    // 1) Essai brut
    JSON5.parse(raw);
    print('✅ Le fichier est directement parseable (JSON5)');
    await File(outPath).writeAsString(raw);
    print('→ Copié tel quel vers: $outPath');
    return;
  } catch (_) {
    // continue
  }

  // 2) Réparer
  final fixed = pre.preprocess(raw);
  for (final line in pre.log) {
    print('🧹 $line');
  }

  // 3) Validation
  try {
    JSON5.parse(fixed);
    print('✅ Réparation OK — JSON5.parse() passe');
  } catch (e) {
    print('❌ JSON5.parse() échoue encore après réparation: $e');
    // On écrit quand même pour inspection
  }

  await File(outPath).writeAsString(fixed);
  print('💾 Écrit: $outPath');
}

