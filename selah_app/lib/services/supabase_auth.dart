import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';

class SupabaseAuthService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Variable statique pour gérer l'état de suppression offline-first
  static bool _accountMarkedForDeletion = false;
  
  /// Vérifie la connectivité réseau
  static Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  /// Récupère le token d'authentification actuel (seulement si en ligne)
  static Future<String?> getCurrentToken() async {
    if (!await isOnline) return null; // Pas de token si offline
    final session = client.auth.currentSession;
    return session?.accessToken;
  }
  
  /// Vérifie si l'utilisateur est connecté (localement ou en ligne)
  static bool get isAuthenticated {
    // Vérifier d'abord si le compte a été marqué pour suppression
    if (_isAccountMarkedForDeletion()) {
      return false;
    }
    // Vérifier ensuite le stockage local
    return _hasLocalUser() || client.auth.currentUser != null;
  }
  
  /// Vérifie si l'utilisateur existe localement
  static bool _hasLocalUser() {
    try {
      return LocalStorageService.hasLocalUser();
    } catch (e) {
      print('❌ Erreur vérification utilisateur local: $e');
      return false;
    }
  }
  
  /// Vérifie si le compte a été marqué pour suppression
  static bool _isAccountMarkedForDeletion() {
    return _accountMarkedForDeletion;
  }
  
  /// Récupère l'ID de l'utilisateur actuel (local ou distant)
  static String? get currentUserId {
    // Priorité au stockage local
    final localUserId = _getLocalUserId();
    if (localUserId != null) return localUserId;
    
    // Fallback sur Supabase si en ligne
    return client.auth.currentUser?.id;
  }
  
  /// Récupère l'ID utilisateur local
  static String? _getLocalUserId() {
    try {
      final localUser = LocalStorageService.getLocalUser();
      return localUser?['id'] as String?;
    } catch (e) {
      print('❌ Erreur récupération ID local: $e');
      return null;
    }
  }
  
  /// Création de compte (nécessite une connexion)
  static Future<AuthResponse?> createAccount({
    required String email,
    required String password,
  }) async {
    if (!await isOnline) {
      throw Exception('Connexion Internet requise pour créer un compte');
    }
    
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );
    
    // Sauvegarder localement après création réussie
    if (response.user != null) {
      await _saveUserLocally(response.user!);
    }
    
    return response;
  }
  
  /// Connexion (nécessite une connexion)
  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!await isOnline) {
      throw Exception('Connexion Internet requise pour se connecter');
    }
    
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // Sauvegarder localement après connexion réussie
    if (response.user != null) {
      await _saveUserLocally(response.user!);
    }
    
    return response;
  }
  
  /// Sauvegarde locale de l'utilisateur
  static Future<void> _saveUserLocally(User user) async {
    try {
      final userData = {
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['display_name'] ?? user.email?.split('@').first,
        'is_complete': false,
        'has_onboarded': false,
        'current_plan_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'needs_supabase_sync': false, // Déjà synchronisé avec Supabase
      };
      
      await LocalStorageService.saveLocalUser(userData);
      print('✅ Utilisateur sauvegardé localement: ${user.id}');
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
    }
  }
  
  /// Mode offline : création d'un utilisateur local temporaire
  static Future<String> createOfflineUser() async {
    final offlineUserId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final userData = {
        'id': offlineUserId,
        'email': 'offline@local.com',
        'display_name': 'Utilisateur Offline',
        'is_complete': false,
        'has_onboarded': false,
        'current_plan_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'needs_supabase_sync': true, // Besoin de sync quand en ligne
      };
      
      await LocalStorageService.saveLocalUser(userData);
      print('✅ Utilisateur offline créé et sauvegardé: $offlineUserId');
    } catch (e) {
      print('❌ Erreur création utilisateur offline: $e');
    }
    
    return offlineUserId;
  }
  
  /// Écoute les changements d'authentification
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Déconnexion
  static Future<void> signOut() async {
    try {
      // Déconnexion Supabase si en ligne
      await client.auth.signOut();
    } catch (e) {
      print('⚠️ Erreur déconnexion Supabase: $e');
    }
    
    // Nettoyer le stockage local
    try {
      await LocalStorageService.clearLocalUser();
      print('✅ Utilisateur déconnecté et données locales nettoyées');
    } catch (e) {
      print('❌ Erreur nettoyage local: $e');
    }
  }
  
  /// Suppression du compte utilisateur (OFFLINE-FIRST)
  static Future<void> deleteAccount() async {
    // Dans une architecture offline-first, on marque le compte comme supprimé localement
    // et on synchronise la suppression quand on sera en ligne
    
    // 1. Marquer le compte comme supprimé dans le stockage local
    await _markAccountForDeletion();
    
    // 2. Déconnecter l'utilisateur
    await signOut();
    
    // 3. Si en ligne, tenter la suppression côté serveur
    if (await isOnline) {
      try {
        final user = client.auth.currentUser;
        if (user != null) {
          await client.auth.admin.deleteUser(user.id);
        }
      } catch (e) {
        // Si la suppression côté serveur échoue, on garde la marque locale
        print('⚠️ Suppression côté serveur échouée, marque locale conservée: $e');
      }
    }
  }
  
  /// Marque le compte pour suppression dans le stockage local
  static Future<void> _markAccountForDeletion() async {
    try {
      // Marquer localement
      _accountMarkedForDeletion = true;
      
      // Persister dans SharedPreferences pour la prochaine session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('account_deleted', true);
      await prefs.setString('deletion_timestamp', DateTime.now().toIso8601String());
      print('🗑️ Compte marqué pour suppression locale');
    } catch (e) {
      print('⚠️ Erreur lors du marquage pour suppression: $e');
    }
  }
  
  /// Initialise l'état de suppression au démarrage de l'application
  static Future<void> initializeDeletionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accountMarkedForDeletion = prefs.getBool('account_deleted') ?? false;
      if (_accountMarkedForDeletion) {
        print('🗑️ Compte marqué pour suppression détecté au démarrage');
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation de l\'état de suppression: $e');
    }
  }
}
