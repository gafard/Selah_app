import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('assets/bibles/francais_courant.json');
  
  if (!file.existsSync()) {
    print('❌ Fichier francais_courant.json non trouvé');
    return;
  }
  
  print('🔧 Correction finale v2 de francais_courant.json...');
  
  try {
    // Lire le contenu
    final content = await file.readAsString();
    
    // Correction spécifique pour les retours à la ligne dans les versets
    final cleaned = content
        // Nettoyer les caractères de fin de ligne Windows/Mac
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Remplacer les retours à la ligne dans les versets par des espaces
        .replaceAllMapped(
          RegExp(r'"Text":"([^"]*?)\n([^"]*?)"'),
          (match) => '"Text":"${match.group(1)} ${match.group(2)}"'
        )
        // Corriger les retours à la ligne dans les structures JSON
        .replaceAll('",\n"Text":', '", "Text":')
        .replaceAll('",\n"ID":', '", "ID":')
        .replaceAll('},\n{', '},{')
        .replaceAll('],\n[', '],[')
        .replaceAll('},\n]', '}]')
        .replaceAll('},\n}', '}}')
        // Nettoyer les espaces multiples
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .trim();
    
    // Sauvegarder le fichier nettoyé
    await file.writeAsString(cleaned);
    print('✅ francais_courant.json nettoyé avec succès');
    
    // Tester la validité
    try {
      final testData = jsonDecode(cleaned);
      print('✅ JSON valide après nettoyage');
      
      // Vérifier la structure
      if (testData is Map && testData.containsKey('Testaments')) {
        print('✅ Structure Testaments trouvée');
        final testaments = testData['Testaments'] as List;
        if (testaments.isNotEmpty) {
          final firstTestament = testaments.first as Map;
          if (firstTestament.containsKey('Books')) {
            print('✅ Structure Books trouvée');
            final books = firstTestament['Books'] as List;
            if (books.isNotEmpty) {
              final firstBook = books.first as Map;
              if (firstBook.containsKey('Chapters')) {
                print('✅ Structure Chapters trouvée');
                final chapters = firstBook['Chapters'] as List;
                if (chapters.isNotEmpty) {
                  final firstChapter = chapters.first as Map;
                  if (firstChapter.containsKey('Verses')) {
                    print('✅ Structure Verses trouvée');
                    final verses = firstChapter['Verses'] as List;
                    print('✅ Premier verset: ${verses.first}');
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ JSON invalide après nettoyage: $e');
    }
    
  } catch (e) {
    print('❌ Erreur avec francais_courant.json: $e');
  }
}


