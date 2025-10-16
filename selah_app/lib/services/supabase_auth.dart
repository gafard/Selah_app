import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // TODO: Vérifier dans Hive si un utilisateur local existe
    return false; // Placeholder
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
    // TODO: Récupérer depuis Hive
    return null; // Placeholder
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
    // TODO: Sauvegarder dans Hive
    print('Sauvegarde locale de l\'utilisateur: ${user.id}');
  }
  
  /// Mode offline : création d'un utilisateur local temporaire
  static Future<String> createOfflineUser() async {
    final offlineUserId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    // TODO: Sauvegarder dans Hive
    print('Utilisateur offline créé: $offlineUserId');
    return offlineUserId;
  }
  
  /// Écoute les changements d'authentification
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Déconnexion
  static Future<void> signOut() async {
    await client.auth.signOut();
    // TODO: Nettoyer le stockage local
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
