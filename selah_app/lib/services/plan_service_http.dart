import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/plan_models.dart';
import '../models/plan_preset.dart';
import '../models/thompson_plan_models.dart';
import 'plan_service.dart';
import 'sync_queue_hive.dart';
import 'telemetry_console.dart';
import 'user_prefs.dart';
import 'user_prefs_sync.dart';
import '../repositories/user_repository.dart';
import 'plan_catchup_service.dart';
import 'thompson_plan_generator.dart';
import 'semantic_passage_boundary_service_v2.dart';
import 'intelligent_local_preset_generator.dart';
import 'bible_verses_database.dart';

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
    
    print('🔍 getPlanDays appelé pour planId: $planId, fromDay: $fromDay, toDay: $toDay');
    print('🔍 Clé principale: $key');
    print('🔍 Clé alternative: $altKey');

    List readFromCache(String cacheKey) {
      final cached = cachePlanDays.get(cacheKey);
      final result = (cached is List) ? cached : const [];
      print('🔍 Cache $cacheKey: ${result.length} éléments');
      return result;
    }

    List<PlanDay> parse(List data) {
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
    final cached = readFromCache(key);
    if (cached.isNotEmpty) {
      print('✅ Jours trouvés avec la clé principale: $key');
      return parse(cached);
    }

    // 2) alt cache
    final alt = readFromCache(altKey);
    if (alt.isNotEmpty) {
      print('✅ Jours trouvés avec la clé alternative: $altKey');
      final parsed = parse(alt);

      // 🔧 auto-migration: re-écrire au bon key (et formats normalisés via toJson)
      await cachePlanDays.put(key, parsed.map((d) => d.toJson()).toList());
      return parsed;
    }
    
    // 3) Essayer de récupérer depuis la clé de sauvegarde standard
    final standardKey = 'days:$planId:1:0';
    final standard = readFromCache(standardKey);
    if (standard.isNotEmpty) {
      print('✅ Jours trouvés avec la clé standard: $standardKey');
      final parsed = parse(standard);
      
      // Sauvegarder avec la clé demandée pour les prochaines fois
      await cachePlanDays.put(key, parsed.map((d) => d.toJson()).toList());
      return parsed;
    }

    // 3) 🔧 NOUVEAU: Auto-régénération des jours si plan local existe
    final activePlan = await getActivePlan();
    if (activePlan != null && activePlan.id == planId) {
      // Vérifier si les jours existent déjà pour éviter la boucle infinie
      final existingDays = readFromCache(key);
      if (existingDays.isNotEmpty) {
        print('✅ Jours déjà présents dans le cache (${existingDays.length} jours)');
        return parse(existingDays);
      }
      
      print('🔄 Auto-régénération des jours pour le plan local $planId');
      try {
        await _createLocalPlanDays(
          planId,
          activePlan.totalDays,
          activePlan.startDate,
          activePlan.books,
          null, // customPassages
          activePlan.daysOfWeek,
        );
        
        // Retry après génération avec un petit délai pour la synchronisation
        await Future.delayed(const Duration(milliseconds: 100));
        final regenerated = readFromCache(key);
        if (regenerated.isNotEmpty) {
          print('✅ Jours régénérés avec succès (${regenerated.length} jours)');
          return parse(regenerated);
        } else {
          print('❌ Échec de la régénération - cache vide après génération');
        }
      } catch (e) {
        print('❌ Erreur auto-régénération: $e');
      }
    }

    // 4) remote (fallback)
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
    final parsed = parse(data);
    await cachePlanDays.put(key, parsed.map((d) => d.toJson()).toList());

    return parsed;
  }

  String _range(int? from, int? to) {
    final q = <String>[];
    if (from != null) q.add('from=$from');
    if (to != null) q.add('to=$to');
    return q.isEmpty ? '' : '?${q.join('&')}';
  }

  /// 🔧 Force la régénération des jours du plan actuel
  @override
  Future<void> regenerateCurrentPlanDays() async {
    final activePlan = await getActivePlan();
    if (activePlan == null) {
      print('⚠️ Aucun plan actif trouvé pour régénération');
      return;
    }

    print('🔄 Régénération forcée des jours pour le plan ${activePlan.id}');
    try {
      await _createLocalPlanDays(
        activePlan.id,
        activePlan.totalDays,
        activePlan.startDate,
        activePlan.books,
        null, // customPassages
        activePlan.daysOfWeek,
      );
      print('✅ Jours régénérés avec succès');
    } catch (e) {
      print('❌ Erreur régénération: $e');
    }
  }

  /// 🐛 DEBUG: Vérifie l'état complet du plan actuel
  @override
  Future<void> debugPlanStatus() async {
    print('🐛 === DEBUG PLAN STATUS ===');
    
    // 1) Vérifier le plan actif
    final activePlan = await getActivePlan();
    if (activePlan == null) {
      print('❌ Aucun plan actif trouvé');
      return;
    }
    
    print('✅ Plan actif trouvé:');
    print('   - ID: ${activePlan.id}');
    print('   - Nom: ${activePlan.name}');
    print('   - Durée: ${activePlan.totalDays} jours');
    print('   - Date début: ${activePlan.startDate}');
    print('   - Livres: ${activePlan.books}');
    print('   - Jours de semaine: ${activePlan.daysOfWeek}');
    
    // 2) Vérifier les jours dans le cache
    final key = 'days:${activePlan.id}:1:0';
    final altKey = 'days:${activePlan.id}';
    
    final cached = cachePlanDays.get(key);
    final altCached = cachePlanDays.get(altKey);
    
    print('🔍 Cache des jours:');
    print('   - Clé principale ($key): ${cached != null ? '${(cached as List).length} jours' : 'VIDE'}');
    print('   - Clé alternative ($altKey): ${altCached != null ? '${(altCached as List).length} jours' : 'VIDE'}');
    
    // 3) Tenter de récupérer les jours
    try {
      final planDays = await getPlanDays(activePlan.id);
      print('📖 Jours récupérés via getPlanDays: ${planDays.length} jours');
      
      if (planDays.isNotEmpty) {
        print('   - Premier jour: ${planDays.first.dayIndex} (${planDays.first.date})');
        print('   - Dernier jour: ${planDays.last.dayIndex} (${planDays.last.date})');
        if (planDays.first.readings.isNotEmpty) {
          print('   - Premier passage: ${planDays.first.readings.first.book} ${planDays.first.readings.first.range}');
        }
      }
    } catch (e) {
      print('❌ Erreur récupération jours: $e');
    }
    
    print('🐛 === FIN DEBUG ===');
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

  @override
  Future<void> markDayCompleted(String planId, int dayIndex, bool completed) async {
    // Alias pour compatibilité - délègue à setDayCompleted
    return setDayCompleted(planId, dayIndex, completed);
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
    Map<String, dynamic>? userProfile, // ✅ NOUVEAU - Profil pour génération intelligente
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
    
    // 🧱 NOUVEAU ! Générer les fondations spirituelles intelligentes
    List<String> foundationIds = [];
    if (userProfile != null) {
      try {
        foundationIds = await IntelligentLocalPresetGenerator.generateFoundationsForPlan(
          userProfile,
          totalDays,
        );
        print('🧱 Fondations générées pour le plan: ${foundationIds.join(', ')}');
      } catch (e) {
        print('⚠️ Erreur génération fondations: $e');
        // Continuer sans fondations si erreur
      }
    }
    
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
      foundationIds: foundationIds.isNotEmpty ? foundationIds : null, // ✅ NOUVEAU
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
    // 🔍 DÉTECTION : Plan avec données vides → Régénération intelligente ⭐
    // ═══════════════════════════════════════════════════════════
    if (books.isEmpty || totalDays == 0) {
      print('🔍 Plan détecté avec données vides - Régénération intelligente');
      
      try {
        // Synchroniser d'abord les deux systèmes
        await UserPrefsSync.syncBidirectional();
        
        // Récupérer le profil utilisateur pour la génération intelligente
        final userProfile = await UserPrefs.loadProfile();
        
        // Générer des presets intelligents basés sur le profil
        final presets = await IntelligentLocalPresetGenerator.generateEnrichedPresets(userProfile);
        
        if (presets.isNotEmpty) {
          final selectedPreset = presets.first; // Prendre le premier preset recommandé
          
          print('🎯 Preset sélectionné: ${selectedPreset.name} (${selectedPreset.durationDays} jours)');
          print('📚 Livres: ${selectedPreset.books}');
          
          // Utiliser les données du preset pour régénérer le plan
          final intelligentPassages = await _generateIntelligentPassages(
            books: selectedPreset.books,
            totalDays: selectedPreset.durationDays,
            startDate: startDate,
            daysOfWeek: daysOfWeek,
            userProfile: userProfile,
          );
          
          for (int i = 0; i < intelligentPassages.length; i++) {
            final passage = intelligentPassages[i];
            final dayDate = startDate.add(Duration(days: i));
            
            // Respecter daysOfWeek si disponible
            if (daysOfWeek != null && !daysOfWeek.contains(dayDate.weekday)) {
              continue; // ✅ Sauter les jours non sélectionnés
            }
            
            final day = PlanDay(
              id: '${planId}_day_${i + 1}',
              planId: planId,
              dayIndex: i + 1,
              date: dayDate,
              completed: false,
              readings: [passage],
            );
            days.add(day);
          }
          
          print('✅ ${days.length} jours régénérés intelligemment');
          
          // Mettre à jour le plan avec les nouvelles données
          final activePlan = await getActivePlan();
          if (activePlan != null) {
            final updatedPlan = Plan(
              id: activePlan.id,
              userId: activePlan.userId,
              name: selectedPreset.name,
              totalDays: selectedPreset.durationDays,
              startDate: activePlan.startDate,
              isActive: activePlan.isActive,
              books: selectedPreset.books,
              specificBooks: activePlan.specificBooks,
              minutesPerDay: selectedPreset.minutesPerDay ?? 15,
              daysOfWeek: activePlan.daysOfWeek,
              foundationIds: activePlan.foundationIds,
            );
            
            // Sauvegarder le plan mis à jour
            await cachePlans.put('active_plan', updatedPlan.toJson());
            print('✅ Plan mis à jour avec les données du preset');
          }
          
          // Sauvegarder les jours avec la même clé que getPlanDays
          await cachePlanDays.put('days:$planId:1:0', days.map((d) => d.toJson()).toList());
          print('✅ ${days.length} jours de plan sauvegardés localement avec clé: days:$planId:1:0');
          return;
        }
      } catch (e) {
        print('❌ Erreur régénération intelligente: $e');
        // Continuer avec la logique normale
      }
    }
    
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
      // 🧠 GÉNÉRATEUR INTELLIGENT PRINCIPAL : IntelligentLocalPresetGenerator ⭐
      // ═══════════════════════════════════════════════════════════
      print('🧠 Génération intelligente avec IntelligentLocalPresetGenerator');
      
      try {
        // Synchroniser d'abord les deux systèmes
        await UserPrefsSync.syncBidirectional();
        
        // Récupérer le profil utilisateur pour la génération intelligente
        final userProfile = await UserPrefs.loadProfile();
        
        // Utiliser IntelligentLocalPresetGenerator pour générer les passages
        final intelligentPassages = await _generateIntelligentPassages(
          books: books,
          totalDays: totalDays,
          startDate: startDate,
          daysOfWeek: daysOfWeek,
          userProfile: userProfile,
        );
        
        for (int i = 0; i < intelligentPassages.length; i++) {
          final passage = intelligentPassages[i];
          final dayDate = startDate.add(Duration(days: i));
          
          // Respecter daysOfWeek si disponible
          if (daysOfWeek != null && !daysOfWeek.contains(dayDate.weekday)) {
            continue; // ✅ Sauter les jours non sélectionnés
          }
          
          final day = PlanDay(
            id: '${planId}_day_${i + 1}',
            planId: planId,
            dayIndex: i + 1,
            date: dayDate,
            completed: false,
            readings: [passage],
          );
          days.add(day);
        }
        
        print('✅ ${days.length} jours générés intelligemment');
        
      } catch (e) {
        print('❌ Erreur génération intelligente: $e');
        print('🔄 Fallback vers ThompsonPlanGenerator...');
        
        // ═══════════════════════════════════════════════════════════
        // 🔄 FALLBACK : ThompsonPlanGenerator ⭐
        // ═══════════════════════════════════════════════════════════
        try {
          final thompsonPassages = await _generateThompsonPassages(
            books: books,
            totalDays: totalDays,
            startDate: startDate,
            daysOfWeek: daysOfWeek,
          );
          
          for (int i = 0; i < thompsonPassages.length; i++) {
            final passage = thompsonPassages[i];
            final dayDate = startDate.add(Duration(days: i));
            
            // Respecter daysOfWeek si disponible
            if (daysOfWeek != null && !daysOfWeek.contains(dayDate.weekday)) {
              continue; // ✅ Sauter les jours non sélectionnés
            }
            
            final day = PlanDay(
              id: '${planId}_day_${i + 1}',
              planId: planId,
              dayIndex: i + 1,
              date: dayDate,
              completed: false,
              readings: [passage],
            );
            days.add(day);
          }
          
          print('✅ ${days.length} jours générés avec Thompson');
          
        } catch (e2) {
          print('❌ Erreur Thompson: $e2');
          print('🔄 Fallback vers génération générique...');
          
          // ═══════════════════════════════════════════════════════════
          // 🚨 DERNIER RECOURS : Génération générique ⭐
          // ═══════════════════════════════════════════════════════════
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
          
          print('⚠️ ${days.length} jours générés avec fallback générique');
        }
      }
    }
    
    // Sauvegarder les jours avec plusieurs clés pour assurer la compatibilité
    final primaryKey = 'days:$planId:1:0';
    final altKey = 'days:$planId';
    
    // Sauvegarder avec la clé principale
    await cachePlanDays.put(primaryKey, days.map((d) => d.toJson()).toList());
    print('✅ ${days.length} jours de plan sauvegardés localement avec la clé: $primaryKey');
    
    // Sauvegarder aussi avec la clé alternative pour compatibilité
    await cachePlanDays.put(altKey, days.map((d) => d.toJson()).toList());
    print('✅ ${days.length} jours de plan sauvegardés localement avec la clé alternative: $altKey');
    
    // Vérification immédiate que les jours sont bien sauvegardés
    final verification1 = cachePlanDays.get(primaryKey);
    final verification2 = cachePlanDays.get(altKey);
    if (verification1 != null && verification1 is List && verification2 != null && verification2 is List) {
      print('✅ Vérification: ${verification1.length} jours confirmés dans le cache (clés: $primaryKey, $altKey)');
    } else {
      print('❌ ERREUR: Les jours ne sont pas trouvés dans le cache après sauvegarde');
    }
  }

  /// 🧠 Génère des passages intelligents avec IntelligentLocalPresetGenerator
  Future<List<ReadingRef>> _generateIntelligentPassages({
    required String books,
    required int totalDays,
    required DateTime startDate,
    List<int>? daysOfWeek,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      print('🧠 Génération intelligente pour $books sur $totalDays jours');
      
      // Créer un preset temporaire pour la génération
      // Laisser le service sémantique gérer la complexité des livres
      final bookList = [books]; // Passer la chaîne complète au service sémantique
      final preset = PlanPreset(
        slug: 'intelligent_temp',
        name: 'Plan Intelligent',
        durationDays: totalDays,
        order: 'thematic',
        books: books,
        minutesPerDay: userProfile['durationMin'] ?? 15,
        recommended: [PresetLevel.regular],
        description: 'Plan généré intelligemment',
      );
      
      // Utiliser le générateur intelligent pour créer des passages
      final passages = <ReadingRef>[];
      
      // Générer des passages thématiques intelligents
      for (int day = 0; day < totalDays; day++) {
        final dayDate = startDate.add(Duration(days: day));
        
        // Respecter daysOfWeek si disponible
        if (daysOfWeek != null && !daysOfWeek.contains(dayDate.weekday)) {
          continue;
        }
        
        // 🚀 FALCON X v2 - Utiliser le service sémantique directement
        final passage = await _generateIntelligentPassageWithSemanticService(
          books, // Passer la chaîne complète
          day + 1,
          userProfile,
        );
        
        passages.add(passage);
      }
      
      print('✅ ${passages.length} passages intelligents générés');
      return passages;
      
    } catch (e) {
      print('❌ Erreur génération intelligente: $e');
      rethrow;
    }
  }
  
  /// 🎯 Génère des passages avec ThompsonPlanGenerator (fallback)
  Future<List<ReadingRef>> _generateThompsonPassages({
    required String books,
    required int totalDays,
    required DateTime startDate,
    List<int>? daysOfWeek,
  }) async {
    try {
      print('🎯 Génération Thompson pour $books sur $totalDays jours');
      
      // Créer un profil Thompson basique
      final profile = CompleteProfile(
        goals: ['Discipline quotidienne'],
        startDate: startDate,
        minutesPerDay: 15,
        daysPerWeek: daysOfWeek?.length ?? 7,
        experience: 'growing',
        language: 'fr',
        hasPhysicalBible: false,
        prefersThemes: true,
      );
      
      // Utiliser ThompsonPlanGenerator
      final generator = ThompsonPlanGenerator(imageFor: (key) => '');
      final thompsonPlan = generator.build(profile);
      
      // Extraire les passages des tâches de lecture
      final passages = <ReadingRef>[];
      for (final day in thompsonPlan.days) {
        for (final task in day.tasks) {
          if (task.kind == ThompsonTaskKind.reading && task.passageRef != null) {
            // Parser la référence (ex: "Matthieu 1:1-5")
            final ref = _parseThompsonReference(task.passageRef!);
            if (ref != null) {
              passages.add(ref);
            }
          }
        }
      }
      
      print('✅ ${passages.length} passages Thompson générés');
      return passages;
      
    } catch (e) {
      print('❌ Erreur génération Thompson: $e');
      rethrow;
    }
  }
  
  /// Sélectionne un livre de manière intelligente (pas juste cyclique)
  int _getIntelligentBookIndex(List<String> books, int day, Map<String, dynamic> userProfile) {
    // Logique intelligente basée sur le profil utilisateur
    final level = userProfile['level'] ?? 'Fidèle régulier';
    final goal = userProfile['goal'] ?? 'Discipline quotidienne';
    
    // Pour les débutants, commencer par les évangiles
    if (level == 'Nouveau converti' && books.contains('Matthieu')) {
      return books.indexOf('Matthieu');
    }
    
    // Pour la discipline, alterner entre AT et NT
    if (goal == 'Discipline quotidienne') {
      final atBooks = books.where((b) => _isOldTestament(b)).toList();
      final ntBooks = books.where((b) => _isNewTestament(b)).toList();
      
      if (day % 2 == 0 && atBooks.isNotEmpty) {
        return books.indexOf(atBooks[day % atBooks.length]);
      } else if (ntBooks.isNotEmpty) {
        return books.indexOf(ntBooks[day % ntBooks.length]);
      }
    }
    
    // Fallback cyclique
    return day % books.length;
  }
  
  /// 🚀 FALCON X v2 - Génère un passage intelligent en utilisant le service sémantique directement
  Future<ReadingRef> _generateIntelligentPassageWithSemanticService(String books, int day, Map<String, dynamic> userProfile) async {
    // Le service sémantique v2 gère toute la complexité
    // Il peut parser les livres, sélectionner intelligemment, et ajuster les passages
    
    // Pour l'instant, utilisons une approche simple mais intelligente
    // Le service sémantique peut être étendu pour gérer des chaînes complexes
    final bookList = books.split(RegExp(r'[&,]')).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
    final selectedBook = bookList[day % bookList.length];
    
    return await _generateIntelligentPassageForBook(selectedBook, day, userProfile);
  }

  /// Génère un passage intelligent pour un livre spécifique
  Future<ReadingRef> _generateIntelligentPassageForBook(String book, int day, Map<String, dynamic> userProfile) async {
    final durationMin = userProfile['durationMin'] ?? 15;
    final meditationType = userProfile['meditation'] as String?;
    final readingLength = _calculateReadingLength(durationMin, meditationType: meditationType);
    
    // 🚀 FALCON X v2 - Service sémantique avec contexte historique et priorisation intelligente
    final maxChapters = _getMaxChaptersForBook(book);
    // Corriger la logique pour commencer par le chapitre 1
    final chapter = ((day - 1) % maxChapters) + 1;
    
    // 1. PRIORISATION INTELLIGENTE : Sélectionner l'unité littéraire la plus pertinente
    final prioritizedUnit = _selectPrioritizedLiteraryUnit(book, chapter, day, userProfile);
    
    if (prioritizedUnit != null) {
      // 2. AJUSTEMENT SÉMANTIQUE : Respecter les unités littéraires
      final boundary = await SemanticPassageBoundaryService.adjustPassageVerses(
        book: book,
        startChapter: prioritizedUnit.startChapter,
        startVerse: prioritizedUnit.startVerse,
        endChapter: prioritizedUnit.endChapter,
        endVerse: prioritizedUnit.endVerse,
      );
      
      if (boundary.adjusted && boundary.includedUnit != null) {
        // 3. ENRICHISSEMENT HISTORIQUE : Ajouter le contexte chronologique
        _enrichWithHistoricalContext(boundary.includedUnit!);
        
        print('🧠 Passage sémantique généré: ${boundary.reference} (${prioritizedUnit.name})');
        return ReadingRef(
          book: book,
          range: _extractRangeFromReference(boundary.reference, book),
          url: null,
        );
      }
    }
    
    // 4. FALLBACK INTELLIGENT : Génération basique avec ajustement sémantique
    final boundary = await SemanticPassageBoundaryService.adjustPassageChapters(
      book: book,
      startChapter: chapter,
      endChapter: chapter,
    );
    
    if (boundary.adjusted && boundary.includedUnit != null) {
      _enrichWithHistoricalContext(boundary.includedUnit!);
      return ReadingRef(
        book: book,
        range: _extractRangeFromReference(boundary.reference, book),
        url: null,
      );
    }
    
    // 5. FALLBACK TRADITIONNEL : Logique basée sur le livre
    if (book.toLowerCase() == 'psaumes' || book.toLowerCase() == 'psaumes') {
      return ReadingRef(
        book: 'Psaumes',
        range: '${(day % 150) + 1}:1-${readingLength['psalms']}',
        url: null,
      );
    } else if (book.toLowerCase() == 'proverbes' || book.toLowerCase() == 'proverbes') {
      return ReadingRef(
        book: 'Proverbes',
        range: '${(day % 31) + 1}:1-${readingLength['proverbs']}',
        url: null,
      );
    } else if (_isNewTestament(book)) {
      // Pour les livres du NT, utiliser le service sémantique pour respecter les unités littéraires
      final semanticBoundary = await SemanticPassageBoundaryService.adjustPassageVerses(
        book: book,
        startChapter: chapter,
        startVerse: 1,
        endChapter: chapter + 1, // Permettre d'aller au chapitre suivant
        endVerse: 999, // Fin du chapitre
      );
      
      if (semanticBoundary.adjusted && semanticBoundary.includedUnit != null) {
        print('🧠 Passage sémantique NT généré: ${semanticBoundary.reference} (${semanticBoundary.includedUnit?.name})');
        return ReadingRef(
          book: book,
          range: _extractRangeFromReference(semanticBoundary.reference, book),
          url: null,
        );
      }
      
      // Fallback si pas d'unité littéraire trouvée
      final maxVerses = _getVersesInChapter(book, chapter);
      final requestedVerses = readingLength['gospels'] ?? 30;
      final actualVerses = requestedVerses > maxVerses ? maxVerses : requestedVerses;
      
      return ReadingRef(
        book: book,
        range: '$chapter:1-$actualVerses',
        url: null,
      );
    } else {
      // Pour les livres de l'AT, utiliser le service sémantique pour respecter les unités littéraires
      final semanticBoundary = await SemanticPassageBoundaryService.adjustPassageVerses(
        book: book,
        startChapter: chapter,
        startVerse: 1,
        endChapter: chapter + 1, // Permettre d'aller au chapitre suivant
        endVerse: 999, // Fin du chapitre
      );
      
      if (semanticBoundary.adjusted && semanticBoundary.includedUnit != null) {
        print('🧠 Passage sémantique AT généré: ${semanticBoundary.reference} (${semanticBoundary.includedUnit?.name})');
        return ReadingRef(
          book: book,
          range: _extractRangeFromReference(semanticBoundary.reference, book),
          url: null,
        );
      }
      
      // Fallback si pas d'unité littéraire trouvée
      return ReadingRef(
        book: book,
        range: '$chapter:1-${readingLength['default']}',
        url: null,
      );
    }
  }
  
  /// Retourne le nombre maximum de chapitres pour un livre donné
  int _getMaxChaptersForBook(String book) {
    return BibleVersesDatabase.getChaptersInBook(book);
  }
  
  /// Extrait la partie chapitre/verset d'une référence complète
  /// Ex: "1 Pierre 1:1–2:25" + "1 Pierre" → "1:1–2:25"
  String _extractRangeFromReference(String fullReference, String book) {
    try {
      // Nettoyer la référence
      final cleanRef = fullReference.trim();
      
      // Trouver le dernier espace pour séparer le livre du chapitre/verset
      final lastSpace = cleanRef.lastIndexOf(' ');
      if (lastSpace <= 0) return '1:1'; // Fallback
      
      final bookPart = cleanRef.substring(0, lastSpace).trim();
      var rangePart = cleanRef.substring(lastSpace + 1).trim();
      
      // 🔧 NOUVEAU : Remplacer :999 par le dernier verset du chapitre
      if (rangePart.contains(':999')) {
        // Parser la référence pour extraire les chapitres
        final match = RegExp(r'(\d+):(\d+)-(\d+):999').firstMatch(rangePart);
        if (match != null) {
          final startChapter = int.parse(match.group(1)!);
          final startVerse = int.parse(match.group(2)!);
          final endChapter = int.parse(match.group(3)!);
          
          // Récupérer le dernier verset du chapitre de fin
          final lastVerse = _getVersesInChapter(book, endChapter);
          rangePart = '$startChapter:$startVerse-$endChapter:$lastVerse';
          print('🔧 Référence corrigée: $rangePart (999 → $lastVerse)');
        }
      }
      
      // Vérifier que le livre correspond (pour éviter les erreurs)
      if (bookPart.toLowerCase() == book.toLowerCase()) {
        return rangePart;
      }
      
      // Si les livres ne correspondent pas, essayer de trouver le range quand même
      // en cherchant le premier ":" ou "-"
      final colonIndex = cleanRef.indexOf(':');
      if (colonIndex > 0) {
        // Prendre tout après le dernier espace avant le ":"
        final beforeColon = cleanRef.substring(0, colonIndex);
        final lastSpaceBeforeColon = beforeColon.lastIndexOf(' ');
        if (lastSpaceBeforeColon > 0) {
          return cleanRef.substring(lastSpaceBeforeColon + 1);
        }
      }
      
      return rangePart;
    } catch (e) {
      print('⚠️ Erreur extraction range de "$fullReference": $e');
      return '1:1'; // Fallback
    }
  }
  
  /// Parse une référence Thompson en ReadingRef
  ReadingRef? _parseThompsonReference(String reference) {
    try {
      // Exemple: "Matthieu 1:1-5" -> ReadingRef
      final parts = reference.split(' ');
      if (parts.length < 2) return null;
      
      final book = parts[0];
      final range = parts.sublist(1).join(' ');
      
      return ReadingRef(
        book: book,
        range: range,
        url: null,
      );
    } catch (e) {
      print('⚠️ Erreur parsing référence Thompson: $e');
      return null;
    }
  }
  
  /// Vérifie si un livre est de l'Ancien Testament
  bool _isOldTestament(String book) {
    const otBooks = [
      'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
      'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel', '1 Rois', '2 Rois',
      '1 Chroniques', '2 Chroniques', 'Esdras', 'Néhémie', 'Esther',
      'Job', 'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique des Cantiques',
      'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel',
      'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas', 'Michée', 'Nahum',
      'Habacuc', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie'
    ];
    return otBooks.contains(book);
  }
  
  /// Vérifie si un livre est du Nouveau Testament
  bool _isNewTestament(String book) {
    const ntBooks = [
      'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
      'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens',
      'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens',
      '1 Timothée', '2 Timothée', 'Tite', 'Philémon', 'Hébreux',
      'Jacques', '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean',
      'Jude', 'Apocalypse'
    ];
    return ntBooks.contains(book);
  }

  /// Génère des lectures locales basées sur les livres sélectionnés et la durée disponible
  Future<List<ReadingRef>> _generateLocalReadings(String books, int dayIndex) async {
    // Récupérer la durée choisie par l'utilisateur depuis le profil
    final durationMin = await _getUserDurationMin();
    final meditationType = await _getUserMeditationType();
    
    // Calculer le nombre de versets/chapitres selon la durée et le type de méditation
    final readingLength = _calculateReadingLength(durationMin, meditationType: meditationType);
    
    // Parser la chaîne books pour extraire les livres individuels
    final bookList = books.split(',').map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
    print('🔍 _generateLocalReadings: Livres parsés: $bookList');
    
    // ✅ NOUVELLE LOGIQUE : Un seul livre par jour, distribué sur plusieurs semaines
    final readings = <ReadingRef>[];
    
    if (bookList.isNotEmpty) {
      // Calculer quel livre lire aujourd'hui (distribution cyclique)
      final bookIndex = (dayIndex - 1) % bookList.length;
      final currentBook = bookList[bookIndex];
      
      print('🔍 _generateLocalReadings: Jour $dayIndex → Livre ${bookIndex + 1}/${bookList.length}: $currentBook');
      
      // Générer le passage pour ce livre spécifique
      if (currentBook.toLowerCase() == 'psalms' || currentBook.toLowerCase() == 'psaumes') {
        readings.add(ReadingRef(
          book: 'Psaumes',
          range: '${(dayIndex % 150) + 1}:1-${readingLength['psalms']}',
          url: null,
        ));
      } else if (currentBook.toLowerCase() == 'proverbs' || currentBook.toLowerCase() == 'proverbes') {
        readings.add(ReadingRef(
          book: 'Proverbes',
          range: '${(dayIndex % 31) + 1}:1-${readingLength['proverbs']}',
          url: null,
        ));
      } else if (currentBook.toLowerCase() == 'gospels' || currentBook.toLowerCase() == 'évangiles') {
        final gospels = ['Matthieu', 'Marc', 'Luc', 'Jean'];
        final gospel = gospels[dayIndex % gospels.length];
        readings.add(ReadingRef(
          book: gospel,
          range: '${(dayIndex % 28) + 1}:1-${readingLength['gospels']}',
          url: null,
        ));
      } else if (currentBook.toLowerCase() == 'nt' || currentBook.toLowerCase() == 'nouveau testament') {
        readings.add(ReadingRef(
          book: 'Épîtres',
          range: '$dayIndex:1-${readingLength['epistles']}',
          url: null,
        ));
      } else if (currentBook.toLowerCase() == 'ot' || currentBook.toLowerCase() == 'ancien testament') {
        readings.add(ReadingRef(
          book: 'Ancien Testament',
          range: '$dayIndex:1-${readingLength['ot']}',
          url: null,
        ));
      } else {
        // Livre spécifique (ex: Matthieu, Romains, Jacques, Éphésiens)
        readings.add(ReadingRef(
          book: currentBook,
          range: '${(dayIndex % 10) + 1}:1-${readingLength['default']}',
          url: null,
        ));
      }
    }
    
    // Si aucune lecture générée, créer une lecture par défaut
    if (readings.isEmpty) {
      readings.add(ReadingRef(
        book: 'Genèse',
        range: '$dayIndex:1-${readingLength['default']}',
        url: null,
      ));
    }
    
    print('🔍 _generateLocalReadings: Lectures générées: ${readings.map((r) => '${r.book} ${r.range}').join(', ')}');
    return readings;
  }

  /// Récupère la durée quotidienne choisie par l'utilisateur
  Future<int> _getUserDurationMin() async {
    try {
      // Synchroniser d'abord les deux systèmes
      await UserPrefsSync.syncBidirectional();
      
      // Essayer de récupérer depuis UserPrefs
      final profile = await UserPrefs.loadProfile();
      return profile['durationMin'] as int? ?? 15; // 15 min par défaut
    } catch (e) {
      return 15; // Fallback à 15 minutes
    }
  }
  
  /// Récupère le type de méditation depuis le profil utilisateur
  Future<String?> _getUserMeditationType() async {
    try {
      // Synchroniser d'abord les deux systèmes
      await UserPrefsSync.syncBidirectional();
      
      // Essayer de récupérer depuis UserPrefs
      final profile = await UserPrefs.loadProfile();
      return profile['meditation'] as String?;
    } catch (e) {
      return null; // Fallback à null (utilisera la valeur par défaut)
    }
  }

  /// Calcule la longueur de lecture selon la durée disponible
  /// S'adapte au type de méditation pour ajuster la vitesse de lecture
  Map<String, int> _calculateReadingLength(int durationMin, {String? meditationType}) {
    // Vitesse de base adaptée au type de méditation
    double versesPerMinute = _getVersesPerMinuteForMeditation(meditationType);
    final totalVerses = (durationMin * versesPerMinute).round();
    
    return {
      'psalms': _clampVerses(totalVerses, 3, 15), // Psaumes : 3-15 versets
      'proverbs': _clampVerses(totalVerses, 5, 20), // Proverbes : 5-20 versets
      'gospels': _clampVerses(totalVerses, 4, 18), // Évangiles : 4-18 versets
      'epistles': _clampVerses(totalVerses, 6, 25), // Épîtres : 6-25 versets
      'ot': _clampVerses(totalVerses, 5, 22), // AT : 5-22 versets
      'default': _clampVerses(totalVerses, 4, 18), // Défaut : 4-18 versets
    };
  }
  
  /// Retourne la vitesse de lecture adaptée au type de méditation
  double _getVersesPerMinuteForMeditation(String? meditationType) {
    if (meditationType == null) return 1.8; // Défaut
    
    // Vitesses ajustées selon l'intensité de chaque méthode
    if (meditationType.contains('Méditation profonde')) {
      return 1.5; // Plus lent pour la réflexion profonde
    } else if (meditationType.contains('Prière')) {
      return 1.2; // Très lent pour les pauses de prière
    } else if (meditationType.contains('Application')) {
      return 1.6; // Modéré pour l'application pratique
    } else if (meditationType.contains('Mémorisation')) {
      return 1.0; // Très lent pour la répétition
    }
    
    return 1.8; // Défaut
  }

  /// Limite le nombre de versets dans une plage raisonnable
  int _clampVerses(int verses, int min, int max) {
    return verses.clamp(min, max);
  }

  /// Retourne le nombre réel de versets pour un chapitre donné
  int _getVersesInChapter(String book, int chapter) {
    return BibleVersesDatabase.getVersesInChapter(book, chapter);
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
  @override
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
  @override
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

  // ============================================================================
  // 🧠 INTELLIGENCE SÉMANTIQUE AVANCÉE - FALCON X v2
  // ============================================================================

  /// Sélectionne l'unité littéraire la plus pertinente selon le profil utilisateur
  LiteraryUnit? _selectPrioritizedLiteraryUnit(String book, int chapter, int day, Map<String, dynamic> userProfile) {
    try {
      // 1. Récupérer toutes les unités littéraires pour ce livre
      final allUnits = SemanticPassageBoundaryService.getUnitsForBook(book);
      if (allUnits.isEmpty) return null;

      // 2. Filtrer les unités qui incluent le chapitre demandé
      final relevantUnits = allUnits.where((unit) => 
        unit.startChapter <= chapter && unit.endChapter >= chapter
      ).toList();

      if (relevantUnits.isEmpty) return null;

      // 3. PRIORISATION INTELLIGENTE basée sur :
      // - Priorité de l'unité (critical > high > medium > low)
      // - Objectif utilisateur
      // - Niveau spirituel
      // - Jour de lecture (progression logique)

      final goal = userProfile['goal'] as String? ?? '';
      final level = userProfile['level'] as String? ?? '';
      final heartPosture = userProfile['heartPosture'] as String? ?? '';

      // Score de priorisation
      LiteraryUnit? bestUnit;
      int bestScore = -1;

      for (final unit in relevantUnits) {
        int score = 0;

        // Score de priorité de l'unité
        switch (unit.priority) {
          case UnitPriority.critical:
            score += 100;
            break;
          case UnitPriority.high:
            score += 75;
            break;
          case UnitPriority.medium:
            score += 50;
            break;
          case UnitPriority.low:
            score += 25;
            break;
        }

        // Score basé sur l'objectif utilisateur
        if (_unitMatchesGoal(unit, goal)) {
          score += 50;
        }

        // Score basé sur le niveau spirituel
        if (_unitMatchesLevel(unit, level)) {
          score += 30;
        }

        // Score basé sur la posture du cœur
        if (_unitMatchesHeartPosture(unit, heartPosture)) {
          score += 20;
        }

        // Score de progression (éviter de répéter les mêmes unités)
        final unitKey = '${unit.name}_${unit.startChapter}_${unit.startVerse}';
        final lastUsed = _getLastUsedUnit(unitKey);
        if (lastUsed == null || (day - lastUsed) > 30) {
          score += 15; // Bonus pour les unités non utilisées récemment
        }

        // Score de cohérence narrative (préférer les unités complètes)
        if (unit.startChapter == unit.endChapter) {
          score += 10; // Bonus pour les unités dans un seul chapitre
        }

        if (score > bestScore) {
          bestScore = score;
          bestUnit = unit;
        }
      }

      // 4. Enregistrer l'unité utilisée pour éviter les répétitions
      if (bestUnit != null) {
        final unitKey = '${bestUnit.name}_${bestUnit.startChapter}_${bestUnit.startVerse}';
        _recordUsedUnit(unitKey, day);
      }

      return bestUnit;
    } catch (e) {
      print('⚠️ Erreur priorisation unité littéraire: $e');
      return null;
    }
  }

  /// Vérifie si une unité correspond à l'objectif utilisateur
  bool _unitMatchesGoal(LiteraryUnit unit, String goal) {
    if (goal.isEmpty) return false;
    
    final goalLower = goal.toLowerCase();
    final unitNameLower = unit.name.toLowerCase();
    final unitDescLower = (unit.description ?? '').toLowerCase();

    // Correspondances spécifiques par objectif
    if (goalLower.contains('témoigner') || goalLower.contains('évangéliser')) {
      return unitNameLower.contains('mission') || 
             unitNameLower.contains('témoignage') ||
             unitNameLower.contains('évangile') ||
             unitDescLower.contains('mission');
    }
    
    if (goalLower.contains('prière') || goalLower.contains('mieux prier')) {
      return unitNameLower.contains('prière') || 
             unitNameLower.contains('prier') ||
             unitDescLower.contains('prière');
    }
    
    if (goalLower.contains('sagesse')) {
      return unitNameLower.contains('sagesse') || 
             unitNameLower.contains('proverbe') ||
             unitDescLower.contains('sagesse');
    }

    return false;
  }

  /// Vérifie si une unité correspond au niveau spirituel
  bool _unitMatchesLevel(LiteraryUnit unit, String level) {
    if (level.isEmpty) return false;
    
    final levelLower = level.toLowerCase();
    final unitNameLower = unit.name.toLowerCase();

    if (levelLower.contains('nouveau') || levelLower.contains('débutant')) {
      // Pour les nouveaux convertis, privilégier les unités fondamentales
      return unitNameLower.contains('création') || 
             unitNameLower.contains('évangile') ||
             unitNameLower.contains('salut') ||
             unit.priority == UnitPriority.critical;
    }
    
    if (levelLower.contains('fidèle') || levelLower.contains('régulier')) {
      // Pour les fidèles réguliers, toutes les unités sont appropriées
      return true;
    }
    
    if (levelLower.contains('mature') || levelLower.contains('avancé')) {
      // Pour les matures, privilégier les unités complexes
      return unitNameLower.contains('prophétie') || 
             unitNameLower.contains('apocalypse') ||
             unit.priority == UnitPriority.high ||
             unit.priority == UnitPriority.critical;
    }

    return true;
  }

  /// Vérifie si une unité correspond à la posture du cœur
  bool _unitMatchesHeartPosture(LiteraryUnit unit, String heartPosture) {
    if (heartPosture.isEmpty) return false;
    
    final postureLower = heartPosture.toLowerCase();
    final unitNameLower = unit.name.toLowerCase();

    if (postureLower.contains('écouter')) {
      return unitNameLower.contains('parole') || 
             unitNameLower.contains('écouter') ||
             unitNameLower.contains('révélation');
    }
    
    if (postureLower.contains('reconnaissance')) {
      return unitNameLower.contains('louange') || 
             unitNameLower.contains('reconnaissance') ||
             unitNameLower.contains('psaume');
    }
    
    if (postureLower.contains('repentance')) {
      return unitNameLower.contains('repentance') || 
             unitNameLower.contains('pardon') ||
             unitNameLower.contains('conversion');
    }

    return true;
  }

  /// Enrichit une unité littéraire avec le contexte historique
  void _enrichWithHistoricalContext(LiteraryUnit unit) {
    try {
      // Utiliser le service de chronologie pour enrichir la description
      final enrichedDescription = _buildEnrichedDescription(unit);
      if (enrichedDescription.isNotEmpty) {
        print('📚 Contexte historique ajouté: ${unit.name}');
        // Note: Dans une implémentation complète, on pourrait stocker cette
        // description enrichie pour l'affichage dans l'interface utilisateur
      }
    } catch (e) {
      print('⚠️ Erreur enrichissement historique: $e');
    }
  }

  /// Construit une description enrichie avec le contexte historique
  String _buildEnrichedDescription(LiteraryUnit unit) {
    try {
      // Trouver la période historique correspondante
      final period = _getHistoricalPeriodForBook(unit.book);
      if (period == null) return unit.description ?? '';

      final buffer = StringBuffer();
      buffer.write(unit.description ?? '');
      
      if (period['name'] != null) {
        buffer.write(' • Contexte historique: ${period['name']}');
      }
      
      if (period['description'] != null) {
        buffer.write(' • ${period['description']}');
      }
      
      if (period['themes'] != null) {
        final themes = (period['themes'] as List<dynamic>? ?? [])
            .map((t) => t.toString())
            .join(', ');
        if (themes.isNotEmpty) {
          buffer.write(' • Thèmes de l\'époque: $themes');
        }
      }
      
      if (period['events'] != null) {
        final events = period['events'] as List<dynamic>? ?? [];
        if (events.isNotEmpty) {
          final eventTitles = events
              .map((e) => (e as Map<String, dynamic>)['title']?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .take(3)
              .join(', ');
          if (eventTitles.isNotEmpty) {
            buffer.write(' • Événements clés: $eventTitles');
          }
        }
      }

      return buffer.toString();
    } catch (e) {
      print('⚠️ Erreur construction description enrichie: $e');
      return unit.description ?? '';
    }
  }

  /// Trouve la période historique correspondant à un livre biblique
  Map<String, dynamic>? _getHistoricalPeriodForBook(String book) {
    try {
      // Mapping simplifié livre -> période historique
      final bookToPeriod = {
        'Genèse': 'Patriarches',
        'Exode': 'Exode et Conquête',
        'Lévitique': 'Exode et Conquête',
        'Nombres': 'Exode et Conquête',
        'Deutéronome': 'Exode et Conquête',
        'Josué': 'Exode et Conquête',
        'Juges': 'Exode et Conquête',
        'Ruth': 'Exode et Conquête',
        '1 Samuel': 'Royaume uni',
        '2 Samuel': 'Royaume uni',
        '1 Rois': 'Royaume uni',
        '2 Rois': 'Royaume uni',
        '1 Chroniques': 'Royaume uni',
        '2 Chroniques': 'Royaume uni',
        'Matthieu': 'Nouveau Testament',
        'Marc': 'Nouveau Testament',
        'Luc': 'Nouveau Testament',
        'Jean': 'Nouveau Testament',
        'Actes': 'Nouveau Testament',
        'Romains': 'Nouveau Testament',
        '1 Corinthiens': 'Nouveau Testament',
        '2 Corinthiens': 'Nouveau Testament',
        'Galates': 'Nouveau Testament',
        'Éphésiens': 'Nouveau Testament',
        'Philippiens': 'Nouveau Testament',
        'Colossiens': 'Nouveau Testament',
        '1 Thessaloniciens': 'Nouveau Testament',
        '2 Thessaloniciens': 'Nouveau Testament',
        '1 Timothée': 'Nouveau Testament',
        '2 Timothée': 'Nouveau Testament',
        'Tite': 'Nouveau Testament',
        'Philémon': 'Nouveau Testament',
        'Hébreux': 'Nouveau Testament',
        'Jacques': 'Nouveau Testament',
        '1 Pierre': 'Nouveau Testament',
        '2 Pierre': 'Nouveau Testament',
        '1 Jean': 'Nouveau Testament',
        '2 Jean': 'Nouveau Testament',
        '3 Jean': 'Nouveau Testament',
        'Jude': 'Nouveau Testament',
        'Apocalypse': 'Nouveau Testament',
      };

      final periodName = bookToPeriod[book];
      if (periodName == null) return null;

      // Retourner les données de la période (simulées pour l'instant)
      return {
        'name': periodName,
        'description': 'Période biblique correspondante',
        'themes': ['foi', 'alliance', 'bénédiction'],
        'events': [
          {'title': 'Événement clé 1'},
          {'title': 'Événement clé 2'},
        ],
      };
    } catch (e) {
      print('⚠️ Erreur recherche période historique: $e');
      return null;
    }
  }

  // Cache simple pour éviter les répétitions d'unités
  static final Map<String, int> _usedUnits = {};

  /// Enregistre l'utilisation d'une unité littéraire
  void _recordUsedUnit(String unitKey, int day) {
    _usedUnits[unitKey] = day;
  }

  /// Récupère le jour d'utilisation d'une unité littéraire
  int? _getLastUsedUnit(String unitKey) {
    return _usedUnits[unitKey];
  }
}
