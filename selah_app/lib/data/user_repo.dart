import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/hive_boxes.dart';

abstract class UserRepo {
  Future<Map<String, dynamic>> getProfileLocal();
  Future<void> upsertLocalProfile(Map<String, dynamic> profile);
  Future<void> syncProfileToServer(Map<String, dynamic> localPayload, {required String idempotencyKey});
}

class UserRepoSupabase implements UserRepo {
  final SupabaseClient supabase;
  final String userId; // injecte depuis auth
  UserRepoSupabase(this.supabase, this.userId);

  @override
  Future<Map<String, dynamic>> getProfileLocal() async {
    final box = Hive.box(Boxes.profile);
    final m = box.get('me') as Map?;
    return m == null ? <String, dynamic>{} : Map<String, dynamic>.from(m);
  }

  @override
  Future<void> upsertLocalProfile(Map<String, dynamic> profile) async {
    final box = Hive.box(Boxes.profile);
    await box.put('me', profile);
  }

  /// Idempotency soft:
  /// 1) Récupère le record serveur
  /// 2) Compare updated_at vs local 'updated_at_local'
  /// 3) Si local plus récent -> upsert (avec Prefer: resolution=merge-duplicates)
  /// 4) Sinon no-op
  @override
  Future<void> syncProfileToServer(Map<String, dynamic> payload, {required String idempotencyKey}) async {
    final updatedAtLocal = payload['updated_at_local'] as String?;
    if (updatedAtLocal == null) return;

    final server = await supabase.from('profiles').select().eq('id', userId).maybeSingle();

    final serverUpdatedAt = server?['updated_at'] as String?;
    final isLocalNewer = serverUpdatedAt == null || DateTime.parse(updatedAtLocal).isAfter(DateTime.parse(serverUpdatedAt));

    if (!isLocalNewer) return;

    final up = {
      ...server ?? {},
      ...payload,
      'id': userId,
      // On recopie updated_at_local côté serveur pour diag (optionnel)
      'updated_at_local': updatedAtLocal,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'idempotency_key': idempotencyKey, // colonne optionnelle côté DB
    };

    // PostgREST ne gère pas officiellement Idempotency-Key, on passe l'info en colonne
    await supabase
        .from('profiles')
        .upsert(up, onConflict: 'id')
        .select()
        .then((_) async {
          // réaligne local avec copie canonique serveur
          final fresh = await supabase.from('profiles').select().eq('id', userId).single();
          final box = Hive.box(Boxes.profile);
          await box.put('me', fresh);
        });
  }
}
