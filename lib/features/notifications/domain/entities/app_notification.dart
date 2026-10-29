import 'package:equatable/equatable.dart';

import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_status.dart';

/// An in-app notification (`notifications/{id}`), currently always about an
/// order status change made by the store.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.orderId,
    this.orderStatus,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? orderId;

  /// The status the order moved to, used for the icon.
  final OrderStatus? orderStatus;

  /// Null only while the server timestamp is pending.
  final DateTime? createdAt;

  AppNotification markedRead() => AppNotification(
        id: id,
        title: title,
        body: body,
        isRead: true,
        orderId: orderId,
        orderStatus: orderStatus,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, body, isRead, orderId, orderStatus, createdAt];
}

/// Title and body for a status change, or null when the status does not
/// notify the customer.
({String title, String body})? orderStatusMessage(
  OrderStatus status,
  String orderId,
) {
  final ref = Order.referenceOf(orderId);
  return switch (status) {
    OrderStatus.confirmed => (
        title: 'Order confirmed',
        body: 'Your order $ref has been confirmed.',
      ),
    OrderStatus.shipped => (
        title: 'Your order is on its way',
        body: 'Order $ref has shipped.',
      ),
    OrderStatus.delivered => (
        title: 'Order delivered',
        body: 'Order $ref was delivered. Enjoy!',
      ),
    OrderStatus.cancelled => (
        title: 'Order cancelled',
        body: 'Order $ref was cancelled by the store.',
      ),
    OrderStatus.pending || OrderStatus.preparing => null,
  };
}
