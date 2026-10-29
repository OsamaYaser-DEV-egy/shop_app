import '../../../../core/errors/failures.dart';
import '../repositories/favorites_repository.dart';

/// Saves or unsaves a product.
class SetFavorite {
  const SetFavorite(this._repository);

  final FavoritesRepository _repository;

  Future<void> call({
    required String uid,
    required String productId,
    required bool favorite,
  }) async {
    if (productId.isEmpty) {
      throw const Failure('Missing product id.', code: 'invalid-product');
    }
    if (favorite) {
      await _repository.add(uid: uid, productId: productId);
    } else {
      await _repository.remove(uid: uid, productId: productId);
    }
  }
}
