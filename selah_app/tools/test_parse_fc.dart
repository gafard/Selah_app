import 'dart:io';
import 'package:json5/json5.dart';

void main(List<String> args) async {
  final path = args.isNotEmpty ? args.first : 'assets/bibles/francais_courant.fixed.json5';
  final content = await File(path).readAsString();
  final data = JSON5.parse(content);
  print('✅ JSON5 OK, clés racine: ${data is Map ? (data as Map).keys.take(6).toList() : data.runtimeType}');
}


