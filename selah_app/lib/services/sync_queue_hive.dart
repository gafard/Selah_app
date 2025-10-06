import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'user_repo_supabase.dart';
import 'telemetry_console.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    // Init Hive en isolate background
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    final syncBox = await Hive.openBox('sync_tasks');

    final telemetry = TelemetryConsole(); // console-safe en BG
    final userRepo = UserRepoSupabase();

    Future<void> _flush() async {
      final keys = syncBox.keys.toList();
      for (final k in keys) {
        final m = Map<String, dynamic>.from(syncBox.get(k));
        final kind = m['kind'] as String;
        try {
          if (kind == 'user_patch') {
            await userRepo.patchUser(m['payload'], idempotencyKey: m['idempotencyKey']);
          }
          // Ajoute d'autres kinds ici si besoin…
          await syncBox.delete(k);
        } catch (e) {
          telemetry.event('sync_error', {'kind': kind, 'error': e.toString()});
          // garder en file => retry au prochain tick
          return;
        }
      }
    }

    if (input?['kind'] == 'sync_all') {
      await _flush();
    } else if (input?['kind'] == 'single') {
      // no-op: on flush quand même tout
      await _flush();
    }
    return Future.value(true);
  });
}

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

    // déclenche un job one-shot
    await Workmanager().registerOneOffTask(
      'sync-single-$idKey',
      'sync.single',
      inputData: {'kind': 'single'},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}