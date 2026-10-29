import '../repositories/auth_repository.dart';

class WatchAuthUid {
  const WatchAuthUid(this._repository);

  final AuthRepository _repository;

  Stream<String?> call() => _repository.watchAuthUid();
}
