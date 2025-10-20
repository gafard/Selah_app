import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Debug de _fixNewlinesInsideStrings');
  
  const testCase = '{"Text":"Dieu créa les êtres humains\ncomme une image de lui-même;\nil les créa homme et femme."}';
  
  print('Input: $testCase');
  print('Length: ${testCase.length}');
  
  // Analyser manuellement les caractères
  for (int i = 0; i < testCase.length; i++) {
    final ch = testCase[i];
    if (ch == '\n' || ch == '"') {
      print('Position $i: "${ch}" (${ch.codeUnitAt(0)})');
    }
  }
  
  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(testCase);
  
  print('\nOutput: $processed');
  print('Length: ${processed.length}');
  
  // Analyser le résultat
  for (int i = 0; i < processed.length; i++) {
    final ch = processed[i];
    if (ch == '\n' || ch == '"' || ch == '\\') {
      print('Position $i: "${ch}" (${ch.codeUnitAt(0)})');
    }
  }
}


