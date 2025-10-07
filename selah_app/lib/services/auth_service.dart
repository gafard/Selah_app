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
      
      // Sauvegarder localement
      await _userRepo.getCurrentUser(); // Fetch et save
      
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
  /// Retourne true si online (email confirmation requis), false si offline
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
    
    final isOnline = ConnectivityService.instance.isOnline;
    
    if (!isOnline) {
      // 2️⃣ Mode offline : créer compte local COMPLET
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
      
      print('✅ Compte local créé pour $email (offline)');
      return false; // Offline
    }
    
    // Mode online : utiliser Supabase
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );
      
      if (response.user == null) {
        throw AuthException(
          'Erreur lors de la création du compte',
          'signup_failed',
        );
      }
      
      // Le trigger handle_new_user() va créer automatiquement :
      // - users
      // - reader_settings
      // - user_progress
      
      // Sauvegarder localement
      await _userRepo.getCurrentUser();
      
      return true; // Online - email confirmation envoyé
      
    } on AuthException {
      rethrow;
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('already registered') || 
          errorMsg.contains('user already exists')) {
        throw AuthException(
          'Un compte existe déjà avec cet email',
          'email_already_exists',
          suggestion: 'Essayez de vous connecter ou utilisez "Mot de passe oublié".',
        );
      } else if (errorMsg.contains('password') && errorMsg.contains('weak')) {
        throw AuthException(
          'Mot de passe trop faible',
          'weak_password',
          suggestion: 'Utilisez au moins 6 caractères avec lettres et chiffres.',
        );
      } else if (errorMsg.contains('network')) {
        throw AuthException(
          'Erreur réseau',
          'network_error',
          suggestion: 'Vérifiez votre connexion ou créez un compte local (mode offline).',
        );
      } else {
        throw AuthException(
          'Erreur lors de l\'inscription: $e',
          'unknown_error',
        );
      }
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
}