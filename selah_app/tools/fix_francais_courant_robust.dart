import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('assets/bibles/francais_courant.json');
  
  if (!file.existsSync()) {
    print('❌ Fichier francais_courant.json non trouvé');
    return;
  }
  
  print('🔧 Correction robuste de francais_courant.json...');
  
  try {
    // Lire le contenu
    final content = await file.readAsString();
    
    // Nettoyage robuste de tous les caractères problématiques
    final cleaned = content
        // Nettoyer les caractères de fin de ligne
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Supprimer tous les caractères de contrôle sauf \n et \t
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        // Corriger les retours à la ligne dans les versets
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
      
      // Essayer une correction encore plus agressive
      final aggressive = _fixAggressiveJsonIssues(cleaned);
      try {
        jsonDecode(aggressive);
        print('✅ JSON corrigé avec succès (mode agressif)');
        await file.writeAsString(aggressive);
      } catch (e2) {
        print('❌ Impossible de corriger: $e2');
      }
    }
    
  } catch (e) {
    print('❌ Erreur avec francais_courant.json: $e');
  }
}

String _fixAggressiveJsonIssues(String content) {
  return content
      // Corriger les clés non-quotées
      .replaceAllMapped(
        RegExp(r'(?<=\{|,)\s*([A-Za-zÀ-ÿ0-9 _\-]+)\s*:'),
        (match) => ' "${match.group(1)!.trim()}":'
      )
      // Corriger les guillemets typographiques
      .replaceAll('"', '"')
      .replaceAll('"', '"')
      .replaceAll(''', "'")
      .replaceAll(''', "'")
      // Supprimer les virgules finales
      .replaceAll(RegExp(r',\s*}'), '}')
      .replaceAll(RegExp(r',\s*]'), ']')
      // Nettoyer les espaces multiples
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}



