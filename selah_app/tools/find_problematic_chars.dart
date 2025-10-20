import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  final path = args.isNotEmpty ? args.first : 'assets/bibles/francais_courant.json';
  final content = await File(path).readAsBytes();
  
  print('🔍 Recherche de caractères problématiques dans $path...');
  print('📄 Taille: ${content.length} bytes');
  
  final problematic = <int, List<int>>{};
  
  for (int i = 0; i < content.length; i++) {
    final byte = content[i];
    final char = String.fromCharCode(byte);
    
    // Caractères potentiellement problématiques
    if (byte < 32 && byte != 9 && byte != 10 && byte != 13) { // contrôles sauf tab, LF, CR
      problematic.putIfAbsent(byte, () => []).add(i);
    } else if (byte > 126 && byte < 160) { // caractères étendus
      problematic.putIfAbsent(byte, () => []).add(i);
    } else if (byte > 255) { // UTF-8 multi-byte
      // Vérifier si c'est un caractère valide UTF-8
      if (i + 1 < content.length) {
        final next = content[i + 1];
        if (byte == 0xC2 || byte == 0xC3) {
          // UTF-8 valide, continuer
        } else {
          problematic.putIfAbsent(byte, () => []).add(i);
        }
      }
    }
  }
  
  if (problematic.isEmpty) {
    print('✅ Aucun caractère problématique trouvé');
  } else {
    print('❌ Caractères problématiques trouvés:');
    for (final entry in problematic.entries) {
      final byte = entry.key;
      final positions = entry.value;
      final char = String.fromCharCode(byte);
      print('  Code $byte ($char): ${positions.length} occurrences');
      if (positions.length <= 10) {
        print('    Positions: ${positions.take(10).join(', ')}');
      } else {
        print('    Premières positions: ${positions.take(10).join(', ')}...');
      }
    }
  }
  
  // Afficher les premiers 500 caractères pour inspection
  print('\n📄 Premiers 500 caractères:');
  final preview = content.take(500).map((b) => String.fromCharCode(b)).join();
  print(preview);
}



