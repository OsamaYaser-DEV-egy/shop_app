import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'failures.dart';

/// Converts any thrown object into a [Failure] with a friendly message.
/// Raw backend messages are never shown to the user.
abstract final class ErrorMapper {
  static Failure map(Object error) {
    if (error is Failure) return error;
    if (error is FirebaseAuthException) return _auth(error);
    if (error is FirebaseFunctionsException) return _functions(error);
    if (error is FirebaseException) return _firestore(error);
    return const Failure('Something went wrong. Please try again.');
  }

  static Failure _auth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const Failure('That email address is not valid.', code: 'invalid-email');
      case 'user-disabled':
        return const Failure('This account has been disabled.', code: 'user-disabled');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const Failure('Incorrect email or password.', code: 'invalid-credential');
      case 'email-already-in-use':
        return const Failure('An account with this email already exists.', code: 'email-in-use');
      case 'weak-password':
        return const Failure('Please choose a stronger password (6+ characters).', code: 'weak-password');
      case 'too-many-requests':
        return const Failure('Too many attempts. Please wait and try again.', code: 'too-many-requests');
      case 'network-request-failed':
        return const Failure('No internet connection.', code: 'network');
      case 'requires-recent-login':
        return const Failure('Please sign in again to continue.', code: 'recent-login');
      default:
        return const Failure('Authentication failed. Please try again.');
    }
  }

  static Failure _firestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const Failure('You do not have permission to do that.', code: 'permission-denied');
      case 'unavailable':
      case 'network-request-failed':
        return const Failure('No internet connection.', code: 'network');
      case 'not-found':
        return const Failure('The requested item was not found.', code: 'not-found');
      case 'unauthenticated':
        return const Failure('Please sign in to continue.', code: 'unauthenticated');
      case 'aborted':
        // A transaction kept conflicting, e.g. many orders for one product.
        return const Failure('The store is busy. Please try again.', code: 'aborted');
      default:
        return const Failure('Something went wrong. Please try again.');
    }
  }

  /// Cloud Functions throw [FirebaseFunctionsException]. Messages from OUR
  /// functions (HttpsError with a safe message) are shown; anything else is
  /// replaced with a generic message.
  static Failure _functions(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return const Failure('Please sign in to continue.', code: 'unauthenticated');
      case 'permission-denied':
        return const Failure('You do not have permission to do that.', code: 'permission-denied');
      case 'failed-precondition':
      case 'invalid-argument':
      case 'not-found':
      case 'already-exists':
        final msg = e.message;
        if (msg != null && msg.isNotEmpty) {
          return Failure(msg, code: e.code);
        }
        return Failure('The request could not be completed.', code: e.code);
      case 'unavailable':
      case 'deadline-exceeded':
        return const Failure('Server is unreachable. Please try again.', code: 'network');
      default:
        return const Failure('Something went wrong. Please try again.');
    }
  }
}
