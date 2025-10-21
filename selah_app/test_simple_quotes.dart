import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Test de la fonction _escapeBareDoubleQuotesInsideStrings améliorée');
  
  // Test simple
  const testCase = '{"Text":"Dieu dit "alors": "Que la terre produise de la végétation!"}';
  
  print('Input: $testCase');
  
  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(testCase);
  
  print('Output: $processed');
  
  // Vérifier les échappements
  print('Contient \\": ${processed.contains('\\"')}');
  print('Contient ": ${processed.contains('"')}');
  print('Contient ": ${processed.contains('"')}');
  
  try {
    final parsed = JSON5.parse(processed);
    print('✅ JSON5.parse() réussit !');
    print('Parsed: $parsed');
  } catch (e) {
    print('❌ JSON5.parse() échoue: $e');
  }
}




