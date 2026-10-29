import 'package:equatable/equatable.dart';

import '../../../profile/domain/entities/app_user.dart';
import '../../../profile/domain/entities/user_role.dart';

enum SessionStatus {
  /// Auth state or profile is still being resolved.
  loading,
  unauthenticated,
  customer,
  admin,

  /// Signed in, but no profile document exists.
  profileMissing,

  /// Signed in, but the profile is invalid or could not be read.
  error,
}

class SessionState extends Equatable {
  const SessionState._(this.status, {this.user, this.message});

  const SessionState.loading() : this._(SessionStatus.loading);

  const SessionState.unauthenticated() : this._(SessionStatus.unauthenticated);

  const SessionState.profileMissing()
      : this._(
          SessionStatus.profileMissing,
          message: 'We could not find your account profile.',
        );

  const SessionState.error(String message)
      : this._(SessionStatus.error, message: message);

  /// The role comes only from the trusted Firestore profile.
  factory SessionState.authenticated(AppUser user) {
    return SessionState._(
      user.role == UserRole.admin ? SessionStatus.admin : SessionStatus.customer,
      user: user,
    );
  }

  final SessionStatus status;
  final AppUser? user;
  final String? message;

  bool get isAuthenticated =>
      status == SessionStatus.customer || status == SessionStatus.admin;

  @override
  List<Object?> get props => [status, user, message];
}
