import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
import '../lib/services/bible_json_preprocessor.dart';

void main() {
  test('préprocesseur fonctionne sur JSON simple avec clés coupées', () {
    const raw = '''
    {
      "Verses": [
        {"ID":7,
        Text:"Au commencement Dieu créa les cieux et la terre."}
      ]
    }
    ''';
    
    final pre = LooseJsonPreprocessor();
    final fixed = pre.preprocess(raw);

    print('Raw input: $raw');
    print('Fixed output: $fixed');

    // Vérifier que les clés sont réparées
    expect(fixed.contains('"ID":7,"Text":'), isTrue, reason: 'Les clés coupées doivent être réparées');
    
    // Vérifier que le JSON peut être parsé
    expect(() => JSON5.parse(fixed), returnsNormally);
  });
}



