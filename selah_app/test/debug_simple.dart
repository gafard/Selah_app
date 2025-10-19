import 'package:json5/json5.dart';
import '../lib/services/bible_json_preprocessor.dart';

void main() {
  const raw = '"Hello "world" test"';
  
  final pre = LooseJsonPreprocessor();
  final fixed = pre.preprocess(raw);

  print('Raw input: $raw');
  print('Fixed output: $fixed');
  
  try {
    final parsed = JSON5.parse(fixed);
    print('✅ JSON5.parse() réussit: $parsed');
  } catch (e) {
    print('❌ JSON5.parse() échoue: $e');
  }
}

