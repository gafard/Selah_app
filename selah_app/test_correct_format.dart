import 'package:json5/json5.dart';

void main() {
  // Test du format correct
  final testCases = [
    r'{"Text":"Dieu dit \"alors\": \"Que la terre produise...\"}"',
    r'{"Text":"Dieu dit \"alors\": \"Que la terre produise...\"}"',
    r'{"Text":"Dieu dit \"alors\": \"Que la terre produise...\"}"',
  ];
  
  for (int i = 0; i < testCases.length; i++) {
    print('🧪 Test case ${i + 1}:');
    print('Input: ${testCases[i]}');
    
    try {
      final parsed = JSON5.parse(testCases[i]);
      print('✅ JSON5.parse() réussit !');
      print('Parsed: $parsed');
    } catch (e) {
      print('❌ JSON5.parse() échoue: $e');
    }
    print('---');
  }
}

