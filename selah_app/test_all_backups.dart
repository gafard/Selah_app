import 'dart:io';
import 'package:json5/json5.dart';

void main() {
  print('🧪 Test de toutes les versions backup...');
  
  final files = [
    'assets/bibles/_backup/lsg1910.json',
    'assets/bibles/_backup/semeur.json', 
    'assets/bibles/_backup/francais_courant.json',
  ];
  
  for (final file in files) {
    try {
      final content = File(file).readAsStringSync();
      print('📄 $file: ${content.length} caractères');
      
      final data = JSON5.parse(content);
      
      if (data is Map && data.containsKey('Testaments')) {
        final testaments = data['Testaments'] as List;
        print('✅ $file: OK (${testaments.length} testaments)');
      } else {
        print('⚠️ $file: Structure inattendue');
      }
    } catch (e) {
      print('❌ $file: $e');
    }
    print('');
  }
}



