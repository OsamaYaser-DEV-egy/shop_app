import '../entities/cart_item.dart';

abstract interface class CartRepository {
  /// Live cart of [uid]. Malformed documents are skipped. Emits a `Failure`
  /// error if the cart cannot be read.
  Stream<List<CartItem>> watchCart(String uid);

  /// Adds the product or replaces its quantity.
  Future<void> setQuantity({
    required String uid,
    required String productId,
    required int quantity,
  });

  Future<void> remove({required String uid, required String productId});

  Future<void> clear(String uid);
}
