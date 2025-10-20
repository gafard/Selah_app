// Test du fichier Francais courant.repaired.json avec le préprocesseur
import 'lib/services/bible_json_preprocessor.dart';
import 'dart:io';

void main() async {
  final file = File('assets/bibles/Francais courant.repaired.json');
  
  if (!await file.exists()) {
    print('❌ Fichier non trouvé: ${file.path}');
    return;
  }
  
  print('=== Test Francais courant.repaired.json ===');
  final raw = await file.readAsString();
  final pre = LooseJsonPreprocessor();
  
  try {
    final data = LooseJsonPreprocessor.parseOrThrow(raw, out: pre);
    print('✅ Parsing réussi!');
    print('Clés principales: ${data.keys.take(5).toList()}');
    
    // Vérifier la structure
    if (data.containsKey('Testaments')) {
      final testaments = data['Testaments'] as List;
      print('Nombre de testaments: ${testaments.length}');
      
      if (testaments.isNotEmpty) {
        final firstTestament = testaments[0] as Map<String, dynamic>;
        if (firstTestament.containsKey('Books')) {
          final books = firstTestament['Books'] as List;
          print('Nombre de livres dans le premier testament: ${books.length}');
          
          if (books.isNotEmpty) {
            final firstBook = books[0] as Map<String, dynamic>;
            if (firstBook.containsKey('Chapters')) {
              final chapters = firstBook['Chapters'] as List;
              print('Nombre de chapitres dans le premier livre: ${chapters.length}');
              
              if (chapters.isNotEmpty) {
                final firstChapter = chapters[0] as Map<String, dynamic>;
                if (firstChapter.containsKey('Verses')) {
                  final verses = firstChapter['Verses'] as List;
                  print('Nombre de versets dans le premier chapitre: ${verses.length}');
                  
                  if (verses.isNotEmpty) {
                    final firstVerse = verses[0] as Map<String, dynamic>;
                    print('Premier verset: ${firstVerse['Text']}');
                  }
                }
              }
            }
          }
        }
      }
    }
    
  } catch (e) {
    print('❌ Erreur de parsing: $e');
    print('Logs de réparation:');
    for (final line in pre.log) {
      print('  $line');
    }
  }
}


