import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Test de _fixNewlinesInsideStrings');
  
  const testCase = '{"Text":"Dieu créa les êtres humains\ncomme une image de lui-même;\nil les créa homme et femme."}';
  
  print('Input: $testCase');
  
  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(testCase);
  
  print('Output: $processed');
  
  // Vérifier si les retours à la ligne sont échappés
  print('Contient \\n: ${processed.contains('\\n')}');
  print('Contient vrais retours: ${processed.contains('\n')}');
}



