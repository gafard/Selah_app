import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  // Test du cas spécifique problématique
  const testCase = r'''
  {"ID":11,"Text":"Dieu dit "alors": "Que la terre produise de la végétation: des herbes produisant leur semence, et des arbres fruitiers dont chaque espèce porte ses propres graines!" Et cela se réalisa."}
  ''';
  
  print('🧪 Test du cas spécifique problématique');
  print('Input: $testCase');
  
  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(testCase);
  
  print('Output: $processed');
  
  // Vérifier si les guillemets typographiques sont échappés
  print('Contient "alors": ${processed.contains('"alors"')}');
  print('Contient \"alors\": ${processed.contains('\\"alors\\"')}');
  
  try {
    final parsed = JSON5.parse(processed);
    print('✅ JSON5.parse() réussit !');
    print('Parsed: $parsed');
  } catch (e) {
    print('❌ JSON5.parse() échoue: $e');
  }
}



