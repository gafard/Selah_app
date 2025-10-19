import 'dart:io';
import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Test du fichier Segond 21 (S21)...');
  
  try {
    final content = File('assets/bibles/Segond 21 (S21).json').readAsStringSync();
    print('📄 Taille: ${content.length} caractères');
    
    final data = JSON5.parse(content);
    
    if (data is Map && data.containsKey('Testaments')) {
      final testaments = data['Testaments'] as List;
      print('✅ Segond 21 (S21): OK (${testaments.length} testaments)');
      
      // Compter les versets
      int totalVerses = 0;
      for (final testament in testaments) {
        if (testament is Map && testament['Books'] is List) {
          final books = testament['Books'] as List;
          print('📚 Livres dans ce testament: ${books.length}');
          
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
        }
      }
      print('📝 Total versets: $totalVerses');
      
    } else {
      print('⚠️ Structure inattendue');
      print('🔍 Clés disponibles: ${data.keys.toList()}');
    }
    
  } catch (e) {
    print('❌ Segond 21 (S21): $e');
    
    // Si ça échoue, essayer de le réparer
    print('🔧 Tentative de réparation...');
    try {
      final rawContent = File('assets/bibles/Segond 21 (S21).json').readAsStringSync();
      print('📄 Taille originale: ${rawContent.length} caractères');
      
      // Appliquer le préprocesseur
      final preprocessor = LooseJsonPreprocessor();
      final processed = preprocessor.preprocess(rawContent);
      print('📄 Taille après traitement: ${processed.length} caractères');
      
      // Tenter de parser
      final data = JSON5.parse(processed);
      
      if (data is Map && data.containsKey('Testaments')) {
        final testaments = data['Testaments'] as List;
        print('✅ Segond 21 (S21) réparé: OK (${testaments.length} testaments)');
        
        // Sauvegarder la version réparée
        File('assets/bibles/Segond 21 (S21).json').writeAsStringSync(processed);
        print('💾 Version réparée sauvegardée');
        
      } else {
        print('⚠️ Structure inattendue après réparation');
      }
      
    } catch (e2) {
      print('❌ Réparation échouée: $e2');
    }
  }
}
