import 'package:json5/json5.dart';
import 'package:selah_app/services/bible_json_preprocessor.dart';

void main() {
  const raw = '''
  {
    "Text":"Jésus dit: "Bonjour" et « salut »."
  }
  ''';
  
  final pre = LooseJsonPreprocessor();
  final fixed = pre.preprocess(raw);

  print('Raw input: $raw');
  print('Fixed output: $fixed');
  
  // Vérifier si les guillemets sont échappés
  print('Contient \\": ${fixed.contains('\\"')}');
  print('Contient ": ${fixed.contains('"')}');
  print('Contient ": ${fixed.contains('"')}');
  
  try {
    final parsed = JSON5.parse(fixed);
    print('✅ JSON5.parse() réussit');
  } catch (e) {
    print('❌ JSON5.parse() échoue: $e');
  }
}




