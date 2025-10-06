import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'core/hive_boxes.dart';
import 'data/user_repo.dart';
import 'sync/sync_queue.dart';
import 'core/sync_models.dart';

class AppState extends ChangeNotifier {
  final UserRepo userRepo;
  final SyncQueue queue;

  Map<String, dynamic>? profile;   // null si pas encore chargé
  bool hasPendingSync = false;

  late final Stream<BoxEvent> _syncWatch;
  late final Stream<BoxEvent> _profileWatch;
  bool _disposed = false;

  AppState(this.userRepo, this.queue) {
    _bind();
  }

  Future<void> _bind() async {
    await refreshLocal();
    await _refreshPendingFlag();

    _syncWatch = Hive.box(Boxes.syncTasks).watch();
    _profileWatch = Hive.box(Boxes.profile).watch();

    _syncWatch.listen((_) => _refreshPendingFlag());
    _profileWatch.listen((_) => refreshLocal());
  }

  Future<void> refreshLocal() async {
    profile = await userRepo.getProfileLocal();
    _emit();
  }

  Future<void> _refreshPendingFlag() async {
    hasPendingSync = await queue.hasPending();
    _emit();
  }

  Future<void> setHasOnboardedOptimistic() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final current = await userRepo.getProfileLocal();
    final opt = {
      ...current,
      'id': current['id'] ?? 'guest',
      'hasOnboarded': true,
      'updated_at_local': now,
    };
    await userRepo.upsertLocalProfile(opt);

    final task = SyncTask(
      id: newTaskId(),
      type: 'profile_sync',
      payload: opt,
      idempotencyKey: 'onboarding_$now',
    );
    await queue.enqueue(task);
  }

  void _emit() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Provider short-hand
class AppStateProvider extends InheritedNotifier<AppState> {
  AppStateProvider({
    super.key,
    required UserRepoSupabase userRepo,
    required SyncQueueImpl queue,
    required super.child,
  }) : super(
          notifier: AppState(userRepo, queue),
        );

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStateProvider>()!.notifier!;
}


