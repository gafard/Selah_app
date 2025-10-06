import 'dart:async';
import 'package:hive/hive.dart';
import '../core/sync_models.dart';
import '../core/hive_boxes.dart';
import '../data/user_repo.dart';

abstract class SyncQueue {
  Future<void> enqueue(SyncTask task);
  Future<bool> hasPending();
}

class SyncQueueImpl implements SyncQueue {
  final UserRepo userRepo;

  static const workUnique = 'selah_sync_worker';
  static const workTask = 'sync_dequeue_once';

  SyncQueueImpl(this.userRepo);

  @override
  Future<void> enqueue(SyncTask task) async {
    final box = Hive.box(Boxes.syncTasks);
    await box.put(task.id, task.toMap());
    await _kickWorker();
  }

  @override
  Future<bool> hasPending() async {
    final box = Hive.box(Boxes.syncTasks);
    return box.isNotEmpty;
  }

  Future<void> _kickWorker() async {
    // Synchronisation directe au lieu de workmanager
    await _processTasksDirectly();
  }

  /// Traite les tâches directement (sans workmanager)
  Future<void> _processTasksDirectly() async {
    final box = Hive.box(Boxes.syncTasks);
    final keys = box.keys.cast<String>().toList();
    if (keys.isEmpty) return;

    final key = keys.first;
    final map = Map<String, dynamic>.from(box.get(key));
    var task = SyncTask.fromMap(map);

    try {
      switch (task.type) {
        case 'profile_sync':
          await userRepo.syncProfileToServer(task.payload, idempotencyKey: task.idempotencyKey);
          await box.delete(key);
          break;
        default:
          // tâche inconnue -> drop
          await box.delete(key);
      }
    } catch (_) {
      // retry/backoff
      task = task.copyWith(attempt: task.attempt + 1);
      if (task.attempt >= task.maxRetries) {
        await box.delete(key); // dead-letter: tu peux déplacer dans une autre box si besoin
      } else {
        await box.put(key, task.toMap());
        // Replanifier avec délai (backoff)
      }
    }
  }
}


