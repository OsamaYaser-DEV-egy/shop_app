import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/cart_item.dart';

/// Serialization for `users/{uid}/cart/{productId}`.
abstract final class CartItemModel {
  /// Returns null for documents without a usable quantity, so one bad
  /// document never breaks the cart.
  static CartItem? tryFromMap(String productId, Map<String, dynamic> data) {
    final value = data['quantity'];
    if (value is! num || !value.isFinite) return null;
    final quantity = value.toInt();
    if (quantity < 1) return null;
    return CartItem(
      productId: productId,
      quantity: quantity > CartItem.maxQuantity ? CartItem.maxQuantity : quantity,
    );
  }

  /// The document id is also the product id; `productId` is stored as well,
  /// as the requirements' data structure suggests.
  static Map<String, dynamic> toMap(String productId, int quantity) {
    return {
      'productId': productId,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
