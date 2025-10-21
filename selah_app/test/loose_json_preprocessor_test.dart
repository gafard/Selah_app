import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
import 'package:selah_app/services/bible_json_preprocessor.dart';

void main() {
  group('LooseJsonPreprocessor', () {
    test('répare "ID":7,\\nText: -> "ID":7,"Text":', () {
      const raw = '''
      { "Verses":[
        {"ID":7,
        Text:"Au commencement…"}
      ]}
      ''';

      final pre = LooseJsonPreprocessor();
      final fixed = pre.preprocess(raw);

      expect(fixed.contains('"ID":7,"Text":'), isTrue, reason: 'La clé "Text" doit être recollée après la virgule + newline');
      // Et cela doit être parse-able
      final obj = JSON5.parse(fixed);
      expect(obj, isA<Map>());
    });

    test('répare générique: "Foo":123,\\nBar: -> "Foo":123,"Bar":', () {
      const raw = '''
      { Foo:123,
      Bar:"ok" }
      ''';

      final pre = LooseJsonPreprocessor();
      final fixed = pre.preprocess(raw);

      expect(fixed.contains('"Foo":123,"Bar":'), isTrue);
      final obj = JSON5.parse(fixed);
      expect(obj, isA<Map>());
    });

    test('préserve les guillemets typographiques dans le contenu', () {
      const raw = r'''
      {
        "Verses":[{"ID":12,"Text":"Jésus dit : « Je suis le chemin ». Puis il ajouta : "N'ayez pas peur"."}]
      }
      ''';
      final pre = LooseJsonPreprocessor();
      final fixed = pre.preprocess(raw);

      // Doit conserver « » et l'apostrophe typographique '
      expect(fixed.contains('«'), isTrue);
      expect(fixed.contains('»'), isTrue);
      // Les guillemets droits internes doivent être échappés
      expect(fixed.contains('\\"'), isTrue);
      expect(fixed.contains("N'ayez"), isTrue);

      // Et rester parse-able
      final obj = JSON5.parse(fixed);
      expect(obj, isA<Map>());
    });

    test('supprime commentaires et virgules traînantes', () {
      const raw = '''
      {
        // commentaire ligne
        Verses: [ 
          { ID:1, Text:"A", }, /* block */
          { ID:2, Text:"B", },
        ],
      }
      ''';

      final pre = LooseJsonPreprocessor();
      final fixed = pre.preprocess(raw);

      // Plus de virgule avant ] ni }
      expect(RegExp(r',\s*[\]\}]').hasMatch(fixed), isFalse);

      // Clés doivent être quotées
      expect(fixed.contains('"Verses"'), isTrue);
      expect(fixed.contains('"ID"'), isTrue);
      expect(fixed.contains('"Text"'), isTrue);

      // Parse OK
      final obj = JSON5.parse(fixed);
      expect(obj, isA<Map>());
    });

    test('newlines DANS les chaines deviennent \\n, sans toucher l exterieur', () {
      const raw = '''
      {"Text":"Ligne 1
Ligne 2", "ID":3}
      ''';

      final pre = LooseJsonPreprocessor();
      final fixed = pre.preprocess(raw);

      // \n à l'intérieur, pas d'ajout ailleurs
      expect(fixed.contains('"Text":"Ligne 1\\nLigne 2"'), isTrue);

      final obj = JSON5.parse(fixed);
      expect(obj, isA<Map>());
    });

    test('répare "ID":7,\\nText:" correctement', () {
      const raw = '''
      {
        "Verses":[
          {"ID":7,
          Text:"Au commencement Dieu créa les cieux"}
        ]
      }
      ''';

      final pre = LooseJsonPreprocessor();
      final fixed = pre.preprocess(raw);

      expect(fixed.contains('"ID":7,"Text":'), isTrue, reason: 'La clé Text doit être recollée proprement');
    });
  });
}
