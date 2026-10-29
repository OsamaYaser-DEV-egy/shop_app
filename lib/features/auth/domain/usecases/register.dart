import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class Register {
  const Register(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String name,
    required String email,
    required String password,
  }) {
    final cleanName = name.trim();
    if (cleanName.length < 2 || cleanName.length > 80) {
      throw const Failure('Please enter a valid name.');
    }
    if (password.length < 8) {
      throw const Failure('Use at least 8 characters for your password.');
    }
    return _repository.register(
      name: cleanName,
      email: email.trim(),
      password: password,
    );
  }
}
