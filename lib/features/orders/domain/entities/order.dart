import 'package:equatable/equatable.dart';

import 'order_item.dart';
import 'order_status.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.totalPrice,
    required this.shippingAddress,
    required this.phone,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;

  /// Sorted by product name.
  final List<OrderItem> items;
  final double totalPrice;
  final String shippingAddress;
  final String phone;
  final OrderStatus status;

  /// Null only while the server timestamp of a new order is pending.
  final DateTime? createdAt;

  /// Short, readable reference shown to customers, e.g. `#A1B2C3D4`.
  String get reference => referenceOf(id);

  static String referenceOf(String orderId) =>
      '#${(orderId.length > 8 ? orderId.substring(0, 8) : orderId).toUpperCase()}';

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [
        id,
        userId,
        customerName,
        customerEmail,
        items,
        totalPrice,
        shippingAddress,
        phone,
        status,
        createdAt,
      ];
}
