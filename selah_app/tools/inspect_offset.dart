import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  final path = args.isNotEmpty ? args.first : 'assets/bibles/francais_courant.json';
  final content = await File(path).readAsBytes();
  const offset = 8862; // <-- l'offset signalé
  final start = (offset - 80).clamp(0, content.length);
  final end = (offset + 80).clamp(0, content.length);
  final slice = content.sublist(start, end);
  final asText = const Utf8Decoder(allowMalformed: true).convert(slice);
  print('--- CONTEXTE ($start..$end) ---\n$asText\n------------------------------');
  final char = offset < content.length ? String.fromCharCode(content[offset]) : '<EOF>';
  print('Char @ $offset = "$char" (code ${offset < content.length ? content[offset] : -1})');
}