import 'dart:io';
import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() async {
  print('🔧 Réparation de la version backup du Français Courant...');
  
  try {
    // Lire la version backup
    final rawContent = await File('assets/bibles/_backup/francais_courant.json').readAsString();
    print('📄 Taille originale: ${rawContent.length} caractères');
    
    // Appliquer le préprocesseur
    final preprocessor = LooseJsonPreprocessor();
    final processed = preprocessor.preprocess(rawContent);
    print('📄 Taille après traitement: ${processed.length} caractères');
    
    // Tenter de parser
    final data = JSON5.parse(processed);
    
    if (data is Map && data.containsKey('Testaments')) {
      final testaments = data['Testaments'] as List;
      print('✅ Parsing réussi ! (${testaments.length} testaments)');
      
      // Compter les versets
      int totalVerses = 0;
      for (final testament in testaments) {
        if (testament is Map && testament['Books'] is List) {
          final books = testament['Books'] as List;
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
      
      // Sauvegarder la version réparée
      await File('assets/bibles/francais_courant.json').writeAsString(processed);
      print('💾 Version réparée sauvegardée');
      
    } else {
      print('⚠️ Structure inattendue après réparation');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}


