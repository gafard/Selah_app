import 'dart:io';
import 'dart:convert';

void main() async {
  final assetsDir = Directory('assets/bibles');
  if (!assetsDir.existsSync()) {
    print('❌ Dossier assets/bibles non trouvé');
    return;
  }

  final jsonFiles = assetsDir.listSync()
      .where((file) => file.path.endsWith('.json'))
      .cast<File>();

  for (final file in jsonFiles) {
    print('🔧 Correction de ${file.path}...');
    
    try {
      // Lire le contenu brut
      final content = await file.readAsString();
      
      // Nettoyer les caractères problématiques
      final cleaned = content
          .replaceAll('\r\n', '\n')  // Windows line endings
          .replaceAll('\r', '\n')    // Mac line endings
          .replaceAll(RegExp(r'\n\s*\n'), '\n')  // Multiple newlines
          .trim();
      
      // Valider que c'est du JSON valide
      jsonDecode(cleaned);
      
      // Sauvegarder le fichier nettoyé
      await file.writeAsString(cleaned);
      print('✅ ${file.path} corrigé avec succès');
      
    } catch (e) {
      print('❌ Erreur avec ${file.path}: $e');
    }
  }
  
  print('🎉 Correction terminée');
}




