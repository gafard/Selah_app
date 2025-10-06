class AuthService {
  AuthService._();
  static final instance = AuthService._();

  Future<void> signInWithEmail(String email, String password) async {
    // TODO: branchement Supabase
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    // TODO: branchement Supabase
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> resetPassword(String email) async {
    // TODO: branchement Supabase
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> signInWithGoogle() async {
    // TODO: branchement Supabase OAuth
    await Future.delayed(const Duration(milliseconds: 800));
  }
}