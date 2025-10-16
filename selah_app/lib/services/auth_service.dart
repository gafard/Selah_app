import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/user_repository.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';

/// Exceptions personnalisées pour une meilleure UX
class AuthException implements Exception {
  final String message;
  final String code;
  final String? suggestion;
  
  AuthException(this.message, this.code, {this.suggestion});
  
  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  
  final _userRepo = UserRepository();

  /// Connexion avec email/password (OFFLINE-FIRST)
  Future<void> signInWithEmail(String email, String password) async {
    // 1️⃣ TOUJOURS vérifier LOCAL en premier
    final localUser = LocalStorageService.getLocalUser();
    
    if (localUser != null && localUser['email'] == email) {
      // Utilisateur local trouvé
      // Vérifier le password si stocké localement
      final storedPasswordHash = localUser['password_hash'] as String?;
      if (storedPasswordHash != null) {
        final passwordHash = password.hashCode.toString(); // Simple hash pour démo
        if (storedPasswordHash == passwordHash) {
          // ✅ Connexion offline réussie
          print('✅ Connexion locale réussie pour $email');
          return;
        } else {
          throw AuthException(
            'Mot de passe incorrect',
            'invalid_password',
            suggestion: 'Vérifiez votre mot de passe.',
          );
        }
      }
      // Pas de password stocké → compte créé online, doit se connecter online
    }
    
    // 2️⃣ Si pas de compte local OU pas de password local → tenter Supabase
    final isOnline = ConnectivityService.instance.isOnline;
    
    if (!isOnline) {
      throw AuthException(
        'Connexion impossible hors-ligne',
        'offline_no_account',
        suggestion: 'Connectez-vous à Internet pour vous connecter, ou créez un compte local.',
      );
    }
    
    // Mode online : utiliser Supabase
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthException(
          'Erreur de connexion',
          'auth_failed',
        );
      }
      
      // Créer un profil local depuis Supabase
      await _createLocalProfileFromSupabase(response.user!);
      
    } on AuthException {
      rethrow;
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('invalid login') || 
          errorMsg.contains('invalid credentials') ||
          errorMsg.contains('user not found')) {
        throw AuthException(
          'Email ou mot de passe incorrect',
          'invalid_credentials',
          suggestion: 'Vérifiez vos identifiants ou créez un compte.',
        );
      } else if (errorMsg.contains('email not confirmed')) {
        throw AuthException(
          'Email non vérifié',
          'email_not_confirmed',
          suggestion: 'Vérifiez votre boîte email pour confirmer votre compte.',
        );
      } else if (errorMsg.contains('network')) {
        throw AuthException(
          'Erreur réseau',
          'network_error',
          suggestion: 'Vérifiez votre connexion Internet.',
        );
      } else {
        throw AuthException(
          'Erreur de connexion: $e',
          'unknown_error',
        );
      }
    }
  }

  /// Inscription avec email/password (OFFLINE-FIRST)
  /// Crée TOUJOURS un utilisateur local, Supabase est optionnel
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    // 1️⃣ Vérifier si l'email existe déjà localement
    final localUser = LocalStorageService.getLocalUser();
    if (localUser != null && localUser['email'] == email) {
      throw AuthException(
        'Un compte local existe déjà avec cet email',
        'email_already_exists',
        suggestion: 'Essayez de vous connecter.',
      );
    }
    
    // 2️⃣ TOUJOURS créer un compte local en premier (OFFLINE-FIRST)
    final passwordHash = password.hashCode.toString(); // Simple hash pour démo
    
    final newUser = await _userRepo.createLocalUser(
      displayName: name,
      email: email,
    );
    
    // Stocker le password hash localement pour permettre connexion offline
    await LocalStorageService.saveLocalUser({
      ...newUser.toJson(),
      'password_hash': passwordHash,
      'needs_supabase_sync': true, // Marquer pour sync future
    });
    
    print('✅ Compte local créé pour $email (offline-first)');
    
    // 3️⃣ Optionnel : tenter sync avec Supabase en arrière-plan (non bloquant)
    final isOnline = ConnectivityService.instance.isOnline;
    if (isOnline) {
      _syncToSupabaseInBackground(email, password, name);
    }
    
    return false; // Toujours offline-first
  }
  
  /// Synchronise avec Supabase en arrière-plan (non bloquant)
  void _syncToSupabaseInBackground(String email, String password, String name) async {
    try {
      print('🔄 Tentative de sync avec Supabase en arrière-plan...');
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );
      
      if (response.user != null) {
        print('✅ Sync Supabase réussie pour $email');
        // Marquer comme synchronisé
        final localUser = LocalStorageService.getLocalUser();
        if (localUser != null) {
          await LocalStorageService.saveLocalUser({
            ...localUser,
            'needs_supabase_sync': false,
            'supabase_user_id': response.user!.id,
          });
        }
      }
    } catch (e) {
      print('⚠️ Sync Supabase échouée (non critique): $e');
      // Pas d'erreur car c'est juste un backup
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    if (!ConnectivityService.instance.isOnline) {
      throw AuthException(
        'Fonctionnalité indisponible hors-ligne',
        'offline_feature',
        suggestion: 'Connectez-vous à Internet pour réinitialiser votre mot de passe.',
      );
    }
    
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException(
        'Erreur lors de la réinitialisation: $e',
        'reset_failed',
      );
    }
  }

  /// Connexion avec Google (future)
  Future<void> signInWithGoogle() async {
    throw AuthException(
      'Connexion Google bientôt disponible',
      'feature_coming_soon',
      suggestion: 'Utilisez email/password pour le moment.',
    );
  }
  
  /// Déconnexion
  Future<void> signOut() async {
    await _userRepo.signOut();
  }
  
  /// Crée un profil local depuis un utilisateur Supabase
  Future<void> _createLocalProfileFromSupabase(User supabaseUser) async {
    final localProfile = {
      'id': supabaseUser.id,
      'email': supabaseUser.email,
      'display_name': supabaseUser.userMetadata?['display_name'] ?? supabaseUser.email,
      'is_complete': false,
      'has_onboarded': false,
      'created_at': supabaseUser.createdAt,
      'updated_at_local': DateTime.now().toIso8601String(),
      'is_local_only': false,
      'supabase_user_id': supabaseUser.id,
    };
    
    await LocalStorageService.saveLocalUser(localProfile);
    print('✅ Profil local créé depuis Supabase pour ${supabaseUser.email}');
  }
}