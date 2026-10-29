import 'package:equatable/equatable.dart';

/// One product in the cart. Only the quantity is stored; the name, price and
/// stock are always read live from the product, so they are never stale.
class CartItem extends Equatable {
  const CartItem({required this.productId, required this.quantity});

  /// Most units of one product a cart may hold (also enforced by the rules).
  static const int maxQuantity = 99;

  final String productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}
