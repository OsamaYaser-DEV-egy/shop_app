// cloud_firestore has its own (index) Order type.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_request.dart';
import '../../domain/entities/order_status.dart';

/// Serialization for `orders/{orderId}`.
///
/// `items` is a map keyed by product id rather than a list, so the Security
/// Rules can find the item of a given product directly.
abstract final class OrderModel {
  static const String cashOnDelivery = 'cash_on_delivery';

  /// Returns null for documents that cannot be shown safely.
  static Order? tryFromMap(String id, Map<String, dynamic> data) {
    final userId = _string(data['userId']);
    final total = data['totalPrice'];
    final rawItems = data['items'];
    if (userId.isEmpty || total is! num || rawItems is! Map) return null;

    final items = <OrderItem>[];
    rawItems.forEach((key, value) {
      final item = _item(key, value);
      if (item != null) items.add(item);
    });
    if (items.isEmpty) return null;
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final createdAt = data['createdAt'];
    return Order(
      id: id,
      userId: userId,
      customerName: _string(data['customerName']),
      customerEmail: _string(data['customerEmail']),
      items: items,
      totalPrice: total.toDouble(),
      shippingAddress: _string(data['shippingAddress']),
      phone: _string(data['phone']),
      status: OrderStatus.fromName(data['status']) ?? OrderStatus.pending,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  static OrderItem? _item(Object? productId, Object? value) {
    if (productId is! String || value is! Map) return null;
    final name = value['name'];
    final price = value['price'];
    final quantity = value['quantity'];
    if (name is! String || price is! num || quantity is! num) return null;
    return OrderItem(
      productId: productId,
      name: name,
      price: price.toDouble(),
      quantity: quantity.toInt(),
    );
  }

  /// One order item, copied from the raw product document so the values are
  /// exactly what the Security Rules compare against. The rules allow only
  /// these three fields.
  static Map<String, dynamic> itemMap(
    Map<String, dynamic> product,
    int quantity,
  ) {
    return {
      'name': product['name'],
      'price': product['price'],
      'quantity': quantity,
    };
  }

  static Map<String, dynamic> createMap({
    required OrderRequest request,
    required Map<String, Map<String, dynamic>> items,
    required double totalPrice,
  }) {
    return {
      'userId': request.userId,
      'customerName': request.customerName.trim(),
      'customerEmail': request.customerEmail,
      'items': items,
      'totalPrice': totalPrice,
      'shippingAddress': request.shippingAddress.trim(),
      'phone': request.phone.trim(),
      'paymentMethod': cashOnDelivery,
      'status': OrderStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// The only fields a status change may touch (see `firestore.rules`).
  static Map<String, dynamic> statusMap(OrderStatus status) {
    return {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Rounds to cents. The rules accept a total within one cent of their own
  /// sum, which absorbs floating-point differences.
  static double roundMoney(double value) => (value * 100).roundToDouble() / 100;

  static String _string(Object? value) => value is String ? value : '';
}
