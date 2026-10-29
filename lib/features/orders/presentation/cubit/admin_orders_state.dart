import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';

enum AdminOrdersStatus { loading, success, failure }

class AdminOrdersState extends Equatable {
  const AdminOrdersState({
    this.status = AdminOrdersStatus.loading,
    this.orders = const [],
    this.filter,
    this.message,
  });

  final AdminOrdersStatus status;

  /// Newest first.
  final List<Order> orders;

  /// Selected status, or null for all orders.
  final OrderStatus? filter;
  final String? message;

  List<Order> get visible => filter == null
      ? orders
      : orders.where((o) => o.status == filter).toList();

  int countOf(OrderStatus status) =>
      orders.where((o) => o.status == status).length;

  AdminOrdersState copyWith({
    AdminOrdersStatus? status,
    List<Order>? orders,
    OrderStatus? filter,
    bool clearFilter = false,
    String? message,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      filter: clearFilter ? null : (filter ?? this.filter),
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, orders, filter, message];
}
