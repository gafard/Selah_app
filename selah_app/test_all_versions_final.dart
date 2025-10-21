import 'dart:io';
import 'package:json5/json5.dart';

void main() {
  print('🧪 Test final de toutes les versions bibliques...');
  
  final files = [
    'assets/bibles/lsg1910.json',
    'assets/bibles/semeur.json', 
    'assets/bibles/francais_courant.json',
    'assets/bibles/Segond 21 (S21).json',
  ];
  
  for (final file in files) {
    try {
      final content = File(file).readAsStringSync();
      print('📄 $file: ${content.length} caractères');
      
      final data = JSON5.parse(content);
      
      if (data is Map && data.containsKey('Testaments')) {
        final testaments = data['Testaments'] as List;
        print('✅ $file: OK (${testaments.length} testaments)');
        
        // Compter les versets pour toutes les versions
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
      } else {
        print('⚠️ $file: Structure inattendue');
      }
    } catch (e) {
      print('❌ $file: $e');
    }
    print('');
  }
}


