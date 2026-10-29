import '../../../../core/errors/failures.dart';
import '../../../products/domain/entities/product.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

/// Adds [product] to the cart or changes its quantity. Stock is checked here
/// for a friendly message; it is checked again on the server at checkout.
class SetCartQuantity {
  const SetCartQuantity(this._repository);

  final CartRepository _repository;

  Future<void> call({
    required String uid,
    required Product product,
    required int quantity,
  }) async {
    if (!product.canBePurchased) {
      throw const Failure('This product is out of stock.', code: 'out-of-stock');
    }
    if (quantity < 1) {
      throw const Failure('Quantity must be at least 1.', code: 'invalid-quantity');
    }
    if (quantity > CartItem.maxQuantity) {
      throw const Failure(
        'You can add up to ${CartItem.maxQuantity} of each item.',
        code: 'invalid-quantity',
      );
    }
    if (quantity > product.stock) {
      throw Failure(
        'Only ${product.stock} left in stock.',
        code: 'out-of-stock',
      );
    }
    await _repository.setQuantity(
      uid: uid,
      productId: product.id,
      quantity: quantity,
    );
  }
}
