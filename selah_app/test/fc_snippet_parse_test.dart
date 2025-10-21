import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
import 'package:selah_app/services/bible_json_preprocessor.dart';

void main() {
  test('snippet FC: "ID":7,\\nText:" est réparé et parse-able', () {
    const raw = '''
    {"Testaments":[{"Books":[{"Chapters":[{"Verses":[
      {"ID":7,
      Text:"Verset avec «guillemets» et "doubles" – OK"}
    ]}]}]}]}
    ''';
    final pre = LooseJsonPreprocessor();
    final fixed = pre.preprocess(raw);
    expect(() => JSON5.parse(fixed), returnsNormally);
  });
}
