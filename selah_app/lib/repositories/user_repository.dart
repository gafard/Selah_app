import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';

/// Repository pour la gestion des utilisateurs (OFFLINE-FIRST)
/// 
/// Priorité : 
/// 1. Local d'abord (Hive)
/// 2. Supabase en arrière-plan (si en ligne)
class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // ═══════════════════════════════════════════════════════════════════
  // LECTURE UTILISATEUR (Local d'abord)
  // ═══════════════════════════════════════════════════════════════════

  /// Récupère l'utilisateur actuel (LOCAL d'abord)
  Future<UserProfile?> getCurrentUser() async {
    // 1. Vérifier d'abord le stockage local (OFFLINE-FIRST)
    final localUser = LocalStorageService.getLocalUser();
    if (localUser != null) {
      return UserProfile.fromJson(localUser);
    }

    // 2. Pas d'utilisateur local trouvé
    print('⚠️ Aucun utilisateur local trouvé');
    return null;
  }

  /// Vérifie si l'utilisateur est authentifié (LOCAL d'abord)
  bool isAuthenticated() {
    // Vérifier d'abord localement
    if (LocalStorageService.hasLocalUser()) {
      return true;
    }

    // Fallback sur Supabase si disponible
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'ID de l'utilisateur actuel
  String? getCurrentUserId() {
    final localUser = LocalStorageService.getLocalUser();
    if (localUser != null && localUser['id'] != null) {
      return localUser['id'] as String;
    }

    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MISE À JOUR PROFIL (Optimistic updates)
  // ═══════════════════════════════════════════════════════════════════

  /// Met à jour le profil utilisateur (LOCAL immédiat, SYNC en arrière-plan)
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final currentUser = LocalStorageService.getLocalUser() ?? <String, dynamic>{};
    
    // 1. Mise à jour locale IMMÉDIATE (optimistic update)
    final updatedProfile = {...currentUser, ...updates, 'updated_at_local': DateTime.now().toIso8601String()};
    await LocalStorageService.saveLocalUser(updatedProfile);

    // 2. Marquer pour synchronisation
    await LocalStorageService.markForSync('user_profile', getCurrentUserId() ?? 'local');

    // 3. Tenter sync immédiate si en ligne (non bloquant)
    _syncProfileInBackground(updatedProfile);
  }

  /// Marque le profil comme complet
  Future<void> markProfileComplete() async {
    await updateProfile({'is_complete': true, 'completed_at': DateTime.now().toIso8601String()});
  }

  /// Marque l'onboarding comme terminé
  Future<void> markOnboardingComplete() async {
    await updateProfile({'has_onboarded': true, 'onboarded_at': DateTime.now().toIso8601String()});
  }

  /// Définit le plan actuel
  Future<void> setCurrentPlan(String planId) async {
    await updateProfile({'current_plan_id': planId});
    await LocalStorageService.setActiveLocalPlan(planId);
  }

  // ═══════════════════════════════════════════════════════════════════
  // CRÉATION UTILISATEUR (Offline-first)
  // ═══════════════════════════════════════════════════════════════════

  /// Crée un utilisateur local (fonctionne offline)
  Future<UserProfile> createLocalUser({
    String? displayName,
    String? email,
  }) async {
    final userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final profile = {
      'id': userId,
      'display_name': displayName ?? 'Utilisateur',
      'email': email,
      'is_complete': false,
      'has_onboarded': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at_local': DateTime.now().toIso8601String(),
      'is_local_only': true,
    };

    await LocalStorageService.saveLocalUser(profile);
    return UserProfile.fromJson(profile);
  }

  /// Crée un utilisateur Supabase (nécessite connexion)
  Future<UserProfile?> createSupabaseUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final isOnline = await LocalStorageService.isOnline;
    if (!isOnline) {
      throw Exception('Connexion Internet requise pour créer un compte Supabase');
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final profile = {
          'id': response.user!.id,
          'email': email,
          'display_name': displayName ?? email.split('@').first,
          'is_complete': false,
          'has_onboarded': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at_local': DateTime.now().toIso8601String(),
          'is_local_only': false,
        };

        await LocalStorageService.saveLocalUser(profile);
        return UserProfile.fromJson(profile);
      }
    } catch (e) {
      print('❌ Error creating Supabase user: $e');
      rethrow;
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // SYNCHRONISATION (Arrière-plan, non bloquant)
  // ═══════════════════════════════════════════════════════════════════

  /// Synchronise le profil avec Supabase (arrière-plan)
  void _syncProfileInBackground(Map<String, dynamic> profile) async {
    try {
      final isOnline = await LocalStorageService.isOnline;
      if (!isOnline) return;

      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser == null) return;

      // Sync vers Supabase
      await Supabase.instance.client
          .from('users')
          .upsert({
            'id': supabaseUser.id,
            ...profile,
            'updated_at': DateTime.now().toIso8601String(),
          });

      print('✅ Profile synced to Supabase');
    } catch (e) {
      print('⚠️ Background sync failed (will retry later): $e');
      // Reste dans la queue de sync pour retry
    }
  }

  /// Récupère et sauvegarde le profil depuis Supabase
  Future<UserProfile?> _fetchAndSaveProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      await LocalStorageService.saveLocalUser(response);
      return UserProfile.fromJson(response);
    } catch (e) {
      print('⚠️ Failed to fetch profile from Supabase: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // DÉCONNEXION
  // ═══════════════════════════════════════════════════════════════════

  /// Déconnecte l'utilisateur (local + Supabase)
  Future<void> signOut() async {
    // 1. Nettoyer stockage local
    await LocalStorageService.clearLocalUser();

    // 2. Déconnexion Supabase si disponible
    try {
      final isOnline = await LocalStorageService.isOnline;
      if (isOnline) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      print('⚠️ Supabase sign out failed (local cleared anyway): $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// MODÈLE UTILISATEUR
// ═══════════════════════════════════════════════════════════════════

class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final bool isComplete;
  final bool hasOnboarded;
  final String? currentPlanId;
  final DateTime? createdAt;
  final DateTime? updatedAtLocal;
  final bool isLocalOnly;

  UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.isComplete = false,
    this.hasOnboarded = false,
    this.currentPlanId,
    this.createdAt,
    this.updatedAtLocal,
    this.isLocalOnly = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      isComplete: json['is_complete'] as bool? ?? false,
      hasOnboarded: json['has_onboarded'] as bool? ?? false,
      currentPlanId: json['current_plan_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAtLocal: json['updated_at_local'] != null ? DateTime.parse(json['updated_at_local'] as String) : null,
      isLocalOnly: json['is_local_only'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'is_complete': isComplete,
      'has_onboarded': hasOnboarded,
      'current_plan_id': currentPlanId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at_local': updatedAtLocal?.toIso8601String(),
      'is_local_only': isLocalOnly,
    };
  }
}
