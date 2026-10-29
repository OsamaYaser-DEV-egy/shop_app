import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<void> call({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) {
    final cleanName = name.trim();
    if (cleanName.length < 2 || cleanName.length > 80) {
      throw const Failure('Please enter a valid name.');
    }
    return _repository.updateProfile(
      uid: uid,
      name: cleanName,
      phone: phone.trim(),
      address: address.trim(),
    );
  }
}
