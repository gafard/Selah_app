import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('assets/bibles/francais_courant.json');
  
  if (!file.existsSync()) {
    print('❌ Fichier francais_courant.json non trouvé');
    return;
  }
  
  print('🔧 Correction spécifique de francais_courant.json...');
  
  try {
    // Lire le contenu
    final content = await file.readAsString();
    
    // Nettoyage agressif pour JSON5
    final cleaned = content
        .replaceAll('\r\n', '\n')  // Windows line endings
        .replaceAll('\r', '\n')    // Mac line endings
        .replaceAll(RegExp(r'\n\s*\n'), '\n')  // Multiple newlines
        .replaceAll(RegExp(r'\s+$'), '')  // Trailing whitespace
        .replaceAll(RegExp(r'^\s+'), '')  // Leading whitespace
        .replaceAll(RegExp(r'\n\s*'), '\n')  // Indentation
        // Correction spécifique pour les caractères problématiques
        .replaceAll(RegExp(r'\n(?=\s*[}\]])'), '')  // Newlines avant } ou ]
        .replaceAll(RegExp(r'(?<=[{\[])\s*\n'), '')  // Newlines après { ou [
        .replaceAll(RegExp(r',\s*\n\s*[}\]])'), '}')  // Virgules finales
        .replaceAll(RegExp(r',\s*\n\s*]'), ']')  // Virgules finales dans arrays
        .trim();
    
    // Valider avec JSON5
    try {
      // Test avec json5 (si disponible) ou json standard
      jsonDecode(cleaned);
      print('✅ francais_courant.json - JSON valide après nettoyage');
    } catch (e) {
      print('⚠️ francais_courant.json - JSON invalide: $e');
      
      // Essayer une correction plus agressive
      final fixed = _fixAggressiveJsonIssues(cleaned);
      try {
        jsonDecode(fixed);
        print('✅ francais_courant.json - Corrigé avec succès');
        await file.writeAsString(fixed);
        return;
      } catch (e2) {
        print('❌ francais_courant.json - Impossible de corriger: $e2');
        return;
      }
    }
    
    // Sauvegarder le fichier nettoyé
    await file.writeAsString(cleaned);
    print('✅ francais_courant.json nettoyé avec succès');
    
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
      // Corriger les newlines problématiques
      .replaceAll(RegExp(r'\n(?=\s*[}\]])'), '')
      .replaceAll(RegExp(r'(?<=[{\[])\s*\n'), '')
      // Nettoyer les espaces multiples
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}




