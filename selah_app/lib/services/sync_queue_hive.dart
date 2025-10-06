import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
// workmanager supprimé pour éviter les problèmes de compatibilité
import 'package:path_provider/path_provider.dart';
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

  Future<void> _flushPendingTasks() async {
    final keys = box.keys.toList();
    for (final k in keys) {
      final m = Map<String, dynamic>.from(box.get(k));
      final kind = m['kind'] as String;
      try {
        if (kind == 'user_patch') {
          await userRepo.patchUser(m['payload'], idempotencyKey: m['idempotencyKey']);
        }
        await box.delete(k);
      } catch (e) {
        telemetry.event('sync_error', {'kind': kind, 'error': e.toString()});
      }
    }
  }
}