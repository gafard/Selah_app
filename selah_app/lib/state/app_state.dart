import 'package:flutter/foundation.dart';
import '../services/sync_queue_hive.dart';

class AppState extends ValueNotifier<AppStateData> {
  final SyncQueueHive syncQueue;

  AppState({required this.syncQueue}) : super(AppStateData.initial()) {
    syncQueue.pendingCount.addListener(() {
      value = value.copyWith(hasPendingSync: syncQueue.pendingCount.value > 0);
    });
  }

  void setProfile(Map<String, dynamic> profile) {
    value = value.copyWith(profile: profile);
  }
}

class AppStateData {
  final Map<String, dynamic>? profile;
  final bool hasPendingSync;
  AppStateData({this.profile, required this.hasPendingSync});
  factory AppStateData.initial() => AppStateData(profile: null, hasPendingSync: false);
  AppStateData copyWith({Map<String, dynamic>? profile, bool? hasPendingSync}) =>
      AppStateData(profile: profile ?? this.profile, hasPendingSync: hasPendingSync ?? this.hasPendingSync);
}