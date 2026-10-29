import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item.dart';

enum CartStatus {
  /// No customer is signed in.
  signedOut,
  loading,
  success,
  failure,
}

class CartState extends Equatable {
  const CartState({
    this.status = CartStatus.signedOut,
    this.items = const [],
    this.message,
  });

  final CartStatus status;
  final List<CartItem> items;
  final String? message;

  /// Total units in the cart, shown on the cart badge.
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int quantityOf(String productId) {
    for (final item in items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  @override
  List<Object?> get props => [status, items, message];
}
