import 'dart:io';
import 'dart:convert';
import 'package:json5/json5.dart';

void main(List<String> args) async {
  final inPath = args.isNotEmpty ? args[0] : 'assets/bibles/francais_courant.json';
  final outPath = args.length > 1 ? args[1] : 'assets/bibles/francais_courant.fixed.json5';

  print('🔧 Réparation d\'encodage pour $inPath...');
  
  // Lire le fichier en tant que bytes pour préserver l'encodage original
  final bytes = await File(inPath).readAsBytes();
  print('📄 Taille originale: ${bytes.length} bytes');

  // Convertir en UTF-8 avec gestion des caractères problématiques
  String content;
  try {
    // Essayer UTF-8 d'abord
    content = const Utf8Decoder(allowMalformed: true).convert(bytes);
    print('✅ Conversion UTF-8 réussie');
  } catch (e) {
    print('⚠️ Erreur UTF-8: $e');
    // Fallback: conversion caractère par caractère
    content = _convertBytesToString(bytes);
    print('⚠️ Utilisation de la conversion manuelle');
  }

  // Nettoyage des caractères problématiques
  var s = content
      .replaceAll('\uFEFF', '') // BOM
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  // Correction des guillemets typographiques
  s = s
      .replaceAll('\u201C', '"')
      .replaceAll('\u201D', '"')
      .replaceAll('\u201E', '"')
      .replaceAll('\u201F', '"')
      .replaceAll('\u00AB', '"')
      .replaceAll('\u00BB', '"')
      .replaceAll('\u2018', '\'')
      .replaceAll('\u2019', '\'')
      .replaceAll('\u2032', '\'')
      .replaceAll('\u2033', '"');

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

  // Validation JSON5
  dynamic data;
  try {
    data = JSON5.parse(s);
    print('✅ JSON5 parsé avec succès');
  } catch (e) {
    print('❌ Échec JSON5: $e');
    
    // Nettoyage agressif des caractères non-ASCII
    s = s
        .replaceAll(RegExp(r'[^\x20-\x7E\u00C0-\u017F]'), ' ') // garder ASCII + français
        .replaceAll(RegExp(r'\s{2,}'), ' ') // espaces multiples
        .trim();
    
    try {
      data = JSON5.parse(s);
      print('✅ JSON5 parsé après nettoyage agressif');
    } catch (e2) {
      print('❌ Échec final: $e2');
      rethrow;
    }
  }

  // Sauvegarde
  await File(outPath).writeAsString(s);
  print('✅ Fichier réparé écrit dans: $outPath');
  print('📄 Taille après réparation: ${s.length} caractères');

  // Vérification de la structure
  if (data is Map && data.containsKey('Testaments')) {
    print('✅ Structure Testaments trouvée');
    final testaments = data['Testaments'] as List;
    print('📚 Nombre de testaments: ${testaments.length}');
    
    if (testaments.isNotEmpty) {
      final firstTestament = testaments.first as Map;
      if (firstTestament.containsKey('Books')) {
        final books = firstTestament['Books'] as List;
        print('📚 Nombre de livres: ${books.length}');
        
        // Compter les versets
        int totalVerses = 0;
        for (final book in books) {
          if (book is Map && book.containsKey('Chapters')) {
            final chapters = book['Chapters'] as List;
            for (final chapter in chapters) {
              if (chapter is Map && chapter.containsKey('Verses')) {
                final verses = chapter['Verses'] as List;
                totalVerses += verses.length;
              }
            }
          }
        }
        print('📝 Nombre total de versets: $totalVerses');
      }
    }
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

/// Conversion manuelle des bytes en string avec gestion des caractères Windows-1252
String _convertBytesToString(List<int> bytes) {
  final sb = StringBuffer();
  
  for (int i = 0; i < bytes.length; i++) {
    final byte = bytes[i];
    
    if (byte < 128) {
      // ASCII standard
      sb.writeCharCode(byte);
    } else if (byte >= 128 && byte <= 159) {
      // Caractères Windows-1252 problématiques → remplacement
      switch (byte) {
        case 128: sb.write('€'); break;
        case 130: sb.write(','); break;
        case 131: sb.write('ƒ'); break;
        case 132: sb.write('"'); break;
        case 133: sb.write('…'); break;
        case 134: sb.write('†'); break;
        case 135: sb.write('‡'); break;
        case 136: sb.write('ˆ'); break;
        case 137: sb.write('‰'); break;
        case 138: sb.write('Š'); break;
        case 139: sb.write('‹'); break;
        case 140: sb.write('Œ'); break;
        case 145: sb.write('''); break;
        case 146: sb.write('''); break;
        case 147: sb.write('"'); break;
        case 148: sb.write('"'); break;
        case 149: sb.write('•'); break;
        case 150: sb.write('–'); break;
        case 151: sb.write('—'); break;
        case 152: sb.write('˜'); break;
        case 153: sb.write('™'); break;
        case 154: sb.write('š'); break;
        case 155: sb.write('›'); break;
        case 156: sb.write('œ'); break;
        case 157: sb.write('Ÿ'); break;
        case 158: sb.write('ž'); break;
        case 159: sb.write('Ÿ'); break;
        default: sb.write('?'); break;
      }
    } else {
      // Autres caractères UTF-8
      sb.writeCharCode(byte);
    }
  }
  
  return sb.toString();
}
