import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
import '../lib/services/bible_json_preprocessor.dart';

void main() {
  test('vérifie que les guillemets typographiques ne sont pas altérés', () {
    const raw = r'''
    {
      "Text":"Jésus a dit : « Je suis le chemin ». Il répète "N'ayez pas peur!"."
    }
    ''';
    final pre = LooseJsonPreprocessor();
    final fixed = pre.preprocess(raw);

    print('Raw input: $raw');
    print('Fixed output: $fixed');

    // Les guillemets typographiques doivent être préservés (JSON5 les gère nativement)
    expect(fixed.contains('«'), isTrue, reason: '« doit être présent');
    expect(fixed.contains('»'), isTrue, reason: '» doit être présent');
    expect(fixed.contains('"'), isTrue, reason: '" doit être présent');
    expect(fixed.contains('"'), isTrue, reason: '" doit être présent');
    expect(fixed.contains('N\'ayez'), isTrue, reason: 'L\'apostrophe doit être préservée');

    // L'analyse JSON5 doit réussir
    expect(() => JSON5.parse(fixed), returnsNormally);
  });
}
