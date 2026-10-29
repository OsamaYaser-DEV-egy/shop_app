import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/stream_error_mapping.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Stream<Set<String>> watchFavoriteIds(String uid) =>
      _remote.watchFavoriteIds(uid).mapErrors();

  @override
  Future<void> add({required String uid, required String productId}) async {
    try {
      await _remote.add(uid, productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> remove({required String uid, required String productId}) async {
    try {
      await _remote.remove(uid, productId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
