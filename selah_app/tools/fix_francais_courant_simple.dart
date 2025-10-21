import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('assets/bibles/francais_courant.json');
  
  if (!file.existsSync()) {
    print('❌ Fichier francais_courant.json non trouvé');
    return;
  }
  
  print('🔧 Correction simple de francais_courant.json...');
  
  try {
    // Lire le contenu
    final content = await file.readAsString();
    
    // Nettoyage simple et efficace
    final cleaned = content
        .replaceAll('\r\n', '\n')  // Windows line endings
        .replaceAll('\r', '\n')    // Mac line endings
        .replaceAll(RegExp(r'\n\s*\n'), '\n')  // Multiple newlines
        .replaceAll(RegExp(r'\s+$'), '')  // Trailing whitespace
        .replaceAll(RegExp(r'^\s+'), '')  // Leading whitespace
        .replaceAll(RegExp(r'\n\s*'), '\n')  // Indentation
        .trim();
    
    // Sauvegarder le fichier nettoyé
    await file.writeAsString(cleaned);
    print('✅ francais_courant.json nettoyé avec succès');
    
    // Tester la validité
    try {
      jsonDecode(cleaned);
      print('✅ JSON valide après nettoyage');
    } catch (e) {
      print('⚠️ JSON invalide après nettoyage: $e');
    }
    
  } catch (e) {
    print('❌ Erreur avec francais_courant.json: $e');
  }
}





