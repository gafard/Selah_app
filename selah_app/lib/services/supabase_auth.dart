import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SupabaseAuthService {
  static SupabaseClient get client => Supabase.instance.client;
  
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
    // Vérifier d'abord le stockage local
    return _hasLocalUser() || client.auth.currentUser != null;
  }
  
  /// Vérifie si l'utilisateur existe localement
  static bool _hasLocalUser() {
    // TODO: Vérifier dans Hive si un utilisateur local existe
    return false; // Placeholder
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
}
