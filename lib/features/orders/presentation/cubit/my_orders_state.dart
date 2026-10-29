import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

enum MyOrdersStatus { loading, success, failure }

class MyOrdersState extends Equatable {
  const MyOrdersState({
    this.status = MyOrdersStatus.loading,
    this.orders = const [],
    this.message,
  });

  final MyOrdersStatus status;

  /// Newest first.
  final List<Order> orders;
  final String? message;

  @override
  List<Object?> get props => [status, orders, message];
}
