import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Debug détaillé de _fixNewlinesInsideStrings');
  
  const testCase = '{"Text":"Dieu créa les êtres humains\ncomme une image de lui-même;\nil les créa homme et femme."}';
  
  print('Input: $testCase');
  print('Length: ${testCase.length}');
  
  // Analyser manuellement les caractères
  print('\n🔍 Analyse manuelle:');
  for (int i = 0; i < testCase.length; i++) {
    final ch = testCase[i];
    if (ch == '\n' || ch == '"' || ch == '\\') {
      print('Position $i: "${ch}" (${ch.codeUnitAt(0)})');
    }
  }
  
  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(testCase);
  
  print('\nOutput: $processed');
  print('Length: ${processed.length}');
  
  // Analyser le résultat
  print('\n🔍 Analyse du résultat:');
  for (int i = 0; i < processed.length; i++) {
    final ch = processed[i];
    if (ch == '\n' || ch == '"' || ch == '\\') {
      print('Position $i: "${ch}" (${ch.codeUnitAt(0)})');
    }
  }
  
  // Test de parsing
  try {
    final parsed = JSON5.parse(processed);
    print('\n✅ JSON5.parse() réussit !');
  } catch (e) {
    print('\n❌ JSON5.parse() échoue: $e');
  }
}
