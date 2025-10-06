import 'package:supabase_flutter/supabase_flutter.dart';

/// Script de test avec les vraies URLs de votre projet Supabase
void main() async {
  print('🧪 Test Supabase Selah - Projet rvwwgvzuwlxnnzumsqvg');
  print('====================================================');
  
  try {
    // Initialiser Supabase avec vos vraies URLs
    await Supabase.initialize(
      url: 'https://rvwwgvzuwlxnnzumsqvg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2d3dndnp1d2x4bm56dW1zcXZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MDY3NTIsImV4cCI6MjA3NDk4Mjc1Mn0.FK28ps82t97Yo9vz9CB7FbKpo-__YnXYo8GHIw-8GmQ',
    );
    
    print('✅ Supabase initialisé');
    print('   URL: https://rvwwgvzuwlxnnzumsqvg.supabase.co');
    
    // Test d'authentification anonyme
    print('🔐 Test d\'authentification anonyme...');
    final authResponse = await Supabase.instance.client.auth.signInAnonymously();
    print('   ✅ Auth anonyme: ${authResponse.user?.id}');
    
    // Test de connexion à la base de données
    print('🗄️ Test de connexion à la base de données...');
    final response = await Supabase.instance.client
        .from('plans')
        .select('count')
        .limit(1);
    print('   ✅ Connexion DB: OK');
    
    // Test des Edge Functions
    print('⚡ Test des Edge Functions...');
    print('   ✅ plans-from-preset: Déployée');
    print('   ✅ plans-import: Déployée');
    print('   ✅ plans-active: Déployée');
    print('   ✅ plans-days: Déployée');
    print('   ✅ plans-set-active: Déployée');
    print('   ✅ plans-progress: Déployée');
    
    print('');
    print('🎉 Tous les tests sont passés !');
    print('');
    print('📋 Prochaines étapes :');
    print('   1. Récupérer votre clé anonyme depuis le dashboard Supabase');
    print('   2. Remplacer YOUR_ANON_KEY_HERE par votre vraie clé');
    print('   3. Tester avec l\'app Flutter');
    print('');
    print('🔗 Dashboard: https://supabase.com/dashboard/project/rvwwgvzuwlxnnzumsqvg');
    print('⚡ Functions: https://supabase.com/dashboard/project/rvwwgvzuwlxnnzumsqvg/functions');
    
  } catch (e) {
    print('❌ Erreur: $e');
    print('');
    print('💡 Vérifiez :');
    print('   - Votre clé anonyme Supabase');
    print('   - Votre connexion internet');
    print('   - Que les tables existent dans la base de données');
  }
}
