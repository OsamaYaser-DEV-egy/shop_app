import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._auth);

  final FirebaseAuth _auth;

  Stream<String?> watchUid() =>
      _auth.authStateChanges().map((user) => user?.uid).distinct();

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Creates the account and returns its uid.
  Future<String> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.uid;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Best-effort removal of the signed-in account, used to roll back a
  /// registration whose profile could not be created.
  Future<void> deleteCurrentUserQuietly() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      // If deletion fails, the session screen offers retry and sign-out.
    }
  }
}
