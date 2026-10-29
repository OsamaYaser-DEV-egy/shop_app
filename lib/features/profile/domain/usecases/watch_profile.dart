import '../entities/app_user.dart';
import '../repositories/profile_repository.dart';

class WatchProfile {
  const WatchProfile(this._repository);

  final ProfileRepository _repository;

  Stream<AppUser?> call(String uid) => _repository.watchProfile(uid);
}
