import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'assets/bibles/francais_courant.json';
  final offset = args.length > 1 ? int.parse(args[1]) : 460;
  
  final content = await File(path).readAsBytes();
  final start = (offset - 20).clamp(0, content.length);
  final end = (offset + 20).clamp(0, content.length);
  final slice = content.sublist(start, end);
  final asText = const Utf8Decoder(allowMalformed: true).convert(slice);
  
  print('--- CONTEXTE AUTOUR DE L\'OFFSET $offset ---');
  print('Position: ${offset - start} dans le slice');
  print('Contenu: $asText');
  print('------------------------------');
  
  final char = offset < content.length ? String.fromCharCode(content[offset]) : '<EOF>';
  print('Char @ $offset = "$char" (code ${offset < content.length ? content[offset] : -1})');
  
  // Afficher les codes des caractères autour
  print('Codes autour:');
  for (int i = (offset - 5).clamp(0, content.length); i < (offset + 5).clamp(0, content.length); i++) {
    final c = content[i];
    final char = String.fromCharCode(c);
    print('  $i: $c ($char)');
  }
}



