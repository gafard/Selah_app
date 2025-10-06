import 'package:supabase_flutter/supabase_flutter.dart';
import 'meditation_models.dart';

/// Repository pour la gestion des données de méditation avec Supabase
class MeditationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère une méditation existante
  Future<MeditationResult?> fetchExisting(String planId, int day) async {
    try {
      final response = await _supabase
          .from('meditations')
          .select()
          .eq('plan_id', planId)
          .eq('day_number', day)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .maybeSingle();

      if (response == null) return null;

      final content = response['content'] as Map<String, dynamic>;
      return MeditationResult.fromJson(content);
    } catch (e) {
      // print('Erreur lors de la récupération de la méditation: $e');
      return null;
    }
  }

  /// Sauvegarde ou met à jour une méditation
  Future<void> upsertResult(MeditationResult result) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      await _supabase.from('meditations').upsert({
        'user_id': userId,
        'plan_id': result.planId,
        'day_number': result.dayNumber,
        'passage_ref': result.passageRef,
        'option': result.option,
        'content': result.toJson(),
        'is_completed': result.isCompleted,
        'created_at': result.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // print('Erreur lors de la sauvegarde de la méditation: $e');
      rethrow;
    }
  }

  /// Sauvegarde un brouillon (sans marquer comme terminé)
  Future<void> saveDraft(MeditationResult result) async {
    final draftResult = result.copyWith(isCompleted: false);
    await upsertResult(draftResult);
  }

  /// Marque une méditation comme terminée
  Future<void> markAsCompleted(MeditationResult result) async {
    final completedResult = result.copyWith(isCompleted: true);
    await upsertResult(completedResult);
  }

  /// Récupère toutes les méditations d'un plan
  Future<List<MeditationResult>> getPlanMeditations(String planId) async {
    try {
      final response = await _supabase
          .from('meditations')
          .select()
          .eq('plan_id', planId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .order('day_number');

      return response
          .map((item) {
            final content = item['content'] as Map<String, dynamic>;
            return MeditationResult.fromJson(content);
          })
          .toList();
    } catch (e) {
      // print('Erreur lors de la récupération des méditations: $e');
      return [];
    }
  }

  /// Supprime une méditation
  Future<void> deleteMeditation(String planId, int day) async {
    try {
      await _supabase
          .from('meditations')
          .delete()
          .eq('plan_id', planId)
          .eq('day_number', day)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
    } catch (e) {
      // print('Erreur lors de la suppression de la méditation: $e');
      rethrow;
    }
  }
}
