class UserRepoSupabase {
  /// Patch du user (table `users`) — upsert idempotent par header.
  Future<void> patchUser(Map<String, dynamic> patch, {required String idempotencyKey}) async {
    // Mock implementation for now - in real app, this would sync to Supabase
    print('[UserRepoSupabase] Mock patch: $patch with key: $idempotencyKey');
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
  }
}