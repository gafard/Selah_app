import 'dart:io';
import 'package:json5/json5.dart';
import 'lib/services/bible_json_preprocessor.dart';

void main() async {
  print('🔧 Réparation de la version Semeur...');
  
  try {
    // Lire la version backup
    final rawContent = await File('assets/bibles/_backup/semeur.json').readAsString();
    print('📄 Taille originale: ${rawContent.length} caractères');
    
    // Appliquer le préprocesseur
    final preprocessor = LooseJsonPreprocessor();
    final processed = preprocessor.preprocess(rawContent);
    print('📄 Taille après traitement: ${processed.length} caractères');
    
    // Tenter de parser
    final data = JSON5.parse(processed);
    
    if (data is Map && data.containsKey('Testaments')) {
      final testaments = data['Testaments'] as List;
      print('✅ Parsing réussi ! (${testaments.length} testaments)');
      
      // Sauvegarder la version réparée
      await File('assets/bibles/semeur.json').writeAsString(processed);
      print('💾 Version Semeur réparée sauvegardée');
      
    } else {
      print('⚠️ Structure inattendue après réparation');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

