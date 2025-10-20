import 'dart:io';
import 'package:flutter/services.dart';
import 'package:json5/json5.dart';

/// Test de la réparation intégrée dans BibleAssetImporter
void main() async {
  print('🧪 Test de la réparation intégrée...');
  
  try {
    // Simuler le chargement du fichier problématique
    final file = File('assets/bibles/francais_courant.json');
    final raw = await file.readAsString();
    print('📄 Fichier chargé: ${raw.length} caractères');
    
    // Test du parsing direct (doit échouer)
    try {
      final data = JSON5.parse(raw);
      print('❌ Parsing direct réussi (inattendu)');
    } catch (e) {
      print('✅ Parsing direct échoue comme attendu: $e');
    }
    
    // Test de la réparation (simulation de la logique intégrée)
    print('🔧 Application de la réparation...');
    
    var s = raw
        .replaceAll('\uFEFF', '') // BOM
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u201C', '"').replaceAll('\u201D', '"')
        .replaceAll('\u201E', '"').replaceAll('\u201F', '"')
        .replaceAll('\u00AB', '"').replaceAll('\u00BB', '"')
        .replaceAll('\u2018', '\'').replaceAll('\u2019', '\'')
        .replaceAll('\u2032', '\'').replaceAll('\u2033', '"');

    // Quotation des clés non-quotées
    final keyLike = RegExp(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', multiLine: true);
    s = s.replaceAllMapped(keyLike, (m) => '${m[1]} "${m[2]}":');

    // Collapse des newlines dans les strings
    s = _collapseNewlinesInsideQuotes(s);
    
    // Suppression des caractères orphelins
    final orphan = RegExp(r'([,\{\}\[\]])\s*([A-Za-z])\s*([,\}\]\{])');
    for (int i = 0; i < 5; i++) {
      final before = s;
      s = s.replaceAllMapped(orphan, (m) => '${m[1]} ${m[3]}');
      if (s == before) break;
    }

    // Nettoyage agressif des caractères problématiques
    s = s
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ') // caractères de contrôle
        .replaceAll(RegExp(r'[^\x20-\x7E\u00C0-\u017F]'), ' ') // caractères non-ASCII sauf français
        .replaceAll(RegExp(r'\s{2,}'), ' ') // espaces multiples
        .trim();

    // Test du parsing après réparation
    try {
      final data = JSON5.parse(s);
      print('✅ JSON réparé avec succès !');
      
      if (data is Map && data.containsKey('Testaments')) {
        print('✅ Structure Testaments trouvée');
        final testaments = data['Testaments'] as List;
        print('📚 Nombre de testaments: ${testaments.length}');
      }
      
    } catch (e) {
      print('❌ Échec de la réparation: $e');
    }
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}

/// Replace unescaped newlines INSIDE quotes by spaces
String _collapseNewlinesInsideQuotes(String input) {
  final sb = StringBuffer();
  bool inString = false;
  String quote = '';
  bool escape = false;

  for (int i = 0; i < input.length; i++) {
    final ch = input[i];

    if (!inString) {
      if (ch == '"' || ch == '\'') {
        inString = true;
        quote = ch;
      }
      sb.write(ch);
      continue;
    }

    if (escape) {
      sb.write(ch);
      escape = false;
      continue;
    }

    if (ch == '\\') {
      sb.write(ch);
      escape = true;
      continue;
    }

    if (ch == quote) {
      inString = false;
      sb.write(ch);
      continue;
    }

    if (ch == '\n') {
      sb.write(' ');
      continue;
    }

    sb.write(ch);
  }

  return sb.toString();
}



