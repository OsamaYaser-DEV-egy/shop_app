import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

enum OrderDetailsStatus { loading, success, notFound, failure }

class OrderDetailsState extends Equatable {
  const OrderDetailsState({
    this.status = OrderDetailsStatus.loading,
    this.order,
    this.message,
  });

  final OrderDetailsStatus status;
  final Order? order;
  final String? message;

  @override
  List<Object?> get props => [status, order, message];
}
