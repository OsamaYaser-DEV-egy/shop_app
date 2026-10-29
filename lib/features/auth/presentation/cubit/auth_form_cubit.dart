import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in.dart';
import 'auth_form_state.dart';

/// Handles the login, register and password-reset actions.
///
/// It never navigates. After a successful sign-in the SessionCubit changes
/// and the router redirects. This cubit lives for the whole app, so errors
/// can still be shown if the page was already replaced.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit({
    required SignIn signIn,
    required Register register,
    required SendPasswordReset sendPasswordReset,
  })  : _signIn = signIn,
        _register = register,
        _sendPasswordReset = sendPasswordReset,
        super(const AuthFormState());

  final SignIn _signIn;
  final Register _register;
  final SendPasswordReset _sendPasswordReset;

  Future<void> login({required String email, required String password}) {
    return _run(() => _signIn(email: email.trim(), password: password));
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => _register(name: name, email: email, password: password),
    );
  }

  Future<void> resetPassword({required String email}) {
    return _run(
      () => _sendPasswordReset(email: email.trim()),
      successMessage: 'Password reset link sent. Check your email.',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (state.isSubmitting) return; // prevents duplicate submissions
    emit(const AuthFormState(status: AuthFormStatus.submitting));
    try {
      await action();
      emit(
        successMessage == null
            ? const AuthFormState()
            : AuthFormState(
                status: AuthFormStatus.success,
                message: successMessage,
              ),
      );
    } on Failure catch (f) {
      emit(AuthFormState(status: AuthFormStatus.failure, message: f.message));
    } catch (_) {
      emit(const AuthFormState(
        status: AuthFormStatus.failure,
        message: 'Something went wrong. Please try again.',
      ));
    }
  }
}
