import '../repositories/favorites_repository.dart';

class WatchFavorites {
  const WatchFavorites(this._repository);

  final FavoritesRepository _repository;

  Stream<Set<String>> call(String uid) => _repository.watchFavoriteIds(uid);
}
