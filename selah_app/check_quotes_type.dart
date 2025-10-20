import 'dart:io';

void main() async {
  final file = File('assets/bibles/Francais courant.repaired.json');
  final content = await file.readAsString();
  
  final idx = content.indexOf('alors');
  if (idx > 0) {
    final snippet = content.substring(idx - 20, idx + 30);
    print('Snippet: $snippet');
    print('');
    print('Codes des caractères:');
    for (int i = 0; i < snippet.length; i++) {
      final char = snippet[i];
      final code = char.codeUnitAt(0);
      if (char == '"' || code == 0x201C || code == 0x201D) {
        print('Position $i: "$char" (U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')})');
      }
    }
  }
}


