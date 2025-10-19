import 'dart:io';
import 'dart:convert';
import 'package:json5/json5.dart';

void main() async {
  print('🔧 Réparation directe avec JSON5 du fichier semeur.json...');
  
  final inputFile = File('assets/bibles/semeur.json');
  final outputFile = File('assets/bibles/semeur_direct_fixed.json');
  
  if (!await inputFile.exists()) {
    print('❌ Fichier semeur.json non trouvé');
    return;
  }
  
  try {
    String content = await inputFile.readAsString();
    print('📖 Fichier lu: ${content.length} caractères');
    
    // Utiliser JSON5 pour parser le fichier
    try {
      // Parser avec JSON5
      dynamic parsed = json5Decode(content);
      print('✅ Parsing JSON5 réussi');
      
      // Convertir en JSON valide
      String jsonString = jsonEncode(parsed);
      
      await outputFile.writeAsString(jsonString);
      print('✅ Fichier réparé sauvegardé: semeur_direct_fixed.json');
      
      // Vérifier que le JSON est valide
      try {
        json.decode(jsonString);
        print('✅ JSON valide confirmé');
      } catch (e) {
        print('❌ JSON invalide: $e');
      }
      
    } catch (e) {
      print('❌ Erreur de parsing JSON5: $e');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

