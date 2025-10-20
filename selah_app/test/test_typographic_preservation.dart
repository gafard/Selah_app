import 'package:json5/json5.dart';
import '../lib/services/bible_json_preprocessor.dart';

void main() {
  const raw = r'''
  {"Text":"Dieu dit : "Que la lumière paraisse!" — "Parole de vie" «Création»"}
  ''';
  
  final pre = LooseJsonPreprocessor();
  final fixed = pre.preprocess(raw);

  print('Raw input: $raw');
  print('Fixed output: $fixed');
  
  // Vérifier la préservation des guillemets typographiques
  print('Contient «: ${fixed.contains('«')}');
  print('Contient »: ${fixed.contains('»')}');
  print('Contient ": ${fixed.contains('"')}');
  print('Contient ": ${fixed.contains('"')}');
  print('Contient —: ${fixed.contains('—')}');
  print('Contient \": ${fixed.contains('\\"')}');
  
  try {
    final parsed = JSON5.parse(fixed);
    print('✅ JSON5.parse() réussit');
    print('Parsed data: $parsed');
  } catch (e) {
    print('❌ JSON5.parse() échoue: $e');
  }
}


