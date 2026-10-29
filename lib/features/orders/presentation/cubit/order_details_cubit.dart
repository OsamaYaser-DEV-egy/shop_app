import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/watch_order.dart';
import 'order_details_state.dart';

/// Live view of one order, so status changes appear while it is open.
class OrderDetailsCubit extends Cubit<OrderDetailsState> {
  OrderDetailsCubit({required WatchOrder watchOrder, required String orderId})
      : _watchOrder = watchOrder,
        _orderId = orderId,
        super(const OrderDetailsState()) {
    _subscribe();
  }

  final WatchOrder _watchOrder;
  final String _orderId;
  StreamSubscription<Order?>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(const OrderDetailsState());
    _subscription = _watchOrder(_orderId).listen(
      (order) => emit(
        order == null
            ? const OrderDetailsState(status: OrderDetailsStatus.notFound)
            : OrderDetailsState(
                status: OrderDetailsStatus.success,
                order: order,
              ),
      ),
      onError: (Object error) => emit(
        OrderDetailsState(
          status: OrderDetailsStatus.failure,
          message: error is Failure
              ? error.message
              : 'Could not load this order. Please try again.',
        ),
      ),
    );
  }

  void retry() => _subscribe();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
