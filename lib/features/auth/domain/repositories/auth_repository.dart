abstract interface class AuthRepository {
  /// Emits the signed-in user's uid, or null when signed out.
  Stream<String?> watchAuthUid();

  Future<void> signIn({required String email, required String password});

  /// Creates the auth account and the customer profile. If the profile cannot
  /// be created, the new auth account is removed again.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset({required String email});
}
