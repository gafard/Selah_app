import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Debug de la logique d\'échappement des guillemets');
  
  const testCase = '{"Text":"Dieu dit "alors": "Que la terre produise de la végétation!"}';
  
  print('Input: $testCase');
  print('Length: ${testCase.length}');
  
  // Analyser manuellement le cas problématique
  print('\n🔍 Analyse manuelle:');
  for (int i = 0; i < testCase.length; i++) {
    final ch = testCase[i];
    if (ch == '"') {
      final prev = i > 0 ? testCase[i - 1] : '';
      final next = i + 1 < testCase.length ? testCase[i + 1] : '\u0000';
      print('Position $i: "$ch" (prev: "$prev", next: "$next")');
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
    if (ch == '"' || ch == '\\') {
      final prev = i > 0 ? processed[i - 1] : '';
      final next = i + 1 < processed.length ? processed[i + 1] : '\u0000';
      print('Position $i: "$ch" (prev: "$prev", next: "$next")');
    }
  }
  
  try {
    final parsed = JSON5.parse(processed);
    print('\n✅ JSON5.parse() réussit !');
    print('Parsed: $parsed');
  } catch (e) {
    print('\n❌ JSON5.parse() échoue: $e');
  }
}


