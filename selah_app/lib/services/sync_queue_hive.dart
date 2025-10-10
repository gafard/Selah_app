import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
// workmanager supprimé pour éviter les problèmes de compatibilité
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'user_repo_supabase.dart';
import 'telemetry_console.dart';

// Callback dispatcher supprimé - workmanager n'est plus utilisé
// La synchronisation se fait maintenant à l'ouverture de l'app

class SyncQueueHive {
  final Box box;
  final TelemetryConsole telemetry;
  final UserRepoSupabase userRepo;
  final _pending = ValueNotifier<int>(0);

  SyncQueueHive(this.box, {required this.telemetry, required this.userRepo}) {
    _pending.value = box.length;
    box.watch().listen((_) => _pending.value = box.length);
  }

  ValueListenable<int> get pendingCount => _pending;

  Future<void> enqueueUserPatch(Map<String, dynamic> patch) async {
    final idKey = const Uuid().v4();
    await box.add({
      'kind': 'user_patch',
      'idempotencyKey': idKey,
      'payload': patch,
      'createdAt': DateTime.now().toIso8601String(),
    });
    telemetry.event('sync_enqueued', {'kind': 'user_patch'});

    // Synchronisation directe au lieu de workmanager
    _flushPendingTasks();
  }

  /// Récupère les tâches en attente de synchronisation
  Future<List<Map<String, dynamic>>> getPendingTasks() async {
    final tasks = <Map<String, dynamic>>[];
    for (var i = 0; i < box.length; i++) {
      final task = box.getAt(i) as Map<String, dynamic>?;
      if (task != null) {
        tasks.add(task);
      }
    }
    return tasks;
  }

  /// Enregistre la création d'un plan pour synchronisation ultérieure
  Future<void> enqueuePlanCreate(dynamic plan) async {
    final idKey = const Uuid().v4();
    await box.add({
      'kind': 'plan_create',
      'idempotencyKey': idKey,
      'payload': plan.toJson(), // Convertir le plan en JSON
      'createdAt': DateTime.now().toIso8601String(),
    });
    telemetry.event('sync_enqueued', {'kind': 'plan_create', 'plan_id': plan.id});

    // Synchronisation directe au lieu de workmanager
    _flushPendingTasks();
  }

  /// Enregistre un patch de plan pour synchronisation ultérieure
  Future<void> enqueuePlanPatch(String planId, Map<String, dynamic> patch) async {
    final idKey = const Uuid().v4();
    await box.add({
      'kind': 'plan_patch',
      'idempotencyKey': idKey,
      'planId': planId,
      'payload': patch,
      'createdAt': DateTime.now().toIso8601String(),
    });
    telemetry.event('sync_enqueued', {'kind': 'plan_patch', 'plan_id': planId});

    // Synchronisation directe au lieu de workmanager
    _flushPendingTasks();
  }

  Future<void> _flushPendingTasks() async {
    final keys = box.keys.toList();
    for (final k in keys) {
      final m = Map<String, dynamic>.from(box.get(k));
      final kind = m['kind'] as String;
      try {
        if (kind == 'user_patch') {
          await userRepo.patchUser(m['payload'], idempotencyKey: m['idempotencyKey']);
        } else if (kind == 'plan_create') {
          // TODO: Implémenter l'envoi du plan au serveur
          // await planRepo.syncPlanToServer(m['payload'], idempotencyKey: m['idempotencyKey']);
          telemetry.event('plan_sync_deferred', {'reason': 'not_implemented'});
        } else if (kind == 'plan_patch') {
          // TODO: Implémenter l'envoi du patch plan au serveur
          // await planRepo.patchPlan(m['planId'], m['payload'], idempotencyKey: m['idempotencyKey']);
          telemetry.event('plan_patch_sync_deferred', {'reason': 'not_implemented', 'plan_id': m['planId']});
        }
        await box.delete(k);
      } catch (e) {
        telemetry.event('sync_error', {'kind': kind, 'error': e.toString()});
      }
    }
  }
}