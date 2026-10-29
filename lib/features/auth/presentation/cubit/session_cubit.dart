import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../profile/domain/entities/app_user.dart';
import '../../../profile/domain/usecases/watch_profile.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/watch_auth_uid.dart';
import 'session_state.dart';

/// Single source of truth for "who is signed in and what may they see".
///
/// Driven by FirebaseAuth.authStateChanges() and the user's Firestore profile.
/// Screens never navigate after login; the router reacts to this state.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required WatchAuthUid watchAuthUid,
    required WatchProfile watchProfile,
    required SignOut signOut,
    this.missingProfileGrace = const Duration(seconds: 8),
  })  : _watchAuthUid = watchAuthUid,
        _watchProfile = watchProfile,
        _signOut = signOut,
        super(const SessionState.loading());

  final WatchAuthUid _watchAuthUid;
  final WatchProfile _watchProfile;
  final SignOut _signOut;

  /// Right after registration the profile document is written a moment after
  /// the auth account exists. We wait this long before calling it missing.
  final Duration missingProfileGrace;

  StreamSubscription<String?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;
  Timer? _graceTimer;
  String? _currentUid;

  /// Starts listening. Call once at app start.
  void start() {
    _authSub?.cancel();
    _authSub = _watchAuthUid().listen(
      _onUid,
      onError: (Object _) =>
          emit(const SessionState.error('Could not check your sign-in status.')),
    );
  }

  void _onUid(String? uid) {
    _currentUid = uid;
    _cancelProfile();
    if (uid == null) {
      emit(const SessionState.unauthenticated());
      return;
    }
    emit(const SessionState.loading());
    _listenProfile(uid);
  }

  void _listenProfile(String uid) {
    _profileSub = _watchProfile(uid).listen(
      _onProfile,
      onError: _onProfileError,
    );
  }

  void _onProfile(AppUser? user) {
    if (_currentUid == null) return;
    if (user == null) {
      _graceTimer ??= Timer(missingProfileGrace, () {
        _graceTimer = null;
        if (!isClosed && _currentUid != null) {
          emit(const SessionState.profileMissing());
        }
      });
      return;
    }
    _graceTimer?.cancel();
    _graceTimer = null;
    emit(SessionState.authenticated(user));
  }

  void _onProfileError(Object error) {
    // Errors that arrive while signing out are expected and ignored.
    if (_currentUid == null) return;
    _graceTimer?.cancel();
    _graceTimer = null;
    final message = error is Failure
        ? error.message
        : 'Could not load your account. Please try again.';
    emit(SessionState.error(message));
  }

  /// Re-checks the profile after a failure.
  void retry() {
    final uid = _currentUid;
    if (uid == null) return;
    _cancelProfile();
    emit(const SessionState.loading());
    _listenProfile(uid);
  }

  Future<void> signOut() async {
    try {
      await _signOut();
    } catch (_) {
      // The auth stream decides the state; nothing to roll back here.
    }
  }

  void _cancelProfile() {
    _graceTimer?.cancel();
    _graceTimer = null;
    _profileSub?.cancel();
    _profileSub = null;
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    _cancelProfile();
    return super.close();
  }
}
