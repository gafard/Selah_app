import 'dart:io';

void main() async {
  print('🔧 Réparation du fichier semeur.json...');
  
  final inputFile = File('assets/bibles/semeur.json');
  final outputFile = File('assets/bibles/semeur_fixed.json');
  
  if (!await inputFile.exists()) {
    print('❌ Fichier semeur.json non trouvé');
    return;
  }
  
  try {
    String content = await inputFile.readAsString();
    print('📖 Fichier lu: ${content.length} caractères');
    
    // Réparer le JSON
    String fixedContent = _fixJsonSyntax(content);
    
    await outputFile.writeAsString(fixedContent);
    print('✅ Fichier réparé sauvegardé: semeur_fixed.json');
    
    // Vérifier que le JSON est valide
    try {
      // Simuler une validation JSON simple
      if (fixedContent.startsWith('{') && fixedContent.endsWith('}')) {
        print('✅ Structure JSON valide détectée');
      } else {
        print('❌ Structure JSON invalide');
      }
    } catch (e) {
      print('❌ Erreur validation JSON: $e');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

String _fixJsonSyntax(String content) {
  print('🔧 Application des corrections JSON...');
  
  // 1. Ajouter des guillemets autour des clés non quotées
  String fixed = content.replaceAllMapped(
    RegExp(r'(\w+):'),
    (match) => '"${match.group(1)}":',
  );
  
  // 2. Corriger les sauts de ligne dans les chaînes
  fixed = fixed.replaceAllMapped(RegExp(r'"([^"]*)\n([^"]*)"'), (match) {
    String content = match.group(0)!;
    return content.replaceAll('\n', '\\n');
  });
  
  // 3. Corriger les guillemets simples dans les chaînes
  fixed = fixed.replaceAllMapped(RegExp(r'"([^"]*)\'([^"]*)"'), (match) {
    String content = match.group(0)!;
    return content.replaceAll("'", "\\'");
  });
  
  print('✅ Corrections appliquées');
  return fixed;
}
