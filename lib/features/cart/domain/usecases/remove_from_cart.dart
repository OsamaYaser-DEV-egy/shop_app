import '../../../../core/errors/failures.dart';
import '../repositories/cart_repository.dart';

class RemoveFromCart {
  const RemoveFromCart(this._repository);

  final CartRepository _repository;

  Future<void> call({required String uid, required String productId}) async {
    if (productId.isEmpty) {
      throw const Failure('Missing product id.', code: 'invalid-product');
    }
    await _repository.remove(uid: uid, productId: productId);
  }
}
