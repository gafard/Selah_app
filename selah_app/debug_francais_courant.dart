import 'dart:io';
import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() async {
  final file = File('assets/bibles/Francais courant.repaired.json');
  final content = await file.readAsString();
  
  print('📄 Analyse du fichier Francais Courant...');
  print('Taille: ${content.length} caractères');
  
  // Trouver la position 1161
  if (content.length > 1161) {
    print('\n🔍 Contexte autour de la position 1161:');
    final start = (1161 - 50).clamp(0, content.length);
    final end = (1161 + 50).clamp(0, content.length);
    final context = content.substring(start, end);
    print('Position ${start}-${end}: $context');
    
    // Afficher les caractères problématiques
    print('\n🔍 Caractères autour de la position 1161:');
    for (int i = 1155; i <= 1165 && i < content.length; i++) {
      final char = content[i];
      final code = char.codeUnitAt(0);
      print('Position $i: "$char" (U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')})');
    }
  }
  
  // Tester le préprocesseur
  print('\n🔧 Test du préprocesseur...');
  final preprocessor = LooseJsonPreprocessor();
  final processed = preprocessor.preprocess(content);
  
  print('Taille après traitement: ${processed.length} caractères');
  
  // Vérifier la position 1161 après traitement
  if (processed.length > 1161) {
    print('\n🔍 Contexte après traitement autour de la position 1161:');
    final start = (1161 - 50).clamp(0, processed.length);
    final end = (1161 + 50).clamp(0, processed.length);
    final context = processed.substring(start, end);
    print('Position ${start}-${end}: $context');
  }
  
  // Tester le parsing
  try {
    final parsed = JSON5.parse(processed);
    print('\n✅ JSON5.parse() réussit !');
  } catch (e) {
    print('\n❌ JSON5.parse() échoue: $e');
    
    // Si c'est une SyntaxException, extraire la position
    if (e.toString().contains('at ')) {
      final match = RegExp(r'at (\d+):(\d+)').firstMatch(e.toString());
      if (match != null) {
        final line = int.parse(match.group(1)!);
        final column = int.parse(match.group(2)!);
        print('Erreur à la ligne $line, colonne $column');
        
        // Afficher le contexte de l'erreur
        final lines = processed.split('\n');
        if (line <= lines.length) {
          final errorLine = lines[line - 1];
          print('Ligne $line: $errorLine');
          if (column <= errorLine.length) {
            final before = errorLine.substring(0, column - 1);
            final at = errorLine.substring(column - 1, column);
            final after = errorLine.substring(column);
            print('Avant: "$before"');
            print('À: "$at"');
            print('Après: "$after"');
          }
        }
      }
    }
  }
}


