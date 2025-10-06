import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/plan_models.dart';
import 'plan_service.dart';
import 'sync_queue_hive.dart';
import 'telemetry_console.dart';

class PlanServiceHttp implements PlanService {
  final String baseUrl; // ex: https://api.selah.app
  final Future<String?> Function() tokenProvider; // Supabase auth.currentSession?.accessToken
  final Box cachePlans;          // Hive box 'plans'
  final Box cachePlanDays;       // Hive box 'plan_days' (map par planId)
  final SyncQueueHive syncQueue; // pour mark progress offline → sync
  final TelemetryConsole telemetry;

  PlanServiceHttp({
    required this.baseUrl,
    required this.tokenProvider,
    required this.cachePlans,
    required this.cachePlanDays,
    required this.syncQueue,
    required this.telemetry,
  });

  /// Vérifie la connectivité réseau
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Map<String, String> _headers({String? idem}) => {
        'Content-Type': 'application/json',
        if (idem != null) 'Idempotency-Key': idem,
      };

  Future<http.Response> _authedPost(String path, Map body, {String? idem}) async {
    final token = await tokenProvider();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        ..._headers(idem: idem),
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _authedGet(String path) async {
    final token = await tokenProvider();
    return http.get(Uri.parse('$baseUrl$path'), headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<http.Response> _authedPatch(String path, Map body, {String? idem}) async {
    final token = await tokenProvider();
    return http.patch(
      Uri.parse('$baseUrl$path'),
      headers: {
        ..._headers(idem: idem),
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // —— active plan ————————————————————————————————————————————————
  @override
  Future<Plan?> getActivePlan() async {
    // PRIORITÉ AU STOCKAGE LOCAL (offline-first)
    final cached = cachePlans.get('active_plan') as Map?;
    if (cached != null) {
      telemetry.event('plan_loaded_from_cache', {'source': 'local'});
      return Plan.fromJson(Map<String, dynamic>.from(cached));
    }
    
    // Fallback sur le serveur si en ligne
    try {
      final r = await _authedGet('/plans/active');
      if (r.statusCode == 204) return null;
      if (r.statusCode ~/ 100 != 2) throw 'getActivePlan ${r.statusCode}: ${r.body}';
      final plan = Plan.fromJson(jsonDecode(r.body));
      await cachePlans.put('active_plan', plan.toJson());
      telemetry.event('plan_loaded_from_server', {'source': 'remote'});
      return plan;
    } catch (e) {
      telemetry.event('plan_load_failed', {'error': e.toString(), 'fallback': 'local'});
      // Retourner null si pas de plan local et serveur inaccessible
      return null;
    }
  }

  @override
  Future<void> setActivePlan(String planId) async {
    // OPTIMISTIC LOCAL UPDATE (toujours fonctionnel)
    final current = cachePlans.get('active_plan');
    if (current != null) {
      final p = Map<String, dynamic>.from(current)..['is_active'] = false;
      await cachePlans.put('active_plan_prev', p);
    }
    // Mise à jour locale immédiate
    await cachePlans.put('active_plan', {'id': planId, 'is_active': true});
    telemetry.event('plan_activated_locally', {'plan_id': planId});

    // Synchronisation serveur (si en ligne)
    try {
      final idem = const Uuid().v4();
      await _authedPost('/plans/$planId/set-active', {}, idem: idem);
      telemetry.event('plan_activated_on_server', {'plan_id': planId});
    } catch (e) {
      // Marquer pour synchronisation ultérieure
      await syncQueue.enqueueUserPatch({
        'patch_kind': 'set_active_plan',
        'plan_id': planId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      telemetry.event('plan_activation_queued_for_sync', {'plan_id': planId, 'error': e.toString()});
    }
  }

  // —— days ————————————————————————————————————————————————————————
  @override
  Future<List<PlanDay>> getPlanDays(String planId, {int? fromDay, int? toDay}) async {
    final key = 'days:$planId:${fromDay ?? 1}:${toDay ?? 0}';
    final cached = cachePlanDays.get(key);
    if (cached != null) {
      final list = (cached as List).map((e) => PlanDay.fromJson(Map<String, dynamic>.from(e))).toList();
      // Async refresh en arrière-plan (sans bloquer)
      _authedGet('/plans/$planId/days${_range(fromDay, toDay)}').then((r) async {
        if (r.statusCode ~/ 100 == 2) {
          final List data = jsonDecode(r.body);
          await cachePlanDays.put(key, data);
        }
      });
      return list;
    }
    final r = await _authedGet('/plans/$planId/days${_range(fromDay, toDay)}');
    if (r.statusCode ~/ 100 != 2) throw 'getPlanDays ${r.statusCode}: ${r.body}';
    final List data = jsonDecode(r.body);
    await cachePlanDays.put(key, data);
    return data.map((e) => PlanDay.fromJson(e)).toList();
  }

  String _range(int? from, int? to) {
    final q = <String>[];
    if (from != null) q.add('from=$from');
    if (to != null) q.add('to=$to');
    return q.isEmpty ? '' : '?${q.join('&')}';
  }

  // —— create/import ————————————————————————————————————————————————
  @override
  Future<Plan> createFromPreset({
    required String presetSlug,
    required DateTime startDate,
    required Map<String, dynamic> profile,
  }) async {
    // Vérifier la connectivité pour la génération
    final isOnline = await _checkConnectivity();
    
    if (!isOnline) {
      throw Exception('Connexion Internet requise pour générer un nouveau plan');
    }
    
    try {
      // Génération côté serveur (nécessite Internet)
      final idem = const Uuid().v4();
      final r = await _authedPost(
        '/plans/from-preset',
        {
          'preset_slug': presetSlug,
          'start_date': startDate.toIso8601String(),
          'profile': profile,
        },
        idem: idem,
      );
      if (r.statusCode ~/ 100 != 2) throw 'createFromPreset ${r.statusCode}: ${r.body}';
      final plan = Plan.fromJson(jsonDecode(r.body));
      
      // Sauvegarde locale immédiate
      await cachePlans.put('active_plan', plan.toJson());
      telemetry.event('plan_created_from_preset', {'slug': presetSlug, 'source': 'server'});
      return plan;
    } catch (e) {
      telemetry.event('plan_creation_failed', {'slug': presetSlug, 'error': e.toString()});
      rethrow;
    }
  }

  @override
  Future<Plan> importFromGenerator({
    required String planName,
    required Uri icsUrl,
  }) async {
    // Vérifier la connectivité pour l'import
    final isOnline = await _checkConnectivity();
    
    if (!isOnline) {
      throw Exception('Connexion Internet requise pour importer un plan');
    }
    
    try {
      // Import côté serveur (nécessite Internet)
      final idem = const Uuid().v4();
      final r = await _authedPost(
        '/plans/import',
        {'name': planName, 'ics_url': icsUrl.toString()},
        idem: idem,
      );
      if (r.statusCode ~/ 100 != 2) throw 'importFromGenerator ${r.statusCode}: ${r.body}';
      final plan = Plan.fromJson(jsonDecode(r.body));
      
      // Sauvegarde locale immédiate
      await cachePlans.put('active_plan', plan.toJson());
      telemetry.event('plan_imported', {'name': planName, 'source': 'server'});
      return plan;
    } catch (e) {
      telemetry.event('plan_import_failed', {'name': planName, 'error': e.toString()});
      rethrow;
    }
  }

  // —— progress ————————————————————————————————————————————————
  @override
  Future<void> setDayCompleted(String planId, int dayIndex, bool completed) async {
    // Optimistic: patch cache
    final keyPrefix = 'days:$planId';
    final keys = cachePlanDays.keys.where((k) => k.toString().startsWith(keyPrefix));
    for (final k in keys) {
      final List data = (cachePlanDays.get(k) as List?) ?? [];
      final i = data.indexWhere((e) => e['day_index'] == dayIndex);
      if (i != -1) {
        data[i]['completed'] = completed;
        await cachePlanDays.put(k, data);
      }
    }
    // Enqueue pour sync serveur via Workmanager
    await syncQueue.enqueueUserPatch({
      'patch_kind': 'plan_progress',
      'plan_id': planId,
      'day_index': dayIndex,
      'completed': completed,
    });
  }

  // —— progress stream (à partir du cache) ————————————————
  @override
  Stream<PlanProgress> watchProgress(String planId) async* {
    // Simplifié : recompute sur chaque write dans n'importe quel cache days
    yield* cachePlanDays.watch().where((e) => e.key.toString().startsWith('days:$planId')).asyncMap((_) async {
      final keys = cachePlanDays.keys.where((k) => k.toString().startsWith('days:$planId'));
      int done = 0, total = 0;
      for (final k in keys) {
        final List data = (cachePlanDays.get(k) as List?) ?? [];
        total += data.length;
        done += data.where((e) => e['completed'] == true).length;
      }
      return PlanProgress(planId: planId, done: done, total: total);
    });
  }
}
