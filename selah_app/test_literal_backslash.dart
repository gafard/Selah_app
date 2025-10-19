import 'lib/services/bible_json_preprocessor.dart';

void main() {
  final preprocessor = LooseJsonPreprocessor();
  
  // Test case: \n littéral suivi de clé non quotée (cas du fichier)
  final testInput = '}]},{\\nID:2,"Verses":[{\\nText:"test"}';
  
  print('Input: $testInput');
  
  // Test du pipeline complet
  final fullResult = preprocessor.preprocess(testInput);
  print('Full pipeline: $fullResult');
}
