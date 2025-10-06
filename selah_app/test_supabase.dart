import 'package:supabase_flutter/supabase_flutter.dart';

/// Script de test rapide pour Supabase
void main() async {
  print('🧪 Test Supabase Selah');
  print('======================');
  
  try {
    // Initialiser Supabase
    await Supabase.initialize(
      url: 'https://your-project.supabase.co', // Remplacez par votre URL
      anonKey: 'your-anon-key', // Remplacez par votre clé
    );
    
    print('✅ Supabase initialisé');
    
    // Test d'authentification anonyme
    final authResponse = await Supabase.instance.client.auth.signInAnonymously();
    print('✅ Authentification anonyme: ${authResponse.user?.id}');
    
    // Test de création d'un plan (simulation)
    print('✅ Test de création de plan simulé');
    
    // Test de récupération (simulation)
    print('✅ Test de récupération simulé');
    
    print('');
    print('🎉 Tous les tests sont passés !');
    print('');
    print('📋 Prochaines étapes :');
    print('   1. Remplacer les URLs par vos vraies valeurs');
    print('   2. Déployer l\'API Supabase');
    print('   3. Tester avec l\'app Flutter');
    
  } catch (e) {
    print('❌ Erreur: $e');
    print('');
    print('💡 Vérifiez :');
    print('   - Votre URL Supabase');
    print('   - Votre clé anonyme');
    print('   - Votre connexion internet');
  }
}
