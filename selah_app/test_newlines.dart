import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Test de _fixNewlinesInsideStrings');
  
  const testCase = r'{"Text":"Dieu créa les êtres humains
comme une image de lui-même;
il les créa homme et femme."}';
  
  print('Input: $testCase');
  
  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(testCase);
  
  print('Output: $processed');
  
  // Vérifier si les retours à la ligne sont échappés
  print('Contient \\n: ${processed.contains('\\n')}');
  print('Contient vrais retours: ${processed.contains('\n')}');
}



