import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/plan_models.dart';
import 'plan_service.dart';
import 'sync_queue_hive.dart';
import 'telemetry_console.dart';
import 'user_prefs.dart';
import '../repositories/user_repository.dart';
import 'plan_catchup_service.dart';

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

  /// ✅ Read-back atomique : vérifie qu'un plan actif existe localement
  @override
  Future<Plan?> getActiveLocalPlan() async {
    try {
      final cached = cachePlans.get('active_plan') as Map?;
      if (cached != null) {
        final plan = Plan.fromJson(Map<String, dynamic>.from(cached));
        telemetry.event('active_local_plan_verified', {'plan_id': plan.id});
        return plan;
      }
      telemetry.event('no_active_local_plan');
      return null;
    } catch (e) {
      telemetry.event('active_local_plan_check_failed', {'error': e.toString()});
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
    
    // 🔒 IMPORTANT: Mettre à jour le profil utilisateur pour le router guard
    final userRepo = UserRepository();
    await userRepo.setCurrentPlan(planId);
    
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

  /// Archive un plan (offline-first)
  @override
  Future<void> archivePlan(String planId) async {
    // 1) Récupérer le plan depuis le cache local
    final current = cachePlans.get('active_plan');
    if (current == null) {
      throw Exception('Aucun plan actif à archiver');
    }

    final planData = Map<String, dynamic>.from(current);
    
    // 2) Marquer comme archivé localement (optimistic update)
    planData['is_active'] = false;
    planData['status'] = 'archived';
    planData['archived_at'] = DateTime.now().toIso8601String();
    
    await cachePlans.put('archived_plan_$planId', planData);
    await cachePlans.delete('active_plan'); // Retirer le plan actif
    
    telemetry.event('plan_archived_locally', {'plan_id': planId});

    // 3) Enqueue patch serveur (sync ultérieure si en ligne)
    await syncQueue.enqueuePlanPatch(planId, {
      'is_active': false,
      'status': 'archived',
      'archived_at': planData['archived_at'],
    });

    telemetry.event('plan_archive_queued_for_sync', {'plan_id': planId});
  }

  /// 🐛 DEBUG: Supprime complètement le plan actuel pour forcer la création d'un nouveau
  Future<void> debugDeleteCurrentPlan() async {
    print('🐛 DEBUG: Suppression du plan actuel pour test');
    
    // Supprimer le plan actif
    await cachePlans.delete('active_plan');
    
    // Supprimer tous les jours de plan du cache
    final allKeys = cachePlanDays.keys.toList();
    for (final key in allKeys) {
      if (key.startsWith('days:')) {
        await cachePlanDays.delete(key);
        print('🐛 DEBUG: Supprimé $key');
      }
    }
    
    print('🐛 DEBUG: Plan actuel supprimé - prêt pour nouveau plan');
  }


  // —— days ————————————————————————————————————————————————————————
  @override
  Future<List<PlanDay>> getPlanDays(String planId, {int? fromDay, int? toDay}) async {
    final key = 'days:$planId:${fromDay ?? 1}:${toDay ?? 0}';
    final altKey = 'days:$planId'; // ancien format

    List _readFromCache(String cacheKey) {
      final cached = cachePlanDays.get(cacheKey);
      return (cached is List) ? cached : const [];
    }

    List<PlanDay> _parse(List data) {
      final days = <PlanDay>[];
      for (final e in data) {
        try {
          final pd = PlanDay.fromJson(Map<String, dynamic>.from(e as Map));
          days.add(pd);
        } catch (err) {
          print('⚠️ PlanDay.fromJson error: $err');
        }
      }
      return days;
    }

    // 1) cache direct
    final cached = _readFromCache(key);
    if (cached.isNotEmpty) return _parse(cached);

    // 2) alt cache
    final alt = _readFromCache(altKey);
    if (alt.isNotEmpty) {
      final parsed = _parse(alt);

      // 🔧 auto-migration: re-écrire au bon key (et formats normalisés via toJson)
      await cachePlanDays.put(key, parsed.map((d) => d.toJson()).toList());
      return parsed;
    }

    // 3) remote
    final r = await _authedGet('/plans/$planId/days${_range(fromDay, toDay)}');
    if (r.statusCode ~/ 100 != 2) {
      if (r.statusCode == 404) {
        print('⚠️ getPlanDays 404: fallback (vide)');
        return [];
      }
      throw 'getPlanDays ${r.statusCode}: ${r.body}';
    }

    final List data = jsonDecode(r.body);

    // 🧹 normaliser & stocker
    final parsed = _parse(data);
    await cachePlanDays.put(key, parsed.map((d) => d.toJson()).toList());

    return parsed;
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
  /// Crée un plan localement sans connexion Internet
  @override
  Future<Plan> createLocalPlan({
    required String name,
    required int totalDays,
    required DateTime startDate,
    required String books,
    String? specificBooks,
    required int minutesPerDay,
    List<Map<String, dynamic>>? customPassages,
    List<int>? daysOfWeek, // ✅ NOUVEAU - Jours de lecture (1=Lun, 7=Dim)
  }) async {
    // 🔒 ARCHIVER L'ANCIEN PLAN S'IL EXISTE
    final current = cachePlans.get('active_plan');
    if (current != null) {
      print('🔄 Archivage de l\'ancien plan avant creation du nouveau');
      final oldPlan = Map<String, dynamic>.from(current)..['is_active'] = false;
      final oldPlanId = oldPlan['id'] as String;
      
      // Archiver le plan
      await cachePlans.put('active_plan_prev', oldPlan);
      
      // Archiver les jours de l'ancien plan
      final oldPlanDaysKey = 'plan_days_$oldPlanId';
      final oldPlanDays = cachePlanDays.get(oldPlanDaysKey);
      if (oldPlanDays != null) {
        await cachePlanDays.put('plan_days_prev_$oldPlanId', oldPlanDays);
        print('🔄 Jours de l\'ancien plan archives: $oldPlanDaysKey');
      }
      
      telemetry.event('old_plan_archived', {'old_plan_id': oldPlanId});
    }
    
    // Générer un ID unique pour le plan
    final planId = const Uuid().v4();
    
    // Créer le plan local
    final plan = Plan(
      id: planId,
      userId: 'local_user', // ID utilisateur local
      name: name,
      totalDays: totalDays,
      startDate: startDate,
      isActive: true,
      books: books,
      specificBooks: specificBooks,
      minutesPerDay: minutesPerDay,
      daysOfWeek: daysOfWeek, // ✅ NOUVEAU
    );
    
    // Sauvegarder localement
    await cachePlans.put('active_plan', plan.toJson());
    
    // Créer des jours de plan avec passages personnalisés ou génériques
    await _createLocalPlanDays(planId, totalDays, startDate, books, customPassages, daysOfWeek);
    
    // 🔒 Mettre à jour le UserRepository pour le router guard
    final userRepo = UserRepository();
    await userRepo.setCurrentPlan(planId);
    print('✅ UserRepository mis à jour avec nouveau planId: $planId');
    
    telemetry.event('plan_created_locally', {
      'plan_id': planId,
      'name': name,
      'total_days': totalDays,
      'books': books,
      'days_of_week': daysOfWeek?.join(','), // ✅ NOUVEAU
    });
    
    return plan;
  }

  /// Crée les jours de plan localement
  Future<void> _createLocalPlanDays(
    String planId,
    int totalDays,
    DateTime startDate,
    String books,
    List<Map<String, dynamic>>? customPassages,
    List<int>? daysOfWeek, // ✅ NOUVEAU
  ) async {
    final List<PlanDay> days = [];
    
    // ═══════════════════════════════════════════════════════════
    // PRIORITÉ : Utiliser customPassages si disponibles ⭐
    // ═══════════════════════════════════════════════════════════
    if (customPassages != null && customPassages.isNotEmpty) {
      print('✅ Utilisation des passages personnalisés (${customPassages.length})');
      
      for (int i = 0; i < customPassages.length; i++) {
        final passage = customPassages[i];
        final dayDate = DateTime.parse(passage['date'] as String);
        
        final day = PlanDay(
          id: '${planId}_day_${i + 1}',
          planId: planId,
          dayIndex: i + 1,
          date: dayDate,
          completed: false,
          readings: [
            ReadingRef(
              book: passage['book'] as String,
              range: passage['reference'] as String,
              url: null,
            ),
          ],
        );
        days.add(day);
      }
    } else {
      // ═══════════════════════════════════════════════════════════
      // FALLBACK : Génération générique respectant daysOfWeek ⭐
      // ═══════════════════════════════════════════════════════════
      print('⚠️ Pas de passages personnalisés, génération générique avec respect calendrier');
      
      var currentDate = startDate;
      int dayIndex = 1;
      
      while (days.length < totalDays) {
        // Respecter daysOfWeek si disponible
        if (daysOfWeek != null && !daysOfWeek.contains(currentDate.weekday)) {
          currentDate = currentDate.add(const Duration(days: 1));
          continue; // ✅ Sauter les jours non sélectionnés
        }
        
        final day = PlanDay(
          id: '${planId}_day_$dayIndex',
          planId: planId,
          dayIndex: dayIndex,
          date: currentDate,
          completed: false,
          readings: await _generateLocalReadings(books, dayIndex),
        );
        days.add(day);
        
        dayIndex++;
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
    
    // Sauvegarder les jours avec la même clé que getPlanDays
    await cachePlanDays.put('days:$planId:1:0', days.map((d) => d.toJson()).toList());
    print('✅ ${days.length} jours de plan sauvegardés localement');
  }

  /// Génère des lectures locales basées sur les livres sélectionnés et la durée disponible
  Future<List<ReadingRef>> _generateLocalReadings(String books, int dayIndex) async {
    // Récupérer la durée choisie par l'utilisateur depuis le profil
    final durationMin = await _getUserDurationMin();
    
    // Calculer le nombre de versets/chapitres selon la durée
    final readingLength = _calculateReadingLength(durationMin);
    
    // Lectures dynamiques selon les livres et la durée
    final readings = <ReadingRef>[];
    
    if (books.contains('Psalms')) {
      readings.add(ReadingRef(
        book: 'Psaumes',
        range: '${(dayIndex % 150) + 1}:1-${readingLength['psalms']}',
        url: null,
      ));
    }
    
    if (books.contains('Proverbs')) {
      readings.add(ReadingRef(
        book: 'Proverbes',
        range: '${(dayIndex % 31) + 1}:1-${readingLength['proverbs']}',
        url: null,
      ));
    }
    
    if (books.contains('Gospels')) {
      final gospels = ['Matthieu', 'Marc', 'Luc', 'Jean'];
      final gospel = gospels[dayIndex % gospels.length];
      readings.add(ReadingRef(
        book: gospel,
        range: '${(dayIndex % 28) + 1}:1-${readingLength['gospels']}',
        url: null,
      ));
    }
    
    if (books.contains('NT') && !books.contains('Gospels')) {
      readings.add(ReadingRef(
        book: 'Épîtres',
        range: '$dayIndex:1-${readingLength['epistles']}',
        url: null,
      ));
    }
    
    if (books.contains('OT')) {
      readings.add(ReadingRef(
        book: 'Ancien Testament',
        range: '$dayIndex:1-${readingLength['ot']}',
        url: null,
      ));
    }
    
    // Si aucune lecture générée, créer une lecture par défaut
    if (readings.isEmpty) {
      readings.add(ReadingRef(
        book: 'Genèse',
        range: '$dayIndex:1-${readingLength['default']}',
        url: null,
      ));
    }
    
    return readings;
  }

  /// Récupère la durée quotidienne choisie par l'utilisateur
  Future<int> _getUserDurationMin() async {
    try {
      // Essayer de récupérer depuis UserPrefs
      final profile = await UserPrefs.loadProfile();
      return profile['durationMin'] as int? ?? 15; // 15 min par défaut
    } catch (e) {
      return 15; // Fallback à 15 minutes
    }
  }

  /// Calcule la longueur de lecture selon la durée disponible
  Map<String, int> _calculateReadingLength(int durationMin) {
    // Estimation : 1 minute = 2-3 versets moyens
    const versesPerMinute = 2.5;
    final totalVerses = (durationMin * versesPerMinute).round();
    
    return {
      'psalms': _clampVerses(totalVerses, 5, 30), // Psaumes : 5-30 versets
      'proverbs': _clampVerses(totalVerses, 8, 40), // Proverbes : 8-40 versets
      'gospels': _clampVerses(totalVerses, 6, 35), // Évangiles : 6-35 versets
      'epistles': _clampVerses(totalVerses, 10, 50), // Épîtres : 10-50 versets
      'ot': _clampVerses(totalVerses, 8, 45), // AT : 8-45 versets
      'default': _clampVerses(totalVerses, 6, 30), // Défaut : 6-30 versets
    };
  }

  /// Limite le nombre de versets dans une plage raisonnable
  int _clampVerses(int verses, int min, int max) {
    return verses.clamp(min, max);
  }

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

  /// 🔄 Recommence le plan depuis le jour 1
  Future<void> restartPlanFromDay1(String planId) async {
    await PlanCatchupService.restartPlanFromDay1(planId);
    
    // Télémetrie
    telemetry.event('plan_restarted_from_day1', {'plan_id': planId});
    
    // Sync en arrière-plan
    try {
      await syncQueue.enqueuePlanPatch(planId, {
        'restarted_at': DateTime.now().toIso8601String(),
        'new_start_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Sync restart plan échouée: $e');
    }
  }

  /// 📅 Replanifie le plan depuis aujourd'hui
  Future<void> rescheduleFromToday(String planId) async {
    await PlanCatchupService.rescheduleFromToday(planId);
    
    // Télémetrie
    telemetry.event('plan_rescheduled_from_today', {'plan_id': planId});
    
    // Sync en arrière-plan
    try {
      await syncQueue.enqueuePlanPatch(planId, {
        'rescheduled_at': DateTime.now().toIso8601String(),
        'new_start_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Sync reschedule plan échouée: $e');
    }
  }
}
