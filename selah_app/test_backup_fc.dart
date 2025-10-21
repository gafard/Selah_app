import 'dart:io';
import 'package:json5/json5.dart';

void main() {
  print('🧪 Test de la version backup du Français Courant...');
  
  try {
    final content = File('assets/bibles/_backup/francais_courant.json').readAsStringSync();
    print('📄 Taille: ${content.length} caractères');
    
    final data = JSON5.parse(content);
    
    if (data is Map && data.containsKey('Testaments')) {
      final testaments = data['Testaments'] as List;
      print('✅ _backup/francais_courant.json: OK (${testaments.length} testaments)');
      
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
      
      // Si ça marche, remplacer la version actuelle
      print('🔄 Remplacement de la version actuelle...');
      File('assets/bibles/francais_courant.json').writeAsStringSync(content);
      print('✅ Version backup copiée vers la version active');
      
    } else {
      print('⚠️ Structure inattendue');
    }
  } catch (e) {
    print('❌ _backup/francais_courant.json: $e');
  }
}


