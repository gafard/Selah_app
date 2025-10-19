import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  print('🧪 Test de la fonction _escapeBareDoubleQuotesInsideStrings améliorée');
  
  final testCases = [
    // Cas 1: Guillemets internes simples
    r'{"Text":"Dieu dit : "alors" la lumière fut."}',
    
    // Cas 2: Guillemets internes avec accents
    r'{"Text":"Que la terre produise de la "végétation"!"}',
    
    // Cas 3: Mélange de guillemets internes et de fermeture
    r'{"Text":"Dieu dit : "alors" la lumière fut. "Que la terre produise de la "végétation"!"}',
    
    // Cas 4: Guillemets typographiques (ne doivent pas être échappés)
    r'{"Text":"Jésus a dit : « Je suis le chemin ». Il répète "N\'ayez pas peur!"."}',
    
    // Cas 5: Cas problématique du Francais Courant
    r'{"ID":11,"Text":"Dieu dit "alors": "Que la terre produise de la végétation: des herbes produisant leur semence, et des arbres fruitiers dont chaque espèce porte ses propres graines!" Et cela se réalisa."}',
  ];
  
  final preprocessor = LooseJsonPreprocessor();
  
  for (int i = 0; i < testCases.length; i++) {
    print('\n🔍 Test case ${i + 1}:');
    print('Input: ${testCases[i]}');
    
    final processed = preprocessor.preprocess(testCases[i]);
    print('Output: $processed');
    
    // Vérifier les échappements
    print('Contient \\": ${processed.contains('\\"')}');
    print('Contient ": ${processed.contains('"')}');
    print('Contient ": ${processed.contains('"')}');
    print('Contient «: ${processed.contains('«')}');
    print('Contient »: ${processed.contains('»')}');
    
    try {
      final parsed = JSON5.parse(processed);
      print('✅ JSON5.parse() réussit !');
      print('Parsed: $parsed');
    } catch (e) {
      print('❌ JSON5.parse() échoue: $e');
    }
    print('---');
  }
}