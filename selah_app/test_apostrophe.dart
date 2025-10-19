import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  // Test simple avec apostrophe
  final testJson = '''
  {
    "Text": "Tels sont les descendants de Cham, répartis d'après leurs clans"
  }
  ''';

  print('🧪 Test JSON original:');
  print(testJson);
  print('');

  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(testJson);
  
  print('🔧 JSON après préprocessing:');
  print(processed);
  print('');

  try {
    final parsed = JSON5.parse(processed);
    print('✅ Parsing réussi !');
    print('Résultat: ${parsed['Text']}');
  } catch (e) {
    print('❌ Erreur de parsing: $e');
  }
}
