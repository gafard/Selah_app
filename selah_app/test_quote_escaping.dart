import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() {
  final preprocessor = LooseJsonPreprocessor();
  
  // Test case: chaîne avec guillemet interne
  final testInput = '{"Text":"Dieu dit encore: "Qu\'il y ait une voûte, pour séparer les eaux en deux masses!""}';
  
  print('Input: $testInput');
  
  final result = preprocessor.preprocess(testInput);
  print('Output: $result');
  
  try {
    final parsed = JSON5.parse(result);
    print('✅ Parsing successful!');
    print('Parsed: $parsed');
  } catch (e) {
    print('❌ Parsing failed: $e');
  }
}



