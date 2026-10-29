import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/cancel_order.dart';
import '../../domain/usecases/update_order_status.dart';
import 'order_actions_state.dart';

/// Status changes and cancellation for one order page. The order itself is
/// watched by OrderDetailsCubit, which shows the result live.
class OrderActionsCubit extends Cubit<OrderActionsState> {
  OrderActionsCubit({
    required UpdateOrderStatus updateOrderStatus,
    required CancelOrder cancelOrder,
  })  : _updateOrderStatus = updateOrderStatus,
        _cancelOrder = cancelOrder,
        super(const OrderActionsState());

  final UpdateOrderStatus _updateOrderStatus;
  final CancelOrder _cancelOrder;

  /// Admin: moves the order to its next status.
  Future<void> advance(Order order) {
    final next = order.status.next;
    return _run(
      successMessage: next == null
          ? 'Order updated.'
          : 'Order marked as ${next.label.toLowerCase()}.',
      action: () => _updateOrderStatus(order),
    );
  }

  Future<void> cancel(Order order, {required bool byStore}) {
    return _run(
      successMessage: 'Order cancelled.',
      action: () => _cancelOrder(order, byStore: byStore),
    );
  }

  Future<void> _run({
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    if (state.isWorking) return; // prevents duplicate submissions
    emit(const OrderActionsState(status: OrderActionsStatus.working));
    try {
      await action();
      if (isClosed) return;
      emit(OrderActionsState(
        status: OrderActionsStatus.success,
        message: successMessage,
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(OrderActionsState(
        status: OrderActionsStatus.failure,
        message: f.message,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const OrderActionsState(
        status: OrderActionsStatus.failure,
        message: 'Something went wrong. Please try again.',
      ));
    }
  }
}
