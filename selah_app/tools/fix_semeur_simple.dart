import 'dart:io';

void main() async {
  print('🔧 Réparation simple du fichier semeur.json...');
  
  final inputFile = File('assets/bibles/semeur.json');
  final outputFile = File('assets/bibles/semeur_fixed.json');
  
  if (!await inputFile.exists()) {
    print('❌ Fichier semeur.json non trouvé');
    return;
  }
  
  try {
    String content = await inputFile.readAsString();
    print('📖 Fichier lu: ${content.length} caractères');
    
    // Réparer le JSON de manière simple
    String fixedContent = _fixJsonSimple(content);
    
    await outputFile.writeAsString(fixedContent);
    print('✅ Fichier réparé sauvegardé: semeur_fixed.json');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

String _fixJsonSimple(String content) {
  print('🔧 Application des corrections JSON simples...');
  
  // 1. Ajouter des guillemets autour des clés non quotées
  String fixed = content.replaceAllMapped(
    RegExp(r'(\w+):'),
    (match) => '"${match.group(1)}":',
  );
  
  // 2. Corriger les sauts de ligne dans les chaînes (approche simple)
  fixed = fixed.replaceAll('\n', '\\n');
  
  // 3. Corriger les guillemets simples dans les chaînes
  fixed = fixed.replaceAll("'", "\\'");
  
  print('✅ Corrections appliquées');
  return fixed;
}



