import '../../../../core/errors/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

/// Cancels an order under the store's or the customer's business rule.
class CancelOrder {
  const CancelOrder(this._repository);

  final OrderRepository _repository;

  Future<void> call(Order order, {required bool byStore}) async {
    final allowed = byStore
        ? order.status.canBeCancelledByStore
        : order.status.canBeCancelledByCustomer;
    if (!allowed) {
      throw Failure(
        byStore
            ? 'Orders can only be cancelled before they ship.'
            : 'This order is already being processed. Please contact the '
                'store to cancel it.',
        code: 'invalid-status',
      );
    }
    await _repository.cancelOrder(orderId: order.id, byStore: byStore);
  }
}
