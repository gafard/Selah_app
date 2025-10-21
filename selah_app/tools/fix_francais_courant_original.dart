import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('assets/bibles/francais_courant.json');
  
  if (!file.existsSync()) {
    print('❌ Fichier francais_courant.json non trouvé');
    return;
  }
  
  print('🔧 Correction du fichier original francais_courant.json...');
  
  try {
    // Lire le contenu original
    final content = await file.readAsString();
    print('📄 Taille du fichier: ${content.length} caractères');
    
    // Nettoyage spécifique pour les retours à la ligne dans les versets
    final cleaned = content
        // Nettoyer les caractères de fin de ligne
        .replaceAll('\r\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        // Corriger les retours à la ligne dans les versets (problème principal)
        .replaceAllMapped(
          RegExp(r'"Text":"([^"]*?)\s+([^"]*?)"'),
          (match) => '"Text":"${match.group(1)} ${match.group(2)}"'
        )
        // Nettoyer les espaces multiples
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    
    print('📄 Taille après nettoyage: ${cleaned.length} caractères');
    
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
        print('📚 Nombre de testaments: ${testaments.length}');
        
        if (testaments.isNotEmpty) {
          final firstTestament = testaments.first as Map;
          if (firstTestament.containsKey('Books')) {
            print('✅ Structure Books trouvée');
            final books = firstTestament['Books'] as List;
            print('📚 Nombre de livres: ${books.length}');
            
            if (books.isNotEmpty) {
              final firstBook = books.first as Map;
              if (firstBook.containsKey('Chapters')) {
                print('✅ Structure Chapters trouvée');
                final chapters = firstBook['Chapters'] as List;
                print('📖 Nombre de chapitres: ${chapters.length}');
                
                if (chapters.isNotEmpty) {
                  final firstChapter = chapters.first as Map;
                  if (firstChapter.containsKey('Verses')) {
                    print('✅ Structure Verses trouvée');
                    final verses = firstChapter['Verses'] as List;
                    print('📝 Nombre de versets: ${verses.length}');
                    
                    if (verses.isNotEmpty) {
                      final firstVerse = verses.first as Map;
                      final text = firstVerse['Text'] as String;
                      print('✅ Premier verset: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
                    }
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




