import 'package:equatable/equatable.dart';

import '../../../../core/utils/validators.dart';
import '../../../cart/domain/entities/cart_item.dart';

/// Everything the customer submits from the checkout screen. Prices are not
/// part of the request: they are read from the products when the order is
/// written, and the Security Rules check them.
class OrderRequest extends Equatable {
  const OrderRequest({
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.shippingAddress,
    required this.phone,
    required this.items,
    required this.expectedTotal,
  });

  /// Most different products in one order (any quantity of each). The
  /// Security Rules check every item, and 8 is the most that fits in
  /// Firestore's per-request rule budget. Must match `firestore.rules`.
  static const int maxDistinctProducts = 8;

  final String userId;
  final String customerName;
  final String customerEmail;
  final String shippingAddress;
  final String phone;
  final List<CartItem> items;

  /// The total the customer saw. The order is refused if prices changed.
  final double expectedTotal;

  /// A user-safe message describing the first problem, or null if valid.
  String? get validationError {
    if (items.isEmpty) return 'Your cart is empty.';
    if (items.length > maxDistinctProducts) {
      return 'You can order up to $maxDistinctProducts different products '
          'at a time.';
    }
    for (final item in items) {
      if (item.quantity < 1 || item.quantity > CartItem.maxQuantity) {
        return 'One of the quantities is not valid.';
      }
    }
    return Validators.phone(phone, required: true) ??
        Validators.address(shippingAddress, required: true);
  }

  @override
  List<Object?> get props => [
        userId,
        customerName,
        customerEmail,
        shippingAddress,
        phone,
        items,
        expectedTotal,
      ];
}
