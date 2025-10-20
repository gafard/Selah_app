import 'dart:io';
import 'package:json5/json5.dart';
import '../lib/services/bible_json_preprocessor.dart';

/// Usage :
/// dart run bin/fix_bible_json.dart "chemin/vers/Francais courant.json"
///
/// Résultat :
/// - Crée un fichier `<nom>.repaired.json` dans le même dossier
/// - Affiche les logs de réparation et indique si le JSON est maintenant valide

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart run bin/fix_bible_json.dart <fichier.json>');
    exit(1);
  }

  final filePath = args.first;
  final file = File(filePath);

  if (!await file.exists()) {
    print('❌ Fichier introuvable: $filePath');
    exit(1);
  }

  print('📖 Lecture du fichier: $filePath...');
  final raw = await file.readAsString();

  final pre = LooseJsonPreprocessor();

  String fixed;
  try {
    fixed = pre.preprocess(raw);
  } catch (e) {
    print('❌ Erreur pendant preprocess(): $e');
    exit(1);
  }

  // Afficher les logs de réparation
  print('\n🧹 Log de préprocessing:');
  for (final l in pre.log) {
    print('  • $l');
  }

  // Vérifier la parseabilité
  bool valid = false;
  try {
    final parsed = JSON5.parse(fixed);
    if (parsed is Map) valid = true;
  } catch (e) {
    print('\n⚠️ JSON toujours invalide: $e');
  }

  // Sauvegarde du résultat
  final output = filePath.replaceAll('.json', '.repaired.json');
  await File(output).writeAsString(fixed);
  print('\n💾 Fichier réparé écrit: $output');
  print('✅ Statut: ${valid ? 'Valide ✅' : 'Toujours invalide ⚠️'}');
}


