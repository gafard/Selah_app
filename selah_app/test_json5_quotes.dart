import 'package:json5/json5.dart';

void main() {
  print('Test JSON5 avec guillemets internes');
  
  final testCases = [
    r'{"Text":"Dieu dit alors"}',  // Valide
    r'{"Text":"Dieu dit \"alors\""}',  // Valide avec échappement
    r'{"Text":"Dieu dit "alors""}',  // INVALIDE - guillemets non échappés
  ];
  
  for (int i = 0; i < testCases.length; i++) {
    print('\nTest ${i + 1}: ${testCases[i]}');
    try {
      final parsed = JSON5.parse(testCases[i]);
      print('✅ Valide: $parsed');
    } catch (e) {
      print('❌ Invalide: $e');
    }
  }
}




