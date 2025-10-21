import 'dart:io';
import 'package:json5/json5.dart';
import 'lib/services/simple_json_preprocessor.dart';

void main() async {
  const inPath = 'assets/bibles/Francais courant.repaired.json';
  const outPath = 'assets/bibles/Francais courant.simple_fixed.json';

  print('🧪 Test du SimpleJsonPreprocessor...');
  
  try {
    final preprocessor = SimpleJsonPreprocessor();
    final result = SimpleJsonPreprocessor.parseOrThrow(
      await File(inPath).readAsString(),
      out: preprocessor,
    );
    
    print('✅ Parsing réussi !');
    print('📊 Structure:');
    print('  - Testaments: ${(result['Testaments'] as List).length}');
    
    if (result['Testaments'] is List && (result['Testaments'] as List).isNotEmpty) {
      final firstTestament = (result['Testaments'] as List).first as Map;
      if (firstTestament['Books'] is List) {
        final books = firstTestament['Books'] as List;
        print('  - Livres: ${books.length}');
        
        // Compter les versets
        int totalVerses = 0;
        for (final book in books) {
          if (book is Map && book['Chapters'] is List) {
            final chapters = book['Chapters'] as List;
            for (final chapter in chapters) {
              if (chapter is Map && chapter['Verses'] is List) {
                final verses = chapter['Verses'] as List;
                totalVerses += verses.length;
              }
            }
          }
        }
        print('  - Versets: $totalVerses');
      }
    }
    
    // Sauvegarder le résultat
    await File(outPath).writeAsString(JSON5.stringify(result));
    print('💾 Sauvegardé dans: $outPath');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
