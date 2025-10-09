/// ═══════════════════════════════════════════════════════════════════════════
/// GÉNÉRATEUR DE SQUELETTES JSON - Chapitres
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Script utilitaire pour générer des fichiers JSON placeholder
/// pour tous les livres bibliques qui n'ont pas encore de données.
///
/// Usage:
///   dart run tools/generate_chapter_json_skeleton.dart
///
/// Résultat:
///   Crée assets/json/chapters/<slug>.json avec:
///   - 25 versets par chapitre (fallback)
///   - Densité 1.0 (moyenne)
///
/// Ces fichiers sont ensuite à éditer manuellement avec les vraies données.
/// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

// Import relatif (ajuster selon structure)
// Si erreur, copier la classe BibleBook ici directement
import '../lib/services/chapter_index_registry.dart';

/// Nombre de chapitres par livre (canon protestant)
final Map<String, int> chapterCounts = {
  // ═══════════════════════════════════════════════════════════════════════
  // ANCIEN TESTAMENT (39 livres)
  // ═══════════════════════════════════════════════════════════════════════
  
  // Pentateuque
  'genese': 50,
  'exode': 40,
  'levitique': 27,
  'nombres': 36,
  'deuteronome': 34,
  
  // Historiques
  'josue': 24,
  'juges': 21,
  'ruth': 4,
  '1_samuel': 31,
  '2_samuel': 24,
  '1_rois': 22,
  '2_rois': 25,
  '1_chroniques': 29,
  '2_chroniques': 36,
  'esdras': 10,
  'nehemie': 13,
  'esther': 10,
  
  // Poétiques
  'job': 42,
  'psaumes': 150,
  'proverbes': 31,
  'ecclesiaste': 12,
  'cantique': 8,
  
  // Grands prophètes
  'esaie': 66,
  'jeremie': 52,
  'lamentations': 5,
  'ezechiel': 48,
  'daniel': 12,
  
  // Petits prophètes
  'osee': 14,
  'joel': 3,
  'amos': 9,
  'abdias': 1,
  'jonas': 4,
  'michee': 7,
  'nahum': 3,
  'habacuc': 3,
  'sophonie': 3,
  'aggee': 2,
  'zacharie': 14,
  'malachie': 4,
  
  // ═══════════════════════════════════════════════════════════════════════
  // NOUVEAU TESTAMENT (27 livres)
  // ═══════════════════════════════════════════════════════════════════════
  
  // Évangiles
  'matthieu': 28,
  'marc': 16,
  'luc': 24,
  'jean': 21,
  
  // Histoire
  'actes': 28,
  
  // Épîtres de Paul
  'romains': 16,
  '1_corinthiens': 16,
  '2_corinthiens': 13,
  'galates': 6,
  'ephesiens': 6,
  'philippiens': 4,
  'colossiens': 4,
  '1_thessaloniciens': 5,
  '2_thessaloniciens': 3,
  '1_timothee': 6,
  '2_timothee': 4,
  'tite': 3,
  'philemon': 1,
  
  // Épîtres générales
  'hebreux': 13,
  'jacques': 5,
  '1_pierre': 5,
  '2_pierre': 3,
  '1_jean': 5,
  '2_jean': 1,
  '3_jean': 1,
  'jude': 1,
  
  // Apocalypse
  'apocalypse': 22,
};

Future<void> main() async {
  const outDir = 'assets/json/chapters';
  
  // Créer le dossier si nécessaire
  await Directory(outDir).create(recursive: true);
  print('📁 Dossier créé/vérifié: $outDir\n');

  int created = 0;
  int skipped = 0;

  for (final b in ChapterIndexRegistry.books) {
    final path = '$outDir/${b.slug}.json';
    final file = File(path);
    
    if (await file.exists()) {
      print('⏭️  Skip ${b.slug}.json (existe déjà)');
      skipped++;
      continue;
    }

    final totalChapters = chapterCounts[b.slug] ?? 25;
    final map = <String, Map<String, dynamic>>{};
    
    for (int c = 1; c <= totalChapters; c++) {
      map['$c'] = {
        'verses': 25, // Fallback à ajuster manuellement
        'density': 1.0, // Moyenne à ajuster
      };
    }

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(map),
    );
    
    print('✅ Créé ${b.slug}.json ($totalChapters chapitres)');
    created++;
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 RÉSUMÉ');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ Fichiers créés : $created');
  print('⏭️  Fichiers skippés : $skipped');
  print('📦 Total livres : ${ChapterIndexRegistry.totalBooks}');
  print('\n💡 PROCHAINES ÉTAPES:');
  print('   1. Éditer les JSON créés avec les vraies données');
  print('   2. Ajuster "verses" et "density" pour chaque chapitre');
  print('   3. Ajouter les fichiers dans pubspec.yaml (assets)');
  print('   4. Lancer ChapterIndexLoader.loadAll() au boot\n');
}

