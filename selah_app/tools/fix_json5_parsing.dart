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
    print('🔧 Correction JSON5 de ${file.path}...');
    
    try {
      // Lire le contenu brut
      final content = await file.readAsString();
      
      // Nettoyage agressif pour JSON5
      final cleaned = content
          .replaceAll('\r\n', '\n')  // Windows line endings
          .replaceAll('\r', '\n')    // Mac line endings
          .replaceAll(RegExp(r'\n\s*\n'), '\n')  // Multiple newlines
          .replaceAll(RegExp(r'\s+$'), '')  // Trailing whitespace
          .replaceAll(RegExp(r'^\s+'), '')  // Leading whitespace
          .replaceAll(RegExp(r'\n\s*'), '\n')  // Indentation
          .trim();
      
      // Valider que c'est du JSON5 valide
      try {
        // Test avec json5 (si disponible) ou json standard
        jsonDecode(cleaned);
        print('✅ ${file.path} - JSON valide');
      } catch (e) {
        print('⚠️ ${file.path} - JSON invalide: $e');
        // Essayer de corriger les problèmes courants
        final fixed = _fixCommonJsonIssues(cleaned);
        try {
          jsonDecode(fixed);
          print('✅ ${file.path} - Corrigé et valide');
          await file.writeAsString(fixed);
        } catch (e2) {
          print('❌ ${file.path} - Impossible de corriger: $e2');
        }
      }
      
    } catch (e) {
      print('❌ Erreur avec ${file.path}: $e');
    }
  }
  
  print('🎉 Correction JSON5 terminée');
}

String _fixCommonJsonIssues(String content) {
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
      .replaceAll(RegExp(r',\s*]'), ']');
}




